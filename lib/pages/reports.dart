import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/report.dart';
import '../../services/firedata.dart';
import '../../widgets/layout.dart';
import '../services/message_cache.dart';
import '../widgets/report_details_dialog.dart';
import '../widgets/report_item.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late Firedata firedata;
  late ReportMessageCache reportMessageCache;
  late StreamSubscription<List<Report>> _reportsSubscription;
  List<Report> _reports = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_reports.isEmpty) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surfaceContainerLow,
          title: const Text('Reports'),
        ),
        body: const SafeArea(child: Center(child: Text('(Empty)'))),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: Text('Reports (${_reports.length})'),
      ),
      body: SafeArea(
        child: Layout(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _reports.length,
            itemBuilder: (context, index) {
              final report = _reports[index];
              return ReportItem(
                report: report,
                onTap: () => _showReportDetails(report),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reportsSubscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    firedata = context.read<Firedata>();
    reportMessageCache = context.read<ReportMessageCache>();

    _reportsSubscription = firedata.subscribeToReports().listen((reports) {
      if (!mounted) return;

      setState(() {
        _reports = reports;
      });

      final activeChatIds = reports
          .where((report) => report.isActive)
          .map((report) => report.chatId)
          .toList();

      reportMessageCache.cleanup(activeChatIds);
    });
  }

  void _showReportDetails(Report report) {
    showDialog(
      context: context,
      builder: (context) => ReportDetailsDialog(report: report),
    );
  }
}
