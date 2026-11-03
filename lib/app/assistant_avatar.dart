import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';

/// A botanical Lily profile picture avatar for Bloom Assistant.
/// Replaces generic icons with a rendered Stargazer Lily portrait.
class BloomAssistantAvatar extends StatelessWidget {
  const BloomAssistantAvatar({
    super.key,
    this.size = 46,
    this.showOnlineBadge = false,
  });

  final double size;
  final bool showOnlineBadge;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFF2F6),
            BloomTheme.peach.withValues(alpha: 0.5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: BloomTheme.plum.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: BloomTheme.peach.withValues(alpha: 0.9),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: CustomPaint(
          size: Size.square(size),
          painter: _BotanicalLilyAvatarPainter(),
        ),
      ),
    );

    if (!showOnlineBadge) {
      return avatar;
    }

    final badgeSize = (size * 0.26).clamp(8.0, 14.0).toDouble();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BotanicalLilyAvatarPainter extends CustomPainter {
  const _BotanicalLilyAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;

    // 1. Soft radial blush background in the throat
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF0F5),
          const Color(0xFFFFDEEA),
          const Color(0xFFF7CADB),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bgPaint);

    // 2. Six botanical lily tepals (3 outer sepals first, then 3 inner petals)
    final petalLength = radius * 0.88;
    final petalWidth = radius * 0.40;

    // Draw outer 3 tepals (at angles 0, 120, 240 deg)
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi / 3) - (math.pi / 2);
      _drawLilyPetal(
        canvas: canvas,
        center: center,
        angle: angle,
        length: petalLength * 0.95,
        width: petalWidth * 0.92,
        isOuter: true,
      );
    }

    // Draw inner 3 tepals (offset by 60 deg: 60, 180, 300 deg)
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi / 3) - (math.pi / 2) + (math.pi / 3);
      _drawLilyPetal(
        canvas: canvas,
        center: center,
        angle: angle,
        length: petalLength,
        width: petalWidth,
        isOuter: false,
      );
    }

    // 3. Central lime/chartreuse throat star
    final throatPaint = Paint()
      ..color = const Color(0xFFDCEAB2).withValues(alpha: 0.90)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawCircle(center, radius * 0.22, throatPaint);

    // 4. Stamen filaments & Pollen-dusted Anthers
    final stamenPaint = Paint()
      ..color = const Color(0xFFC7E298)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (radius * 0.05).clamp(1.0, 2.0)
      ..strokeCap = StrokeCap.round;

    final antherPaint = Paint()
      ..color = const Color(0xFF884E25) // deep amber pollen
      ..style = PaintingStyle.fill;

    final pollenGlowPaint = Paint()
      ..color = const Color(0xFFE2AC50) // bright pollen golden yellow
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final stamenAngle = (i * 2 * math.pi / 6) - (math.pi / 4);
      final filamentEnd = Offset(
        center.dx + math.cos(stamenAngle) * radius * 0.46,
        center.dy + math.sin(stamenAngle) * radius * 0.46,
      );

      // Filament
      canvas.drawLine(center, filamentEnd, stamenPaint);

      // Anther head (crossbar / pill)
      canvas.save();
      canvas.translate(filamentEnd.dx, filamentEnd.dy);
      canvas.rotate(stamenAngle + (math.pi / 2));
      final antherRect = Rect.fromCenter(
        center: Offset.zero,
        width: radius * 0.22,
        height: radius * 0.09,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(antherRect, Radius.circular(radius * 0.04)),
        antherPaint,
      );
      // Bright pollen highlight on top of anther
      final pollenRect = Rect.fromCenter(
        center: Offset.zero,
        width: radius * 0.16,
        height: radius * 0.05,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(pollenRect, Radius.circular(radius * 0.03)),
        pollenGlowPaint,
      );
      canvas.restore();
    }

    // 5. Central 3-lobed Stigma / Pistil
    final pistilPaint = Paint()
      ..color = const Color(0xFF5E8B42)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, (radius * 0.09).clamp(2.0, 4.0), pistilPaint);

    final pistilHighlight = Paint()..color = const Color(0xFFD6F0A2);
    canvas.drawCircle(center, (radius * 0.04).clamp(1.0, 2.0), pistilHighlight);
  }

  void _drawLilyPetal({
    required Canvas canvas,
    required Offset center,
    required double angle,
    required double length,
    required double width,
    required bool isOuter,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    // Lily petal shape: narrow throat base, swooping curvy flanks, gently pointed tip
    final path = Path();
    path.moveTo(0, 0);
    path.cubicTo(
      -width * 0.55,
      -length * 0.28,
      -width * 0.52,
      -length * 0.72,
      0,
      -length,
    );
    path.cubicTo(
      width * 0.52,
      -length * 0.72,
      width * 0.55,
      -length * 0.28,
      0,
      0,
    );
    path.close();

    // Stargazer lily gradient: Lime base -> Velvet Rose center -> Soft pink tip
    final petalShader = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: isOuter
          ? const [
              Color(0xFFDCEAB2), // Lime throat
              Color(0xFFD03873), // Velvet Stargazer rose
              Color(0xFFEA578B), // Petal rose
              Color(0xFFFFAAC8), // Soft pink
              Color(0xFFFFF0F5), // White/pink tip
            ]
          : const [
              Color(0xFFE5F0BD), // Inner lime
              Color(0xFFC7306A), // Deep velvet rose
              Color(0xFFF06597), // Luminous rose
              Color(0xFFFFBFD5), // Petal blush
              Color(0xFFFFFFFF), // Crisp tip
            ],
      stops: const [0.0, 0.25, 0.55, 0.85, 1.0],
    ).createShader(Rect.fromLTWH(-width, -length, width * 2, length));

    canvas.drawPath(path, Paint()..shader = petalShader);

    // Petal edge delicate contour
    final strokePaint = Paint()
      ..color = const Color(0xFF9E1B4F).withValues(alpha: isOuter ? 0.35 : 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(path, strokePaint);

    // Center midrib vein (raised white/pale stripe running up the center of the petal)
    final midribPath = Path()
      ..moveTo(0, -length * 0.12)
      ..lineTo(0, -length * 0.88);
    final midribPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(midribPath, midribPaint);

    // Stargazer dark nectar spots / freckles along the lower-mid petal
    final spotPaint = Paint()
      ..color = const Color(0xFF56112C).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    const spots = [
      Offset(-2.0, -0.32),
      Offset(2.2, -0.35),
      Offset(-3.2, -0.45),
      Offset(3.0, -0.48),
      Offset(-1.8, -0.55),
      Offset(1.6, -0.58),
    ];
    for (final spot in spots) {
      canvas.drawCircle(
        Offset(spot.dx * (width / 16), spot.dy * length),
        (length * 0.022).clamp(0.6, 1.4),
        spotPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
