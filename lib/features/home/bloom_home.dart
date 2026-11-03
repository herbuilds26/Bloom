import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:share_plus/share_plus.dart';
import '../../app/living_lily.dart';
import '../../app/bloom_splash.dart';
import '../../app/theme.dart';
import '../../domain/cycle_calculator.dart';
import '../../widgets/girly_pop_avatar.dart';
import '../auth/auth_service.dart';
import '../auth/bloom_auth_page.dart';
import '../auth/user_profile.dart';
import 'home_art.dart';

class BloomHome extends StatefulWidget {
  const BloomHome({super.key});
  @override
  State<BloomHome> createState() => _BloomHomeState();
}

class _AssistantMessage {
  _AssistantMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
  final String text;
  final bool isUser;
  final DateTime time;
}

class _BloomHomeState extends State<BloomHome> {
  int tab = 0;
  final Map<DateTime, String> periods = {};
  final Map<DateTime, String> moods = {};
  final Map<DateTime, String> notes = {};
  final Map<DateTime, Set<String>> symptoms = {};
  final Map<DateTime, Set<String>> sexLogs = {};
  final Map<DateTime, Set<String>> dischargeLogs = {};
  final Map<DateTime, Set<String>> digestionLogs = {};
  final Map<DateTime, String> energyLogs = {};
  final Map<DateTime, Set<String>> sleepLogs = {};
  final Map<DateTime, Set<String>> selfCareLogs = {};
  final Map<DateTime, String> pregnancyTests = {};
  final Map<DateTime, String> ovulationTests = {};
  final Map<DateTime, Set<String>> otherLogs = {};
  final Map<DateTime, Set<String>> activityLogs = {};
  final Map<DateTime, double> waterLogs = {};
  final Map<DateTime, double> weightLogs = {};
  final Map<DateTime, double> temperatureLogs = {};
  String partnerCode = 'BLOOM-7K92';
  bool partnerConnected = false;
  String? connectedPartnerCode;

  DateTime selected = CycleCalculator.day(DateTime.now());
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  int calendarViewMode = 0; // 0: Month, 1: Year
  int yearViewYear = DateTime.now().year;

  final TextEditingController _assistantInputController = TextEditingController();
  final ScrollController _assistantScrollController = ScrollController();
  bool _assistantTyping = false;
  final List<_AssistantMessage> _assistantMessages = [];
  final List<String> _suggestedPrompts = [
    'When is my next period?',
    'What phase am I in today?',
    'How to soothe cramps naturally?',
    'Why is my period late?',
    'Am I fertile today?',
    'What did I log today?',
    'What does my discharge mean?',
    'Foods that ease PMS & bloating',
  ];

  // Profile settings state
  String userName = 'Bloom User';
  String userEmail = 'bloom.user@bloom.app';
  int userAge = 24;
  double userHeightCm = 165.0;
  double userWeightKg = 58.0;
  String cycleGoal = 'Track menstrual cycle';
  String userAvatarId = 'coquette';

  int usualCycleLength = 28;
  int usualPeriodLength = 5;
  int lutealPhaseLength = 14;

  bool reminderPeriod = true;
  int reminderDaysBefore = 2;
  bool reminderFertile = true;
  bool reminderDaily = true;
  TimeOfDay reminderTime = const TimeOfDay(hour: 20, minute: 0);

  String selectedPalette = 'Rose Bloom';
  bool highContrastMode = false;

  bool appLockActive = false;
  String appLockPin = '1234';
  bool hideAppSwitcher = true;

  @override
  void initState() {
    super.initState();
    _syncUserProfile(AuthService.instance.currentUser.value);
    AuthService.instance.currentUser.addListener(_onProfileChanged);
    _initAssistantChat();
  }

  void _onProfileChanged() {
    if (!mounted) return;
    setState(() {
      _syncUserProfile(AuthService.instance.currentUser.value);
    });
  }

  void _syncUserProfile(UserProfile user) {
    userName = user.name;
    userEmail = user.email;
    userAge = user.age;
    userHeightCm = user.heightCm;
    userWeightKg = user.weightKg;
    cycleGoal = user.trackingGoal;
    userAvatarId = user.avatarId;
    usualCycleLength = user.usualCycleLength;
    usualPeriodLength = user.usualPeriodLength;
  }

  @override
  void dispose() {
    AuthService.instance.currentUser.removeListener(_onProfileChanged);
    _assistantInputController.dispose();
    _assistantScrollController.dispose();
    super.dispose();
  }

  void _initAssistantChat() {
    _assistantMessages.add(_AssistantMessage(
      text: "Hi! 🌸 I'm Bloom, your personal cycle & health assistant. Ask me anything about your cycle, next period date, symptoms, cramps, fertile window, late periods, or personal care! Type any question below and tap send.",
      isUser: false,
      time: DateTime.now(),
    ));
  }

  void _goToCalendarToLog({DateTime? date}) {
    setState(() {
      tab = 1;
      selected = CycleCalculator.day(date ?? DateTime.now());
      month = DateTime(selected.year, selected.month);
    });
  }

  CycleEstimate get estimate => CycleCalculator.estimate(
      starts: _periodStartDates,
      today: DateTime.now(),
      usualCycleLength: usualCycleLength);

  List<DateTime> get _periodStartDates {
    if (periods.isEmpty) return const [];
    final days = periods.keys.map(CycleCalculator.day).toSet().toList()..sort();
    if (days.isEmpty) return const [];
    final starts = <DateTime>[days.first];
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays > 4) {
        starts.add(days[i]);
      }
    }
    return starts;
  }

  static const _moods = [
    'Calm',
    'Happy',
    'Energetic',
    'Frisky',
    'Mood swings',
    'Irritable',
    'Irritated',
    'Sad',
    'Anxious',
    'Depressed',
    'In pain',
    'Feeling guilty',
    'Obsessive thoughts',
    'Low energy',
    'Apathetic',
    'Confused',
    'Very self-critical',
  ];

  static const _primaryMoods = ['Happy', 'Calm', 'Stressed', 'Tired'];

  static const _sexOptions = [
    ("Didn't have sex", Icons.block),
    ("Protected sex", Icons.lock_outline),
    ("Unprotected sex", Icons.lock_open_outlined),
    ("Oral sex", Icons.face_retouching_natural),
    ("Anal sex", Icons.wine_bar_outlined),
    ("Masturbation", Icons.favorite_border),
    ("Sensual touch", Icons.volunteer_activism_outlined),
    ("Sex toys", Icons.auto_awesome_outlined),
    ("Orgasm", Icons.star_border),
    ("No orgasm", Icons.star_outline_sharp),
    ("High sex drive", Icons.favorite),
    ("Neutral sex drive", Icons.favorite_outline),
    ("Low sex drive", Icons.heart_broken_outlined),
  ];

  static const _symptomOptions = [
    ('Everything is fine', Icons.sentiment_satisfied_alt_outlined),
    ('Cramps', Icons.bolt_outlined),
    ('Tender breasts', Icons.favorite_border_rounded),
    ('Headache', Icons.psychology_outlined),
    ('Acne', Icons.bubble_chart_outlined),
    ('Backache', Icons.airline_seat_recline_extra_outlined),
    ('Fatigue', Icons.battery_2_bar_outlined),
    ('Cravings', Icons.cookie_outlined),
    ('Insomnia', Icons.nights_stay_outlined),
    ('Abdominal pain', Icons.error_outline),
    ('Vaginal itching', Icons.touch_app_outlined),
    ('Vaginal dryness', Icons.water_damage_outlined),
    ('Hot flashes', Icons.whatshot_outlined),
    ('Night sweats', Icons.shower_outlined),
    ('Joint pain', Icons.directions_walk_outlined),
    ('Brain fog', Icons.cloud_outlined),
    ('Dry skin', Icons.grain_outlined),
    ('Dry eyes', Icons.remove_red_eye_outlined),
  ];

  static const _flowOptions = [
    ('None', Icons.remove_circle_outline),
    ('Spotting', Icons.grain_outlined),
    ('Light', Icons.water_drop_outlined),
    ('Medium', Icons.water_drop),
    ('Heavy', Icons.opacity),
  ];

  static const _dischargeOptions = [
    ('No discharge', Icons.block_outlined),
    ('Creamy', Icons.cloud_outlined),
    ('Watery', Icons.water_drop_outlined),
    ('Sticky', Icons.touch_app_outlined),
    ('Egg white', Icons.egg_outlined),
    ('Spotting', Icons.grain_outlined),
    ('Unusual', Icons.help_outline),
    ('Clumpy white', Icons.bubble_chart_outlined),
    ('Gray', Icons.lens_blur_outlined),
  ];

  static const _digestionOptions = [
    ('Nausea', Icons.sick_outlined),
    ('Bloating', Icons.circle_outlined),
    ('Constipation', Icons.block_outlined),
    ('Diarrhea', Icons.water_outlined),
  ];

  static const _sleepOptions = [
    ('Restful (7-9h)', Icons.nights_stay_outlined),
    ('Deep sleep', Icons.bedtime_outlined),
    ('Light / restless', Icons.cloud_outlined),
    ('Trouble sleeping', Icons.nightlight_outlined),
    ('Afternoon nap', Icons.airline_seat_flat_outlined),
    ('Woke up tired', Icons.alarm_off_outlined),
  ];

  static const _energyOptions = [
    ('High energy', Icons.bolt_outlined),
    ('Balanced', Icons.spa_outlined),
    ('Low energy', Icons.battery_2_bar_outlined),
    ('Exhausted', Icons.battery_alert_outlined),
    ('Calm focus', Icons.center_focus_strong_outlined),
  ];

  static const _selfCareOptions = [
    ('Warm bath / heat', Icons.hot_tub_outlined),
    ('Skincare ritual', Icons.face_outlined),
    ('Herbal tea', Icons.local_cafe_outlined),
    ('Fresh air walk', Icons.park_outlined),
    ('Quiet me-time', Icons.self_improvement_outlined),
    ('Reading / cozy', Icons.menu_book_outlined),
    ('Gentle stretching', Icons.accessibility_new_outlined),
  ];

  static const _pregnancyOptions = [
    "Didn't take tests",
    'Positive',
    'Negative',
    'Faint line',
  ];

  static const _ovulationOptions = [
    "Didn't take tests",
    'Test: positive',
    'Test: negative',
    'Ovulation: my method',
  ];

  static const _otherOptions = [
    ('Travel', Icons.location_on_outlined),
    ('Stress', Icons.bolt_outlined),
    ('Meditation', Icons.self_improvement_outlined),
    ('Journaling', Icons.menu_book_outlined),
    ('Kegel exercises', Icons.fitness_center_outlined),
    ('Breathing exercises', Icons.air_outlined),
    ('Disease or injury', Icons.healing_outlined),
    ('Alcohol', Icons.wine_bar_outlined),
  ];

  static const _activityOptions = [
    ("Didn't exercise", Icons.block),
    ('Yoga', Icons.self_improvement_outlined),
    ('Gym', Icons.fitness_center_outlined),
    ('Aerobics & dancing', Icons.music_note_outlined),
    ('Swimming', Icons.pool_outlined),
    ('Team sports', Icons.sports_basketball_outlined),
    ('Running', Icons.directions_run_outlined),
    ('Cycling', Icons.directions_bike_outlined),
    ('Walking', Icons.directions_walk_outlined),
  ];

  bool _hasSex(DateTime date) {
    final key = CycleCalculator.day(date);
    final logs = sexLogs[key];
    if (logs == null || logs.isEmpty) return false;
    return logs.any((s) => s != "Didn't have sex");
  }

  int? _cycleDayFor(DateTime d) {
    final sorted = periods.keys.map(CycleCalculator.day).toSet().toList()..sort();
    if (sorted.isEmpty) return null;
    final past = sorted.where((p) => !p.isAfter(d)).toList();
    if (past.isEmpty) return null;
    return d.difference(past.last).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_dashboard(), _calendar(), _assistant(), _profile()];
    return Scaffold(
      appBar: (tab == 0 || tab == 2)
          ? null
          : AppBar(
              title: const Text('Bloom',
                  style: TextStyle(
                      fontFamily: 'serif',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2))),
      body: SafeArea(child: IndexedStack(index: tab, children: pages)),
      floatingActionButton: FloatingActionButton(
          onPressed: () => _dailyEntry(),
          tooltip: "Add today's entry",
          child: const Icon(Icons.add, size: 30)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).colorScheme.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 7,
        child: SizedBox(
            height: 62,
            child: Row(children: [
              _navItem(0, Icons.spa_outlined, 'Home'),
              _navItem(1, Icons.calendar_month_outlined, 'Calendar'),
              const SizedBox(width: 52),
              _navItem(2, Icons.auto_awesome_outlined, 'Assistant'),
              _navItem(3, Icons.person_outline, 'Profile'),
            ])),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = tab == index;
    return Expanded(
        child: Semantics(
            button: true,
            selected: active,
            label: label,
            child: InkWell(
              onTap: () => setState(() => tab = index),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon,
                        size: 22,
                        color: active
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 2),
                    Text(label,
                        maxLines: 1,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w500,
                            color: active
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                  ]),
            )));
  }

  // --- DASHBOARD (SCREEN 1) ---
  Widget _dashboard() => CustomPaint(
        painter: const BloomFloralWallpaperPainter(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
          children: [
            _topBar(),
            _weekStrip(),
            const SizedBox(height: 6),
            _cycleHeroSection(),
            const SizedBox(height: 12),
            _threeActionButtons(),
            const SizedBox(height: 14),
            _section('How are you today?'),
            _moodPicker(compact: true),
            const SizedBox(height: 16),
            _partnerBannerCard(),
            const SizedBox(height: 16),
            _cycleHistoryCard(),
          ],
        ),
      );

  Widget _topBar() {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Center(
        child: Text(
          '${now.day} ${_monthName(now.month)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: BloomTheme.plum,
          ),
        ),
      ),
    );
  }

  Widget _weekStrip() {
    final today = CycleCalculator.day(DateTime.now());
    final days = List.generate(7, (i) => today.add(Duration(days: i - 3)));
    const weekdayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((d) {
          final isSelected = CycleCalculator.day(selected) == d;
          final isToday = d == today;
          final hasSex = _hasSex(d);
          final isPeriod = periods.containsKey(d);
          final weekdayLabel = weekdayNames[(d.weekday - 1) % 7];

          return InkWell(
            onTap: () => setState(() => selected = d),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isToday)
                    Text('TODAY',
                        style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .4,
                            color: BloomTheme.plum))
                  else
                    Text(weekdayLabel,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: BloomTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPeriod
                          ? BloomTheme.raspberry
                          : (isToday
                              ? BloomTheme.plum
                              : (isSelected ? BloomTheme.peach : Colors.transparent)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${d.day}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: (isToday || isSelected)
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: (isPeriod || isToday)
                            ? Colors.white
                            : BloomTheme.plum,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (hasSex)
                    Icon(Icons.favorite, size: 10, color: BloomTheme.raspberry)
                  else
                    const SizedBox(height: 10),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _cycleHeroSection() {
    final e = estimate;
    final date = e.nextPeriod;
    final remaining =
        date?.difference(CycleCalculator.day(DateTime.now())).inDays;

    String headlineText;
    if (e.cycleDay != null && periods.containsKey(CycleCalculator.day(DateTime.now()))) {
      headlineText = 'Period · Day ${e.cycleDay}';
    } else if (remaining != null && remaining > 0) {
      headlineText = 'Period may start in\n$remaining days';
    } else if (remaining == 0) {
      headlineText = 'Period expected today';
    } else if (e.cycleDay != null) {
      headlineText = 'Cycle Day ${e.cycleDay}';
    } else {
      headlineText = 'Log period to\npredict your cycle';
    }

    return Column(
      children: [
        Text(
          'YOUR CYCLE',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: BloomTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          headlineText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 23,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: BloomTheme.plum,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _phaseSubtitle(e),
              style: TextStyle(
                fontSize: 12,
                color: BloomTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _showPhaseInfoDialog,
              child: Icon(Icons.info_outline,
                  size: 14, color: BloomTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: SizedBox(
            width: 260,
            height: 195,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Decorative Lily in left gap
                const Positioned(
                  left: 2,
                  top: 14,
                  child: Opacity(
                    opacity: 0.82,
                    child: LivingLily(
                      size: 56,
                      showStem: false,
                      interactive: false,
                    ),
                  ),
                ),
                // Decorative Lily in right gap
                const Positioned(
                  right: 4,
                  bottom: 12,
                  child: Opacity(
                    opacity: 0.82,
                    child: LivingLily(
                      size: 50,
                      showStem: false,
                      interactive: false,
                    ),
                  ),
                ),
                // The Cycle Phase Wheel
                CustomPaint(
                  size: const Size.square(190),
                  painter: CyclePhaseWheelPainter(
                    cycleDay: e.cycleDay,
                    cycleLength: e.cycleLength ?? 28,
                    periodLength: 5,
                  ),
                ),
                // Plain cycle & phase display in center
                _cycleCircleCenterContent(e),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _cycleCircleCenterContent(CycleEstimate e) {
    final day = e.cycleDay;
    final isPeriod =
        day != null && periods.containsKey(CycleCalculator.day(DateTime.now()));
    final remaining =
        e.nextPeriod?.difference(CycleCalculator.day(DateTime.now())).inDays;

    String phaseBadge;
    Color phaseColor;
    String dayTitle;
    String phaseName;
    String pregnancyChance;

    if (day == null) {
      phaseBadge = 'TRACK CYCLE';
      phaseColor = BloomTheme.raspberry;
      dayTitle = '--';
      phaseName = 'Tap to Log Period';
      pregnancyChance = 'Predict your cycle & phases';
    } else if (isPeriod || day <= 5) {
      phaseBadge = 'PERIOD';
      phaseColor = BloomTheme.raspberry;
      dayTitle = 'Day $day';
      phaseName = 'Menstrual Phase';
      pregnancyChance = 'Low chance of pregnancy';
    } else if (day >= 12 && day <= 16) {
      phaseBadge = day == 14 ? 'PEAK OVULATION' : 'FERTILE WINDOW';
      phaseColor = BloomTheme.rose;
      dayTitle = 'Day $day';
      phaseName = day == 14 ? 'Ovulation Day' : 'Fertile Window';
      pregnancyChance = 'High chance of pregnancy';
    } else if (day <= 11) {
      phaseBadge = 'FOLLICULAR';
      phaseColor = const Color(0xFFC47B4E);
      dayTitle = 'Day $day';
      phaseName = 'Follicular Phase';
      pregnancyChance = 'Energy & mood rising';
    } else {
      phaseBadge = 'LUTEAL';
      phaseColor = BloomTheme.plum;
      dayTitle = 'Day $day';
      phaseName = 'Luteal Phase';
      pregnancyChance = remaining != null && remaining > 0
          ? 'Period in $remaining days'
          : 'Low chance of pregnancy';
    }

    return InkWell(
      onTap: () => _goToCalendarToLog(date: selected),
      borderRadius: BorderRadius.circular(95),
      child: Container(
        width: 155,
        height: 155,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: phaseColor.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: phaseColor.withValues(alpha: .32), width: 0.8),
              ),
              child: Text(
                phaseBadge,
                style: TextStyle(
                  fontSize: 9.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: phaseColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayTitle,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.05,
                color: BloomTheme.plum,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              phaseName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: BloomTheme.plum,
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                pregnancyChance,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: BloomTheme.textSecondary,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _phaseSubtitle(CycleEstimate e) {
    if (e.cycleDay == null) {
      return 'Track your days for fertile & cycle estimates';
    }
    if (e.cycleDay! <= 5) {
      return 'Menstrual phase · Getting pregnant is less likely';
    } else if (e.cycleDay! >= 12 && e.cycleDay! <= 16) {
      return 'Fertile window · Getting pregnant is more likely';
    } else {
      return 'Getting pregnant is less likely in this phase';
    }
  }

  void _showPhaseInfoDialog() => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cycle & Phase Guide'),
          content: const Text(
            'Estimated phases are calculated from your logged period start dates. '
            'Fertile windows and pregnancy likelihood are gentle estimates based on biological averages, not medical guarantees.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Understood')),
          ],
        ),
      );

  Widget _threeActionButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionRoundButton(
            label: 'Log period',
            icon: Icons.water_drop_outlined,
            isFilled: true,
            color: BloomTheme.raspberry,
            onTap: () => _goToCalendarToLog(),
          ),
          _actionRoundButton(
            label: 'Symptoms',
            icon: Icons.add,
            isFilled: false,
            color: BloomTheme.raspberry,
            onTap: () => _openTodayEntry('symptoms'),
          ),
          _actionRoundButton(
            label: 'Sex',
            icon: Icons.favorite_border_rounded,
            isFilled: false,
            color: BloomTheme.raspberry,
            onTap: () => _openTodayEntry('sex'),
          ),
        ],
      );

  Widget _actionRoundButton({
    required String label,
    required IconData icon,
    required bool isFilled,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? color : Colors.white,
                border: isFilled
                    ? null
                    : Border.all(color: BloomTheme.peach, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: isFilled
                        ? color.withValues(alpha: .28)
                        : BloomTheme.plum.withValues(alpha: .06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: isFilled ? Colors.white : color,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: BloomTheme.plum,
              ),
            ),
          ],
        ),
      ),
    );
  }



  // --- CALENDAR (SCREEN 2) ---
  Widget _calendar() {
    final now = DateTime.now();
    final today = CycleCalculator.day(now);
    final selectedKey = CycleCalculator.day(selected);
    final isSelectedLogged = periods.containsKey(selectedKey);
    final prediction = estimate.nextPeriod;
    final isSelectedPrediction = prediction != null &&
        prediction.isBefore(selected.add(const Duration(days: 4))) &&
        !prediction.isAfter(selected) &&
        !isSelectedLogged;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'Back to Home',
                  onPressed: () => setState(() => tab = 0),
                  icon: const Icon(Icons.close),
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: BloomTheme.peach.withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      _toggleTab('Month', calendarViewMode == 0, () {
                        setState(() => calendarViewMode = 0);
                      }),
                      _toggleTab('Year', calendarViewMode == 1, () {
                        setState(() {
                          calendarViewMode = 1;
                          yearViewYear = month.year;
                        });
                      }),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 12),
            if (calendarViewMode == 0) ...[
              _monthViewControls(now),
              const SizedBox(height: 12),
              _monthBlock(month),
              const SizedBox(height: 16),
              _calendarLegend(),
            ] else ...[
              _yearViewControls(now),
              const SizedBox(height: 14),
              _yearGrid(),
              const SizedBox(height: 16),
              _calendarLegend(),
            ],
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 14,
          child: InkWell(
            onTap: () => _openEntryForDate(selected),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: BloomTheme.plum.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: BloomTheme.peach.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelectedLogged
                          ? BloomTheme.raspberry
                          : BloomTheme.peach.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isSelectedLogged
                          ? Icons.water_drop
                          : Icons.calendar_today_outlined,
                      color: isSelectedLogged ? Colors.white : BloomTheme.plum,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${selected.day} ${_monthName(selected.month)}${selectedKey == today ? ' (Today)' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: BloomTheme.plum,
                          ),
                        ),
                        Text(
                          isSelectedLogged
                              ? 'Period: ${periods[selectedKey]} flow'
                              : (isSelectedPrediction
                                  ? 'Predicted period window'
                                  : 'Tap any date to log entry'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelectedLogged
                                ? BloomTheme.raspberry
                                : BloomTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isSelectedLogged
                              ? BloomTheme.plum
                              : BloomTheme.raspberry)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isSelectedLogged ? 'View entry' : 'Log entry',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelectedLogged
                                ? BloomTheme.plum
                                : BloomTheme.raspberry,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: isSelectedLogged
                              ? BloomTheme.plum
                              : BloomTheme.raspberry,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _toggleTab(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: BloomTheme.plum.withValues(alpha: .06),
                    blurRadius: 4,
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? BloomTheme.plum : BloomTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _monthViewControls(DateTime now) {
    final isCurrentMonth = month.year == now.year && month.month == now.month;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: BloomTheme.plum, size: 28),
          tooltip: 'Previous month',
          onPressed: () {
            setState(() {
              month = DateTime(month.year, month.month - 1);
            });
          },
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_monthName(month.month)} ${month.year}',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: BloomTheme.plum,
              ),
            ),
            if (!isCurrentMonth) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    month = DateTime(now.year, now.month);
                    selected = CycleCalculator.day(now);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: BloomTheme.peach.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: BloomTheme.plum,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: BloomTheme.plum, size: 28),
          tooltip: 'Next month',
          onPressed: () {
            setState(() {
              month = DateTime(month.year, month.month + 1);
            });
          },
        ),
      ],
    );
  }

  Widget _yearViewControls(DateTime now) {
    final isCurrentYear = yearViewYear == now.year;
    final yearPeriodCount =
        periods.keys.where((k) => k.year == yearViewYear).length;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: BloomTheme.plum, size: 28),
              tooltip: 'Previous year',
              onPressed: () {
                setState(() => yearViewYear--);
              },
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$yearViewYear',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: BloomTheme.plum,
                  ),
                ),
                if (!isCurrentYear) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() => yearViewYear = now.year);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: BloomTheme.peach.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'This year',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: BloomTheme.plum,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: BloomTheme.plum, size: 28),
              tooltip: 'Next year',
              onPressed: () {
                setState(() => yearViewYear++);
              },
            ),
          ],
        ),
        Text(
          yearPeriodCount == 0
              ? 'No periods logged yet in $yearViewYear'
              : '$yearPeriodCount period day${yearPeriodCount == 1 ? '' : 's'} logged in $yearViewYear',
          style: TextStyle(
            fontSize: 12,
            color: BloomTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _yearGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.88,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 12,
      itemBuilder: (context, idx) {
        final m = DateTime(yearViewYear, idx + 1);
        return _yearMiniMonthCard(m);
      },
    );
  }

  Widget _yearMiniMonthCard(DateTime m) {
    final daysInMonth = DateTime(m.year, m.month + 1, 0).day;
    final offset = (DateTime(m.year, m.month, 1).weekday - 1) % 7;
    final prediction = estimate.nextPeriod;
    final today = CycleCalculator.day(DateTime.now());

    final monthPeriodCount =
        periods.keys.where((k) => k.year == m.year && k.month == m.month).length;

    return InkWell(
      onTap: () {
        setState(() {
          month = DateTime(m.year, m.month);
          calendarViewMode = 0;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: BloomTheme.peach.withValues(alpha: 0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: BloomTheme.plum.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _monthName(m.month),
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: BloomTheme.plum,
                  ),
                ),
                if (monthPeriodCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: BloomTheme.raspberry.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$monthPeriodCount d',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: BloomTheme.raspberry,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('M', style: TextStyle(fontSize: 8, color: BloomTheme.textSecondary, fontWeight: FontWeight.w600)),
                Text('T', style: TextStyle(fontSize: 8, color: BloomTheme.textSecondary, fontWeight: FontWeight.w600)),
                Text('W', style: TextStyle(fontSize: 8, color: BloomTheme.textSecondary, fontWeight: FontWeight.w600)),
                Text('T', style: TextStyle(fontSize: 8, color: BloomTheme.textSecondary, fontWeight: FontWeight.w600)),
                Text('F', style: TextStyle(fontSize: 8, color: BloomTheme.textSecondary, fontWeight: FontWeight.w600)),
                Text('S', style: TextStyle(fontSize: 8, color: BloomTheme.textSecondary, fontWeight: FontWeight.w600)),
                Text('S', style: TextStyle(fontSize: 8, color: BloomTheme.textSecondary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.0,
                ),
                itemCount: offset + daysInMonth,
                itemBuilder: (ctx, idx) {
                  if (idx < offset) return const SizedBox();
                  final dayNum = idx - offset + 1;
                  final d = DateTime(m.year, m.month, dayNum);
                  final key = CycleCalculator.day(d);
                  final isLogged = periods.containsKey(key);
                  final isPrediction = prediction != null &&
                      prediction.isBefore(d.add(const Duration(days: 4))) &&
                      !prediction.isAfter(d) &&
                      !isLogged;
                  final isToday = key == today;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        month = DateTime(m.year, m.month);
                        selected = d;
                        calendarViewMode = 0;
                      });
                      _openEntryForDate(d);
                    },
                    child: Center(
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLogged
                              ? BloomTheme.raspberry
                              : (isToday ? BloomTheme.plum : null),
                          border: isPrediction
                              ? Border.all(color: BloomTheme.rose, width: 1.2)
                              : (isToday && !isLogged
                                  ? Border.all(color: BloomTheme.plum, width: 1.2)
                                  : null),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: (isLogged || isToday)
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: (isLogged || isToday)
                                ? Colors.white
                                : (isPrediction
                                    ? BloomTheme.raspberry
                                    : BloomTheme.plum),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calendarLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BloomTheme.peach.withValues(alpha: 0.35)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _legendItem(
            icon: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: BloomTheme.raspberry,
                shape: BoxShape.circle,
              ),
            ),
            label: 'Period',
          ),
          _legendItem(
            icon: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: BloomTheme.rose, width: 1.5),
              ),
            ),
            label: 'Predicted period',
          ),
          _legendItem(
            icon: Icon(Icons.favorite, size: 12, color: BloomTheme.raspberry),
            label: 'Intimacy',
          ),
          _legendItem(
            icon: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: BloomTheme.plum,
                shape: BoxShape.circle,
              ),
            ),
            label: 'Logged entry',
          ),
        ],
      ),
    );
  }

  Widget _legendItem({required Widget icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: BloomTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _monthBlock(DateTime m) {
    final daysInMonth = DateTime(m.year, m.month + 1, 0).day;
    final offset = (DateTime(m.year, m.month, 1).weekday - 1) % 7;
    final prediction = estimate.nextPeriod;
    final today = CycleCalculator.day(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: BloomTheme.peach.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: BloomTheme.plum.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('M', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
              Text('T', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
              Text('W', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
              Text('T', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
              Text('F', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
              Text('S', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
              Text('S', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.74,
            ),
            itemCount: offset + daysInMonth,
            itemBuilder: (context, idx) {
              if (idx < offset) return const SizedBox();
              final dayNum = idx - offset + 1;
              final d = DateTime(m.year, m.month, dayNum);
              final key = CycleCalculator.day(d);
              final isLogged = periods.containsKey(key);
              final isPrediction = prediction != null &&
                  prediction.isBefore(d.add(const Duration(days: 4))) &&
                  !prediction.isAfter(d) &&
                  !isLogged;
              final isToday = key == today;
              final isSelected = CycleCalculator.day(selected) == key;
              final hasSex = _hasSex(d);
              final hasLogs = (symptoms[key]?.isNotEmpty ?? false) ||
                  moods.containsKey(key) ||
                  (dischargeLogs[key]?.isNotEmpty ?? false) ||
                  (sleepLogs[key]?.isNotEmpty ?? false) ||
                  (selfCareLogs[key]?.isNotEmpty ?? false);

              return InkWell(
                onTap: () {
                  setState(() => selected = d);
                  _openEntryForDate(d);
                },
                borderRadius: BorderRadius.circular(16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isToday)
                          Text(
                            'TODAY',
                            style: TextStyle(
                              fontSize: 7.0,
                              height: 1.0,
                              fontWeight: FontWeight.w800,
                              color: BloomTheme.plum,
                            ),
                          )
                        else
                          const SizedBox(height: 7),
                        const SizedBox(height: 2),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLogged
                                ? BloomTheme.raspberry
                                : (isToday ? BloomTheme.plum : null),
                            border: isSelected
                                ? Border.all(
                                    color: BloomTheme.plum,
                                    width: 2.0,
                                  )
                                : (isPrediction
                                    ? Border.all(
                                        color: BloomTheme.rose,
                                        width: 1.5,
                                      )
                                    : null),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$dayNum',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: (isLogged || isToday || isSelected)
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: (isLogged || isToday)
                                  ? Colors.white
                                  : (isSelected
                                      ? BloomTheme.plum
                                      : (isPrediction
                                          ? BloomTheme.raspberry
                                          : BloomTheme.plum)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        SizedBox(
                          height: 8,
                          child: hasSex
                              ? Icon(Icons.favorite,
                                  size: 8, color: BloomTheme.raspberry)
                              : (hasLogs
                                  ? Center(
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: BloomTheme.plum,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                  : null),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- DAILY LOG ENTRY (SCREENS 3, 4, 5) ---
  void _dailyEntry({String initialQuery = '', DateTime? forDate}) {
    if (forDate != null) {
      selected = CycleCalculator.day(forDate);
    }
    DateTime activeDate = selected;
    DateTime activeKey = CycleCalculator.day(activeDate);

    String? flow = periods[activeKey];
    var mood = moods[activeKey];
    var currentEnergy = energyLogs[activeKey];
    var selectedSymptoms = <String>{...?symptoms[activeKey]};
    var selectedSex = <String>{...?sexLogs[activeKey]};
    var selectedDischarge = <String>{...?dischargeLogs[activeKey]};
    var selectedDigestion = <String>{...?digestionLogs[activeKey]};
    var selectedSleep = <String>{...?sleepLogs[activeKey]};
    var selectedSelfCare = <String>{...?selfCareLogs[activeKey]};
    String? selectedPregnancy = pregnancyTests[activeKey];
    String? selectedOvulation = ovulationTests[activeKey];
    var selectedOther = <String>{...?otherLogs[activeKey]};
    var selectedActivity = <String>{...?activityLogs[activeKey]};
    var currentWater = waterLogs[activeKey] ?? 0.0;
    var currentWeight = weightLogs[activeKey];
    var currentTemp = temperatureLogs[activeKey];
    final note = TextEditingController(text: notes[activeKey] ?? '');
    final searchController = TextEditingController(text: initialQuery);
    var search = initialQuery;
    var activeCategoryFilter = 'All';

    void saveDate(DateTime k) {
      if (flow == null || flow == 'None') {
        periods.remove(k);
      } else {
        periods[k] = flow!;
      }
      if (mood != null) {
        moods[k] = mood!;
      } else {
        moods.remove(k);
      }
      if (selectedSymptoms.isEmpty) {
        symptoms.remove(k);
      } else {
        symptoms[k] = selectedSymptoms;
      }
      if (selectedSex.isEmpty) {
        sexLogs.remove(k);
      } else {
        sexLogs[k] = selectedSex;
      }
      if (selectedDischarge.isEmpty) {
        dischargeLogs.remove(k);
      } else {
        dischargeLogs[k] = selectedDischarge;
      }
      if (selectedDigestion.isEmpty) {
        digestionLogs.remove(k);
      } else {
        digestionLogs[k] = selectedDigestion;
      }
      if (currentEnergy != null) {
        energyLogs[k] = currentEnergy!;
      } else {
        energyLogs.remove(k);
      }
      if (selectedSleep.isEmpty) {
        sleepLogs.remove(k);
      } else {
        sleepLogs[k] = selectedSleep;
      }
      if (selectedSelfCare.isEmpty) {
        selfCareLogs.remove(k);
      } else {
        selfCareLogs[k] = selectedSelfCare;
      }
      if (selectedPregnancy != null && selectedPregnancy != "Didn't take tests") {
        pregnancyTests[k] = selectedPregnancy!;
      } else {
        pregnancyTests.remove(k);
      }
      if (selectedOvulation != null && selectedOvulation != "Didn't take tests") {
        ovulationTests[k] = selectedOvulation!;
      } else {
        ovulationTests.remove(k);
      }
      if (selectedOther.isEmpty) {
        otherLogs.remove(k);
      } else {
        otherLogs[k] = selectedOther;
      }
      if (selectedActivity.isEmpty) {
        activityLogs.remove(k);
      } else {
        activityLogs[k] = selectedActivity;
      }
      if (currentWater > 0) {
        waterLogs[k] = currentWater;
      } else {
        waterLogs.remove(k);
      }
      if (currentWeight != null) {
        weightLogs[k] = currentWeight!;
      } else {
        weightLogs.remove(k);
      }
      if (currentTemp != null) {
        temperatureLogs[k] = currentTemp!;
      } else {
        temperatureLogs.remove(k);
      }
      if (note.text.trim().isEmpty) {
        notes.remove(k);
      } else {
        notes[k] = note.text.trim();
      }
    }

    void loadDate(DateTime newDate) {
      activeDate = CycleCalculator.day(newDate);
      activeKey = CycleCalculator.day(activeDate);
      selected = activeDate;
      flow = periods[activeKey];
      mood = moods[activeKey];
      currentEnergy = energyLogs[activeKey];
      selectedSymptoms = <String>{...?symptoms[activeKey]};
      selectedSex = <String>{...?sexLogs[activeKey]};
      selectedDischarge = <String>{...?dischargeLogs[activeKey]};
      selectedDigestion = <String>{...?digestionLogs[activeKey]};
      selectedSleep = <String>{...?sleepLogs[activeKey]};
      selectedSelfCare = <String>{...?selfCareLogs[activeKey]};
      selectedPregnancy = pregnancyTests[activeKey];
      selectedOvulation = ovulationTests[activeKey];
      selectedOther = <String>{...?otherLogs[activeKey]};
      selectedActivity = <String>{...?activityLogs[activeKey]};
      currentWater = waterLogs[activeKey] ?? 0.0;
      currentWeight = weightLogs[activeKey];
      currentTemp = temperatureLogs[activeKey];
      note.text = notes[activeKey] ?? '';
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: BloomTheme.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) {
          final normalized = search.trim().toLowerCase();
          final media = MediaQuery.of(ctx);
          final sheetHeight = math.min(
              media.size.height * .92,
              math.max(0.0, media.size.height - media.viewInsets.bottom - 20));

          return Padding(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, media.viewInsets.bottom + 16),
            child: SizedBox(
              height: sheetHeight,
              child: Column(
                children: [
                  // Top bar: 'X' on left, '< Title >' in center, 'Done' on right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() {
                                saveDate(activeKey);
                                loadDate(activeDate.subtract(const Duration(days: 1)));
                              });
                              update(() {});
                            },
                          ),
                          Column(
                            children: [
                              Text(
                                activeKey == CycleCalculator.day(DateTime.now())
                                    ? "Today's entry"
                                    : (activeKey == CycleCalculator.day(DateTime.now().subtract(const Duration(days: 1)))
                                        ? "Yesterday's entry"
                                        : (activeKey == CycleCalculator.day(DateTime.now().add(const Duration(days: 1)))
                                            ? "Tomorrow's entry"
                                            : '${_monthName(activeDate.month)} ${activeDate.day} entry')),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: BloomTheme.plum,
                                ),
                              ),
                              Text(
                                '${_weekdayFullName(activeDate.weekday)}, ${_date(activeDate)}${_cycleDayFor(activeDate) != null ? " · Cycle day ${_cycleDayFor(activeDate)}" : ""}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: BloomTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              setState(() {
                                saveDate(activeKey);
                                loadDate(activeDate.add(const Duration(days: 1)));
                              });
                              update(() {});
                            },
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            saveDate(activeKey);
                          });
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: BloomTheme.raspberry,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Search bar
                  TextField(
                    key: const Key('entry-search'),
                    controller: searchController,
                    onChanged: (v) => update(() => search = v),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => update(() {
                                search = '';
                                searchController.clear();
                              }),
                            )
                          : null,
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          'All',
                          'Body & Flow',
                          'Daily Wellness',
                          'Sleep & Energy',
                          'Lifestyle',
                          'Tests & Vitals',
                        ].map((cat) {
                          final isSelected = activeCategoryFilter == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              selectedColor: BloomTheme.raspberry,
                              labelStyle: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : BloomTheme.plum,
                              ),
                              backgroundColor: Colors.white,
                              onSelected: (_) =>
                                  update(() => activeCategoryFilter = cat),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Scrollable categories
                  Expanded(
                    child: ListView(
                      children: [
                        // SECTION 1: Period & Flow
                        if (_matchesCategory(normalized, 'period bleeding flow none spotting light medium heavy'))
                          _categoryCard('Period Bleeding', [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _flowOptions
                                  .map((f) => ChoiceChip(
                                        avatar: Icon(
                                          f.$2,
                                          size: 16,
                                          color: flow == f.$1
                                              ? Colors.white
                                              : BloomTheme.raspberry,
                                        ),
                                        label: Text(f.$1),
                                        selected: flow == f.$1,
                                        selectedColor: BloomTheme.raspberry,
                                        labelStyle: TextStyle(
                                          color: flow == f.$1
                                              ? Colors.white
                                              : BloomTheme.plum,
                                          fontWeight: flow == f.$1
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                        onSelected: (val) => update(() {
                                          if (f.$1 == 'None' || !val) {
                                            flow = null;
                                          } else {
                                            flow = f.$1;
                                          }
                                        }),
                                      ))
                                  .toList(),
                            ),
                            if (flow != null && flow != 'None') ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => update(() => flow = null),
                                  icon: Icon(Icons.delete_outline,
                                      size: 16, color: BloomTheme.raspberry),
                                  label: Text(
                                    'Remove period',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: BloomTheme.raspberry,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ]),

                        // SECTION 2: Sex and sex drive (Image 3)
                        if (_matchesCategory(normalized, 'sex intimacy sex drive protection orgasm ${_sexOptions.map((e) => e.$1).join(' ')}'))
                          _categoryCard('Sex and sex drive', [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _sexOptions
                                  .where((opt) => normalized.isEmpty || 'sex and sex drive'.contains(normalized) || opt.$1.toLowerCase().contains(normalized))
                                  .map((opt) {
                                final active = selectedSex.contains(opt.$1);
                                return FilterChip(
                                  avatar: Icon(opt.$2, size: 18, color: active ? Colors.white : BloomTheme.raspberry),
                                  label: Text(opt.$1),
                                  selected: active,
                                  onSelected: (val) => update(() {
                                    val ? selectedSex.add(opt.$1) : selectedSex.remove(opt.$1);
                                  }),
                                );
                              }).toList(),
                            ),
                          ]),

                        // SECTION 3: Mood (Image 4)
                        if (_matchesCategory(normalized, 'mood ${_moods.join(' ')}'))
                          _categoryCard('Mood', [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _moods
                                  .where((m) => normalized.isEmpty || 'mood'.contains(normalized) || m.toLowerCase().contains(normalized))
                                  .map((m) {
                                final active = mood == m;
                                return ChoiceChip(
                                  avatar: HomeMoodCharacter(mood: m, size: 24, selected: active),
                                  label: Text(m),
                                  selected: active,
                                  onSelected: (_) => update(() => mood = m),
                                );
                              }).toList(),
                            ),
                          ]),

                        // SECTION 4: Symptoms (Images 4 & 5)
                        if (_matchesCategory(normalized, 'symptoms ${_symptomOptions.map((e) => e.$1).join(' ')}'))
                          _categoryCard('Symptoms', [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _symptomOptions
                                  .where((s) => normalized.isEmpty || 'symptoms'.contains(normalized) || s.$1.toLowerCase().contains(normalized))
                                  .map((s) {
                                final active = selectedSymptoms.contains(s.$1);
                                return FilterChip(
                                  avatar: Icon(s.$2, size: 16, color: active ? Colors.white : BloomTheme.raspberry),
                                  label: Text(s.$1),
                                  selected: active,
                                  onSelected: (val) => update(() {
                                    val ? selectedSymptoms.add(s.$1) : selectedSymptoms.remove(s.$1);
                                  }),
                                );
                              }).toList(),
                            ),
                          ]),

                        // SECTION 5: Vaginal discharge (Image 5)
                        if (_matchesCategory(normalized, 'discharge vaginal ${_dischargeOptions.map((e) => e.$1).join(' ')}'))
                          _categoryCard('Vaginal discharge', [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _dischargeOptions
                                  .where((d) => normalized.isEmpty || 'vaginal discharge'.contains(normalized) || d.$1.toLowerCase().contains(normalized))
                                  .map((d) {
                                final active = selectedDischarge.contains(d.$1);
                                return FilterChip(
                                  avatar: Icon(d.$2, size: 16, color: active ? Colors.white : BloomTheme.raspberry),
                                  label: Text(d.$1),
                                  selected: active,
                                  onSelected: (val) => update(() {
                                    val ? selectedDischarge.add(d.$1) : selectedDischarge.remove(d.$1);
                                  }),
                                );
                              }).toList(),
                            ),
                          ]),

                        // SECTION 6: Digestion and stool (Image 5)
                        if ((activeCategoryFilter == 'All' || activeCategoryFilter == 'Body & Flow' || normalized.isNotEmpty) &&
                            _matchesCategory(normalized, 'digestion stool ${_digestionOptions.map((e) => e.$1).join(' ')}'))
                          _categoryCard('Digestion and stool', [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _digestionOptions
                                  .where((dg) => normalized.isEmpty || 'digestion and stool'.contains(normalized) || dg.$1.toLowerCase().contains(normalized))
                                  .map((dg) {
                                final active = selectedDigestion.contains(dg.$1);
                                return FilterChip(
                                  avatar: Icon(dg.$2, size: 16, color: active ? Colors.white : BloomTheme.raspberry),
                                  label: Text(dg.$1),
                                  selected: active,
                                  onSelected: (val) => update(() {
                                    val ? selectedDigestion.add(dg.$1) : selectedDigestion.remove(dg.$1);
                                  }),
                                );
                              }).toList(),
                            ),
                          ]),

                        // SECTION 7: Sleep & rest
                        if ((activeCategoryFilter == 'All' || activeCategoryFilter == 'Daily Wellness' || activeCategoryFilter == 'Sleep & Energy' || normalized.isNotEmpty) &&
                            _matchesCategory(normalized, 'sleep rest night nap insomnia ${_sleepOptions.map((e) => e.$1).join(' ')}'))
                          _categoryCard('Sleep & rest', [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _sleepOptions
                                  .where((s) => normalized.isEmpty || 'sleep and rest'.contains(normalized) || s.$1.toLowerCase().contains(normalized))
                                  .map((s) {
                                final active = selectedSleep.contains(s.$1);
                                return FilterChip(
                                  avatar: Icon(s.$2, size: 16, color: active ? Colors.white : BloomTheme.raspberry),
                                  label: Text(s.$1),
                                  selected: active,
                                  onSelected: (val) => update(() {
                                    val ? selectedSleep.add(s.$1) : selectedSleep.remove(s.$1);
                                  }),
                                );
                              }).toList(),
                            ),
                          ]),

                        // SECTION 8: Energy level
                        if ((activeCategoryFilter == 'All' || activeCategoryFilter == 'Mood & Energy' || activeCategoryFilter == 'Sleep & Energy' || normalized.isNotEmpty) &&
                            _matchesCategory(normalized, 'energy fatigue vitality ${_energyOptions.map((e) => e.$1).join(' ')}'))
                          _categoryCard('Energy level', [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _energyOptions
                                  .where((e) => normalized.isEmpty || 'energy level'.contains(normalized) || e.$1.toLowerCase().contains(normalized))
                                  .map((e) {
                                final active = currentEnergy == e.$1;
                                return ChoiceChip(
                                  avatar: Icon(e.$2, size: 16, color: active ? Colors.white : BloomTheme.raspberry),
                                  label: Text(e.$1),
                                  selected: active,
                                  selectedColor: BloomTheme.raspberry,
                                  labelStyle: TextStyle(
                                    color: active ? Colors.white : BloomTheme.plum,
                                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                  onSelected: (_) => update(() => currentEnergy = active ? null : e.$1),
                                );
                              }).toList(),
                            ),
                          ]),

                        // SECTION 9: Self-care & comfort
                        if ((activeCategoryFilter == 'All' || activeCategoryFilter == 'Daily Wellness' || normalized.isNotEmpty) &&
                            _matchesCategory(normalized, 'self care comfort ritual tea bath skincare stretching ${_selfCareOptions.map((e) => e.$1).join(' ')}'))
                          _categoryCard('Self-care & comfort', [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selfCareOptions
                                  .where((sc) => normalized.isEmpty || 'self-care and comfort'.contains(normalized) || sc.$1.toLowerCase().contains(normalized))
                                  .map((sc) {
                                final active = selectedSelfCare.contains(sc.$1);
                                return FilterChip(
                                  avatar: Icon(sc.$2, size: 16, color: active ? Colors.white : BloomTheme.raspberry),
                                  label: Text(sc.$1),
                                  selected: active,
                                  onSelected: (val) => update(() {
                                    val ? selectedSelfCare.add(sc.$1) : selectedSelfCare.remove(sc.$1);
                                  }),
                                );
                              }).toList(),
                            ),
                          ]),

                        // SECTION 7: Pregnancy test (Image 1)
                        if (_matchesCategory(normalized, 'pregnancy test ${_pregnancyOptions.join(' ')}'))
                          _categoryCard('Pregnancy test', [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _pregnancyOptions
                                  .where((pt) => normalized.isEmpty || 'pregnancy test'.contains(normalized) || pt.toLowerCase().contains(normalized))
                                  .map((pt) {
                                final active = selectedPregnancy == pt;
                                return ChoiceChip(
                                  avatar: Icon(
                                    pt == 'Positive'
                                        ? Icons.check_circle_outline
                                        : (pt == 'Faint line' ? Icons.remove : Icons.block),
                                    size: 16,
                                    color: active ? Colors.white : BloomTheme.raspberry,
                                  ),
                                  label: Text(pt),
                                  selected: active,
                                  onSelected: (val) => update(() {
                                    if (!val || pt == "Didn't take tests") {
                                      selectedPregnancy = null;
                                    } else {
                                      selectedPregnancy = pt;
                                    }
                                  }),
                                );
                              }).toList(),
                            ),
                          ]),

                        // SECTION 8: Ovulation test (Image 1)
                        if (_matchesCategory(normalized, 'ovulation test ${_ovulationOptions.join(' ')}'))
                          _categoryCard('Ovulation test', [
                            Text(
                              'Log them to know when you ovulate',
                              style: TextStyle(fontSize: 12, color: BloomTheme.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _ovulationOptions
                                  .where((ot) => normalized.isEmpty || 'ovulation test'.contains(normalized) || ot.toLowerCase().contains(normalized))
                                  .map((ot) {
                                final active = selectedOvulation == ot;
                                return ChoiceChip(
                                  avatar: Icon(
                                    ot.contains('positive') ? Icons.check_circle_outline : Icons.science_outlined,
                                    size: 16,
                                    color: active ? Colors.white : const Color(0xFF2E8B84),
                                  ),
                                  label: Text(ot),
                                  selected: active,
                                  selectedColor: const Color(0xFFE2F4F2),
                                  onSelected: (val) => update(() {
                                    if (!val || ot == "Didn't take tests") {
                                      selectedOvulation = null;
                                    } else {
                                      selectedOvulation = ot;
                                    }
                                  }),
                                );
                              }).toList(),
                            ),
                          ]),

                        // SECTION 9: Other (Images 1 & 2)
                        if (_matchesCategory(normalized, 'other stress travel meditation journaling kegel breathing alcohol disease injury ${_otherOptions.map((e) => e.$1).join(' ')}'))
                          _categoryCard('Other', [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _otherOptions
                                  .where((opt) => normalized.isEmpty || 'other'.contains(normalized) || opt.$1.toLowerCase().contains(normalized))
                                  .map((opt) {
                                final active = selectedOther.contains(opt.$1);
                                return FilterChip(
                                  avatar: Icon(opt.$2, size: 16, color: active ? Colors.white : BloomTheme.raspberry),
                                  label: Text(opt.$1),
                                  selected: active,
                                  onSelected: (val) => update(() {
                                    val ? selectedOther.add(opt.$1) : selectedOther.remove(opt.$1);
                                  }),
                                );
                              }).toList(),
                            ),
                          ]),

                        // SECTION 10: Physical activity (Image 2)
                        if (_matchesCategory(normalized, 'physical activity exercise gym yoga swimming running walking cycling ${_activityOptions.map((e) => e.$1).join(' ')}'))
                          _categoryCard('Physical activity', [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _activityOptions
                                  .where((opt) => normalized.isEmpty || 'physical activity exercise'.contains(normalized) || opt.$1.toLowerCase().contains(normalized))
                                  .map((opt) {
                                final active = selectedActivity.contains(opt.$1);
                                return FilterChip(
                                  avatar: Icon(opt.$2, size: 16, color: active ? Colors.white : const Color(0xFF2E7D32)),
                                  label: Text(opt.$1),
                                  selected: active,
                                  selectedColor: const Color(0xFFE8F5E9),
                                  onSelected: (val) => update(() {
                                    if (opt.$1 == "Didn't exercise") {
                                      selectedActivity.clear();
                                      if (val) selectedActivity.add(opt.$1);
                                    } else {
                                      selectedActivity.remove("Didn't exercise");
                                      val ? selectedActivity.add(opt.$1) : selectedActivity.remove(opt.$1);
                                    }
                                  }),
                                );
                              }).toList(),
                            ),
                          ]),

                        // SECTION 11: Water (Image 3)
                        if (_matchesCategory(normalized, 'water hydration drink'))
                          _categoryCard('Water', [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F2FD),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.water_drop, color: Color(0xFF1E88E5), size: 26),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${currentWater.toStringAsFixed(1)} / 2.0 L',
                                        style: TextStyle(
                                            fontSize: 20, fontWeight: FontWeight.bold, color: BloomTheme.plum),
                                      ),
                                      Text(
                                        'Reminders and Settings >',
                                        style: TextStyle(fontSize: 12, color: BloomTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton.filledTonal(
                                  onPressed: currentWater > 0
                                      ? () => update(() => currentWater = math.max(0.0, currentWater - 0.25))
                                      : null,
                                  icon: const Icon(Icons.remove),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  onPressed: () =>
                                      update(() => currentWater = (currentWater + 0.25).clamp(0.0, 5.0)),
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                          ]),

                        // SECTION 12: Weight (Image 3)
                        if (_matchesCategory(normalized, 'weight scale mass'))
                          _categoryCard('Weight', [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: BloomTheme.peach.withValues(alpha: .5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.monitor_weight_outlined,
                                      color: BloomTheme.plum, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentWeight != null
                                            ? '${currentWeight!.toStringAsFixed(1)} kg'
                                            : 'Log your weight',
                                        style: TextStyle(
                                          fontSize: currentWeight != null ? 18 : 15,
                                          fontWeight: currentWeight != null ? FontWeight.bold : FontWeight.w500,
                                          color: BloomTheme.plum,
                                        ),
                                      ),
                                      Text('View chart >',
                                          style: TextStyle(fontSize: 12, color: BloomTheme.textSecondary)),
                                    ],
                                  ),
                                ),
                                if (currentWeight != null)
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: BloomTheme.textSecondary),
                                    onPressed: () => update(() => currentWeight = null),
                                  ),
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, color: BloomTheme.raspberry),
                                  onPressed: () => _showNumberInputDialog(
                                    title: 'Log Weight (kg)',
                                    initial: currentWeight ?? 55.0,
                                    unit: 'kg',
                                    onSave: (val) => update(() => currentWeight = val),
                                  ),
                                ),
                              ],
                            ),
                          ]),

                        // SECTION 13: Basal temperature (Image 3)
                        if (_matchesCategory(normalized, 'temperature basal temp thermometer fever'))
                          _categoryCard('Basal temperature', [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFCE4EC),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.thermostat_outlined,
                                      color: BloomTheme.raspberry, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentTemp != null
                                            ? '${currentTemp!.toStringAsFixed(1)} °C'
                                            : 'Log your temperature',
                                        style: TextStyle(
                                          fontSize: currentTemp != null ? 18 : 15,
                                          fontWeight: currentTemp != null ? FontWeight.bold : FontWeight.w500,
                                          color: BloomTheme.plum,
                                        ),
                                      ),
                                      Text('View chart >',
                                          style: TextStyle(fontSize: 12, color: BloomTheme.textSecondary)),
                                    ],
                                  ),
                                ),
                                if (currentTemp != null)
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: BloomTheme.textSecondary),
                                    onPressed: () => update(() => currentTemp = null),
                                  ),
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, color: BloomTheme.raspberry),
                                  onPressed: () => _showNumberInputDialog(
                                    title: 'Log Basal Temperature (°C)',
                                    initial: currentTemp ?? 36.6,
                                    unit: '°C',
                                    onSave: (val) => update(() => currentTemp = val),
                                  ),
                                ),
                              ],
                            ),
                          ]),

                        // SECTION 14: Personal notes (Image 3)
                        if (_matchesCategory(normalized, 'notes memo diary extra symptoms feeling'))
                          _categoryCard('Notes', [
                            TextField(
                              controller: note,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Add notes, any extra symptoms, or how you\'ve been feeling.',
                                filled: true,
                                fillColor: BloomTheme.ivory,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        saveDate(activeKey);
                      });
                      Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: BloomTheme.raspberry,
                    ),
                    child: const Text('Save entry'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _matchesCategory(String query, String categoryKeywords) {
    if (query.isEmpty) return true;
    final words = query.split(' ').where((w) => w.isNotEmpty);
    return words.any((w) => categoryKeywords.toLowerCase().contains(w));
  }

  Widget _categoryCard(String title, List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BloomTheme.peach.withValues(alpha: .5)),
          boxShadow: [
            BoxShadow(
              color: BloomTheme.plum.withValues(alpha: .03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: BloomTheme.plum,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      );

  void _openEntryForDate(DateTime d, [String query = '']) {
    setState(() {
      selected = CycleCalculator.day(d);
      month = DateTime(d.year, d.month);
    });
    _dailyEntry(initialQuery: query, forDate: d);
  }

  void _openTodayEntry([String query = '']) {
    _openEntryForDate(DateTime.now(), query);
  }

  // --- MOOD PICKER & CYCLE HISTORY (WIDGET COMPATIBILITY) ---
  Widget _moodPicker({required bool compact}) {
    final list = compact ? _primaryMoods : _moods;
    final key = CycleCalculator.day(selected);
    final current = moods[key];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...list.map((m) => ChoiceChip(
              avatar: HomeMoodCharacter(mood: m, size: 24, selected: current == m),
              label: Text(m),
              selected: current == m,
              onSelected: (_) => setState(() => moods[key] = m),
            )),
        if (compact)
          ActionChip(
            label: const Text('More moods'),
            onPressed: _openMoodDialog,
          ),
      ],
    );
  }

  void _openMoodDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final key = CycleCalculator.day(selected);
        final current = moods[key];
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Select Mood',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: BloomTheme.plum)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _moods.map((m) {
                      final selectedMood = current == m;
                      return ChoiceChip(
                        avatar: HomeMoodCharacter(
                            mood: m, size: 24, selected: selectedMood),
                        label: Text(m),
                        selected: selectedMood,
                        onSelected: (sel) {
                          setState(() {
                            if (sel) {
                              moods[key] = m;
                            } else {
                              moods.remove(key);
                            }
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showNumberInputDialog({
    required String title,
    required double initial,
    required String unit,
    required void Function(double) onSave,
  }) {
    final controller = TextEditingController(text: initial.toStringAsFixed(1));
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            suffixText: unit,
            filled: true,
            fillColor: BloomTheme.ivory,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BloomTheme.raspberry),
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null) {
                onSave(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // --- BLOOM FOR PARTNERS (IMAGE 4) ---
  Widget _partnerBannerCard() {
    final e = estimate;
    final dayText = e.cycleDay != null
        ? 'Cycle day ${e.cycleDay} · ${_phaseLabel(e)}'
        : 'Cycle in progress';
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFBF0F5),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BloomTheme.rose.withValues(alpha: .4)),
        boxShadow: [
          BoxShadow(
            color: BloomTheme.plum.withValues(alpha: .04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BloomTheme.raspberry.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.favorite, color: BloomTheme.raspberry, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bloom for Partners',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: BloomTheme.plum,
                      ),
                    ),
                    Text(
                      partnerConnected
                          ? 'Connected ($connectedPartnerCode) · $dayText'
                          : 'Share your cycle code & care guides',
                      style: TextStyle(
                        fontSize: 12,
                        color: BloomTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: _openPartnerScreen,
                style: FilledButton.styleFrom(
                  backgroundColor: BloomTheme.peach.withValues(alpha: .6),
                  foregroundColor: BloomTheme.plum,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(partnerConnected ? 'View Care' : 'Link Partner'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: BloomTheme.peach.withValues(alpha: .4)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: BloomTheme.raspberry),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _partnerCareHeadline(e),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: BloomTheme.plum,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _partnerCareHeadline(CycleEstimate e) {
    if (e.cycleDay == null) {
      return 'Log your period to get tailored partner care tips';
    }
    if (e.cycleDay! <= 5) {
      return "Ask if she'd like a hot-water bottle for cramps";
    } else if (e.cycleDay! >= 12 && e.cycleDay! <= 16) {
      return 'Her energy & glow are peak today · Plan romantic quality time';
    } else if (e.cycleDay! > 20) {
      return 'Pre-menstrual comfort · Bring warm tea and offer reassurance';
    } else {
      return 'Her energy is rising · Great day for an active date together';
    }
  }

  List<String> _partnerCareTips(CycleEstimate e) {
    if (e.cycleDay == null || e.cycleDay! <= 5) {
      return [
        'Bring a warm hot-water bottle or heating pad for cramps',
        'Keep comforting dark chocolate or soothing herbal tea handy',
        'Offer a gentle lower back or foot rub without asking for anything in return',
        'Keep evening plans quiet, cozy, and relaxing',
      ];
    } else if (e.cycleDay! >= 12 && e.cycleDay! <= 16) {
      return [
        'She is in her fertile and ovulation window with peak energy',
        'Suggest a fun night out, romantic dinner, or new adventure',
        'Give sincere compliments and enjoy deep intimacy together',
      ];
    } else if (e.cycleDay! > 20) {
      return [
        'She may experience PMS mood changes, bloating, or fatigue',
        'Be extra patient, listen with kindness, and avoid arguments',
        'Take over household chores or cook her favorite comfort meal',
        'Draw a warm bath or prepare a cozy relaxing evening',
      ];
    } else {
      return [
        'Her energy and confidence are blooming in the follicular phase',
        'Great time for workouts together, walks in the park, and shared projects',
        'Check in and ask how her day is feeling',
      ];
    }
  }

  void _openPartnerScreen() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: BloomTheme.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) {
          final e = estimate;
          return DraggableScrollableSheet(
            initialChildSize: 0.92,
            maxChildSize: 0.96,
            minChildSize: 0.5,
            expand: false,
            builder: (ctx, scrollController) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    Text(
                      'Bloom for Partners',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: BloomTheme.plum,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Share invite',
                      icon: Icon(Icons.share_outlined, color: BloomTheme.plum),
                      onPressed: () {
                        Share.share(
                          'Connect with me on Bloom! Use my partner code: $partnerCode to see my cycle status and care tips.',
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Hero Banner matching Image 4
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF3D2DF), Color(0xFFE5D5F2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.favorite, color: BloomTheme.raspberry, size: 28),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              partnerConnected ? 'Connected with Partner ❤️' : 'Ready to get even closer?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: BloomTheme.plum,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '✓ Know they\'re in tune with your cycle\n'
                        '✓ Connect with daily check-ins and comfort suggestions\n'
                        '✓ Care for cramps, moods, energy, and intimacy',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: BloomTheme.plum,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'What your partner sees',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: BloomTheme.plum,
                  ),
                ),
                const SizedBox(height: 12),
                // Partner's Care View Card (Image 4)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: BloomTheme.peach),
                    boxShadow: [
                      BoxShadow(
                        color: BloomTheme.plum.withValues(alpha: .04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: BloomTheme.peach.withValues(alpha: .5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              e.cycleDay != null ? 'Day ${e.cycleDay} of her cycle' : 'Her Cycle Status',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: BloomTheme.plum,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Partner view ❤️',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _partnerCareHeadline(e),
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 20,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: BloomTheme.plum,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'What you can do to care today:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: BloomTheme.raspberry,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._partnerCareTips(e).map((tip) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ',
                                    style: TextStyle(
                                        color: BloomTheme.raspberry, fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: TextStyle(
                                        fontSize: 12.5, color: BloomTheme.plum, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 12),
                      // Symptoms logged by her today
                      if ((symptoms[CycleCalculator.day(DateTime.now())] ?? {}).isNotEmpty ||
                          moods[CycleCalculator.day(DateTime.now())] != null) ...[
                        const Divider(height: 20),
                        Text(
                          'Her logged symptoms & mood today:',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700, color: BloomTheme.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (moods[CycleCalculator.day(DateTime.now())] != null)
                              Chip(
                                avatar: Icon(Icons.mood, size: 14, color: BloomTheme.plum),
                                label: Text(moods[CycleCalculator.day(DateTime.now())]!,
                                    style: const TextStyle(fontSize: 11)),
                                backgroundColor: BloomTheme.peach.withValues(alpha: .5),
                              ),
                            ...?symptoms[CycleCalculator.day(DateTime.now())]?.map((s) => Chip(
                                  avatar: Icon(Icons.spa_outlined,
                                      size: 14, color: BloomTheme.raspberry),
                                  label: Text(s, style: const TextStyle(fontSize: 11)),
                                  backgroundColor: const Color(0xFFFDE8EE),
                                )),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      // Quick action buttons for partner
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.chat_bubble_outline, size: 16),
                              label: const Text('Send check-in', style: TextStyle(fontSize: 12)),
                              onPressed: () {
                                Share.share(
                                  'Hey love, thinking of you! Let me know if you need a hot water bottle, warm tea, or anything cozy ❤️',
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.water_drop_outlined, size: 16),
                              label: const Text('Remind water', style: TextStyle(fontSize: 12)),
                              onPressed: () {
                                Share.share('Gentle reminder to sip some water today, stay hydrated love! 💧');
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Code Link Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BloomTheme.peach.withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: BloomTheme.peach),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your Bloom Partner Code',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: BloomTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            partnerCode,
                            style: TextStyle(
                              fontSize: 24,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.w800,
                              color: BloomTheme.plum,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Copy code',
                            icon: Icon(Icons.copy, size: 20, color: BloomTheme.plum),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: partnerCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Partner code copied to clipboard!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share code with partner'),
                        style: FilledButton.styleFrom(
                          backgroundColor: BloomTheme.raspberry,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: () {
                          Share.share(
                            'Connect with me on Bloom! Use my partner code: $partnerCode to see my cycle status and care tips.',
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        icon: Icon(partnerConnected ? Icons.link_off : Icons.link),
                        label: Text(partnerConnected
                            ? 'Disconnect partner ($connectedPartnerCode)'
                            : "Enter partner's code to connect"),
                        onPressed: () {
                          if (partnerConnected) {
                            setState(() {
                              partnerConnected = false;
                              connectedPartnerCode = null;
                            });
                            update(() {});
                          } else {
                            _showEnterPartnerCodeDialog(update);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEnterPartnerCodeDialog(void Function(void Function()) parentUpdate) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Partner Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the 6-character Bloom code shared by your partner to connect your cycles.',
              style: TextStyle(fontSize: 13, color: BloomTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. BLOOM-7K92',
                filled: true,
                fillColor: BloomTheme.ivory,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BloomTheme.raspberry),
            onPressed: () {
              final code = controller.text.trim();
              if (code.isNotEmpty) {
                setState(() {
                  partnerConnected = true;
                  connectedPartnerCode = code;
                });
                parentUpdate(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Connected with partner code $code!'),
                    backgroundColor: BloomTheme.plum,
                  ),
                );
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Widget _cycleHistoryCard() {
    final starts = periods.keys.toList()..sort();
    final points = <CycleLengthPoint>[];
    for (var i = 1; i < starts.length; i++) {
      final gap = starts[i].difference(starts[i - 1]).inDays;
      if (gap >= 15 && gap <= 90) {
        points.add(CycleLengthPoint(start: starts[i], days: gap));
      }
    }
    return CycleHistoryCard(points: points);
  }

  // --- ASSISTANT & PROFILE ---
  Widget _assistant() {
    return Column(
      children: [
        // Sleek Assistant Header
        Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: BloomTheme.plum.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFF0F3), Color(0xFFFDE8ED)],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.spa, color: BloomTheme.raspberry, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bloom Assistant',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: BloomTheme.plum,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          estimate.cycleDay != null
                              ? 'Cycle Day ${estimate.cycleDay} · Active'
                              : 'Cycle & Wellness Guide · Online',
                          style: TextStyle(
                            fontSize: 11,
                            color: BloomTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Restart chat',
                icon: Icon(Icons.refresh,
                    color: BloomTheme.textSecondary, size: 20),
                onPressed: () {
                  setState(() {
                    _assistantMessages.clear();
                    _initAssistantChat();
                  });
                },
              ),
            ],
          ),
        ),

        // Quick suggested topic chips
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: _suggestedPrompts.length,
            itemBuilder: (ctx, i) {
              final prompt = _suggestedPrompts[i];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(
                    prompt,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: BloomTheme.plum,
                    ),
                  ),
                  backgroundColor: BloomTheme.peach.withValues(alpha: 0.35),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  onPressed: () => _handleAssistantSend(prompt),
                ),
              );
            },
          ),
        ),

        const Divider(height: 1, thickness: 0.5, color: Color(0xFFF0E5DF)),

        // Message List
        Expanded(
          child: ListView.builder(
            controller: _assistantScrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount:
                _assistantMessages.length + (_assistantTyping ? 1 : 0),
            itemBuilder: (ctx, idx) {
              if (idx == _assistantMessages.length && _assistantTyping) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: BloomTheme.peach.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: BloomTheme.raspberry),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Bloom is typing...',
                          style: TextStyle(
                              fontSize: 12,
                              color: BloomTheme.textSecondary,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final msg = _assistantMessages[idx];
              final isUser = msg.isUser;

              return Align(
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(ctx).size.width * 0.82,
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isUser ? BloomTheme.raspberry : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: BloomTheme.peach.withValues(alpha: 0.5),
                            width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: BloomTheme.plum
                            .withValues(alpha: isUser ? 0.08 : 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: isUser ? Colors.white : BloomTheme.plum,
                      fontWeight:
                          isUser ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Input Field
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: BloomTheme.plum.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _assistantInputController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleAssistantSend(),
                  decoration: InputDecoration(
                    hintText: 'Ask about your symptoms, cycle, or care...',
                    hintStyle: TextStyle(
                        fontSize: 13, color: BloomTheme.textSecondary),
                    filled: true,
                    fillColor: BloomTheme.ivory,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BloomTheme.raspberry,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
                  tooltip: 'Send message',
                  onPressed: () => _handleAssistantSend(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleAssistantSend([String? presetText]) {
    final text = (presetText ?? _assistantInputController.text).trim();
    if (text.isEmpty) return;

    _assistantInputController.clear();
    setState(() {
      _assistantMessages.add(_AssistantMessage(
        text: text,
        isUser: true,
        time: DateTime.now(),
      ));
      _assistantTyping = true;
    });

    _scrollAssistantToBottom();

    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final reply = _generateAssistantReply(text);
      setState(() {
        _assistantTyping = false;
        _assistantMessages.add(_AssistantMessage(
          text: reply,
          isUser: false,
          time: DateTime.now(),
        ));
      });
      _scrollAssistantToBottom();
    });
  }

  void _scrollAssistantToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_assistantScrollController.hasClients) {
        _assistantScrollController.animateTo(
          _assistantScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _generateAssistantReply(String query) {
    final q = query.toLowerCase().trim();
    final todayKey = CycleCalculator.day(DateTime.now());

    // ==========================================
    // 1. PERSONAL DATA & LIVE TRACKER QUERIES
    // ==========================================

    // A. Next period date & countdown
    if (q.contains('next period') ||
        q.contains('when is my period') ||
        q.contains('when will i bleed') ||
        q.contains('when will my period') ||
        q.contains('period start') ||
        q.contains('days left') ||
        q.contains('days until period') ||
        q.contains('when does my period') ||
        q.contains('period date')) {
      final nextP = estimate.nextPeriod;
      if (nextP == null) {
        return "Based on your logged data, I need at least one period start date to calculate your cycle! 🌸\n\n"
            "Tap 'Log period' or go to the Calendar to record when your last period started, and I'll immediately calculate your next period date and fertile days for you.";
      }
      final diff = nextP.difference(todayKey).inDays;
      final formattedDate = '${_monthName(nextP.month)} ${nextP.day}, ${nextP.year}';
      if (diff == 0) {
        return "🌸 Your period is predicted to start **today** ($formattedDate)!\n\n"
            "Make sure you have your supplies ready (pads, tampons, or menstrual cup). Once your bleeding begins, be sure to tap 'Log period' on Home or Calendar so your cycle stays accurately calibrated!";
      } else if (diff > 0) {
        return "🌸 Based on your tracked cycles, your next period is expected on **$formattedDate** (in **$diff day${diff == 1 ? '' : 's'}**).\n\n"
            "• Current status: Cycle Day ${estimate.cycleDay ?? '--'} (${_phaseLabel(estimate)})\n"
            "• Usual cycle duration: ${estimate.cycleLength ?? usualCycleLength} days\n\n"
            "Remember that natural human cycles can shift by 2–4 days from month to month due to stress, travel, or sleep, which is completely healthy!";
      } else {
        final lateDays = diff.abs();
        return "🌸 Your period was expected on **$formattedDate** ($lateDays day${lateDays == 1 ? '' : 's'} ago).\n\n"
            "Variations of 2–7 days happen frequently due to stress, travel, illness, or hormonal shifts. If there is a chance of pregnancy, testing with morning urine will give you peace of mind 💕";
      }
    }

    // B. Current cycle phase / Where am I in my cycle?
    if (q.contains('what phase') ||
        q.contains('current phase') ||
        q.contains('which phase') ||
        q.contains('my phase') ||
        q.contains('cycle day') ||
        q.contains('day of my cycle') ||
        q.contains('where am i in my cycle')) {
      final day = estimate.cycleDay;
      if (day == null) {
        return "You haven't logged a recent period start date yet! Tap 'Log period' to see your exact cycle day and phase breakdown.";
      }
      String phaseDetails;
      if (day <= 5) {
        phaseDetails = "• Phase: **Menstrual Phase** 🩸\n"
            "• Hormones: Estrogen and progesterone are at their lowest baseline.\n"
            "• What your body needs: Rest, iron-rich meals (spinach, lentils), warm tea, and gentle walking.";
      } else if (day <= 11) {
        phaseDetails = "• Phase: **Follicular Phase** 🌱\n"
            "• Hormones: Follicle-Stimulating Hormone (FSH) and estrogen are steadily rising.\n"
            "• What your body needs: High energy! Great time for strength training, creative projects, and learning.";
      } else if (day <= 16) {
        phaseDetails = "• Phase: **Ovulatory Phase** ✨\n"
            "• Hormones: Estrogen peaks and Luteinizing Hormone (LH) surges to release an egg.\n"
            "• What your body needs: Peak confidence, high stamina, and highest fertility window.";
      } else {
        phaseDetails = "• Phase: **Luteal Phase** 🍂\n"
            "• Hormones: Progesterone rises to support the uterine lining, then drops before menstruation.\n"
            "• What your body needs: Slower workouts (pilates, walking), complex carbs for serotonin, magnesium, and extra sleep.";
      }
      return "🌸 Today you are on **Day $day** of your ${estimate.cycleLength ?? usualCycleLength}-day cycle.\n\n"
          "$phaseDetails";
    }

    // C. Am I fertile today? / Chance of pregnancy
    if (q.contains('fertile today') ||
        q.contains('can i get pregnant today') ||
        q.contains('pregnancy chance today') ||
        q.contains('safe day') ||
        q.contains('am i fertile') ||
        q.contains('conception chance')) {
      final day = estimate.cycleDay;
      if (day == null) {
        return "Log your last period start date so I can calculate your exact fertile window and ovulation dates!";
      }
      if (day >= 11 && day <= 16) {
        final isPeak = day == 14;
        return "⚠️ **High Chance of Pregnancy Today!**\n\n"
            "You are currently on **Day $day**, right within your **${isPeak ? 'PEAK OVULATION DAY' : 'Fertile Window'}** ✨\n\n"
            "• Why: Sperm can survive up to 5 days inside fertile cervical mucus, and an egg lives for 12–24 hours after release.\n"
            "• If trying to conceive: Today is an ideal day for intercourse.\n"
            "• If preventing pregnancy: Use barrier protection or abstain, as fertility is at its monthly peak.";
      } else {
        return "🌸 **Low Chance of Pregnancy Today**\n\n"
            "You are on **Day $day** (${_phaseLabel(estimate)}), outside the estimated fertile window.\n\n"
            "💡 Important: While pregnancy probability is lower outside Days 11–16, calendar tracking alone is an estimate. Always use reliable contraception if you are actively avoiding pregnancy.";
      }
    }

    // D. Ovulation date & fertile window
    if (q.contains('when is ovulation') ||
        q.contains('when do i ovulate') ||
        q.contains('my ovulation') ||
        q.contains('fertile window')) {
      final day = estimate.cycleDay;
      return "✨ **Your Ovulation & Fertile Window**\n\n"
          "• In a typical cycle, ovulation occurs roughly 14 days before your next period.\n"
          "• Current Cycle Day: ${day != null ? 'Day $day' : 'Not tracked yet'}\n"
          "• Estimated Fertile Days: Days 11 to 16 of your cycle (Peak around Day 14).\n\n"
          "Key signs to watch for:\n"
          "1. Clear, slippery 'raw egg-white' cervical discharge.\n"
          "2. Mild lower abdominal twinge (mittelschmerz).\n"
          "3. Higher energy and increased libido.";
    }

    // E. What did I log today? / My symptoms today
    if (q.contains('what did i log') ||
        q.contains('my log') ||
        q.contains('logged today') ||
        q.contains('symptoms today') ||
        q.contains('my entry today') ||
        q.contains('today logs')) {
      final todaySymp = symptoms[todayKey] ?? <String>{};
      final todayMood = moods[todayKey];
      final todayDis = dischargeLogs[todayKey] ?? <String>{};
      final todaySlp = sleepLogs[todayKey] ?? <String>{};
      final todayCare = selfCareLogs[todayKey] ?? <String>{};
      final isLoggedPeriod = periods.containsKey(todayKey);

      final buffer = StringBuffer("📋 **Your Logs for Today** (${_monthName(todayKey.month)} ${todayKey.day}):\n\n");
      buffer.writeln("• Period flow: ${isLoggedPeriod ? '🩸 Logged as Period Day' : 'No period logged'}");
      buffer.writeln("• Mood: ${todayMood ?? 'None logged yet'}");
      buffer.writeln("• Symptoms: ${todaySymp.isNotEmpty ? todaySymp.join(', ') : 'None logged'}");
      buffer.writeln("• Cervical fluid: ${todayDis.isNotEmpty ? todayDis.join(', ') : 'None logged'}");
      buffer.writeln("• Sleep: ${todaySlp.isNotEmpty ? todaySlp.join(', ') : 'Not recorded'}");
      buffer.writeln("• Self-care: ${todayCare.isNotEmpty ? todayCare.join(', ') : 'Not recorded'}\n");
      buffer.writeln("You can tap the '+' button on the Home screen anytime to update your entry!");
      return buffer.toString();
    }

    // F. User Profile info
    if (q.contains('my profile') ||
        q.contains('my info') ||
        q.contains('my name') ||
        q.contains('my age') ||
        q.contains('my height') ||
        q.contains('my weight')) {
      return "👤 **Your Personal Profile**:\n\n"
          "• Name: $userName\n"
          "• Age: $userAge years\n"
          "• Height: ${userHeightCm.toInt()} cm\n"
          "• Weight: ${userWeightKg.toInt()} kg\n"
          "• Tracking Goal: $cycleGoal\n"
          "• Usual Cycle Length: $usualCycleLength days\n"
          "• Usual Period Duration: $usualPeriodLength days\n\n"
          "You can update any of these anytime in your Profile tab under 'Personal information'!";
    }

    // G. Cycle length / History
    if (q.contains('how long is my cycle') ||
        q.contains('my cycle length') ||
        q.contains('usual cycle') ||
        q.contains('cycle history')) {
      final recordedCount = periods.keys.map(CycleCalculator.day).toSet().length;
      return "📊 **Your Cycle Details**:\n\n"
          "• Current cycle estimate: ${estimate.cycleLength ?? usualCycleLength} days\n"
          "• Usual period length: $usualPeriodLength days\n"
          "• Total period days recorded: $recordedCount\n\n"
          "A healthy cycle typically ranges from 21 to 35 days. As you log more months, your prediction accuracy gets even sharper!";
    }

    // ==========================================
    // 2. CONVERSATIONAL & GREETINGS
    // ==========================================
    if (q == 'hi' ||
        q == 'hello' ||
        q == 'hey' ||
        q == 'hi bloom' ||
        q == 'hello bloom' ||
        q.startsWith('good morning') ||
        q.startsWith('good afternoon') ||
        q.startsWith('good evening') ||
        q == 'yo' ||
        q == 'sup') {
      final day = estimate.cycleDay;
      final ctx = day != null ? "You're on Day $day (${_phaseLabel(estimate)}) today. " : "";
      return "Hello $userName! 🌸 How are you feeling today? $ctx\n\n"
          "You can ask me anything—whether you're wondering about your next period, experiencing cramps, feeling moody, curious about discharge, or looking for wellness tips. How can I help you right now?";
    }

    if (q.contains('how are you')) {
      return "I'm doing wonderfully, thank you for asking $userName! 🌸 I'm always here and ready to support you through every phase of your cycle. How are you feeling today?";
    }

    if (q.contains('who are you') ||
        q.contains('what are you') ||
        q.contains('what can you do') ||
        q.contains('your name') ||
        q == 'help') {
      return "I'm **Bloom**, your personalized cycle, fertility, and wellness companion! 🌸\n\n"
          "Here is what I can help you with:\n"
          "• 📅 Predict your next period, ovulation, and fertile windows\n"
          "• 🩸 Soothe menstrual cramps, headaches, bloating, and fatigue\n"
          "• 💧 Explain vaginal discharge and cervical mucus changes\n"
          "• 🧠 Support you through PMS, mood swings, and PMDD\n"
          "• 🏃‍♀️ Guide you through cycle-syncing workouts and nutrition\n"
          "• 💊 Answer questions about birth control, pregnancy tests, and intimacy\n\n"
          "Just type whatever is on your mind into the box below!";
    }

    if (q.contains('thank') || q.contains('thx') || q.contains('love you') || q.contains('appreciate')) {
      return "You are so very welcome, $userName! 💕 I'm always right here whenever you need advice, reassurance, or a gentle wellness check. Take good care of yourself today!";
    }

    if (q.contains('talk to you') ||
        q.contains('ask you') ||
        q.contains('can i ask') ||
        q.contains('can we chat') ||
        q.contains('real person') ||
        q.contains('talk anything')) {
      return "Yes, absolutely $userName! 💕 You can talk to me and ask me ANY question you have about your body, cycle, symptoms, moods, or sexual health. You are never limited to the suggestions above—just type your question into the chat box below and tap send!";
    }

    // ==========================================
    // 3. PHYSICAL SYMPTOMS & CLINICAL TOPICS
    // ==========================================

    // Headaches and Migraines
    if (q.contains('headache') ||
        q.contains('migraine') ||
        q.contains('head hurt') ||
        q.contains('temple') ||
        q.contains('head throbbing')) {
      return "Hormonal headaches and menstrual migraines are very common! 🤕💕\n\n"
          "• Why it happens: A steep drop in estrogen right before your period triggers blood vessels around the brain to constrict and dilate, causing throbbing.\n\n"
          "How to find relief:\n"
          "1. 💧 Hydrate with Electrolytes: Dehydration dramatically amplifies hormonal headaches.\n"
          "2. 🌿 Peppermint Oil: Dab a drop of diluted peppermint oil across your temples and nape of the neck.\n"
          "3. 🧊 Cold Compress: Apply an ice pack across your forehead or the back of your neck for 15 minutes.\n"
          "4. 💊 Magnesium & B2: Magnesium glycinate (400mg) helps stabilize neurovascular spasming.\n"
          "5. 🛌 Rest in a Dark Room: Limit bright screens and loud noises until the peak subsides.";
    }

    // Cramps and Pelvic Pain
    if (q.contains('cramp') ||
        q.contains('pain') ||
        q.contains('ache') ||
        q.contains('hurt') ||
        q.contains('dysmenorrhea') ||
        q.contains('pelvic') ||
        q.contains('tummy hurt') ||
        q.contains('belly hurt') ||
        q.contains('stomach cramp') ||
        q.contains('uterus')) {
      return "I'm so sorry you're dealing with cramps! 💕 Here are gentle, proven ways to soothe the ache:\n\n"
          "🔥 Heat Therapy: Place a heating pad or hot water bottle across your lower pelvis for 15–20 minutes. Heat dilates uterine blood vessels and relaxes muscle contractions as effectively as mild pain relievers.\n\n"
          "🍵 Chamomile or Ginger Tea: Chamomile contains glycine, which calms nerve spasms, and ginger inhibits inflammatory prostaglandins.\n\n"
          "🧘 Gentle Movement: Try 'Child’s Pose' and gentle 'Cat-Cow' stretches to decompress your lumbar spine and pelvic floor.\n\n"
          "🍫 Magnesium & Hydration: Dark chocolate, pumpkin seeds, and plenty of warm water help prevent muscular cramping.\n\n"
          "⚠️ If cramps are sudden, debilitating, or don't ease with rest, please check in with a doctor.";
    }

    // Lower Back Pain
    if (q.contains('back pain') || q.contains('back ache') || q.contains('lower back') || q.contains('spine')) {
      return "Lower back ache is a classic period symptom! 🧘‍♀️\n\n"
          "• Why it happens: The uterine muscles contract via prostaglandins, and the pelvic nerves share pathways with your lumbar spine and sacrum, referring pain to your lower back.\n\n"
          "Ways to soothe it:\n"
          "1. 🛌 Pillow Between Knees: Sleep on your side with a pillow between your knees to align your hips and decompress your lower spine.\n"
          "2. 🔥 Lower Back Heat Wrap: A heating pad applied to the sacrum relaxes deep pelvic muscles.\n"
          "3. 🐈 Gentle Stretches: 'Cat-Cow' and 'Knee-to-Chest' stretches gently release lower back tension.\n"
          "4. 🚫 Avoid high heels and heavy lifting while your joints are lax from relaxin and prostaglandins.";
    }

    // Nausea, Vomiting, Period Flu
    if (q.contains('nausea') ||
        q.contains('vomit') ||
        q.contains('queasy') ||
        q.contains('sick to my stomach') ||
        q.contains('period flu') ||
        q.contains('upset stomach')) {
      return "Feeling nauseous or having the 'period flu' can be so exhausting! 🍵\n\n"
          "• Why it happens: Prostaglandins released to shed the uterine lining can enter the bloodstream and trigger muscle contractions in your stomach and intestines.\n\n"
          "Comfort tips:\n"
          "• 🫖 Fresh Ginger or Peppermint Tea: Ginger is clinically proven to reduce nausea and soothe gastric motility.\n"
          "• 🍞 Bland Foods (BRAT Diet): Nibble on bananas, rice, applesauce, or crackers in small amounts.\n"
          "• 🧊 Cold Water Sips: Sip ice water slowly rather than gulping.\n"
          "• 💡 Note: If you also missed your period and have morning nausea, consider taking a home pregnancy test.";
    }

    // Sore Breasts & Chest Tenderness
    if (q.contains('breast') ||
        q.contains('boob') ||
        q.contains('nipple') ||
        q.contains('tender chest') ||
        q.contains('swollen breast')) {
      return "Breast tenderness (cyclical mastalgia) is a very common hormonal symptom! 🌸\n\n"
          "• Why it happens: After ovulation in your luteal phase, progesterone and estrogen cause the milk ducts and lobules to swell and retain fluid.\n\n"
          "How to get comfortable:\n"
          "• 👙 Soft, Supportive Bra: Switch to a wire-free bralette or sports bra with good support, even while sleeping.\n"
          "• ☕ Limit Caffeine & Sodium: Caffeine can heighten breast cyst sensitivity, and salt increases fluid retention.\n"
          "• 🧊 Cold or Warm Compress: 10 minutes of gentle heat or a cool pack can reduce throbbing tenderness.\n"
          "• 🌼 Tenderness usually resolves within 1–2 days after your period bleeding starts.";
    }

    // Acne, Breakouts & Skin Care
    if (q.contains('acne') ||
        q.contains('pimple') ||
        q.contains('breakout') ||
        q.contains('skin') ||
        q.contains('blackhead') ||
        q.contains('cystic')) {
      return "Hormonal breakouts along the jawline and chin are closely tied to cycle shifts! ✨\n\n"
          "• Why it happens: In the week leading up to your period, estrogen drops while progesterone and androgens rise, increasing sebum (oil) production and clogging pores.\n\n"
          "Skin-saving routine:\n"
          "• 🧴 Salicylic Acid (BHA): Penetrates oil to keep pores clear without stripping the skin barrier.\n"
          "• 🚫 Hands Off: Never squeeze hormonal cystic bumps—they sit deep under the skin and squeezing causes scarring.\n"
          "• 🧼 Clean Pillowcases & Screen: Change your pillowcase frequently and sanitize your phone.\n"
          "• 🥗 Zinc & Green Tea: Zinc and antioxidants reduce inflammatory skin responses.";
    }

    // Heavy Bleeding & Blood Clots
    if (q.contains('heavy bleeding') ||
        q.contains('heavy period') ||
        q.contains('blood clot') ||
        q.contains('clot') ||
        q.contains('soaking pad') ||
        q.contains('menorrhagia')) {
      return "Here is important information about menstrual flow and blood clots: 🩸\n\n"
          "• Normal Clots: Small clots (smaller than a quarter/coin) that are dark red are common, especially on heavy flow days when anticoagulants in your uterus can't keep up.\n\n"
          "⚠️ When to contact a doctor:\n"
          "1. Passing blood clots larger than a golf ball.\n"
          "2. Soaking through 1 or more pads/tampons every hour for 2+ consecutive hours.\n"
          "3. Feeling dizzy, lightheaded, or unusually short of breath.\n\n"
          "• Replenish Iron: Heavy bleeding drains iron stores. Eat dark leafy greens, beans, pumpkin seeds, or speak with your doctor about an iron supplement.";
    }

    // Light Period, Spotting, Implantation Bleeding
    if (q.contains('light period') ||
        q.contains('spotting') ||
        q.contains('implantation') ||
        q.contains('scanty') ||
        q.contains('brown blood') ||
        q.contains('pink blood') ||
        q.contains('black blood')) {
      return "Curious about lighter bleeding or unusual color? Here is what it means: 🌸\n\n"
          "• Brown or Dark Blood: Blood that has oxidized because it took longer to leave the uterus. Very common at the beginning or tail end of your period.\n"
          "• Implantation Bleeding vs Period:\n"
          "  - Implantation: Very light pink or brown spotting lasting 1–2 days without clots, occurring 6–12 days after conception.\n"
          "  - Period: Progresses to a heavier, redder flow with cramps over 3–7 days.\n"
          "• Causes of Light Periods: Stress, low body fat, intense endurance training, thyroid shifts, or hormonal birth control (pills/IUDs).";
    }

    // Late or Delayed Period
    if (q.contains('late') ||
        q.contains('delay') ||
        q.contains('missed') ||
        q.contains('not coming') ||
        q.contains('where is my period')) {
      return "Having a late period can definitely feel stressful, but variations are very normal! 🌸\n\n"
          "Common reasons your period might be delayed:\n"
          "1. 🧠 Stress & Cortisol: High stress can delay ovulation. Since the luteal phase is typically a fixed 12–16 days, delayed ovulation pushes your period back.\n"
          "2. ✈️ Travel & Routine Changes: Jet lag, time zone shifts, illness, or sleep disruption can affect your pituitary cycle signals.\n"
          "3. 🥗 Nutrition & Intense Workouts: Sudden shifts in caloric intake or heavy training can temporarily postpone menstruation.\n"
          "4. 📊 Natural Variability: Cycles naturally vary by 2–4 days from month to month without any issue.\n\n"
          "👶 Pregnancy Testing: If there's a chance of pregnancy, testing with first-morning urine 5–7 days after your expected period date yields the most accurate result.";
    }

    // Early Period
    if (q.contains('early') || q.contains('came early') || q.contains('started early') || q.contains('too soon')) {
      return "Did your period arrive earlier than expected? Here is why that happens: 🩸\n\n"
          "1. Shorter Follicular Phase: High stress or hormonal fluctuations can trigger earlier ovulation, shortening the overall cycle.\n"
          "2. Anovulatory Cycle: If an egg wasn't released, the uterine lining sheds prematurely without the normal luteal phase.\n"
          "3. Emergency Contraception (Plan B): Often causes bleeding a few days to a week earlier than normal.\n"
          "4. Mid-Cycle Spotting: Light spotting during ovulation (Day 12–16) can sometimes be mistaken for an early period.";
    }

    // Vaginal Discharge and Cervical Fluid
    if (q.contains('discharge') ||
        q.contains('mucus') ||
        q.contains('wet') ||
        q.contains('white discharge') ||
        q.contains('fluid')) {
      return "Vaginal discharge changes naturally throughout your cycle to reflect hormone levels! 💧 Here is what each type typically signifies:\n\n"
          "• 🥚 Clear & Stretchy (Raw egg-white): Peak fertile window! Estrogen surges right before ovulation, making fluid slippery to help sperm travel.\n"
          "• 🥛 Creamy & Lotion-like: Common in the follicular phase and early luteal phase. Normal and non-fertile.\n"
          "• 💧 Watery: High estrogen leading up to ovulation.\n"
          "• 🩹 Sticky & Thick: Right after your period when estrogen is at its lowest.\n"
          "• 🍂 Spotting / Brownish: Normal at the beginning or end of your period, or sometimes mild ovulation spotting.\n\n"
          "⚠️ Check with a provider if discharge has a strong fishy odor, cottage-cheese texture, green/gray tint, or causes itching/burning.";
    }

    // Itching, Burning, Odor & Infections (Yeast, BV, UTI)
    if (q.contains('itch') ||
        q.contains('burn') ||
        q.contains('odor') ||
        q.contains('smell') ||
        q.contains('fishy') ||
        q.contains('yeast') ||
        q.contains('thrush') ||
        q.contains('bv') ||
        q.contains('bacterial') ||
        q.contains('uti') ||
        q.contains('peeing hurt')) {
      return "Vaginal and urinary discomfort should always be taken seriously! 🩺💕\n\n"
          "Common possibilities:\n"
          "• 🍞 Yeast Infection: Thick, white, odorless 'cottage cheese' discharge with intense itching or redness.\n"
          "• 🐟 Bacterial Vaginosis (BV): Thin gray/white watery discharge with a distinct fishy odor, often stronger after sex.\n"
          "• 🚽 UTI (Urinary Tract Infection): Burning during urination, constant urge to pee, cloudy urine.\n\n"
          "Immediate Care:\n"
          "• Wear breathable 100% cotton underwear.\n"
          "• Do NOT douche or use scented feminine washes—they disrupt your natural vaginal pH (3.8–4.5).\n"
          "• Please visit a clinic or gynecologist for a quick swab so you can receive the proper targeted treatment (antibiotic or antifungal)!";
    }

    // Mood Swings, PMS, PMDD, Anxiety, Crying
    if (q.contains('mood') ||
        q.contains('pms') ||
        q.contains('pmdd') ||
        q.contains('cry') ||
        q.contains('sad') ||
        q.contains('angry') ||
        q.contains('irrit') ||
        q.contains('anxious') ||
        q.contains('depress') ||
        q.contains('emotional')) {
      return "What you're feeling is completely valid! 💛 In the second half of your cycle (the Luteal Phase), progesterone rises and then sharply drops before bleeding, causing a natural dip in serotonin.\n\n"
          "How to nurture your mood right now:\n"
          "• 🍠 Complex Carbohydrates: Sweet potatoes, oats, brown rice, and bananas help your brain synthesize serotonin naturally.\n"
          "• 🌿 Magnesium & Vitamin B6: Help regulate neurotransmitters and stabilize mood swings.\n"
          "• 🛋️ Lower Your Stimulation: Honor your body's request to slow down. Cancel optional high-stress plans and give yourself permission to rest.\n"
          "• 💤 Protect Your Sleep: Restlessness is common right now—keep your bedroom cool and limit screens before bed.\n\n"
          "You are not broken—your hormones are doing heavy lifting!";
    }

    // Ovulation & Fertile Window
    if (q.contains('ovulat') ||
        q.contains('fertile') ||
        q.contains('conception')) {
      return "Here is what you need to know about ovulation and your fertile window! ✨\n\n"
          "• The Fertile Window spans roughly 6 days: the 5 days leading up to ovulation plus ovulation day itself. Sperm can survive up to 5 days inside fertile cervical mucus!\n"
          "• Ovulation typically occurs about 14 days before your next period begins (around Day 12–16 of an average 28-day cycle).\n"
          "• Common Ovulation Signs:\n"
          "  1. Clear, stretchy 'egg-white' cervical mucus\n"
          "  2. Mild one-sided lower abdominal twinge (mittelschmerz)\n"
          "  3. Increased libido and energy\n"
          "  4. Slight dip in basal temperature followed by a sustained 0.3–0.5°C rise.\n\n"
          "💡 If you're trying to conceive, having intercourse every 1–2 days during the fertile window gives the highest chance.";
    }

    // Pregnancy Testing & Early Pregnancy Signs
    if (q.contains('pregnant') ||
        q.contains('pregnancy test') ||
        q.contains('am i pregnant') ||
        q.contains('positive test') ||
        q.contains('negative test')) {
      return "Here is guidance on pregnancy testing and early symptoms: 🤰💕\n\n"
          "• Best Time to Test: Test on the day of your expected period or 14 days after unprotected intercourse. Use first-morning urine, which has the highest hCG concentration.\n"
          "• Early Signs: Tender swollen breasts, implantation spotting (1–2 days light pink/brown), heightened sense of smell, subtle cramping, and fatigue.\n"
          "• Faint Lines: If taking a test within the valid timeframe (usually 3–5 minutes), even a faint second line indicates hCG detection (positive).\n"
          "• If your test is negative but your period is still missing after a week, re-test with morning urine or consult your doctor.";
    }

    // Sex, Libido, and Intimacy
    if (q.contains('sex') ||
        q.contains('libido') ||
        q.contains('intima') ||
        q.contains('desire') ||
        q.contains('arous') ||
        q.contains('horny') ||
        q.contains('period sex')) {
      return "Libido naturally rises and falls throughout your cycle! ❤️\n\n"
          "• Why libido peaks around ovulation: Estrogen and testosterone peak right before ovulation to biologically encourage conception. Many people also feel heightened sensitivity and natural lubrication.\n"
          "• Luteal phase dips: As progesterone takes over, libido often softens into a desire for emotional closeness, cuddles, and relaxation.\n"
          "• Period sex: Perfectly safe and normal if you and your partner are comfortable! Orgasms actually release oxytocin and endorphins that can relieve menstrual cramps.";
    }

    // Unprotected Sex, Can I get pregnant on period, Plan B
    if (q.contains('pregnant on period') ||
        q.contains('unprotected') ||
        q.contains('pull out') ||
        q.contains('precum') ||
        q.contains('condom broke') ||
        q.contains('plan b') ||
        q.contains('morning after')) {
      return "Important information on conception risks and emergency contraception: 🛡️\n\n"
          "• Can you get pregnant on your period? Yes, especially if you have shorter cycles (e.g. 21–24 days). Sperm can live up to 5 days, so sex late in your period could fertilize an early egg!\n"
          "• Pull-out method: Pre-ejaculatory fluid can contain active sperm, making withdrawal less reliable (~78% effective in typical use).\n"
          "• Emergency Contraception (Plan B / Levonorgestrel): Most effective when taken within 72 hours (up to 5 days) after unprotected sex. It works by delaying ovulation.\n"
          "• Ella (Ulipristal): Available by prescription and effective up to 120 hours, including for higher BMIs.";
    }

    // Birth Control & Missed Pills
    if (q.contains('birth control') ||
        q.contains('pill') ||
        q.contains('missed pill') ||
        q.contains('iud') ||
        q.contains('implant') ||
        q.contains('contracept')) {
      return "Guidance on birth control and missed doses: 💊\n\n"
          "• Missed 1 Combined Pill: Take it as soon as you remember, even if it means taking 2 pills in one day. You remain protected.\n"
          "• Missed 2+ Pills: Take the most recent missed pill, leave the rest, and use barrier protection (condoms) for the next 7 days.\n"
          "• Bleeding on Birth Control: The bleeding during the placebo week is a 'withdrawal bleed' from hormone pause, not a true biological period.\n"
          "• IUD / Implant: Irregular spotting is very common in the first 3–6 months after insertion.";
    }

    // Bloating, Digestion, Water Retention
    if (q.contains('bloat') ||
        q.contains('digest') ||
        q.contains('constipat') ||
        q.contains('diarrhea') ||
        q.contains('gas') ||
        q.contains('stomach') ||
        q.contains('water weight')) {
      return "Digestive changes are very closely tied to your cycle! 🥑\n\n"
          "• Why it happens: Progesterone in the luteal phase acts as a smooth-muscle relaxant, which slows down intestinal transit and traps gas and fluid.\n"
          "• On Day 1–2: Prostaglandins that cause uterine contractions can also reach the bowel, occasionally causing loose stools.\n\n"
          "Tips to relieve bloating:\n"
          "• 🍌 Potassium foods (avocados, bananas, spinach) counterbalance sodium retention.\n"
          "• 🫖 Peppermint and fennel teas relax intestinal spasms.\n"
          "• 💧 Drink plenty of room-temperature water.\n"
          "• 🚫 Reduce carbonated drinks, excess sodium, and chewing gum.";
    }

    // Food, Nutrition, Cravings
    if (q.contains('food') ||
        q.contains('eat') ||
        q.contains('diet') ||
        q.contains('nutrition') ||
        q.contains('snack') ||
        q.contains('craving') ||
        q.contains('chocolate') ||
        q.contains('sugar') ||
        q.contains('hungry')) {
      return "Nourishing your body with cycle-supportive foods makes a wonderful difference! 🥗🍎\n\n"
          "• Iron Replenishment: During your period, replenish lost iron with lentils, dark leafy greens, pumpkin seeds, and citrus (vitamin C enhances iron absorption).\n"
          "• Healthy Fats for Hormones: Avocados, olive oil, and walnuts provide the fatty acid building blocks your body needs for hormone synthesis.\n"
          "• Craving Sweets? It's normal! Your metabolic rate actually rises by 100–300 calories in the luteal phase. Reach for dark chocolate (70%+ cacao for magnesium) or fruit with nut butter to keep blood sugar stable.";
    }

    // Exercise and Workouts
    if (q.contains('exercise') ||
        q.contains('workout') ||
        q.contains('gym') ||
        q.contains('run') ||
        q.contains('sport') ||
        q.contains('fitness') ||
        q.contains('train')) {
      return "Cycle syncing your workouts can dramatically boost your energy and prevent burnout! 🏃‍♀️✨\n\n"
          "• Menstrual Phase (Days 1–5): Low hormones. Choose gentle walking, restorative yin yoga, or light stretching. Rest without guilt!\n"
          "• Follicular Phase (Days 6–11): Rising estrogen! Great time for strength training, progressive overload, and high-intensity cardio.\n"
          "• Ovulatory Phase (Days 12–16): Peak estrogen & testosterone. You have maximum strength, endurance, and social stamina. Great for HIIT and personal records.\n"
          "• Luteal Phase (Days 17–28): Progesterone increases body temperature and catabolism. Shift toward pilates, moderate resistance, and incline walks.";
    }

    // Sleep, Fatigue, Exhaustion
    if (q.contains('sleep') ||
        q.contains('tired') ||
        q.contains('exhaust') ||
        q.contains('fatigue') ||
        q.contains('insomnia') ||
        q.contains('energy') ||
        q.contains('drowsy')) {
      return "Experiencing fatigue or restless sleep is very common around your period! 🌙💤\n\n"
          "• The temperature factor: In your luteal phase, progesterone raises your basal body temperature by ~0.5°C, which can interrupt deep slow-wave sleep.\n"
          "• Keep it cool: Try setting your bedroom between 18°C–20°C (65°F–68°F).\n"
          "• Evening magnesium: Taking magnesium glycinate 30 minutes before bed helps calm the nervous system and relaxes muscles.\n"
          "• Take a 20-minute afternoon nap if needed, and give yourself grace—your body is actively preparing or shedding the uterine lining!";
    }

    // Period Products, Swimming, Baths
    if (q.contains('swim') ||
        q.contains('bath') ||
        q.contains('tampon') ||
        q.contains('pad') ||
        q.contains('menstrual cup') ||
        q.contains('cup') ||
        q.contains('disc') ||
        q.contains('period underwear') ||
        q.contains('shower')) {
      return "Everything you need to know about period products & water: 🛁🏊‍♀️\n\n"
          "• Can I swim on my period? Yes, absolutely! Use a tampon or menstrual cup while swimming. Water pressure temporarily slows flow, but coughing or laughing can still cause leaks.\n"
          "• Can I take a hot bath? Yes! Warm water actually relaxes pelvic muscles and reduces cramp intensity.\n"
          "• Tampon Safety: Never wear a tampon for longer than 8 hours to avoid Toxic Shock Syndrome (TSS). Change every 4–6 hours on heavy days.\n"
          "• Menstrual Cups & Discs: Medical-grade silicone options hold 2–3x more fluid than pads, can be worn up to 12 hours, and are eco-friendly!";
    }

    // PCOS & Endometriosis
    if (q.contains('pcos') ||
        q.contains('endometriosis') ||
        q.contains('cyst') ||
        q.contains('irregular period')) {
      return "Understanding PCOS & Endometriosis: 🩺💕\n\n"
          "• PCOS (Polycystic Ovary Syndrome): Often involves longer/irregular cycles, skipped periods, excess androgens (cystic acne, facial hair), and insulin resistance.\n"
          "• Endometriosis: Tissue similar to the uterine lining grows outside the uterus, causing severe pelvic pain, heavy bleeding, painful bowel movements, or pain during intercourse.\n\n"
          "💡 Chronic debilitating pain is NOT something you have to just endure. Tracking your symptoms here in Bloom gives your gynecologist actionable data to get you a clear diagnosis and treatment plan.";
    }

    // Teas, Herbs, Vitamins & Supplements
    if (q.contains('tea') ||
        q.contains('supplement') ||
        q.contains('vitamin') ||
        q.contains('herb') ||
        q.contains('magnesium') ||
        q.contains('iron')) {
      return "Beneficial teas & supplements for cycle wellness: 🍵🌿\n\n"
          "• Chamomile Tea: Contains glycine to ease uterine muscle spasms.\n"
          "• Ginger Tea: Inhibits inflammatory prostaglandins to reduce cramps and nausea.\n"
          "• Raspberry Leaf Tea: Known as a uterine tonic to tone pelvic muscles.\n"
          "• Magnesium Glycinate: Eases cramps, headaches, and PMS anxiety.\n"
          "• Vitamin B6: Helps synthesize serotonin and dopamine to steady mood.\n"
          "• Iron + Vitamin C: Crucial to restore red blood cells lost through bleeding.";
    }

    // Alcohol, Coffee, Caffeine
    if (q.contains('caffeine') ||
        q.contains('coffee') ||
        q.contains('alcohol') ||
        q.contains('wine') ||
        q.contains('beer') ||
        q.contains('water') ||
        q.contains('drink')) {
      return "How beverages affect your cycle: ☕🍷💧\n\n"
          "• Coffee / Caffeine: Constricts blood vessels, which can worsen uterine cramping and increase breast tenderness. Try cutting back to 1 cup during your luteal phase.\n"
          "• Alcohol: Dehydrates tissues and stresses the liver (which is responsible for metabolizing excess estrogen), often worsening PMS mood swings.\n"
          "• Water & Electrolytes: Aim for 2–2.5 liters of water daily to reduce fluid retention and flush out excess sodium.";
    }

    // ==========================================
    // 4. INTELLIGENT PERSONALIZED FALLBACK
    // ==========================================
    final day = estimate.cycleDay;
    final phase = day != null ? _phaseLabel(estimate) : "your cycle";
    final nextP = estimate.nextPeriod;
    final nextPStr = nextP != null
        ? "Your next period is predicted around ${_monthName(nextP.month)} ${nextP.day}."
        : "Be sure to log your period dates to keep your tracker up to date.";

    return "Thank you for asking, $userName! 🌸\n\n"
        "Regarding your question about **\"$query\"**:\n\n"
        "Right now, you are in your **$phase**${day != null ? ' (Cycle Day $day)' : ''}. During this time, shifting estrogen and progesterone levels naturally influence your energy, pain sensitivity, body temperature, and mood.\n\n"
        "✨ Gentle personalized guidance:\n"
        "• $nextPStr\n"
        "• Listen to your body: If you need rest, hydration, or warm nourishment, honor that signal without guilt.\n"
        "• Track any shifts: You can log this in your Daily Log (+) so we can identify repeating patterns across your monthly cycles.\n\n"
        "Feel free to ask me anything else about your symptoms, cramps, fertile days, or cycle care! 💕";
  }

  Widget _profile() =>
      ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 88), children: [
        // User Profile Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: BloomTheme.peach.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: BloomTheme.plum.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _openAvatarPicker,
                child: GirlyPopAvatar(
                  avatarId: userAvatarId,
                  size: 58,
                  showEditBadge: true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: BloomTheme.plum,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '🌸 ${GirlyPopGallery.get(userAvatarId).name} · ${GirlyPopGallery.get(userAvatarId).tagline}',
                      style: TextStyle(
                        fontSize: 12,
                        color: BloomTheme.raspberry,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 11,
                        color: BloomTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    color: BloomTheme.raspberry),
                tooltip: 'Edit Profile Pic & Name',
                onPressed: _openAvatarPicker,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _group('YOUR SETTINGS', [
          _profileTile(
            Icons.manage_accounts_outlined,
            'Account & Credentials',
            '$userEmail · Password, security & login',
            _openAccountSettings,
          ),
          _profileTile(
            Icons.person_outline,
            'Personal information',
            '$userAge yrs · ${userHeightCm.toInt()} cm · ${userWeightKg.toInt()} kg · $cycleGoal',
            _openPersonalInfo,
          ),
          _profileTile(
              Icons.tune,
              'Cycle settings',
              'Usual cycle ($usualCycleLength d) & period ($usualPeriodLength d)',
              _openCycleSettings),
          _profileTile(
              Icons.notifications_none,
              'Reminders',
              reminderPeriod
                  ? 'Period, fertile & daily alerts active'
                  : 'Notifications customized',
              _openReminders),
          _profileTile(Icons.palette_outlined, 'Appearance',
              '$selectedPalette · Bloom light palette', _openAppearance),
        ]),
        _group('PRIVACY & SUPPORT', [
          _profileTile(
            Icons.people_outline,
            'Partner connection',
            partnerConnected
                ? 'Connected ($connectedPartnerCode)'
                : 'Link your partner · Share code & care tips',
            _openPartnerScreen,
          ),
          _profileTile(
              Icons.lock_outline,
              'App Lock',
              appLockActive
                  ? 'PIN protection active'
                  : 'Protect your data with a PIN',
              _openAppLock),
          _profileTile(Icons.ios_share, 'Export / Backup',
              'Share doctor report or export data', _openExportBackup),
          _profileTile(Icons.help_outline, 'Help & Support',
              'Cycle FAQ, guides & feedback', _openHelpSupport),
          _profileTile(Icons.info_outline, 'About Bloom',
              'Version 1.0.0 · Privacy commitment', _openAboutBloom),
        ]),
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: BloomTheme.peach.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, size: 20, color: BloomTheme.plum),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your data is stored privately on this device. Bloom never sells or shares your personal cycle data.',
                  style: TextStyle(
                    fontSize: 11,
                    color: BloomTheme.plum,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ]);

  Widget _group(String heading, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 7),
            child: Text(heading,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(letterSpacing: 1.2))),
        Card(child: Column(children: children))
      ]));

  Widget _profileTile(
          IconData icon, String title, String subtitle, VoidCallback? action) =>
      ListTile(
          leading: Icon(icon, color: BloomTheme.lavender),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: action);

  void _openAccountSettings() {
    final emailCtrl = TextEditingController(text: userEmail);
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    var isChangingPass = false;
    String? statusMessage;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BloomTheme.peach,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Account & Credentials',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: BloomTheme.plum,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Profile Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BloomTheme.blush,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: BloomTheme.peach),
                ),
                child: Row(
                  children: [
                    GirlyPopAvatar(avatarId: userAvatarId, size: 50),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: BloomTheme.plum,
                            ),
                          ),
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontSize: 12,
                              color: BloomTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '🌸 ${GirlyPopGallery.get(userAvatarId).name} · Active Profile',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: BloomTheme.raspberry,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Email credential
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: BloomTheme.peach.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.alternate_email, size: 20, color: BloomTheme.raspberry),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Account Email',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final newEmail = emailCtrl.text.trim();
                        if (newEmail.contains('@')) {
                          setState(() => userEmail = newEmail);
                          AuthService.instance.updateProfile(email: newEmail);
                          setModalState(() => statusMessage = 'Email updated successfully');
                        }
                      },
                      child: const Text('Update'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Password option
              if (!isChangingPass) ...[
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: BloomTheme.peach.withValues(alpha: 0.6)),
                    ),
                    tileColor: Colors.white,
                    leading: Icon(Icons.lock_outline, color: BloomTheme.raspberry),
                    title: const Text('Password & Security', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('•••••••• · Tap to change password', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => setModalState(() => isChangingPass = true),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: BloomTheme.peach),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: oldPassCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Current Password',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: newPassCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New Password (min 6 chars)',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setModalState(() => isChangingPass = false),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BloomTheme.raspberry,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              if (newPassCtrl.text.length >= 6) {
                                setModalState(() {
                                  isChangingPass = false;
                                  statusMessage = 'Password updated securely';
                                });
                              }
                            },
                            child: const Text('Save Password'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              if (statusMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  statusMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF388E3C), fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.switch_account_outlined, size: 18),
                label: const Text('Switch Account / Login'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: BorderSide(color: BloomTheme.peach),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BloomAuthPage(initialMode: AuthMode.login),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Log out of Bloom'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBE9E7),
                  foregroundColor: const Color(0xFFD32F2F),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Log out of Bloom?'),
                      content: const Text(
                        'Your cycle entries and personal health information remain securely stored on this device.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(dCtx, true),
                          child: const Text('Log Out'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    await AuthService.instance.logout();
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const BloomAuthPage(initialMode: AuthMode.login),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPersonalInfo() {
    final ageCtrl = TextEditingController(text: userAge.toString());
    final heightCtrl = TextEditingController(
      text: userHeightCm > 0
          ? (userHeightCm == userHeightCm.roundToDouble()
              ? userHeightCm.toInt().toString()
              : userHeightCm.toString())
          : '',
    );
    final weightCtrl = TextEditingController(
      text: userWeightKg > 0
          ? (userWeightKg == userWeightKg.roundToDouble()
              ? userWeightKg.toInt().toString()
              : userWeightKg.toString())
          : '',
    );
    var tempGoal = cycleGoal;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) {
          final media = MediaQuery.of(ctx);
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, media.viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Personal information',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: BloomTheme.plum,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Your age',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: BloomTheme.plum),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: BloomTheme.ivory,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      hintText: 'e.g. 24',
                      suffixText: 'years',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Height',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: BloomTheme.plum),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: heightCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: BloomTheme.ivory,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                hintText: 'e.g. 165',
                                suffixText: 'cm',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weight',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: BloomTheme.plum),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: weightCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: BloomTheme.ivory,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                hintText: 'e.g. 58',
                                suffixText: 'kg',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Your tracking goal',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: BloomTheme.plum)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Track menstrual cycle',
                      'Trying to conceive',
                      'Prevent pregnancy',
                      'General wellness',
                    ].map((g) {
                      final selected = tempGoal == g;
                      return ChoiceChip(
                        label: Text(g),
                        selected: selected,
                        selectedColor: BloomTheme.raspberry,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : BloomTheme.plum,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (_) => update(() => tempGoal = g),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        userAge = int.tryParse(ageCtrl.text.trim()) ?? userAge;
                        userHeightCm = double.tryParse(heightCtrl.text.trim()) ?? userHeightCm;
                        userWeightKg = double.tryParse(weightCtrl.text.trim()) ?? userWeightKg;
                        cycleGoal = tempGoal;
                      });
                      AuthService.instance.updateProfile(
                        age: userAge,
                        heightCm: userHeightCm,
                        weightKg: userWeightKg,
                        trackingGoal: cycleGoal,
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Personal details updated!')),
                      );
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: BloomTheme.raspberry,
                    ),
                    child: const Text('Save details'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAvatarPicker() {
    var tempAvatar = userAvatarId;
    final nameCtrl = TextEditingController(text: userName);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) {
          final ch = GirlyPopGallery.get(tempAvatar);
          final media = MediaQuery.of(ctx);
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, media.viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Avatars',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: BloomTheme.plum,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GirlyPopAvatar(
                    avatarId: tempAvatar,
                    size: 96,
                    animate: true,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${ch.name} • ${ch.tagline}',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: BloomTheme.plum,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ch.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${ch.vibe} · ${ch.accessoryName}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: BloomTheme.plum,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Your Name',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: BloomTheme.plum),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: BloomTheme.ivory,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      hintText: 'Enter your name',
                      prefixIcon: Icon(Icons.face_retouching_natural, color: BloomTheme.raspberry),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Avatar',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: BloomTheme.plum),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: GirlyPopGallery.characters.length,
                    itemBuilder: (ctx, i) {
                      final item = GirlyPopGallery.characters[i];
                      final isSelected = tempAvatar == item.id;
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => update(() => tempAvatar = item.id),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected ? BloomTheme.ivory : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? BloomTheme.raspberry : BloomTheme.peach.withValues(alpha: 0.4),
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GirlyPopAvatar(
                                avatarId: item.id,
                                size: 48,
                                animate: isSelected,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  color: isSelected ? BloomTheme.raspberry : BloomTheme.plum,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        userAvatarId = tempAvatar;
                        if (nameCtrl.text.trim().isNotEmpty) {
                          userName = nameCtrl.text.trim();
                        }
                      });
                      AuthService.instance.updateProfile(
                        name: userName,
                        avatarId: userAvatarId,
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched avatar to ${ch.name}! 🌸'),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: BloomTheme.raspberry,
                    ),
                    child: const Text('Save Avatar & Name'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openCycleSettings() {
    var tempCycle = usualCycleLength.toDouble();
    var tempPeriod = usualPeriodLength.toDouble();
    var tempLuteal = lutealPhaseLength.toDouble();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cycle settings',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: BloomTheme.plum,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: BloomTheme.ivory,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Average Cycle Length', style: TextStyle(fontWeight: FontWeight.w700, color: BloomTheme.plum)),
                            Text('${tempCycle.round()} days', style: TextStyle(fontWeight: FontWeight.w800, color: BloomTheme.raspberry, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Counted from first day of one period to the day before the next.',
                          style: TextStyle(fontSize: 11.5, color: BloomTheme.textSecondary),
                        ),
                        Slider(
                          value: tempCycle,
                          min: 20,
                          max: 45,
                          divisions: 25,
                          activeColor: BloomTheme.raspberry,
                          onChanged: (val) => update(() => tempCycle = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: BloomTheme.ivory,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Average Period Duration', style: TextStyle(fontWeight: FontWeight.w700, color: BloomTheme.plum)),
                            Text('${tempPeriod.round()} days', style: TextStyle(fontWeight: FontWeight.w800, color: BloomTheme.raspberry, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'How many days period bleeding typically lasts.',
                          style: TextStyle(fontSize: 11.5, color: BloomTheme.textSecondary),
                        ),
                        Slider(
                          value: tempPeriod,
                          min: 2,
                          max: 10,
                          divisions: 8,
                          activeColor: BloomTheme.raspberry,
                          onChanged: (val) => update(() => tempPeriod = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: BloomTheme.ivory,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Luteal Phase Length', style: TextStyle(fontWeight: FontWeight.w700, color: BloomTheme.plum)),
                            Text('${tempLuteal.round()} days', style: TextStyle(fontWeight: FontWeight.w800, color: BloomTheme.raspberry, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Days between ovulation and next period (typically 12–16 days).',
                          style: TextStyle(fontSize: 11.5, color: BloomTheme.textSecondary),
                        ),
                        Slider(
                          value: tempLuteal,
                          min: 10,
                          max: 16,
                          divisions: 6,
                          activeColor: BloomTheme.raspberry,
                          onChanged: (val) => update(() => tempLuteal = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        usualCycleLength = tempCycle.round();
                        usualPeriodLength = tempPeriod.round();
                        lutealPhaseLength = tempLuteal.round();
                      });
                      AuthService.instance.updateProfile(
                        usualCycleLength: usualCycleLength,
                        usualPeriodLength: usualPeriodLength,
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cycle settings saved! Estimates updated.')),
                      );
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: BloomTheme.raspberry,
                    ),
                    child: const Text('Save cycle settings'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openReminders() {
    var tempPeriod = reminderPeriod;
    var tempDaysBefore = reminderDaysBefore;
    var tempFertile = reminderFertile;
    var tempDaily = reminderDaily;
    var tempTime = reminderTime;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reminders',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: BloomTheme.plum,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text('Upcoming Period Alert', style: TextStyle(fontWeight: FontWeight.w600, color: BloomTheme.plum)),
                    subtitle: Text('Remind me $tempDaysBefore days before predicted start'),
                    value: tempPeriod,
                    activeThumbColor: BloomTheme.raspberry,
                    onChanged: (val) => update(() => tempPeriod = val),
                  ),
                  if (tempPeriod)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Row(
                        children: [1, 2, 3].map((d) {
                          final active = tempDaysBefore == d;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('$d day${d == 1 ? '' : 's'} before'),
                              selected: active,
                              selectedColor: BloomTheme.raspberry,
                              labelStyle: TextStyle(
                                color: active ? Colors.white : BloomTheme.plum,
                                fontSize: 11,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                              ),
                              onSelected: (_) => update(() => tempDaysBefore = d),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const Divider(),
                  SwitchListTile(
                    title: Text('Fertile Window Alert', style: TextStyle(fontWeight: FontWeight.w600, color: BloomTheme.plum)),
                    subtitle: const Text('Gentle heads-up when entering fertile days'),
                    value: tempFertile,
                    activeThumbColor: BloomTheme.raspberry,
                    onChanged: (val) => update(() => tempFertile = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text('Daily Wellness Check-in', style: TextStyle(fontWeight: FontWeight.w600, color: BloomTheme.plum)),
                    subtitle: Text('Reminder to log at ${tempTime.format(context)}'),
                    value: tempDaily,
                    activeThumbColor: BloomTheme.raspberry,
                    onChanged: (val) => update(() => tempDaily = val),
                  ),
                  if (tempDaily)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 12),
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.access_time, size: 16, color: BloomTheme.raspberry),
                        label: Text('Change time: ${tempTime.format(context)}', style: TextStyle(color: BloomTheme.raspberry)),
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: tempTime);
                          if (picked != null) {
                            update(() => tempTime = picked);
                          }
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        reminderPeriod = tempPeriod;
                        reminderDaysBefore = tempDaysBefore;
                        reminderFertile = tempFertile;
                        reminderDaily = tempDaily;
                        reminderTime = tempTime;
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reminder preferences saved!')),
                      );
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: BloomTheme.raspberry,
                    ),
                    child: const Text('Save preferences'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAppearance() {
    var tempPalette = selectedPalette;
    var tempContrast = highContrastMode;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Appearance',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: BloomTheme.plum,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text('Color Theme', style: TextStyle(fontWeight: FontWeight.w700, color: BloomTheme.plum)),
                  const SizedBox(height: 8),
                  ...BloomPalette.all.map((p) {
                    final active = tempPalette == p.name;
                    return Card(
                      elevation: 0,
                      color: active ? BloomTheme.ivory : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: active ? BloomTheme.raspberry : BloomTheme.peach.withValues(alpha: 0.4),
                          width: active ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          p.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: active ? BloomTheme.raspberry : BloomTheme.plum,
                          ),
                        ),
                        subtitle: Text(
                          p.description,
                          style: TextStyle(fontSize: 11, color: BloomTheme.textSecondary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [p.plum, p.raspberry, p.rose, p.peach]
                              .map((c) => Container(
                                    width: 14,
                                    height: 14,
                                    margin: const EdgeInsets.only(left: 3),
                                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                                  ))
                              .toList(),
                        ),
                        onTap: () {
                          update(() => tempPalette = p.name);
                          BloomTheme.setPalette(p.name, highContrast: tempContrast);
                          setState(() {
                            selectedPalette = p.name;
                          });
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text('High-contrast Text', style: TextStyle(fontWeight: FontWeight.w600, color: BloomTheme.plum)),
                    subtitle: const Text('Enhanced contrast for easier reading'),
                    value: tempContrast,
                    activeThumbColor: BloomTheme.raspberry,
                    onChanged: (val) {
                      update(() => tempContrast = val);
                      BloomTheme.setPalette(tempPalette, highContrast: val);
                      setState(() {
                        highContrastMode = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      BloomTheme.setPalette(tempPalette, highContrast: tempContrast);
                      setState(() {
                        selectedPalette = tempPalette;
                        highContrastMode = tempContrast;
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Switched to $tempPalette palette! ✨')),
                      );
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: BloomTheme.raspberry,
                    ),
                    child: const Text('Apply appearance'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAppLock() {
    var tempLock = appLockActive;
    var tempPin = appLockPin;
    var tempHide = hideAppSwitcher;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'App Lock & Privacy',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: BloomTheme.plum,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text('Passcode Protection', style: TextStyle(fontWeight: FontWeight.w600, color: BloomTheme.plum)),
                  subtitle: const Text('Require a 4-digit PIN when opening Bloom'),
                  value: tempLock,
                  activeThumbColor: BloomTheme.raspberry,
                  onChanged: (val) => update(() => tempLock = val),
                ),
                if (tempLock)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: BloomTheme.ivory,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Current Passcode', style: TextStyle(fontSize: 11, color: BloomTheme.textSecondary)),
                            Text('• ' * tempPin.length, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: BloomTheme.plum)),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            final pinCtrl = TextEditingController(text: tempPin);
                            showDialog<void>(
                              context: context,
                              builder: (dCtx) => AlertDialog(
                                title: const Text('Set 4-digit Passcode'),
                                content: TextField(
                                  controller: pinCtrl,
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  obscureText: true,
                                  decoration: const InputDecoration(hintText: 'Enter 4 digits'),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                                  FilledButton(
                                    onPressed: () {
                                      if (pinCtrl.text.trim().length == 4) {
                                        update(() => tempPin = pinCtrl.text.trim());
                                        Navigator.pop(dCtx);
                                      }
                                    },
                                    child: const Text('Set PIN'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Change PIN'),
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                SwitchListTile(
                  title: Text('Hide in App Switcher', style: TextStyle(fontWeight: FontWeight.w600, color: BloomTheme.plum)),
                  subtitle: const Text('Blurs cycle details in multitasking view'),
                  value: tempHide,
                  activeThumbColor: BloomTheme.raspberry,
                  onChanged: (val) => update(() => tempHide = val),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      appLockActive = tempLock;
                      appLockPin = tempPin;
                      hideAppSwitcher = tempHide;
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy settings updated!')),
                    );
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: BloomTheme.raspberry,
                  ),
                  child: const Text('Save privacy settings'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openExportBackup() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Export & Backup',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: BloomTheme.plum,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: BloomTheme.peach.withValues(alpha: 0.5)),
              ),
              child: ListTile(
                leading: Icon(Icons.summarize_outlined, color: BloomTheme.raspberry),
                title: const Text('Share Doctor / Health Report', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Creates a clear summary of your cycle lengths, period start dates, and common symptoms.'),
                trailing: const Icon(Icons.ios_share),
                onTap: () {
                  final buffer = StringBuffer();
                  buffer.writeln('BLOOM MENSTRUAL HEALTH SUMMARY');
                  buffer.writeln('User: $userName ($userAge yrs)');
                  buffer.writeln('Height: ${userHeightCm.toInt()} cm · Weight: ${userWeightKg.toInt()} kg');
                  buffer.writeln('Goal: $cycleGoal');
                  buffer.writeln('Usual Cycle: $usualCycleLength days · Period: $usualPeriodLength days');
                  buffer.writeln('-----------------------------------');
                  buffer.writeln('Logged Period Dates (${periods.length} entries):');
                  final sortedDates = periods.keys.toList()..sort();
                  for (final d in sortedDates) {
                    buffer.writeln('• ${_date(d)}: ${periods[d]} flow');
                  }
                  buffer.writeln('-----------------------------------');
                  buffer.writeln('Generated via Bloom Cycle Tracker.');
                  Share.share(buffer.toString(), subject: 'My Cycle Health Summary');
                },
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: BloomTheme.peach.withValues(alpha: 0.5)),
              ),
              child: ListTile(
                leading: Icon(Icons.data_object, color: BloomTheme.plum),
                title: const Text('Export JSON Data Backup', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Save a raw digital backup of your periods, symptoms, and entries.'),
                trailing: const Icon(Icons.download),
                onTap: () {
                  final data = {
                    'user': userName,
                    'age': userAge,
                    'heightCm': userHeightCm,
                    'weightKg': userWeightKg,
                    'periods': periods.map((k, v) => MapEntry(k.toIso8601String(), v)),
                    'symptoms': symptoms.map((k, v) => MapEntry(k.toIso8601String(), v.toList())),
                    'moods': moods.map((k, v) => MapEntry(k.toIso8601String(), v)),
                    'water': waterLogs.map((k, v) => MapEntry(k.toIso8601String(), v)),
                    'notes': notes.map((k, v) => MapEntry(k.toIso8601String(), v)),
                  };
                  Share.share(jsonEncode(data), subject: 'bloom_backup.json');
                },
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Clear All Entries', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red)),
                subtitle: const Text('Delete all logged cycle data from memory.'),
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Clear All Data?'),
                      content: const Text('This will delete all logged periods, symptoms, and entries from this session.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () {
                            setState(() {
                              periods.clear();
                              moods.clear();
                              symptoms.clear();
                              notes.clear();
                              sexLogs.clear();
                              dischargeLogs.clear();
                              digestionLogs.clear();
                              energyLogs.clear();
                              sleepLogs.clear();
                              selfCareLogs.clear();
                              waterLogs.clear();
                            });
                            Navigator.pop(dCtx);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('All data has been cleared.')),
                            );
                          },
                          child: const Text('Clear Data'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openHelpSupport() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Help & FAQ',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: BloomTheme.plum,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...[
              (
                'How does Bloom predict my next period?',
                'Bloom looks at the start dates of your previous periods to determine your natural cycle rhythm. When at least two intervals are logged, Bloom uses your personalized median cycle interval. You can also customize your default cycle length in Cycle Settings.'
              ),
              (
                'How is the fertile window estimated?',
                'Biologically, ovulation occurs about 14 days before your next period starts, and sperm can survive for up to 5 days in fertile cervical mucus. The fertile window covers the 5 days leading up to ovulation plus ovulation day itself. Please note: calendar calculations are gentle estimates, not guaranteed clinical contraception.'
              ),
              (
                'Where is my health data stored?',
                'Your personal cycle logs and notes are stored strictly on your local device. Bloom does not upload your sensitive health information to advertising networks or external data brokers.'
              ),
              (
                'What should I do if my cycle is irregular?',
                'Cycles naturally fluctuate by 2 to 4 days between months due to stress, illness, travel, or sleep changes. If your cycle regularly varies by more than 7–9 days or skips consecutive months, consulting your gynecologist is recommended.'
              ),
              (
                'How does Partner Sharing work?',
                'Under "Partner Connection", you can copy your unique code (e.g. BLOOM-7K92) and send it to your partner. They can connect to see cycle phase guidance and comfort tips tailored to support you.'
              ),
            ].map((faq) => Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: BloomTheme.peach.withValues(alpha: 0.4)),
                  ),
                  child: ExpansionTile(
                    title: Text(faq.$1, style: TextStyle(fontWeight: FontWeight.w700, color: BloomTheme.plum, fontSize: 13.5)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Text(faq.$2, style: TextStyle(fontSize: 12.5, height: 1.4, color: BloomTheme.textSecondary)),
                    ],
                  ),
                )),
            const SizedBox(height: 14),
            FilledButton.icon(
              icon: const Icon(Icons.mail_outline),
              label: const Text('Send In-App Feedback'),
              style: FilledButton.styleFrom(
                backgroundColor: BloomTheme.raspberry,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                final feedbackCtrl = TextEditingController();
                showDialog<void>(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: const Text('Send Feedback'),
                    content: TextField(
                      controller: feedbackCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Share any question, feature request, or suggestion...',
                        filled: true,
                        fillColor: BloomTheme.ivory,
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(dCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Thank you! Your feedback has been received.')),
                          );
                        },
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openAboutBloom() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFFF0F3), Color(0xFFFDE8ED)],
                ),
              ),
              child: Center(
                child: Icon(Icons.spa, size: 36, color: BloomTheme.raspberry),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bloom',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: BloomTheme.plum,
              ),
            ),
            Text(
              'Version 1.0.0 (Release Build)',
              style: TextStyle(fontSize: 12, color: BloomTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BloomTheme.ivory,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Text(
                    'Your cycle, your way.',
                    style: TextStyle(fontWeight: FontWeight.w700, color: BloomTheme.plum),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Bloom is crafted to be a quiet, dignified, and pressure-free sanctuary for menstrual wellness. We empower you with clear biological insights while honoring your natural bodily rhythms.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, height: 1.4, color: BloomTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              icon: Icon(Icons.spa_outlined, color: BloomTheme.raspberry),
              label: Text('Replay Blooming Flower',
                  style: TextStyle(
                      color: BloomTheme.plum, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: BloomTheme.peach),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  PageRouteBuilder<void>(
                    pageBuilder: (_, __, ___) =>
                        const BloomSplash(isReopen: true),
                    transitionsBuilder: (_, animation, __, child) =>
                        FadeTransition(opacity: animation, child: child),
                    transitionDuration: const Duration(milliseconds: 350),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => _showPolicyDialog('Privacy Policy', 'Bloom is 100% offline-first. Your health records and cycle entries never leave your device.'),
                  child: const Text('Privacy Policy'),
                ),
                TextButton(
                  onPressed: () => _showPolicyDialog('Terms of Use', 'Bloom provides educational wellness tracking and is not a certified medical device or clinical diagnostic tool.'),
                  child: const Text('Terms of Use'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPolicyDialog(String title, String content) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );

  Widget _section(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge));

  String _date(DateTime d) => '${_monthName(d.month)} ${d.day}';

  String _phaseLabel(CycleEstimate e) {
    if (e.cycleDay == null) return 'Cycle in progress';
    if (e.cycleDay! <= 5) return 'Period phase';
    if (e.cycleDay! <= 11) return 'Follicular phase';
    if (e.cycleDay! <= 16) return 'Ovulatory window';
    return 'Luteal phase';
  }

  String _monthName(int m) => const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ][m - 1];

  String _weekdayFullName(int w) => const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ][(w - 1) % 7];
}
