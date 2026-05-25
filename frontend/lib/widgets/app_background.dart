import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AppBackground extends StatelessWidget {
  final Widget? child;
  
  const AppBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.background,
      child: Stack(
        children: [
          // Background Decorative Circles (Simple/Static like Home)
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}
