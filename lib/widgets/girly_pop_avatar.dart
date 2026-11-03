import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Metadata definition for a Girly Pop character style
class GirlyPopCharacter {
  final String id;
  final String name;
  final String tagline;
  final String vibe;
  final Color primaryColor;
  final Color hairColor;
  final Color eyeColor;
  final Color bgStart;
  final Color bgEnd;
  final String accessoryName;

  const GirlyPopCharacter({
    required this.id,
    required this.name,
    required this.tagline,
    required this.vibe,
    required this.primaryColor,
    required this.hairColor,
    required this.eyeColor,
    required this.bgStart,
    required this.bgEnd,
    required this.accessoryName,
  });
}

/// Catalog of all 8 Girly Pop character styles
abstract final class GirlyPopGallery {
  static const List<GirlyPopCharacter> characters = [
    GirlyPopCharacter(
      id: 'coquette',
      name: 'Chloe',
      tagline: 'Soft Waves',
      vibe: 'Gentle & Elegant',
      primaryColor: Color(0xFFFF85A1),
      hairColor: Color(0xFF5D4037),
      eyeColor: Color(0xFF4A2810),
      bgStart: Color(0xFFFFF0F5),
      bgEnd: Color(0xFFFFDDE6),
      accessoryName: 'Pearl Hairpin & Necklace',
    ),
    GirlyPopCharacter(
      id: 'cherry',
      name: 'Ruby',
      tagline: 'Cherry Pop',
      vibe: 'Chic & Playful',
      primaryColor: Color(0xFFD81B60),
      hairColor: Color(0xFF212121),
      eyeColor: Color(0xFF2C3E50),
      bgStart: Color(0xFFFFEBEE),
      bgEnd: Color(0xFFFFCDD2),
      accessoryName: 'Cherry Beret',
    ),
    GirlyPopCharacter(
      id: 'blossom',
      name: 'Flora',
      tagline: 'Sakura Fairy',
      vibe: 'Gentle & Dreamy',
      primaryColor: Color(0xFFF06292),
      hairColor: Color(0xFFE0A996),
      eyeColor: Color(0xFF00897B),
      bgStart: Color(0xFFFCE4EC),
      bgEnd: Color(0xFFF8BBD0),
      accessoryName: 'Sakura Crown',
    ),
    GirlyPopCharacter(
      id: 'butterfly',
      name: 'Bella',
      tagline: 'Y2K Butterfly',
      vibe: 'Aesthetic & Nostalgic',
      primaryColor: Color(0xFFAB47BC),
      hairColor: Color(0xFF4A148C),
      eyeColor: Color(0xFF7B1FA2),
      bgStart: Color(0xFFF3E5F5),
      bgEnd: Color(0xFFE1BEE7),
      accessoryName: 'Butterfly Clips',
    ),
    GirlyPopCharacter(
      id: 'star',
      name: 'Stella',
      tagline: 'Cosmic Glam',
      vibe: 'Radiant & Bubbly',
      primaryColor: Color(0xFFFFB300),
      hairColor: Color(0xFFFFD54F),
      eyeColor: Color(0xFF3F51B5),
      bgStart: Color(0xFFFFF8E1),
      bgEnd: Color(0xFFFFECB3),
      accessoryName: 'Golden Star Barrettes',
    ),
    GirlyPopCharacter(
      id: 'matcha',
      name: 'Maya',
      tagline: 'Matcha Cozy',
      vibe: 'Calm & Cottagecore',
      primaryColor: Color(0xFF66BB6A),
      hairColor: Color(0xFF6D4C41),
      eyeColor: Color(0xFF33691E),
      bgStart: Color(0xFFE8F5E9),
      bgEnd: Color(0xFFC8E6C9),
      accessoryName: 'Sage Beanie & Daisy',
    ),
    GirlyPopCharacter(
      id: 'strawberry',
      name: 'Sunny',
      tagline: 'Strawberry Sweet',
      vibe: 'Sunny & Cheerful',
      primaryColor: Color(0xFFE53935),
      hairColor: Color(0xFFFFCA28),
      eyeColor: Color(0xFF5D4037),
      bgStart: Color(0xFFFFF3E0),
      bgEnd: Color(0xFFFFCCBC),
      accessoryName: 'Strawberry Bandana',
    ),
    GirlyPopCharacter(
      id: 'goth',
      name: 'Luna',
      tagline: 'Pastel Goth',
      vibe: 'Edgy & Kawaii',
      primaryColor: Color(0xFF7E57C2),
      hairColor: Color(0xFF1A1A1A),
      eyeColor: Color(0xFF6A1B9A),
      bgStart: Color(0xFFEDE7F6),
      bgEnd: Color(0xFFD1C4E9),
      accessoryName: 'Bat Wing & Choker',
    ),
  ];

  static GirlyPopCharacter get(String id) {
    return characters.firstWhere(
      (c) => c.id == id,
      orElse: () => characters.first,
    );
  }
}

/// An animated vector avatar widget rendering a cute girly pop character
class GirlyPopAvatar extends StatefulWidget {
  final String avatarId;
  final double size;
  final bool animate;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const GirlyPopAvatar({
    super.key,
    required this.avatarId,
    this.size = 56,
    this.animate = true,
    this.onTap,
    this.showEditBadge = false,
  });

  @override
  State<GirlyPopAvatar> createState() => _GirlyPopAvatarState();
}

class _GirlyPopAvatarState extends State<GirlyPopAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    final inTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!inTest && widget.animate) {
      _controller.repeat();
    } else {
      _controller.value = 0.25;
    }
  }

  @override
  void didUpdateWidget(covariant GirlyPopAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final inTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!inTest && widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0.25;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final character = GirlyPopGallery.get(widget.avatarId);

    Widget avatarWidget = SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _GirlyPopPainter(
              character: character,
              progress: _controller.value,
            ),
          );
        },
      ),
    );

    if (widget.showEditBadge) {
      avatarWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarWidget,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFCF4173),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }
}

class _GirlyPopPainter extends CustomPainter {
  final GirlyPopCharacter character;
  final double progress;

  _GirlyPopPainter({
    required this.character,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r = w / 2;

    // Phase oscillators for lively animations
    final sway = math.sin(progress * 2 * math.pi);
    final breathe = math.sin(progress * 4 * math.pi) * (h * 0.012);
    final blinkPhase = (progress * 3.5) % 3.5;
    final isBlinking = blinkPhase > 3.3; // brief natural blink
    final blinkFactor = isBlinking
        ? math.sin((blinkPhase - 3.3) / 0.2 * math.pi)
        : 0.0;

    // Clip to round circle
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.save();
    canvas.clipPath(circlePath);

    // 1. Background Gradient
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [character.bgStart, character.bgEnd],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Subtle background glowing orb
    final glowPaint = Paint()
      ..color = character.primaryColor.withValues(alpha: 0.12 + 0.06 * sway)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(cx, cy + breathe), r * 0.75, glowPaint);

    // 2. Animated Floating Particles (hearts, petals, stars)
    _drawParticles(canvas, w, h, cx, cy, sway);

    // 3. Hair Back Layer (behind body & face)
    _drawHairBack(canvas, w, h, cx, cy + breathe, sway);

    // 4. Neck & Outfit
    _drawBodyAndOutfit(canvas, w, h, cx, cy + breathe);

    // 5. Head & Ears
    _drawHeadAndEars(canvas, w, h, cx, cy + breathe);

    // 6. Blush & Face details
    _drawBlushAndSmile(canvas, w, h, cx, cy + breathe);

    // 7. Expressive Anime Eyes (with blinking & shine)
    _drawEyes(canvas, w, h, cx, cy + breathe, blinkFactor);

    // 8. Front Hair & Bangs
    _drawHairFront(canvas, w, h, cx, cy + breathe, sway);

    // 9. Signature Girly Pop Accessory (Bow, Beret, Crown, Butterfly, etc.)
    _drawAccessory(canvas, w, h, cx, cy + breathe, sway);

    canvas.restore();

    // 10. Outer border ring with subtle gloss
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.035)
      ..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(cx, cy), r - (borderPaint.strokeWidth / 2), borderPaint);

    final highlightRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, w * 0.015)
      ..color = character.primaryColor.withValues(alpha: 0.4);
    canvas.drawCircle(Offset(cx, cy), r - (borderPaint.strokeWidth), highlightRing);
  }

  void _drawParticles(Canvas canvas, double w, double h, double cx, double cy, double sway) {
    final pPaint = Paint()..style = PaintingStyle.fill;

    if (character.id == 'coquette') {
      // Floating tiny cute pink hearts
      pPaint.color = const Color(0xFFFF85A1).withValues(alpha: 0.55);
      _drawMiniHeart(canvas, cx - w * 0.32, cy - h * 0.22 + sway * 3, w * 0.045, pPaint);
      _drawMiniHeart(canvas, cx + w * 0.30, cy + h * 0.05 - sway * 3, w * 0.038, pPaint);
    } else if (character.id == 'star' || character.id == 'butterfly' || character.id == 'goth') {
      // Twinkling stars
      pPaint.color = character.primaryColor.withValues(alpha: 0.65);
      _drawStar(canvas, cx - w * 0.34, cy - h * 0.20 + sway * 2.5, w * 0.045, progress * math.pi, pPaint);
      _drawStar(canvas, cx + w * 0.32, cy - h * 0.15 - sway * 2.5, w * 0.038, -progress * math.pi, pPaint);
      _drawStar(canvas, cx + w * 0.30, cy + h * 0.18 + sway * 2, w * 0.032, progress * 2 * math.pi, pPaint);
    } else if (character.id == 'blossom' || character.id == 'matcha') {
      // Drifting gentle sakura petals / leaves
      pPaint.color = character.primaryColor.withValues(alpha: 0.6);
      canvas.save();
      canvas.translate(cx - w * 0.32, cy - h * 0.24 + sway * 3);
      canvas.rotate(sway * 0.3);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.07, height: h * 0.04), pPaint);
      canvas.restore();

      canvas.save();
      canvas.translate(cx + w * 0.32, cy + h * 0.08 - sway * 3);
      canvas.rotate(-sway * 0.4);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.06, height: h * 0.035), pPaint);
      canvas.restore();
    } else {
      // Sparkle glints
      pPaint.color = character.primaryColor.withValues(alpha: 0.6);
      _drawStar(canvas, cx - w * 0.32, cy - h * 0.20 + sway * 2, w * 0.04, 0, pPaint);
      _drawStar(canvas, cx + w * 0.30, cy + h * 0.05 - sway * 2, w * 0.035, math.pi / 4, pPaint);
    }
  }

  void _drawMiniHeart(Canvas canvas, double x, double y, double size, Paint paint) {
    final path = Path();
    path.moveTo(x, y + size * 0.3);
    path.cubicTo(x - size, y - size * 0.6, x - size * 0.5, y - size, x, y - size * 0.4);
    path.cubicTo(x + size * 0.5, y - size, x + size, y - size * 0.6, x, y + size * 0.3);
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, double cx, double cy, double r, double angle, Paint paint) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final a = (i * math.pi / 2);
      final ax = math.cos(a) * r;
      final ay = math.sin(a) * r;
      final bx = math.cos(a + math.pi / 4) * (r * 0.3);
      final by = math.sin(a + math.pi / 4) * (r * 0.3);
      if (i == 0) {
        path.moveTo(ax, ay);
      } else {
        path.lineTo(ax, ay);
      }
      path.lineTo(bx, by);
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawHairBack(Canvas canvas, double w, double h, double cx, double cy, double sway) {
    final hairPaint = Paint()
      ..color = character.hairColor
      ..style = PaintingStyle.fill;

    final id = character.id;
    if (id == 'star') {
      // Twin high space buns
      final bunR = w * 0.17;
      canvas.drawCircle(Offset(cx - w * 0.30, cy - h * 0.26), bunR, hairPaint);
      canvas.drawCircle(Offset(cx + w * 0.30, cy - h * 0.26), bunR, hairPaint);
    } else if (id == 'strawberry') {
      // Twin high bouncy pigtails
      final pigtailPathLeft = Path()
        ..moveTo(cx - w * 0.22, cy - h * 0.15)
        ..cubicTo(cx - w * 0.48 + sway * 2, cy - h * 0.18, cx - w * 0.46, cy + h * 0.32, cx - w * 0.28, cy + h * 0.36)
        ..close();
      canvas.drawPath(pigtailPathLeft, hairPaint);

      final pigtailPathRight = Path()
        ..moveTo(cx + w * 0.22, cy - h * 0.15)
        ..cubicTo(cx + w * 0.48 - sway * 2, cy - h * 0.18, cx + w * 0.46, cy + h * 0.32, cx + w * 0.28, cy + h * 0.36)
        ..close();
      canvas.drawPath(pigtailPathRight, hairPaint);
    } else {
      // Long flowing locks / waves behind shoulders
      final hairPath = Path();
      hairPath.moveTo(cx - w * 0.32, cy - h * 0.15);
      hairPath.cubicTo(
        cx - w * 0.46 + (sway * 2),
        cy + h * 0.10,
        cx - w * 0.42,
        cy + h * 0.48,
        cx - w * 0.16,
        cy + h * 0.50,
      );
      hairPath.lineTo(cx + w * 0.16, cy + h * 0.50);
      hairPath.cubicTo(
        cx + w * 0.42,
        cy + h * 0.48,
        cx + w * 0.46 - (sway * 2),
        cy + h * 0.10,
        cx + w * 0.32,
        cy - h * 0.15,
      );
      hairPath.close();
      canvas.drawPath(hairPath, hairPaint);
    }
  }

  void _drawBodyAndOutfit(Canvas canvas, double w, double h, double cx, double cy) {
    // Skin Tone
    final skinPaint = Paint()
      ..color = const Color(0xFFFFF2EC)
      ..style = PaintingStyle.fill;

    // Neck
    final neckRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + h * 0.26), width: w * 0.18, height: h * 0.22),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(neckRect, skinPaint);

    // Subtle neck shadow
    final neckShadow = Paint()..color = const Color(0xFFF0D5C9);
    canvas.drawCircle(Offset(cx, cy + h * 0.20), w * 0.08, neckShadow);

    // Outfit Shoulders
    final outfitPaint = Paint()
      ..color = character.primaryColor
      ..style = PaintingStyle.fill;

    final outfitPath = Path();
    outfitPath.moveTo(cx - w * 0.38, h);
    outfitPath.cubicTo(cx - w * 0.36, cy + h * 0.32, cx - w * 0.18, cy + h * 0.30, cx, cy + h * 0.34);
    outfitPath.cubicTo(cx + w * 0.18, cy + h * 0.30, cx + w * 0.36, cy + h * 0.32, cx + w * 0.38, h);
    outfitPath.close();
    canvas.drawPath(outfitPath, outfitPaint);

    // Collar / Top Detail
    if (character.id == 'goth') {
      // Black velvet choker with metallic charm
      final chokerPaint = Paint()..color = const Color(0xFF1E1E1E);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy + h * 0.23), width: w * 0.19, height: h * 0.045),
          const Radius.circular(2),
        ),
        chokerPaint,
      );
      // Silver cross/moon pendant
      final charmPaint = Paint()..color = const Color(0xFFE0E0E0);
      canvas.drawCircle(Offset(cx, cy + h * 0.255), w * 0.022, charmPaint);
    } else if (character.id == 'coquette') {
      // Pearl necklace
      final pearlPaint = Paint()..color = Colors.white;
      for (int i = -3; i <= 3; i++) {
        canvas.drawCircle(
          Offset(cx + (i * w * 0.03), cy + h * 0.27 + (i.abs() * h * 0.008)),
          w * 0.018,
          pearlPaint,
        );
      }
    } else {
      // Sweet Peter Pan collar or white lace trim
      final lacePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.95)
        ..style = PaintingStyle.fill;
      final lacePath = Path();
      lacePath.moveTo(cx - w * 0.14, cy + h * 0.32);
      lacePath.quadraticBezierTo(cx - w * 0.07, cy + h * 0.38, cx, cy + h * 0.35);
      lacePath.quadraticBezierTo(cx + w * 0.07, cy + h * 0.38, cx + w * 0.14, cy + h * 0.32);
      lacePath.close();
      canvas.drawPath(lacePath, lacePaint);
    }
  }

  void _drawHeadAndEars(Canvas canvas, double w, double h, double cx, double cy) {
    final skinPaint = Paint()
      ..color = const Color(0xFFFFF2EC)
      ..style = PaintingStyle.fill;

    // Ears
    final earL = Offset(cx - w * 0.24, cy + h * 0.04);
    final earR = Offset(cx + w * 0.24, cy + h * 0.04);
    canvas.drawCircle(earL, w * 0.075, skinPaint);
    canvas.drawCircle(earR, w * 0.075, skinPaint);

    // Inner ear delicate tint
    final earInner = Paint()..color = const Color(0xFFFFD7D7);
    canvas.drawCircle(earL, w * 0.04, earInner);
    canvas.drawCircle(earR, w * 0.04, earInner);

    // Cute Earrings
    _drawEarrings(canvas, w, h, earL, earR);

    // Cute Chibi Head
    final headRect = Rect.fromCenter(
      center: Offset(cx, cy + h * 0.01),
      width: w * 0.52,
      height: h * 0.54,
    );
    final headRRect = RRect.fromRectAndCorners(
      headRect,
      topLeft: Radius.circular(w * 0.26),
      topRight: Radius.circular(w * 0.26),
      bottomLeft: Radius.circular(w * 0.24),
      bottomRight: Radius.circular(w * 0.24),
    );
    canvas.drawRRect(headRRect, skinPaint);
  }

  void _drawEarrings(Canvas canvas, double w, double h, Offset earL, Offset earR) {
    final id = character.id;
    if (id == 'coquette') {
      // Pearl drops
      final pPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(earL.dx, earL.dy + h * 0.045), w * 0.024, pPaint);
      canvas.drawCircle(Offset(earR.dx, earR.dy + h * 0.045), w * 0.024, pPaint);
    } else if (id == 'cherry') {
      // Tiny cherry drops
      final cPaint = Paint()..color = const Color(0xFFC2185B);
      canvas.drawCircle(Offset(earL.dx, earL.dy + h * 0.045), w * 0.022, cPaint);
      canvas.drawCircle(Offset(earR.dx, earR.dy + h * 0.045), w * 0.022, cPaint);
    } else if (id == 'star') {
      // Golden star studs
      final sPaint = Paint()..color = const Color(0xFFFFD54F);
      _drawStar(canvas, earL.dx, earL.dy + h * 0.035, w * 0.024, 0, sPaint);
      _drawStar(canvas, earR.dx, earR.dy + h * 0.035, w * 0.024, 0, sPaint);
    } else {
      // Sweet round studs
      final sPaint = Paint()..color = character.primaryColor;
      canvas.drawCircle(Offset(earL.dx, earL.dy + h * 0.04), w * 0.02, sPaint);
      canvas.drawCircle(Offset(earR.dx, earR.dy + h * 0.04), w * 0.02, sPaint);
    }
  }

  void _drawBlushAndSmile(Canvas canvas, double w, double h, double cx, double cy) {
    // Cheeks blush
    final blushPaint = Paint()
      ..color = const Color(0xFFFF7290).withValues(alpha: 0.38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(cx - w * 0.16, cy + h * 0.11), w * 0.07, blushPaint);
    canvas.drawCircle(Offset(cx + w * 0.16, cy + h * 0.11), w * 0.07, blushPaint);

    // Kawaii highlight dot on blush
    final blushHighlight = Paint()..color = Colors.white.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(cx - w * 0.145, cy + h * 0.10), w * 0.016, blushHighlight);
    canvas.drawCircle(Offset(cx + w * 0.175, cy + h * 0.10), w * 0.016, blushHighlight);

    // Strawberry Freckles
    if (character.id == 'strawberry') {
      final fPaint = Paint()..color = const Color(0xFFD38165).withValues(alpha: 0.6);
      canvas.drawCircle(Offset(cx - w * 0.13, cy + h * 0.09), 1.2, fPaint);
      canvas.drawCircle(Offset(cx - w * 0.09, cy + h * 0.11), 1.2, fPaint);
      canvas.drawCircle(Offset(cx + w * 0.09, cy + h * 0.11), 1.2, fPaint);
      canvas.drawCircle(Offset(cx + w * 0.13, cy + h * 0.09), 1.2, fPaint);
    }

    // Cute button nose
    final nosePaint = Paint()..color = const Color(0xFFE89B88).withValues(alpha: 0.65);
    canvas.drawCircle(Offset(cx, cy + h * 0.08), w * 0.016, nosePaint);

    // Sweet Smile
    final smilePaint = Paint()
      ..color = const Color(0xFFC74360)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.8, w * 0.035);

    final smilePath = Path();
    smilePath.moveTo(cx - w * 0.055, cy + h * 0.14);
    smilePath.quadraticBezierTo(cx, cy + h * 0.17, cx + w * 0.055, cy + h * 0.14);
    canvas.drawPath(smilePath, smilePaint);

    // Lip gloss shine
    final glossPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(cx + w * 0.02, cy + h * 0.155), 1.3, glossPaint);
  }

  void _drawEyes(Canvas canvas, double w, double h, double cx, double cy, double blinkFactor) {
    final eyeSpacing = w * 0.14;
    final eyeY = cy + h * 0.02;

    _drawSingleEye(canvas, w, h, cx - eyeSpacing, eyeY, blinkFactor, isLeft: true);
    _drawSingleEye(canvas, w, h, cx + eyeSpacing, eyeY, blinkFactor, isLeft: false);
  }

  void _drawSingleEye(
    Canvas canvas,
    double w,
    double h,
    double ex,
    double ey,
    double blinkFactor, {
    required bool isLeft,
  }) {
    final lashPaint = Paint()
      ..color = const Color(0xFF2C1920)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2.0, w * 0.04);

    // Delicate Eyebrow
    final browPaint = Paint()
      ..color = character.hairColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.5, w * 0.028);

    final browPath = Path();
    final browY = ey - h * 0.11;
    if (isLeft) {
      browPath.moveTo(ex - w * 0.06, browY + h * 0.01);
      browPath.quadraticBezierTo(ex - w * 0.01, browY - h * 0.012, ex + w * 0.06, browY);
    } else {
      browPath.moveTo(ex - w * 0.06, browY);
      browPath.quadraticBezierTo(ex + w * 0.01, browY - h * 0.012, ex + w * 0.06, browY + h * 0.01);
    }
    canvas.drawPath(browPath, browPaint);

    if (blinkFactor > 0.5) {
      // Eyes closed / happy blink arc
      final closedPath = Path();
      closedPath.moveTo(ex - w * 0.07, ey + h * 0.02);
      closedPath.quadraticBezierTo(ex, ey + h * 0.07, ex + w * 0.07, ey + h * 0.02);
      canvas.drawPath(closedPath, lashPaint);

      // Winged lash flick
      final flickPath = Path();
      if (isLeft) {
        flickPath.moveTo(ex - w * 0.065, ey + h * 0.025);
        flickPath.lineTo(ex - w * 0.09, ey);
      } else {
        flickPath.moveTo(ex + w * 0.065, ey + h * 0.025);
        flickPath.lineTo(ex + w * 0.09, ey);
      }
      canvas.drawPath(flickPath, lashPaint);
      return;
    }

    // Wide, glossy anime eye
    final eyeW = w * 0.13;
    final eyeH = h * 0.16 * (1.0 - blinkFactor);

    // White eye sclera
    final scleraPaint = Paint()..color = Colors.white;
    final eyeRect = Rect.fromCenter(center: Offset(ex, ey), width: eyeW, height: eyeH);
    canvas.drawOval(eyeRect, scleraPaint);

    // Iris with gradient
    final irisPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF1B0B11), character.eyeColor, character.primaryColor],
      ).createShader(eyeRect);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(ex, ey), width: eyeW * 0.88, height: eyeH * 0.95),
      irisPaint,
    );

    // Deep pupil
    final pupilPaint = Paint()..color = const Color(0xFF10070B);
    canvas.drawCircle(Offset(ex, ey + eyeH * 0.05), eyeW * 0.25, pupilPaint);

    // Glassy Anime Eye Highlights
    final gleamPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(ex - eyeW * 0.22, ey - eyeH * 0.25), eyeW * 0.26, gleamPaint);
    canvas.drawCircle(Offset(ex + eyeW * 0.22, ey + eyeH * 0.22), eyeW * 0.14, gleamPaint);

    // Winged Upper Eyelash line
    final lashPath = Path();
    lashPath.moveTo(ex - eyeW * 0.65, ey);
    lashPath.quadraticBezierTo(ex, ey - eyeH * 0.65, ex + eyeW * 0.65, ey);
    // Outer upward wing flick
    if (isLeft) {
      lashPath.quadraticBezierTo(ex - eyeW * 0.72, ey - eyeH * 0.35, ex - eyeW * 0.90, ey - eyeH * 0.35);
    } else {
      lashPath.quadraticBezierTo(ex + eyeW * 0.72, ey - eyeH * 0.35, ex + eyeW * 0.90, ey - eyeH * 0.35);
    }
    canvas.drawPath(lashPath, lashPaint);
  }

  void _drawHairFront(Canvas canvas, double w, double h, double cx, double cy, double sway) {
    final hairPaint = Paint()
      ..color = character.hairColor
      ..style = PaintingStyle.fill;

    final id = character.id;
    final bangsPath = Path();

    if (id == 'coquette') {
      // Soft curtain bangs parted slightly
      bangsPath.moveTo(cx - w * 0.28, cy - h * 0.05);
      bangsPath.cubicTo(cx - w * 0.26, cy - h * 0.28, cx + w * 0.26, cy - h * 0.28, cx + w * 0.28, cy - h * 0.05);
      bangsPath.quadraticBezierTo(cx + w * 0.16, cy - h * 0.03, cx + w * 0.02, cy - h * 0.14);
      bangsPath.quadraticBezierTo(cx - w * 0.16, cy - h * 0.03, cx - w * 0.28, cy - h * 0.05);
      canvas.drawPath(bangsPath, hairPaint);
    } else if (id == 'goth') {
      // Sharp straight hime cut bangs
      bangsPath.moveTo(cx - w * 0.27, cy - h * 0.02);
      bangsPath.lineTo(cx - w * 0.27, cy - h * 0.25);
      bangsPath.cubicTo(cx - w * 0.15, cy - h * 0.30, cx + w * 0.15, cy - h * 0.30, cx + w * 0.27, cy - h * 0.25);
      bangsPath.lineTo(cx + w * 0.27, cy - h * 0.02);
      bangsPath.lineTo(cx + w * 0.18, cy - h * 0.08);
      bangsPath.lineTo(cx, cy - h * 0.07);
      bangsPath.lineTo(cx - w * 0.18, cy - h * 0.08);
      bangsPath.close();
      canvas.drawPath(bangsPath, hairPaint);
    } else {
      // Fluffy rounded anime fringe
      bangsPath.moveTo(cx - w * 0.27, cy - h * 0.02);
      bangsPath.cubicTo(cx - w * 0.24, cy - h * 0.28, cx + w * 0.24, cy - h * 0.28, cx + w * 0.27, cy - h * 0.02);
      bangsPath.quadraticBezierTo(cx + w * 0.14, cy - h * 0.07, cx + w * 0.06, cy - h * 0.05);
      bangsPath.quadraticBezierTo(cx, cy - h * 0.08, cx - w * 0.06, cy - h * 0.05);
      bangsPath.quadraticBezierTo(cx - w * 0.14, cy - h * 0.07, cx - w * 0.27, cy - h * 0.02);
      canvas.drawPath(bangsPath, hairPaint);
    }

    // Hair Sheen / Gloss Arc
    final sheenPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.5, w * 0.025);
    final sheenPath = Path();
    sheenPath.moveTo(cx - w * 0.16, cy - h * 0.18);
    sheenPath.quadraticBezierTo(cx, cy - h * 0.22, cx + w * 0.16, cy - h * 0.18);
    canvas.drawPath(sheenPath, sheenPaint);
  }

  void _drawAccessory(Canvas canvas, double w, double h, double cx, double cy, double sway) {
    final id = character.id;
    if (id == 'coquette') {
      // Dainty pearl hairpin on the side of hair (no bow on the head)
      final pinX = cx - w * 0.18;
      final pinY = cy - h * 0.16 + (sway * 0.8);
      final pearlPaint = Paint()..color = Colors.white;
      final goldBar = Paint()
        ..color = const Color(0xFFFFD54F)
        ..strokeWidth = math.max(1.5, w * 0.02)
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(pinX - w * 0.05, pinY), Offset(pinX + w * 0.05, pinY), goldBar);
      canvas.drawCircle(Offset(pinX - w * 0.035, pinY), w * 0.022, pearlPaint);
      canvas.drawCircle(Offset(pinX, pinY), w * 0.028, pearlPaint);
      canvas.drawCircle(Offset(pinX + w * 0.035, pinY), w * 0.022, pearlPaint);
    } else if (id == 'cherry') {
      // French raspberry beret tilted on head
      final beretPaint = Paint()..color = const Color(0xFFD81B60);
      final beretPath = Path();
      beretPath.moveTo(cx - w * 0.28, cy - h * 0.16);
      beretPath.cubicTo(cx - w * 0.32, cy - h * 0.36, cx + w * 0.36, cy - h * 0.36, cx + w * 0.32, cy - h * 0.16);
      beretPath.close();
      canvas.drawPath(beretPath, beretPaint);

      // Beret tip stem
      final stemPaint = Paint()
        ..color = const Color(0xFFAD1457)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(cx + w * 0.02, cy - h * 0.34), Offset(cx + w * 0.05, cy - h * 0.39), stemPaint);

      // Cherry pin on side of beret
      final cherryPaint = Paint()..color = const Color(0xFFFF1744);
      canvas.drawCircle(Offset(cx + w * 0.18, cy - h * 0.19 + sway * 1.5), w * 0.035, cherryPaint);
      canvas.drawCircle(Offset(cx + w * 0.23, cy - h * 0.17 - sway * 1.5), w * 0.035, cherryPaint);
      final greenStem = Paint()
        ..color = const Color(0xFF4CAF50)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(cx + w * 0.18, cy - h * 0.19), Offset(cx + w * 0.21, cy - h * 0.24), greenStem);
      canvas.drawLine(Offset(cx + w * 0.23, cy - h * 0.17), Offset(cx + w * 0.21, cy - h * 0.24), greenStem);
    } else if (id == 'blossom') {
      // Sakura Flower Crown
      for (int i = -2; i <= 2; i++) {
        final fx = cx + (i * w * 0.11);
        final fy = cy - h * 0.23 + (i.abs() * h * 0.025);
        _drawSakuraFlower(canvas, fx, fy, w * 0.055, sway * (i == 0 ? 0.2 : 0));
      }
    } else if (id == 'butterfly') {
      // Y2K Hologram Butterfly Hair Clips
      _drawButterflyClip(canvas, cx - w * 0.22, cy - h * 0.16, w * 0.07, sway, isLeft: true);
      _drawButterflyClip(canvas, cx + w * 0.22, cy - h * 0.16, w * 0.07, -sway, isLeft: false);
    } else if (id == 'star') {
      // Golden star hairpins
      final starPaint = Paint()..color = const Color(0xFFFFD54F);
      _drawStar(canvas, cx - w * 0.28, cy - h * 0.26, w * 0.065, progress * math.pi * 0.5, starPaint);
      _drawStar(canvas, cx + w * 0.28, cy - h * 0.26, w * 0.065, -progress * math.pi * 0.5, starPaint);
    } else if (id == 'matcha') {
      // Sage beanie
      final beaniePaint = Paint()..color = const Color(0xFF7CB342);
      final beaniePath = Path();
      beaniePath.moveTo(cx - w * 0.28, cy - h * 0.14);
      beaniePath.cubicTo(cx - w * 0.30, cy - h * 0.36, cx + w * 0.30, cy - h * 0.36, cx + w * 0.28, cy - h * 0.14);
      beaniePath.close();
      canvas.drawPath(beaniePath, beaniePaint);

      // Ribbed cuff
      final cuffPaint = Paint()..color = const Color(0xFF689F38);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy - h * 0.16), width: w * 0.58, height: h * 0.07),
          const Radius.circular(4),
        ),
        cuffPaint,
      );

      // Cute white daisy
      _drawDaisy(canvas, cx + w * 0.18, cy - h * 0.22, w * 0.04);
    } else if (id == 'strawberry') {
      // Strawberry headband / clip
      final sPaint = Paint()..color = const Color(0xFFE53935);
      final sbX = cx + w * 0.18;
      final sbY = cy - h * 0.22 + sway * 1.5;
      final sPath = Path()
        ..moveTo(sbX, sbY - w * 0.04)
        ..cubicTo(sbX - w * 0.06, sbY - w * 0.04, sbX - w * 0.05, sbY + w * 0.06, sbX, sbY + w * 0.08)
        ..cubicTo(sbX + w * 0.05, sbY + w * 0.06, sbX + w * 0.06, sbY - w * 0.04, sbX, sbY - w * 0.04)
        ..close();
      canvas.drawPath(sPath, sPaint);

      // Green Calyx
      final calyxPaint = Paint()..color = const Color(0xFF4CAF50);
      canvas.drawCircle(Offset(sbX - w * 0.02, sbY - w * 0.04), w * 0.015, calyxPaint);
      canvas.drawCircle(Offset(sbX, sbY - w * 0.045), w * 0.015, calyxPaint);
      canvas.drawCircle(Offset(sbX + w * 0.02, sbY - w * 0.04), w * 0.015, calyxPaint);

      // Seeds
      final seedPaint = Paint()..color = const Color(0xFFFFEE58);
      canvas.drawCircle(Offset(sbX - w * 0.02, sbY), 1.2, seedPaint);
      canvas.drawCircle(Offset(sbX + w * 0.02, sbY), 1.2, seedPaint);
      canvas.drawCircle(Offset(sbX, sbY + w * 0.035), 1.2, seedPaint);
    } else if (id == 'goth') {
      // Bat wing hair clip
      final batPaint = Paint()..color = const Color(0xFF1E1E1E);
      final bx = cx - w * 0.18;
      final by = cy - h * 0.20 + sway * 1.2;
      final batPath = Path()
        ..moveTo(bx, by)
        ..lineTo(bx - w * 0.08, by - h * 0.04)
        ..lineTo(bx - w * 0.05, by - h * 0.01)
        ..lineTo(bx - w * 0.09, by + h * 0.02)
        ..lineTo(bx, by + h * 0.01)
        ..close();
      canvas.drawPath(batPath, batPaint);

      // Purple crystal center
      final gemPaint = Paint()..color = const Color(0xFFBA68C8);
      canvas.drawCircle(Offset(bx, by), w * 0.018, gemPaint);
    }
  }

  void _drawSakuraFlower(Canvas canvas, double cx, double cy, double r, double rot) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rot);
    final petalPaint = Paint()..color = const Color(0xFFFFB2C9);
    for (int i = 0; i < 5; i++) {
      canvas.save();
      canvas.rotate(i * (2 * math.pi / 5));
      final pPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-r * 0.4, -r * 0.8, 0, -r)
        ..quadraticBezierTo(r * 0.4, -r * 0.8, 0, 0);
      canvas.drawPath(pPath, petalPaint);
      canvas.restore();
    }
    // Flower center
    canvas.drawCircle(Offset.zero, r * 0.25, Paint()..color = const Color(0xFFFF4081));
    canvas.restore();
  }

  void _drawDaisy(Canvas canvas, double cx, double cy, double r) {
    final petalPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 6; i++) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(i * (math.pi / 3));
      canvas.drawOval(Rect.fromCenter(center: Offset(0, -r * 0.7), width: r * 0.4, height: r * 0.7), petalPaint);
      canvas.restore();
    }
    canvas.drawCircle(Offset(cx, cy), r * 0.35, Paint()..color = const Color(0xFFFFD54F));
  }

  void _drawButterflyClip(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    double flap, {
    required bool isLeft,
  }) {
    canvas.save();
    canvas.translate(cx, cy);
    final scaleX = (isLeft ? 1.0 : -1.0) * (0.85 + 0.15 * flap);
    canvas.scale(scaleX, 1.0);

    final wingPaint = Paint()..color = const Color(0xFFCE93D8);
    // Upper wing
    final wing1 = Path()
      ..moveTo(0, 0)
      ..cubicTo(r * 0.5, -r * 0.8, r * 1.1, -r * 0.4, 0, 0);
    canvas.drawPath(wing1, wingPaint);

    // Lower wing
    final wing2 = Path()
      ..moveTo(0, 0)
      ..cubicTo(r * 0.5, r * 0.6, r * 0.9, r * 0.3, 0, 0);
    canvas.drawPath(wing2, Paint()..color = const Color(0xFFBA68C8));

    // Center body
    canvas.drawCircle(Offset.zero, r * 0.18, Paint()..color = Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GirlyPopPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.character.id != character.id;
  }
}
