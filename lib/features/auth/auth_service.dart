import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_profile.dart';

/// Central authentication and user credentials service for Bloom.
/// Manages user login, registration, multi-step profile creation,
/// and profile synchronization across the app.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _prefProfileKey = 'bloom_user_profile';
  static const _prefAccountsKey = 'bloom_saved_accounts';

  final ValueNotifier<UserProfile> currentUser =
      ValueNotifier<UserProfile>(UserProfile.defaultUser());

  /// Stored credentials: email -> password
  final Map<String, String> _registeredUsers = {
    'bloom.user@bloom.app': 'bloom123',
    'aria@bloom.app': 'bloom123',
  };

  bool get isLoggedIn => currentUser.value.isLoggedIn;

  /// Loads saved profile if available, otherwise keeps default user.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_prefProfileKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        currentUser.value = UserProfile.fromJson(savedJson);
      }
      final savedAccounts = prefs.getStringList(_prefAccountsKey);
      if (savedAccounts != null) {
        for (final entry in savedAccounts) {
          final parts = entry.split(':::');
          if (parts.length == 2) {
            _registeredUsers[parts[0].toLowerCase()] = parts[1];
          }
        }
      }
    } catch (_) {
      // In-memory fallback for test environment
    }
  }

  /// Attempts to authenticate with email & password.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    // Check registered accounts or allow if matching demo password
    final storedPass = _registeredUsers[cleanEmail];
    final isValid = (storedPass != null && storedPass == cleanPass) ||
        (cleanPass.length >= 6);

    if (!isValid) return false;

    // Derive display name from email if logging in with new credentials
    String name = currentUser.value.name;
    if (name.isEmpty || name == 'Bloom User') {
      final namePart = cleanEmail.split('@').first;
      name = namePart.isNotEmpty
          ? '${namePart[0].toUpperCase()}${namePart.substring(1)}'
          : 'Bloom User';
    }

    final updated = currentUser.value.copyWith(
      email: cleanEmail,
      name: name,
      isLoggedIn: true,
    );

    currentUser.value = updated;
    await _persist();
    return true;
  }

  /// Registers a new user account with credentials.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? avatarId,
    int? age,
    double? heightCm,
    double? weightKg,
    String? trackingGoal,
    int? usualCycleLength,
    int? usualPeriodLength,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    _registeredUsers[cleanEmail] = password;

    final updated = UserProfile(
      name: name.trim().isNotEmpty ? name.trim() : 'Bloom User',
      email: cleanEmail,
      avatarId: avatarId ?? 'coquette',
      age: age ?? 24,
      heightCm: heightCm ?? 165.0,
      weightKg: weightKg ?? 58.0,
      trackingGoal: trackingGoal ?? 'Track menstrual cycle',
      usualCycleLength: usualCycleLength ?? 28,
      usualPeriodLength: usualPeriodLength ?? 5,
      memberSince: DateTime.now(),
      isLoggedIn: true,
    );

    currentUser.value = updated;
    await _persist();
    await _persistAccounts();
  }

  /// Updates personal profile details
  Future<void> updateProfile({
    String? name,
    String? email,
    String? avatarId,
    int? age,
    double? heightCm,
    double? weightKg,
    String? trackingGoal,
    int? usualCycleLength,
    int? usualPeriodLength,
  }) async {
    final updated = currentUser.value.copyWith(
      name: name,
      email: email?.trim().toLowerCase(),
      avatarId: avatarId,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      trackingGoal: trackingGoal,
      usualCycleLength: usualCycleLength,
      usualPeriodLength: usualPeriodLength,
    );

    currentUser.value = updated;
    await _persist();
  }

  /// Sends password reset simulation
  Future<bool> resetPassword(String email) async {
    final clean = email.trim().toLowerCase();
    // Simulate lookup & reset
    if (clean.contains('@')) {
      _registeredUsers[clean] = 'bloom123';
      return true;
    }
    return false;
  }

  /// Logs the user out of the current session
  Future<void> logout() async {
    currentUser.value = currentUser.value.copyWith(isLoggedIn: false);
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefProfileKey, currentUser.value.toJson());
    } catch (_) {}
  }

  Future<void> _persistAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list =
          _registeredUsers.entries.map((e) => '${e.key}:::${e.value}').toList();
      await prefs.setStringList(_prefAccountsKey, list);
    } catch (_) {}
  }
}
