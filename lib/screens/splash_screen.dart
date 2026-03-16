import 'dart:math' as math;

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _circleProgress;
  late final Animation<double> _starProgress;
  late final Animation<double> _startOpacity;
  late final Animation<double> _startYOffset;
  late final Animation<double> _circleScale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _circleProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.68, curve: Curves.easeOutCubic),
    );

    _starProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.06, 0.7, curve: Curves.easeOutCubic),
    );

    _startOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.72, 0.9, curve: Curves.easeInOut),
    );

    _startYOffset = Tween<double>(begin: 14, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.72, 0.92, curve: Curves.easeOutCubic),
      ),
    );

    _circleScale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacementNamed('/app');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: _circleScale.value,
                  child: SizedBox(
                    width: 340,
                    height: 340,
                    child: CustomPaint(
                      painter: _SplashCirclePainter(
                        progress: _circleProgress.value,
                        starProgress: _starProgress.value,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Transform.translate(
                  offset: Offset(0, _startYOffset.value),
                  child: Opacity(
                    opacity: _startOpacity.value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/icon/icon.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'START',
                          style: TextStyle(
                            fontSize: 26,
                            letterSpacing: 5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SplashCirclePainter extends CustomPainter {
  _SplashCirclePainter({required this.progress, required this.starProgress});

  final double progress;
  final double starProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 20;

    final sweepTotal = 2 * math.pi * 0.9;
    final startAngle = -math.pi / 2 - 0.78;
    final sweep = sweepTotal * progress;

    final paintStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.black
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      paintStroke,
    );

    final starAngle = startAngle + (sweepTotal * starProgress);
    final starCenter = Offset(
      center.dx + radius * math.cos(starAngle),
      center.dy + radius * math.sin(starAngle),
    );

    _drawSparkStar(canvas, starCenter, 16, Colors.black);
  }

  void _drawSparkStar(Canvas canvas, Offset center, double r, Color color) {
    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < 8; i++) {
      final angle = (-math.pi / 2) + (i * math.pi / 4);
      final radius = i.isEven ? r : r * 0.42;
      points.add(
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
      );
    }

    path.moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();

    final fill = Paint()..color = color;
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant _SplashCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.starProgress != starProgress;
  }
}
