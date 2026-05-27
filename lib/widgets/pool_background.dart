import 'package:flutter/material.dart';
import 'package:soaksafe/core/theme/soaksafe_colors.dart';

class PoolBackground extends StatelessWidget {
  const PoolBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/bg_home_pool.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: SoakSafeColors.homePrimary),
        ),
        Container(color: SoakSafeColors.scrim),
        child,
      ],
    );
  }
}
