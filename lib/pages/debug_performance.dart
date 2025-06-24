import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/performance_monitor.dart';
import '../services/cache/sqlite_message_cache.dart';
import '../services/service_locator.dart';

class DebugPerformancePage extends StatefulWidget {
  const DebugPerformancePage({super.key});

  @override
  State<DebugPerformancePage> createState() => _DebugPerformancePageState();
}

class _DebugPerformancePageState extends State<DebugPerformancePage>
    with TickerProviderStateMixin {
  late PerformanceMonitor _perfMonitor;
  SqliteMessageCache? _cache;

  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _memoryStats = {};
  Map<String, dynamic> _insights = {};
  bool _isLoading = false;
  late AnimationController _refreshController;

  @override
  void initState() {
    super.initState();
    _perfMonitor = PerformanceMonitor.instance;
    _refreshController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _loadStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _cache = Provider.of<SqliteMessageCache>(context, listen: false);
    } catch (e) {
      debugPrint('Cache service not available: $e');
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    _refreshController.forward(from: 0);

    try {
      final serviceStats = await ServiceLocator.instance.getMemoryStats();
      final perfReport = _perfMonitor.generateReport();
      final memoryInfo = await _perfMonitor.getCurrentMemoryUsage();
      final insights = _perfMonitor.getPerformanceInsights();

      setState(() {
        _stats = {
          'service_stats': serviceStats,
          'performance_report': perfReport,
        };
        _memoryStats = memoryInfo != null
            ? {
                'used_mb': memoryInfo.usedMemoryMB,
                'available_mb': memoryInfo.availableMemoryMB,
                'total_mb': memoryInfo.totalMemoryMB,
                'usage_percentage': memoryInfo.usagePercentage,
              }
            : {};
        _insights = insights;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stats: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await _showConfirmationDialog(
      'Clear Cache',
      'This will clear all cached messages and performance data. Continue?',
    );

    if (!confirmed) return;

    try {
      await ServiceLocator.instance.clearAllCache();
      _perfMonitor.clear();
      await _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing cache: $e')),
        );
      }
    }
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _runMaintenance() async {
    try {
      await ServiceLocator.instance.performMaintenance();
      await _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maintenance completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error running maintenance: $e')),
        );
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final data = _perfMonitor.exportData();
      final jsonString = data.toString();

      await Clipboard.setData(ClipboardData(text: jsonString));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Performance data copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Performance Data'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: SingleChildScrollView(
                child: Text(
                  jsonString,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: jsonString));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  }
                },
                child: const Text('Copy'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e')),
        );
      }
    }
  }

  Future<void> _simulateLoad() async {
    if (_cache == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache service not available')),
      );
      return;
    }

    try {
      _perfMonitor.startTimer('simulate_load');

      for (int i = 0; i < 10; i++) {
        _perfMonitor.trackSqliteOperation(
          operation: 'SELECT',
          table: 'test_table',
          rowCount: 25,
          executionTimeMs: 10.0 + (i * 2),
        );
        await Future.delayed(const Duration(milliseconds: 50));
      }

      final loadTime = _perfMonitor.endTimer('simulate_load');
      _perfMonitor.trackMessageLoad(
        chatId: 'test-chat',
        messageCount: 250,
        fromCache: true,
        loadTimeMs: loadTime,
      );

      await _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Simulated load completed in ${loadTime?.toStringAsFixed(1)}ms'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error simulating load: $e')),
        );
      }
    }
  }

  Widget _buildServiceStatusCard() {
    final serviceLocator = ServiceLocator.instance;
    final isInitialized = serviceLocator.isInitialized;
    final isInitializing = serviceLocator.isInitializing;
    final initError = serviceLocator.initializationError;
    final initTime = serviceLocator.initializationTime;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isInitializing) {
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
      statusText = 'Initializing...';
    } else if (isInitialized) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Operational';
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'Not Initialized';
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Service Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (initTime != null) ...[
              const SizedBox(height: 8),
              Text(
                'Initialized: ${initTime.toString().split('.')[0]}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            if (initError != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: $initError',
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceScoreCard() {
    if (_insights.isEmpty) {
      return const SizedBox.shrink();
    }

    final score = _insights['performance_score'] as double? ?? 0.0;
    final recommendations = _insights['recommendations'] as List? ?? [];

    Color scoreColor;
    IconData scoreIcon;
    String scoreLabel;

    if (score >= 80) {
      scoreColor = Colors.green;
      scoreIcon = Icons.sentiment_very_satisfied;
      scoreLabel = 'Excellent';
    } else if (score >= 60) {
      scoreColor = Colors.orange;
      scoreIcon = Icons.sentiment_satisfied;
      scoreLabel = 'Good';
    } else if (score >= 40) {
      scoreColor = Colors.deepOrange;
      scoreIcon = Icons.sentiment_neutral;
      scoreLabel = 'Fair';
    } else {
      scoreColor = Colors.red;
      scoreIcon = Icons.sentiment_very_dissatisfied;
      scoreLabel = 'Poor';
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(scoreIcon, color: scoreColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Performance Score',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${score.toStringAsFixed(0)}/100',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              scoreLabel,
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Recommendations:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rec.toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryCard() {
    if (_memoryStats.isEmpty) {
      return const Card(
        margin: EdgeInsets.all(8.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Memory information not available'),
        ),
      );
    }

    final usagePercentage = _memoryStats['usage_percentage'] as double? ?? 0.0;
    final color = usagePercentage > 80
        ? Colors.red
        : usagePercentage > 60
            ? Colors.orange
            : Colors.green;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Memory Usage',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: usagePercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            const SizedBox(height: 8),
            Text(
              '${usagePercentage.toStringAsFixed(1)}% used',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            ..._memoryStats.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        _formatValue(entry.value),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loadStats,
                  icon: AnimatedBuilder(
                    animation: _refreshController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _refreshController.value * 2 * 3.14159,
                        child: const Icon(Icons.refresh, size: 16),
                      );
                    },
                  ),
                  label: const Text('Refresh'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _clearCache,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear Cache'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runMaintenance,
                  icon: const Icon(Icons.build, size: 16),
                  label: const Text('Maintenance'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _exportData,
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Export Data'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _simulateLoad,
                  icon: const Icon(Icons.speed, size: 16),
                  label: const Text('Simulate Load'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...data.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _formatValue(entry.value),
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value is double) {
      return value.toStringAsFixed(2);
    } else if (value is Map) {
      return 'Map(${value.length} items)';
    } else if (value is List) {
      return 'List(${value.length} items)';
    } else {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Debug'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildServiceStatusCard(),
                  _buildPerformanceScoreCard(),
                  _buildMemoryCard(),
                  _buildActionButtons(),
                  if (_stats['performance_report'] != null)
                    _buildStatCard(
                      'Performance Report',
                      Map<String, dynamic>.from(
                          _stats['performance_report'] as Map),
                    ),
                  if (_stats['service_stats'] != null)
                    _buildStatCard(
                      'Service Stats',
                      Map<String, dynamic>.from(_stats['service_stats'] as Map),
                    ),
                  if (_insights.isNotEmpty)
                    _buildStatCard(
                      'Performance Insights',
                      Map<String, dynamic>.from(_insights),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
