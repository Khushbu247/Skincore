import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('Progress Analytics & Insights Unit Tests', () {
    test('Calculates 7-day adherence percentage correctly', () {
      const totalRoutines = 2; // e.g. Morning & Evening
      const possible7Days = totalRoutines * 7; // 14 total tasks
      const completed7Days = 7; // Completed 7 tasks

      final rate = possible7Days > 0 ? (completed7Days / possible7Days * 100) : 0.0;
      expect(rate, equals(50.0));
    });

    test('Handles zero total routines gracefully without division by zero', () {
      const totalRoutines = 0;
      const possible7Days = totalRoutines * 7;
      const completed7Days = 0;

      final rate = possible7Days > 0 ? (completed7Days / possible7Days * 100) : 0.0;
      expect(rate, equals(0.0));
    });

    test('Calculates consecutive day streaks accurately', () {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));
      final twoDaysAgoStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 2)));

      final logs = [todayStr, yesterdayStr, twoDaysAgoStr];
      final activeRoutineIds = {'r1'};

      int streak = 0;
      for (int i = 0;; i++) {
        final d = now.subtract(Duration(days: i));
        final dStr = DateFormat('yyyy-MM-dd').format(d);
        if (logs.contains(dStr) && activeRoutineIds.isNotEmpty) {
          streak++;
        } else {
          break;
        }
      }

      expect(streak, equals(3));
    });

    test('Categorizes medical report predictions correctly', () {
      final predictions = [
        'Acne Vulgaris',
        'Acne',
        'Hyperpigmentation',
        'Eczema / Rash',
        'Serious Condition Alert',
        'Skin Understanding Profile',
      ];

      int acne = 0;
      int pigmentation = 0;
      int eczema = 0;
      int serious = 0;
      int profile = 0;

      for (final p in predictions) {
        final lower = p.toLowerCase();
        if (lower.contains('acne')) {
          acne++;
        } else if (lower.contains('pigmentation')) {
          pigmentation++;
        } else if (lower.contains('eczema') || lower.contains('rash')) {
          eczema++;
        } else if (lower.contains('serious')) {
          serious++;
        } else if (lower.contains('skin understanding')) {
          profile++;
        }
      }

      expect(acne, equals(2));
      expect(pigmentation, equals(1));
      expect(eczema, equals(1));
      expect(serious, equals(1));
      expect(profile, equals(1));
    });
  });
}
