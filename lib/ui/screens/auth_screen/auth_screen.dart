import 'package:collab_tasks/features/auth/domain/failures/failure.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:collab_tasks/ui/blocs/auth_bloc/auth_bloc.dart';
import 'package:collab_tasks/ui/blocs/auth_bloc/auth_event.dart';
import 'package:collab_tasks/ui/blocs/auth_bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoginMode = true;
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure ||
          previous.passwordResetEmailSent != current.passwordResetEmailSent,
      listener: (context, state) {
        if (state.failure != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_failureMessage(state.failure!))));
          context.read<AuthBloc>().add(const AuthErrorCleared());
        }

        if (state.passwordResetEmailSent) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(localization.authResetPasswordSent)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(localization.authTitle), centerTitle: true),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment<bool>(value: true, label: Text(localization.authLogin)),
                        ButtonSegment<bool>(value: false, label: Text(localization.authRegister)),
                      ],
                      selected: {_isLoginMode},
                      onSelectionChanged: (value) {
                        setState(() {
                          _isLoginMode = value.first;
                        });
                      },
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _emailController,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      decoration: InputDecoration(
                        labelText: localization.emailTitle,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localization.authEnterEmail;
                        }
                        if (!value.contains('@')) {
                          return localization.authInvalidEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: localization.authPassword,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _isPasswordObscured = !_isPasswordObscured;
                            });
                          },
                          icon: Icon(
                            _isPasswordObscured
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      obscureText: _isPasswordObscured,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localization.authEnterPassword;
                        }
                        if (value.length < 6) {
                          return localization.authPasswordMinLength;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 48),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final loading = state.status == AuthStatus.loading;
                        return FilledButton.icon(
                          onPressed: loading ? null : _onSubmit,
                          icon: const Icon(Icons.lock_open),
                          label: Text(
                            _isLoginMode ? localization.authSignIn : localization.authCreateAccount,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _onGoogleSignIn,
                      icon: const Icon(Icons.g_mobiledata),
                      label: Text(localization.authContinueWithGoogle),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _onResetPassword,
                      child: Text(localization.authForgotPassword),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              localization.authResetHint,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final bloc = context.read<AuthBloc>();

    if (_isLoginMode) {
      bloc.add(AuthLoginRequested(email: email, password: password));
      return;
    }

    bloc.add(AuthRegisterRequested(email: email, password: password));
  }

  void _onGoogleSignIn() {
    context.read<AuthBloc>().add(const AuthGoogleSignInRequested());
  }

  void _onResetPassword() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      final localization = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localization.authEnterValidEmailToReset)));
      return;
    }

    context.read<AuthBloc>().add(AuthResetPasswordRequested(email));
  }

  String _failureMessage(Failure failure) => failure.message;
}
