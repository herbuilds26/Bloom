import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Local vector lily artwork; no remote image or generated asset required.
class BloomFlower extends StatelessWidget {
  const BloomFlower(
      {super.key, this.size = 96, this.progress = 1, this.glow = false});
  final double size;
  final double progress;
  final bool glow;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _FlowerPainter(progress.clamp(0.0, 1.0).toDouble(), glow),
        child: SizedBox.square(dimension: size),
      );
}

class _FlowerPainter extends CustomPainter {
  const _FlowerPainter(this.progress, this.glow);
  final double progress;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * .52);
    final unit = size.shortestSide;
    if (glow) {
      canvas.drawCircle(
          c,
          unit * .43,
          Paint()
            ..color = const Color(0xFFFFD9EC).withValues(alpha: .30)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13));
    }
    // Stem and leaves
    final stem = Paint()
      ..color = const Color(0xFF768755)
      ..strokeWidth = unit * .025
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final stemPath = Path()
      ..moveTo(c.dx, c.dy + unit * .10)
      ..quadraticBezierTo(c.dx + unit * .04, c.dy + unit * .29,
          c.dx - unit * .01, size.height * .96);
    canvas.drawPath(stemPath, stem);
    _leaf(canvas, c + Offset(-unit * .01, unit * .28), -1, unit);
    _leaf(canvas, c + Offset(unit * .02, unit * .36), 1, unit);

    final colors = [
      const Color(0xFFF47CA9),
      const Color(0xFFE95C91),
      const Color(0xFFFFA5C4),
      const Color(0xFFCF4173),
      const Color(0xFFFFBCD2),
      const Color(0xFFE77AA8)
    ];
    for (var i = 0; i < 6; i++) {
      final delay = i * .075;
      final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      final open = Curves.easeOutBack.transform(t);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate((i * math.pi / 3) - math.pi / 2);
      canvas.scale(.10 + .90 * open, .18 + .82 * open);
      final path = Path()
        ..moveTo(0, unit * .04)
        ..cubicTo(
            -unit * .17, -unit * .10, -unit * .18, -unit * .37, 0, -unit * .43)
        ..cubicTo(
            unit * .18, -unit * .37, unit * .17, -unit * .10, 0, unit * .04)
        ..close();
      canvas.drawPath(
          path,
          Paint()
            ..shader = LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors[i], const Color(0xFFFFE5EF)])
                .createShader(
                    Rect.fromCircle(center: Offset.zero, radius: unit * .5)));
      canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFB64179).withValues(alpha: .35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = unit * .008);
      canvas.drawLine(
          Offset.zero,
          Offset(0, -unit * .31),
          Paint()
            ..color = Colors.white.withValues(alpha: .55)
            ..strokeWidth = unit * .008);
      canvas.restore();
    }
    final centerPaint = Paint()..color = const Color(0xFFFFD47B);
    for (var i = -2; i <= 2; i++) {
      final x = c.dx + i * unit * .035;
      canvas.drawLine(
          c,
          Offset(x, c.dy - unit * (.16 + (2 - i.abs()) * .035)),
          Paint()
            ..color = const Color(0xFF806040)
            ..strokeWidth = unit * .008);
      canvas.drawCircle(Offset(x, c.dy - unit * (.16 + (2 - i.abs()) * .035)),
          unit * .012, centerPaint);
    }
  }

  void _leaf(Canvas canvas, Offset origin, double direction, double unit) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(direction * -.58);
    final p = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(direction * unit * .20, -unit * .13,
          direction * unit * .28, -unit * .01)
      ..quadraticBezierTo(direction * unit * .14, unit * .08, 0, 0);
    canvas.drawPath(p, Paint()..color = const Color(0xFF9EAD77));
    canvas.drawPath(
        p,
        Paint()
          ..color = const Color(0xFF687B4D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = unit * .009);
    canvas.drawLine(
        Offset.zero,
        Offset(direction * unit * .24, -unit * .01),
        Paint()
          ..color = const Color(0xFF66794E)
          ..strokeWidth = unit * .008);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FlowerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.glow != glow;
}
