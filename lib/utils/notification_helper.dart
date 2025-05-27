import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart'; // Import for DateFormat
import '../models/policy.dart';

class NotificationHelper {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future init({bool initScheduled = false}) async {
    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iOS = DarwinInitializationSettings();
    final settings = InitializationSettings(android: android, iOS: iOS);
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Handle notification tap
      },
    );
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // Set local timezone for India
  }

  static Future showScheduledNotification({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate, // Use TZDateTime
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'policy_reminder_channel',
      'Policy Reminders',
      channelDescription: 'Channel for policy premium due date reminders',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    final iOSDetails = DarwinNotificationDetails();
    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      platformDetails,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time, // This will make it repeat daily at the scheduled time
    );
  }

  static Future cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future schedulePolicyReminder(Policy policy) async {
    if (policy.premiumDueDate.isEmpty || policy.id == null) return;

    // Cancel any existing notifications for this policy to avoid duplicates
    await cancelNotification(policy.id!);

    final premiumDate = DateTime.parse(policy.premiumDueDate);
    final now = tz.TZDateTime.now(tz.local);

    // Schedule notifications starting 15 days before the due date
    for (int i = 15; i >= 0; i--) {
      final reminderDate = premiumDate.subtract(Duration(days: i));
      
      // Only schedule if the reminder date is in the future
      if (reminderDate.isAfter(now)) {
        final scheduledTime = tz.TZDateTime(
          tz.local,
          reminderDate.year,
          reminderDate.month,
          reminderDate.day,
          9, // Schedule at 9 AM
          0,
          0,
        );

        // Ensure the scheduled time is in the future
        if (scheduledTime.isAfter(now)) {
          await showScheduledNotification(
            id: policy.id! + i, // Unique ID for each daily notification
            title: 'Premium Due Soon!',
            body: '${policy.customerName}\'s ${policy.policyType} premium is due on ${DateFormat('yyyy-MM-dd').format(premiumDate)}.',
            scheduledDate: scheduledTime,
            payload: policy.id.toString(),
          );
        }
      }
    }
  }
}
