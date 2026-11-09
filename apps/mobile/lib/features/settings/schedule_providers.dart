/// Días de entreno, pausas y recordatorio local (idea 6, ADR-0013).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_failure.dart';
import '../../core/offline/offline_providers.dart';
import '../../core/reminders/reminders.dart';
import '../../data/pipos_api.dart';
import '../../l10n/app_localizations.dart';
import '../../models/notes_breaks.dart';
import '../../models/plan.dart';

/// Pausas que aún no han terminado, con respaldo en caché (las usa el
/// recordatorio sin red).
final breaksProvider = FutureProvider.autoDispose<List<TrainingBreak>>(
  (ref) => loadBreaks(
    ref.watch(scheduleApiProvider),
    ref.read(cacheStoreProvider),
    ref.read(clockProvider)(),
  ),
);

Future<List<TrainingBreak>> loadBreaks(
  ScheduleApi api,
  CacheStore cache,
  DateTime now,
) async {
  try {
    final list = await api.listBreaks(from: calendarDate(now));
    await cache.write(CacheKeys.breaks, list.toJson());
    return list.items;
  } on ApiFailure catch (f) {
    if (!f.isConnectivity && f.type != ApiFailureType.server) rethrow;
    final cached = await cache.read(CacheKeys.breaks);
    if (cached == null) rethrow;
    return TrainingBreakList.fromJson(cached.json).items;
  }
}

final reminderSettingsProvider = FutureProvider.autoDispose<ReminderSettings>(
  (ref) => ref.watch(reminderServiceProvider).load(),
);

/// Selector de rango de fechas (sustituible en tests).
typedef DateRangePicker =
    Future<DateTimeRange?> Function(
      BuildContext context,
      DateTime first,
      DateTime last,
    );

final dateRangePickerProvider = Provider<DateRangePicker>(
  (_) =>
      (context, first, last) => showDateRangePicker(
        context: context,
        firstDate: first,
        lastDate: last,
        helpText: AppLocalizations.of(context).scheduleBreakPickerHelp,
      ),
);

/// Días de entreno efectivos (ISO): los elegidos o, si no hay, los del plan
/// (`dayIndex` 0 = lunes). Sin red, los del plan en caché.
Future<List<int>> effectiveWeekdays(WidgetRef ref) async {
  try {
    final profile = await ref.read(profileApiProvider).getProfile();
    final chosen = profile?.trainingWeekdays ?? const <int>[];
    if (chosen.isNotEmpty) return chosen;
  } on ApiFailure catch (f) {
    if (!f.isConnectivity) rethrow;
  }
  final cached = await ref.read(cacheStoreProvider).read(CacheKeys.currentPlan);
  if (cached == null) return const [];
  final plan = PlanVersion.fromJson(cached.json);
  return {for (final s in plan.sessions) s.dayIndex + 1}.toList()..sort();
}

/// Reprograma los avisos con las preferencias guardadas, los días de
/// entreno y las pausas. Sin red usa lo que haya en caché; si no hay nada,
/// no toca lo ya programado.
Future<void> refreshReminders(
  WidgetRef ref,
  AppLocalizations l10n, {
  ReminderSettings? settings,
}) async {
  final service = ref.read(reminderServiceProvider);
  final s = settings ?? await service.load();
  if (!s.enabled) {
    await service.scheduler.cancelAll();
    return;
  }
  final List<int> weekdays;
  final List<TrainingBreak> breaks;
  try {
    weekdays = await effectiveWeekdays(ref);
    breaks = await loadBreaks(
      ref.read(scheduleApiProvider),
      ref.read(cacheStoreProvider),
      ref.read(clockProvider)(),
    );
  } catch (_) {
    return;
  }
  await service.reschedule(
    settings: s,
    weekdays: weekdays,
    breaks: breaks,
    title: l10n.reminderNotificationTitle,
    body: l10n.reminderNotificationBody,
  );
}
