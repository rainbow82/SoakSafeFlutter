import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:soaksafe/app_state.dart';
import 'package:soaksafe/core/constants/app_strings.dart';
import 'package:soaksafe/core/services/profile_image_store.dart';
import 'package:soaksafe/core/theme/soaksafe_colors.dart';
import 'package:soaksafe/data/user_repository.dart';
import 'package:soaksafe/widgets/frosted_card.dart';
import 'package:soaksafe/widgets/pool_background.dart';
import 'package:soaksafe/widgets/profile_photo_section.dart';
import 'package:soaksafe/widgets/soaksafe_buttons.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _username = TextEditingController();
  final _poolSize = TextEditingController();
  bool _saltWater = false;
  bool _aboveGround = false;
  bool _loading = true;
  File? _existingPhoto;
  File? _pendingPhoto;
  bool _removePhoto = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final app = context.read<AppState>();
    final userId = app.currentUserId;
    if (userId == null) return;
    final user = await context.read<UserRepository>().userById(userId);
    File? photo;
    if (await ProfileImageStore.hasImage(userId)) {
      photo = await ProfileImageStore.imageFile(userId);
    }
    if (user == null || !mounted) return;
    setState(() {
      _username.text = user.username;
      _poolSize.text = user.poolSizeGallons.toString();
      _saltWater = user.poolSaltWater;
      _aboveGround = user.poolAboveGround;
      _existingPhoto = photo;
      _loading = false;
    });
  }

  void _onPhotoChanged(File? preview, bool removeExisting) {
    setState(() {
      _pendingPhoto = preview;
      _removePhoto = removeExisting;
    });
  }

  Future<bool> _savePhoto(int userId) async {
    if (_removePhoto) {
      await ProfileImageStore.delete(userId);
      return true;
    }
    if (_pendingPhoto == null) return true;
    final ok = await ProfileImageStore.saveFromPicker(userId, XFile(_pendingPhoto!.path));
    if (!ok && mounted) {
      _snack(AppStrings.profilePhotoSaveFailed);
    }
    return ok;
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    final userId = app.currentUserId;
    if (userId == null) return;
    final size = int.tryParse(_poolSize.text.trim()) ?? 0;
    final (result, updated) = await context.read<UserRepository>().updateProfile(
          userId: userId,
          username: _username.text,
          poolSizeGallons: size,
          poolSaltWater: _saltWater,
          poolAboveGround: _aboveGround,
        );
    if (!mounted) return;
    if (result != UpdateProfileResult.success || updated == null) {
      if (result == UpdateProfileResult.invalidPoolSize) {
        _snack(AppStrings.errorPoolSize);
      } else if (result == UpdateProfileResult.usernameTaken) {
        _snack(AppStrings.errorUsernameTaken);
      }
      return;
    }
    if (!await _savePhoto(userId)) return;
    final enrollment = await app.sessionService.biometricEnrollment();
    if (enrollment != null && enrollment.userId == userId) {
      await app.sessionService.saveBiometricEnrollment(
        userId: updated.id,
        username: updated.username,
      );
    }
    await app.setSession(updated.id, updated.username);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.profileSaved)),
    );
    context.pop(true);
  }

  Future<void> _logout() async {
    final app = context.read<AppState>();
    await app.clearSession();
    if (context.mounted) context.go('/');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
                      AppStrings.profileTitle,
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ProfilePhotoSection(
                          initialFile: _existingPhoto,
                          onChanged: _onPhotoChanged,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _username,
                          decoration: const InputDecoration(
                            labelText: 'Username',
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
                        const SizedBox(height: 16),
                        const Text('Installation', style: TextStyle(fontWeight: FontWeight.w600)),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: true, label: Text(AppStrings.poolAboveGround)),
                            ButtonSegment(value: false, label: Text(AppStrings.poolInGround)),
                          ],
                          selected: {_aboveGround},
                          onSelectionChanged: (s) => setState(() => _aboveGround = s.first),
                        ),
                        const SizedBox(height: 16),
                        const Text('Pool type', style: TextStyle(fontWeight: FontWeight.w600)),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text(AppStrings.poolTypeFresh)),
                            ButtonSegment(value: true, label: Text(AppStrings.poolTypeSalt)),
                          ],
                          selected: {_saltWater},
                          onSelectionChanged: (s) => setState(() => _saltWater = s.first),
                        ),
                        const SizedBox(height: 24),
                        SaveButton(label: AppStrings.saveProfile, onPressed: _save),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _logout,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SoakSafeColors.homeFormOnSurface,
                            side: const BorderSide(color: SoakSafeColors.homeInputOutline),
                          ),
                          child: const Text(AppStrings.logout),
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
    );
  }
}
