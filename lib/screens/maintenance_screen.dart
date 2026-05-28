import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:soaksafe/app_state.dart';
import 'package:soaksafe/core/constants/app_strings.dart';
import 'package:soaksafe/core/services/profile_image_store.dart';
import 'package:soaksafe/core/models/models.dart';
import 'package:soaksafe/core/theme/soaksafe_colors.dart';
import 'package:soaksafe/core/utils/codecs.dart';
import 'package:soaksafe/data/maintenance_repository.dart';
import 'package:soaksafe/widgets/frosted_card.dart';
import 'package:soaksafe/widgets/pool_background.dart';
import 'package:soaksafe/widgets/soaksafe_buttons.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  ChecklistRecord? _checklist;
  List<CustomLineEntry> _customLines = [];
  bool _loading = true;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _loadProfileImage(int userId) async {
    if (await ProfileImageStore.hasImage(userId)) {
      final file = await ProfileImageStore.imageFile(userId);
      if (mounted) setState(() => _profileImage = file);
    } else if (mounted) {
      setState(() => _profileImage = null);
    }
  }

  Future<void> _load() async {
    final app = context.read<AppState>();
    final userId = app.currentUserId;
    if (userId == null) return;
    final repo = context.read<MaintenanceRepository>();
    await repo.ensureTodayDate(userId);
    final checklist = await repo.loadChecklist(userId);
    if (!mounted) return;
    setState(() {
      _checklist = checklist;
      _customLines = CustomLinesCodec.decode(checklist.customLinesJson);
      _loading = false;
    });
    await _loadProfileImage(userId);
  }

  Future<void> _logout() async {
    final app = context.read<AppState>();
    await app.clearSession();
    if (context.mounted) context.go('/');
  }

  Future<void> _openProfile() async {
    final updated = await context.push<bool>('/profile');
    if (updated == true && mounted) {
      final userId = context.read<AppState>().currentUserId;
      if (userId != null) await _loadProfileImage(userId);
    }
  }

  Widget _profileMenuIcon() {
    final image = _profileImage;
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.white24,
      backgroundImage: image != null ? FileImage(image) : null,
      child: image == null
          ? const Icon(Icons.person, color: Colors.white, size: 22)
          : null,
    );
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    final userId = app.currentUserId;
    final checklist = _checklist;
    if (userId == null || checklist == null) return;
    checklist.customLinesJson = CustomLinesCodec.encode(_customLines);
    await context.read<MaintenanceRepository>().saveFullChecklist(userId, checklist);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.maintenanceSaved)),
      );
    }
  }

  Future<void> _setChemical(String label, void Function(double) setter) async {
    final controller = TextEditingController();
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SoakSafeColors.dialogSurface,
        title: Text(label, style: const TextStyle(color: SoakSafeColors.maintTextPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              if (parsed == null || parsed <= 0) return;
              Navigator.pop(ctx, parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null) setState(() => setter(value));
  }

  Future<void> _addCustomItem() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SoakSafeColors.dialogSurface,
        title: const Text('Add item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (added == true) {
      final amount = double.tryParse(amountController.text.trim());
      setState(() {
        _customLines.add(
          CustomLineEntry(
            label: nameController.text.trim(),
            selected: true,
            amount: amount,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _checklist == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final c = _checklist!;
    final date = DateFormat('MM/dd/yyyy').format(DateTime.now());

    return Scaffold(
      body: PoolBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Text(
                      AppStrings.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      tooltip: AppStrings.menuProfile,
                      offset: const Offset(0, 48),
                      onSelected: (value) {
                        if (value == 'profile') {
                          _openProfile();
                        } else if (value == 'logout') {
                          _logout();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'profile',
                          child: Text(AppStrings.menuProfile),
                        ),
                        PopupMenuItem(
                          value: 'logout',
                          child: Text(AppStrings.logout),
                        ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _profileMenuIcon(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          date,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      FrostedCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(AppStrings.sectionTasks, style: TextStyle(fontWeight: FontWeight.bold)),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(AppStrings.taskVacuum),
                              value: c.vacuum,
                              checkColor: SoakSafeColors.saveButtonText,
                              activeColor: SoakSafeColors.checkboxChecked,
                              onChanged: (v) => setState(() => c.vacuum = v ?? false),
                            ),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(AppStrings.taskCleanSkimmer),
                              value: c.cleanSkimmer,
                              checkColor: SoakSafeColors.saveButtonText,
                              activeColor: SoakSafeColors.checkboxChecked,
                              onChanged: (v) => setState(() => c.cleanSkimmer = v ?? false),
                            ),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(AppStrings.taskAddWater),
                              value: c.addWater,
                              checkColor: SoakSafeColors.saveButtonText,
                              activeColor: SoakSafeColors.checkboxChecked,
                              onChanged: (v) => setState(() => c.addWater = v ?? false),
                            ),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(AppStrings.taskBrushWalls),
                              value: c.brushWalls,
                              checkColor: SoakSafeColors.saveButtonText,
                              activeColor: SoakSafeColors.checkboxChecked,
                              onChanged: (v) => setState(() => c.brushWalls = v ?? false),
                            ),
                            const SizedBox(height: 12),
                            const Text(AppStrings.sectionChemicals, style: TextStyle(fontWeight: FontWeight.bold)),
                            _chemicalTile(AppStrings.chemicalChlorine, c.chlorine, (v) => c.chlorine = v),
                            _chemicalTile(AppStrings.chemicalPhUp, c.phUp, (v) => c.phUp = v),
                            _chemicalTile(AppStrings.chemicalPhDown, c.phDown, (v) => c.phDown = v),
                            _chemicalTile(AppStrings.chemicalNoPhos, c.noPhos, (v) => c.noPhos = v),
                            for (final custom in _customLines)
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(custom.amount != null
                                    ? '${custom.label} · ${custom.amount}'
                                    : custom.label),
                                value: custom.selected,
                                onChanged: (v) => setState(() {
                                  final i = _customLines.indexOf(custom);
                                  _customLines[i] = CustomLineEntry(
                                    label: custom.label,
                                    selected: v ?? false,
                                    amount: custom.amount,
                                  );
                                }),
                              ),
                            const SizedBox(height: 16),
                            SaveButton(label: AppStrings.saveMaintenance, onPressed: _save),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: AddFab(onPressed: _addCustomItem),
      bottomNavigationBar: Container(
        color: SoakSafeColors.bottomBarBg,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => context.push('/report'),
            ),
            IconButton(
              icon: const Icon(Icons.description_outlined),
              onPressed: () => context.push('/report'),
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => context.push('/report?export=1'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chemicalTile(String label, double value, ValueChanged<double> onSet) {
    final subtitle = value > 0 ? value.toStringAsFixed(2) : 'Tap to set';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _setChemical(label, onSet),
    );
  }
}
