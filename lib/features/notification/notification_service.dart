import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../../core/local_db.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Inisialisasi notifikasi lokal dan minta izin jika di Android 13+.
  /// Kontrak serah terima H12.
  static Future<bool> init() async {
    if (_initialized) return true;

    tzdata.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    final ok = await _notificationsPlugin.initialize(settings: initSettings);

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    bool? permissionGranted = true;
    if (androidImplementation != null) {
      permissionGranted =
          await androidImplementation.requestNotificationsPermission();
    }

    _initialized = ok ?? true;
    return permissionGranted ?? true;
  }

  /// Menampilkan notifikasi uji coba 10 detik kemudian (Brief 6.4 & 11.3).
  static Future<void> showTest() async {
    await init();
    final isEnabled = (await LocalDb.getPref('notification_enabled')) == '1';
    if (!isEnabled) return;

    final scheduledTime =
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));

    const androidDetails = AndroidNotificationDetails(
      'eclipse_test_channel',
      'Test Notifications',
      channelDescription: 'Uji coba notifikasi EclipseVerse',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _notificationsPlugin.zonedSchedule(
      id: 9999,
      title: 'Uji Notifikasi EclipseVerse',
      body:
          'Notifikasi berhasil muncul setelah 10 detik! Fandom Eclipse siap menyapamu.',
      scheduledDate: scheduledTime,
      notificationDetails: const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Menampilkan notifikasi order berhasil dibuat (Brief 6.3 & H12).
  static Future<void> showOrderConfirmed(dynamic orderId) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'eclipse_order_channel',
      'Order Notifications',
      channelDescription: 'Notifikasi pesanan merchandise EclipseVerse',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _notificationsPlugin.show(
      id: 1000 + (int.tryParse('$orderId') ?? 0),
      title: 'Pesanan Berhasil Dikonfirmasi',
      body: 'Pesanan #$orderId berhasil dibuat dan tercatat di blockchain.',
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }

  /// Jadwalkan pengingat event 24 jam dan 1 jam sebelum event (Brief 6.2 & H13).
  /// ID: event.id * 10 + 1 (24 jam), event.id * 10 + 2 (1 jam).
  static Future<bool> scheduleEventReminder(dynamic event) async {
    final granted = await init();
    if (!granted) return false;

    final now = DateTime.now().toUtc();
    final DateTime eventDate = (event.eventDate is DateTime)
        ? (event.eventDate as DateTime).toUtc()
        : DateTime.parse(event.eventDate.toString()).toUtc();

    if (eventDate.isBefore(now)) {
      return false;
    }

    final id =
        (event.id is int) ? event.id as int : int.parse(event.id.toString());
    final title = event.title.toString();

    const androidDetails = AndroidNotificationDetails(
      'eclipse_event_channel',
      'Event Reminders',
      channelDescription: 'Pengingat jadwal konser dan event Eclipse',
      importance: Importance.max,
      priority: Priority.high,
    );

    final durationUntilEvent = eventDate.difference(now);

    // 24 jam sebelum event (hanya jika waktu event masih > 24 jam lagi)
    if (durationUntilEvent.inHours >= 24) {
      final scheduled24h = tz.TZDateTime.from(
        eventDate.subtract(const Duration(hours: 24)),
        tz.local,
      );
      if (scheduled24h.isAfter(tz.TZDateTime.now(tz.local))) {
        await _notificationsPlugin.zonedSchedule(
          id: id * 10 + 1,
          title: 'Pengingat Event: Besok!',
          body: '$title akan berlangsung dalam 24 jam.',
          scheduledDate: scheduled24h,
          notificationDetails:
              const NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }

    // 1 jam sebelum event (jika waktu event masih > 1 jam lagi)
    if (durationUntilEvent.inHours >= 1) {
      final scheduled1h = tz.TZDateTime.from(
        eventDate.subtract(const Duration(hours: 1)),
        tz.local,
      );
      if (scheduled1h.isAfter(tz.TZDateTime.now(tz.local))) {
        await _notificationsPlugin.zonedSchedule(
          id: id * 10 + 2,
          title: 'Pengingat Event: Segera Dimulai!',
          body: '$title akan dimulai dalam 1 jam.',
          scheduledDate: scheduled1h,
          notificationDetails:
              const NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }

    return true;
  }

  /// Batalkan notifikasi reminder event (Brief 6.2 & H13).
  static Future<void> cancelEventReminder(int id) async {
    await init();
    await _notificationsPlugin.cancel(id: id * 10 + 1);
    await _notificationsPlugin.cancel(id: id * 10 + 2);
  }
}

