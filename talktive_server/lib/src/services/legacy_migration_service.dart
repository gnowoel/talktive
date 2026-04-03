import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;

import 'gamification_service.dart';

class LegacyMigrationService {
  static const Set<String> _supportedLanguageCodes = {
    'en',
    'es',
    'fr',
    'de',
    'it',
    'pt',
    'ru',
    'ja',
    'ko',
    'zh',
    'hi',
    'ar',
    'tr',
    'vi',
    'id',
    'th',
    'nl',
    'pl',
    'sv',
    'no',
    'fi',
    'da',
    'el',
    'uk',
    'he',
    'fa',
    'ms',
    'tl',
  };

  static const Map<String, String> _languageAliases = {
    'fil': 'tl',
    'nb': 'no',
    'nn': 'no',
    'zh-cn': 'zh',
    'zh-tw': 'zh',
    'zh-hans': 'zh',
    'zh-hant': 'zh',
  };

  static const Map<String, String> _genderMappings = {
    'f': 'female',
    'female': 'female',
    'm': 'male',
    'male': 'male',
    'o': 'non-binary',
    'other': 'non-binary',
    'non-binary': 'non-binary',
    'nonbinary': 'non-binary',
    'x': 'prefer-not-to-say',
    'prefer-not-to-say': 'prefer-not-to-say',
    'prefer_not_to_say': 'prefer-not-to-say',
    'private': 'prefer-not-to-say',
  };

  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/datastore',
    'https://www.googleapis.com/auth/firebase.database',
  ];

  static Future<protocol.LegacyMigrationData?> fetchForUser(
    Session session,
    String userId,
  ) async {
    if (session.server.runMode == 'test') {
      return null;
    }

    http.Client? client;
    try {
      client = await _authorizedClient();

      final firestoreData = await _fetchFirestoreUser(client, userId);
      if (firestoreData != null) {
        final migration = convertLegacyUserData(firestoreData);
        if (migration != null) return migration;
      }

      final realtimeData = await _fetchRealtimeDatabaseUser(client, userId);
      if (realtimeData != null) {
        return convertLegacyUserData(realtimeData);
      }
    } catch (e, stackTrace) {
      session.log(
        'Legacy migration fetch failed for $userId: $e',
        level: LogLevel.warning,
        exception: e,
        stackTrace: stackTrace,
      );
    } finally {
      client?.close();
    }

    return null;
  }

  static protocol.LegacyMigrationData? convertLegacyUserData(
    Map<String, dynamic> data,
  ) {
    final name = _cleanString(data['displayName']);
    final bio = _cleanString(data['description']);
    final avatar = _cleanString(data['photoURL']);
    final gender = _normalizeGender(data['gender']);
    final languages = _normalizeLanguages(data['languageCode']);
    final messageCount = _parseNonNegativeInt(data['messageCount']);
    final role = _normalizeRole(data['role']);

    final xp = messageCount == null
        ? null
        : messageCount * GamificationService.XP_PER_MESSAGE;
    final level = xp == null ? null : GamificationService.computeBaseFloor(xp);

    final migration = protocol.LegacyMigrationData(
      name: name,
      bio: bio,
      avatar: avatar,
      gender: gender,
      languages: languages,
      xp: xp,
      level: level,
      role: role,
    );

    final hasUsefulData =
        migration.name != null ||
        migration.bio != null ||
        migration.avatar != null ||
        migration.gender != null ||
        (migration.languages?.isNotEmpty ?? false) ||
        migration.xp != null ||
        migration.role != null;

    return hasUsefulData ? migration : null;
  }

  static Future<http.Client> _authorizedClient() async {
    final credentials = ServiceAccountCredentials.fromJson(
      jsonDecode(
            File('config/firebase_service_account_key.json').readAsStringSync(),
          )
          as Map<String, dynamic>,
    );

    return clientViaServiceAccount(credentials, _scopes);
  }

  static Future<Map<String, dynamic>?> _fetchFirestoreUser(
    http.Client client,
    String userId,
  ) async {
    final projectId = _projectId;
    final response = await client.get(
      Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$userId',
      ),
    );

    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Firestore lookup failed (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final fields = json['fields'];
    if (fields is! Map<String, dynamic>) return null;

    return fields.map(
      (key, value) => MapEntry(
        key,
        _decodeFirestoreValue(value as Map<String, dynamic>),
      ),
    );
  }

  static Future<Map<String, dynamic>?> _fetchRealtimeDatabaseUser(
    http.Client client,
    String userId,
  ) async {
    final response = await client.get(
      Uri.parse(
        'https://$_projectId-default-rtdb.firebaseio.com/users/$userId.json',
      ),
    );

    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Realtime Database lookup failed (${response.statusCode}): ${response.body}',
      );
    }

    if (response.body.trim() == 'null') return null;
    final json = jsonDecode(response.body);
    if (json is! Map) return null;
    return Map<String, dynamic>.from(json);
  }

  static dynamic _decodeFirestoreValue(Map<String, dynamic> value) {
    if (value.containsKey('nullValue')) return null;
    if (value.containsKey('stringValue')) return value['stringValue'] as String;
    if (value.containsKey('booleanValue')) return value['booleanValue'] as bool;
    if (value.containsKey('integerValue')) {
      return int.tryParse(value['integerValue'].toString());
    }
    if (value.containsKey('doubleValue')) {
      return (value['doubleValue'] as num).toDouble();
    }
    if (value.containsKey('timestampValue')) {
      return value['timestampValue'] as String;
    }
    if (value.containsKey('mapValue')) {
      final mapValue = value['mapValue'] as Map<String, dynamic>;
      final fields = mapValue['fields'];
      if (fields is! Map<String, dynamic>) return <String, dynamic>{};
      return fields.map(
        (key, nestedValue) => MapEntry(
          key,
          _decodeFirestoreValue(nestedValue as Map<String, dynamic>),
        ),
      );
    }
    if (value.containsKey('arrayValue')) {
      final arrayValue = value['arrayValue'] as Map<String, dynamic>;
      final values = arrayValue['values'];
      if (values is! List) return <dynamic>[];
      return values
          .map((entry) => _decodeFirestoreValue(entry as Map<String, dynamic>))
          .toList();
    }
    return null;
  }

  static String get _projectId {
    final serviceAccount =
        jsonDecode(
              File(
                'config/firebase_service_account_key.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    return serviceAccount['project_id'] as String;
  }

  static String? _cleanString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _normalizeGender(dynamic value) {
    final raw = _cleanString(value)?.toLowerCase();
    if (raw == null) return null;
    return _genderMappings[raw];
  }

  static List<String>? _normalizeLanguages(dynamic value) {
    final raw = _cleanString(value)?.toLowerCase();
    if (raw == null) return null;

    final canonical =
        _languageAliases[raw] ??
        _languageAliases[_primaryLanguage(raw)] ??
        _primaryLanguage(raw);
    final languages = <String>{'en'};
    if (_supportedLanguageCodes.contains(canonical)) {
      languages.add(canonical);
    }

    return languages.toList()..sort();
  }

  static String _primaryLanguage(String raw) {
    final normalized = raw.replaceAll('_', '-');
    return normalized.split('-').first;
  }

  static int? _parseNonNegativeInt(dynamic value) {
    if (value is int) return value < 0 ? 0 : value;
    if (value is num) return value.toInt().clamp(0, 1 << 31);
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed == null) return null;
      return parsed < 0 ? 0 : parsed;
    }
    return null;
  }

  static protocol.ResidentRole? _normalizeRole(dynamic value) {
    final raw = _cleanString(value)?.toLowerCase();
    switch (raw) {
      case 'admin':
        return protocol.ResidentRole.admin;
      case 'moderator':
        return protocol.ResidentRole.moderator;
      default:
        return null;
    }
  }
}
