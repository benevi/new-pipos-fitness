/// Contenido de cada paso del cuestionario. Lo comparten el alta
/// ([OnboardingScreen]) y la edición del perfil (Ajustes).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums.dart';
import '../../models/profile.dart';
import '../../shared/widgets.dart';
import 'form_parts.dart';
import 'onboarding_controller.dart';
import 'profile_draft.dart';

class ProfileStepView extends ConsumerWidget {
  const ProfileStepView({
    super.key,
    required this.state,
    required this.controller,
  });

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final d = state.draft;
    FieldMessage? err(OnboardingField f) => state.errors[f];

    switch (state.step) {
      case OnboardingStep.goal:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuestionTitle(l10n.onboardingGoalTitle),
            SingleChoiceList<TrainingGoal>(
              keyPrefix: 'goal',
              options: TrainingGoal.values,
              selected: d.goal,
              label: (g) => l10n.goalLabel(g.wire),
              onSelected: (g) => controller.edit(
                (d) => d.goal = g,
                field: OnboardingField.goal,
              ),
            ),
            FieldErrorText(
              err(OnboardingField.goal),
              key: const Key('error-goal'),
            ),
            QuestionTitle(l10n.onboardingLevelTitle),
            SingleChoiceList<TrainingLevel>(
              keyPrefix: 'level',
              options: TrainingLevel.values,
              selected: d.level,
              label: (v) => l10n.levelLabel(v.wire),
              onSelected: (v) => controller.edit(
                (d) => d.level = v,
                field: OnboardingField.level,
              ),
            ),
            FieldErrorText(
              err(OnboardingField.level),
              key: const Key('error-level'),
            ),
          ],
        );

      case OnboardingStep.schedule:
        final minutes = {...minuteChoices, ?d.minutesPerSession}.toList()
          ..sort();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuestionTitle(l10n.onboardingScheduleTitle),
            Text(
              l10n.onboardingDaysLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            ChipChoices<int>(
              single: true,
              keyPrefix: 'days',
              options: [
                for (
                  var i = ProfileLimits.minDays;
                  i <= ProfileLimits.maxDays;
                  i++
                )
                  i,
              ],
              isSelected: (v) => d.daysPerWeek == v,
              label: (v) => l10n.onboardingDaysValue(v),
              onToggle: (v) => controller.edit(
                (d) => d.daysPerWeek = v,
                field: OnboardingField.daysPerWeek,
              ),
            ),
            FieldErrorText(
              err(OnboardingField.daysPerWeek),
              key: const Key('error-daysPerWeek'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.onboardingMinutesLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            ChipChoices<int>(
              single: true,
              keyPrefix: 'minutes',
              options: minutes,
              isSelected: (v) => d.minutesPerSession == v,
              label: (v) => l10n.onboardingMinutesValue(v),
              onToggle: (v) => controller.edit(
                (d) => d.minutesPerSession = v,
                field: OnboardingField.minutesPerSession,
              ),
            ),
            FieldErrorText(
              err(OnboardingField.minutesPerSession),
              key: const Key('error-minutesPerSession'),
            ),
          ],
        );

      case OnboardingStep.equipment:
        void preset(Set<Equipment> set) => controller.edit((d) {
          d.equipment
            ..clear()
            ..addAll(set);
        }, field: OnboardingField.equipment);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuestionTitle(
              l10n.onboardingEquipmentTitle,
              hint: l10n.onboardingEquipmentHint,
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.fitness_center),
                  label: Text(l10n.onboardingEquipmentPresetGym),
                  onPressed: () => preset(EquipmentPresets.gym),
                ),
                ActionChip(
                  avatar: const Icon(Icons.home_outlined),
                  label: Text(l10n.onboardingEquipmentPresetHome),
                  onPressed: () => preset(EquipmentPresets.home),
                ),
                ActionChip(
                  key: const Key('preset-bodyweight'),
                  avatar: const Icon(Icons.accessibility_new),
                  label: Text(l10n.onboardingEquipmentPresetBodyweight),
                  onPressed: () => preset(EquipmentPresets.bodyweight),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xl),
            ChipChoices<Equipment>(
              keyPrefix: 'equipment',
              options: Equipment.values,
              isSelected: d.equipment.contains,
              label: (e) => l10n.equipmentLabel(e.wire),
              onToggle: (e) => controller.edit((d) {
                if (!d.equipment.remove(e)) d.equipment.add(e);
              }, field: OnboardingField.equipment),
            ),
            FieldErrorText(
              err(OnboardingField.equipment),
              key: const Key('error-equipment'),
            ),
          ],
        );

      case OnboardingStep.consent:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            QuestionTitle(
              l10n.onboardingConsentTitle,
              hint: l10n.onboardingConsentIntro,
            ),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.healthConsentText,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.onboardingConsentVersion(healthConsentPolicyVersion),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            NoticeBanner(
              text: l10n.screeningNotice,
              icon: Icons.health_and_safety_outlined,
            ),
            FilledButton(
              key: const Key('consent-accept'),
              onPressed: () => controller.setConsent(true),
              child: Text(l10n.onboardingConsentAccept),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              key: const Key('consent-skip'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, AppSpacing.xxl),
              ),
              onPressed: () => controller.setConsent(false),
              child: Text(l10n.onboardingConsentSkip),
            ),
          ],
        );

      case OnboardingStep.limitations:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuestionTitle(
              l10n.onboardingLimitationsTitle,
              hint: l10n.onboardingLimitationsHint,
            ),
            NoticeBanner(
              text: l10n.screeningNotice,
              icon: Icons.health_and_safety_outlined,
            ),
            ChipChoices<BodyZone>(
              keyPrefix: 'zone',
              options: BodyZone.values,
              isSelected: d.limitations.contains,
              label: (z) => l10n.zoneLabel(z.wire),
              onToggle: (z) => controller.edit((d) {
                if (!d.limitations.remove(z)) d.limitations.add(z);
              }, field: OnboardingField.limitations),
            ),
            FieldErrorText(err(OnboardingField.limitations)),
          ],
        );

      case OnboardingStep.preferences:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuestionTitle(l10n.onboardingPreferencesTitle),
            Text(
              l10n.onboardingPriorityLabel(ProfileLimits.maxPriorityMuscles),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            ChipChoices<Muscle>(
              keyPrefix: 'muscle',
              options: Muscle.values,
              isSelected: d.priorityMuscles.contains,
              label: (m) => l10n.muscleLabel(m.wire),
              onToggle: (m) => controller.edit((d) {
                if (!d.priorityMuscles.remove(m)) d.priorityMuscles.add(m);
              }, field: OnboardingField.priorityMuscles),
            ),
            FieldErrorText(
              err(OnboardingField.priorityMuscles),
              key: const Key('error-priorityMuscles'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ExerciseListField(
              title: l10n.onboardingFavouritesLabel,
              items: d.favourites,
              onAdd: (e) => controller.edit(
                (d) => d.favourites.add(e),
                field: OnboardingField.favouriteExerciseSlugs,
              ),
              onRemove: (e) => controller.edit(
                (d) => d.favourites.removeWhere((x) => x.slug == e.slug),
                field: OnboardingField.favouriteExerciseSlugs,
              ),
            ),
            FieldErrorText(err(OnboardingField.favouriteExerciseSlugs)),
            const SizedBox(height: AppSpacing.md),
            _ExerciseListField(
              title: l10n.onboardingBannedLabel,
              items: d.banned,
              onAdd: (e) => controller.edit(
                (d) => d.banned.add(e),
                field: OnboardingField.bannedExerciseSlugs,
              ),
              onRemove: (e) => controller.edit(
                (d) => d.banned.removeWhere((x) => x.slug == e.slug),
                field: OnboardingField.bannedExerciseSlugs,
              ),
            ),
            FieldErrorText(err(OnboardingField.bannedExerciseSlugs)),
          ],
        );

      case OnboardingStep.body:
        final tz = d.timezone ?? ref.watch(deviceTimezoneProvider).valueOrNull;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuestionTitle(
              l10n.onboardingBodyTitle,
              hint: l10n.onboardingBodyHint,
            ),
            _NumberField(
              fieldKey: const Key('field-birthYear'),
              label: l10n.fieldBirthYear,
              value: d.birthYear,
              error: err(OnboardingField.birthYear),
              decimal: false,
              onChanged: (v) => controller.edit(
                (d) => d.birthYear = v,
                field: OnboardingField.birthYear,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.fieldSex, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ChipChoices<Sex?>(
              single: true,
              keyPrefix: 'sex',
              options: const [...Sex.values, null],
              isSelected: (s) => d.sex == s,
              label: (s) =>
                  s == null ? l10n.fieldNotSpecified : l10n.sexLabel(s.wire),
              onToggle: (s) =>
                  controller.edit((d) => d.sex = s, field: OnboardingField.sex),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.fieldActivityLevel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            ChipChoices<ActivityLevel?>(
              single: true,
              keyPrefix: 'activity',
              options: const [...ActivityLevel.values, null],
              isSelected: (a) => d.activityLevel == a,
              label: (a) => a == null
                  ? l10n.fieldNotSpecified
                  : l10n.activityLabel(a.wire),
              onToggle: (a) => controller.edit(
                (d) => d.activityLevel = a,
                field: OnboardingField.activityLevel,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (d.hasConsent) ...[
              _NumberField(
                fieldKey: const Key('field-weightKg'),
                label: l10n.fieldWeightKg,
                value: d.weightKg,
                error: err(OnboardingField.weightKg),
                onChanged: (v) => controller.edit(
                  (d) => d.weightKg = v,
                  field: OnboardingField.weightKg,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _NumberField(
                fieldKey: const Key('field-heightCm'),
                label: l10n.fieldHeightCm,
                value: d.heightCm,
                error: err(OnboardingField.heightCm),
                onChanged: (v) => controller.edit(
                  (d) => d.heightCm = v,
                  field: OnboardingField.heightCm,
                ),
              ),
            ] else
              NoticeBanner(
                text: l10n.onboardingBodyNeedsConsent,
                icon: Icons.lock_outline,
              ),
            const SizedBox(height: AppSpacing.md),
            if (tz != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.public),
                title: Text(l10n.fieldTimezone),
                subtitle: Text(l10n.onboardingTimezoneAuto(tz)),
              ),
            FieldErrorText(err(OnboardingField.timezone)),
          ],
        );

      case OnboardingStep.review:
        final lines = <String>[
          if (d.goal != null) l10n.goalLabel(d.goal!.wire),
          if (d.level != null) l10n.levelLabel(d.level!.wire),
          if (d.daysPerWeek != null && d.minutesPerSession != null)
            '${l10n.onboardingDaysValue(d.daysPerWeek!)} · ${l10n.onboardingMinutesValue(d.minutesPerSession!)}',
          Equipment.values
              .where(d.equipment.contains)
              .map((e) => l10n.equipmentLabel(e.wire))
              .join(', '),
          if (d.hasConsent && d.limitations.isNotEmpty)
            BodyZone.values
                .where(d.limitations.contains)
                .map((z) => l10n.zoneLabel(z.wire))
                .join(', '),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            QuestionTitle(l10n.onboardingReviewTitle),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(
                        line,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                ],
              ),
            ),
            if (d.consent == false)
              NoticeBanner(text: l10n.onboardingConsentSkippedNote),
            NoticeBanner(
              text: l10n.medicalNotice,
              icon: Icons.health_and_safety_outlined,
            ),
          ],
        );
    }
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.error,
    required this.onChanged,
    this.decimal = true,
  });

  final Key fieldKey;
  final String label;
  final String value;
  final FieldMessage? error;
  final ValueChanged<String> onChanged;
  final bool decimal;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      key: widget.fieldKey,
      controller: _controller,
      keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(widget.decimal ? r'[0-9.,]' : r'[0-9]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.error?.call(l10n),
        errorMaxLines: 3,
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _ExerciseListField extends StatelessWidget {
  const _ExerciseListField({
    required this.title,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final List<PickedExercise> items;
  final ValueChanged<PickedExercise> onAdd;
  final ValueChanged<PickedExercise> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final e in items)
              InputChip(
                label: Text(e.name),
                materialTapTargetSize: MaterialTapTargetSize.padded,
                deleteButtonTooltipMessage: l10n.onboardingRemoveExercise(
                  e.name,
                ),
                onDeleted: () => onRemove(e),
              ),
            ActionChip(
              avatar: const Icon(Icons.add),
              label: Text(l10n.onboardingAddExercise),
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onPressed: () async {
                final picked = await showExercisePicker(context);
                if (picked == null) return;
                if (items.any((i) => i.slug == picked.slug)) return;
                onAdd(
                  PickedExercise(
                    slug: picked.slug,
                    name: picked.localizedName(lang),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
