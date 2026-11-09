/// Botón «Ver vídeo (YouTube)» de la ficha y de la tarjeta de Hoy
/// (ADR-0014, Fase 4; docs/UX_MOVIL.md).
///
/// Abre un vídeo concreto y revisado en el segundo de inicio, FUERA de la
/// app (app de YouTube o navegador), tras avisar de que se sale de Pipos.
/// La app no carga código de terceros ni envía datos del usuario: solo pide
/// al sistema que abra un enlace público. Sin vídeo revisado no hay botón;
/// sin red, el botón avisa en lugar de abrir nada.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/tokens.dart';
import '../../core/api/api_failure.dart';
import '../../core/offline/offline_providers.dart';
import '../../data/pipos_api.dart';
import '../../l10n/app_localizations.dart';
import '../../models/exercise.dart';
import 'exercise_providers.dart';

/// Abre enlaces fuera de la app (sustituible en tests).
abstract class ExternalLinkLauncher {
  /// true si el sistema ha abierto el enlace.
  Future<bool> open(Uri uri);
}

/// `url_launcher` en modo aplicación externa: nunca un WebView dentro de
/// Pipos. Android necesita la `<queries>` de https del manifiesto.
class UrlLauncherExternalLinks implements ExternalLinkLauncher {
  const UrlLauncherExternalLinks();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

final externalLinkLauncherProvider = Provider<ExternalLinkLauncher>(
  (_) => const UrlLauncherExternalLinks(),
);

/// Botón «Ver vídeo (YouTube)». Con [video] (ficha) abre ese vídeo; sin él
/// (tarjeta de Hoy, que solo sabe `hasVideo`) pide la ficha de [idOrSlug]
/// —o su copia en caché— para conocer el vídeo antes de abrirlo.
class ExerciseVideoButton extends ConsumerWidget {
  const ExerciseVideoButton({
    super.key,
    required this.idOrSlug,
    required this.exerciseName,
    this.video,
  });

  final String idOrSlug;
  final String exerciseName;
  final ExerciseVideo? video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return OutlinedButton.icon(
      key: Key('exercise-video-$idOrSlug'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(AppSpacing.xxl, AppSpacing.xxl),
      ),
      onPressed: () => _open(context, ref),
      icon: const Icon(Icons.play_circle_outline),
      label: Text(
        l10n.exerciseVideoButton,
        semanticsLabel: l10n.exerciseVideoSemantics(exerciseName),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    void tell(String text) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
    }

    // Sin red no se abre nada: YouTube no cargaría y el usuario saldría de
    // la app para ver un error.
    if (!await ref.read(connectivitySourceProvider).isOnline()) {
      tell(l10n.exerciseVideoOffline);
      return;
    }
    var target = video;
    if (target == null) {
      try {
        final cached = await loadExerciseDetail(
          ref.read(catalogApiProvider),
          ref.read(cacheStoreProvider),
          idOrSlug,
        );
        target = cached.value.primaryVideo;
      } catch (e) {
        final failure = ApiFailure.from(e);
        tell(
          failure.isConnectivity || failure.type == ApiFailureType.server
              ? l10n.exerciseVideoOffline
              : l10n.exerciseVideoUnavailable,
        );
        return;
      }
      if (target == null) {
        tell(l10n.exerciseVideoUnavailable);
        return;
      }
    }
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('exercise-video-leave'),
        title: Text(l10n.exerciseVideoLeaveTitle),
        content: Text(l10n.exerciseVideoLeaveBody(target!.channelName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton.icon(
            key: const Key('exercise-video-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.open_in_new),
            label: Text(l10n.exerciseVideoLeaveConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final opened = await ref
        .read(externalLinkLauncherProvider)
        .open(target.watchUri);
    if (!opened) tell(l10n.exerciseVideoOpenFailed);
  }
}
