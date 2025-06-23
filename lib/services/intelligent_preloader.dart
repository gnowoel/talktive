import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat.dart';
import '../models/message.dart';
import '../models/topic_message.dart';
import 'cache/sqlite_message_cache.dart';
import 'paginated_message_service.dart';
import 'performance_monitor.dart';

/// Intelligent preloading service that predicts and preloads content
/// based on user behavior patterns and usage analytics
class IntelligentPreloader extends ChangeNotifier {
  static const String _prefsPrefix = 'intelligent_preloader_';
  static const int _maxPreloadItems = 10;
  static const int _maxPatternHistory = 100;
  static const Duration _preloadDelay = Duration(milliseconds: 500);
  static const Duration _backgroundPreloadInterval = Duration(seconds: 30);

  final PaginatedMessageService _messageService;
  final SqliteMessageCache _cache;
  final PerformanceMonitor _perfMonitor;

  // User behavior tracking
  final Map<String, UserAccessPattern> _accessPatterns = {};
  final Map<String, ChatPreference> _chatPreferences = {};
  final List<UserAction> _recentActions = [];

  // Preloading state
  final Set<String> _currentlyPreloading = {};
  final Map<String, DateTime> _lastPreloadTime = {};
  final Map<String, PreloadResult> _preloadResults = {};

  // Configuration
  bool _isEnabled = true;
  bool _allowMobileDataPreload = false;
  PreloadStrategy _strategy = PreloadStrategy.adaptive;
  int _maxConcurrentPreloads = 3;
  double _confidenceThreshold = 0.7;

  // Background processing
  Timer? _backgroundTimer;
  Timer? _patternAnalysisTimer;

  IntelligentPreloader({
    required PaginatedMessageService messageService,
    required SqliteMessageCache cache,
    required PerformanceMonitor perfMonitor,
  })  : _messageService = messageService,
        _cache = cache,
        _perfMonitor = perfMonitor {
    _initialize();
  }

  // Public API

  /// Initialize the preloader
  Future<void> _initialize() async {
    await _loadUserPreferences();
    await _loadAccessPatterns();
    _startBackgroundProcessing();
    _startPatternAnalysis();
  }

  /// Record user action for behavior analysis
  void recordUserAction(UserAction action) {
    _recentActions.add(action);

    // Keep only recent actions
    if (_recentActions.length > _maxPatternHistory) {
      _recentActions.removeRange(0, _recentActions.length - _maxPatternHistory);
    }

    _updateAccessPattern(action);

    // Trigger preloading analysis
    _schedulePreloadAnalysis();
  }

  /// Record chat access for preference learning
  void recordChatAccess(String chatId, Duration sessionDuration) {
    final pattern = _accessPatterns[chatId] ?? UserAccessPattern(chatId: chatId);
    pattern.recordAccess(sessionDuration);
    _accessPatterns[chatId] = pattern;

    final preference = _chatPreferences[chatId] ?? ChatPreference(chatId: chatId);
    preference.updatePreference(sessionDuration);
    _chatPreferences[chatId] = preference;

    _saveAccessPatterns();
  }

  /// Suggest next likely chat to access
  List<ChatPrediction> predictNextChats({int limit = 5}) {
    final predictions = <ChatPrediction>[];

    for (final pattern in _accessPatterns.values) {
      final confidence = _calculateChatConfidence(pattern);
      if (confidence > _confidenceThreshold) {
        predictions.add(ChatPrediction(
          chatId: pattern.chatId,
          confidence: confidence,
          reasoning: _generateReasoning(pattern),
        ));
      }
    }

    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return predictions.take(limit).toList();
  }

  /// Manual preload trigger
  Future<PreloadResult> preloadChat(String chatId, {int messageCount = 25}) async {
    if (!_isEnabled || _currentlyPreloading.contains(chatId)) {
      return PreloadResult.skipped('Already preloading or disabled');
    }

    return await _performPreload(chatId, messageCount, isManual: true);
  }

  /// Configure preloading behavior
  void configure({
    bool? enabled,
    bool? allowMobileData,
    PreloadStrategy? strategy,
    int? maxConcurrentPreloads,
    double? confidenceThreshold,
  }) {
    _isEnabled = enabled ?? _isEnabled;
    _allowMobileDataPreload = allowMobileData ?? _allowMobileDataPreload;
    _strategy = strategy ?? _strategy;
    _maxConcurrentPreloads = maxConcurrentPreloads ?? _maxConcurrentPreloads;
    _confidenceThreshold = confidenceThreshold ?? _confidenceThreshold;

    _saveUserPreferences();
  }

  /// Get preloading statistics
  PreloadingStats getStats() {
    final totalPreloads = _preloadResults.length;
    final successfulPreloads = _preloadResults.values
        .where((result) => result.success)
        .length;

    final totalDataPreloaded = _preloadResults.values
        .map((result) => result.messagesPreloaded)
        .fold(0, (sum, count) => sum + count);

    return PreloadingStats(
      totalPreloads: totalPreloads,
      successfulPreloads: successfulPreloads,
      totalMessagesPreloaded: totalDataPreloaded,
      successRate: totalPreloads > 0 ? successfulPreloads / totalPreloads : 0.0,
      activePreloads: _currentlyPreloading.length,
      trackedChats: _accessPatterns.length,
    );
  }

  // Private implementation

  void _updateAccessPattern(UserAction action) {
    switch (action.type) {
      case UserActionType.chatOpen:
        _recordChatInteraction(action.entityId, ActionContext.open);
        break;
      case UserActionType.messageScroll:
        _recordChatInteraction(action.entityId, ActionContext.scroll);
        break;
      case UserActionType.messageSend:
        _recordChatInteraction(action.entityId, ActionContext.send);
        break;
      case UserActionType.chatSearch:
        _recordSearchPattern(action.entityId);
        break;
    }
  }

  void _recordChatInteraction(String chatId, ActionContext context) {
    final pattern = _accessPatterns[chatId] ?? UserAccessPattern(chatId: chatId);
    pattern.addInteraction(context, DateTime.now());
    _accessPatterns[chatId] = pattern;
  }

  void _recordSearchPattern(String query) {
    // Analyze search patterns for predictive preloading
    // Implementation would analyze search queries to predict chat access
  }

  double _calculateChatConfidence(UserAccessPattern pattern) {
    double confidence = 0.0;

    // Recent activity weight (40%)
    final recentActivity = pattern.getRecentActivityScore();
    confidence += recentActivity * 0.4;

    // Access frequency weight (30%)
    final frequency = pattern.getFrequencyScore();
    confidence += frequency * 0.3;

    // Time pattern weight (20%)
    final timePattern = pattern.getTimePatternScore();
    confidence += timePattern * 0.2;

    // Context similarity weight (10%)
    final contextSimilarity = _calculateContextSimilarity(pattern);
    confidence += contextSimilarity * 0.1;

    return confidence.clamp(0.0, 1.0);
  }

  double _calculateContextSimilarity(UserAccessPattern pattern) {
    // Analyze current context (time of day, day of week, etc.)
    // and compare with pattern's typical access contexts
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentDayOfWeek = now.weekday;

    double similarity = 0.0;

    // Hour similarity
    final typicalHours = pattern.getTypicalAccessHours();
    if (typicalHours.contains(currentHour)) {
      similarity += 0.5;
    }

    // Day of week similarity
    final typicalDays = pattern.getTypicalAccessDays();
    if (typicalDays.contains(currentDayOfWeek)) {
      similarity += 0.5;
    }

    return similarity;
  }

  String _generateReasoning(UserAccessPattern pattern) {
    final reasons = <String>[];

    if (pattern.getRecentActivityScore() > 0.7) {
      reasons.add('high recent activity');
    }

    if (pattern.getFrequencyScore() > 0.8) {
      reasons.add('frequently accessed');
    }

    if (pattern.getTimePatternScore() > 0.6) {
      reasons.add('typical access time');
    }

    return reasons.join(', ');
  }

  void _schedulePreloadAnalysis() {
    Timer(_preloadDelay, () {
      _performPreloadAnalysis();
    });
  }

  Future<void> _performPreloadAnalysis() async {
    if (!_isEnabled || _currentlyPreloading.length >= _maxConcurrentPreloads) {
      return;
    }

    final predictions = predictNextChats(limit: _maxPreloadItems);

    for (final prediction in predictions) {
      if (_currentlyPreloading.length >= _maxConcurrentPreloads) break;

      if (_shouldPreload(prediction)) {
        _performPreload(prediction.chatId, 25).catchError((error) {
          debugPrint('Preload error for ${prediction.chatId}: $error');
        });
      }
    }
  }

  bool _shouldPreload(ChatPrediction prediction) {
    // Don't preload if already done recently
    final lastPreload = _lastPreloadTime[prediction.chatId];
    if (lastPreload != null &&
        DateTime.now().difference(lastPreload) < const Duration(minutes: 15)) {
      return false;
    }

    // Check network conditions
    if (!_allowMobileDataPreload && _isOnMobileData()) {
      return false;
    }

    // Check confidence threshold
    return prediction.confidence > _confidenceThreshold;
  }

  bool _isOnMobileData() {
    // This would need to be implemented with platform-specific code
    // or a connectivity plugin to detect network type
    return false; // Placeholder
  }

  Future<PreloadResult> _performPreload(
    String chatId,
    int messageCount, {
    bool isManual = false,
  }) async {
    _currentlyPreloading.add(chatId);
    _lastPreloadTime[chatId] = DateTime.now();

    final startTime = DateTime.now();
    _perfMonitor.startTimer('preload_$chatId');

    try {
      // Check if messages are already cached
      final cachedCount = await _cache.getChatMessageCount(chatId);
      if (cachedCount >= messageCount && !isManual) {
        return PreloadResult.success(
          messagesPreloaded: 0,
          fromCache: true,
          duration: DateTime.now().difference(startTime),
        );
      }

      // Preload messages
      final result = await _messageService.loadChatMessages(
        chatId,
        pageSize: messageCount,
        isInitialLoad: true,
      );

      final duration = DateTime.now().difference(startTime);
      final loadTime = _perfMonitor.endTimer('preload_$chatId');

      _perfMonitor.trackMessageLoad(
        chatId: chatId,
        messageCount: result.items.length,
        fromCache: result.isFromCache,
        loadTimeMs: loadTime,
      );

      final preloadResult = PreloadResult.success(
        messagesPreloaded: result.items.length,
        fromCache: result.isFromCache,
        duration: duration,
      );

      _preloadResults[chatId] = preloadResult;
      return preloadResult;

    } catch (error) {
      _perfMonitor.endTimer('preload_$chatId');

      final preloadResult = PreloadResult.failed(
        error: error.toString(),
        duration: DateTime.now().difference(startTime),
      );

      _preloadResults[chatId] = preloadResult;
      return preloadResult;

    } finally {
      _currentlyPreloading.remove(chatId);
    }
  }

  void _startBackgroundProcessing() {
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer.periodic(_backgroundPreloadInterval, (timer) {
      if (_strategy == PreloadStrategy.aggressive ||
          _strategy == PreloadStrategy.adaptive) {
        _performPreloadAnalysis();
      }
    });
  }

  void _startPatternAnalysis() {
    _patternAnalysisTimer?.cancel();
    _patternAnalysisTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _analyzeAndOptimizePatterns();
    });
  }

  void _analyzeAndOptimizePatterns() {
    // Remove stale patterns
    final now = DateTime.now();
    _accessPatterns.removeWhere((key, pattern) {
      return now.difference(pattern.lastAccess) > const Duration(days: 30);
    });

    // Optimize pattern data
    for (final pattern in _accessPatterns.values) {
      pattern.optimize();
    }

    _saveAccessPatterns();
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    _isEnabled = prefs.getBool('${_prefsPrefix}enabled') ?? true;
    _allowMobileDataPreload = prefs.getBool('${_prefsPrefix}mobile_data') ?? false;
    _maxConcurrentPreloads = prefs.getInt('${_prefsPrefix}max_concurrent') ?? 3;
    _confidenceThreshold = prefs.getDouble('${_prefsPrefix}confidence') ?? 0.7;

    final strategyIndex = prefs.getInt('${_prefsPrefix}strategy') ?? 1;
    _strategy = PreloadStrategy.values[strategyIndex.clamp(0, PreloadStrategy.values.length - 1)];
  }

  Future<void> _saveUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('${_prefsPrefix}enabled', _isEnabled);
    await prefs.setBool('${_prefsPrefix}mobile_data', _allowMobileDataPreload);
    await prefs.setInt('${_prefsPrefix}max_concurrent', _maxConcurrentPreloads);
    await prefs.setDouble('${_prefsPrefix}confidence', _confidenceThreshold);
    await prefs.setInt('${_prefsPrefix}strategy', _strategy.index);
  }

  Future<void> _loadAccessPatterns() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('${_prefsPrefix}pattern_'));

    for (final key in keys) {
      final patternData = prefs.getString(key);
      if (patternData != null) {
        try {
          final pattern = UserAccessPattern.fromJson(patternData);
          _accessPatterns[pattern.chatId] = pattern;
        } catch (e) {
          debugPrint('Failed to load access pattern: $e');
        }
      }
    }
  }

  Future<void> _saveAccessPatterns() async {
    final prefs = await SharedPreferences.getInstance();

    for (final pattern in _accessPatterns.values) {
      final key = '${_prefsPrefix}pattern_${pattern.chatId}';
      await prefs.setString(key, pattern.toJson());
    }
  }

  @override
  void dispose() {
    _backgroundTimer?.cancel();
    _patternAnalysisTimer?.cancel();
    super.dispose();
  }
}

// Data classes and enums

enum PreloadStrategy {
  disabled,
  conservative,
  adaptive,
  aggressive,
}

enum UserActionType {
  chatOpen,
  messageScroll,
  messageSend,
  chatSearch,
}

enum ActionContext {
  open,
  scroll,
  send,
  search,
}

class UserAction {
  final UserActionType type;
  final String entityId;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  UserAction({
    required this.type,
    required this.entityId,
    required this.timestamp,
    this.metadata = const {},
  });
}

class UserAccessPattern {
  final String chatId;
  final List<DateTime> accessTimes = [];
  final Map<ActionContext, int> actionCounts = {};
  DateTime lastAccess = DateTime.now();

  UserAccessPattern({required this.chatId});

  void recordAccess(Duration sessionDuration) {
    accessTimes.add(DateTime.now());
    lastAccess = DateTime.now();

    // Keep only recent access times
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    accessTimes.removeWhere((time) => time.isBefore(cutoff));
  }

  void addInteraction(ActionContext context, DateTime time) {
    actionCounts[context] = (actionCounts[context] ?? 0) + 1;
    lastAccess = time;
  }

  double getRecentActivityScore() {
    final recentCutoff = DateTime.now().subtract(const Duration(days: 7));
    final recentAccesses = accessTimes.where((time) => time.isAfter(recentCutoff)).length;
    return (recentAccesses / 10.0).clamp(0.0, 1.0);
  }

  double getFrequencyScore() {
    final totalAccesses = accessTimes.length;
    final daysSinceFirst = accessTimes.isEmpty ? 1 :
        DateTime.now().difference(accessTimes.first).inDays + 1;
    final avgAccessesPerDay = totalAccesses / daysSinceFirst;
    return (avgAccessesPerDay / 3.0).clamp(0.0, 1.0);
  }

  double getTimePatternScore() {
    if (accessTimes.length < 3) return 0.0;

    final currentHour = DateTime.now().hour;
    final typicalHours = getTypicalAccessHours();
    return typicalHours.contains(currentHour) ? 1.0 : 0.0;
  }

  Set<int> getTypicalAccessHours() {
    final hourCounts = <int, int>{};
    for (final time in accessTimes) {
      hourCounts[time.hour] = (hourCounts[time.hour] ?? 0) + 1;
    }

    if (hourCounts.isEmpty) return {};

    final maxCount = hourCounts.values.reduce(max);
    final threshold = maxCount * 0.5;

    return hourCounts.entries
        .where((entry) => entry.value >= threshold)
        .map((entry) => entry.key)
        .toSet();
  }

  Set<int> getTypicalAccessDays() {
    final dayCounts = <int, int>{};
    for (final time in accessTimes) {
      dayCounts[time.weekday] = (dayCounts[time.weekday] ?? 0) + 1;
    }

    if (dayCounts.isEmpty) return {};

    final maxCount = dayCounts.values.reduce(max);
    final threshold = maxCount * 0.3;

    return dayCounts.entries
        .where((entry) => entry.value >= threshold)
        .map((entry) => entry.key)
        .toSet();
  }

  void optimize() {
    // Remove old access times
    final cutoff = DateTime.now().subtract(const Duration(days: 60));
    accessTimes.removeWhere((time) => time.isBefore(cutoff));
  }

  String toJson() {
    // Simplified JSON serialization - in production use proper JSON encoding
    return 'UserAccessPattern:$chatId:${accessTimes.length}:${lastAccess.millisecondsSinceEpoch}';
  }

  static UserAccessPattern fromJson(String json) {
    final parts = json.split(':');
    final pattern = UserAccessPattern(chatId: parts[1]);
    pattern.lastAccess = DateTime.fromMillisecondsSinceEpoch(int.parse(parts[3]));
    return pattern;
  }
}

class ChatPreference {
  final String chatId;
  double priority = 0.5;
  Duration averageSessionDuration = Duration.zero;
  int totalSessions = 0;

  ChatPreference({required this.chatId});

  void updatePreference(Duration sessionDuration) {
    totalSessions++;
    averageSessionDuration = Duration(
      milliseconds: ((averageSessionDuration.inMilliseconds * (totalSessions - 1)) +
          sessionDuration.inMilliseconds) ~/ totalSessions,
    );

    // Update priority based on session duration and frequency
    priority = ((averageSessionDuration.inMinutes / 10.0) + (totalSessions / 100.0)).clamp(0.0, 1.0);
  }
}

class ChatPrediction {
  final String chatId;
  final double confidence;
  final String reasoning;

  ChatPrediction({
    required this.chatId,
    required this.confidence,
    required this.reasoning,
  });
}

class PreloadResult {
  final bool success;
  final int messagesPreloaded;
  final bool fromCache;
  final Duration duration;
  final String? error;

  PreloadResult._({
    required this.success,
    required this.messagesPreloaded,
    required this.fromCache,
    required this.duration,
    this.error,
  });

  factory PreloadResult.success({
    required int messagesPreloaded,
    required bool fromCache,
    required Duration duration,
  }) {
    return PreloadResult._(
      success: true,
      messagesPreloaded: messagesPreloaded,
      fromCache: fromCache,
      duration: duration,
    );
  }

  factory PreloadResult.failed({
    required String error,
    required Duration duration,
  }) {
    return PreloadResult._(
      success: false,
      messagesPreloaded: 0,
      fromCache: false,
      duration: duration,
      error: error,
    );
  }

  factory PreloadResult.skipped(String reason) {
    return PreloadResult._(
      success: false,
      messagesPreloaded: 0,
      fromCache: true,
      duration: Duration.zero,
      error: reason,
    );
  }
}

class PreloadingStats {
  final int totalPreloads;
  final int successfulPreloads;
  final int totalMessagesPreloaded;
  final double successRate;
  final int activePreloads;
  final int trackedChats;

  PreloadingStats({
    required this.totalPreloads,
    required this.successfulPreloads,
    required this.totalMessagesPreloaded,
    required this.successRate,
    required this.activePreloads,
    required this.trackedChats,
  });
}
