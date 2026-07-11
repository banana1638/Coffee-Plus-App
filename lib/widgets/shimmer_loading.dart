import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_motion.dart';

class ShimmerTickerScope extends StatefulWidget {
  final Widget child;

  const ShimmerTickerScope({super.key, required this.child});

  static Animation<double>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedShimmerTicker>()
        ?.animation;
  }

  @override
  State<ShimmerTickerScope> createState() => _ShimmerTickerScopeState();
}

class _ShimmerTickerScopeState extends State<ShimmerTickerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = _buildShimmerAnimation(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedShimmerTicker(animation: _animation, child: widget.child);
  }
}

class _InheritedShimmerTicker extends InheritedWidget {
  final Animation<double> animation;

  const _InheritedShimmerTicker({
    required this.animation,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedShimmerTicker oldWidget) {
    return animation != oldWidget.animation;
  }
}

class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _fallbackAnimation;

  Animation<double> get _animation {
    final scopedAnimation = ShimmerTickerScope.maybeOf(context);
    if (scopedAnimation != null) {
      _controller?.dispose();
      _controller = null;
      _fallbackAnimation = null;
      return scopedAnimation;
    }

    final existingAnimation = _fallbackAnimation;
    if (existingAnimation != null) return existingAnimation;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _controller = controller;
    return _fallbackAnimation = _buildShimmerAnimation(controller);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = context.appBorder;
    final highlightColor = context.appSurfaceSubtle;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.1, 0.5, 0.9],
                colors: [baseColor, highlightColor, baseColor],
                transform: _SlidingGradientTransform(_animation.value),
              ),
            ),
            child: SizedBox(width: widget.width, height: widget.height),
          );
        },
      ),
    );
  }
}

Animation<double> _buildShimmerAnimation(AnimationController controller) {
  return Tween<double>(
    begin: -1.5,
    end: 1.5,
  ).animate(CurvedAnimation(parent: controller, curve: AppMotion.standard));
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
