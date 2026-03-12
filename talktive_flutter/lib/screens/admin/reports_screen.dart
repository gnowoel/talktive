import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/client_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../widgets/duo/duo_button.dart';
import '../../helpers/snackbar_helper.dart';

/// Reports moderation screen for admins
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  ReportStatus _filterStatus = ReportStatus.pending;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final client = ref.read(clientProvider);
      final reports = _filterStatus == ReportStatus.pending
          ? await client.admin.getPendingReports(limit: 20, offset: 0)
          : await client.admin.getAllReports(
              status: _filterStatus,
              limit: 20,
              offset: 0,
            );

      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reports: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reports: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _resolveReport(int reportId, ReportStatus status) async {
    try {
      final client = ref.read(clientProvider);
      await client.admin.resolveReport(reportId: reportId, status: status);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == ReportStatus.approved
                  ? 'Report approved'
                  : 'Report rejected',
            ),
            backgroundColor: AppTheme.duoGreen,
          ),
        );
        _loadReports();
      }
    } catch (e) {
      debugPrint('Error resolving report: $e');
      if (mounted) {
        SnackBarHelper.showError(context, e);
      }
    }
  }

  Future<void> _showReportDetails(Map<String, dynamic> reportData) async {
    final report = Report.fromJson(
      reportData['report'] as Map<String, dynamic>,
    );
    final reporter = reportData['reporter'] as Map<String, dynamic>;
    final target = reportData['target'] as Map<String, dynamic>;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Report Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildDetailSection('Reporter', [
                    'Name: ${reporter['userName']}',
                    'Floor: ${reporter['floor']}',
                  ]),
                  const SizedBox(height: 20),

                  _buildDetailSection('Target User', [
                    'Name: ${target['userName']}',
                    'Floor: ${target['floor']}',
                    'Reputation: ${target['floor'] ?? target['trustScore'] ?? 0}',
                  ]),
                  const SizedBox(height: 20),

                  _buildDetailSection('Report Info', [
                    'Reason: ${report.reason}',
                    'Status: ${report.status.name}',
                    'Created: ${_formatDate(report.createdAt)}',
                    if (report.channelId != null)
                      'Channel ID: ${report.channelId}',
                    if (report.messageId != null)
                      'Message ID: ${report.messageId}',
                  ]),

                  if (report.status == ReportStatus.pending) ...[
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: DuoButton(
                            text: 'Reject',
                            onPressed: () {
                              Navigator.pop(context);
                              _resolveReport(report.id!, ReportStatus.rejected);
                            },
                            variant: DuoButtonVariant.secondary,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DuoButton(
                            text: 'Approve & Take Action',
                            onPressed: () {
                              Navigator.pop(context);
                              _resolveReport(report.id!, ReportStatus.approved);
                            },
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
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
          'Reports',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Pending', ReportStatus.pending),
                const SizedBox(width: 8),
                _buildFilterChip('Approved', ReportStatus.approved),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', ReportStatus.rejected),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
          ? DuoEmptyState(
              emoji: '✅',
              title: 'No reports',
              subtitle: _filterStatus == ReportStatus.pending
                  ? 'All caught up!'
                  : 'No ${_filterStatus.name} reports',
            )
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _reports.length,
                itemBuilder: (context, index) {
                  return _buildReportCard(_reports[index])
                      .animate(delay: Duration(milliseconds: index * 50))
                      .fadeIn()
                      .slideX(begin: -0.1, end: 0);
                },
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label, ReportStatus status) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _filterStatus = status;
        });
        _loadReports();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> reportData) {
    final report = Report.fromJson(
      reportData['report'] as Map<String, dynamic>,
    );
    final reporter = reportData['reporter'] as Map<String, dynamic>;
    final target = reportData['target'] as Map<String, dynamic>;

    return DuoCard(
      onTap: () {
        HapticFeedback.lightImpact();
        _showReportDetails(reportData);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(report.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(report.status),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(report.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            'Reason: ${report.reason}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Text(
                'Reporter: ',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              Text(
                '${reporter['userName']} (Floor ${reporter['floor']})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Row(
            children: [
              const Text(
                'Target: ',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              Text(
                '${target['userName']} (Floor ${target['floor']})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),

          if (report.status == ReportStatus.pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DuoButton(
                    text: 'Reject',
                    onPressed: () =>
                        _resolveReport(report.id!, ReportStatus.rejected),
                    variant: DuoButtonVariant.secondary,
                    size: DuoButtonSize.small,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DuoButton(
                    text: 'Approve',
                    onPressed: () =>
                        _resolveReport(report.id!, ReportStatus.approved),
                    size: DuoButtonSize.small,
                    color: AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return AppTheme.duoYellow;
      case ReportStatus.approved:
        return AppTheme.errorColor;
      case ReportStatus.rejected:
        return AppTheme.textSecondary;
    }
  }
}
