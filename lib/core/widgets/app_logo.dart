import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:recipe_mobile_app/core/theme/theme.dart';

/// Icon app (bát cơm và đôi đũa trên nền `chili-soft`), vẽ theo
/// `docs/design/design-system/assets/Logos/bep-hoa-lac-icon.svg`.
///
/// Icon giữ màu thương hiệu của theme sáng ở cả hai theme, như icon trên màn hình chính.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      // Bo 9/32 như header prototype `Main`.
      borderRadius: BorderRadius.circular(size * 9 / 32),
      child: CustomPaint(size: Size.square(size), painter: const _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const colors = AppColors.light;
    // Toạ độ theo viewBox 96×96 của file SVG.
    canvas.scale(size.width / 96);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 96, 96), Paint()..color = colors.chiliSoft);
    canvas.translate(-2, -1);
    final chopsticks = Paint()
      ..color = colors.chili
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(38, 44), const Offset(74, 18), chopsticks);
    canvas.drawLine(const Offset(48, 46), const Offset(82, 24), chopsticks);
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(48, 50), radius: 30),
      0,
      math.pi,
      true,
      Paint()..color = colors.ink,
    );
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => false;
}
