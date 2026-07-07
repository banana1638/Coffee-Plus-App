import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_motion.dart';

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

  // ====== 常量优化（消除 warning + 更专业）======
  static const double _startDelay = 0.18; // 先倒水
  static const double _maxFillOffset = 10; // 不要太满
  static const double _fillDurationFactor = 0.65; // 更快填满

  // Paint 缓存
  static final Paint _outlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final Paint _liquidPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _foamPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _streamPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  static final Paint _splashPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _steamPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  CartoonCoffeePainter({
    required this.progress,
    required this.outlineColor,
    required this.liquidColor,
    required this.steamColor,
    this.config = const CoffeePainterConfig(),
  });

  final Path _path = Path();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final double cupTop = h * 0.35;
    final double cupBottom = h * 0.85;
    final double cupLeft = w * 0.22;
    final double cupRight = w * 0.73;
    final double centerX = (cupLeft + cupRight) / 2;

    _outlinePaint.color = outlineColor;
    _outlinePaint.strokeWidth = config.strokeWidth;

    // ===== 1. 杯把 =====
    _path.reset();
    _path.moveTo(cupRight, h * 0.45);
    _path.cubicTo(w * 0.95, h * 0.45, w * 0.95, h * 0.75, cupRight, h * 0.75);
    canvas.drawPath(_path, _outlinePaint);

    // ===== 2. 液体高度（核心优化🔥）=====
    double fillProgress =
        (progress - _startDelay).clamp(0.0, 1.0) / _fillDurationFactor;

    fillProgress = fillProgress.clamp(0.0, 1.0);

    final double easedFill = Curves.easeOut.transform(fillProgress);

    final double fillLevel =
        cupBottom - (cupBottom - (cupTop + _maxFillOffset)) * easedFill;

    // ===== 3. 液体 =====
    if (progress > 0.03) {
      canvas.save();

      _path.reset();
      _path.moveTo(cupLeft, cupTop);
      _path.lineTo(cupLeft, h * 0.7);
      _path.quadraticBezierTo(cupLeft, cupBottom, centerX, cupBottom);
      _path.quadraticBezierTo(cupRight, cupBottom, cupRight, h * 0.7);
      _path.lineTo(cupRight, cupTop);
      _path.close();

      canvas.clipPath(_path);

      // 渐变（防止高度为0 bug）
      _liquidPaint.shader = ui.Gradient.linear(
        Offset(centerX, fillLevel),
        Offset(centerX, math.max(fillLevel + 5, cupBottom)),
        [
          liquidColor,
          liquidColor.withValues(alpha: 0.85),
          liquidColor.withValues(alpha: 0.95),
        ],
        [0.0, 0.4, 1.0],
      );

      const double step = 4.0;
      final double phase = progress * 2 * math.pi;

      // 波浪同步 easing（更真实）
      final double waveHeight = config.waveHeight * (1.1 - easedFill * 0.6);

      _path.reset();

      final double startY = fillLevel + math.sin(phase) * waveHeight;

      _path.moveTo(-10, startY);

      for (double i = 0; i <= w + 20; i += step) {
        final double y = fillLevel + math.sin(i / 15 + phase) * waveHeight;

        final double nextX = i + step - 10;
        final double nextY =
            fillLevel + math.sin((i + step) / 15 + phase) * waveHeight;

        _path.quadraticBezierTo(
          i - 10,
          y,
          (i - 10 + nextX) / 2,
          (y + nextY) / 2,
        );
      }

      _path.lineTo(w + 10, cupBottom + 20);
      _path.lineTo(-10, cupBottom + 20);
      _path.close();

      canvas.drawPath(_path, _liquidPaint);

      // 泡沫
      _foamPaint.color = Colors.white.withValues(alpha: 0.18);

      _path.reset();
      _path.moveTo(-10, fillLevel);

      for (double i = 0; i <= w + 20; i += step) {
        final double y =
            fillLevel + math.cos(i / 12 + phase) * (waveHeight * 0.6) - 2;
        _path.lineTo(i - 10, y);
      }

      _path.lineTo(w + 10, fillLevel + 12);
      _path.lineTo(-10, fillLevel + 12);
      _path.close();

      canvas.drawPath(_path, _foamPaint);

      canvas.restore();
    }

    // ===== 4. 水流 =====
    if (progress < 0.98) {
      _streamPaint.color = liquidColor.withValues(alpha: 0.9);
      _streamPaint.strokeWidth = config.strokeWidth * (1.1 - progress * 0.1);

      final double streamOffset = math.sin(progress * 45) * 1.5;

      _path.reset();
      _path.moveTo(centerX, 0);
      _path.quadraticBezierTo(
        centerX + streamOffset,
        fillLevel / 2,
        centerX,
        fillLevel,
      );

      canvas.drawPath(_path, _streamPaint);

      // 飞溅
      if (progress > 0.08) {
        _splashPaint.color = liquidColor;

        for (int i = 0; i < 4; i++) {
          final double splashAnim = (progress * 48 + i * 2.5) % 10 / 10;

          final double radius = (1 - splashAnim) * 2.5;

          if (radius > 0) {
            canvas.drawCircle(
              Offset(
                centerX + math.sin(i * 123.0 + progress) * 12,
                fillLevel - (splashAnim * 18),
              ),
              radius,
              _splashPaint,
            );
          }
        }
      }
    }

    // ===== 5. 杯身 =====
    _path.reset();
    _path.moveTo(cupLeft, cupTop);
    _path.lineTo(cupLeft, h * 0.7);
    _path.quadraticBezierTo(cupLeft, cupBottom, centerX, cupBottom);
    _path.quadraticBezierTo(cupRight, cupBottom, cupRight, h * 0.7);
    _path.lineTo(cupRight, cupTop);

    canvas.drawPath(_path, _outlinePaint);

    // ===== 6. 蒸汽 =====
    if (fillProgress > 0.5) {
      final double steamAlphaBase = (fillProgress - 0.5) * 2.0;

      for (int i = 0; i < 3; i++) {
        final double t = (progress + i * 0.33) % 1.0;

        final double sx = centerX - 18 + i * 18 + math.sin(t * 5) * 4;

        final double sy = cupTop - 5 - (t * 32);

        _steamPaint.color = steamColor.withValues(
          alpha: 0.22 * (1 - t) * steamAlphaBase,
        );

        _steamPaint.strokeWidth = 2.0;

        _path.reset();
        _path.moveTo(sx, sy);
        _path.relativeQuadraticBezierTo(math.sin(t * 8 + i) * 8, -12, 0, -22);

        canvas.drawPath(_path, _steamPaint);
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

  Color _defaultOutlineColor(BuildContext context) {
    return context.isDarkMode
        ? const Color(0xFFFFD9A8)
        : const Color(0xFF2A1710);
  }

  Color _defaultLiquidColor(BuildContext context) {
    return context.isDarkMode
        ? const Color(0xFFC47B3A)
        : const Color(0xFF4B2616);
  }

  Color _defaultSteamColor(BuildContext context) {
    return context.isDarkMode
        ? const Color(0xFFFFE7C7)
        : const Color(0xFFB87E2D);
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
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
              final double curvedValue = AppMotion.standard.transform(
                _controller.value,
              );

              return CustomPaint(
                painter: CartoonCoffeePainter(
                  progress: curvedValue,
                  outlineColor:
                      widget.config.outlineColor ??
                      _defaultOutlineColor(context),
                  liquidColor:
                      widget.config.liquidColor ?? _defaultLiquidColor(context),
                  steamColor:
                      widget.config.steamColor ?? _defaultSteamColor(context),
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
    final navigator = Navigator.of(context, rootNavigator: true);
    var isDialogOpen = true;
    final dialogFuture = showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (context) =>
          const PopScope(canPop: false, child: CoffeeLoadingIndicator()),
    );
    unawaited(dialogFuture.whenComplete(() => isDialogOpen = false));

    try {
      return await future;
    } finally {
      if (isDialogOpen && navigator.mounted) {
        navigator.pop();
      }
    }
  }
}
