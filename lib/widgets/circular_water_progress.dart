import 'dart:math';
import 'package:flutter/material.dart';

class CircularWaterProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final int currentMl;
  final int goalMl;

  const CircularWaterProgress({
    super.key,
    required this.progress,
    required this.currentMl,
    required this.goalMl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: _CircularProgressPainter(progress: progress),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: currentMl / 1000),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, _) => Text(
                  '${value.toStringAsFixed(1)} L',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
              Text(
                'of ${(goalMl / 1000).toStringAsFixed(1)} L',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                progress >= 1.0 ? '🎉 Goal reached!' : '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: progress >= 1.0 ? Colors.tealAccent : Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  _CircularProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 12.0;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [Colors.cyanAccent, Colors.tealAccent],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) => old.progress != progress;
}
