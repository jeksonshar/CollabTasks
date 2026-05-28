import 'package:collab_tasks/core/utils/auth_utils.dart';
import 'package:collab_tasks/features/auth/domain/failures/failure.dart';
import 'package:collab_tasks/l10n/app_localizations.dart';
import 'package:collab_tasks/ui/blocs/auth_bloc/auth_bloc.dart';
import 'package:collab_tasks/ui/blocs/auth_bloc/auth_event.dart';
import 'package:collab_tasks/ui/blocs/auth_bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationCodeController = TextEditingController();
  final _resetCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoginMode = true;
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationCodeController.dispose();
    _resetCodeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure ||
          previous.passwordResetEmailSent != current.passwordResetEmailSent ||
          previous.passwordResetConfirmed != current.passwordResetConfirmed ||
          previous.signUpCodeResent != current.signUpCodeResent ||
          previous.signUpConfirmed != current.signUpConfirmed,
      listener: (context, state) {
        if (state.requiresSignUpConfirmation && _isLoginMode) {
          setState(() {
            _isLoginMode = false;
          });
        }

        if (state.failure != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_failureMessage(state.failure!, localization))));
          context.read<AuthBloc>().add(const AuthErrorCleared());
        }

        if (state.passwordResetEmailSent) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(localization.authResetPasswordSent)));
        }

        if (state.passwordResetConfirmed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localization.authPasswordUpdated)),
          );
        }

        if (state.signUpCodeResent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localization.authVerificationCodeResent)),
          );
        }

        if (state.signUpConfirmed) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(localization.authAccountConfirmed)));
          setState(() {
            _isLoginMode = true;
          });
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
                    const SizedBox(height: 8),
                    Visibility(
                      visible: _isLoginMode,
                      // Maintains the widget's dimensions when it is hidden.
                      maintainSize: true,
                      // Required for maintainSize to work
                      maintainAnimation: true,
                      // Saves the widget's state
                      maintainState: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _onResetPassword,
                            child: Text(
                              localization.authForgotPassword,
                              style: const TextStyle(color: Colors.indigo),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (authBackend == AuthBackend.aws)
                      BlocBuilder<AuthBloc, AuthState>(
                        buildWhen: (previous, current) =>
                            previous.requiresSignUpConfirmation !=
                                current.requiresSignUpConfirmation ||
                            previous.pendingConfirmationEmail != current.pendingConfirmationEmail,
                        builder: (context, state) {
                          return _buildSignUpConfirmationFields(state, localization);
                        },
                      ),
                    if (authBackend == AuthBackend.aws)
                      BlocBuilder<AuthBloc, AuthState>(
                        buildWhen: (previous, current) =>
                            previous.requiresResetPasswordConfirmation !=
                                current.requiresResetPasswordConfirmation ||
                            previous.pendingResetPasswordEmail != current.pendingResetPasswordEmail,
                        builder: (context, state) {
                          return _buildResetPasswordConfirmationFields(state, localization);
                        },
                      ),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final loading = state.status == AuthStatus.loadingFormSubmit;
                        return _buildSubmitButton(loading, localization);
                      },
                    ),
                    const SizedBox(height: 32),
                    _buildAuthDivider(context),
                    const SizedBox(height: 32),
                    _buildGoogleSignInButton(context),
                    const SizedBox(height: 16),
                    _buildResetHint(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpConfirmationFields(AuthState state, AppLocalizations localization) {
    final visible = state.requiresSignUpConfirmation;
    final pendingEmail = state.pendingConfirmationEmail ?? _emailController.text.trim();

    return Visibility(
      visible: visible,
      maintainState: true,
      child: Column(
        children: [
          TextFormField(
            controller: _confirmationCodeController,
            decoration: InputDecoration(
              labelText: localization.authVerificationCodeLabel(pendingEmail),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _onConfirmSignUp,
                  child: Text(localization.authConfirmSignUp),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _onResendSignUpCode,
                  child: Text(localization.authResendCode),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildResetPasswordConfirmationFields(AuthState state, AppLocalizations localization) {
    final visible = state.requiresResetPasswordConfirmation;
    final pendingEmail = state.pendingResetPasswordEmail ?? _emailController.text.trim();

    return Visibility(
      visible: visible,
      maintainState: true,
      child: Column(
        children: [
          const SizedBox(height: 12),
          TextFormField(
            controller: _resetCodeController,
            decoration: InputDecoration(
              labelText: localization.authResetCodeLabel(pendingEmail),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _newPasswordController,
            decoration: InputDecoration(
              labelText: localization.authNewPasswordLabel,
              border: const OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _onConfirmResetPassword,
              child: Text(localization.authConfirmResetPassword),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isLoading, AppLocalizations localization) {
    if (isLoading) {
      return const Center(
        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A06FA), Color(0xFFB794FF), Color(0xFF4A06FA)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: FilledButton.icon(
        onPressed: _onSubmit,
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        label: Text(_isLoginMode ? localization.authSignIn : localization.authCreateAccount),
      ),
    );
  }

  Widget _buildAuthDivider(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: SvgPicture.asset('assets/icon/auth_divider.svg', width: 32, height: 2)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            // A small indent around the "or" text to prevent the dashes from sticking together
            child: Text(localization.orTitle),
          ),
          Expanded(child: SvgPicture.asset('assets/icon/auth_divider.svg', width: 32, height: 2)),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A06FA), Color(0xFFCBAEFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(1.5),
      child: OutlinedButton.icon(
        onPressed: _onGoogleSignIn,
        icon: SvgPicture.asset('assets/icon/ic_google_logo.svg', width: 24, height: 24),
        label: Text(localization.authContinueWithGoogle),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              22.5,
            ), // 22.5 = 24 - 1.5 container thicknesses, everything is calculated correctly
          ),
          foregroundColor: Colors.black87,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildResetHint(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Container(
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
            child: Text(localization.authResetHint, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
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

  void _onConfirmSignUp() {
    final state = context.read<AuthBloc>().state;
    final email = state.pendingConfirmationEmail ?? _emailController.text.trim();
    final code = _confirmationCodeController.text.trim();
    final localization = AppLocalizations.of(context)!;

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localization.authErrorEnterValidEmail)));
      return;
    }

    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localization.authErrorEnterVerificationCode)));
      return;
    }

    context.read<AuthBloc>().add(AuthConfirmSignUpRequested(email: email, code: code));
  }

  void _onResendSignUpCode() {
    final state = context.read<AuthBloc>().state;
    final email = state.pendingConfirmationEmail ?? _emailController.text.trim();
    final localization = AppLocalizations.of(context)!;
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localization.authErrorEnterValidEmail)));
      return;
    }

    context.read<AuthBloc>().add(AuthResendSignUpCodeRequested(email));
  }

  void _onConfirmResetPassword() {
    final state = context.read<AuthBloc>().state;
    final email = state.pendingResetPasswordEmail ?? _emailController.text.trim();
    final code = _resetCodeController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final localization = AppLocalizations.of(context)!;

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localization.authErrorEnterValidEmail)));
      return;
    }
    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localization.authErrorEnterResetCode)));
      return;
    }
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localization.authErrorNewPasswordTooShort)));
      return;
    }

    context.read<AuthBloc>().add(
      AuthConfirmResetPasswordRequested(email: email, code: code, newPassword: newPassword),
    );
  }

  String _failureMessage(Failure failure, AppLocalizations localization) {
    if (failure is WrongPasswordFailure) {
      return localization.authErrorWrongPassword;
    }
    if (failure is UserNotFoundFailure) {
      return localization.authErrorUserNotFound;
    }
    if (failure is NetworkFailure) {
      return localization.authErrorNetwork;
    }
    if (failure is ActionCodeExpiredFailure) {
      return localization.authErrorActionCodeExpired;
    }
    if (failure is EmailAlreadyInUseFailure) {
      return localization.authErrorEmailAlreadyInUse;
    }
    if (failure is InvalidEmailFailure) {
      return localization.authErrorInvalidEmail;
    }
    if (failure is WeakPasswordFailure) {
      return localization.authErrorWeakPassword;
    }
    if (failure is TooManyRequestsFailure) {
      return localization.authErrorTooManyRequests;
    }
    if (failure is UserDisabledFailure) {
      return localization.authErrorUserDisabled;
    }
    if (failure is EmailNotVerifiedFailure) {
      if (failure.message.contains('Confirm email')) {
        return localization.authErrorEmailNotVerifiedConfirmEmail;
      }
      if (failure.message.contains('Verification email sent')) {
        return localization.authErrorEmailNotVerifiedSent;
      }
      return localization.authErrorEmailNotVerified;
    }
    if (failure is InvalidCredentialFailure) {
      return localization.authErrorInvalidCredential;
    }
    if (failure is OperationNotAllowedFailure) {
      if (failure.message.contains('Reset password')) {
        return localization.authErrorResetNotAvailable;
      }
      if (failure.message.contains('Google Sign-in')) {
        return localization.authErrorGoogleSignInNotSupported;
      }
      return localization.authErrorOperationNotAllowed;
    }
    if (failure is NoPasswordProviderFailure) {
      if (failure.message.contains('reset is required')) {
        return localization.authErrorPasswordResetRequired;
      }
      return localization.authErrorNoPasswordProvider;
    }
    if (failure is CanceledByUserFailure) {
      return localization.authErrorCanceledByUser;
    }
    if (failure is UnknownAuthFailure) {
      if (failure.message.contains('Confirmation is not complete')) {
        return localization.authErrorConfirmationNotComplete;
      }
      return localization.authErrorUnknown;
    }
    return failure.message;
  }
}
