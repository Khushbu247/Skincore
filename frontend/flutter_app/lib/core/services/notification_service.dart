import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../../models/skincare_routine.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    tz.initializeTimeZones();
    
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
      } catch (e) {
        debugPrint('Could not initialize local timezone: $e');
      }
    }
    
    const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInitSettings);
    
    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  Future<void> scheduleRoutineReminders(List<SkincareRoutineItem> routines) async {
    if (kIsWeb || !_initialized) return;
    
    await cancelAll(); // Prevent duplicates

    int id = 0;
    final now = tz.TZDateTime.now(tz.local);

    for (var routine in routines) {
      // Parse time like '08:00 AM'
      final timeParts = routine.time.split(' ');
      if (timeParts.length != 2) continue;
      
      final hm = timeParts[0].split(':');
      if (hm.length != 2) continue;
      
      int hour = int.parse(hm[0]);
      int minute = int.parse(hm[1]);
      
      if (timeParts[1].toUpperCase() == 'PM' && hour != 12) hour += 12;
      if (timeParts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;
      
      tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      try {
        await _plugin.zonedSchedule(
          id: id,
          title: 'Skincare Routine',
          body: 'Time for your ${routine.productName} routine! Stay consistent for healthy skin.',
          scheduledDate: scheduledDate,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'routine_channel',
              'Routine Reminders',
              channelDescription: 'Scheduled skincare routines',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        debugPrint('Failed to schedule exact alarm: $e');
        try {
          await _plugin.zonedSchedule(
            id: id,
            title: 'Skincare Routine',
            body: 'Time for your ${routine.productName} routine! Stay consistent for healthy skin.',
            scheduledDate: scheduledDate,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'routine_channel_inexact',
                'Routine Reminders (Inexact)',
                channelDescription: 'Scheduled skincare routines',
                importance: Importance.high,
                priority: Priority.high,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        } catch (_) {}
      }
      id++;
    }

    // Schedule 6 daily motivational/hydration reminders
    final dailyNotifications = [
      {
        'id': 9001,
        'title': 'Good Morning!',
        'body': 'You are beautiful! Start your day with a smile and confidence.',
        'hour': 9,
        'minute': 0,
      },
      {
        'id': 9002,
        'title': 'Hydration Check',
        'body': 'Stay hydrated! Drinking water is key to glowing skin.',
        'hour': 11,
        'minute': 30,
      },
      {
        'id': 9003,
        'title': 'Skin Care Reminder',
        'body': 'Reminder to take care of your skin. Don\'t forget your sunscreen if you\'re stepping out!',
        'hour': 14, // 2:00 PM
        'minute': 0,
      },
      {
        'id': 9004,
        'title': 'Healthy Habits',
        'body': 'Eat healthy and be healthy. A nutritious diet reflects on your skin.',
        'hour': 16, // 4:30 PM
        'minute': 30,
      },
      {
        'id': 9005,
        'title': 'Evening Unwind',
        'body': 'Wind down and relax. A stress-free evening leads to healthy skin.',
        'hour': 19, // 7:00 PM
        'minute': 0,
      },
      {
        'id': 9006,
        'title': 'Rest well',
        'body': 'Time to rest. A good night\'s sleep is the best skincare routine.',
        'hour': 21, // 9:30 PM
        'minute': 30,
      }
    ];

    for (var note in dailyNotifications) {
      tz.TZDateTime scheduleTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, note['hour'] as int, note['minute'] as int);
      if (scheduleTime.isBefore(now)) {
        scheduleTime = scheduleTime.add(const Duration(days: 1));
      }

      try {
        await _plugin.zonedSchedule(
          id: note['id'] as int,
          title: note['title'] as String,
          body: note['body'] as String,
          scheduledDate: scheduleTime,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'motivation_channel',
              'Motivational Reminders',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {}
    }
  }
}
