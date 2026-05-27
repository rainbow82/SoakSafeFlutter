import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:soaksafe/app_state.dart';
import 'package:soaksafe/core/constants/app_strings.dart';
import 'package:soaksafe/core/models/models.dart';
import 'package:soaksafe/core/theme/soaksafe_colors.dart';
import 'package:soaksafe/core/utils/codecs.dart';
import 'package:soaksafe/data/maintenance_repository.dart';
import 'package:soaksafe/data/user_repository.dart';
import 'package:soaksafe/report/maintenance_pdf_report.dart';
import 'package:soaksafe/widgets/frosted_card.dart';
import 'package:soaksafe/widgets/pool_background.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, this.exportOnOpen = false});

  final bool exportOnOpen;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const _pdfFileName = 'SoakSafe_maintenance_report.pdf';

  List<MaintenanceEventRecord> _events = [];
  String _query = '';
  bool _loading = true;
  bool _exporting = false;
  bool _exportOnOpenHandled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AppState>().currentUserId;
    if (userId == null) return;
    final events = await context.read<MaintenanceRepository>().loadEvents(userId);
    if (!mounted) return;
    setState(() {
      _events = events;
      _loading = false;
    });
    if (widget.exportOnOpen && !_exportOnOpenHandled) {
      _exportOnOpenHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _exportMaintenancePdf();
      });
    }
  }

  List<MaintenanceEventRecord> get _filtered {
    if (_query.trim().isEmpty) return _events;
    final q = _query.toLowerCase();
    return _events.where((e) {
      final hay = StringBuffer()..write(e.eventType.toLowerCase());
      for (final item in LineItemsCodec.resolveLineItems(e)) {
        hay.write(' ${item.label.toLowerCase()}');
        if (item.amount != null) hay.write(' ${item.amount}');
      }
      return hay.toString().contains(q);
    }).toList();
  }

  Future<void> _exportMaintenancePdf() async {
    if (_exporting) return;
    if (_events.isEmpty) {
      _snack(AppStrings.pdfExportNoData);
      return;
    }

    setState(() => _exporting = true);
    try {
      final app = context.read<AppState>();
      final userId = app.currentUserId;
      if (userId == null) return;

      final user = await context.read<UserRepository>().userById(userId);
      final owner = (user?.fullName.trim().isNotEmpty ?? false)
          ? user!.fullName.trim()
          : AppStrings.pdfOwnerFallback;
      final ownerLine = AppStrings.pdfReportOwnerLine(owner);

      final bytes = await MaintenancePdfReport.build(
        events: List<MaintenanceEventRecord>.from(_events),
        ownerLine: ownerLine,
      );
      if (!mounted) return;
      await _showPdfReadyDialog(bytes);
    } catch (_) {
      if (mounted) _snack(AppStrings.pdfExportFailed);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _showPdfReadyDialog(Uint8List bytes) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: SoakSafeColors.dialogSurface,
        title: const Text(AppStrings.pdfExportReadyTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _sharePdf(bytes);
              },
              child: const Text(AppStrings.pdfActionShare),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _savePdf(bytes);
              },
              child: const Text(AppStrings.pdfActionSave),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sharePdf(Uint8List bytes) async {
    final xFile = XFile.fromData(
      bytes,
      mimeType: 'application/pdf',
      name: _pdfFileName,
    );
    await Share.shareXFiles(
      [xFile],
      subject: AppStrings.pdfShareSubject,
      text: AppStrings.pdfShareBody,
    );
  }

  Future<void> _savePdf(Uint8List bytes) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: AppStrings.pdfActionSave,
      fileName: _pdfFileName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: bytes,
    );
    if (!mounted) return;
    if (path != null && path.isNotEmpty) {
      _snack(AppStrings.pdfSaved);
      return;
    }
    if (Platform.isIOS || Platform.isAndroid) {
      // Some mobile save flows return null when the user cancels.
      return;
    }
    _snack(AppStrings.pdfExportFailed);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PoolBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Text(
                        AppStrings.maintenanceReportTitle,
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (!_loading && _events.isNotEmpty)
                      IconButton(
                        icon: _exporting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
                        tooltip: AppStrings.pdfExportMenu,
                        onPressed: _exporting ? null : _exportMaintenancePdf,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: SoakSafeColors.frostedSurface,
                    hintText: 'Search tasks and chemicals',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filtered.isEmpty
                        ? const Center(
                            child: Text(
                              AppStrings.reportNoEvents,
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              final event = _filtered[index];
                              final when = DateFormat('MM/dd/yyyy hh:mm a').format(
                                DateTime.fromMillisecondsSinceEpoch(event.eventTimeMillis),
                              );
                              final lines = LineItemsCodec.resolveLineItems(event);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: FrostedCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(when, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                const Text(AppStrings.reportCardSubtitle),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () => context.push('/report/${event.id}/edit'),
                                          ),
                                        ],
                                      ),
                                      for (final line in lines)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            line.amount == null
                                                ? '✓ ${line.label}'
                                                : '${line.label}: ${line.amount!.toStringAsFixed(2)}',
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
