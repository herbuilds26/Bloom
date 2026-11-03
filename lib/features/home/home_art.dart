import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app/theme.dart';
import '../../app/living_lily.dart';

class CycleRingPainter extends CustomPainter {
  const CycleRingPainter({required this.progress});
  final double? progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = size.shortestSide * .052;
    final radius = size.shortestSide / 2 - stroke / 2 - 1;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackGradient = const SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: math.pi * 3 / 2,
      colors: [
        Color(0xFFF39399),
        Color(0xFFCF4173),
        Color(0xFFF6D8BD),
        Color(0xFFF39399),
        Color(0xFFCF4173),
      ],
      stops: [0, .24, .48, .74, 1],
    );
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = SweepGradient(
                  startAngle: -math.pi / 2,
                  endAngle: math.pi * 3 / 2,
                  colors: trackGradient.colors
                      .map((c) => c.withValues(alpha: .34))
                      .toList(),
                  stops: trackGradient.stops)
              .createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke + 1.5);
    canvas.drawCircle(
        center,
        radius + stroke * .56,
        Paint()
          ..color = Colors.white.withValues(alpha: .76)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    canvas.drawCircle(
        center,
        radius - stroke * .82,
        Paint()
          ..color = Colors.white.withValues(alpha: .68)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    final value = progress?.clamp(0.0, 1.0).toDouble();
    if (value == null || value <= 0) return;

    final sweep = math.pi * 2 * value;
    final gradient = const SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: math.pi * 3 / 2,
      colors: [
        Color(0xFFF39399),
        Color(0xFFCF4173),
        Color(0xFFF6D8BD),
        Color(0xFFF39399),
        Color(0xFFCF4173),
      ],
      stops: [0, .25, .48, .76, 1],
    );
    final arcPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arcPaint);

    final angle = -math.pi / 2 + sweep;
    final marker = Offset(center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle));
    canvas.drawCircle(marker, stroke * .78,
        Paint()..color = Colors.white.withValues(alpha: .92));
    canvas.drawCircle(
        marker,
        stroke * .52,
        Paint()
          ..color =
              value < .55 ? BloomTheme.raspberry : BloomTheme.plum);
  }

  @override
  bool shouldRepaint(covariant CycleRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Paints the 4 biological cycle phases (Menstrual, Follicular, Ovulation, Luteal)
/// with daily tick marks and a prominent "Today" pointer.
class CyclePhaseWheelPainter extends CustomPainter {
  const CyclePhaseWheelPainter({
    required this.cycleDay,
    this.cycleLength = 28,
    this.periodLength = 5,
  });

  final int? cycleDay;
  final int cycleLength;
  final int periodLength;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.shortestSide * 0.065;
    final radius = (size.shortestSide - strokeWidth) / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track groove
    final bgPaint = Paint()
      ..color = BloomTheme.peach.withValues(alpha: .28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final totalDays = math.max(20, cycleLength);
    final dayAngle = (2 * math.pi) / totalDays;
    const startAngle = -math.pi / 2;

    final pLen = periodLength.clamp(3, 7);
    final fertileStart = math.max(pLen + 1, totalDays ~/ 2 - 2);
    final fertileEnd = math.min(totalDays - 2, fertileStart + 4);

    final phases = [
      // 1. Menstrual phase (Raspberry)
      (
        start: 0,
        count: pLen,
        color: BloomTheme.raspberry,
        bgAlpha: 0.38,
      ),
      // 2. Follicular phase (Peach)
      (
        start: pLen,
        count: math.max(1, fertileStart - 1 - pLen),
        color: BloomTheme.peach,
        bgAlpha: 0.55,
      ),
      // 3. Fertile & Ovulation window (Rose)
      (
        start: fertileStart - 1,
        count: math.max(1, fertileEnd - fertileStart + 1),
        color: BloomTheme.rose,
        bgAlpha: 0.48,
      ),
      // 4. Luteal phase (Plum)
      (
        start: fertileEnd,
        count: math.max(1, totalDays - fertileEnd),
        color: BloomTheme.plum,
        bgAlpha: 0.32,
      ),
    ];

    // Draw phase segment arcs
    for (final p in phases) {
      final arcStart = startAngle + (p.start * dayAngle);
      final arcSweep = p.count * dayAngle - 0.04;

      final arcPaint = Paint()
        ..color = p.color.withValues(alpha: p.bgAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, arcStart, arcSweep, false, arcPaint);
    }

    // Outer subtle guide circle
    canvas.drawCircle(
      center,
      radius + strokeWidth * 0.72,
      Paint()
        ..color = Colors.white.withValues(alpha: .70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Inner subtle guide circle
    canvas.drawCircle(
      center,
      radius - strokeWidth * 0.72,
      Paint()
        ..color = Colors.white.withValues(alpha: .75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Draw day tick marks & ovulation star
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < totalDays; i++) {
      final a = startAngle + (i * dayAngle);
      final isOvulationDay = (i + 1 == 14);
      final dotPos = Offset(
        center.dx + (radius + strokeWidth * 0.72) * math.cos(a),
        center.dy + (radius + strokeWidth * 0.72) * math.sin(a),
      );

      if (isOvulationDay) {
        dotPaint.color = BloomTheme.raspberry;
        canvas.drawCircle(dotPos, 2.8, dotPaint);
      } else {
        dotPaint.color = BloomTheme.plum.withValues(alpha: .24);
        canvas.drawCircle(dotPos, 1.2, dotPaint);
      }
    }

    // Active progress arc & "Today" marker
    if (cycleDay != null && cycleDay! > 0) {
      final day = cycleDay!.clamp(1, totalDays);
      final progressSweep = (day - 1) * dayAngle;

      final activePaint = Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 3 / 2,
          colors: [
            BloomTheme.raspberry,
            BloomTheme.rose,
            BloomTheme.peach,
            BloomTheme.plum,
          ],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 1.0
        ..strokeCap = StrokeCap.round;

      if (progressSweep > 0.04) {
        canvas.drawArc(rect, startAngle, progressSweep, false, activePaint);
      }

      // "Today" marker along the circumference
      final markerAngle = startAngle + progressSweep;
      final markerPos = Offset(
        center.dx + radius * math.cos(markerAngle),
        center.dy + radius * math.sin(markerAngle),
      );

      // Shadow / halo
      canvas.drawCircle(
        markerPos,
        strokeWidth * 0.95,
        Paint()..color = BloomTheme.plum.withValues(alpha: .18),
      );
      // White boundary
      canvas.drawCircle(
        markerPos,
        strokeWidth * 0.75,
        Paint()..color = Colors.white,
      );
      // Center indicator dot
      canvas.drawCircle(
        markerPos,
        strokeWidth * 0.48,
        Paint()..color = BloomTheme.raspberry,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CyclePhaseWheelPainter oldDelegate) =>
      oldDelegate.cycleDay != cycleDay ||
      oldDelegate.cycleLength != cycleLength ||
      oldDelegate.periodLength != periodLength;
}

/// Artistic wallpaper painter that decorates the background and whitespace gaps
/// with graceful Lily blossoms, petals, and floral sprays.
class BloomFloralWallpaperPainter extends CustomPainter {
  const BloomFloralWallpaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Top-right corner lily blossom
    _drawLilyBlossom(canvas, Offset(size.width * 0.92, size.height * 0.06), 46, 0.45);

    // 2. Left side lily blossom (beside cycle hero gap)
    _drawLilyBlossom(canvas, Offset(size.width * 0.05, size.height * 0.22), 42, -0.6);

    // 3. Right side floating petal cluster (below cycle hero)
    _drawPetalCluster(canvas, Offset(size.width * 0.94, size.height * 0.36), 32, 0.85);

    // 4. Left gap floral spray (beside moods section)
    _drawLilyBlossom(canvas, Offset(size.width * 0.06, size.height * 0.52), 38, 1.15);

    // 5. Right gap floral accent (beside partner card)
    _drawLilyBlossom(canvas, Offset(size.width * 0.92, size.height * 0.70), 48, -0.35);

    // 6. Bottom-left petals
    _drawPetalCluster(canvas, Offset(size.width * 0.08, size.height * 0.88), 34, 0.4);
  }

  void _drawLilyBlossom(Canvas canvas, Offset center, double size, double rotation) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final petalPaint = Paint()
      ..color = BloomTheme.rose.withValues(alpha: 0.13)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = BloomTheme.raspberry.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    // 6 Lily petals radiating outward
    for (var i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3);
      canvas.save();
      canvas.rotate(angle);

      final petal = Path()
        ..moveTo(0, 0)
        ..cubicTo(size * 0.15, -size * 0.35, size * 0.25, -size * 0.75, 0, -size)
        ..cubicTo(-size * 0.25, -size * 0.75, -size * 0.15, -size * 0.35, 0, 0)
        ..close();

      canvas.drawPath(petal, petalPaint);
      canvas.drawPath(petal, outlinePaint);

      // Subtle midrib vein
      canvas.drawLine(
        const Offset(0, 0),
        Offset(0, -size * 0.85),
        Paint()
          ..color = BloomTheme.raspberry.withValues(alpha: 0.12)
          ..strokeWidth = 0.7,
      );

      canvas.restore();
    }

    // Center pistil dot
    final centerPaint = Paint()..color = BloomTheme.peach.withValues(alpha: 0.35);
    canvas.drawCircle(Offset.zero, size * 0.14, centerPaint);

    canvas.restore();
  }

  void _drawPetalCluster(Canvas canvas, Offset center, double size, double rotation) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final petalPaint = Paint()
      ..color = BloomTheme.peach.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.rotate(i * 0.8);
      final petal = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(size * 0.3, -size * 0.4, 0, -size * 0.8)
        ..quadraticBezierTo(-size * 0.3, -size * 0.4, 0, 0)
        ..close();
      canvas.drawPath(petal, petalPaint);
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BloomFloralWallpaperPainter oldDelegate) => false;
}

class CycleCardBackdropPainter extends CustomPainter {
  const CycleCardBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final topGlow = Paint()
      ..shader = RadialGradient(
        colors: [BloomTheme.rose.withValues(alpha: .22), Colors.transparent],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * .94, size.height * .18),
          radius: size.width * .42));
    canvas.drawRect(Offset.zero & size, topGlow);

    final branch = Paint()
      ..color = const Color(0xFF87916F).withValues(alpha: .20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final stem = Path()
      ..moveTo(size.width * .92, size.height * .06)
      ..cubicTo(size.width * .86, size.height * .22, size.width * .95,
          size.height * .31, size.width * .84, size.height * .42);
    canvas.drawPath(stem, branch);
    for (final spec in [
      (Offset(size.width * .88, size.height * .15), -2.45, .085),
      (Offset(size.width * .91, size.height * .27), .58, .075),
      (Offset(size.width * .85, size.height * .37), -2.48, .07),
    ]) {
      canvas.save();
      canvas.translate(spec.$1.dx, spec.$1.dy);
      canvas.rotate(spec.$2);
      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(size.width * spec.$3, -size.height * .045,
            size.width * spec.$3 * 1.65, 0)
        ..quadraticBezierTo(size.width * spec.$3, size.height * .045, 0, 0)
        ..close();
      canvas.drawPath(leaf,
          Paint()..color = const Color(0xFF87916F).withValues(alpha: .11));
      canvas.drawPath(leaf, branch..strokeWidth = .8);
      canvas.restore();
    }

    final sparkle = Paint()..color = Colors.white.withValues(alpha: .68);
    for (final point in [
      Offset(size.width * .18, size.height * .24),
      Offset(size.width * .78, size.height * .56),
      Offset(size.width * .70, size.height * .13),
    ]) {
      canvas.drawCircle(point, 1.5, sparkle);
      canvas.drawLine(Offset(point.dx - 3, point.dy),
          Offset(point.dx + 3, point.dy), sparkle..strokeWidth = .7);
      canvas.drawLine(Offset(point.dx, point.dy - 3),
          Offset(point.dx, point.dy + 3), sparkle..strokeWidth = .7);
    }
  }

  @override
  bool shouldRepaint(covariant CycleCardBackdropPainter oldDelegate) => false;
}

class HomeBotanicalSprig extends StatelessWidget {
  const HomeBotanicalSprig({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size * .78, size),
        painter: const _BotanicalSprigPainter(),
      );
}

class _BotanicalSprigPainter extends CustomPainter {
  const _BotanicalSprigPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = const Color(0xFF7F8D68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final stem = Path()
      ..moveTo(size.width * .48, size.height * .94)
      ..cubicTo(size.width * .36, size.height * .65, size.width * .70,
          size.height * .36, size.width * .51, size.height * .08);
    canvas.drawPath(stem, stemPaint);
    for (final leaf in [
      (Offset(size.width * .42, size.height * .72), -2.7),
      (Offset(size.width * .55, size.height * .52), .24),
      (Offset(size.width * .56, size.height * .31), -2.7),
      (Offset(size.width * .50, size.height * .1), -.1),
    ]) {
      canvas.save();
      canvas.translate(leaf.$1.dx, leaf.$1.dy);
      canvas.rotate(leaf.$2);
      final shape = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(
            size.width * .24, -size.height * .12, size.width * .39, 0)
        ..quadraticBezierTo(size.width * .21, size.height * .11, 0, 0);
      canvas.drawPath(shape,
          Paint()..color = const Color(0xFFE5EAD8).withValues(alpha: .92));
      canvas.drawPath(shape, stemPaint..strokeWidth = .85);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BotanicalSprigPainter oldDelegate) => false;
}

class CycleLengthPoint {
  const CycleLengthPoint({required this.start, required this.days});
  final DateTime start;
  final int days;
}

class CycleHistoryCard extends StatelessWidget {
  const CycleHistoryCard({super.key, required this.points});
  final List<CycleLengthPoint> points;

  @override
  Widget build(BuildContext context) {
    final canShowTrend = points.length >= 2;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      elevation: 1.5,
      shadowColor: BloomTheme.plum.withValues(alpha: .06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: BloomTheme.peach.withValues(alpha: .6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 17, 17, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Your cycle history',
                      style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 21,
                          height: 1.15,
                          color: BloomTheme.plum)),
                  const SizedBox(height: 4),
                  Text('See how your cycle changes over time',
                      style: TextStyle(fontSize: 11, color: BloomTheme.textSecondary))
                ])),
            if (canShowTrend)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                    color: BloomTheme.blush,
                    borderRadius: BorderRadius.circular(16)),
                child: Text('${points.length} cycles',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: BloomTheme.plum)),
              )
          ]),
          const SizedBox(height: 14),
          if (canShowTrend) _chart() else _emptyState(),
        ]),
      ),
    );
  }

  Widget _emptyState() => Container(
        width: double.infinity,
        height: 148,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF9F7), Color(0xFFFAF0E8)]),
        ),
        child: Stack(alignment: Alignment.center, children: [
          const Positioned(
              right: 14,
              top: 8,
              child:
                  Opacity(opacity: .75, child: LivingLily(size: 58, showStem: true, interactive: false))),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.timeline_rounded,
                color: BloomTheme.lavender, size: 27),
            const SizedBox(height: 8),
            Text(
                points.isEmpty
                    ? 'Your history will bloom here'
                    : 'A little more history is needed',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: BloomTheme.plum)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                  points.isEmpty
                      ? 'Record period start dates to see how many days your cycles last.'
                      : 'Record one more completed cycle to see your cycle-length trend.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10, height: 1.35, color: BloomTheme.textSecondary)),
            ),
          ]),
        ]),
      );

  Widget _chart() {
    final visiblePoints =
        points.length > 8 ? points.sublist(points.length - 8) : points;
    final minValue = visiblePoints
        .map((point) => point.days)
        .reduce((a, b) => a < b ? a : b);
    final maxValue = visiblePoints
        .map((point) => point.days)
        .reduce((a, b) => a > b ? a : b);
    final minY = math.max(10, minValue - 5).toDouble();
    final maxY = math.min(95, maxValue + 5).toDouble();
    final yInterval = math.max(2, ((maxY - minY) / 4).round()).toDouble();
    final xInterval = math.max(1, (visiblePoints.length / 4).ceil()).toDouble();
    final spots = [
      for (var i = 0; i < visiblePoints.length; i++)
        FlSpot(i.toDouble(), visiblePoints[i].days.toDouble())
    ];

    return Column(children: [
      Align(
          alignment: Alignment.centerLeft,
          child: Padding(
              padding: const EdgeInsets.only(left: 37, bottom: 2),
              child: Text('Cycle length · days',
                  style: TextStyle(fontSize: 9, color: BloomTheme.textSecondary)))),
      SizedBox(
        height: 185,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: math.max(1, visiblePoints.length - 1).toDouble(),
            minY: minY,
            maxY: maxY,
            clipData: const FlClipData.all(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: yInterval,
              getDrawingHorizontalLine: (value) => FlLine(
                  color: BloomTheme.lilac.withValues(alpha: .55),
                  strokeWidth: .7,
                  dashArray: [3, 4]),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                axisNameWidget: const SizedBox.shrink(),
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    space: 7,
                    child: Text('${value.toInt()}',
                        style: TextStyle(
                            fontSize: 9, color: BloomTheme.textSecondary)),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: xInterval,
                  getTitlesWidget: (value, meta) {
                    final index = value.round();
                    if (index < 0 || index >= visiblePoints.length) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      space: 8,
                      child: Text(_shortDate(visiblePoints[index].start),
                          style: TextStyle(
                              fontSize: 8, color: BloomTheme.textSecondary)),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                  final point = visiblePoints[spot.x.round()];
                  return LineTooltipItem(
                    '${point.days} days\n${_shortDate(point.start)}',
                    const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: .22,
                color: BloomTheme.lavender,
                barWidth: 2.8,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: BloomTheme.rose,
                    strokeColor: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      BloomTheme.lavender.withValues(alpha: .17),
                      BloomTheme.lilac.withValues(alpha: .015)
                    ],
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 380),
        ),
      ),
      Padding(
          padding: const EdgeInsets.only(left: 34, top: 2),
          child: Align(
              alignment: Alignment.center,
              child: Text('Period start date',
                  style: TextStyle(fontSize: 9, color: BloomTheme.textSecondary)))),
    ]);
  }

  String _shortDate(DateTime date) => '${_monthAbbrev(date.month)} ${date.day}';

  String _monthAbbrev(int month) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][month - 1];
}

class HomeMoodCharacter extends StatelessWidget {
  const HomeMoodCharacter({
    super.key,
    required this.mood,
    required this.selected,
    this.size = 48,
  });
  final String mood;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$mood mood',
        child: CustomPaint(
          size: Size.square(size),
          painter: _MoodCharacterPainter(mood, selected),
        ),
      );
}

class _MoodCharacterPainter extends CustomPainter {
  const _MoodCharacterPainter(this.mood, this.selected);
  final String mood;
  final bool selected;

  static const _palette = <String, Color>{
    'Happy': Color(0xFFF39399),
    'Calm': Color(0xFFF6D8BD),
    'Energetic': Color(0xFFE88A6E),
    'Frisky': Color(0xFFE65D82),
    'Mood swings': Color(0xFFD67D9C),
    'Irritated': Color(0xFFD65876),
    'Sad': Color(0xFF9E7C85),
    'Anxious': Color(0xFFB8627D),
    'Depressed': Color(0xFF7A5864),
    'Feeling guilty': Color(0xFFBC8594),
    'Obsessive thoughts': Color(0xFFE07E64),
    'Low energy': Color(0xFFD4A59A),
    'Apathetic': Color(0xFFA8949B),
    'Confused': Color(0xFFC78471),
    'Very self-critical': Color(0xFF8F4258),
    'Stressed': Color(0xFFCF4173),
    'Low': Color(0xFF9E7C85),
    'Tired': Color(0xFFD4A59A),
    'In pain': Color(0xFF8F4258),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final palette = _palette[mood] ?? BloomTheme.lavender;
    if (selected) {
      canvas.drawCircle(
          center,
          s * .48,
          Paint()
            ..color = BloomTheme.lavender.withValues(alpha: .18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * .045);
    }

    final shape = Path();
    final bounds =
        Rect.fromCenter(center: center, width: s * .84, height: s * .84);
    switch (mood) {
      case 'Happy': // friendly scalloped blob
      case 'Energetic':
        final count = mood == 'Energetic' ? 12 : 9;
        final points = List.generate(count, (i) {
          final angle = -math.pi / 2 + i * math.pi * 2 / count;
          final radius = s * (mood == 'Energetic' && i.isEven ? .43 : .39);
          return Offset(center.dx + math.cos(angle) * radius,
              center.dy + math.sin(angle) * radius);
        });
        shape.moveTo((points.first.dx + points.last.dx) / 2,
            (points.first.dy + points.last.dy) / 2);
        for (var i = 0; i < count; i++) {
          final point = points[i];
          final next = points[(i + 1) % count];
          shape.quadraticBezierTo(point.dx, point.dy, (point.dx + next.dx) / 2,
              (point.dy + next.dy) / 2);
        }
        shape.close();
        break;
      case 'Calm':
        shape.addOval(bounds);
        break;
      case 'Stressed':
        const count = 10;
        final points = <Offset>[];
        for (var i = 0; i < count; i++) {
          final angle = -math.pi / 2 + i * math.pi * 2 / count;
          final radius = s * (i.isEven ? .43 : .34);
          points.add(Offset(center.dx + math.cos(angle) * radius,
              center.dy + math.sin(angle) * radius));
        }
        shape.moveTo(points.first.dx, points.first.dy);
        for (final point in points.skip(1)) {
          shape.lineTo(point.dx, point.dy);
        }
        shape.close();
        break;
      case 'Anxious':
        shape
          ..moveTo(center.dx, center.dy - s * .43)
          ..cubicTo(
              center.dx + s * .06,
              center.dy - s * .34,
              center.dx + s * .42,
              center.dy + s * .06,
              center.dx + s * .34,
              center.dy + s * .27)
          ..cubicTo(
              center.dx + s * .21,
              center.dy + s * .48,
              center.dx - s * .21,
              center.dy + s * .48,
              center.dx - s * .34,
              center.dy + s * .27)
          ..cubicTo(
              center.dx - s * .42,
              center.dy + s * .06,
              center.dx - s * .06,
              center.dy - s * .34,
              center.dx,
              center.dy - s * .43)
          ..close();
        break;
      case 'Irritable':
        final points = List.generate(6, (i) {
          final angle = -math.pi / 2 + i * math.pi / 3;
          return Offset(center.dx + math.cos(angle) * s * .41,
              center.dy + math.sin(angle) * s * .41);
        });
        shape.moveTo((points.first.dx + points.last.dx) / 2,
            (points.first.dy + points.last.dy) / 2);
        for (var i = 0; i < points.length; i++) {
          final point = points[i];
          final next = points[(i + 1) % points.length];
          shape.quadraticBezierTo(point.dx, point.dy, (point.dx + next.dx) / 2,
              (point.dy + next.dy) / 2);
        }
        shape.close();
        break;
      case 'In pain':
        shape.addOval(
            Rect.fromCenter(center: center, width: s * .88, height: s * .76));
        break;
      case 'Low':
      case 'Tired':
        shape.addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: center,
                width: s * .79,
                height: s * (mood == 'Tired' ? .72 : .84)),
            Radius.circular(s * .25)));
        break;
      default:
        shape.addOval(bounds);
    }
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(palette, Colors.white, .24)!, palette],
      ).createShader(bounds);
    canvas.drawShadow(
        shape, BloomTheme.plum.withValues(alpha: .14), s * .04, true);
    canvas.drawPath(shape, fill);
    canvas.drawPath(
        shape,
        Paint()
          ..color = Colors.white.withValues(alpha: .62)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * .018);

    final ink = Paint()
      ..color = BloomTheme.plum
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .027
      ..strokeCap = StrokeCap.round;
    final eyeY = center.dy - s * .025;
    final eyeOffset = s * .105;

    if (mood == 'Calm' || mood == 'Tired' || mood == 'In pain') {
      for (final side in [-1.0, 1.0]) {
        final eye = Path()
          ..moveTo(center.dx + side * eyeOffset - s * .045, eyeY)
          ..quadraticBezierTo(
              center.dx + side * eyeOffset,
              eyeY + (mood == 'In pain' ? -s * .012 : s * .035),
              center.dx + side * eyeOffset + s * .045,
              eyeY);
        canvas.drawPath(eye, ink..strokeWidth = s * .036);
      }
    } else {
      final eyePaint = Paint()..color = ink.color;
      for (final side in [-1.0, 1.0]) {
        final ex = center.dx + side * eyeOffset;
        final eyeHeight = mood == 'Anxious' || mood == 'Happy'
            ? s * .07
            : mood == 'Stressed'
                ? s * .055
                : s * .05;
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(ex, eyeY), width: s * .041, height: eyeHeight),
            eyePaint);
        if (mood == 'Happy' || mood == 'Energetic') {
          canvas.drawCircle(Offset(ex - s * .008, eyeY - s * .012), s * .009,
              Paint()..color = Colors.white);
        }
      }
    }

    if (mood == 'Stressed' ||
        mood == 'Anxious' ||
        mood == 'Irritable' ||
        mood == 'In pain') {
      for (final side in [-1.0, 1.0]) {
        final brow = Path()
          ..moveTo(center.dx + side * eyeOffset - s * .048,
              eyeY - s * (mood == 'In pain' ? .09 : .08))
          ..lineTo(center.dx + side * eyeOffset + s * .035,
              eyeY - s * (mood == 'In pain' ? .045 : .055));
        canvas.drawPath(brow, ink..strokeWidth = s * .032);
      }
    }

    final mouth = Path();
    switch (mood) {
      case 'Happy':
      case 'Calm':
      case 'Energetic':
        mouth
          ..moveTo(center.dx - s * .095, center.dy + s * .055)
          ..cubicTo(
              center.dx - s * .07,
              center.dy + s * .19,
              center.dx + s * .07,
              center.dy + s * .19,
              center.dx + s * .095,
              center.dy + s * .055);
        break;
      case 'Stressed':
        mouth
          ..moveTo(center.dx - s * .07, center.dy + s * .12)
          ..quadraticBezierTo(center.dx, center.dy + s * .075,
              center.dx + s * .07, center.dy + s * .12);
        break;
      case 'Low':
      case 'Tired':
        mouth
          ..moveTo(center.dx - s * .06, center.dy + s * .14)
          ..quadraticBezierTo(center.dx, center.dy + s * .09,
              center.dx + s * .06, center.dy + s * .14);
        break;
      case 'Irritable':
        mouth
          ..moveTo(center.dx - s * .065, center.dy + s * .12)
          ..lineTo(center.dx + s * .065, center.dy + s * .12);
        break;
      case 'In pain':
        mouth
          ..moveTo(center.dx - s * .075, center.dy + s * .13)
          ..cubicTo(
              center.dx - s * .04,
              center.dy + s * .08,
              center.dx + s * .04,
              center.dy + s * .08,
              center.dx + s * .075,
              center.dy + s * .13)
          ..cubicTo(
              center.dx + s * .045,
              center.dy + s * .205,
              center.dx - s * .045,
              center.dy + s * .205,
              center.dx - s * .075,
              center.dy + s * .13);
        break;
      default:
        mouth
          ..moveTo(center.dx - s * .025, center.dy + s * .12)
          ..quadraticBezierTo(center.dx + s * .045, center.dy + s * .11,
              center.dx + s * .04, center.dy + s * .15);
    }
    canvas.drawPath(mouth, ink..strokeWidth = s * .034);

    final cheek = Paint()
      ..color = const Color(0xFFF09AB2).withValues(alpha: .6);
    canvas.drawCircle(
        Offset(center.dx - s * .17, center.dy + s * .09), s * .026, cheek);
    canvas.drawCircle(
        Offset(center.dx + s * .17, center.dy + s * .09), s * .026, cheek);
    if (mood == 'In pain') {
      final strain = Paint()
        ..color = BloomTheme.rose.withValues(alpha: .78)
        ..strokeWidth = s * .024
        ..strokeCap = StrokeCap.round;
      for (final side in [-1.0, 1.0]) {
        canvas.drawLine(Offset(center.dx + side * s * .19, center.dy - s * .17),
            Offset(center.dx + side * s * .22, center.dy - s * .12), strain);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MoodCharacterPainter oldDelegate) =>
      oldDelegate.mood != mood || oldDelegate.selected != selected;
}

class HomeSymptomIcon extends StatelessWidget {
  const HomeSymptomIcon({super.key, required this.symptom});
  final String symptom;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size.square(22),
        painter: _SymptomPainter(symptom),
      );
}

class _SymptomPainter extends CustomPainter {
  const _SymptomPainter(this.symptom);
  final String symptom;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final line = Paint()
      ..color = BloomTheme.rose
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    switch (symptom) {
      case 'Cramps':
        for (var i = 0; i < 3; i++) {
          final y = s * (.34 + i * .16);
          path
            ..moveTo(s * .22, y)
            ..quadraticBezierTo(s * .5, y - s * .11, s * .78, y);
        }
        canvas.drawPath(path, line);
        break;
      case 'Headache':
        canvas.drawCircle(center, s * .29, line);
        for (final angle in [-math.pi / 2, -math.pi / 4, 0.0]) {
          final from = Offset(center.dx + math.cos(angle) * s * .37,
              center.dy + math.sin(angle) * s * .37);
          final to = Offset(center.dx + math.cos(angle) * s * .48,
              center.dy + math.sin(angle) * s * .48);
          canvas.drawLine(from, to, line);
        }
        break;
      case 'Bloating':
        canvas.drawOval(
            Rect.fromCenter(center: center, width: s * .45, height: s * .64),
            line);
        canvas.drawLine(
            Offset(s * .36, s * .51), Offset(s * .64, s * .51), line);
        break;
      case 'Acne':
        canvas.drawCircle(center, s * .31, line);
        for (final point in [
          Offset(s * .39, s * .40),
          Offset(s * .61, s * .44),
          Offset(s * .50, s * .61),
        ]) {
          canvas.drawCircle(point, s * .045, Paint()..color = BloomTheme.rose);
        }
        break;
      case 'Back pain':
        path
          ..moveTo(center.dx, s * .17)
          ..cubicTo(s * .35, s * .36, s * .65, s * .64, center.dx, s * .83);
        canvas.drawPath(path, line);
        for (var i = 0; i < 4; i++) {
          final y = s * (.30 + i * .13);
          canvas.drawLine(Offset(center.dx - s * .10, y),
              Offset(center.dx + s * .10, y + s * .035), line);
        }
        break;
      case 'Nausea':
        path
          ..moveTo(s * .24, s * .35)
          ..cubicTo(s * .22, s * .18, s * .72, s * .18, s * .72, s * .37)
          ..cubicTo(s * .72, s * .54, s * .62, s * .64, s * .59, s * .78)
          ..moveTo(s * .16, s * .77)
          ..quadraticBezierTo(s * .31, s * .66, s * .44, s * .77);
        canvas.drawPath(path, line);
        break;
      case 'Breast tenderness':
        canvas.drawArc(
            Rect.fromCircle(center: Offset(s * .36, s * .52), radius: s * .20),
            -math.pi * .85,
            math.pi * 1.55,
            false,
            line);
        canvas.drawArc(
            Rect.fromCircle(center: Offset(s * .64, s * .52), radius: s * .20),
            -math.pi * .7,
            math.pi * 1.55,
            false,
            line);
        break;
      default:
        canvas.drawCircle(center, s * .28, line);
    }
  }

  @override
  bool shouldRepaint(covariant _SymptomPainter oldDelegate) =>
      oldDelegate.symptom != symptom;
}
