import 'package:flutter/material.dart';
import '../../app/living_lily.dart';
import '../../app/theme.dart';
import '../../widgets/girly_pop_avatar.dart';
import '../home/bloom_home.dart';
import 'auth_service.dart';

enum AuthMode {
  login,
  signUp,
  onboarding,
  forgotPassword,
}

/// A comprehensive, botanical-themed authentication and profile creation screen.
/// Includes Login, Sign Up, Multi-Step Profile Onboarding, and Password Recovery.
class BloomAuthPage extends StatefulWidget {
  const BloomAuthPage({
    super.key,
    this.initialMode = AuthMode.login,
  });

  final AuthMode initialMode;

  @override
  State<BloomAuthPage> createState() => _BloomAuthPageState();
}

class _BloomAuthPageState extends State<BloomAuthPage> {
  late AuthMode _mode;

  // Login form controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscure = true;
  bool _rememberMe = true;
  String? _loginError;

  // Sign up form controllers
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();
  bool _signupObscure = true;
  bool _agreedToTerms = true;
  String? _signupError;

  // Onboarding wizard state
  int _onboardingStep = 0; // 0: Goals, 1: Cycle Calibration, 2: Info & Avatar, 3: Success
  String _selectedGoal = 'Track cycle & symptoms';
  int _cycleLength = 28;
  int _periodLength = 5;
  DateTime _lastPeriodDate = DateTime.now().subtract(const Duration(days: 14));
  int _age = 24;
  double _heightCm = 165.0;
  double _weightKg = 58.0;
  String _selectedAvatarId = 'coquette';

  // Forgot password controllers
  final _forgotEmailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _recoveryCodeSent = false;
  final _codeController = TextEditingController();
  String? _forgotMessage;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    final current = AuthService.instance.currentUser.value;
    _loginEmailController.text = current.email;
    _selectedAvatarId = current.avatarId;
    _age = current.age;
    _heightCm = current.heightCm;
    _weightKg = current.weightKg;
    _selectedGoal = current.trackingGoal;
    _cycleLength = current.usualCycleLength;
    _periodLength = current.usualPeriodLength;
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    _forgotEmailController.dispose();
    _newPasswordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final pass = _loginPasswordController.text.trim();

    if (email.isEmpty) {
      setState(() => _loginError = 'Please enter your email address');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _loginError = 'Please enter a valid email address');
      return;
    }
    if (pass.isEmpty) {
      setState(() => _loginError = 'Please enter your password');
      return;
    }

    setState(() {
      _loading = true;
      _loginError = null;
    });

    final success = await AuthService.instance.login(
      email: email,
      password: pass,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      _navigateToHome();
    } else {
      setState(() => _loginError = 'Invalid email or password. (Min 6 chars)');
    }
  }

  void _handleQuickDemoLogin() async {
    setState(() => _loading = true);
    await AuthService.instance.login(
      email: 'bloom.user@bloom.app',
      password: 'bloom123',
    );
    if (!mounted) return;
    setState(() => _loading = false);
    _navigateToHome();
  }

  void _handleSignupNext() {
    final name = _signupNameController.text.trim();
    final email = _signupEmailController.text.trim();
    final pass = _signupPasswordController.text.trim();
    final confirm = _signupConfirmPasswordController.text.trim();

    if (name.isEmpty) {
      setState(() => _signupError = 'Please enter your name');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _signupError = 'Please enter a valid email address');
      return;
    }
    if (pass.length < 6) {
      setState(() => _signupError = 'Password must be at least 6 characters');
      return;
    }
    if (pass != confirm) {
      setState(() => _signupError = 'Passwords do not match');
      return;
    }
    if (!_agreedToTerms) {
      setState(() => _signupError = 'Please agree to the privacy terms');
      return;
    }

    setState(() {
      _signupError = null;
      _mode = AuthMode.onboarding;
      _onboardingStep = 0;
    });
  }

  Future<void> _finishOnboarding() async {
    setState(() => _loading = true);

    final name = _signupNameController.text.trim().isNotEmpty
        ? _signupNameController.text.trim()
        : 'Bloom User';
    final email = _signupEmailController.text.trim().isNotEmpty
        ? _signupEmailController.text.trim()
        : 'bloom.user@bloom.app';
    final pass = _signupPasswordController.text.trim().isNotEmpty
        ? _signupPasswordController.text.trim()
        : 'bloom123';

    await AuthService.instance.register(
      name: name,
      email: email,
      password: pass,
      avatarId: _selectedAvatarId,
      age: _age,
      heightCm: _heightCm,
      weightKg: _weightKg,
      trackingGoal: _selectedGoal,
      usualCycleLength: _cycleLength,
      usualPeriodLength: _periodLength,
    );

    if (!mounted) return;
    setState(() => _loading = false);
    _navigateToHome();
  }

  void _handleForgotPassword() async {
    final email = _forgotEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _forgotMessage = 'Please enter a valid email address');
      return;
    }

    setState(() => _loading = true);
    await AuthService.instance.resetPassword(email);
    if (!mounted) return;

    setState(() {
      _loading = false;
      _recoveryCodeSent = true;
      _codeController.text = '784920';
      _forgotMessage = 'We sent a 6-digit recovery code to $email';
    });
  }

  void _handleResetPasswordComplete() async {
    final newPass = _newPasswordController.text.trim();
    if (newPass.length < 6) {
      setState(() => _forgotMessage = 'New password must be at least 6 characters');
      return;
    }
    setState(() => _loading = true);
    await AuthService.instance.login(
      email: _forgotEmailController.text.trim(),
      password: newPass,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const BloomHome(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0DDF4),
              Color(0xFFFFF6F2),
              Color(0xFFF9E4EE),
              Color(0xFFEFE8F8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeaderLily(),
                    const SizedBox(height: 18),
                    _buildMainCard(),
                    const SizedBox(height: 18),
                    _buildBottomBar(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderLily() {
    return Column(
      children: [
        const LivingLily(
          size: 78,
          showStem: false,
          interactive: true,
          glow: true,
        ),
        const SizedBox(height: 6),
        Text(
          'Bloom',
          style: TextStyle(
            fontFamily: 'serif',
            color: BloomTheme.plum,
            fontSize: 42,
            height: 1,
            letterSpacing: -1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _mode == AuthMode.login
              ? 'welcome back, darling'
              : _mode == AuthMode.signUp
                  ? 'your private, mindful cycle space'
                  : _mode == AuthMode.onboarding
                      ? 'step ${_onboardingStep + 1} of 4 · create your profile'
                      : 'reset your credentials',
          style: TextStyle(
            color: BloomTheme.textSecondary,
            letterSpacing: 1.4,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: BloomTheme.peach.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: BloomTheme.plum.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: _mode == AuthMode.login
            ? _buildLoginView()
            : _mode == AuthMode.signUp
                ? _buildSignUpView()
                : _mode == AuthMode.onboarding
                    ? _buildOnboardingView()
                    : _buildForgotPasswordView(),
      ),
    );
  }

  // --- 1. LOGIN VIEW ---

  Widget _buildLoginView() {
    return Column(
      key: const ValueKey('login_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSegmentBar(),
        const SizedBox(height: 22),
        _buildFieldLabel('Email address'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _loginEmailController,
          hint: 'you@bloom.app',
          icon: Icons.alternate_email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildFieldLabel('Password'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _loginPasswordController,
          hint: '••••••••',
          icon: Icons.lock_outline,
          obscureText: _loginObscure,
          suffix: IconButton(
            icon: Icon(
              _loginObscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: BloomTheme.textSecondary,
            ),
            onPressed: () => setState(() => _loginObscure = !_loginObscure),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: BloomTheme.raspberry,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    onChanged: (val) =>
                        setState(() => _rememberMe = val ?? true),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Remember me',
                  style: TextStyle(
                    fontSize: 12,
                    color: BloomTheme.textSecondary,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => setState(() {
                _mode = AuthMode.forgotPassword;
                _forgotMessage = null;
                _recoveryCodeSent = false;
              }),
              child: Text(
                'Forgot password?',
                style: TextStyle(
                  fontSize: 12,
                  color: BloomTheme.raspberry,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (_loginError != null) ...[
          const SizedBox(height: 12),
          _buildErrorBanner(_loginError!),
        ],
        const SizedBox(height: 20),
        _buildPrimaryButton(
          label: 'Sign In to Bloom',
          onPressed: _loading ? null : _handleLogin,
          icon: Icons.arrow_forward_rounded,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: BloomTheme.peach),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _loading ? null : _handleQuickDemoLogin,
          child: Text(
            'Quick Demo Sign-In',
            style: TextStyle(
              color: BloomTheme.plum,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildSocialDivider(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSocialPill(
                label: 'Google',
                icon: Icons.g_mobiledata_rounded,
                onTap: _handleQuickDemoLogin,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSocialPill(
                label: 'Apple',
                icon: Icons.apple_rounded,
                onTap: _handleQuickDemoLogin,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 2. SIGN UP VIEW ---

  Widget _buildSignUpView() {
    final pass = _signupPasswordController.text;
    final int strength = _calculatePasswordStrength(pass);

    return Column(
      key: const ValueKey('signup_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSegmentBar(),
        const SizedBox(height: 22),
        _buildFieldLabel('Full Name or Preferred Nickname'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _signupNameController,
          hint: 'e.g. Aria, Chloe, Maya',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 14),
        _buildFieldLabel('Email address'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _signupEmailController,
          hint: 'you@bloom.app',
          icon: Icons.alternate_email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _buildFieldLabel('Create Password'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _signupPasswordController,
          hint: 'At least 6 characters',
          icon: Icons.lock_outline,
          obscureText: _signupObscure,
          onChanged: (_) => setState(() {}),
          suffix: IconButton(
            icon: Icon(
              _signupObscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: BloomTheme.textSecondary,
            ),
            onPressed: () => setState(() => _signupObscure = !_signupObscure),
          ),
        ),
        const SizedBox(height: 8),
        _buildPasswordStrengthBar(strength),
        const SizedBox(height: 14),
        _buildFieldLabel('Confirm Password'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _signupConfirmPasswordController,
          hint: 'Re-enter your password',
          icon: Icons.lock_reset,
          obscureText: _signupObscure,
          onChanged: (_) => setState(() {}),
          suffix: _signupConfirmPasswordController.text.isNotEmpty &&
                  _signupConfirmPasswordController.text == _signupPasswordController.text
              ? const Icon(Icons.check_circle, size: 20, color: Color(0xFF43A047))
              : null,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _agreedToTerms,
                activeColor: BloomTheme.raspberry,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                onChanged: (val) =>
                    setState(() => _agreedToTerms = val ?? true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'I agree to Bloom’s private on-device cycle storage and health commitment.',
                style: TextStyle(
                  fontSize: 11,
                  color: BloomTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        if (_signupError != null) ...[
          const SizedBox(height: 12),
          _buildErrorBanner(_signupError!),
        ],
        const SizedBox(height: 20),
        _buildPrimaryButton(
          label: 'Continue to Profile Setup →',
          onPressed: _handleSignupNext,
        ),
      ],
    );
  }

  // --- 3. MULTI-STEP ONBOARDING WIZARD ---

  Widget _buildOnboardingView() {
    return Column(
      key: ValueKey('onboarding_step_$_onboardingStep'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildWizardProgress(),
        const SizedBox(height: 18),
        if (_onboardingStep == 0) _buildStepGoals(),
        if (_onboardingStep == 1) _buildStepCycle(),
        if (_onboardingStep == 2) _buildStepPersona(),
        if (_onboardingStep == 3) _buildStepSuccess(),
      ],
    );
  }

  Widget _buildWizardProgress() {
    return Row(
      children: List.generate(4, (index) {
        final active = index <= _onboardingStep;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 5,
            decoration: BoxDecoration(
              color: active ? BloomTheme.raspberry : BloomTheme.peach.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  // Step 0: Goals
  Widget _buildStepGoals() {
    final goals = [
      (
        'Track cycle & symptoms',
        '🌸',
        'Daily menstrual flow, cramps, moods and PMS tracking'
      ),
      (
        'Predict ovulation & fertility',
        '🌙',
        'Fertile window alerts, ovulation prediction and chance ratings'
      ),
      (
        'Trying to conceive',
        '💕',
        'Conception timing, basal body temp logs and LH test tracker'
      ),
      (
        'Hormonal wellness & balance',
        '🌿',
        'Mindful energy, skin insights and holistic cycle awareness'
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What is your primary focus?',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: BloomTheme.plum,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Bloom personalizes your insights and calendar around your needs.',
          style: TextStyle(fontSize: 12, color: BloomTheme.textSecondary),
        ),
        const SizedBox(height: 14),
        ...goals.map((g) {
          final selected = _selectedGoal == g.$1;
          return GestureDetector(
            onTap: () => setState(() => _selectedGoal = g.$1),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected
                    ? BloomTheme.blush
                    : BloomTheme.peach.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? BloomTheme.raspberry
                      : BloomTheme.peach.withValues(alpha: 0.4),
                  width: selected ? 1.8 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Text(g.$2, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.$1,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: BloomTheme.plum,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          g.$3,
                          style: TextStyle(
                            fontSize: 11,
                            color: BloomTheme.textSecondary,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle,
                        color: BloomTheme.raspberry, size: 20),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        _buildPrimaryButton(
          label: 'Next: Cycle Baseline →',
          onPressed: () => setState(() => _onboardingStep = 1),
        ),
      ],
    );
  }

  // Step 1: Cycle Calibration
  Widget _buildStepCycle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Cycle Calibration',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: BloomTheme.plum,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Provide your best estimates. Bloom learns and refines automatically.',
          style: TextStyle(fontSize: 12, color: BloomTheme.textSecondary),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BloomTheme.blush.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: BloomTheme.peach),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Average Cycle Length',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: BloomTheme.plum),
                    ),
                  ),
                  Text(
                    '$_cycleLength days',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: BloomTheme.raspberry,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _cycleLength.toDouble(),
                min: 21,
                max: 45,
                divisions: 24,
                activeColor: BloomTheme.raspberry,
                inactiveColor: BloomTheme.peach,
                onChanged: (v) => setState(() => _cycleLength = v.round()),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Usual Period Duration',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: BloomTheme.plum),
                    ),
                  ),
                  Text(
                    '$_periodLength days',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: BloomTheme.raspberry,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _periodLength.toDouble(),
                min: 2,
                max: 10,
                divisions: 8,
                activeColor: BloomTheme.raspberry,
                inactiveColor: BloomTheme.peach,
                onChanged: (v) => setState(() => _periodLength = v.round()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BloomTheme.peach),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Period Started',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: BloomTheme.plum),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_lastPeriodDate.day}/${_lastPeriodDate.month}/${_lastPeriodDate.year}',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: BloomTheme.raspberry),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.calendar_month, size: 18),
                label: const Text('Change Date'),
                style: TextButton.styleFrom(
                  foregroundColor: BloomTheme.raspberry,
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _lastPeriodDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 90)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _lastPeriodDate = picked);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: BloomTheme.peach),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => setState(() => _onboardingStep = 0),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildPrimaryButton(
                label: 'Next: Personal Info →',
                onPressed: () => setState(() => _onboardingStep = 2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 2: Persona & Avatar
  Widget _buildStepPersona() {
    final avatar = GirlyPopGallery.get(_selectedAvatarId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Details & Avatar',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: BloomTheme.plum,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select your favorite aesthetic avatar for your Bloom profile.',
          style: TextStyle(fontSize: 12, color: BloomTheme.textSecondary),
        ),
        const SizedBox(height: 14),
        Center(
          child: Column(
            children: [
              GirlyPopAvatar(
                avatarId: _selectedAvatarId,
                size: 72,
                showEditBadge: false,
              ),
              const SizedBox(height: 6),
              Text(
                '${avatar.name} · ${avatar.tagline}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: BloomTheme.plum,
                ),
              ),
              Text(
                avatar.vibe,
                style: TextStyle(fontSize: 11, color: BloomTheme.raspberry),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: GirlyPopGallery.characters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final char = GirlyPopGallery.characters[index];
              final isSel = char.id == _selectedAvatarId;
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatarId = char.id),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSel ? BloomTheme.raspberry : Colors.transparent,
                      width: 2.2,
                    ),
                  ),
                  child: GirlyPopAvatar(
                    avatarId: char.id,
                    size: 50,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildNumberInput(
                label: 'Age',
                value: '$_age yrs',
                onDecrement: () => setState(() {
                  if (_age > 12) _age--;
                }),
                onIncrement: () => setState(() {
                  if (_age < 75) _age++;
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildNumberInput(
                label: 'Height',
                value: '${_heightCm.toInt()} cm',
                onDecrement: () => setState(() {
                  if (_heightCm > 120) _heightCm -= 1;
                }),
                onIncrement: () => setState(() {
                  if (_heightCm < 210) _heightCm += 1;
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildNumberInput(
                label: 'Weight',
                value: '${_weightKg.toInt()} kg',
                onDecrement: () => setState(() {
                  if (_weightKg > 35) _weightKg -= 1;
                }),
                onIncrement: () => setState(() {
                  if (_weightKg < 180) _weightKg += 1;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: BloomTheme.peach),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => setState(() => _onboardingStep = 1),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildPrimaryButton(
                label: 'Review Profile →',
                onPressed: () => setState(() => _onboardingStep = 3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 3: Success Celebration
  Widget _buildStepSuccess() {
    final avatar = GirlyPopGallery.get(_selectedAvatarId);
    final name = _signupNameController.text.trim().isNotEmpty
        ? _signupNameController.text.trim()
        : 'Bloom User';

    return Column(
      children: [
        const LivingLily(size: 68, showStem: false, glow: true),
        const SizedBox(height: 10),
        Text(
          'Your Bloom Profile is Ready! 🌸',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: BloomTheme.plum,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Welcome to your private wellness sanctuary, $name.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: BloomTheme.textSecondary),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BloomTheme.blush,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BloomTheme.peach),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  GirlyPopAvatar(avatarId: _selectedAvatarId, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: BloomTheme.plum,
                          ),
                        ),
                        Text(
                          _signupEmailController.text.trim().isNotEmpty
                              ? _signupEmailController.text.trim()
                              : 'bloom.user@bloom.app',
                          style: TextStyle(
                              fontSize: 11, color: BloomTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🌸 ${avatar.name}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: BloomTheme.raspberry,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 22),
              _buildSummaryRow('Goal', _selectedGoal),
              _buildSummaryRow(
                  'Cycle Baseline', '$_cycleLength days · $_periodLength days flow'),
              _buildSummaryRow('Personal', '$_age yrs · ${_heightCm.toInt()} cm · ${_weightKg.toInt()} kg'),
              _buildSummaryRow('Data Security', '🔒 Stored privately on device'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildPrimaryButton(
          label: 'Enter Bloom Dashboard',
          onPressed: _loading ? null : _finishOnboarding,
          icon: Icons.spa_rounded,
        ),
      ],
    );
  }

  // --- 4. FORGOT PASSWORD VIEW ---

  Widget _buildForgotPasswordView() {
    return Column(
      key: const ValueKey('forgot_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _mode = AuthMode.login),
            ),
            const SizedBox(width: 4),
            Text(
              'Reset Password',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BloomTheme.plum,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Enter your registered email address to receive your recovery code.',
          style: TextStyle(fontSize: 12, color: BloomTheme.textSecondary),
        ),
        const SizedBox(height: 16),
        _buildFieldLabel('Email address'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _forgotEmailController,
          hint: 'you@bloom.app',
          icon: Icons.alternate_email,
          keyboardType: TextInputType.emailAddress,
        ),
        if (_recoveryCodeSent) ...[
          const SizedBox(height: 16),
          _buildFieldLabel('6-Digit Verification Code'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _codeController,
            hint: '784920',
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('New Password'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _newPasswordController,
            hint: 'At least 6 characters',
            icon: Icons.lock_outline,
            obscureText: true,
          ),
        ],
        if (_forgotMessage != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BloomTheme.peach.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _forgotMessage!,
              style: TextStyle(
                fontSize: 12,
                color: BloomTheme.plum,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildPrimaryButton(
          label: _recoveryCodeSent ? 'Set New Password & Sign In' : 'Send Recovery Code',
          onPressed: _loading
              ? null
              : _recoveryCodeSent
                  ? _handleResetPasswordComplete
                  : _handleForgotPassword,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _mode = AuthMode.login),
            child: Text(
              'Back to Sign In',
              style: TextStyle(
                color: BloomTheme.raspberry,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- REUSABLE WIDGETS ---

  Widget _buildSegmentBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BloomTheme.peach.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _mode = AuthMode.login;
                _loginError = null;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _mode == AuthMode.login
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _mode == AuthMode.login
                      ? [
                          BoxShadow(
                            color: BloomTheme.plum.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Sign In',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _mode == AuthMode.login
                        ? BloomTheme.plum
                        : BloomTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _mode = AuthMode.signUp;
                _signupError = null;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _mode == AuthMode.signUp
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _mode == AuthMode.signUp
                      ? [
                          BoxShadow(
                            color: BloomTheme.plum.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Create Profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _mode == AuthMode.signUp
                        ? BloomTheme.plum
                        : BloomTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: BloomTheme.plum,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(fontSize: 14, color: BloomTheme.plum),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: BloomTheme.textSecondary.withValues(alpha: 0.5),
          fontSize: 13,
        ),
        filled: true,
        fillColor: BloomTheme.surfaceMuted.withValues(alpha: 0.5),
        prefixIcon: Icon(icon, color: BloomTheme.raspberry, size: 20),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: BloomTheme.peach.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: BloomTheme.peach.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: BloomTheme.raspberry, width: 1.6),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            BloomTheme.raspberry,
            BloomTheme.rose,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: BloomTheme.raspberry.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onPressed,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: BloomTheme.peach)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or connect with',
            style: TextStyle(
              fontSize: 11,
              color: BloomTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: BloomTheme.peach)),
      ],
    );
  }

  Widget _buildSocialPill({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BloomTheme.peach),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: BloomTheme.plum),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: BloomTheme.plum,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthBar(int strength) {
    Color color;
    String text;
    switch (strength) {
      case 1:
        color = const Color(0xFFEF5350);
        text = 'Weak password';
        break;
      case 2:
        color = const Color(0xFFFFA726);
        text = 'Moderate';
        break;
      case 3:
        color = const Color(0xFF66BB6A);
        text = 'Strong password';
        break;
      case 4:
        color = BloomTheme.raspberry;
        text = 'Blooming & Secure! 🌸';
        break;
      default:
        color = BloomTheme.peach;
        text = 'Use at least 6 characters';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final active = i < strength;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 4,
                decoration: BoxDecoration(
                  color: active ? color : BloomTheme.peach.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  int _calculatePasswordStrength(String pass) {
    if (pass.isEmpty) return 0;
    if (pass.length < 6) return 1;
    int score = 1;
    if (pass.length >= 8) score++;
    if (RegExp(r'[0-9]').hasMatch(pass)) score++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(pass)) score++;
    return score.clamp(1, 4);
  }

  Widget _buildNumberInput({
    required String label,
    required String value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BloomTheme.peach),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: BloomTheme.textSecondary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: BloomTheme.plum,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: onDecrement,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: BloomTheme.blush,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.remove, size: 14, color: BloomTheme.plum),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onIncrement,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: BloomTheme.blush,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, size: 14, color: BloomTheme.plum),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: BloomTheme.textSecondary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: BloomTheme.plum,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: Color(0xFFD32F2F)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFD32F2F),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 16, color: BloomTheme.plum),
          const SizedBox(width: 6),
          Text(
            '100% Private · Zero data selling · Stored on device',
            style: TextStyle(
              fontSize: 11,
              color: BloomTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
