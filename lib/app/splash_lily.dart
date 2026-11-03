import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Six independently animated botanical lily tepals, drawn in hardware-accelerated
/// vector paths, unfurling smoothly and sequentially ("petal-by-petal") from a closed bud.
class SplashLily extends StatelessWidget {
  const SplashLily({super.key, required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(280.0, 360.0).toDouble()
            : 360.0;
        return CustomPaint(
          painter: _LilyPainter(progress.clamp(0.0, 1.0).toDouble()),
          child: SizedBox(width: width, height: width * 1.08),
        );
      });
}

class _LilyPainter extends CustomPainter {
  const _LilyPainter(this.progress);
  final double progress;

  // Staggered botanical petal schedule:
  // Outer 3 tepals open first, followed sequentially by inner 3 tepals,
  // providing a realistic, slow, petal-by-petal unfolding sequence.
  static const _petals = <_PetalSpec>[
    // 1. Outer Top Tepal
    _PetalSpec(
      angle: .05,
      length: .54,
      width: .195,
      inner: false,
      start: .22,
      end: .52,
    ),
    // 2. Outer Lower-Right Tepal
    _PetalSpec(
      angle: 2.12,
      length: .56,
      width: .205,
      inner: false,
      start: .30,
      end: .60,
    ),
    // 3. Outer Lower-Left Tepal
    _PetalSpec(
      angle: -2.12,
      length: .54,
      width: .205,
      inner: false,
      start: .38,
      end: .68,
    ),
    // 4. Inner Upper-Right Tepal
    _PetalSpec(
      angle: 1.05,
      length: .52,
      width: .220,
      inner: true,
      start: .48,
      end: .76,
    ),
    // 5. Inner Upper-Left Tepal
    _PetalSpec(
      angle: -1.02,
      length: .57,
      width: .230,
      inner: true,
      start: .56,
      end: .84,
    ),
    // 6. Inner Lower-Center Tepal
    _PetalSpec(
      angle: 3.14,
      length: .49,
      width: .195,
      inner: true,
      start: .64,
      end: .90,
    ),
  ];

  // Reusable Paint objects to eliminate GC allocations during the 60fps render loop
  static final Paint _paintFill = Paint()..style = PaintingStyle.fill;
  static final Paint _paintStroke = Paint()..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final base = Offset(size.width * .50, size.height * .57);

    // 0. Soft warm floral aura behind the blossoming flower
    final auraProgress =
        Curves.easeOut.transform(((progress - .72) / .28).clamp(0.0, 1.0));
    if (auraProgress > 0) {
      _drawAura(canvas, base, s, auraProgress);
    }

    // 1. Stem physically rises smoothly from bottom of screen to floral receptacle
    final stemT =
        Curves.easeOutCubic.transform((progress / .20).clamp(0.0, 1.0));
    final fullStemPath = Path()
      ..moveTo(base.dx + s * .030, size.height * .97)
      ..quadraticBezierTo(
        base.dx - s * .040,
        base.dy + s * .46,
        base.dx,
        base.dy + s * .040,
      );

    if (stemT > 0) {
      final metrics = fullStemPath.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final metric = metrics.first;
        final currentStem = metric.extractPath(0.0, metric.length * stemT);
        _paintStroke
          ..color = const Color(0xFF637648)
          ..strokeWidth = s * .0095
          ..strokeCap = StrokeCap.round
          ..shader = null;
        canvas.drawPath(currentStem, _paintStroke);
      }
    }

    // Leaves sprout and unfurl naturally as the stem ascends
    final leaf1T = Curves.easeOutCubic
        .transform(((progress - .09) / .12).clamp(0.0, 1.0));
    _drawLeaf(canvas, Offset(base.dx - s * .005, base.dy + s * .36), s,
        direction: 1, reveal: leaf1T);

    final leaf2T = Curves.easeOutCubic
        .transform(((progress - .13) / .12).clamp(0.0, 1.0));
    _drawLeaf(canvas, Offset(base.dx + s * .020, base.dy + s * .24), s,
        direction: -1, reveal: leaf2T);

    // 2. Closed floral bud emerges at the stem tip, then parts open as petals unfurl
    final budAppear = Curves.easeOutCubic
        .transform(((progress - .06) / .14).clamp(0.0, 1.0));
    final budFade = 1.0 -
        Curves.easeInOut.transform(((progress - .22) / .22).clamp(0.0, 1.0));
    final budOpacity = (budAppear * budFade).clamp(0.0, 1.0);
    if (budOpacity > 0.0) {
      _drawBud(canvas, base, s, budOpacity, budAppear);
    }

    // 3. True Sequential Petal-by-Petal Blooming:
    // Outer petals bloom first, followed by the inner petals, each with its own
    // dedicated smooth opening curve.
    for (final petal in _petals) {
      if (progress < petal.start) continue;
      final local =
          ((progress - petal.start) / (petal.end - petal.start)).clamp(0.0, 1.0);
      final open = Curves.easeInOutCubic.transform(local.toDouble());
      _drawPetal(canvas, base, s, petal, open, local.toDouble(), progress);
    }

    // 4. Central floral throat, filaments and golden pollen anthers emerge
    final stamenProgress = Curves.easeOutCubic
        .transform(((progress - .74) / .20).clamp(0.0, 1.0).toDouble());
    if (stamenProgress > 0) {
      _drawCenterAndStamens(canvas, base, s, stamenProgress);
    }

    // 5. Delicate sparkling floral dust once full bloom is reached
    final sparkleProgress = Curves.easeOutCubic
        .transform(((progress - .88) / .12).clamp(0.0, 1.0).toDouble());
    if (sparkleProgress > 0) {
      _drawSparkles(canvas, base, s, sparkleProgress);
    }
  }

  void _drawAura(Canvas canvas, Offset base, double s, double opacity) {
    final auraRect = Rect.fromCircle(center: base, radius: s * .45);
    _paintFill
      .shader = RadialGradient(
        colors: [
          const Color(0xFFFFDDE8).withValues(alpha: .38 * opacity),
          const Color(0xFFFFF0F5).withValues(alpha: .18 * opacity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(auraRect);
    canvas.drawCircle(base, s * .45, _paintFill);
    _paintFill.shader = null;
  }

  void _drawBud(
      Canvas canvas, Offset base, double s, double opacity, double appear) {
    final budHeight = s * .21 * (.45 + .55 * appear);
    final budWidth = s * .085 * (.45 + .55 * appear);

    canvas.save();
    canvas.translate(base.dx, base.dy);

    final centerBud = Path()
      ..moveTo(0, s * .035)
      ..cubicTo(-budWidth * .92, -budHeight * .25, -budWidth * .85,
          -budHeight * .70, 0, -budHeight)
      ..cubicTo(budWidth * .85, -budHeight * .70, budWidth * .92,
          -budHeight * .25, 0, s * .035)
      ..close();

    final budRect =
        Rect.fromLTWH(-budWidth, -budHeight, budWidth * 2, budHeight);

    // Soft base underlay for depth (hardware accelerated, zero lag)
    _paintFill
      ..color = const Color(0xFF6B7F4B).withValues(alpha: .22 * opacity)
      ..shader = null;
    canvas.drawCircle(Offset(0, -budHeight * .45), budWidth * 1.1, _paintFill);

    // Botanical gradient from calyx green through cream to blushing rose tip
    _paintFill
      .shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFF667B48).withValues(alpha: opacity),
          const Color(0xFFD4E3B7).withValues(alpha: opacity),
          const Color(0xFFF29BB9).withValues(alpha: opacity),
        ],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(budRect);
    canvas.drawPath(centerBud, _paintFill);
    _paintFill.shader = null;

    // Calyx receptacle collar
    final calyx = Path()
      ..moveTo(-budWidth * .52, s * .022)
      ..quadraticBezierTo(0, s * .046, budWidth * .52, s * .022)
      ..lineTo(budWidth * .32, -budHeight * .15)
      ..quadraticBezierTo(0, -budHeight * .08, -budWidth * .32, -budHeight * .15)
      ..close();
    _paintFill
      ..color = const Color(0xFF586C3C).withValues(alpha: opacity)
      ..shader = null;
    canvas.drawPath(calyx, _paintFill);

    // Fine midline sepal seam
    _paintStroke
      ..color = const Color(0xFF485B31).withValues(alpha: .45 * opacity)
      ..strokeWidth = s * .004
      ..strokeCap = StrokeCap.round
      ..shader = null;
    canvas.drawLine(
      Offset(0, s * .022),
      Offset(0, -budHeight * .92),
      _paintStroke,
    );

    canvas.restore();
  }

  void _drawPetal(
    Canvas canvas,
    Offset base,
    double s,
    _PetalSpec spec,
    double open,
    double local,
    double animationProgress,
  ) {
    final ease = open.clamp(0.0, 1.0);
    // Smooth fade-in over the first 20% of its dedicated window
    final petalAlpha = Curves.easeIn.transform((local / .20).clamp(0.0, 1.0));
    if (petalAlpha <= 0.0) return;

    // Natural botanical settling at the culmination of the bloom
    final settleT =
        ((animationProgress - .88) / .12).clamp(0.0, 1.0).toDouble();
    final settleAngle = math.sin((animationProgress - .88) * math.pi * 2) *
        .015 *
        (1 - settleT);

    // The petal rotates from upright (0 rad) outward to its final botanical radial angle
    final unfoldAngle = spec.angle * Curves.easeOutCubic.transform(ease);
    final angle = unfoldAngle + settleAngle;

    final length = s * spec.length;
    final width = s * spec.width;

    // The petal elongates and uncurls in width with natural organic easing
    final lengthScale = 0.28 + 0.72 * Curves.easeOutCubic.transform(ease);
    final widthScale = 0.14 + 0.86 * Curves.easeInOutCubic.transform(ease);

    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(-math.pi / 2 + angle);
    canvas.scale(widthScale, lengthScale);

    // Elegant lily tepal geometry: narrow base, wide curvaceous body, delicately recurved tip
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
      center: Offset(0, -length * .46),
      width: width * 1.7,
      height: length,
    );

    // Subtle petal depth under-layer (fast vector depth, zero GPU stall)
    _paintFill
      ..color = const Color(0xFF7E284F).withValues(alpha: 0.16 * petalAlpha * ease)
      ..shader = null;
    canvas.drawPath(path, _paintFill);

    // Rich botanical petal gradient:
    // Lime throat -> creamy blush center -> vibrant rose -> deep velvet ruby tip
    final colors = spec.inner
        ? [
            const Color(0xFFDCEAB2).withValues(alpha: petalAlpha),
            const Color(0xFFFFB2C9).withValues(alpha: petalAlpha),
            const Color(0xFFEA578B).withValues(alpha: petalAlpha),
            const Color(0xFFD03873).withValues(alpha: petalAlpha),
          ]
        : [
            const Color(0xFFCFE0A6).withValues(alpha: petalAlpha),
            const Color(0xFFFFC9D8).withValues(alpha: petalAlpha),
            const Color(0xFFF2749E).withValues(alpha: petalAlpha),
            const Color(0xFFC8457B).withValues(alpha: petalAlpha),
          ];

    _paintFill
      .shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: colors,
        stops: const [0.0, 0.28, 0.70, 1.0],
      ).createShader(rect);
    canvas.drawPath(path, _paintFill);
    _paintFill.shader = null;

    // Botanical midrib / central vein: embossed ridge running along petal axis
    _paintStroke
      ..color = const Color(0xFFB32A64).withValues(alpha: .56 * ease * petalAlpha)
      ..strokeWidth = s * .006
      ..strokeCap = StrokeCap.round
      ..shader = null;
    final veinPath = Path()
      ..moveTo(0, -s * .015)
      ..cubicTo(
          -s * .008, -length * .30, s * .012, -length * .60, 0, -length * .89);
    canvas.drawPath(veinPath, _paintStroke);

    // Sunlight edge rim highlight
    _paintStroke
      ..color = const Color(0xFFFFF7F9).withValues(alpha: .72 * ease * petalAlpha)
      ..strokeWidth = s * .0075
      ..strokeCap = StrokeCap.round
      ..shader = null;
    final highlightPath = Path()
      ..moveTo(-width * .12, -length * .18)
      ..quadraticBezierTo(
          -width * .35, -length * .53, -width * .18, -length * .78);
    canvas.drawPath(highlightPath, _paintStroke);

    // Botanical nectar speckles (papillae) near the throat
    _paintFill
      ..color = const Color(0xFFA11C55).withValues(alpha: .75 * ease * petalAlpha)
      ..shader = null;
    for (var i = 0; i < 8; i++) {
      final y = length * (.20 + (i % 4) * .065);
      final side = i.isEven ? -1.0 : 1.0;
      final x = side * width * (.12 + (i % 3) * .100);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, -y),
          width: s * (i % 3 == 0 ? .017 : .010),
          height: s * .030,
        ),
        _paintFill,
      );
      if (i < 3) {
        _paintStroke
          ..color =
              const Color(0xFFB5346D).withValues(alpha: .44 * ease * petalAlpha)
          ..strokeWidth = s * .0045
          ..shader = null;
        canvas.drawLine(
          Offset(0, -y + s * .01),
          Offset(x, -y - s * .018),
          _paintStroke,
        );
      }
    }

    canvas.restore();
  }

  void _drawCenterAndStamens(
      Canvas canvas, Offset base, double s, double reveal) {
    // 1. Central lime-green ovary throat
    final throatRadius = s * .042 * reveal;
    final throatRect = Rect.fromCircle(center: base, radius: throatRadius);
    _paintFill
      .shader = RadialGradient(
        colors: [
          const Color(0xFFE2F4B8),
          const Color(0xFF90B050),
          const Color(0xFF678238),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(throatRect);
    canvas.drawCircle(base, throatRadius, _paintFill);
    _paintFill.shader = null;

    // 2. Six slender filaments with golden-amber pollen anthers
    final specs = <(double, double, double)>[
      (-.40, .32, .80),
      (-.27, .40, .93),
      (-.12, .35, 1.0),
      (.12, .39, .96),
      (.27, .34, .88),
      (.40, .30, .78),
    ];

    for (final spec in specs) {
      final dx = spec.$1 * s * reveal;
      final rise = spec.$2 * s * reveal;
      final end = base + Offset(dx, -rise);

      // Filament
      final path = Path()
        ..moveTo(base.dx, base.dy - s * .015)
        ..cubicTo(base.dx + dx * .2, base.dy - rise * .15, base.dx + dx * .78,
            end.dy + rise * .18, end.dx, end.dy);

      _paintStroke
        ..color = const Color(0xFF758748)
        ..strokeWidth = s * .0075
        ..strokeCap = StrokeCap.round
        ..shader = null;
      canvas.drawPath(path, _paintStroke);

      // Golden Anther with pollen rim
      canvas.save();
      canvas.translate(end.dx, end.dy);
      canvas.rotate(spec.$1 * .18);

      final anther = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: s * .024,
          height: s * .095,
        ),
        Radius.circular(s * .012),
      );

      _paintFill
        ..color = const Color(0xFF884E25)
        ..shader = null;
      canvas.drawRRect(anther, _paintFill);

      _paintStroke
        ..color = const Color(0xFFE2AC50)
        ..strokeWidth = s * .004
        ..strokeCap = StrokeCap.round
        ..shader = null;
      canvas.drawRRect(anther, _paintStroke);

      canvas.restore();
    }
  }

  void _drawLeaf(Canvas canvas, Offset start, double s,
      {required double direction, required double reveal}) {
    if (reveal <= 0) return;
    canvas.save();
    canvas.translate(start.dx, start.dy);
    canvas.rotate(direction * -.58);
    canvas.scale(reveal, reveal);

    final leaf = Path()
      ..moveTo(0, 0)
      ..cubicTo(direction * s * .10, -s * .15, direction * s * .27, -s * .16,
          direction * s * .31, -s * .04)
      ..cubicTo(
          direction * s * .23, s * .06, direction * s * .10, s * .065, 0, 0)
      ..close();

    _paintFill
      .shader = const LinearGradient(
        colors: [Color(0xFFB2BF88), Color(0xFF6E804B)],
      ).createShader(Rect.fromLTWH(-s * .2, -s * .18, s * .55, s * .3));
    canvas.drawPath(leaf, _paintFill);
    _paintFill.shader = null;

    _paintStroke
      ..color = const Color(0xFF5A6C3E)
      ..strokeWidth = s * .005
      ..strokeCap = StrokeCap.round
      ..shader = null;
    canvas.drawPath(leaf, _paintStroke);

    _paintStroke
      ..color = const Color(0xFF546639)
      ..strokeWidth = s * .004
      ..shader = null;
    canvas.drawLine(
      Offset.zero,
      Offset(direction * s * .27, -s * .045),
      _paintStroke,
    );

    canvas.restore();
  }

  void _drawSparkles(Canvas canvas, Offset base, double s, double opacity) {
    if (opacity <= 0) return;
    const points = [
      Offset(-.40, -.35),
      Offset(.43, -.32),
      Offset(.02, -.52),
      Offset(-.22, -.48),
      Offset(.24, -.46),
    ];
    for (final point in points) {
      final p = base + Offset(point.dx * s, point.dy * s);
      _paintFill
        ..color = Colors.white.withValues(alpha: .75 * opacity)
        ..shader = null;
      canvas.drawCircle(p, s * .011, _paintFill);

      _paintStroke
        ..color = Colors.white.withValues(alpha: .70 * opacity)
        ..strokeWidth = s * .004
        ..strokeCap = StrokeCap.round
        ..shader = null;
      canvas.drawLine(
        Offset(p.dx - s * .022, p.dy),
        Offset(p.dx + s * .022, p.dy),
        _paintStroke,
      );
      canvas.drawLine(
        Offset(p.dx, p.dy - s * .022),
        Offset(p.dx, p.dy + s * .022),
        _paintStroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LilyPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _PetalSpec {
  const _PetalSpec({
    required this.angle,
    required this.length,
    required this.width,
    required this.inner,
    required this.start,
    required this.end,
  });

  final double angle;
  final double length;
  final double width;
  final bool inner;
  final double start;
  final double end;
}
