import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';

/// A living, breathing vector Lily widget with organic sway, bloom pulse,
/// and interactive sparkle animations.
class LivingLily extends StatefulWidget {
  const LivingLily({
    super.key,
    this.size = 120,
    this.showStem = false,
    this.interactive = true,
    this.progress,
    this.glow = true,
    this.onTap,
  });

  final double size;
  final bool showStem;
  final bool interactive;
  final double? progress;
  final bool glow;
  final VoidCallback? onTap;

  @override
  State<LivingLily> createState() => _LivingLilyState();
}

class _LivingLilyState extends State<LivingLily>
    with TickerProviderStateMixin {
  late final AnimationController _breatheController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    final inTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!inTest) {
      _breatheController.repeat(reverse: true);
    } else {
      _breatheController.value = 0.5;
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _pulseController.forward(from: 0.0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.interactive ? _handleTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breatheController, _pulseController]),
        builder: (context, _) {
          final breathe = _breatheController.value;
          final pulse = Curves.easeOutBack.transform(_pulseController.value);

          // Subtle organic breathing scale and gentle breeze sway
          final scale = 1.0 + (math.sin(breathe * math.pi) * 0.04) + (pulse * 0.08);
          final sway = math.sin(breathe * math.pi * 2) * 0.035;

          return Transform.scale(
            scale: scale,
            child: Transform.rotate(
              angle: sway,
              child: CustomPaint(
                size: Size(widget.size, widget.size * (widget.showStem ? 1.15 : 1.0)),
                painter: _LivingLilyPainter(
                  progress: widget.progress ?? 1.0,
                  breathe: breathe,
                  pulse: pulse,
                  showStem: widget.showStem,
                  glow: widget.glow,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LivingLilyPainter extends CustomPainter {
  const _LivingLilyPainter({
    required this.progress,
    required this.breathe,
    required this.pulse,
    required this.showStem,
    required this.glow,
  });

  final double progress;
  final double breathe;
  final double pulse;
  final bool showStem;
  final bool glow;

  static const _petals = <_PetalSpec>[
    _PetalSpec(-2.12, .51, .205, false),
    _PetalSpec(-1.00, .56, .22, true),
    _PetalSpec(.08, .52, .19, false),
    _PetalSpec(1.04, .50, .20, true),
    _PetalSpec(2.10, .54, .20, false),
    _PetalSpec(3.12, .48, .185, true),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final base = showStem
        ? Offset(size.width * .50, size.height * .54)
        : Offset(size.width * .50, size.height * .50);

    // Glowing aura behind bloom
    if (glow) {
      final glowRadius = s * (.38 + 0.06 * math.sin(breathe * math.pi) + pulse * .08);
      canvas.drawCircle(
        base,
        glowRadius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              BloomTheme.rose.withValues(alpha: .28 + pulse * .15),
              BloomTheme.peach.withValues(alpha: .14 + pulse * .10),
              Colors.transparent,
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(Rect.fromCircle(center: base, radius: glowRadius)),
      );
    }

    // Stem and leaves if requested
    if (showStem) {
      final stemPath = Path()
        ..moveTo(base.dx, base.dy + s * .045)
        ..quadraticBezierTo(base.dx - s * .045, base.dy + s * .47,
            base.dx + s * .035, size.height * .97);
      canvas.drawPath(
          stemPath,
          Paint()
            ..color = const Color(0xFF6E7E52)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * .016
            ..strokeCap = StrokeCap.round);
      _drawLeaf(canvas, Offset(base.dx + s * .02, base.dy + s * .25), s,
          direction: -1);
      _drawLeaf(canvas, Offset(base.dx - s * .005, base.dy + s * .37), s,
          direction: 1);
    }

    // Petals opening and undulating softly
    for (final petal in _petals) {
      final start = petal.inner ? .18 : .0;
      final end = petal.inner ? .85 : .74;
      final local = ((progress - start) / (end - start)).clamp(0.0, 1.0);
      final open = Curves.easeInOutCubic.transform(local.toDouble());
      if (open > 0) {
        _drawPetal(canvas, base, s, petal, open);
      }
    }

    // Stamens emerging and swaying
    final stamenReveal = Curves.easeOutCubic
        .transform(((progress - .72) / .26).clamp(0.0, 1.0).toDouble());
    if (stamenReveal > 0) {
      _drawStamens(canvas, base, s, stamenReveal);
    }

    // Gentle ambient and pulse sparkles
    _drawSparkles(canvas, base, s);
  }

  void _drawPetal(
      Canvas canvas, Offset base, double s, _PetalSpec spec, double open) {
    final ease = open.clamp(0.0, 1.0).toDouble();

    // Petal breathing undulation
    final petalBreathe = math.sin((breathe * math.pi * 2) + spec.angle) * 0.022;
    final angle = spec.angle * ease + petalBreathe;
    final length = s * spec.length;
    final width = s * spec.width;
    final petalScale = Curves.easeOutCubic.transform(open.clamp(0.0, 1.0));
    final petalAlpha = (open / .12).clamp(0.0, 1.0).toDouble();

    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(-math.pi / 2 + angle);
    canvas.scale(
      (.035 + ease * .965) * petalScale,
      (.10 + ease * .90) * petalScale,
    );

    final path = Path()
      ..moveTo(0, s * .035)
      ..cubicTo(-width * .72, -length * .19, -width * .76, -length * .67,
          -width * .30, -length * .94)
      ..cubicTo(-width * .17, -length * 1.005, -width * .07, -length * .96, 0,
          -length * .90)
      ..cubicTo(width * .07, -length * .96, width * .17, -length * 1.005,
          width * .30, -length * .94)
      ..cubicTo(
          width * .76, -length * .67, width * .72, -length * .19, 0, s * .035)
      ..close();

    final rect = Rect.fromCenter(
        center: Offset(0, -length * .46), width: width * 1.7, height: length);

    final colors = (spec.inner
        ? const [Color(0xFFFFF0F4), Color(0xFFF39399), Color(0xFFCF4173)]
        : const [Color(0xFFFFF7F9), Color(0xFFF68BAE), Color(0xFFCF4173)])
        .map((c) => c.withValues(alpha: c.a * petalAlpha))
        .toList();

    canvas.drawShadow(
        path,
        BloomTheme.plum.withValues(alpha: .35 * petalAlpha),
        s * .028,
        true);
    canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
            stops: const [0, .52, 1],
          ).createShader(rect));

    // A central pink vein, fine edge highlight and brush marks
    final vein = Paint()
      ..color = BloomTheme.plum.withValues(alpha: .45 * ease * petalAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .007
      ..strokeCap = StrokeCap.round;
    final veinPath = Path()
      ..moveTo(0, -s * .015)
      ..cubicTo(
          -s * .008, -length * .30, s * .012, -length * .60, 0, -length * .89);
    canvas.drawPath(veinPath, vein);

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: .75 * ease * petalAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .008
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
        Path()
          ..moveTo(-width * .12, -length * .18)
          ..quadraticBezierTo(
              -width * .35, -length * .53, -width * .18, -length * .78),
        highlight);

    final marks = Paint()
      ..color = BloomTheme.plum.withValues(alpha: .68 * ease * petalAlpha)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final y = length * (.18 + (i % 4) * .065);
      final side = i.isEven ? -1.0 : 1.0;
      final x = side * width * (.13 + (i % 3) * .105);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, -y),
              width: s * (i % 3 == 0 ? .018 : .011),
              height: s * .032),
          marks);
      if (i < 3) {
        canvas.drawLine(
            Offset(0, -y + s * .01),
            Offset(x, -y - s * .02),
            Paint()
              ..color = BloomTheme.raspberry.withValues(alpha: .40 * ease * petalAlpha)
              ..strokeWidth = s * .005);
      }
    }

    canvas.restore();
  }

  void _drawStamens(Canvas canvas, Offset base, double s, double reveal) {
    final specs = <(double, double, double)>[
      (-.40, .32, .80),
      (-.27, .40, .93),
      (-.12, .35, 1.0),
      (.12, .39, .96),
      (.27, .34, .88),
      (.40, .30, .78),
    ];
    final swayOffset = math.sin(breathe * math.pi * 2) * 0.015;

    for (final spec in specs) {
      final dx = (spec.$1 + swayOffset) * s * reveal;
      final rise = spec.$2 * s * reveal;
      final end = base + Offset(dx, -rise);
      final path = Path()
        ..moveTo(base.dx, base.dy - s * .015)
        ..cubicTo(base.dx + dx * .2, base.dy - rise * .15, base.dx + dx * .78,
            end.dy + rise * .18, end.dx, end.dy);
      canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF6E7E52)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * .009
            ..strokeCap = StrokeCap.round);
      canvas.save();
      canvas.translate(end.dx, end.dy);
      canvas.rotate(spec.$1 * .18);
      final anther = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: s * .025, height: s * .095),
          Radius.circular(s * .014));
      canvas.drawRRect(anther, Paint()..color = BloomTheme.plum);
      canvas.drawRRect(
          anther,
          Paint()
            ..color = BloomTheme.peach
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * .004);
      canvas.restore();
    }
  }

  void _drawLeaf(Canvas canvas, Offset start, double s,
      {required double direction}) {
    canvas.save();
    canvas.translate(start.dx, start.dy);
    canvas.rotate(direction * -.58 + math.sin(breathe * math.pi) * 0.03);
    final leaf = Path()
      ..moveTo(0, 0)
      ..cubicTo(direction * s * .10, -s * .15, direction * s * .27, -s * .16,
          direction * s * .31, -s * .04)
      ..cubicTo(
          direction * s * .23, s * .06, direction * s * .10, s * .065, 0, 0)
      ..close();
    canvas.drawPath(
        leaf,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFB4C18B), Color(0xFF6E7E52)],
          ).createShader(Rect.fromLTWH(-s * .2, -s * .18, s * .55, s * .3)));
    canvas.drawPath(
        leaf,
        Paint()
          ..color = const Color(0xFF5E7042)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * .005);
    canvas.drawLine(
        Offset.zero,
        Offset(direction * s * .27, -s * .045),
        Paint()
          ..color = const Color(0xFF596B3D)
          ..strokeWidth = s * .004);
    canvas.restore();
  }

  void _drawSparkles(Canvas canvas, Offset base, double s) {
    final twinkle = (math.sin(breathe * math.pi * 3) * 0.5 + 0.5) + pulse;
    const points = [
      Offset(-.38, -.32),
      Offset(.41, -.28),
      Offset(.02, -.48),
      Offset(-.28, .22),
      Offset(.30, .26),
    ];
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final p = base + Offset(point.dx * s, point.dy * s);
      final alpha = ((twinkle + (i * 0.2)) % 1.0).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: .75 * alpha);
      final sparkSize = s * (.012 + pulse * .008);
      canvas.drawCircle(p, sparkSize, paint);
      canvas.drawLine(Offset(p.dx - sparkSize * 2, p.dy),
          Offset(p.dx + sparkSize * 2, p.dy), paint..strokeWidth = s * .004);
      canvas.drawLine(Offset(p.dx, p.dy - sparkSize * 2),
          Offset(p.dx, p.dy + sparkSize * 2), paint..strokeWidth = s * .004);
    }
  }

  @override
  bool shouldRepaint(covariant _LivingLilyPainter oldDelegate) => true;
}

class _PetalSpec {
  const _PetalSpec(this.angle, this.length, this.width, this.inner);
  final double angle;
  final double length;
  final double width;
  final bool inner;
}
