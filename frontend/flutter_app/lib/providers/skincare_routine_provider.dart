import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/di/providers.dart';
import '../core/services/skincare_routine_service.dart';
import '../models/skincare_routine.dart';
import 'notification_provider.dart';

final skincareRoutineServiceProvider = Provider((ref) => SkincareRoutineService());

String formatRoutineDate(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

/// Manages Skincare Routine definitions
class SkincareRoutineNotifier extends Notifier<List<SkincareRoutineItem>> {
  @override
  List<SkincareRoutineItem> build() {
    final userId = ref.watch(activeUserIdProvider);
    _loadUserRoutines(userId);
    return [];
  }

  Future<void> _loadUserRoutines(String userId) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final service = ref.read(skincareRoutineServiceProvider);
    final list = await service.getRoutines(prefs, userId);
    state = list;
  }

  Future<void> refresh() async {
    final userId = ref.read(activeUserIdProvider);
    await _loadUserRoutines(userId);
  }

  Future<void> addRoutine({
    required String productName,
    required String routineType,
    required String time,
  }) async {
    final userId = ref.read(activeUserIdProvider);
    final newItem = SkincareRoutineItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      productName: productName.trim(),
      routineType: routineType,
      time: time,
      createdAt: DateTime.now(),
    );

    final updated = [...state, newItem];
    state = updated;
    await _save(updated);
  }

  Future<void> updateRoutine(SkincareRoutineItem item) async {
    final updated = state.map((r) => r.id == item.id ? item : r).toList();
    state = updated;
    await _save(updated);
  }

  Future<void> deleteRoutine(String id) async {
    final userId = ref.read(activeUserIdProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final service = ref.read(skincareRoutineServiceProvider);
    
    final updated = state.where((r) => r.id != id).toList();
    state = updated;
    
    await service.deleteRoutine(prefs, userId, id);
    ref.read(smartNotificationsProvider.notifier).syncRoutineReminders(updated);
  }

  Future<void> _save(List<SkincareRoutineItem> items) async {
    final userId = ref.read(activeUserIdProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final service = ref.read(skincareRoutineServiceProvider);
    await service.saveRoutines(prefs, userId, items);

    ref.read(smartNotificationsProvider.notifier).syncRoutineReminders(items);
  }
}

final skincareRoutineProvider =
    NotifierProvider<SkincareRoutineNotifier, List<SkincareRoutineItem>>(
  SkincareRoutineNotifier.new,
);

/// Manages Date-Stamped Completion Logs (YYYY-MM-DD)
class RoutineCompletionLogsNotifier extends Notifier<List<RoutineCompletionLog>> {
  @override
  List<RoutineCompletionLog> build() {
    final userId = ref.watch(activeUserIdProvider);
    _loadLogs(userId);
    return [];
  }

  Future<void> _loadLogs(String userId) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final service = ref.read(skincareRoutineServiceProvider);
    final logs = await service.getCompletionLogs(prefs, userId);
    state = logs;
  }

  /// Toggle completion log for a routine on a specific date (default: today)
  Future<void> toggleCompletion(String routineId, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final dateStr = formatRoutineDate(targetDate);
    final userId = ref.read(activeUserIdProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final service = ref.read(skincareRoutineServiceProvider);

    final updatedLogs = await service.toggleCompletionLog(
      prefs: prefs,
      userId: userId,
      routineId: routineId,
      dateString: dateStr,
    );

    state = updatedLogs;
  }

  /// Check if a routine is completed on a specific date (default: today)
  bool isRoutineCompleted(String routineId, {DateTime? date}) {
    final dateStr = formatRoutineDate(date ?? DateTime.now());
    return state.any((l) => l.routineId == routineId && l.dateString == dateStr);
  }

  /// Get total completed routines count for today
  int getTodayCompletedCount(List<SkincareRoutineItem> routines) {
    final todayStr = formatRoutineDate(DateTime.now());
    final activeRoutineIds = routines.map((r) => r.id).toSet();
    return state
        .where((l) => l.dateString == todayStr && activeRoutineIds.contains(l.routineId))
        .length;
  }

  /// Execute 30-day retention cleanup for history logs
  Future<int> cleanup30DaysHistory() async {
    final userId = ref.read(activeUserIdProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final service = ref.read(skincareRoutineServiceProvider);

    final deletedCount = await service.cleanupOldHistory(prefs, userId, daysRetention: 30);
    await _loadLogs(userId);
    return deletedCount;
  }
}

final routineCompletionLogsProvider =
    NotifierProvider<RoutineCompletionLogsNotifier, List<RoutineCompletionLog>>(
  RoutineCompletionLogsNotifier.new,
);
