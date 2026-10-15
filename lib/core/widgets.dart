import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/auth_repository.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

extension L10nX on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this);
  String get lang => Localizations.localeOf(this).languageCode;

  /// "14:05", "Yesterday", "Mon" or "12.03.26" depending on how old [t] is.
  String chatTime(DateTime? t) {
    if (t == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return DateFormat.Hm(lang).format(t);
    if (diff == 1) return l.yesterday;
    if (diff < 7) return DateFormat.E(lang).format(t);
    return DateFormat.yMd(lang).format(t);
  }

  String dayLabel(DateTime t) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day).difference(DateTime(t.year, t.month, t.day)).inDays;
    if (diff == 0) return l.today;
    if (diff == 1) return l.yesterday;
    return DateFormat.yMMMMd(lang).format(t);
  }

  String presence(AppUser user) {
    if (user.online) return l.online;
    final seen = user.lastSeen;
    if (seen == null) return '';
    final diff = DateTime.now().difference(seen);
    final time = diff.inDays == 0 ? DateFormat.Hm(lang).format(seen) : chatTime(seen);
    return l.lastSeen(time);
  }

  String authError(Object error) {
    final kind = error is AuthFailure ? error.kind : AuthErrorKind.unknown;
    return switch (kind) {
      AuthErrorKind.invalidCredentials => l.errorInvalidCredentials,
      AuthErrorKind.emailInUse => l.errorEmailInUse,
      AuthErrorKind.weakPassword => l.errorWeakPassword,
      AuthErrorKind.invalidEmail => l.errorInvalidEmail,
      AuthErrorKind.tooManyRequests => l.errorTooManyRequests,
      AuthErrorKind.network => l.errorNetwork,
      AuthErrorKind.cancelled || AuthErrorKind.unknown => l.errorUnknown,
    };
  }
}

/// Initials on the user's chosen gradient, with an optional online dot.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.user, this.size = 48, this.showOnline = true});

  final AppUser? user;
  final double size;
  final bool showOnline;

  @override
  Widget build(BuildContext context) {
    final u = user;
    final colors = PulseTheme.avatarGradients[(u?.colorIndex ?? 0) % PulseTheme.avatarGradients.length];
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Text(
              u?.initials ?? '',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * .38),
            ),
          ),
          if (showOnline && (u?.online ?? false))
            Positioned(
              right: -1,
              bottom: -1,
              child: OnlineDot(size: size * .3),
            ),
        ],
      ),
    );
  }
}

/// Green dot that gently pulses — the app's namesake.
class OnlineDot extends StatefulWidget {
  const OnlineDot({super.key, this.size = 14});

  final double size;

  @override
  State<OnlineDot> createState() => _OnlineDotState();
}

class _OnlineDotState extends State<OnlineDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.pulse.online;
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.scale(
              scale: 1 + _c.value * .9,
              child: Container(
                decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: .45 * (1 - _c.value))),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body, this.action});

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: PulseTheme.brandGradient),
                child: Icon(icon, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 22),
              Text(title, textAlign: TextAlign.center, style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center, style: TextStyle(color: context.pulse.inkSoft, height: 1.45)),
              if (action != null) ...[const SizedBox(height: 22), action!],
            ],
          ),
        ),
      );
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: context.pulse.inkSoft),
            const SizedBox(height: 12),
            Text(context.l.errorLoad),
            TextButton(onPressed: onRetry, child: Text(context.l.retry)),
          ],
        ),
      );
}
