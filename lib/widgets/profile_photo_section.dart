import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soaksafe/core/constants/app_strings.dart';
import 'package:soaksafe/core/theme/soaksafe_colors.dart';

class ProfilePhotoSection extends StatefulWidget {
  const ProfilePhotoSection({
    super.key,
    this.initialFile,
    this.onChanged,
  });

  final File? initialFile;
  final void Function(File? previewFile, bool removeExisting)? onChanged;

  @override
  State<ProfilePhotoSection> createState() => _ProfilePhotoSectionState();
}

class _ProfilePhotoSectionState extends State<ProfilePhotoSection> {
  File? _preview;
  bool _removeExisting = false;

  bool get _hasPhoto => !_removeExisting && (_preview != null || widget.initialFile != null);

  File? get _displayFile =>
      _removeExisting ? null : (_preview ?? widget.initialFile);

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 88,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _preview = File(picked.path);
      _removeExisting = false;
    });
    widget.onChanged?.call(_preview, false);
  }

  void _removePhoto() {
    setState(() {
      _preview = null;
      _removeExisting = true;
    });
    widget.onChanged?.call(null, true);
  }

  @override
  Widget build(BuildContext context) {
    final file = _displayFile;
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: SoakSafeColors.frostedOutline,
          backgroundImage: file != null ? FileImage(file) : null,
          child: file == null
              ? const Icon(Icons.person, size: 48, color: SoakSafeColors.homeFormOnSurfaceVariant)
              : null,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _pickPhoto,
          child: Text(_hasPhoto ? AppStrings.profilePhotoChange : AppStrings.profilePhotoAdd),
        ),
        if (_hasPhoto)
          TextButton(
            onPressed: _removePhoto,
            child: const Text(AppStrings.profilePhotoRemove),
          ),
      ],
    );
  }
}
