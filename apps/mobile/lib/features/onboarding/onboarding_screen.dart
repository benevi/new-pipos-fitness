/// Cuestionario de alta (CUJ-1) y edición del perfil (CUJ-6).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/failure_messages.dart';
import '../../models/profile.dart';
import '../../shared/widgets.dart';
import '../plan/plan_view.dart';
import '../setup/setup_provider.dart';
import 'onboarding_controller.dart';
import 'profile_draft.dart';
import 'profile_form.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return profile.when(
      loading: () => const Scaffold(body: LoadingView()),
      // Sin perfil legible (p. ej. sin red): se empieza de cero.
      error: (_, _) => const _ProfileFormScaffold(
        profile: null,
        mode: ProfileFormMode.onboarding,
      ),
      data: (p) =>
          _ProfileFormScaffold(profile: p, mode: ProfileFormMode.onboarding),
    );
  }
}

/// Edición del perfil desde Ajustes. Con [pick] (desde la ficha de un
/// ejercicio) se abre en preferencias con ese cambio ya preparado.
class ProfileEditScreen extends ConsumerWidget {
  const ProfileEditScreen({super.key, this.pick});

  final ProfilePick? pick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final l10n = AppLocalizations.of(context);
    return profile.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.settingsProfile)),
        body: const LoadingView(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.settingsProfile)),
        body: ErrorView(
          error: e,
          onRetry: () => ref.invalidate(profileProvider),
        ),
      ),
      data: (p) => p == null
          ? const _ProfileFormScaffold(
              profile: null,
              mode: ProfileFormMode.onboarding,
            )
          : pick == null
          ? _ProfileFormScaffold(profile: p, mode: ProfileFormMode.edit)
          : _WithPick(
              profile: p,
              pick: pick!,
              child: _ProfileFormScaffold(
                profile: p,
                mode: ProfileFormMode.edit,
              ),
            ),
    );
  }
}

/// Aplica una sola vez el cambio preparado desde la ficha.
class _WithPick extends ConsumerStatefulWidget {
  const _WithPick({
    required this.profile,
    required this.pick,
    required this.child,
  });

  final ProfileResponse profile;
  final ProfilePick pick;
  final Widget child;

  @override
  ConsumerState<_WithPick> createState() => _WithPickState();
}

class _WithPickState extends ConsumerState<_WithPick> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(profileEditControllerProvider(widget.profile).notifier)
          .applyPick(widget.pick);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ProfileFormScaffold extends ConsumerWidget {
  const _ProfileFormScaffold({required this.profile, required this.mode});

  final ProfileResponse? profile;
  final ProfileFormMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = mode == ProfileFormMode.edit
        ? profileEditControllerProvider(profile!)
        : onboardingControllerProvider(profile);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final l10n = AppLocalizations.of(context);

    ref.listen(provider, (prev, next) {
      if (mode != ProfileFormMode.edit || prev?.saved == true || !next.saved) {
        return;
      }
      ref.invalidate(profileProvider);
      _afterEditSaved(context, next);
    });

    final plan = state.plan;
    if (mode == ProfileFormMode.onboarding && plan != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.onboardingResultTitle),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PlanOverview(plan: plan, rationaleExpanded: true),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: FilledButton(
                  key: const Key('onboarding-start'),
                  onPressed: () {
                    ref.read(setupStatusProvider.notifier).markReady();
                    context.go('/today');
                  },
                  child: Text(l10n.onboardingResultStart),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final steps = controller.steps;
    final index = steps.indexOf(state.step);
    final isConsent = state.step == OnboardingStep.consent;
    final isLast = controller.isLastStep;
    final failure = state.failure;

    return PopScope(
      canPop: index <= 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            mode == ProfileFormMode.edit
                ? l10n.settingsProfile
                : l10n.onboardingTitle,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(AppSpacing.lg),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.onboardingStepOf(index + 1, steps.length),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ExcludeSemantics(
                    child: LinearProgressIndicator(
                      value: (index + 1) / steps.length,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  key: ValueKey(state.step),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (failure != null)
                        Semantics(
                          liveRegion: true,
                          child: NoticeBanner(
                            key: const Key('form-failure'),
                            text: failure.localized(l10n),
                            icon: Icons.error_outline,
                          ),
                        ),
                      ProfileStepView(state: state, controller: controller),
                    ],
                  ),
                ),
              ),
              if (!isConsent)
                _BottomBar(
                  showBack: index > 0,
                  primaryLabel: isLast
                      ? (mode == ProfileFormMode.edit
                            ? l10n.onboardingSaveChanges
                            : l10n.onboardingGenerate)
                      : l10n.onboardingNext,
                  busy: state.submitting,
                  busyLabel: l10n.onboardingGenerating,
                  onBack: controller.back,
                  onPrimary: () {
                    if (isLast) {
                      if (controller.next()) {
                        controller.submit(
                          locale: Localizations.localeOf(context),
                        );
                      }
                    } else {
                      controller.next();
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _afterEditSaved(
    BuildContext context,
    OnboardingState state,
  ) async {
    final l10n = AppLocalizations.of(context);
    final version = state.newPlanVersion;
    if (version == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsProfileSaved)));
      context.pop();
      return;
    }
    final goPlan = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsNewPlanTitle),
        content: Text(l10n.settingsNewPlanBody(version.version)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionClose),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.settingsNewPlanAction),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (goPlan == true) {
      context.go('/plan');
    } else {
      context.pop();
    }
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.showBack,
    required this.primaryLabel,
    required this.busy,
    required this.busyLabel,
    required this.onBack,
    required this.onPrimary,
  });

  final bool showBack;
  final String primaryLabel;
  final bool busy;
  final String busyLabel;
  final VoidCallback onBack;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          if (showBack) ...[
            Expanded(
              child: OutlinedButton(
                key: const Key('onboarding-back'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.xxl),
                ),
                onPressed: busy ? null : onBack,
                child: Text(l10n.actionBack),
              ),
            ),
            const SizedBox(width: AppSpacing.ms),
          ],
          Expanded(
            flex: 2,
            child: FilledButton(
              key: const Key('onboarding-next'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.xxl),
              ),
              onPressed: busy ? null : onPrimary,
              child: busy
                  ? Semantics(
                      label: busyLabel,
                      liveRegion: true,
                      child: const SizedBox.square(
                        dimension: AppSpacing.lg - AppSpacing.xs,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Text(primaryLabel, textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}
