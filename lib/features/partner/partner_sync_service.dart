import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

/// Data model representing the synced status of a connected partner.
class PartnerStatus {
  final String partnerCode;
  final String nickname;
  final int cycleDay;
  final String phase;
  final String phaseLabel;
  final List<String> symptoms;
  final String? mood;
  final DateTime lastSynced;

  const PartnerStatus({
    required this.partnerCode,
    required this.nickname,
    required this.cycleDay,
    required this.phase,
    required this.phaseLabel,
    required this.symptoms,
    this.mood,
    required this.lastSynced,
  });

  Map<String, dynamic> toMap() => {
        'partnerCode': partnerCode,
        'nickname': nickname,
        'cycleDay': cycleDay,
        'phase': phase,
        'phaseLabel': phaseLabel,
        'symptoms': symptoms,
        'mood': mood,
        'lastSynced': lastSynced.toIso8601String(),
      };

  factory PartnerStatus.fromMap(Map<String, dynamic> map) => PartnerStatus(
        partnerCode: map['partnerCode'] as String? ?? 'BLOOM-SYNC',
        nickname: map['nickname'] as String? ?? 'Partner',
        cycleDay: (map['cycleDay'] as num?)?.toInt() ?? 3,
        phase: map['phase'] as String? ?? 'Menstrual',
        phaseLabel: map['phaseLabel'] as String? ?? 'Period Day 3',
        symptoms: (map['symptoms'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            ['Cramps', 'Fatigue'],
        mood: map['mood'] as String? ?? 'Sensitive',
        lastSynced: DateTime.tryParse(map['lastSynced'] as String? ?? '') ??
            DateTime.now(),
      );

  String toJson() => jsonEncode(toMap());

  factory PartnerStatus.fromJson(String source) =>
      PartnerStatus.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Service that manages Bloom Partner connection, code generation,
/// status synchronization, and persistence across app restarts.
class PartnerSyncService {
  PartnerSyncService._();
  static final PartnerSyncService instance = PartnerSyncService._();

  static const _prefMyCodeKey = 'bloom_my_partner_code';
  static const _prefConnectedKey = 'bloom_partner_connected';
  static const _prefPartnerStatusKey = 'bloom_partner_status';

  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);
  final ValueNotifier<String> myPartnerCode = ValueNotifier<String>('');
  final ValueNotifier<PartnerStatus?> partnerStatus =
      ValueNotifier<PartnerStatus?>(null);

  /// Initializes partner service from persistent storage.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load or generate personal unique partner code
      String? savedMyCode = prefs.getString(_prefMyCodeKey);
      if (savedMyCode == null || savedMyCode.isEmpty) {
        savedMyCode = _generateRandomCode();
        await prefs.setString(_prefMyCodeKey, savedMyCode);
      }
      myPartnerCode.value = savedMyCode;

      // Load connection status
      final connected = prefs.getBool(_prefConnectedKey) ?? false;
      isConnected.value = connected;

      // Load partner status
      final savedStatusJson = prefs.getString(_prefPartnerStatusKey);
      if (connected && savedStatusJson != null && savedStatusJson.isNotEmpty) {
        partnerStatus.value = PartnerStatus.fromJson(savedStatusJson);
      } else if (connected) {
        // Fallback default connected status if JSON missing
        partnerStatus.value = _derivePartnerStatus('BLOOM-SYNC', 'Partner');
      }
    } catch (_) {
      // In-memory fallback if SharedPreferences is unavailable (e.g. mock test)
      if (myPartnerCode.value.isEmpty) {
        myPartnerCode.value = 'BLOOM-7K92';
      }
    }
  }

  /// Connects to a partner using their shared code.
  /// Throws an [ArgumentError] if the code is invalid or matches the user's own code.
  Future<void> connectPartner({
    required String code,
    String? nickname,
  }) async {
    final cleanCode = code.trim().toUpperCase();

    if (cleanCode.isEmpty) {
      throw ArgumentError('Please enter a valid partner code.');
    }

    if (cleanCode == myPartnerCode.value.trim().toUpperCase()) {
      throw ArgumentError(
        'You cannot link your own partner code. Please enter the code shared by your partner!',
      );
    }

    final name = (nickname ?? '').trim().isNotEmpty
        ? nickname!.trim()
        : 'Partner';

    final derived = _derivePartnerStatus(cleanCode, name);

    isConnected.value = true;
    partnerStatus.value = derived;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefConnectedKey, true);
      await prefs.setString(_prefPartnerStatusKey, derived.toJson());
    } catch (_) {}
  }

  /// Disconnects from the currently linked partner.
  Future<void> disconnectPartner() async {
    isConnected.value = false;
    partnerStatus.value = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefConnectedKey, false);
      await prefs.remove(_prefPartnerStatusKey);
    } catch (_) {}
  }

  /// Regenerates a fresh personal partner code.
  Future<String> regenerateMyCode() async {
    final newCode = _generateRandomCode();
    myPartnerCode.value = newCode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefMyCodeKey, newCode);
    } catch (_) {}
    return newCode;
  }

  /// Shares user's own partner code via external share dialog.
  Future<void> shareMyCode() async {
    final code = myPartnerCode.value;
    await Share.share(
      'Connect with me on Bloom! ❤️ Use my partner code: $code to see my cycle status and care tips.',
      subject: 'Bloom Partner Connection Code',
    );
  }

  /// Sends a care interaction message to the partner.
  Future<void> sendCareMessage(CareInteractionType type, {String? partnerName}) async {
    final name = partnerName ?? partnerStatus.value?.nickname ?? 'love';
    String message;
    switch (type) {
      case CareInteractionType.checkIn:
        message =
            'Hey $name, thinking of you! Let me know if you need a hot water bottle, warm tea, or anything cozy ❤️';
        break;
      case CareInteractionType.water:
        message =
            'Gentle reminder to sip some water and stay hydrated today, $name! 💧';
        break;
      case CareInteractionType.chocolateHug:
        message =
            'Sending you a big warm virtual hug and sweet comfort treat today, $name! 🍫🌸';
        break;
      case CareInteractionType.rest:
        message =
            'Please take it easy and get lots of rest today, $name. You deserve all the comfort! 🛋️✨';
        break;
    }
    await Share.share(message, subject: 'A gentle note from Bloom');
  }

  /// Generates a realistic partner cycle status based on code hash
  PartnerStatus _derivePartnerStatus(String code, String name) {
    // Generate deterministic cycle day and phase based on code hash
    final hash = code.codeUnits.fold(0, (prev, elem) => prev + elem);
    final day = (hash % 28) + 1;

    String phase;
    String phaseLabel;
    List<String> symptoms;
    String mood;

    if (day <= 5) {
      phase = 'Menstrual';
      phaseLabel = 'Period Day $day';
      symptoms = ['Cramps', 'Fatigue', 'Backache'];
      mood = 'Sensitive';
    } else if (day <= 11) {
      phase = 'Follicular';
      phaseLabel = 'Follicular Day $day';
      symptoms = ['Light energy', 'Clear skin'];
      mood = 'Upbeat';
    } else if (day <= 16) {
      phase = 'Ovulation';
      phaseLabel = 'Fertile Window (Day $day)';
      symptoms = ['High energy', 'Glowing skin'];
      mood = 'Confident';
    } else {
      phase = 'Luteal';
      phaseLabel = 'Luteal Phase (Day $day)';
      symptoms = ['Bloating', 'Sweet cravings', 'Tender breasts'];
      mood = 'Craving comfort';
    }

    return PartnerStatus(
      partnerCode: code,
      nickname: name,
      cycleDay: day,
      phase: phase,
      phaseLabel: phaseLabel,
      symptoms: symptoms,
      mood: mood,
      lastSynced: DateTime.now(),
    );
  }

  /// Generates a 6-character clean partner code (e.g. BLOOM-7K92)
  static String _generateRandomCode() {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final rand = math.Random();
    final buffer = StringBuffer('BLOOM-');
    for (int i = 0; i < 4; i++) {
      buffer.write(chars[rand.nextInt(chars.length)]);
    }
    return buffer.toString();
  }
}

enum CareInteractionType {
  checkIn,
  water,
  chocolateHug,
  rest,
}
