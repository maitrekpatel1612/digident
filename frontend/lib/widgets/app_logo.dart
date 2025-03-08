import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool useLightModeColor;

  const AppLogo({
    super.key,
    this.size = 28.0,
    this.color,
    this.useLightModeColor = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final logoColor = color ?? (isDarkMode || !useLightModeColor ? Colors.white : Colors.blue);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/digident_logo_bgremove.png',
          height: size * 1.5,
          width: size * 1.5,
          color: logoColor,
          colorBlendMode: BlendMode.srcIn,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to a simple icon if the image fails to load
            return Icon(
              Icons.medical_services,
              color: logoColor,
              size: size * 1.2,
            );
          },
        ),
        SizedBox(width: size / 2),
        Text(
          'Digident',
          style: TextStyle(
            color: logoColor,
            fontSize: size * 0.9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 