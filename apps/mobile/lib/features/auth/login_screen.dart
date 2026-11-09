import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'auth_provider.dart';
import 'widgets/auth_form_parts.dart';

/// Pantalla de login. La navegación tras autenticarse la hace el router
/// (redirect + refreshListenable), no esta pantalla.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final error = authState.error;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.appTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  TextFormField(
                    key: const Key('login-email'),
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: l10n.fieldEmail,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    validator: (v) => AuthValidators.email(l10n, v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const Key('login-password'),
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: l10n.fieldPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) => v == null || v.isEmpty
                        ? l10n.validationPasswordRequired
                        : null,
                  ),
                  if (error != null) AuthErrorText(error: error),
                  const SizedBox(height: AppSpacing.lg),
                  AuthSubmitButton(
                    key: const Key('login-submit'),
                    label: l10n.loginSubmit,
                    isLoading: authState.isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.ms),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.register),
                    child: Text(l10n.loginGoToRegister),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
