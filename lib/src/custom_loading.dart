import 'package:flutter/material.dart';

/// A widget that shows a shimmer loading effect when [visible] is true.
///
/// When [visible] is false, it shows the [replacement] widget instead.
class Shimmer extends StatefulWidget {
  /// The child widget to apply the shimmer effect to.
  final Widget child;

  /// Whether to show the shimmer or the [replacement] widget.
  final bool visible;

  /// The widget to display when shimmer is not visible.
  final Widget replacement;

  /// A widget that displays a shimmer animation over [child] while [visible] is true,
  /// and shows [replacement] when [visible] is false.
  ///
  /// Typically used for loading placeholders.
  ///
  /// - [child]: The widget to display with a shimmer effect.
  /// - [visible]: Whether to show the shimmer or the replacement.
  /// - [replacement]: The widget to show when shimmer is not visible.
  const Shimmer({
    super.key,

    /// The widget over which the shimmer effect is applied.
    required this.child,

    /// Determines whether the shimmer effect is shown.
    required this.visible,

    /// The widget to show when shimmer is not visible.
    required this.replacement,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
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
    return widget.visible
        ? AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: [
                      Colors.grey[300]!,
                      Colors.grey[100]!,
                      Colors.grey[300]!,
                    ],
                    stops: const [0.1, 0.3, 0.4],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    transform: SlidingGradientTransform(_controller.value * 2),
                  ).createShader(bounds);
                },
                blendMode: BlendMode.srcATop,
                child: widget.child,
              );
            },
          )
        : widget.replacement;
  }
}

/// A custom [GradientTransform] that slides the gradient horizontally
/// based on the provided [slidePercent].
///
/// This is typically used in shimmer effects to animate the gradient.
class SlidingGradientTransform extends GradientTransform {
  /// The percentage (0.0 - 1.0+) of how far to slide the gradient
  /// across the widget's width.
  final double slidePercent;

  /// Creates a sliding gradient transform.
  ///
  /// The [slidePercent] controls how far the gradient is offset
  /// horizontally from its original position.
  const SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
