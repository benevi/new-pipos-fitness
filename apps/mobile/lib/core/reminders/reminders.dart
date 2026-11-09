/// Recordatorio LOCAL de los días de entreno (idea 6, ADR-0013). No hay push
/// del servidor: el móvil programa notificaciones locales en los días de
/// entreno, a la hora que elige el usuario, y se salta los días de pausa.
///
/// Como una notificación semanal repetida no sabe de pausas, se programan
/// avisos sueltos para los próximos [reminderHorizonDays] días y se vuelven a
/// programar al abrir la app y al cambiar días, pausas, hora o interruptor.
/// La planificación ([planReminders]) es pura y se prueba con un
/// [NotificationScheduler] inyectado.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../models/notes_breaks.dart';
import '../offline/offline_providers.dart';

/// Días que se programan por adelantado.
const reminderHorizonDays = 14;

/// Preferencias del recordatorio (solo en este dispositivo).
@immutable
class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.hour = 18,
    this.minute = 0,
  });

  final bool enabled;
  final int hour;
  final int minute;

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  ReminderSettings copyWith({bool? enabled, TimeOfDay? time}) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        hour: time?.hour ?? hour,
        minute: time?.minute ?? minute,
      );

  factory ReminderSettings.fromJson(Map<String, dynamic> j) => ReminderSettings(
    enabled: j['enabled'] == true,
    hour: (j['hour'] as num?)?.toInt() ?? 18,
    minute: (j['minute'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'hour': hour,
    'minute': minute,
  };
}

/// Momentos (hora local) en que avisar: días de entreno ([weekdays] ISO,
/// 1 = lunes) de los próximos [days] días, a la hora de [settings], sin los
/// días cubiertos por una pausa y sin los que ya han pasado.
List<DateTime> planReminders({
  required ReminderSettings settings,
  required List<int> weekdays,
  required List<TrainingBreak> breaks,
  required DateTime now,
  int days = reminderHorizonDays,
}) {
  if (!settings.enabled || weekdays.isEmpty) return const [];
  final result = <DateTime>[];
  final today = DateTime(now.year, now.month, now.day);
  for (var i = 0; i < days; i++) {
    final day = DateTime(today.year, today.month, today.day + i);
    if (!weekdays.contains(day.weekday)) continue;
    if (breaks.any((b) => b.covers(day))) continue;
    final at = DateTime(
      day.year,
      day.month,
      day.day,
      settings.hour,
      settings.minute,
    );
    if (!at.isAfter(now)) continue;
    result.add(at);
  }
  return result;
}

/// Canal de Android de cada tipo de aviso (el usuario puede silenciarlos
/// por separado en los ajustes del sistema).
enum NotificationChannel {
  reminders('training_reminders'),
  restTimer('rest_timer');

  const NotificationChannel(this.id);
  final String id;
}

/// Lo que la app necesita del sistema de notificaciones (sustituible en
/// tests).
abstract class NotificationScheduler {
  /// Pide permiso (Android 13+ / iOS). true si se puede notificar.
  Future<bool> requestPermission();

  /// true si la app ya puede notificar (sin pedir permiso).
  Future<bool> hasPermission();

  Future<void> cancelAll();

  Future<void> cancel(int id);

  /// Programa un aviso en [when] (hora local del dispositivo).
  Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    NotificationChannel channel = NotificationChannel.reminders,
  });
}

/// Implementación con flutter_local_notifications (inexacta: no requiere el
/// permiso de alarmas exactas).
class LocalNotificationScheduler implements NotificationScheduler {
  LocalNotificationScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _ready;

  Future<void> _init() => _ready ??= () async {
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(
        tz.getLocation(await FlutterTimezone.getLocalTimezone()),
      );
    } catch (_) {
      // Sin zona conocida se usa UTC; el aviso puede desplazarse.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }();

  @override
  Future<bool> requestPermission() async {
    await _init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    return true;
  }

  @override
  Future<bool> hasPermission() async {
    await _init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return (await ios.checkPermissions())?.isEnabled ?? false;
    }
    return true;
  }

  @override
  Future<void> cancelAll() async {
    await _init();
    await _plugin.cancelAll();
  }

  @override
  Future<void> cancel(int id) async {
    await _init();
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    NotificationChannel channel = NotificationChannel.reminders,
  }) async {
    await _init();
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          title,
          importance: Importance.defaultImportance,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}

final notificationSchedulerProvider = Provider<NotificationScheduler>(
  (_) => LocalNotificationScheduler(),
);

/// Clave de [CacheStore] con las preferencias del recordatorio.
const reminderSettingsKey = 'reminders/settings';

/// Lee y guarda las preferencias y reprograma los avisos.
class ReminderService {
  ReminderService({
    required this.scheduler,
    required this.cache,
    required this.clock,
  });

  final NotificationScheduler scheduler;
  final CacheStore cache;
  final DateTime Function() clock;

  Future<ReminderSettings> load() async {
    final saved = await cache.read(reminderSettingsKey);
    return saved == null
        ? const ReminderSettings()
        : ReminderSettings.fromJson(saved.json);
  }

  Future<void> save(ReminderSettings settings) =>
      cache.write(reminderSettingsKey, settings.toJson());

  /// Cancela lo programado y programa los avisos de los próximos días.
  /// Devuelve cuántos se programaron.
  Future<int> reschedule({
    required ReminderSettings settings,
    required List<int> weekdays,
    required List<TrainingBreak> breaks,
    required String title,
    required String body,
  }) async {
    await scheduler.cancelAll();
    final times = planReminders(
      settings: settings,
      weekdays: weekdays,
      breaks: breaks,
      now: clock(),
    );
    for (var i = 0; i < times.length; i++) {
      await scheduler.schedule(id: i, when: times[i], title: title, body: body);
    }
    return times.length;
  }
}

final reminderServiceProvider = Provider<ReminderService>(
  (ref) => ReminderService(
    scheduler: ref.watch(notificationSchedulerProvider),
    cache: ref.watch(cacheStoreProvider),
    clock: ref.watch(clockProvider),
  ),
);
