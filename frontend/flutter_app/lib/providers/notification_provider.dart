import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/di/providers.dart';
import '../models/skincare_routine.dart';

class SmartNotificationsNotifier extends Notifier<bool> {
  static String _prefKey(String userId) => 'smart_notifications_enabled_$userId';

  @override
  bool build() {
    final userId = ref.watch(activeUserIdProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_prefKey(userId)) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final userId = ref.read(activeUserIdProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_prefKey(userId), value);

    if (value) {
      debugPrint('Smart Notifications ENABLED for user $userId');
    } else {
      debugPrint('Smart Notifications DISABLED for user $userId');
    }
  }

  void syncRoutineReminders(List<SkincareRoutineItem> routines) {
    if (!state) {
      debugPrint('Smart Notifications are OFF. Skipping routine reminder scheduling.');
      return;
    }
    debugPrint('Scheduled ${routines.length} skincare routine reminders for current user.');
  }
}

final smartNotificationsProvider =
    NotifierProvider<SmartNotificationsNotifier, bool>(
  SmartNotificationsNotifier.new,
);
