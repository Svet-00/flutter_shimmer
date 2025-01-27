///
/// * author: hunghd
/// * email: hunghd.yb@gmail.com
///
/// A package provides an easy way to add shimmer effect to Flutter application
///

library shimmer;

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

///
/// An enum defines all supported directions of shimmer effect
///
/// * [ShimmerDirection.ltr] left to right direction
/// * [ShimmerDirection.rtl] right to left direction
/// * [ShimmerDirection.ttb] top to bottom direction
/// * [ShimmerDirection.btt] bottom to top direction
///
enum ShimmerDirection { ltr, rtl, ttb, btt }

///
/// A widget renders shimmer effect over [child] widget tree.
///
/// [child] defines an area that shimmer effect blends on. You can build [child]
/// from whatever [Widget] you like but there're some notices in order to get
/// exact expected effect and get better rendering performance:
///
/// * Use static [Widget] (which is an instance of [StatelessWidget]).
/// * [Widget] should be a solid color element. Every colors you set on these
/// [Widget]s will be overridden by colors of [gradient].
/// * Shimmer effect only affects to opaque areas of [child], transparent areas
/// still stays transparent.
///
/// [period] controls the speed of shimmer effect. The default value is 1500
/// milliseconds.
///
/// [direction] controls the direction of shimmer effect. The default value
/// is [ShimmerDirection.ltr].
///
/// [gradient] controls colors of shimmer effect.
///
/// [loop] the number of animation loop, set value of `0` to make animation run
/// forever.
///
/// [enabled] controls if shimmer effect is active. When set to false the animation
/// is paused
///
///
/// ## Pro tips:
///
/// * [child] should be made of basic and simple [Widget]s, such as [Container],
/// [Row] and [Column], to avoid side effect.
///
/// * use one [Shimmer] to wrap list of [Widget]s instead of a list of many [Shimmer]s
///
@immutable
class Shimmer extends StatelessWidget {
  final Widget child;
  final Duration? period;
  final ShimmerDirection direction;
  final Gradient gradient;
  final int? loop;
  final bool? enabled;

  const Shimmer({
    Key? key,
    required this.child,
    required this.gradient,
    this.direction = ShimmerDirection.ltr,
    this.period,
    this.loop,
    this.enabled,
  }) : super(key: key);

  ///
  /// A convenient constructor provides an easy and convenient way to create a
  /// [Shimmer] which [gradient] is [LinearGradient] made up of `baseColor` and
  /// `highlightColor`.
  ///
  Shimmer.fromColors({
    Key? key,
    required this.child,
    required Color baseColor,
    required Color highlightColor,
    this.period,
    this.direction = ShimmerDirection.ltr,
    this.loop,
    this.enabled,
  })  : gradient = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.centerRight,
            colors: <Color>[baseColor, baseColor, highlightColor, baseColor, baseColor],
            stops: const <double>[0.0, 0.35, 0.5, 0.65, 1.0]),
        super(key: key);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Gradient>('gradient', gradient, defaultValue: null));
    properties.add(EnumProperty<ShimmerDirection>('direction', direction));
    properties.add(DiagnosticsProperty<Duration>('period', period, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('enabled', enabled, defaultValue: null));
    properties.add(DiagnosticsProperty<int>('loop', loop, defaultValue: 0));
  }

  bool synced(BuildContext context) {
    return ShimmerController.maybeOf(context) != null;
  }

  Widget _buildShimmer(BuildContext context, AnimationController controller) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (BuildContext context, Widget? child) => _Shimmer(
        child: child,
        direction: direction,
        gradient: gradient,
        percent: controller.value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (synced(context)) {
      assert(() {
        if (enabled != null || loop != null || period != null) {
          log(
            '[Shimmer] WARNING This Shimmer is controlled by external ShimmerController'
            ' so [enabled], [loop] and [period] parameters are ignored.',
            stackTrace: StackTrace.current,
          );
        }
        return true;
      }());

      return _buildShimmer(
        context,
        ShimmerController.of(context)._controller,
      );
    } else {
      return ShimmerController(
        enabled: enabled ?? true,
        loop: loop ?? 0,
        period: period ?? const Duration(milliseconds: 1500),
        child: Builder(
          builder: (BuildContext context) {
            return _buildShimmer(
              context,
              ShimmerController.of(context)._controller,
            );
          },
        ),
      );
    }
  }
}

@immutable
class _Shimmer extends SingleChildRenderObjectWidget {
  final double percent;
  final ShimmerDirection direction;
  final Gradient gradient;

  const _Shimmer({
    Widget? child,
    required this.percent,
    required this.direction,
    required this.gradient,
  }) : super(child: child);

  @override
  _ShimmerFilter createRenderObject(BuildContext context) {
    return _ShimmerFilter(percent, direction, gradient);
  }

  @override
  void updateRenderObject(BuildContext context, _ShimmerFilter shimmer) {
    shimmer.percent = percent;
    shimmer.gradient = gradient;
    shimmer.direction = direction;
  }
}

class _ShimmerFilter extends RenderProxyBox {
  ShimmerDirection _direction;
  Gradient _gradient;
  double _percent;

  _ShimmerFilter(this._percent, this._direction, this._gradient);

  @override
  ShaderMaskLayer? get layer => super.layer as ShaderMaskLayer?;

  @override
  bool get alwaysNeedsCompositing => child != null;

  set percent(double newValue) {
    if (newValue == _percent) {
      return;
    }
    _percent = newValue;
    markNeedsPaint();
  }

  set gradient(Gradient newValue) {
    if (newValue == _gradient) {
      return;
    }
    _gradient = newValue;
    markNeedsPaint();
  }

  set direction(ShimmerDirection newDirection) {
    if (newDirection == _direction) {
      return;
    }
    _direction = newDirection;
    markNeedsLayout();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      assert(needsCompositing);

      final double width = child!.size.width;
      final double height = child!.size.height;
      Rect rect;
      double dx, dy;
      if (_direction == ShimmerDirection.rtl) {
        dx = _offset(width, -width, _percent);
        dy = 0.0;
        rect = Rect.fromLTWH(dx - width, dy, 3 * width, height);
      } else if (_direction == ShimmerDirection.ttb) {
        dx = 0.0;
        dy = _offset(-height, height, _percent);
        rect = Rect.fromLTWH(dx, dy - height, width, 3 * height);
      } else if (_direction == ShimmerDirection.btt) {
        dx = 0.0;
        dy = _offset(height, -height, _percent);
        rect = Rect.fromLTWH(dx, dy - height, width, 3 * height);
      } else {
        dx = _offset(-width, width, _percent);
        dy = 0.0;
        rect = Rect.fromLTWH(dx - width, dy, 3 * width, height);
      }
      layer ??= ShaderMaskLayer();
      layer!
        ..shader = _gradient.createShader(rect)
        ..maskRect = offset & size
        ..blendMode = BlendMode.srcIn;
      context.pushLayer(layer!, super.paint, offset);
    } else {
      layer = null;
    }
  }

  double _offset(double start, double end, double percent) {
    return start + (end - start) * percent;
  }
}

class ShimmerController extends StatefulWidget {
  final Widget child;
  final Duration period;
  final int loop;
  final bool enabled;

  const ShimmerController({
    Key? key,
    required this.child,
    this.period = const Duration(milliseconds: 1500),
    this.loop = 0,
    this.enabled = true,
  }) : super(key: key);

  static _ShimmerControllerState? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ShimmerControllerScope>()?._state;
  }

  static _ShimmerControllerState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ShimmerControllerScope>()!._state;
  }

  @override
  _ShimmerControllerState createState() => _ShimmerControllerState();
}

class _ShimmerControllerState extends State<ShimmerController> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..addStatusListener((AnimationStatus status) {
        if (status != AnimationStatus.completed) {
          return;
        }
        _count++;
        if (widget.loop <= 0) {
          _controller.repeat();
        } else if (_count < widget.loop) {
          _controller.forward(from: 0.0);
        }
      });
    if (widget.enabled) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ShimmerController oldWidget) {
    if (widget.enabled) {
      _controller.forward();
    } else {
      _controller.stop();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerControllerScope(this, child: widget.child);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _ShimmerControllerScope extends InheritedWidget {
  const _ShimmerControllerScope(
    this._state, {
    Key? key,
    required Widget child,
  }) : super(key: key, child: child);
  final _ShimmerControllerState _state;

  @override
  bool updateShouldNotify(_ShimmerControllerScope oldWidget) => _state != oldWidget._state;
}
