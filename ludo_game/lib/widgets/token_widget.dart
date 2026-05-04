import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/game_enums.dart';
import '../models/token.dart';

class TokenWidget extends StatefulWidget {
  final Token token;
  final double cellSize;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const TokenWidget({
    super.key,
    required this.token,
    required this.cellSize,
    this.isHighlighted = false,
    this.onTap,
  });

  @override
  State<TokenWidget> createState() => _TokenWidgetState();
}

class _TokenWidgetState extends State<TokenWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isHighlighted) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TokenWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isHighlighted && oldWidget.isHighlighted) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color    = widget.token.color.color;
    final diameter = widget.cellSize * 0.75;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) => Transform.scale(
          scale: widget.isHighlighted ? _pulseAnimation.value : 1.0,
          child: child,
        ),
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: CustomPaint(
            painter: _TokenPainter(
              color: color,
              isHighlighted: widget.isHighlighted,
              isFinished: widget.token.isFinished,
            ),
          ),
        ),
      ),
    );
  }
}

class _TokenPainter extends CustomPainter {
  final Color color;
  final bool isHighlighted;
  final bool isFinished;

  const _TokenPainter({
    required this.color,
    required this.isHighlighted,
    required this.isFinished,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    // Glow when highlighted
    if (isHighlighted) {
      canvas.drawCircle(
        Offset(cx, cy),
        r * 1.15,
        Paint()
          ..color = Colors.white.withOpacity(0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // Drop shadow
    canvas.drawCircle(
      Offset(cx + 1, cy + 2),
      r * 0.88,
      Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // White outer ring
    canvas.drawCircle(Offset(cx, cy), r * 0.92,
        Paint()..color = Colors.white);

    // Colored fill
    canvas.drawCircle(Offset(cx, cy), r * 0.76,
        Paint()..color = color);

    // Inner shadow ring
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.76,
      Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.1,
    );

    // Glossy highlight
    canvas.drawCircle(
      Offset(cx - r * 0.22, cy - r * 0.25),
      r * 0.28,
      Paint()..color = Colors.white.withOpacity(0.45),
    );

    // Finished star
    if (isFinished) {
      _drawStar(canvas, Offset(cx, cy), r * 0.38, Colors.white);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    const pts = 5;
    final inner = radius * 0.42;
    for (int i = 0; i < pts * 2; i++) {
      final r2 = i.isEven ? radius : inner;
      final angle = (i * math.pi / pts) - math.pi / 2;
      final x = center.dx + r2 * math.cos(angle);
      final y = center.dy + r2 * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TokenPainter old) =>
      old.color != color ||
      old.isHighlighted != isHighlighted ||
      old.isFinished != isFinished;
}
