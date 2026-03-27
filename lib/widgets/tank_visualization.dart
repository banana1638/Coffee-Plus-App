import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/app_colors.dart';

class TankVisualization extends StatefulWidget {
  final double currentOz;
  final double maxCapacity;
  final double size;

  const TankVisualization({
    super.key,
    required this.currentOz,
    this.maxCapacity = 10000.0,
    this.size = 150.0,
  });

  @override
  State<TankVisualization> createState() => _TankVisualizationState();
}

class _TankVisualizationState extends State<TankVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double percentage = (widget.currentOz / widget.maxCapacity).clamp(0.0, 1.0);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Pulse Effect
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
                width: 4,
              ),
            ),
          ),

          // Tank Background & Wave
          ClipOval(
            child: Container(
              color: AppColors.background,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return RepaintBoundary(
                    child: CustomPaint(
                      painter: _WavePainter(
                        progress: percentage,
                        waveValue: _controller.value,
                      ),
                      size: Size(widget.size, widget.size),
                    ),
                  );
                },
              ),
            ),
          ),

          // Border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
          ),

          // Text Overlay
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${(percentage * 100).round()}',
                    style: TextStyle(
                      fontSize: widget.size * 0.2,
                      fontWeight: FontWeight.w900,
                      color: percentage > 0.5
                          ? Colors.white
                          : AppColors.primary,
                    ),
                  ),
                  Text(
                    '%',
                    style: TextStyle(
                      fontSize: widget.size * 0.08,
                      fontWeight: FontWeight.bold,
                      color: percentage > 0.5
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
              // 这里的 TextStyle 增加了 const
              Text(
                'CAPACITY',
                style: TextStyle(
                  fontSize: widget.size * 0.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: percentage > 0.5
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double waveValue;

  _WavePainter({required this.progress, required this.waveValue});

  @override
  void paint(Canvas canvas, Size size) {
    final yOffset = size.height * (1 - progress);
    final waveAmplitude = progress > 0 && progress < 1 ? 6.0 : 0.0; // 稍微增加振幅

    // Layer 1: Front wave (Solid)
    final paint1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // 更亮一点的蓝色
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path1 = Path();
    path1.moveTo(0, yOffset);
    for (double i = 0; i <= size.width; i++) {
      path1.lineTo(
        i,
        yOffset +
            math.sin((i / size.width * 2 * math.pi) + (waveValue * 2 * math.pi)) *
                waveAmplitude,
      );
    }
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();

    // Layer 2: Back wave (Semi-transparent)
    final paint2 = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.5);

    final path2 = Path();
    path2.moveTo(0, yOffset);
    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(
        i,
        yOffset +
            math.cos((i / size.width * 2 * math.pi) + (waveValue * 2 * math.pi)) *
                waveAmplitude,
      );
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint2);
    canvas.drawPath(path1, paint1);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.waveValue != waveValue ||
        oldDelegate.progress != progress;
  }
}
