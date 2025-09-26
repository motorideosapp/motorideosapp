
import 'dart:math' as math;
import 'package:flutter/material.dart';

class SpeedometerWidget extends StatelessWidget {
  final double speed;
  final double maxSpeed;

  const SpeedometerWidget({
    super.key,
    required this.speed,
    this.maxSpeed = 240,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(250, 250),
            painter: SpeedometerPainter(
              speed: speed,
              maxSpeed: maxSpeed,
              context: context, // Pass context to the painter
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                speed.toInt().toString(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                        blurRadius: 20.0, color: Theme.of(context).primaryColor),
                  ],
                ),
              ),
              Text(
                'KM/H',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SpeedometerPainter extends CustomPainter {
  final double speed;
  final double maxSpeed;
  final BuildContext context;

  SpeedometerPainter({
    required this.speed,
    required this.maxSpeed,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final theme = Theme.of(context);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const startAngle = (5 * math.pi) / 6;
    const sweepAngle = (4 * math.pi) / 3;

    final backgroundPaint = Paint()
      ..color = theme.colorScheme.onSurface.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        sweepAngle, false, backgroundPaint);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(colors: [
        theme.primaryColor,
        theme.colorScheme.secondary,
      ]).createShader(Rect.fromCircle(center: center, radius: radius));
    progressPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    final progress = (speed / maxSpeed).clamp(0.0, 1.0);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        sweepAngle * progress, false, progressPaint);

    final tickPaint = Paint()
      ..color = theme.colorScheme.onSurface.withOpacity(0.5)
      ..strokeWidth = 2.0;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    const majorTickCount = 12;
    for (int i = 0; i <= majorTickCount; i++) {
      final tickAngle = startAngle + (i / majorTickCount) * sweepAngle;
      final tickSpeed = (i * 20);

      final innerMajorTick = Offset(
        center.dx + (radius - 28) * math.cos(tickAngle),
        center.dy + (radius - 28) * math.sin(tickAngle),
      );
      final outerMajorTick = Offset(
        center.dx + (radius - 15) * math.cos(tickAngle),
        center.dy + (radius - 15) * math.sin(tickAngle),
      );
      canvas.drawLine(innerMajorTick, outerMajorTick, tickPaint);

      textPainter.text = TextSpan(
        text: tickSpeed.toString(),
        style: TextStyle(
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();

      final textOffset = Offset(
        center.dx + (radius - 45) * math.cos(tickAngle) - textPainter.width / 2,
        center.dy + (radius - 45) * math.sin(tickAngle) - textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);
    }

    const minorTickCount = 24;
    for (int i = 0; i <= minorTickCount; i++) {
      if (i % 2 == 0) continue;

      final tickAngle = startAngle + (i / minorTickCount) * sweepAngle;

      final innerMinorTick = Offset(
        center.dx + (radius - 22) * math.cos(tickAngle),
        center.dy + (radius - 22) * math.sin(tickAngle),
      );
      final outerMinorTick = Offset(
        center.dx + (radius - 15) * math.cos(tickAngle),
        center.dy + (radius - 15) * math.sin(tickAngle),
      );
      canvas.drawLine(innerMinorTick, outerMinorTick, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SpeedometerPainter oldDelegate) {
    return speed != oldDelegate.speed ||
        maxSpeed != oldDelegate.maxSpeed ||
        context != oldDelegate.context;
  }
}
