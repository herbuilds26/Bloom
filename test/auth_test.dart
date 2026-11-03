import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloom/features/auth/auth_service.dart';
import 'package:bloom/features/auth/bloom_auth_page.dart';
import 'package:bloom/features/home/bloom_home.dart';

void main() {
  setUp(() async {
    // Reset to default user before each test
    await AuthService.instance.register(
      name: 'Bloom User',
      email: 'bloom.user@bloom.app',
      password: 'bloom123',
    );
  });

  group('AuthService Tests', () {
    test('Default user is logged in with expected baseline credentials', () {
      final user = AuthService.instance.currentUser.value;
      expect(user.name, 'Bloom User');
      expect(user.email, 'bloom.user@bloom.app');
      expect(user.isLoggedIn, isTrue);
    });

    test('Login updates currentUser and succeeds with valid password', () async {
      final success = await AuthService.instance.login(
        email: 'maya@bloom.app',
        password: 'securepassword123',
      );
      expect(success, isTrue);
      expect(AuthService.instance.currentUser.value.email, 'maya@bloom.app');
      expect(AuthService.instance.currentUser.value.name, 'Maya');
      expect(AuthService.instance.isLoggedIn, isTrue);
    });

    test('Logout clears isLoggedIn state', () async {
      await AuthService.instance.logout();
      expect(AuthService.instance.isLoggedIn, isFalse);
    });

    test('Register creates new profile with full credentials and cycle settings', () async {
      await AuthService.instance.register(
        name: 'Chloe',
        email: 'chloe@bloom.app',
        password: 'chloepassword',
        avatarId: 'cherry',
        age: 26,
        heightCm: 168.0,
        weightKg: 55.0,
        trackingGoal: 'Predict ovulation & fertility',
        usualCycleLength: 30,
        usualPeriodLength: 6,
      );

      final user = AuthService.instance.currentUser.value;
      expect(user.name, 'Chloe');
      expect(user.email, 'chloe@bloom.app');
      expect(user.avatarId, 'cherry');
      expect(user.age, 26);
      expect(user.heightCm, 168.0);
      expect(user.weightKg, 55.0);
      expect(user.trackingGoal, 'Predict ovulation & fertility');
      expect(user.usualCycleLength, 30);
      expect(user.usualPeriodLength, 6);
      expect(user.isLoggedIn, isTrue);
    });
  });

  group('BloomAuthPage Widget Tests', () {
    testWidgets('Renders Login view with botanical header, fields and social options',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: BloomAuthPage(initialMode: AuthMode.login)),
      );
      await tester.pump();

      expect(find.text('Bloom'), findsOneWidget);
      expect(find.text('welcome back, darling'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Create Profile'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Sign In to Bloom'), findsOneWidget);
      expect(find.text('Quick Demo Sign-In'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('Shows validation error when signing in with empty email or short password',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: BloomAuthPage(initialMode: AuthMode.login)),
      );
      await tester.pump();

      // Clear email and tap Sign In
      await tester.enterText(find.byType(TextField).first, '');
      await tester.tap(find.text('Sign In to Bloom'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address'), findsOneWidget);

      // Enter invalid email
      await tester.enterText(find.byType(TextField).first, 'invalidemail');
      await tester.tap(find.text('Sign In to Bloom'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('Switching to Create Profile shows signup form and password strength meter',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: BloomAuthPage(initialMode: AuthMode.login)),
      );
      await tester.pump();

      // Tap Create Profile tab
      await tester.tap(find.text('Create Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Full Name or Preferred Nickname'), findsOneWidget);
      expect(find.text('Create Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Continue to Profile Setup →'), findsOneWidget);

      // Type password to trigger strength meter
      final passField = find.byType(TextField).at(2);
      await tester.enterText(passField, 'test123!');
      await tester.pumpAndSettle();

      expect(find.textContaining('password'), findsWidgets);
    });

    testWidgets('Multi-step onboarding wizard steps through goals, cycle, and persona',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: BloomAuthPage(initialMode: AuthMode.signUp)),
      );
      await tester.pump();

      // Fill in signup details
      await tester.enterText(find.byType(TextField).at(0), 'Aria');
      await tester.enterText(find.byType(TextField).at(1), 'aria@bloom.app');
      await tester.enterText(find.byType(TextField).at(2), 'secretpass');
      await tester.enterText(find.byType(TextField).at(3), 'secretpass');
      await tester.pumpAndSettle();

      // Advance to Onboarding Wizard
      await tester.ensureVisible(find.text('Continue to Profile Setup →'));
      await tester.tap(find.text('Continue to Profile Setup →'));
      await tester.pumpAndSettle();

      // Step 0: Goals
      expect(find.text('What is your primary focus?'), findsOneWidget);
      expect(find.text('Track cycle & symptoms'), findsOneWidget);
      expect(find.text('Trying to conceive'), findsOneWidget);

      await tester.ensureVisible(find.text('Trying to conceive'));
      await tester.tap(find.text('Trying to conceive'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Next: Cycle Baseline →'));
      await tester.tap(find.text('Next: Cycle Baseline →'));
      await tester.pumpAndSettle();

      // Step 1: Cycle Calibration
      expect(find.text('Your Cycle Calibration'), findsOneWidget);
      expect(find.text('Average Cycle Length'), findsOneWidget);
      expect(find.text('Usual Period Duration'), findsOneWidget);

      await tester.ensureVisible(find.text('Next: Personal Info →'));
      await tester.tap(find.text('Next: Personal Info →'));
      await tester.pumpAndSettle();

      // Step 2: Personal Details & Avatar
      expect(find.text('Personal Details & Avatar'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      expect(find.text('Height'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);

      await tester.ensureVisible(find.text('Review Profile →'));
      await tester.tap(find.text('Review Profile →'));
      await tester.pumpAndSettle();

      // Step 3: Success Celebration
      expect(find.textContaining('Your Bloom Profile is Ready!'), findsOneWidget);
      expect(find.text('Enter Bloom Dashboard'), findsOneWidget);
    });

    testWidgets('Forgot password flow sends code and allows resetting password',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: BloomAuthPage(initialMode: AuthMode.forgotPassword)),
      );
      await tester.pump();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Send Recovery Code'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'user@bloom.app');
      await tester.tap(find.text('Send Recovery Code'));
      await tester.pumpAndSettle();

      expect(find.text('6-Digit Verification Code'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Set New Password & Sign In'), findsOneWidget);
    });

    testWidgets('Profile tab in BloomHome includes Account & Credentials tile and opens sheet',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: BloomHome()));
      await tester.pumpAndSettle();

      // Navigate to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Account & Credentials tile is visible
      expect(find.text('Account & Credentials'), findsOneWidget);
      expect(find.textContaining('bloom.user@bloom.app'), findsWidgets);

      // Tap Account & Credentials
      await tester.tap(find.text('Account & Credentials'));
      await tester.pumpAndSettle();

      expect(find.text('Password & Security'), findsOneWidget);
      expect(find.text('Switch Account / Login'), findsOneWidget);
      expect(find.text('Log out of Bloom'), findsOneWidget);
    });
  });
}
