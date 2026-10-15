import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/auth_repository.dart';
import 'auth_widgets.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _googleBusy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, {bool google = false}) async {
    setState(() => google ? _googleBusy = true : _busy = true);
    try {
      await action();
    } on AuthFailure catch (e) {
      if (mounted && e.kind != AuthErrorKind.cancelled) showError(context, context.authError(e));
    } catch (e) {
      if (mounted) showError(context, context.authError(e));
    } finally {
      if (mounted) setState(() => _busy = _googleBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final auth = ref.read(authRepositoryProvider);
    return AuthScaffold(
      title: l.appName,
      subtitle: l.tagline,
      children: [
        Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(hintText: l.email, prefixIcon: const Icon(Icons.alternate_email_rounded)),
                validator: (v) => emailPattern.hasMatch(v?.trim() ?? '') ? null : l.validationEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(auth),
                decoration: InputDecoration(
                  hintText: l.password,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
                ),
                validator: (v) => (v ?? '').length < 6 ? l.validationPasswordLength : null,
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: () => context.push('/forgot'), child: Text(l.forgotPassword)),
        ),
        const SizedBox(height: 4),
        _GradientButton(
          label: l.signIn,
          loading: _busy,
          onPressed: () => _submit(auth),
        ),
        const OrDivider(),
        GoogleButton(loading: _googleBusy, onPressed: () => _run(auth.signInWithGoogle, google: true)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l.noAccount, style: TextStyle(color: context.pulse.inkSoft)),
            TextButton(onPressed: () => context.push('/sign-up'), child: Text(l.signUp)),
          ],
        ),
      ],
    );
  }

  void _submit(AuthRepository auth) {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _run(() => auth.signIn(email: _email.text, password: _password.text));
  }
}

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).signUp(name: _name.text, email: _email.text, password: _password.text);
      // The router redirects to the chat list once the auth state changes.
    } catch (e) {
      if (mounted) showError(context, context.authError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AuthScaffold(
      title: l.signUp,
      subtitle: l.tagline,
      showBack: true,
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 40,
                decoration: InputDecoration(
                  hintText: l.fullName,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  counterText: '',
                ),
                validator: (v) => (v?.trim().isEmpty ?? true) ? l.validationRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(hintText: l.email, prefixIcon: const Icon(Icons.alternate_email_rounded)),
                validator: (v) => emailPattern.hasMatch(v?.trim() ?? '') ? null : l.validationEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(hintText: l.password, prefixIcon: const Icon(Icons.lock_outline_rounded)),
                validator: (v) => (v ?? '').length < 6 ? l.validationPasswordLength : null,
              ),
              const SizedBox(height: 10),
              _StrengthMeter(password: _password.text),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                onFieldSubmitted: (_) => _submit(),
                decoration:
                    InputDecoration(hintText: l.confirmPassword, prefixIcon: const Icon(Icons.lock_reset_rounded)),
                validator: (v) => v != _password.text ? l.validationPasswordMatch : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _GradientButton(label: l.signUp, loading: _busy, onPressed: _submit),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l.haveAccount, style: TextStyle(color: context.pulse.inkSoft)),
            TextButton(onPressed: () => context.pop(), child: Text(l.signIn)),
          ],
        ),
      ],
    );
  }
}

/// 0..3 based on length, digits, mixed case and symbols.
int passwordScore(String p) {
  if (p.length < 6) return 0;
  var score = 1;
  if (p.length >= 10) score++;
  if (RegExp(r'\d').hasMatch(p) && RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
  return score.clamp(0, 3);
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final score = passwordScore(password);
    final colors = [context.scheme.error, const Color(0xFFFFB020), PulseTheme.accent];
    final labels = [context.l.passwordWeak, context.l.passwordOk, context.l.passwordStrong];
    final level = score <= 1 ? 0 : score == 2 ? 1 : 2;
    return Row(
      children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 5,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: i <= level ? colors[level] : context.pulse.muted,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        const SizedBox(width: 6),
        Text(labels[level], style: TextStyle(color: colors[level], fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  String? _sentTo;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      setState(() => _sentTo = _email.text.trim());
    } catch (e) {
      if (mounted) showError(context, context.authError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AuthScaffold(
      title: l.resetPassword,
      subtitle: l.resetPasswordBody,
      showBack: true,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _sentTo != null
              ? Container(
                  key: const ValueKey('sent'),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PulseTheme.accent.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_read_rounded, color: PulseTheme.accent),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l.resetSent(_sentTo!))),
                    ],
                  ),
                )
              : Form(
                  key: _form,
                  child: TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(hintText: l.email, prefixIcon: const Icon(Icons.alternate_email_rounded)),
                    validator: (v) => emailPattern.hasMatch(v?.trim() ?? '') ? null : l.validationEmail,
                  ),
                ),
        ),
        const SizedBox(height: 20),
        if (_sentTo == null)
          _GradientButton(label: l.sendResetLink, loading: _busy, onPressed: _send)
        else
          OutlinedButton(onPressed: () => context.pop(), child: Text(l.backToSignIn)),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onPressed, this.loading = false});

  final String label;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: PulseTheme.brandGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: PulseTheme.accent.withValues(alpha: .35), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
          onPressed: loading ? null : onPressed,
          child: loading
              ? const SizedBox.square(
                  dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
              : Text(label),
        ),
      );
}
