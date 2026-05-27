import 'package:flutter/material.dart';
import 'package:soaksafe/core/theme/soaksafe_colors.dart';

class SaveButton extends StatelessWidget {
  const SaveButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: SoakSafeColors.saveButton,
          foregroundColor: SoakSafeColors.saveButtonText,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(label),
      ),
    );
  }
}

class OutlinedPrimaryButton extends StatelessWidget {
  const OutlinedPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, color: SoakSafeColors.homeFormOnSurface) : const SizedBox.shrink(),
        label: Text(label, style: const TextStyle(color: SoakSafeColors.homeFormOnSurface)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: SoakSafeColors.homePrimary),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class AddFab extends StatelessWidget {
  const AddFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: SoakSafeColors.saveButton,
      foregroundColor: SoakSafeColors.saveButtonText,
      child: const Icon(Icons.add),
    );
  }
}
