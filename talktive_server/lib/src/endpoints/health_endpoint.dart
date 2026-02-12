import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart' as protocol;

/// Health check endpoint for monitoring and load balancers
class HealthEndpoint extends Endpoint {
  /// Basic health check - returns 200 OK if server is running
  Future<Map<String, dynamic>> check(Session session) async {
    return {
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }

  /// Detailed health check - includes database and Redis status
  Future<Map<String, dynamic>> detailed(Session session) async {
    final checks = <String, dynamic>{
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'checks': {},
    };

    // Check database connection
    try {
      await session.db.unsafeQuery('SELECT 1');
      checks['checks']['database'] = {
        'status': 'healthy',
        'message': 'Database connection successful',
      };
    } catch (e) {
      checks['status'] = 'unhealthy';
      checks['checks']['database'] = {
        'status': 'unhealthy',
        'message': 'Database connection failed: $e',
      };
    }

    // Check Redis connection via Global Cache
    try {
      await session.caches.global.put(
        'health_check',
        protocol.CacheString(value: 'ok'),
      );
      final value =
          await session.caches.global.get('health_check')
              as protocol.CacheString?;

      if (value?.value == 'ok') {
        checks['checks']['redis'] = {
          'status': 'healthy',
          'message': 'Redis connection successful',
        };
      } else {
        checks['status'] = 'unhealthy';
        checks['checks']['redis'] = {
          'status': 'unhealthy',
          'message': 'Redis read/write failed',
        };
      }
    } catch (e) {
      checks['status'] = 'unhealthy';
      checks['checks']['redis'] = {
        'status': 'unhealthy',
        'message': 'Redis connection failed: $e',
      };
    }

    return checks;
  }

  /// Readiness check - returns 200 when server is ready to accept traffic
  Future<Map<String, dynamic>> ready(Session session) async {
    try {
      // Test database
      await session.db.unsafeQuery('SELECT 1');

      // Test Redis
      await session.caches.global.put(
        'ready_check',
        protocol.CacheString(value: 'ok'),
        lifetime: Duration(seconds: 1),
      );

      return {
        'status': 'ready',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'not_ready',
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  /// Liveness check - returns 200 if server process is alive
  Future<Map<String, dynamic>> live(Session session) async {
    return {
      'status': 'alive',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Metrics endpoint - returns basic server metrics
  Future<Map<String, dynamic>> metrics(Session session) async {
    try {
      // Get database stats
      final dbStats = await session.db.unsafeQuery(
        'SELECT count(*) as total_connections FROM pg_stat_activity',
      );

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'database': {
          'connections': dbStats
              .first
              .first, // unsafeQuery returns List<List<dynamic>> and first row first col is counts
        },
        'server': {
          'uptime': DateTime.now().difference(DateTime(2024, 1, 1)).inSeconds,
        },
      };
    } catch (e) {
      session.log('Metrics error: $e', level: LogLevel.warning);
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'error': 'Failed to collect metrics',
      };
    }
  }
}
