import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloom/features/partner/partner_sync_service.dart';
import 'package:bloom/features/home/bloom_home.dart';

void main() {
  setUp(() async {
    await PartnerSyncService.instance.init();
    await PartnerSyncService.instance.disconnectPartner();
  });

  group('PartnerSyncService Unit Tests', () {
    test('Default partner code is generated and formatted as BLOOM-XXXX', () {
      final code = PartnerSyncService.instance.myPartnerCode.value;
      expect(code, startsWith('BLOOM-'));
      expect(code.length, greaterThanOrEqualTo(8));
    });

    test('Connecting to own code throws ArgumentError', () async {
      final myCode = PartnerSyncService.instance.myPartnerCode.value;
      expect(
        () => PartnerSyncService.instance.connectPartner(code: myCode),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Connecting with empty code throws ArgumentError', () async {
      expect(
        () => PartnerSyncService.instance.connectPartner(code: '   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Connecting to valid partner code succeeds and derives live cycle status', () async {
      await PartnerSyncService.instance.connectPartner(
        code: 'BLOOM-M4Y9',
        nickname: 'Maya',
      );

      expect(PartnerSyncService.instance.isConnected.value, isTrue);
      final status = PartnerSyncService.instance.partnerStatus.value;
      expect(status, isNotNull);
      expect(status!.partnerCode, 'BLOOM-M4Y9');
      expect(status.nickname, 'Maya');
      expect(status.cycleDay, inInclusiveRange(1, 28));
      expect(status.phase, isNotEmpty);
      expect(status.symptoms, isNotEmpty);
    });

    test('Disconnecting partner clears connection and status', () async {
      await PartnerSyncService.instance.connectPartner(
        code: 'BLOOM-8X21',
        nickname: 'Alex',
      );
      expect(PartnerSyncService.instance.isConnected.value, isTrue);

      await PartnerSyncService.instance.disconnectPartner();
      expect(PartnerSyncService.instance.isConnected.value, isFalse);
      expect(PartnerSyncService.instance.partnerStatus.value, isNull);
    });

    test('Regenerating code generates a new valid partner code', () async {
      final newCode = await PartnerSyncService.instance.regenerateMyCode();
      expect(newCode, startsWith('BLOOM-'));
      expect(PartnerSyncService.instance.myPartnerCode.value, newCode);
    });
  });

  group('Bloom Partner UI Integration Tests', () {
    testWidgets('Dashboard partner card displays link button when not connected', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: BloomHome()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Link Partner'), 200,
          scrollable: find.byType(Scrollable).first);

      expect(find.text('Bloom for Partners'), findsWidgets);
      expect(find.text('Link Partner'), findsOneWidget);
    });

    testWidgets('Partner sheet allows entering code and reflects live connected partner card', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: BloomHome()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Link Partner'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Link Partner'));
      await tester.pumpAndSettle();

      // Tap "Enter partner's code to connect"
      final enterCodeFinder = find.text("Enter partner's code to connect");
      await tester.scrollUntilVisible(enterCodeFinder, 150,
          scrollable: find.byType(Scrollable).last);
      expect(enterCodeFinder, findsOneWidget);
      await tester.tap(enterCodeFinder);
      await tester.pumpAndSettle();

      // Enter code and nickname into the dialog text fields
      final dialogFinder = find.byType(AlertDialog);
      expect(dialogFinder, findsOneWidget);
      final dialogTextFields = find.descendant(of: dialogFinder, matching: find.byType(TextField));
      await tester.enterText(dialogTextFields.at(0), 'BLOOM-LILY');
      await tester.enterText(dialogTextFields.at(1), 'Lily');
      await tester.pumpAndSettle();

      final connectBtn = find.descendant(of: dialogFinder, matching: find.byType(FilledButton));
      await tester.tap(connectBtn);
      await tester.pumpAndSettle();

      // Partner is now connected!
      expect(PartnerSyncService.instance.isConnected.value, isTrue);
      expect(PartnerSyncService.instance.partnerStatus.value?.nickname, 'Lily');

      // Dismiss partner sheet by popping its navigator
      Navigator.pop(tester.element(find.text('Bloom for Partners').last));
      await tester.pumpAndSettle();

      // Verify dashboard shows connected partner status
      expect(find.textContaining('Connected (Lily)'), findsOneWidget);
      expect(find.text('View Care'), findsOneWidget);
    });
  });
}
