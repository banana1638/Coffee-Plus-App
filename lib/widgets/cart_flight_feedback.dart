import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_motion.dart';

class CartFlightFeedback {
  const CartFlightFeedback._();

  static Future<void> playFrom(
    BuildContext context, {
    required GlobalKey sourceKey,
  }) async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final sourceContext = sourceKey.currentContext;
    if (overlay == null || sourceContext == null) return;

    final sourceBox = sourceContext.findRenderObject();
    if (sourceBox is! RenderBox || !sourceBox.hasSize) return;

    final media = MediaQuery.of(context);
    final screenSize = media.size;
    final sourceTopLeft = sourceBox.localToGlobal(Offset.zero);
    final sourceCenter = sourceTopLeft + sourceBox.size.center(Offset.zero);
    final target = Offset(
      screenSize.width * 0.625,
      screenSize.height - media.padding.bottom - 48,
    );

    final controller = AnimationController(
      vsync: overlay,
      duration: const Duration(milliseconds: 560),
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: AppMotion.routeEnter,
    );

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = animation.value;
            final easedOut = Curves.easeOutCubic.transform(t);
            final x = _lerp(sourceCenter.dx, target.dx, easedOut);
            final y =
                _lerp(sourceCenter.dy, target.dy, easedOut) -
                math.sin(math.pi * t) * 72;
            final scale = _lerp(1, 0.58, t);
            final opacity = t > 0.82 ? _lerp(1, 0, (t - 0.82) / 0.18) : 1.0;

            return IgnorePointer(
              child: Stack(
                children: [
                  Positioned(
                    left: x - 16,
                    top: y - 16,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: scale,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.appPrimary,
                            border: Border.all(
                              color: context.appSurface,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: context.appPrimary.withValues(
                                  alpha: 0.22,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(
                              Icons.local_cafe_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    overlay.insert(entry);
    try {
      await controller.forward();
    } finally {
      entry.remove();
      controller.dispose();
    }
  }

  static double _lerp(double begin, double end, double t) {
    return begin + (end - begin) * t;
  }
}
