/// Ajustes: perfil (→ nueva versión del plan, CUJ-6), datos de salud y
/// consentimiento (ADR-0011), objetivos de nutrición (ADR-0004), exportar y
/// borrar cuenta (CUJ-8), cerrar sesión y aviso legal/médico.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tokens.dart';
import '../../core/api/api_failure.dart';
import '../../core/offline/offline_providers.dart';
import '../../data/pipos_api.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/failure_messages.dart';
import '../../models/enums.dart';
import '../../models/profile.dart';
import '../../shared/widgets.dart';
import '../auth/auth_provider.dart';
import '../onboarding/onboarding_controller.dart';
import '../plan/plan_providers.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final email = ref.watch(currentUserProvider)?.email;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (email != null && email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(email, style: Theme.of(context).textTheme.bodyMedium),
            )
          else if (email != null)
            // Entrada sin red con solo el id del usuario guardado (sesiones
            // antiguas): se marca en vez de dejar el correo vacío (#26).
            Padding(
              key: const Key('settings-email-offline'),
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.cloud_off_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.settingsEmailOffline,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          _TileCard(
            child: ListTile(
              key: const Key('settings-profile'),
              minTileHeight: AppSpacing.xxl + AppSpacing.md,
              leading: const Icon(Icons.tune),
              title: Text(l10n.settingsProfile),
              subtitle: Text(l10n.settingsProfileSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings/profile'),
            ),
          ),
          const _HealthCard(),

          const _NutritionCard(),
          _TileCard(
            child: ListTile(
              key: const Key('settings-schedule'),
              minTileHeight: AppSpacing.xxl + AppSpacing.md,
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(l10n.settingsSchedule),
              subtitle: Text(l10n.settingsScheduleSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings/schedule'),
            ),
          ),
          _TileCard(
            child: Column(
              children: [
                ListTile(
                  key: const Key('settings-export'),
                  minTileHeight: AppSpacing.xxl + AppSpacing.md,
                  leading: const Icon(Icons.download_outlined),
                  title: Text(l10n.settingsExport),
                  subtitle: Text(l10n.settingsExportSubtitle),
                  onTap: () => _export(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('settings-legal'),
                  minTileHeight: AppSpacing.xxl + AppSpacing.md,
                  leading: const Icon(Icons.gavel_outlined),
                  title: Text(l10n.settingsLegal),
                  onTap: () => _showLegal(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('settings-logout'),
                  minTileHeight: AppSpacing.xxl + AppSpacing.md,
                  leading: const Icon(Icons.logout),
                  title: Text(l10n.settingsLogout),
                  onTap: () => _logout(context, ref),
                ),
              ],
            ),
          ),
          _TileCard(
            child: ListTile(
              key: const Key('settings-delete'),
              minTileHeight: AppSpacing.xxl + AppSpacing.md,
              leading: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                l10n.settingsDelete,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              subtitle: Text(l10n.settingsDeleteSubtitle),
              onTap: () => showDeleteAccountDialog(context),
            ),
          ),
          NoticeBanner(
            text: l10n.medicalNotice,
            icon: Icons.health_and_safety_outlined,
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final export = await ref.read(accountApiProvider).exportData();
      final stamp = export.exportedAt.toUtc().toIso8601String().substring(
        0,
        10,
      );
      await ref
          .read(exportSaverProvider)
          .save('pipos-fitness-$stamp.json', export.raw);
      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsExportDone)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(ApiFailure.from(e).localized(l10n))),
      );
    }
  }

  /// Cerrar sesión: confirma avisando de las series sin enviar (se
  /// perderían) y, tras confirmar, borra del dispositivo los datos de este
  /// usuario (caché del plan/sesión y cola offline).
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final sync = ref.read(syncServiceProvider);
    var summary = await sync.watchSummary().first;
    if (!summary.isClean) {
      // Último intento de enviar lo pendiente antes de preguntar.
      try {
        await sync.syncNow().timeout(const Duration(seconds: 5));
      } catch (_) {}
      summary = await sync.watchSummary().first;
    }
    final unsent = summary.unsent;
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsLogoutConfirmTitle),
        content: Text(
          unsent > 0
              ? l10n.settingsLogoutUnsent(unsent)
              : l10n.settingsLogoutConfirmBody,
          key: const Key('logout-body'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('logout-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.settingsLogout),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await sync.dispose();
    await ref.read(cacheStoreProvider).wipeUser();
    await ref.read(authProvider.notifier).logout();
  }

  void _showLegal(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final consent = ref.read(healthConsentProvider).valueOrNull;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsLegal),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.medicalNotice),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.screeningNotice),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.healthConsentText),
              Text(
                l10n.onboardingConsentVersion(healthConsentPolicyVersion),
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              // La versión aceptada solo se muestra aquí (detalle legal), no
              // en la tarjeta de Ajustes.
              if (consent != null &&
                  consent.granted &&
                  consent.version != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.settingsLegalConsentVersion(
                    consent.version!,
                    consent.grantedAt == null
                        ? '–'
                        : l10n.shortDate(consent.grantedAt!),
                  ),
                  key: const Key('legal-consent-version'),
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.actionClose),
          ),
        ],
      ),
    );
  }
}

class _HealthCard extends ConsumerStatefulWidget {
  const _HealthCard();

  @override
  ConsumerState<_HealthCard> createState() => _HealthCardState();
}

class _HealthCardState extends ConsumerState<_HealthCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(ApiFailure.from(e).localized(l10n))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _withdraw() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsHealthWithdrawTitle),
        content: Text(l10n.settingsHealthWithdrawBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('withdraw-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.settingsHealthWithdraw),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await _run(() async {
      await ref.read(profileApiProvider).withdrawHealthConsent();
      await ref.read(cacheStoreProvider).remove(CacheKeys.today);
      ref.invalidate(healthConsentProvider);
      ref.invalidate(profileProvider);
      ref.invalidate(currentPlanProvider);
      ref.invalidate(nutritionTargetsProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsHealthWithdrawn)),
      );
    });
  }

  Future<void> _grant() async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.onboardingConsentTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.healthConsentText),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.onboardingConsentVersion(healthConsentPolicyVersion),
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.onboardingConsentAccept),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(() async {
      await ref
          .read(profileApiProvider)
          .grantHealthConsent(
            version: healthConsentPolicyVersion,
            locale: locale.languageCode == 'en' ? AppLocale.en : AppLocale.es,
          );
      ref.invalidate(healthConsentProvider);
      ref.invalidate(profileProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final consent = ref.watch(healthConsentProvider);
    return SectionCard(
      title: l10n.settingsHealth,
      child: consent.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text(ApiFailure.from(e).localized(l10n)),
        data: (c) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              !c.granted
                  ? l10n.settingsHealthNotGranted
                  : c.grantedAt == null
                  ? l10n.settingsHealthGrantedNoDate
                  : l10n.settingsHealthGranted(l10n.shortDate(c.grantedAt!)),
              key: const Key('health-status'),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Consentimiento de una versión anterior: sigue cubriendo sus
            // ámbitos; para medidas y estimaciones hay que aceptar la nueva.
            if (c.granted && !c.isValid) ...[
              Text(
                l10n.settingsHealthUpdateBody,
                key: const Key('health-update-body'),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                key: const Key('health-update'),
                onPressed: _busy ? null : _grant,
                child: Text(l10n.settingsHealthUpdate),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (c.granted)
              OutlinedButton(
                key: const Key('health-withdraw'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, AppSpacing.xxl),
                ),
                onPressed: _busy ? null : _withdraw,
                child: Text(l10n.settingsHealthWithdraw),
              )
            else
              FilledButton(
                key: const Key('health-grant'),
                onPressed: _busy ? null : _grant,
                child: Text(l10n.settingsHealthGrant),
              ),
          ],
        ),
      ),
    );
  }
}

class _NutritionCard extends ConsumerWidget {
  const _NutritionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final targets = ref.watch(nutritionTargetsProvider);
    return SectionCard(
      title: l10n.settingsNutrition,
      child: targets.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) {
          final f = ApiFailure.from(e);
          final incomplete =
              f.code == ApiErrorCode.nutritionInputIncomplete ||
              f.code == ApiErrorCode.profileRequired ||
              f.statusCode == 422;
          if (!incomplete) {
            return Row(
              children: [
                Expanded(child: Text(f.localized(l10n))),
                IconButton(
                  tooltip: l10n.actionRetry,
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(nutritionTargetsProvider),
                ),
              ],
            );
          }
          final fields = {for (final i in f.issues) i.field}.toList();
          return Column(
            key: const Key('nutrition-incomplete'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsNutritionIncomplete,
                style: theme.textTheme.bodyMedium,
              ),
              for (final field in fields)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text('• ${l10n.fieldNames(field)}'),
                ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, AppSpacing.xxl),
                ),
                onPressed: () => context.go('/settings/profile'),
                child: Text(l10n.settingsNutritionComplete),
              ),
            ],
          );
        },
        data: (t) => Column(
          key: const Key('nutrition-targets'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              // Separador de miles del idioma: «2.350 kcal».
              l10n.settingsNutritionKcal(l10n.number(t.kcal)),
              style: theme.textTheme.headlineSmall,
            ),
            Text(
              l10n.settingsNutritionMacros(
                l10n.number(t.proteinG),
                l10n.number(t.fatG),
                l10n.number(t.carbsG),
              ),
            ),
            Text(
              l10n.nutritionGoalLabel(t.nutritionGoal.wire),
              style: theme.textTheme.bodySmall,
            ),
            for (final w in t.warnings)
              NoticeBanner(text: w.message, icon: Icons.warning_amber_outlined),
            RationaleExpander(lines: t.rationale),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de una o varias filas de lista con el mismo inset horizontal y
/// la misma separación que [SectionCard] (Card trae un margen de 4 dp por
/// defecto que la desalineaba).
class _TileCard extends StatelessWidget {
  const _TileCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: child,
  );
}

/// Diálogo de borrado de cuenta: explica las consecuencias y pide la
/// contraseña (`DELETE /me` reautentica; 403 = contraseña incorrecta y la
/// sesión sigue abierta).
Future<void> showDeleteAccountDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _DeleteAccountDialog(),
  );
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    if (_password.text.isEmpty) {
      setState(() => _error = l10n.validationPasswordRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountApiProvider).deleteAccount(_password.text);
      final auth = ref.read(authProvider.notifier);
      await ref.read(cacheStoreProvider).wipeUser();
      if (mounted) Navigator.of(context).pop();
      await auth.onAccountDeleted();
    } catch (e) {
      if (!mounted) return;
      final f = ApiFailure.from(e);
      setState(() {
        _busy = false;
        _error = f.statusCode == 403 || f.statusCode == 401
            ? l10n.settingsDeleteWrongPassword
            : f.localized(l10n);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
      title: Text(l10n.settingsDeleteTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.settingsDeleteBody),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('delete-password'),
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: l10n.fieldPassword,
                errorText: _error,
                errorMaxLines: 3,
              ),
              onSubmitted: (_) => _delete(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const Key('delete-confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            minimumSize: const Size(AppSpacing.xxl, AppSpacing.xxl),
          ),
          onPressed: _busy ? null : _delete,
          child: Text(l10n.settingsDeleteConfirm),
        ),
      ],
    );
  }
}
