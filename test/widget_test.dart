import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloom/features/home/bloom_home.dart';
import 'package:bloom/app/bloom_splash.dart';
import 'package:bloom/app/theme.dart';

void main() {
  testWidgets('Bloom shows its five primary destinations', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BloomHome()));

    expect(find.text('YOUR CYCLE'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Assistant'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byTooltip("Add today's entry"), findsOneWidget);
    expect(find.text('Log period'), findsOneWidget);
    expect(find.text('Symptoms'), findsWidgets);
    expect(find.text('Sex'), findsOneWidget);
    expect(find.text("Today's quick log"), findsNothing);
  });

  testWidgets('Home actions open supported entry sections and disclose limits',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BloomHome()));

    await tester.ensureVisible(find.text('Symptoms').first);
    await tester.tap(find.text('Symptoms').first);
    await tester.pumpAndSettle();
    expect(find.text('Symptoms'), findsWidgets);
    expect(find.text('Cramps'), findsOneWidget);
    expect(find.text('Headache'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('entry-search')), 'Cramps');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilterChip, 'Cramps'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Headache'), findsNothing);
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Sex'));
    await tester.tap(find.text('Sex'));
    await tester.pumpAndSettle();
    expect(find.text('Sex and sex drive'), findsOneWidget);
    expect(find.text('Protected sex'), findsOneWidget);
  });

  testWidgets('Home shows primary moods and reveals the full mood grid',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BloomHome()));

    await tester.scrollUntilVisible(find.text('Happy'), 100,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Happy'), findsOneWidget);
    expect(find.text('Calm'), findsOneWidget);
    expect(find.text('Stressed'), findsOneWidget);
    expect(find.text('Tired'), findsOneWidget);
    expect(find.text('Low'), findsNothing);
    expect(find.text('Energetic'), findsNothing);

    await tester.ensureVisible(find.text('More moods'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('More moods'));
    await tester.pumpAndSettle();

    expect(find.text('Energetic'), findsOneWidget);
    expect(find.text('Irritable'), findsOneWidget);
    expect(find.text('Anxious'), findsOneWidget);
    expect(find.text('In pain'), findsOneWidget);

    await tester.tap(find.text('Energetic'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("Add today's entry"));
    await tester.pumpAndSettle();
    final energeticChip = find.ancestor(
        of: find.text('Energetic'), matching: find.byType(ChoiceChip));
    await tester.scrollUntilVisible(energeticChip, 100,
        scrollable: find.byType(Scrollable).last);
    expect(tester.widget<ChoiceChip>(energeticChip).selected, isTrue);
  });

  testWidgets('Home replaces quick log with cycle history and keeps add entry',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BloomHome()));

    expect(find.text("Today's quick log"), findsNothing);
    expect(find.text('Your cycle history'), findsNothing);
    await tester.scrollUntilVisible(find.text('Your cycle history'), 260,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('Your cycle history'), findsOneWidget);
    expect(find.text('Your history will bloom here'), findsOneWidget);

    await tester.tap(find.byTooltip("Add today's entry"));
    await tester.pumpAndSettle();
    expect(find.text("Today's entry"), findsOneWidget);
    expect(find.text('Save entry'), findsOneWidget);
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();
    expect(find.text("Today's entry"), findsNothing);
  });

  testWidgets('Bloom splash shows the full animation before reaching Home',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BloomSplash()));
    await tester.pump();
    expect(find.text('your cycle, your way'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3400));
    expect(find.text('Home'), findsNothing);

    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('Bloom for Partners reveals share code and care guidance',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BloomHome()));

    await tester.scrollUntilVisible(find.text('Link Partner'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Bloom for Partners'), findsWidgets);

    await tester.tap(find.text('Link Partner'));
    await tester.pumpAndSettle();

    expect(find.text('What your partner sees'), findsOneWidget);
    expect(find.text('Partner view ❤️'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Your Bloom Partner Code'), 150,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('Your Bloom Partner Code'), findsOneWidget);
    expect(find.text('BLOOM-7K92'), findsOneWidget);
    expect(find.text('Share code with partner'), findsOneWidget);

    Navigator.pop(tester.element(find.text('BLOOM-7K92')));
    await tester.pumpAndSettle();
  });

  testWidgets('Daily entry includes physical activity, tests, water and notes',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BloomHome()));

    await tester.tap(find.byTooltip("Add today's entry"));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('entry-search')), 'activity');
    await tester.pumpAndSettle();
    expect(find.text('Physical activity'), findsOneWidget);
    expect(find.text('Yoga'), findsOneWidget);
    expect(find.text('Gym'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('entry-search')), 'water');
    await tester.pumpAndSettle();
    expect(find.text('Water'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('entry-search')), 'ovulation');
    await tester.pumpAndSettle();
    expect(find.text('Ovulation test'), findsOneWidget);
    expect(find.text('Test: positive'), findsOneWidget);

    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();
  });

  testWidgets('Calendar tapping a date allows logging period directly without edit dates button',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BloomHome()));

    // Navigate to Calendar
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    // Verify 'Edit period dates' is NOT present
    expect(find.text('Edit period dates'), findsNothing);

    // Tap on a date cell in the calendar (e.g. day 5)
    final day5 = find.text('5').first;
    await tester.tap(day5, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify the date period sheet opened
    expect(find.text('Period Bleeding'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Medium'), findsWidgets);

    // Tap 'Medium' in the choice chips to log period on this day
    await tester.tap(find.widgetWithText(ChoiceChip, 'Medium'));
    await tester.pumpAndSettle();

    expect(find.text('Remove period'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Bottom summary bar reflects period logged
    expect(find.textContaining('Period: Medium flow'), findsOneWidget);
  });

  testWidgets('Tapping Log period on Home takes user to the Calendar',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BloomHome()));

    // Tap 'Log period' button on Home
    await tester.tap(find.text('Log period'));
    await tester.pumpAndSettle();

    // Verify user is now on Calendar screen
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Year'), findsOneWidget);
  });

  testWidgets(
      'Calendar Month and Year views are distinct and functional',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BloomHome()));

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    // Default is Month view with month controls
    expect(find.byTooltip('Previous month'), findsOneWidget);
    expect(find.byTooltip('Next month'), findsOneWidget);

    // Switch to Year view
    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();

    // Year view controls and annual grid are shown
    expect(find.byTooltip('Previous year'), findsOneWidget);
    expect(find.byTooltip('Next year'), findsOneWidget);
    expect(find.textContaining('No periods logged yet'), findsOneWidget);

    // Switch back to Month view
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Previous month'), findsOneWidget);
  });

  testWidgets(
      'Assistant is an interactive chat box where user can ask questions and receive replies',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BloomHome()));

    // Navigate to Assistant
    await tester.tap(find.text('Assistant'));
    await tester.pumpAndSettle();

    // Verify Bloom Assistant header & greeting
    expect(find.text('Bloom Assistant'), findsOneWidget);
    expect(find.textContaining('personal cycle & health assistant'), findsOneWidget);

    // Enter a question about cramps
    final inputField = find.byType(TextField).last;
    await tester.enterText(inputField, 'How do I stop cramps?');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();

    // Message shows in chat
    expect(find.text('How do I stop cramps?'), findsOneWidget);

    // Wait for assistant reply
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify cramp relief answer
    expect(find.textContaining('Heat Therapy'), findsOneWidget);
  });

  testWidgets(
      'Profile options open dedicated functional sheets without placeholder',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BloomHome()));

    // Navigate to Profile
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Verify user profile card (only displays avatar, name, and character style without age/goal)
    expect(find.text('Bloom User'), findsWidgets);
    expect(find.text('🌸 Chloe · Soft Waves'), findsOneWidget);

    // Tapping the pencil icon opens Profile Avatar & Name editor
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Avatars'), findsOneWidget);
    expect(find.text('Save Avatar & Name'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Tap Personal information
    await tester.tap(find.text('Personal information'));
    await tester.pumpAndSettle();
    expect(find.text('Your age'), findsOneWidget);
    expect(find.text('Height'), findsOneWidget);
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('Your tracking goal'), findsOneWidget);
    expect(find.text('Save details'), findsOneWidget);
    expect(find.text('This screen is a visual placeholder'), findsNothing);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Tap Cycle settings
    await tester.tap(find.text('Cycle settings'));
    await tester.pumpAndSettle();
    expect(find.text('Save cycle settings'), findsOneWidget);
    expect(find.text('Average Cycle Length'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Tap Reminders
    await tester.tap(find.text('Reminders'));
    await tester.pumpAndSettle();
    expect(find.text('Upcoming Period Alert'), findsOneWidget);
    expect(find.text('Fertile Window Alert'), findsOneWidget);
    expect(find.text('Daily Wellness Check-in'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Verify redundant 'Profile Avatar' setting tile is removed
    expect(find.text('Profile Avatar'), findsNothing);

    // Tap top card pencil icon to edit Avatar & Name
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Avatars'), findsOneWidget);
    expect(find.text('Select Avatar'), findsOneWidget);
    expect(find.text('Save Avatar & Name'), findsOneWidget);
    await tester.tap(find.text('Ruby')); // Switch to Ruby
    await tester.pumpAndSettle();
    expect(find.textContaining('Ruby • Cherry Pop'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Bloom User'), 'Aria');
    await tester.ensureVisible(find.text('Save Avatar & Name'));
    await tester.tap(find.text('Save Avatar & Name'));
    await tester.pumpAndSettle();

    // Tap Personal information and verify it has age, height, weight, and goal
    await tester.tap(find.text('Personal information'));
    await tester.pumpAndSettle();
    expect(find.text('Your age'), findsOneWidget);
    expect(find.text('Height'), findsOneWidget);
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('Your tracking goal'), findsOneWidget);
    expect(find.text('Choose avatar'), findsNothing);
    await tester.ensureVisible(find.text('Save details'));
    await tester.tap(find.text('Save details'));
    await tester.pumpAndSettle();

    // Verify profile updated with custom name and avatar
    expect(find.text('Aria'), findsOneWidget);
    expect(find.text('🌸 Ruby · Cherry Pop'), findsOneWidget);

    // Scroll Profile down and tap Appearance
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    expect(find.text('Color Theme'), findsOneWidget);
    expect(find.text('Warm Blossom'), findsOneWidget);
    expect(find.text('Lavender Dusk'), findsOneWidget);
    expect(find.text('Sage Meadow'), findsOneWidget);

    // Tap Lavender Dusk and apply
    await tester.tap(find.text('Lavender Dusk'));
    await tester.pumpAndSettle();
    expect(BloomTheme.currentPalette.name, 'Lavender Dusk');
    await tester.ensureVisible(find.text('Apply appearance'));
    await tester.tap(find.text('Apply appearance'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lavender Dusk · Bloom light palette'), findsOneWidget);
  });

  testWidgets(
      'Assistant answers custom typed personal and health queries via Send button',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BloomHome()));

    // Navigate to Assistant
    await tester.tap(find.text('Assistant'));
    await tester.pumpAndSettle();

    final inputField = find.byType(TextField).last;

    // 1. Ask personal cycle question: "When is my next period?"
    await tester.enterText(inputField, 'When is my next period?');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.textContaining('Based on your'), findsWidgets);

    // 2. Ask physical health question: "I have a headache"
    await tester.enterText(inputField, 'I have a headache');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.textContaining('Hormonal headaches'), findsOneWidget);

    // 3. Ask conversational question: "Hello Bloom"
    await tester.enterText(inputField, 'Hello Bloom');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.textContaining('How are you feeling today?'), findsOneWidget);
  });
}
