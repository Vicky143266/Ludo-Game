import 'dart:math';
import 'package:flutter/material.dart';

class DiceWidget extends StatefulWidget {
  final int value;
  final bool isRolling;
  final VoidCallback onRoll;

  const DiceWidget({
    super.key,
    required this.value,
    required this.isRolling,
    required this.onRoll,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _rollController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  int _displayValue = 1;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value;

    _rollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2).animate(
      CurvedAnimation(
        parent: _rollController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 0.9, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 30),
    ]).animate(_rollController);
  }

  @override
  void didUpdateWidget(DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRolling && !oldWidget.isRolling) {
      _startRollAnimation();
    }

    if (!widget.isRolling && oldWidget.isRolling) {
      _displayValue = widget.value;
      setState(() {});
    }
  }

  void _startRollAnimation() {
    _rollController.reset();
    _rollController.forward();

    // Rapidly cycle display value during phase 1 (0–700ms)
    _cycleValues();
  }

  void _cycleValues() {
    if (!widget.isRolling || !mounted) return;
    setState(() {
      _displayValue = _random.nextInt(6) + 1;
    });
    Future.delayed(const Duration(milliseconds: 80), _cycleValues);
  }

  @override
  void dispose() {
    _rollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rollController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: RotationTransition(
            turns: _rotationAnimation,
            child: child,
          ),
        );
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: _DiceFace(value: _displayValue),
        ),
      ),
    );
  }
}

class _DiceFace extends StatelessWidget {
  final int value;

  const _DiceFace({required this.value});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotPainter(value: value),
    );
  }
}

class _DotPainter extends CustomPainter {
  final int value;

  const _DotPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1040)
      ..style = PaintingStyle.fill;

    final dotRadius = size.width * 0.12;
    final w = size.width;
    final h = size.height;

    // Dot positions for each face value
    final positions = _getDotPositions(value, w, h);
    for (final pos in positions) {
      canvas.drawCircle(pos, dotRadius, paint);
    }
  }

  List<Offset> _getDotPositions(int value, double w, double h) {
    final tl = Offset(w * 0.25, h * 0.25);
    final tr = Offset(w * 0.75, h * 0.25);
    final ml = Offset(w * 0.25, h * 0.5);
    final mr = Offset(w * 0.75, h * 0.5);
    final bl = Offset(w * 0.25, h * 0.75);
    final br = Offset(w * 0.75, h * 0.75);
    final center = Offset(w * 0.5, h * 0.5);

    switch (value) {
      case 1:
        return [center];
      case 2:
        return [tr, bl];
      case 3:
        return [tr, center, bl];
      case 4:
        return [tl, tr, bl, br];
      case 5:
        return [tl, tr, center, bl, br];
      case 6:
        return [tl, tr, ml, mr, bl, br];
      default:
        return [center];
    }
  }

  @override
  bool shouldRepaint(covariant _DotPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
