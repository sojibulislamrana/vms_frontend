import 'package:flutter/material.dart';
import '../models/vehicle.dart';

/// Elegant status badges following Reference Image 2:
/// Active: Green (#16A34A) with soft mint background
/// Maintenance: Orange (#EA580C) with soft amber background
/// Inactive: Gray (#64748B) with soft slate background
class VehicleStatusBadge extends StatelessWidget {
  final VehicleStatus status;
  final bool showDot;

  const VehicleStatusBadge({
    super.key,
    required this.status,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (color, bgLight, bgDark) = switch (status) {
      VehicleStatus.active => (
          const Color(0xFF16A34A),
          const Color(0xFFF0FDF4),
          const Color(0xFF052E16),
        ),
      VehicleStatus.maintenance => (
          const Color(0xFFEA580C),
          const Color(0xFFFFFBEB),
          const Color(0xFF451A03),
        ),
      VehicleStatus.inactive => (
          const Color(0xFF64748B),
          const Color(0xFFF1F5F9),
          const Color(0xFF1E293B),
        ),
    };

    final bg = isDark ? bgDark : bgLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.4 : 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            status.label,
            style: TextStyle(
              color: color,
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
