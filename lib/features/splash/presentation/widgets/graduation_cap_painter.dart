import 'package:flutter/material.dart';

class GraduationCapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final Paint outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Draw the square part (mortarboard)
    final squarePath = Path()
      ..moveTo(size.width * 0.25, size.height * 0.45)
      ..lineTo(size.width * 0.75, size.height * 0.45)
      ..lineTo(size.width * 0.65, size.height * 0.3)
      ..lineTo(size.width * 0.35, size.height * 0.3)
      ..close();

    canvas.drawPath(squarePath, paint);
    canvas.drawPath(squarePath, outlinePaint);

    // Draw the cap (curved part)
    final capPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeWidth = 1;

    final capPath = Path()
      ..moveTo(size.width * 0.3, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.6,
        size.width * 0.7,
        size.height * 0.45,
      )
      ..lineTo(size.width * 0.65, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.55,
        size.width * 0.35,
        size.height * 0.45,
      )
      ..close();

    canvas.drawPath(capPath, capPaint);

    // Draw decorative lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.32),
      Offset(size.width * 0.65, size.height * 0.32),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.35),
      Offset(size.width * 0.6, size.height * 0.35),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}