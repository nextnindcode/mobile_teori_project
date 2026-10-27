import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../../core/local_db.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<bool> _enabled() async => (await LocalDb.getPref('notification_enabled')) != '0';

  static Future<bool> init() async {
    if (_initialized) return true;
    if (!await _enabled()) return false;
    tzdata.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    final ok = await _notificationsPlugin.initialize(settings: initSettings);
    final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    bool? permissionGranted = true;
    if (androidImplementation != null) permissionGranted = await androidImplementation.requestNotificationsPermission();
    _initialized = (ok ?? false) && (permissionGranted ?? false);
    return _initialized;
  }

  static Future<void> showOrderConfirmed(dynamic orderId) async {
    if (!await _enabled()) return;
    final ready = await init();
    if (!ready) return;
    const androidDetails = AndroidNotificationDetails('eclipse_order_channel', 'Order Notifications', channelDescription: 'Notifikasi pesanan merchandise EclipseVerse', importance: Importance.max, priority: Priority.high);
    await _notificationsPlugin.show(id: 1000 + (int.tryParse('$orderId') ?? 0), title: 'Pesanan Berhasil Dikonfirmasi', body: 'Pesanan #$orderId berhasil dibuat dan tercatat.', notificationDetails: const NotificationDetails(android: androidDetails));
  }

  static Future<bool> scheduleEventReminder(dynamic event) async {
    if (!await _enabled()) return false;
    final granted = await init();
    if (!granted) return false;
    final now = DateTime.now().toUtc();
    final eventDate = (event.eventDate is DateTime) ? (event.eventDate as DateTime).toUtc() : DateTime.parse(event.eventDate.toString()).toUtc();
    if (eventDate.isBefore(now)) return false;
    final id = event.id is int ? event.id as int : int.parse(event.id.toString());
    final title = event.title.toString();
    const androidDetails = AndroidNotificationDetails('eclipse_event_channel', 'Event Reminders', channelDescription: 'Pengingat event EclipseVerse', importance: Importance.max, priority: Priority.high);
    final durationUntilEvent = eventDate.difference(now);
    if (durationUntilEvent.inHours >= 24) {
      final scheduled = tz.TZDateTime.from(eventDate.subtract(const Duration(hours: 24)), tz.local);
      if (scheduled.isAfter(tz.TZDateTime.now(tz.local))) {
        await _notificationsPlugin.zonedSchedule(id: id * 10 + 1, title: 'Pengingat Event: Besok!', body: '$title akan berlangsung dalam 24 jam.', scheduledDate: scheduled, notificationDetails: const NotificationDetails(android: androidDetails), androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle);
      }
    }
    if (durationUntilEvent.inHours >= 1) {
      final scheduled = tz.TZDateTime.from(eventDate.subtract(const Duration(hours: 1)), tz.local);
      if (scheduled.isAfter(tz.TZDateTime.now(tz.local))) {
        await _notificationsPlugin.zonedSchedule(id: id * 10 + 2, title: 'Pengingat Event: Segera Dimulai!', body: '$title akan dimulai dalam 1 jam.', scheduledDate: scheduled, notificationDetails: const NotificationDetails(android: androidDetails), androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle);
      }
    }
    return true;
  }

  static Future<void> cancelEventReminder(int id) async {
    await init();
    await _notificationsPlugin.cancel(id: id * 10 + 1);
    await _notificationsPlugin.cancel(id: id * 10 + 2);
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
