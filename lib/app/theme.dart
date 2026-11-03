import 'package:flutter/material.dart';

class BloomPalette {
  final String name;
  final String description;
  final Color plum;
  final Color raspberry;
  final Color rose;
  final Color peach;
  final Color ivory;
  final Color textSecondary;
  final Color blush;
  final Color sage;
  final Color surfaceMuted;
  final Color highContrastPlum;
  final Color highContrastTextSecondary;

  const BloomPalette({
    required this.name,
    required this.description,
    required this.plum,
    required this.raspberry,
    required this.rose,
    required this.peach,
    required this.ivory,
    required this.textSecondary,
    required this.blush,
    required this.sage,
    required this.surfaceMuted,
    Color? highContrastPlum,
    Color? highContrastTextSecondary,
  })  : highContrastPlum = highContrastPlum ?? const Color(0xFF1F0D15),
        highContrastTextSecondary =
            highContrastTextSecondary ?? const Color(0xFF3B1E29);

  // 1. Signature Stargazer Lily: Exact plum, velvet rose, petal pink and lime throat from the animation
  static const roseBloom = BloomPalette(
    name: 'Rose Bloom',
    description: 'Signature Stargazer Lily · Royal plum, velvet rose & petal blush',
    plum: Color(0xFF542565),
    raspberry: Color(0xFFD03873),
    rose: Color(0xFFEA578B),
    peach: Color(0xFFFFDDE8),
    ivory: Color(0xFFFFF7FA),
    textSecondary: Color(0xFF754483),
    blush: Color(0xFFF9EAF2),
    sage: Color(0xFFDCEAB2),
    surfaceMuted: Color(0xFFF6E8F2),
    highContrastPlum: Color(0xFF32103F),
    highContrastTextSecondary: Color(0xFF4A1F57),
  );

  // 2. Tiger Lily: Warm golden pollen amber, sunset lily rose and soft leaf sage
  static const warmBlossom = BloomPalette(
    name: 'Warm Blossom',
    description: 'Tiger Lily · Warm amber, golden pollen & velvet rose',
    plum: Color(0xFF56283C),
    raspberry: Color(0xFFD84A70),
    rose: Color(0xFFE88A6E),
    peach: Color(0xFFFFE0CF),
    ivory: Color(0xFFFFFDF8),
    textSecondary: Color(0xFF884E25),
    blush: Color(0xFFFFF0E6),
    sage: Color(0xFFDCE3BF),
    surfaceMuted: Color(0xFFFDF1EB),
    highContrastPlum: Color(0xFF361022),
    highContrastTextSecondary: Color(0xFF562134),
  );

  // 3. Water Lily: Serene twilight violet, lilac mist and aquatic lily pad
  static const lavenderDusk = BloomPalette(
    name: 'Lavender Dusk',
    description: 'Water Lily · Twilight violet, lilac mist & soft plum',
    plum: Color(0xFF421E5C),
    raspberry: Color(0xFFA64A9D),
    rose: Color(0xFFC778BE),
    peach: Color(0xFFEBD4F7),
    ivory: Color(0xFFFAF6FD),
    textSecondary: Color(0xFF6B4785),
    blush: Color(0xFFF3E7FB),
    sage: Color(0xFFD3E0CB),
    surfaceMuted: Color(0xFFF1E4FA),
    highContrastPlum: Color(0xFF240B38),
    highContrastTextSecondary: Color(0xFF42195E),
  );

  // 4. Lily Garden: Botanical stem olive, calyx lime, and delicate bud rose
  static const sageMeadow = BloomPalette(
    name: 'Sage Meadow',
    description: 'Lily Garden · Botanical calyx green, stem sage & rose',
    plum: Color(0xFF402242),
    raspberry: Color(0xFFC43872),
    rose: Color(0xFFE86F98),
    peach: Color(0xFFE5ECCF),
    ivory: Color(0xFFFBFDF9),
    textSecondary: Color(0xFF637648),
    blush: Color(0xFFF2F7EC),
    sage: Color(0xFFD4E3B7),
    surfaceMuted: Color(0xFFEDF4E6),
    highContrastPlum: Color(0xFF260E28),
    highContrastTextSecondary: Color(0xFF3F1942),
  );

  static const List<BloomPalette> all = [
    roseBloom,
    warmBlossom,
    lavenderDusk,
    sageMeadow,
  ];

  static BloomPalette get(String name) => all.firstWhere(
        (p) => p.name.toLowerCase() == name.toLowerCase(),
        orElse: () => roseBloom,
      );
}

abstract final class BloomTheme {
  static BloomPalette _current = BloomPalette.roseBloom;
  static bool _highContrast = false;
  static final ValueNotifier<String> paletteNotifier =
      ValueNotifier<String>('Rose Bloom');

  static Color get plum =>
      _highContrast ? _current.highContrastPlum : _current.plum;
  static Color get raspberry => _current.raspberry;
  static Color get rose => _current.rose;
  static Color get peach => _current.peach;
  static Color get ivory => _current.ivory;
  static Color get textSecondary =>
      _highContrast ? _current.highContrastTextSecondary : _current.textSecondary;
  static Color get blush => _current.blush;
  static Color get sage => _current.sage;
  static Color get surfaceMuted => _current.surfaceMuted;

  // Palette-aligned aliases:
  static Color get primary => raspberry;
  static Color get lavender => raspberry;
  static Color get lilac => peach;

  static BloomPalette get currentPalette => _current;
  static bool get isHighContrast => _highContrast;

  static void setPalette(String name, {bool? highContrast}) {
    if (highContrast != null) _highContrast = highContrast;
    _current = BloomPalette.get(name);
    paletteNotifier.value = '${_current.name}-${_highContrast ? "hc" : "std"}';
  }

  static ThemeData _make(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: dark ? rose : raspberry,
      onPrimary: Colors.white,
      primaryContainer: dark ? plum : blush,
      onPrimaryContainer: dark ? peach : plum,
      secondary: rose,
      onSecondary: Colors.white,
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      surface: dark ? plum : ivory,
      onSurface: dark ? peach : plum,
      surfaceDim: dark ? _current.highContrastPlum : surfaceMuted,
      surfaceBright: dark ? plum : Colors.white,
      outline: peach,
      outlineVariant: dark ? textSecondary : peach,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? plum : ivory,
      fontFamily: 'sans-serif',
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? plum : ivory,
        foregroundColor: dark ? peach : plum,
        elevation: 0,
        centerTitle: true,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dark ? plum : Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? plum : Colors.white,
      ),
      cardTheme: CardThemeData(
        color: dark ? plum : Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: raspberry,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: raspberry,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: plum,
          side: BorderSide(color: peach),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: raspberry),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: raspberry,
        thumbColor: raspberry,
        inactiveTrackColor: peach.withValues(alpha: 0.5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? raspberry : peach,
        ),
      ),
    );
  }

  static ThemeData get light => _make(Brightness.light);
  static ThemeData get dark => _make(Brightness.dark);
}
