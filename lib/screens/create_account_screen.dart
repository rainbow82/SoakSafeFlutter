import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:soaksafe/core/constants/app_strings.dart';
import 'package:soaksafe/core/services/profile_image_store.dart';
import 'package:soaksafe/core/theme/soaksafe_colors.dart';
import 'package:soaksafe/data/user_repository.dart';
import 'package:soaksafe/widgets/frosted_card.dart';
import 'package:soaksafe/widgets/pool_background.dart';
import 'package:soaksafe/widgets/profile_photo_section.dart';
import 'package:soaksafe/widgets/soaksafe_buttons.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _poolSize = TextEditingController();
  final _hotTubSize = TextEditingController();
  bool _saltWater = false;
  bool _hotTubSaltWater = false;
  File? _pendingPhoto;

  Future<void> _save() async {
    final repo = context.read<UserRepository>();
    final size = int.tryParse(_poolSize.text.trim()) ?? 0;
    final hotTubSize = int.tryParse(_hotTubSize.text.trim()) ?? 0;
    final poolGallons = size < 0 ? 0 : size;
    final hotTubGallons = hotTubSize < 0 ? 0 : hotTubSize;
    if (poolGallons <= 0 && hotTubGallons <= 0) {
      _snack(AppStrings.errorNoWaterBody);
      return;
    }
    final (result, user) = await repo.registerUser(
      fullName: _fullName.text,
      username: _username.text,
      password: _password.text,
      poolSizeGallons: poolGallons,
      poolSaltWater: _saltWater,
      hotTubSizeGallons: hotTubGallons,
      hotTubSaltWater: _hotTubSaltWater,
    );
    if (!mounted) return;
    switch (result) {
      case RegisterResult.emptyFields:
        _snack(AppStrings.errorCreateEmpty);
      case RegisterResult.usernameTaken:
        _snack(AppStrings.errorUsernameTaken);
      case RegisterResult.success:
        if (user != null && _pendingPhoto != null) {
          final saved = await ProfileImageStore.saveFromPicker(
            user.id,
            XFile(_pendingPhoto!.path),
          );
          if (!saved && mounted) {
            _snack(AppStrings.profilePhotoSaveFailed);
          }
        }
        if (mounted) context.pop(true);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  ButtonStyle get _waterTypeStyle => ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SoakSafeColors.saveButton;
          }
          return null;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SoakSafeColors.saveButtonText;
          }
          return null;
        }),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PoolBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: FrostedCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Create account',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: SoakSafeColors.homeFormOnSurface,
                              ),
                        ),
                        const SizedBox(height: 16),
                        ProfilePhotoSection(
                          onChanged: (file, _) => setState(() => _pendingPhoto = file),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _fullName,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _username,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _poolSize,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: AppStrings.poolSizeLabel,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _hotTubSize,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: AppStrings.hotTubSizeLabel,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Pool type', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        SegmentedButton<bool>(
                          style: _waterTypeStyle,
                          segments: const [
                            ButtonSegment(value: false, label: Text(AppStrings.poolTypeFresh)),
                            ButtonSegment(value: true, label: Text(AppStrings.poolTypeSalt)),
                          ],
                          selected: {_saltWater},
                          onSelectionChanged: (s) => setState(() => _saltWater = s.first),
                        ),
                        const SizedBox(height: 16),
                        const Text('Hot tub type', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        SegmentedButton<bool>(
                          style: _waterTypeStyle,
                          segments: const [
                            ButtonSegment(value: false, label: Text(AppStrings.poolTypeFresh)),
                            ButtonSegment(value: true, label: Text(AppStrings.poolTypeSalt)),
                          ],
                          selected: {_hotTubSaltWater},
                          onSelectionChanged: (s) =>
                              setState(() => _hotTubSaltWater = s.first),
                        ),
                        const SizedBox(height: 24),
                        SaveButton(label: AppStrings.saveAccount, onPressed: _save),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
