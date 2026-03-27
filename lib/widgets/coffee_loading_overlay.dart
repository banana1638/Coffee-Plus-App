import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/app_colors.dart';

class CartoonCoffeePainter extends CustomPainter {
  final double progress;

  CartoonCoffeePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    
    // 基础参数 (Cup Dimensions)
    final double cupTop = h * 0.35;
    final double cupBottom = h * 0.85;
    final double cupLeft = w * 0.22;
    final double cupRight = w * 0.73;
    final double centerX = (cupLeft + cupRight) / 2;

    final outlinePaint = Paint()
      ..color = AppColors.textMain
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final liquidPaint = Paint()
      ..color = const Color(0xFF6F4E37) // Typical Coffee Brown
      ..style = PaintingStyle.fill;

    // 1. Draw Cup Handle
    final handlePath = Path();
    handlePath.moveTo(cupRight, h * 0.45);
    handlePath.cubicTo(w * 0.95, h * 0.45, w * 0.95, h * 0.75, cupRight, h * 0.75);
    canvas.drawPath(handlePath, outlinePaint);

    // 2. Liquid Filling Logic
    // Start rising only after 10% progress to look like it's being "poured in" first
    double fillProgress = (progress - 0.1).clamp(0.0, 1.0) / 0.9;
    final double fillLevel = cupBottom - (cupBottom - (cupTop + 8)) * fillProgress;

    // 3. Draw Liquid (Inside Cup)
    if (progress > 0.05) {
      canvas.save();
      // Clip to interior of cup (U-shape)
      final clipPath = Path();
      clipPath.moveTo(cupLeft, cupTop);
      clipPath.lineTo(cupLeft, h * 0.7);
      clipPath.quadraticBezierTo(cupLeft, cupBottom, centerX, cupBottom);
      clipPath.quadraticBezierTo(cupRight, cupBottom, cupRight, h * 0.7);
      clipPath.lineTo(cupRight, cupTop);
      clipPath.close();
      canvas.clipPath(clipPath);

      final liquidPath = Path();
      liquidPath.moveTo(-20, fillLevel);
      
      // Dynamic Wave Effect
      const double waveHeight = 3.5;
      for (double i = 0; i <= w + 40; i += 5) {
        final double waveOffset = math.sin(i / 12 + progress * 15) * waveHeight;
        liquidPath.lineTo(i - 20, fillLevel + waveOffset);
      }
      
      liquidPath.lineTo(w + 20, h);
      liquidPath.lineTo(-20, h);
      liquidPath.close();
      canvas.drawPath(liquidPath, liquidPaint);
      canvas.restore();
    }

    // 4. Pouring Stream (From Top)
    if (progress < 0.98) {
      final streamPaint = Paint()
        ..color = const Color(0xFF5D3A1A) // Slightly darker for contrast
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round;

      // Solid Stream
      canvas.drawLine(Offset(centerX, 0), Offset(centerX, fillLevel), streamPaint);

      // 5. Splash Effect
      if (progress > 0.1) {
        final splashPaint = Paint()
          ..color = const Color(0xFF6F4E37)
          ..style = PaintingStyle.fill;
        
        final double splashAnim = math.sin(progress * 40).abs();
        canvas.drawCircle(Offset(centerX - 8, fillLevel - 2), splashAnim * 3 + 1, splashPaint);
        canvas.drawCircle(Offset(centerX + 8, fillLevel - 4), splashAnim * 2 + 1, splashPaint);
      }
    }

    // 6. Draw Cup Body Outline
    final cupPath = Path();
    cupPath.moveTo(cupLeft, cupTop);
    cupPath.lineTo(cupLeft, h * 0.7);
    cupPath.quadraticBezierTo(cupLeft, cupBottom, centerX, cupBottom);
    cupPath.quadraticBezierTo(cupRight, cupBottom, cupRight, h * 0.7);
    cupPath.lineTo(cupRight, cupTop);
    canvas.drawPath(cupPath, outlinePaint);

    // 7. Steam Effect (near end of fill)
    if (fillProgress > 0.8) {
      final double steamOpacity = (fillProgress - 0.8) * 5.0;
      final steamPaint = Paint()
        ..color = AppColors.textMain.withValues(alpha: 0.15 * steamOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      
      for (int i = 0; i < 3; i++) {
        final double sx = centerX - 12 + i * 12;
        final double sy = cupTop - 8 - (progress * 25 % 12);
        canvas.drawLine(Offset(sx, sy), Offset(sx, sy - 12), steamPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CartoonCoffeePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class CoffeeLoadingIndicator extends StatefulWidget {
  final double size;
  const CoffeeLoadingIndicator({super.key, this.size = 70});

  @override
  State<CoffeeLoadingIndicator> createState() => _CoffeeLoadingIndicatorState();
}

class _CoffeeLoadingIndicatorState extends State<CoffeeLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Slightly faster
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: CartoonCoffeePainter(progress: _controller.value),
            );
          },
        ),
      ),
    );
  }
}

class CoffeeLoadingOverlay {
  static Future<T> show<T>(BuildContext context, Future<T> future) async {
    // Show overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: CoffeeLoadingIndicator(),
      ),
    );

    try {
      final result = await future;
      if (context.mounted) Navigator.of(context).pop();
      return result;
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      rethrow;
    }
  }
}
