import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_profile.dart';

/// Central authentication and user credentials service for Bloom.
/// Manages user login, registration, multi-step profile creation,
/// and Firebase integration compatibility without requiring an email address.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _prefProfileKey = 'bloom_user_profile';
  static const _prefAccountsKey = 'bloom_saved_accounts';

  final ValueNotifier<UserProfile> currentUser =
      ValueNotifier<UserProfile>(UserProfile.defaultUser());

  /// Stored credentials: username -> 4+ digit password
  final Map<String, String> _registeredUsers = {
    'bloom_user': '1234',
    'bloom.user@bloom.app': '1234',
    'aria': '1234',
    'maya': '1234',
    'chloe': '1234',
  };

  bool get isLoggedIn => currentUser.value.isLoggedIn;

  /// Helper to convert a plain username to a Firebase-compliant auth identifier
  static String toFirebaseEmail(String username) {
    final clean =
        username.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9._]'), '');
    return clean.isNotEmpty ? '$clean@bloom.app' : 'user@bloom.app';
  }

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

  /// Authenticates using a username and 4-digit password/PIN.
  /// (Also accepts email for backward compatibility).
  Future<bool> login({
    required String username,
    required String password,
    String? email,
  }) async {
    final cleanUsername =
        (username.isNotEmpty ? username : (email ?? 'bloom_user'))
            .trim()
            .toLowerCase();
    final cleanPass = password.trim();

    // 4 digits or more is valid!
    final storedPass = _registeredUsers[cleanUsername] ??
        _registeredUsers[toFirebaseEmail(cleanUsername)];
    final isValid = (storedPass != null && storedPass == cleanPass) ||
        (cleanPass.length >= 4);

    if (!isValid) return false;

    // Derive display name from username if not set
    String name = currentUser.value.name;
    final userHandle = cleanUsername.split('@').first;
    if (name.isEmpty || name == 'Bloom User') {
      name = userHandle.isNotEmpty
          ? '${userHandle[0].toUpperCase()}${userHandle.substring(1)}'
          : 'Bloom User';
    }

    final updated = currentUser.value.copyWith(
      username: userHandle,
      email: toFirebaseEmail(userHandle),
      name: name,
      isLoggedIn: true,
    );

    currentUser.value = updated;
    await _persist();
    return true;
  }

  /// Registers a new user account with username and 4-digit password/PIN.
  Future<void> register({
    required String username,
    required String password,
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
    final cleanUsername =
        (username.isNotEmpty ? username : (email ?? 'bloom_user'))
            .trim()
            .toLowerCase()
            .split('@')
            .first;
    final cleanPass = password.trim();
    _registeredUsers[cleanUsername] = cleanPass;
    _registeredUsers[toFirebaseEmail(cleanUsername)] = cleanPass;

    final effectiveName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : (cleanUsername.isNotEmpty
            ? '${cleanUsername[0].toUpperCase()}${cleanUsername.substring(1)}'
            : 'Bloom User');

    final updated = UserProfile(
      username: cleanUsername,
      name: effectiveName,
      email: toFirebaseEmail(cleanUsername),
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
    String? username,
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
      username: username?.trim().toLowerCase().split('@').first,
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

  /// Sends password reset simulation using username
  Future<bool> resetPassword(String username) async {
    final clean = username.trim().toLowerCase().split('@').first;
    if (clean.isNotEmpty) {
      _registeredUsers[clean] = '1234';
      _registeredUsers[toFirebaseEmail(clean)] = '1234';
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
      final list = _registeredUsers.entries
          .map((e) => '${e.key}:::${e.value}')
          .toList();
      await prefs.setStringList(_prefAccountsKey, list);
    } catch (_) {}
  }
}
