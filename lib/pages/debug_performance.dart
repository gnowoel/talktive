import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/performance_monitor.dart';
import '../services/cache/sqlite_message_cache.dart';
import '../services/paginated_message_service.dart';
import '../services/service_locator.dart';

class DebugPerformancePage extends StatefulWidget {
  const DebugPerformancePage({super.key});

  @override
  State<DebugPerformancePage> createState() => _DebugPerformancePageState();
}

class _DebugPerformancePageState extends State<DebugPerformancePage> {
  late PerformanceMonitor _perfMonitor;
  late SqliteMessageCache _cache;
  late PaginatedMessageService _messageService;

  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _memoryStats = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _perfMonitor = PerformanceMonitor.instance;
    _loadStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cache = Provider.of<SqliteMessageCache>(context);
    _messageService = Provider.of<PaginatedMessageService>(context);
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final serviceStats = await ServiceLocator.instance.getMemoryStats();
      final perfReport = _perfMonitor.generateReport();
      final memoryInfo = await _perfMonitor.getCurrentMemoryUsage();

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
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading stats: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearCache() async {
    try {
      await ServiceLocator.instance.clearAllCache();
      _perfMonitor.clear();
      await _loadStats();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing cache: $e')),
      );
    }
  }

  Future<void> _runMaintenance() async {
    try {
      await ServiceLocator.instance.performMaintenance();
      await _loadStats();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maintenance completed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error running maintenance: $e')),
      );
    }
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
                  icon: const Icon(Icons.refresh, size: 16),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final data = _perfMonitor.exportData();
      final jsonString = data.toString();

      // In a real app, you'd save this to a file or share it
      // For now, we'll just show it in a dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Performance Data'),
          content: SingleChildScrollView(
            child: Text(
              jsonString,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting data: $e')),
      );
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
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Performance monitoring is ${_perfMonitor.isInitialized ? 'active' : 'inactive'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _perfMonitor.isInitialized
                                ? Colors.green
                                : Colors.red,
                          ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
