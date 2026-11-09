/// Ajustes → «Días de entreno, pausas y recordatorio» (idea 6, ADR-0013).
///
/// - Días de entreno (`PATCH /me/profile/schedule`): como mucho tantos como
///   días por semana tiene el plan; no crean una versión del plan.
/// - Pausas (`GET/POST/DELETE /me/breaks`): 1-60 días, sin motivo.
/// - Recordatorio LOCAL (sin push del servidor): hora elegida, no suena en
///   las pausas; pide el permiso de notificaciones con una explicación antes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/tokens.dart';
import '../../core/api/api_failure.dart';
import '../../core/offline/offline_providers.dart';
import '../../core/reminders/reminders.dart';
import '../../data/pipos_api.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/failure_messages.dart';
import '../../models/notes_breaks.dart';
import '../../models/profile.dart';
import '../../shared/widgets.dart';
import '../onboarding/onboarding_controller.dart';
import '../today/today_providers.dart';
import 'schedule_providers.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scheduleTitle)),
      body: ListView(
        key: const Key('schedule-list'),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          profile.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.invalidate(profileProvider),
            ),
            data: (p) =>
                p == null ? const SizedBox.shrink() : _WeekdaysCard(profile: p),
          ),
          const _BreaksCard(),
          const _ReminderCard(),
        ],
      ),
    );
  }
}

// ── Días de entreno ──

class _WeekdaysCard extends ConsumerStatefulWidget {
  const _WeekdaysCard({required this.profile});

  final ProfileResponse profile;

  @override
  ConsumerState<_WeekdaysCard> createState() => _WeekdaysCardState();
}

class _WeekdaysCardState extends ConsumerState<_WeekdaysCard> {
  late Set<int> _days = {...widget.profile.trainingWeekdays};
  bool _busy = false;
  String? _error;

  int get _max => widget.profile.daysPerWeek;

  bool get _changed =>
      _days.length != widget.profile.trainingWeekdays.length ||
      !_days.containsAll(widget.profile.trainingWeekdays);

  void _toggle(int day, bool on) => setState(() {
    on ? _days.add(day) : _days.remove(day);
    _error = null;
  });

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_days.length > _max) {
      setState(() => _error = l10n.scheduleDaysTooMany(_max));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final days = _days.toList()..sort();
      final updated = await ref.read(scheduleApiProvider).updateSchedule(days);
      if (!mounted) return;
      setState(() => _days = {...updated.trainingWeekdays});
      ref.invalidate(profileProvider);
      ref.invalidate(todaySessionProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.scheduleDaysSaved)));
      await refreshReminders(ref, l10n);
    } catch (e) {
      if (!mounted) return;
      final f = ApiFailure.from(e);
      setState(
        () => _error = f.statusCode == 422
            ? l10n.scheduleDaysTooMany(_max)
            : f.isConnectivity
            ? l10n.errorOfflineAction
            : f.localized(l10n),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tooMany = _days.length > _max;
    return SectionCard(
      title: l10n.scheduleDaysTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.scheduleDaysIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  key: Key('weekday-$d'),
                  label: Text(l10n.weekdayLabel('${d - 1}')),
                  selected: _days.contains(d),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: _busy ? null : (on) => _toggle(d, on),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            liveRegion: true,
            child: Text(
              _error ??
                  (_days.isEmpty
                      ? l10n.scheduleDaysDefault
                      : tooMany
                      ? l10n.scheduleDaysTooMany(_max)
                      : l10n.scheduleDaysCount(_days.length, _max)),
              key: const Key('weekdays-status'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: _error != null || tooMany
                    ? theme.colorScheme.error
                    : null,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            key: const Key('weekdays-save'),
            onPressed: _busy || !_changed || tooMany ? null : _save,
            child: Text(l10n.scheduleDaysSave),
          ),
        ],
      ),
    );
  }
}

// ── Pausas ──

class _BreaksCard extends ConsumerStatefulWidget {
  const _BreaksCard();

  @override
  ConsumerState<_BreaksCard> createState() => _BreaksCardState();
}

class _BreaksCardState extends ConsumerState<_BreaksCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String done) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(breaksProvider);
      ref.invalidate(todaySessionProvider);
      messenger.showSnackBar(SnackBar(content: Text(done)));
      await refreshReminders(ref, l10n);
    } catch (e) {
      final f = ApiFailure.from(e);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            f.isConnectivity ? l10n.errorOfflineAction : f.localized(l10n),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    final now = ref.read(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final range = await ref.read(dateRangePickerProvider)(
      context,
      today,
      DateTime(today.year + 1, today.month, today.day),
    );
    if (range == null || !mounted) return;
    final days = range.end.difference(range.start).inDays + 1;
    if (days > trainingBreakMaxDays) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.scheduleBreakTooLong)));
      return;
    }
    final request = CreateTrainingBreakRequest(
      clientId: const Uuid().v4(),
      startsOn: calendarDate(range.start),
      endsOn: calendarDate(range.end),
    );
    await _run(
      () => ref.read(scheduleApiProvider).createBreak(request),
      l10n.scheduleBreakAdded,
    );
  }

  Future<void> _delete(TrainingBreak b) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.scheduleBreakDeleteTitle),
        content: Text(l10n.scheduleBreakDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('break-delete-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.scheduleBreakDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(
      () => ref.read(scheduleApiProvider).deleteBreak(b.id),
      l10n.scheduleBreakDeleted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final breaks = ref.watch(breaksProvider);
    return SectionCard(
      title: l10n.scheduleBreaksTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.scheduleBreaksIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          breaks.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(ApiFailure.from(e).localized(l10n)),
            data: (items) => items.isEmpty
                ? Text(l10n.scheduleBreaksEmpty, key: const Key('breaks-empty'))
                : Column(
                    children: [
                      for (final b in items)
                        ListTile(
                          key: Key('break-${b.id}'),
                          contentPadding: EdgeInsets.zero,
                          minTileHeight: AppSpacing.xxl,
                          leading: const Icon(Icons.beach_access_outlined),
                          title: Text(
                            l10n.scheduleBreakRange(
                              l10n.shortDate(parseCalendarDate(b.startsOn)),
                              l10n.shortDate(parseCalendarDate(b.endsOn)),
                            ),
                          ),
                          subtitle: Text(
                            l10n.scheduleBreakDays(
                              parseCalendarDate(b.endsOn)
                                      .difference(parseCalendarDate(b.startsOn))
                                      .inDays +
                                  1,
                            ),
                          ),
                          trailing: IconButton(
                            key: Key('break-delete-${b.id}'),
                            tooltip: l10n.scheduleBreakDelete,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: _busy ? null : () => _delete(b),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const Key('break-add'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, AppSpacing.xxl),
            ),
            onPressed: _busy ? null : _add,
            icon: const Icon(Icons.add),
            label: Text(l10n.scheduleBreakAdd),
          ),
        ],
      ),
    );
  }
}

// ── Recordatorio local ──

class _ReminderCard extends ConsumerStatefulWidget {
  const _ReminderCard();

  @override
  ConsumerState<_ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends ConsumerState<_ReminderCard> {
  bool _busy = false;

  Future<void> _apply(ReminderSettings next) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(reminderServiceProvider).save(next);
      ref.invalidate(reminderSettingsProvider);
      await refreshReminders(ref, l10n, settings: next);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggle(ReminderSettings current, bool on) async {
    if (!on) return _apply(current.copyWith(enabled: false));
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // Se explica para qué es el permiso antes de que lo pida el sistema.
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.notifications_outlined),
        title: Text(l10n.scheduleReminderPermissionTitle),
        content: Text(l10n.scheduleReminderPermissionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.scheduleReminderPermissionLater),
          ),
          FilledButton(
            key: const Key('reminder-permission-continue'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.scheduleReminderPermissionContinue),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    final granted = await ref
        .read(notificationSchedulerProvider)
        .requestPermission();
    if (!granted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.scheduleReminderDenied)),
      );
      return;
    }
    await _apply(current.copyWith(enabled: true));
  }

  Future<void> _pickTime(ReminderSettings current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current.time,
    );
    if (picked == null || !mounted) return;
    await _apply(current.copyWith(time: picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(reminderSettingsProvider);
    return SectionCard(
      title: l10n.scheduleReminderTitle,
      child: settings.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text(ApiFailure.from(e).localized(l10n)),
        data: (s) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              key: const Key('reminder-toggle'),
              contentPadding: EdgeInsets.zero,
              value: s.enabled,
              onChanged: _busy ? null : (on) => _toggle(s, on),
              title: Text(l10n.scheduleReminderToggle),
              subtitle: Text(l10n.scheduleReminderHelp),
            ),
            if (s.enabled)
              ListTile(
                key: const Key('reminder-time'),
                contentPadding: EdgeInsets.zero,
                minTileHeight: AppSpacing.xxl,
                leading: const Icon(Icons.schedule),
                title: Text(l10n.scheduleReminderTime(s.time.format(context))),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _busy ? null : () => _pickTime(s),
              ),
          ],
        ),
      ),
    );
  }
}

/// Reprograma el recordatorio una vez al entrar en la app con sesión (los
/// avisos se programan solo para los próximos días).
class ReminderRefresher extends ConsumerStatefulWidget {
  const ReminderRefresher({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ReminderRefresher> createState() => _ReminderRefresherState();
}

class _ReminderRefresherState extends ConsumerState<ReminderRefresher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      try {
        final settings = await ref.read(reminderServiceProvider).load();
        if (settings.enabled && mounted) {
          await refreshReminders(ref, l10n, settings: settings);
        }
      } catch (_) {
        // El recordatorio nunca debe romper el arranque.
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
