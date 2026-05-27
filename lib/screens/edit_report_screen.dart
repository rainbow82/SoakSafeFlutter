import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:soaksafe/app_state.dart';
import 'package:soaksafe/core/constants/app_strings.dart';
import 'package:soaksafe/core/models/models.dart';
import 'package:soaksafe/core/theme/soaksafe_colors.dart';
import 'package:soaksafe/core/utils/codecs.dart';
import 'package:soaksafe/data/maintenance_repository.dart';
import 'package:soaksafe/widgets/frosted_card.dart';
import 'package:soaksafe/widgets/pool_background.dart';
import 'package:soaksafe/widgets/soaksafe_buttons.dart';

class EditReportScreen extends StatefulWidget {
  const EditReportScreen({super.key, required this.eventId});

  final int eventId;

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  MaintenanceEventRecord? _event;
  List<EventLineItem> _lines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final app = context.read<AppState>();
    final userId = app.currentUserId;
    if (userId == null) return;
    final event = await context.read<MaintenanceRepository>().eventById(widget.eventId, userId);
    if (!mounted) return;
    setState(() {
      _event = event;
      _lines = event == null ? [] : LineItemsCodec.resolveLineItems(event);
      _loading = false;
    });
  }

  Future<void> _save() async {
    final event = _event;
    if (event == null) return;
    LineItemsCodec.applyLinesToEvent(event, _lines);
    await context.read<MaintenanceRepository>().updateEvent(event);
    if (mounted) context.pop();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SoakSafeColors.dialogSurface,
        title: const Text(AppStrings.deleteReport, style: TextStyle(color: SoakSafeColors.maintTextPrimary)),
        content: const Text(
          AppStrings.deleteReportConfirm,
          style: TextStyle(color: SoakSafeColors.maintTextPrimary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    final app = context.read<AppState>();
    await context.read<MaintenanceRepository>().deleteEvent(widget.eventId, app.currentUserId!);
    if (mounted) context.pop();
  }

  void _addLine() {
    setState(() => _lines.add(const EventLineItem('', null)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
                    const Text(
                      AppStrings.editReportTitle,
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: FrostedCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < _lines.length; i++)
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: _lines[i].label,
                                  decoration: const InputDecoration(labelText: 'Item'),
                                  onChanged: (v) => _lines[i] = EventLineItem(v, _lines[i].amount),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: _lines[i].amount?.toString() ?? '',
                                  decoration: const InputDecoration(labelText: 'Amt'),
                                  onChanged: (v) {
                                    final amt = double.tryParse(v.trim());
                                    _lines[i] = EventLineItem(_lines[i].label, amt);
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => setState(() => _lines.removeAt(i)),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        SaveButton(label: AppStrings.saveMaintenance, onPressed: _save),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _confirmDelete,
                          child: const Text(AppStrings.deleteReport),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: AddFab(onPressed: _addLine),
    );
  }
}
