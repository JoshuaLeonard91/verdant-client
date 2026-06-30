import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

const _defaultSmoothScrollDuration = Duration(milliseconds: 220);
const _defaultSmoothScrollCurve = Curves.easeOutCubic;

class SmoothWheelScroll extends StatefulWidget {
  const SmoothWheelScroll({
    required this.controller,
    required this.child,
    this.scrollDirection = Axis.vertical,
    this.scrollMultiplier = 1,
    this.duration = _defaultSmoothScrollDuration,
    this.curve = _defaultSmoothScrollCurve,
    this.onWheelScrollDelta,
    this.resetToken,
    super.key,
  });

  final ScrollController controller;
  final Widget child;
  final Axis scrollDirection;
  final double scrollMultiplier;
  final Duration duration;
  final Curve curve;
  final ValueChanged<double>? onWheelScrollDelta;
  final Object? resetToken;

  @override
  State<SmoothWheelScroll> createState() => _SmoothWheelScrollState();
}

class _SmoothWheelScrollState extends State<SmoothWheelScroll> {
  var _scrollGeneration = 0;
  var _hasTargetPixels = false;
  var _targetPixels = 0.0;

  @override
  void didUpdateWidget(covariant SmoothWheelScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller ||
        widget.resetToken != oldWidget.resetToken) {
      _hasTargetPixels = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: _handlePointerSignal,
      child: widget.child,
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !widget.controller.hasClients) {
      return;
    }

    final delta = widget.scrollDirection == Axis.vertical
        ? event.scrollDelta.dy
        : event.scrollDelta.dx;
    if (delta == 0) {
      return;
    }
    _logSmoothWheel('signal', {'delta': _scrollNumber(delta)});
    widget.onWheelScrollDelta?.call(delta);

    final position = widget.controller.position;
    if (!position.haveDimensions) {
      _logSmoothWheel('ignored', {'reason': 'noDimensions'});
      return;
    }

    final startPixels = position.pixels;
    var handledByResolver = false;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      handledByResolver = true;
      _logSmoothWheel('resolverAccepted', {
        'delta': _scrollNumber(delta),
        'start': _scrollNumber(startPixels),
      });
      scheduleMicrotask(() {
        if (mounted && widget.controller.hasClients) {
          _animateWheelDelta(delta, startPixels: startPixels);
        }
      });
    });

    scheduleMicrotask(() {
      if (!mounted || handledByResolver || !widget.controller.hasClients) {
        return;
      }

      final fallbackPosition = widget.controller.position;
      if (!fallbackPosition.haveDimensions) {
        _logSmoothWheel('fallbackIgnored', {'reason': 'noDimensions'});
        return;
      }

      final clampedStart = startPixels
          .clamp(
            fallbackPosition.minScrollExtent,
            fallbackPosition.maxScrollExtent,
          )
          .toDouble();
      if ((fallbackPosition.pixels - clampedStart).abs() > 0.5) {
        _logSmoothWheel('fallbackReset', {
          'target': _scrollNumber(clampedStart),
        });
        widget.controller.jumpTo(clampedStart);
      }

      _logSmoothWheel('fallbackAccepted', {
        'delta': _scrollNumber(delta),
        'start': _scrollNumber(clampedStart),
      });
      _animateWheelDelta(delta, startPixels: clampedStart);
    });
  }

  void _animateWheelDelta(double delta, {required double startPixels}) {
    final position = widget.controller.position;
    if (!position.haveDimensions) {
      return;
    }

    final current = _hasTargetPixels ? _targetPixels : startPixels;
    final target = (current + delta * widget.scrollMultiplier)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if ((target - position.pixels).abs() < 0.5) {
      _logSmoothWheel('noop', {
        'delta': _scrollNumber(delta),
        'target': _scrollNumber(target),
      });
      return;
    }

    _targetPixels = target;
    _hasTargetPixels = true;
    final generation = ++_scrollGeneration;
    _logSmoothWheel('animate', {
      'delta': _scrollNumber(delta),
      'start': _scrollNumber(startPixels),
      'target': _scrollNumber(target),
      'generation': generation,
    });
    widget.controller
        .animateTo(target, duration: widget.duration, curve: widget.curve)
        .whenComplete(() {
          _logSmoothWheel('complete', {
            'target': _scrollNumber(target),
            'generation': generation,
            'activeGeneration': _scrollGeneration,
          });
          if (mounted && generation == _scrollGeneration) {
            _hasTargetPixels = false;
          }
        });
  }

  void _logSmoothWheel(String event, Map<String, Object?> fields) {
    if (!kDebugMode) {
      return;
    }
    final metrics = widget.controller.hasClients
        ? widget.controller.position
        : null;
    debugPrint(
      'verdant.scroll smoothWheel.$event {'
      'hasClients: ${widget.controller.hasClients}, '
      'pixels: ${_scrollNumber(metrics?.pixels)}, '
      'min: ${_scrollNumber(metrics?.minScrollExtent)}, '
      'max: ${_scrollNumber(metrics?.maxScrollExtent)}, '
      'hasTarget: $_hasTargetPixels, '
      'target: ${_scrollNumber(_targetPixels)}, '
      'fields: $fields'
      '}',
    );
  }
}

class SmoothSingleChildScrollView extends StatefulWidget {
  const SmoothSingleChildScrollView({
    required this.child,
    this.controller,
    this.padding,
    this.primary,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.physics,
    this.scrollMultiplier = 1,
    this.duration = _defaultSmoothScrollDuration,
    this.curve = _defaultSmoothScrollCurve,
    super.key,
  });

  final Widget child;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool? primary;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollPhysics? physics;
  final double scrollMultiplier;
  final Duration duration;
  final Curve curve;

  @override
  State<SmoothSingleChildScrollView> createState() =>
      _SmoothSingleChildScrollViewState();
}

Object? _scrollNumber(double? value) {
  if (value == null || !value.isFinite) {
    return value;
  }
  return (value * 10).roundToDouble() / 10;
}

class _SmoothSingleChildScrollViewState
    extends State<SmoothSingleChildScrollView> {
  ScrollController? _ownedController;

  ScrollController get _controller =>
      widget.controller ?? (_ownedController ??= ScrollController());

  @override
  void didUpdateWidget(covariant SmoothSingleChildScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller &&
        widget.controller != null) {
      _ownedController?.dispose();
      _ownedController = null;
    }
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return SmoothWheelScroll(
      controller: controller,
      scrollDirection: widget.scrollDirection,
      scrollMultiplier: widget.scrollMultiplier,
      duration: widget.duration,
      curve: widget.curve,
      onWheelScrollDelta: null,
      child: SingleChildScrollView(
        controller: controller,
        padding: widget.padding,
        primary: widget.primary,
        scrollDirection: widget.scrollDirection,
        reverse: widget.reverse,
        physics: widget.physics,
        child: widget.child,
      ),
    );
  }
}
