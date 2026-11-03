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
        highContrastTextSecondary = highContrastTextSecondary ?? const Color(0xFF3B1E29);

  static const roseBloom = BloomPalette(
    name: 'Rose Bloom',
    description: 'Natural plum, raspberry and peach tones',
    plum: Color(0xFF5D3140),
    raspberry: Color(0xFFCF4173),
    rose: Color(0xFFF39399),
    peach: Color(0xFFF6D8BD),
    ivory: Color(0xFFFDF8F5),
    textSecondary: Color(0xFF8A5D6B),
    blush: Color(0xFFFCECE5),
    sage: Color(0xFFE9EEDC),
    surfaceMuted: Color(0xFFFAF1EB),
    highContrastPlum: Color(0xFF2E121E),
    highContrastTextSecondary: Color(0xFF4C2735),
  );

  static const warmBlossom = BloomPalette(
    name: 'Warm Blossom',
    description: 'Soft coral, blush pink, and honey cream',
    plum: Color(0xFF572A24),
    raspberry: Color(0xFFD9534F),
    rose: Color(0xFFF29580),
    peach: Color(0xFFFCE2CE),
    ivory: Color(0xFFFFFDF9),
    textSecondary: Color(0xFF8C5549),
    blush: Color(0xFFFDF0E7),
    sage: Color(0xFFEAEEDB),
    surfaceMuted: Color(0xFFF8EDE5),
    highContrastPlum: Color(0xFF2C110E),
    highContrastTextSecondary: Color(0xFF4D2820),
  );

  static const lavenderDusk = BloomPalette(
    name: 'Lavender Dusk',
    description: 'Serene violet, soft mauve, and lilac',
    plum: Color(0xFF38254C),
    raspberry: Color(0xFF854FB5),
    rose: Color(0xFFB38DD9),
    peach: Color(0xFFE5D8F6),
    ivory: Color(0xFFFAF7FD),
    textSecondary: Color(0xFF67507F),
    blush: Color(0xFFF2ECFA),
    sage: Color(0xFFDFE6D5),
    surfaceMuted: Color(0xFFF0E8F8),
    highContrastPlum: Color(0xFF1E102E),
    highContrastTextSecondary: Color(0xFF3B2651),
  );

  static const sageMeadow = BloomPalette(
    name: 'Sage Meadow',
    description: 'Fresh botanical jade, eucalyptus, and mint',
    plum: Color(0xFF213A2E),
    raspberry: Color(0xFF338A63),
    rose: Color(0xFF73BD98),
    peach: Color(0xFFD3EADE),
    ivory: Color(0xFFF7FAF8),
    textSecondary: Color(0xFF4A6B5B),
    blush: Color(0xFFEBF5EE),
    sage: Color(0xFFC8E2CB),
    surfaceMuted: Color(0xFFE8F2EC),
    highContrastPlum: Color(0xFF0F2119),
    highContrastTextSecondary: Color(0xFF274436),
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
      onPrimaryContainer: dark ? blush : plum,
      secondary: dark ? peach : rose,
      onSecondary: dark ? plum : Colors.white,
      secondaryContainer:
          dark ? const Color(0xFF452B33) : peach.withValues(alpha: 0.35),
      onSecondaryContainer: dark ? peach : plum,
      tertiary: dark ? sage : raspberry,
      onTertiary: Colors.white,
      surface: dark ? const Color(0xFF22161A) : ivory,
      onSurface: dark ? const Color(0xFFF8EDE6) : plum,
      onSurfaceVariant: dark ? const Color(0xFFD4B4BC) : textSecondary,
      surfaceContainerHighest: dark ? const Color(0xFF332328) : surfaceMuted,
      outline: dark ? const Color(0xFF9E7C85) : peach,
      outlineVariant: dark ? const Color(0xFF523D44) : peach.withValues(alpha: 0.5),
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: dark ? Colors.white : plum,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: ThemeData(brightness: brightness)
          .textTheme
          .apply(
            bodyColor: dark ? const Color(0xFFF7EDF8) : plum,
            displayColor: dark ? const Color(0xFFF7EDF8) : plum,
          )
          .copyWith(
            headlineLarge: const TextStyle(
                fontFamily: 'serif', fontSize: 32, fontWeight: FontWeight.w500),
            headlineMedium: const TextStyle(
                fontFamily: 'serif', fontSize: 25, fontWeight: FontWeight.w500),
          ),
      cardTheme: CardThemeData(
        color:
            dark ? const Color(0xFF2E1F24) : Colors.white.withValues(alpha: .94),
        elevation: dark ? 0 : 1,
        shadowColor: plum.withValues(alpha: .06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: peach.withValues(alpha: .45)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? const Color(0xFF2E1F24) : Colors.white,
        indicatorColor: blush,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? raspberry
                  : textSecondary,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 11,
              color: states.contains(WidgetState.selected)
                  ? raspberry
                  : textSecondary,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            )),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: raspberry,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
      ),
    );
  }

  static ThemeData get light => _make(Brightness.light);
  static ThemeData get dark => _make(Brightness.dark);
}
