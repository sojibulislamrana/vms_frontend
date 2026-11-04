import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Renders the official Stark Group VMS logo with graceful fallback to vector icon.
class AppLogo extends StatelessWidget {
  final double size;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final bool isDark;

  const AppLogo({
    super.key,
    this.size = 40,
    this.borderRadius,
    this.backgroundColor,
    this.padding,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.22);
    final bg = backgroundColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.18)
            : AppTheme.primaryBlue.withValues(alpha: 0.1));

    return Container(
      width: size,
      height: size,
      padding: padding ?? EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.22)
              : AppTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.15),
        child: Image.asset(
          'web/icons/icon.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/images/icon.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.shield_rounded,
                    color: isDark ? Colors.white : AppTheme.primaryBlue,
                    size: size * 0.55,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

