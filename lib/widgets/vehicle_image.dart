import 'package:flutter/material.dart';
import '../models/vehicle.dart';

/// Renders a modern, high-fidelity car visual for a given vehicle.
/// Utilizes curated free CDN car photography with an instant, resolution-independent
/// vector car illustration fallback drawn using CustomPainter.
class VehicleImage extends StatelessWidget {
  final VehicleType? type;
  final String? brand;
  final String? model;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const VehicleImage({
    super.key,
    this.type,
    this.brand,
    this.model,
    this.width = double.infinity,
    this.height = 140,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  /// Curated royalty-free car photography from Unsplash CDN
  static String getCarImageUrl(VehicleType? type, String? brand) {
    final b = (brand ?? '').toLowerCase();
    final t = type ?? VehicleType.suv;

    if (b.contains('tesla') || b.contains('cyber')) {
      return 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?auto=format&fit=crop&w=600&q=80';
    } else if (b.contains('porsche') || b.contains('audi')) {
      return 'https://images.unsplash.com/photo-1617814076367-b759c7d7e738?auto=format&fit=crop&w=600&q=80';
    } else if (b.contains('mercedes') || b.contains('bmw')) {
      return 'https://images.unsplash.com/photo-1555215695-3004980ad54e?auto=format&fit=crop&w=600&q=80';
    }

    switch (t) {
      case VehicleType.suv:
        return 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=600&q=80';
      case VehicleType.sedan:
        return 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?auto=format&fit=crop&w=600&q=80';
      case VehicleType.truck:
        return 'https://images.unsplash.com/photo-1559416523-140ddc3d238c?auto=format&fit=crop&w=600&q=80';
      case VehicleType.van:
        return 'https://images.unsplash.com/photo-1527786356703-4b100091cd2c?auto=format&fit=crop&w=600&q=80';
      case VehicleType.electric:
        return 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?auto=format&fit=crop&w=600&q=80';
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(10);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final imageUrl = getCarImageUrl(type, brand);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        ),
        child: Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildVectorFallback(isDark);
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildVectorFallback(isDark);
          },
        ),
      ),
    );
  }

  Widget _buildVectorFallback(bool isDark) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
        ),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(width > 120 ? 100 : width * 0.7, height * 0.6),
          painter: _VectorCarPainter(
            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
            wheelColor: isDark ? const Color(0xFF334155) : const Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }
}

/// A precision aerodynamic vector car silhouette drawn on Canvas
class _VectorCarPainter extends CustomPainter {
  final Color color;
  final Color wheelColor;

  _VectorCarPainter({required this.color, required this.wheelColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final windowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final wheelPaint = Paint()
      ..color = wheelColor
      ..style = PaintingStyle.fill;

    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Body silhouette
    final bodyPath = Path();
    bodyPath.moveTo(w * 0.05, h * 0.65);
    bodyPath.quadraticBezierTo(w * 0.05, h * 0.50, w * 0.18, h * 0.48);
    bodyPath.lineTo(w * 0.32, h * 0.30);
    bodyPath.quadraticBezierTo(w * 0.36, h * 0.22, w * 0.45, h * 0.22);
    bodyPath.lineTo(w * 0.68, h * 0.22);
    bodyPath.quadraticBezierTo(w * 0.75, h * 0.25, w * 0.82, h * 0.45);
    bodyPath.lineTo(w * 0.94, h * 0.50);
    bodyPath.quadraticBezierTo(w * 0.98, h * 0.58, w * 0.95, h * 0.68);
    bodyPath.lineTo(w * 0.88, h * 0.68);
    bodyPath.arcToPoint(
      Offset(w * 0.72, h * 0.68),
      radius: Radius.circular(h * 0.16),
      clockwise: false,
    );
    bodyPath.lineTo(w * 0.36, h * 0.68);
    bodyPath.arcToPoint(
      Offset(w * 0.20, h * 0.68),
      radius: Radius.circular(h * 0.16),
      clockwise: false,
    );
    bodyPath.lineTo(w * 0.05, h * 0.68);
    bodyPath.close();

    canvas.drawPath(bodyPath, bodyPaint);

    // Windshield & Side Windows
    final windowPath = Path();
    windowPath.moveTo(w * 0.35, h * 0.33);
    windowPath.lineTo(w * 0.46, h * 0.26);
    windowPath.lineTo(w * 0.66, h * 0.26);
    windowPath.lineTo(w * 0.77, h * 0.45);
    windowPath.lineTo(w * 0.35, h * 0.45);
    windowPath.close();

    canvas.drawPath(windowPath, windowPaint);

    // Wheels
    final wheelRadius = h * 0.15;
    final rimRadius = h * 0.07;

    // Front Wheel
    final frontWheelCenter = Offset(w * 0.28, h * 0.68);
    canvas.drawCircle(frontWheelCenter, wheelRadius, wheelPaint);
    canvas.drawCircle(frontWheelCenter, rimRadius, rimPaint);

    // Rear Wheel
    final rearWheelCenter = Offset(w * 0.80, h * 0.68);
    canvas.drawCircle(rearWheelCenter, wheelRadius, wheelPaint);
    canvas.drawCircle(rearWheelCenter, rimRadius, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _VectorCarPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.wheelColor != wheelColor;
}
