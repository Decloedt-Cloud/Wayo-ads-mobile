import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// GPU fragment shader backdrop; falls back to solid [fallback] if compile/load fails.
class LiquidMetalBackground extends StatefulWidget {
  const LiquidMetalBackground({
    super.key,
    required this.time,
    this.fallback = const Color(0xFF0A0A0A),
  });

  final double time;
  final Color fallback;

  @override
  State<LiquidMetalBackground> createState() => _LiquidMetalBackgroundState();
}

class _LiquidMetalBackgroundState extends State<LiquidMetalBackground> {
  ui.FragmentProgram? _program;
  ui.FragmentShader? _shader;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await ui.FragmentProgram.fromAsset('shaders/liquid_metal.frag');
      if (!mounted) {
        return;
      }
      _shader?.dispose();
      _shader = p.fragmentShader();
      setState(() => _program = p);
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || _program == null || _shader == null) {
      return ColoredBox(color: widget.fallback);
    }
    return CustomPaint(
      painter: _LiquidMetalPainter(shader: _shader!, time: widget.time),
      size: Size.infinite,
    );
  }
}

class _LiquidMetalPainter extends CustomPainter {
  _LiquidMetalPainter({required this.shader, required this.time});

  final ui.FragmentShader shader;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _LiquidMetalPainter oldDelegate) =>
      oldDelegate.time != time;
}
