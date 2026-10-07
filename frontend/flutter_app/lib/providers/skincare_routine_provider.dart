import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/di/providers.dart';
import '../core/services/skincare_routine_service.dart';
import '../models/skincare_routine.dart';
import 'notification_provider.dart';

final skincareRoutineServiceProvider = Provider((ref) => SkincareRoutineService());

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
      isCompleted: false,
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
    final updated = state.where((r) => r.id != id).toList();
    state = updated;
    await _save(updated);
  }

  Future<void> toggleComplete(String id) async {
    final updated = state.map((r) {
      if (r.id == id) {
        return r.copyWith(isCompleted: !r.isCompleted);
      }
      return r;
    }).toList();
    state = updated;
    await _save(updated);
  }

  Future<void> _save(List<SkincareRoutineItem> items) async {
    final userId = ref.read(activeUserIdProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final service = ref.read(skincareRoutineServiceProvider);
    await service.saveRoutines(prefs, userId, items);

    // Refresh notifications trigger check if enabled
    ref.read(smartNotificationsProvider.notifier).syncRoutineReminders(items);
  }
}

final skincareRoutineProvider =
    NotifierProvider<SkincareRoutineNotifier, List<SkincareRoutineItem>>(
  SkincareRoutineNotifier.new,
);
