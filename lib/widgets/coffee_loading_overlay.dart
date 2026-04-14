import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/app_colors.dart';

/// 咖啡动画配置类
class CoffeePainterConfig {
  final Color? outlineColor;
  final Color? liquidColor;
  final Color? steamColor;
  final double strokeWidth;
  final double waveHeight;

  const CoffeePainterConfig({
    this.outlineColor,
    this.liquidColor,
    this.steamColor,
    this.strokeWidth = 3.5,
    this.waveHeight = 3.0,
  });
}

class CartoonCoffeePainter extends CustomPainter {
  final double progress;
  final Color outlineColor;
  final Color liquidColor;
  final Color steamColor;
  final CoffeePainterConfig config;

  CartoonCoffeePainter({
    required this.progress,
    required this.outlineColor,
    required this.liquidColor,
    required this.steamColor,
    this.config = const CoffeePainterConfig(),
  });

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
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final liquidPaint = Paint()
      ..color = liquidColor
      ..style = PaintingStyle.fill;

    // 1. Draw Cup Handle
    final handlePath = Path();
    handlePath.moveTo(cupRight, h * 0.45);
    handlePath.cubicTo(w * 0.95, h * 0.45, w * 0.95, h * 0.75, cupRight, h * 0.75);
    canvas.drawPath(handlePath, outlinePaint);

    // 2. Liquid Filling Logic
    // Start rising only after 10% progress
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

      // Draw Main Liquid
      final liquidPath = Path();
      liquidPath.moveTo(-20, fillLevel);
      
      // Dynamic Wave Effect
      final double waveHeight = config.waveHeight;
      for (double i = 0; i <= w + 40; i += 5) {
        final double waveOffset = math.sin(i / 15 + progress * 2 * math.pi) * waveHeight;
        liquidPath.lineTo(i - 20, fillLevel + waveOffset);
      }
      
      liquidPath.lineTo(w + 20, h);
      liquidPath.lineTo(-20, h);
      liquidPath.close();
      canvas.drawPath(liquidPath, liquidPaint);

      // Draw Foam/Surface Light Layer
      final foamPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      
      final foamPath = Path();
      foamPath.moveTo(-20, fillLevel);
      for (double i = 0; i <= w + 40; i += 5) {
        final double foamOffset = math.cos(i / 12 + progress * 2 * math.pi) * (waveHeight * 0.8);
        foamPath.lineTo(i - 20, fillLevel + foamOffset - 2);
      }
      foamPath.lineTo(w + 20, fillLevel + 10);
      foamPath.lineTo(-20, fillLevel + 10);
      foamPath.close();
      canvas.drawPath(foamPath, foamPaint);
      
      canvas.restore();
    }

    // 4. Pouring Stream (From Top)
    if (progress < 0.98) {
      final streamPaint = Paint()
        ..color = liquidColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = config.strokeWidth * 1.3
        ..strokeCap = StrokeCap.round;

      // Draw a slightly wobbly stream
      final streamPath = Path();
      streamPath.moveTo(centerX, 0);
      final double wobble = math.sin(progress * 30) * 1.5;
      streamPath.quadraticBezierTo(centerX + wobble, fillLevel / 2, centerX, fillLevel);
      canvas.drawPath(streamPath, streamPaint);

      // 5. Splash Effect
      if (progress > 0.1) {
        final splashPaint = Paint()
          ..color = liquidColor
          ..style = PaintingStyle.fill;
        
        for (int i = 0; i < 3; i++) {
          final double splashAnim = (progress * 50 + i * 2) % 10 / 10;
          final double offsetX = math.sin(i * 123.0) * 10;
          final double offsetY = - (splashAnim * 15);
          final double radius = (1 - splashAnim) * 2.5;
          if (radius > 0) {
            canvas.drawCircle(Offset(centerX + offsetX, fillLevel + offsetY), radius, splashPaint);
          }
        }
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

    // 7. Organic Steam Effect
    if (fillProgress > 0.6) {
      final double steamOpacity = (fillProgress - 0.6) * 2.5;
      final steamPaint = Paint()
        ..color = steamColor.withValues(alpha: 0.2 * steamOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      
      for (int i = 0; i < 3; i++) {
        final double time = (progress + i * 0.33) % 1.0;
        final double sx = centerX - 15 + i * 15;
        final double sy = cupTop - 10 - (time * 30);
        
        final steamPath = Path();
        steamPath.moveTo(sx, sy);
        steamPath.relativeQuadraticBezierTo(
          math.sin(time * 6) * 8, -10,
          0, -20
        );
        
        // Fade out steam as it rises
        steamPaint.color = steamColor.withValues(alpha: (0.2 * (1 - time)) * steamOpacity);
        canvas.drawPath(steamPath, steamPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CartoonCoffeePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.outlineColor != outlineColor ||
      oldDelegate.liquidColor != liquidColor ||
      oldDelegate.config != config;
}

class CoffeeLoadingIndicator extends StatefulWidget {
  final double size;
  final CoffeePainterConfig config;
  
  const CoffeeLoadingIndicator({
    super.key, 
    this.size = 70,
    this.config = const CoffeePainterConfig(),
  });

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
      duration: const Duration(milliseconds: 1500),
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
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: CartoonCoffeePainter(
                  progress: _controller.value,
                  outlineColor: widget.config.outlineColor ?? context.appTextMain,
                  liquidColor: widget.config.liquidColor ?? context.appCoffee,
                  steamColor: widget.config.steamColor ?? context.appTextMain,
                  config: widget.config,
                ),
              );
            },
          ),
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
