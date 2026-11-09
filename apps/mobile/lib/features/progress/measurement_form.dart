/// Formulario de medidas de un día (idea 7, ADR-0013). Todas opcionales
/// (al menos una), con su unidad, su rango del contrato y «cómo medir». Los
/// perímetros se habilitan solo si el consentimiento cubre
/// `body_measurements`; si no, se ofrece leer y aceptar el texto nuevo. Se
/// guarda en la cola offline (`PUT /me/measurements`, idempotente por día).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tokens.dart';
import '../../core/api/api_failure.dart';
import '../../core/offline/app_database.dart';
import '../../core/offline/mutation_sender.dart';
import '../../core/offline/offline_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/failure_messages.dart';
import '../../models/body.dart';
import '../../models/enums.dart';
import '../../models/notes_breaks.dart';
import '../../shared/widgets.dart';
import '../settings/settings_providers.dart';
import 'body_providers.dart';

Future<void> openMeasurementForm(BuildContext context) => Navigator.of(
  context,
  rootNavigator: true,
).push(MaterialPageRoute<void>(builder: (_) => const MeasurementFormScreen()));

class MeasurementFormScreen extends ConsumerStatefulWidget {
  const MeasurementFormScreen({super.key});

  @override
  ConsumerState<MeasurementFormScreen> createState() =>
      _MeasurementFormScreenState();
}

class _MeasurementFormScreenState extends ConsumerState<MeasurementFormScreen> {
  final _controllers = {
    for (final f in BodyField.values) f: TextEditingController(),
  };
  final _errors = <BodyField, String>{};
  String? _formError;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    _date = DateTime(now.year, now.month, now.day);
  }

  bool _prefilledOnce = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// `PUT` sustituye el día entero: se precargan las medidas ya guardadas
  /// de esa fecha para no borrarlas sin querer.
  void _prefill() {
    if (!mounted) return;
    final server =
        ref.read(measurementsProvider).valueOrNull ??
        const <BodyMeasurementRecord>[];
    final pending =
        ref.read(pendingMeasurementsProvider).valueOrNull ??
        const <String, BodyMeasurement?>{};
    final day = calendarDate(_date);
    final existing = mergeMeasurements(
      server,
      pending,
    ).where((m) => m.measurement.measuredOn == day).firstOrNull;
    setState(() {
      for (final f in BodyField.values) {
        final v = existing?.measurement[f];
        _controllers[f]!.text = v == null ? '' : _fmt(v);
      }
      _errors.clear();
      _formError = null;
    });
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  Future<void> _pickDate() async {
    final now = ref.read(clockProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
    _prefill();
  }

  Future<void> _save(Set<BodyField> allowed) async {
    final l10n = AppLocalizations.of(context);
    final values = <BodyField, double>{};
    final errors = <BodyField, String>{};
    for (final f in BodyField.values) {
      final raw = _controllers[f]!.text.trim().replaceAll(',', '.');
      if (raw.isEmpty || !allowed.contains(f)) continue;
      final v = double.tryParse(raw);
      if (v == null || v < f.min || v > f.max) {
        errors[f] = l10n.validationRange(
          l10n.number(f.min),
          l10n.number(f.max),
        );
      } else {
        values[f] = v;
      }
    }
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
      _formError = errors.isEmpty && values.isEmpty
          ? l10n.measureAtLeastOne
          : null;
    });
    if (errors.isNotEmpty || values.isEmpty) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final m = BodyMeasurement(
        measuredOn: calendarDate(_date),
        values: values,
      );
      await ref
          .read(syncServiceProvider)
          .enqueueMutation(
            key: MutationKeys.measurement(m.measuredOn),
            kind: MutationKind.measurementPut,
            payload: m.toJson(),
          );
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.measureSaved)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final consent = ref.watch(healthConsentProvider);
    // Se mantienen vivas para precargar el día (y al cambiar la fecha).
    final saved = ref.watch(measurementsProvider);
    ref.watch(pendingMeasurementsProvider);
    if (!_prefilledOnce && (saved.hasValue || saved.hasError)) {
      _prefilledOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _prefill());
    }
    // Mientras se carga el consentimiento solo se ofrece lo que ya consta.
    final status = consent.valueOrNull;
    final allowed = {
      for (final f in BodyField.values)
        if (consentAllows(status, f)) f,
    };
    final circumferencesLocked =
        status != null && !allowed.contains(BodyField.waistCm);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.measureTitle)),
      body: consent.hasError
          ? ErrorView(
              error: consent.error!,
              message: ApiFailure.from(consent.error!).isConnectivity
                  ? l10n.errorOfflineAction
                  : null,
              onRetry: () => ref.invalidate(healthConsentProvider),
            )
          : ListView(
              key: const Key('measure-list'),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(l10n.measureIntro, style: theme.textTheme.bodyMedium),
                ListTile(
                  key: const Key('measure-date'),
                  contentPadding: EdgeInsets.zero,
                  minTileHeight: AppSpacing.xxl,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(l10n.measureDate(l10n.shortDate(_date))),
                  trailing: Tooltip(
                    message: l10n.measureDateEdit,
                    child: const Icon(Icons.edit_calendar_outlined),
                  ),
                  onTap: _pickDate,
                ),
                for (final f in BodyField.values) ...[
                  if (f == BodyField.waistCm && circumferencesLocked)
                    Container(
                      key: const Key('measure-consent-locked'),
                      margin: const EdgeInsets.only(top: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.ms),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l10n.measureNeedsConsent),
                          const SizedBox(height: AppSpacing.sm),
                          OutlinedButton(
                            key: const Key('measure-consent'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(
                                double.infinity,
                                AppSpacing.xxl,
                              ),
                            ),
                            onPressed: () => askHealthConsent(context, ref),
                            child: Text(l10n.bodyConsentReview),
                          ),
                        ],
                      ),
                    ),
                  _MeasureField(
                    field: f,
                    controller: _controllers[f]!,
                    enabled: allowed.contains(f) && !_saving,
                    error: _errors[f],
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (_formError != null)
                  Semantics(
                    liveRegion: true,
                    child: NoticeBanner(
                      key: const Key('measure-form-error'),
                      text: _formError!,
                      icon: Icons.error_outline,
                    ),
                  ),
                FilledButton(
                  key: const Key('measure-save'),
                  onPressed: _saving || allowed.isEmpty
                      ? null
                      : () => _save(allowed),
                  child: Text(l10n.measureSave),
                ),
                const SizedBox(height: AppSpacing.md),
                NoticeBanner(
                  text: l10n.medicalNotice,
                  icon: Icons.health_and_safety_outlined,
                ),
              ],
            ),
    );
  }
}

class _MeasureField extends StatelessWidget {
  const _MeasureField({
    required this.field,
    required this.controller,
    required this.enabled,
    required this.error,
  });

  final BodyField field;
  final TextEditingController controller;
  final bool enabled;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = field == BodyField.weightKg
        ? l10n.measureUnitKg
        : l10n.measureUnitCm;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: TextField(
        key: Key('measure-${field.wire}'),
        controller: controller,
        enabled: enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: InputDecoration(
          labelText: l10n.bodyFieldLabel(field.wire),
          suffixText: unit,
          helperText: l10n.bodyFieldHelp(field.wire),
          helperMaxLines: 4,
          errorText: error,
          errorMaxLines: 2,
        ),
      ),
    );
  }
}
