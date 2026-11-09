/// Piezas de UI compartidas: estados de carga, error y vacío, explicaciones
/// desplegables y tarjetas de sección. Solo tokens (`AppSpacing`,
/// `AppRadius`, `Theme`), nunca colores ni tamaños literales.
library;

import 'package:flutter/material.dart';

import '../app/tokens.dart';
import '../core/api/api_failure.dart';
import '../l10n/app_localizations.dart';
import '../l10n/failure_messages.dart';

/// Indicador de carga centrado con etiqueta accesible.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Semantics(
        label: label ?? l10n.splashLoading,
        liveRegion: true,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}

/// Error con mensaje humano y acción de reintento.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry, this.message});

  final Object error;
  final VoidCallback? onRetry;

  /// Mensaje explícito (si no, se deriva de [error]).
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final text = message ?? ApiFailure.from(error).localized(l10n);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: AppSpacing.xxl,
              color: theme.colorScheme.onSurfaceVariant,
              semanticLabel: null,
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.actionRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado vacío: qué pasa, por qué y qué hacer.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.xxl, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Tarjeta de sección con título.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    required this.child,
    this.trailing,
  });

  final String? title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(title!, style: theme.textTheme.titleMedium),
                      ),
                    ),
                    ?trailing,
                  ],
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

/// «Por qué»: lista de explicaciones del motor, plegada por defecto.
class RationaleExpander extends StatefulWidget {
  const RationaleExpander({
    super.key,
    required this.lines,
    this.initiallyExpanded = false,
  });

  final List<String> lines;
  final bool initiallyExpanded;

  @override
  State<RationaleExpander> createState() => _RationaleExpanderState();
}

class _RationaleExpanderState extends State<RationaleExpander> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if (widget.lines.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          style: TextButton.styleFrom(
            minimumSize: const Size(AppSpacing.xxl, AppSpacing.xxl),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          onPressed: () => setState(() => _open = !_open),
          icon: Icon(_open ? Icons.expand_less : Icons.help_outline),
          label: Text(_open ? l10n.actionShowLess : l10n.actionShowMore),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in widget.lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text('• $line', style: theme.textTheme.bodyMedium),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Aviso informativo (no médico, sin conexión...).
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
    this.margin = const EdgeInsets.only(bottom: AppSpacing.md),
  });

  final String text;
  final IconData icon;

  /// Margen exterior; dentro de una tarjeta el último aviso va sin margen
  /// inferior (el relleno de la tarjeta ya separa).
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(AppSpacing.ms),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
