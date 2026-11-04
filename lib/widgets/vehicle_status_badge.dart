import 'package:flutter/material.dart';
import '../models/vehicle.dart';

/// Reusable badge chip that displays the vehicle's operational status
/// with Stark Group high-contrast status colors.
class VehicleStatusBadge extends StatelessWidget {
  final VehicleStatus status;

  const VehicleStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final (bgLight, bgDark, fgLight, fgDark, icon) = switch (status) {
      VehicleStatus.active => (
          const Color(0xFFDCFCE7), // Emerald 100
          const Color(0xFF064E3B), // Emerald 900
          const Color(0xFF15803D), // Emerald 700
          const Color(0xFF4ADE80), // Emerald 400
          Icons.check_circle_rounded,
        ),
      VehicleStatus.maintenance => (
          const Color(0xFFFEF3C7), // Amber 100
          const Color(0xFF78350F), // Amber 900
          const Color(0xFFB45309), // Amber 700
          const Color(0xFFFBBF24), // Amber 400
          Icons.build_circle_rounded,
        ),
      VehicleStatus.inactive => (
          const Color(0xFFF1F5F9), // Slate 100
          const Color(0xFF1E293B), // Slate 800
          const Color(0xFF475569), // Slate 600
          const Color(0xFF94A3B8), // Slate 400
          Icons.pause_circle_rounded,
        ),
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? bgDark : bgLight;
    final foregroundColor = isDark ? fgDark : fgLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: foregroundColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
