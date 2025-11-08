import 'package:flutter/material.dart';

/// Reusable app logo widget
class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppLogo({
    Key? key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/Picsart_25-11-09_00-12-02-037.jpg',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback if image fails to load
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B9D).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.favorite,
              color: Color(0xFFFF6B9D),
              size: 48,
            ),
          ),
        );
      },
    );
  }
}
