import 'package:flutter/material.dart';
import 'package:soaksafe/core/theme/soaksafe_colors.dart';

class FrostedCard extends StatelessWidget {
  const FrostedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.margin,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SoakSafeColors.frostedOutline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: SoakSafeColors.frostedSurface,
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
