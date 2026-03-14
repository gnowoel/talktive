import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/client_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_card.dart';
import 'package:talktive_flutter/helpers/duo_snackbar_helper.dart';

/// Analytics dashboard for admins
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final client = ref.read(clientProvider);
      final stats = await client.admin.getStatistics();

      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        DuoSnackBarHelper.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Analytics',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_stats != null) ...[
                    _buildTotalsSection(),
                    const SizedBox(height: 24),
                    _buildLast24hSection(),
                    const SizedBox(height: 24),
                    _buildLast7dSection(),
                    const SizedBox(height: 24),
                    _buildLast30dSection(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildTotalsSection() {
    final totals = _stats!['totals'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Total Counts',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                '👥',
                'Users',
                totals['users'].toString(),
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                '💬',
                'Messages',
                totals['messages'].toString(),
                AppTheme.accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                '📸',
                'Moments',
                totals['moments'].toString(),
                AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                '👥',
                'Groups',
                totals['groups'].toString(),
                AppTheme.duoOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                '⚠️',
                'Reports',
                totals['reports'].toString(),
                AppTheme.duoYellow,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                '🔔',
                'Pending',
                totals['pendingReports'].toString(),
                AppTheme.errorColor,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildLast24hSection() {
    final last24h = _stats!['last24h'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Last 24 Hours',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        DuoCard(
          child: Column(
            children: [
              _buildActivityRow(
                '💬',
                'Messages',
                last24h['messages'].toString(),
                AppTheme.accentColor,
              ),
              const Divider(height: 24),
              _buildActivityRow(
                '📸',
                'Moments',
                last24h['moments'].toString(),
                AppTheme.secondaryColor,
              ),
              const Divider(height: 24),
              _buildActivityRow(
                '⚠️',
                'Reports',
                last24h['reports'].toString(),
                AppTheme.duoYellow,
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildLast7dSection() {
    final last7d = _stats!['last7d'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Last 7 Days',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        DuoCard(
          child: Column(
            children: [
              _buildActivityRow(
                '💬',
                'Messages',
                last7d['messages'].toString(),
                AppTheme.accentColor,
              ),
              const Divider(height: 24),
              _buildActivityRow(
                '📸',
                'Moments',
                last7d['moments'].toString(),
                AppTheme.secondaryColor,
              ),
              const Divider(height: 24),
              _buildActivityRow(
                '👥',
                'Active Users',
                last7d['activeUsers'].toString(),
                AppTheme.primaryColor,
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildLast30dSection() {
    final last30d = _stats!['last30d'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Last 30 Days',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        DuoCard(
          child: Column(
            children: [
              _buildActivityRow(
                '💬',
                'Messages',
                last30d['messages'].toString(),
                AppTheme.accentColor,
              ),
              const Divider(height: 24),
              _buildActivityRow(
                '📸',
                'Moments',
                last30d['moments'].toString(),
                AppTheme.secondaryColor,
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildMetricCard(
    String emoji,
    String label,
    String value,
    Color color,
  ) {
    return DuoCard(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow(
    String emoji,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
