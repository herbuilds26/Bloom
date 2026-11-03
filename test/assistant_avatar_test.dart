import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloom/app/assistant_avatar.dart';
import 'package:bloom/app/theme.dart';
import 'package:bloom/features/auth/auth_service.dart';
import 'package:bloom/features/home/bloom_home.dart';

void main() {
  setUp(() async {
    await AuthService.instance.updateProfile(
      name: '',
      username: '',
      age: 0,
      heightCm: 0.0,
      weightKg: 0.0,
      usualCycleLength: 0,
      usualPeriodLength: 0,
    );
  });

  testWidgets('BloomAssistantAvatar renders properly with and without online badge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              BloomAssistantAvatar(size: 48, showOnlineBadge: true),
              BloomAssistantAvatar(size: 30, showOnlineBadge: false),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(BloomAssistantAvatar), findsNWidgets(2));
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('BloomHome profile displays clean non-default state when user has not entered metrics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: BloomTheme.light,
        home: const BloomHome(),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to Profile tab (tab index 3)
    final profileTabFinder = find.text('Profile');
    expect(profileTabFinder, findsOneWidget);
    await tester.tap(profileTabFinder);
    await tester.pumpAndSettle();

    // Verify Personal information displays "Not set · Tap to add age, height & weight"
    expect(find.textContaining('Not set · Tap to add age'), findsOneWidget);

    // Verify Cycle settings displays "Not calibrated"
    expect(find.textContaining('Not calibrated'), findsOneWidget);

    // Verify Reminders display "Off · Turn on to receive alerts"
    expect(find.textContaining('Off · Turn on to receive alerts'), findsOneWidget);
  });

  testWidgets('Appearance color palettes all match the botanical lily animation palette', (tester) async {
    expect(BloomPalette.all.length, 4);
    for (final palette in BloomPalette.all) {
      expect(palette.plum, isNotNull);
      expect(palette.raspberry, isNotNull);
      expect(palette.rose, isNotNull);
      expect(palette.peach, isNotNull);
      expect(palette.sage, isNotNull);
    }

    // Verify Rose Bloom palette colors match botanical Stargazer lily
    expect(BloomPalette.roseBloom.plum, const Color(0xFF542565));
    expect(BloomPalette.roseBloom.raspberry, const Color(0xFFD03873));
    expect(BloomPalette.roseBloom.sage, const Color(0xFFDCEAB2));
  });
}
