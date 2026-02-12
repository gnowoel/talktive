import 'package:serverpod/serverpod.dart';

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
      await session.db.query('SELECT 1');
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

    // Check Redis connection
    try {
      await session.redis.set('health_check', 'ok');
      final value = await session.redis.get('health_check');
      if (value == 'ok') {
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
    // Check if migrations are up to date
    // Check if critical services are available
    // This is a simplified version - expand based on your needs

    try {
      // Test database
      await session.db.query('SELECT 1');

      // Test Redis
      await session.redis.ping();

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
      final dbStats = await session.db.query(
        'SELECT count(*) as total_connections FROM pg_stat_activity',
      );

      // Get Redis stats
      final redisInfo = await session.redis.info();

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'database': {
          'connections': dbStats.first.toColumnMap()['total_connections'],
        },
        'redis': {
          'connected': redisInfo.isNotEmpty,
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
