import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Brand header with expanding "pulse" rings around the logo.
class PulseLogo extends StatefulWidget {
  const PulseLogo({super.key, this.size = 92});

  final double size;

  @override
  State<PulseLogo> createState() => _PulseLogoState();
}

class _PulseLogoState extends State<PulseLogo> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox.square(
      dimension: s * 2,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Builder(builder: (context) {
                final t = (_c.value + i / 3) % 1;
                return Container(
                  width: s * (1 + t),
                  height: s * (1 + t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: PulseTheme.accent.withValues(alpha: (1 - t) * .5), width: 2),
                  ),
                );
              }),
            child!,
          ],
        ),
        child: Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: PulseTheme.brandGradient,
            boxShadow: [BoxShadow(color: PulseTheme.accent.withValues(alpha: .4), blurRadius: 30, offset: const Offset(0, 12))],
          ),
          child: Icon(Icons.forum_rounded, color: Colors.white, size: s * .46),
        ),
      ),
    );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, required this.subtitle, required this.children, this.showBack = false});

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: showBack ? AppBar() : null,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: PulseLogo(size: 76)),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.5),
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: context.pulse.inkSoft, height: 1.4)),
                    const SizedBox(height: 28),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed, required this.loading});

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: loading ? null : onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4))
            else
              const _GoogleG(),
            const SizedBox(width: 12),
            Text(context.l.continueWithGoogle),
          ],
        ),
      );
}

/// The four-colour "G", drawn so no image asset is needed.
class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) => const SizedBox.square(dimension: 20, child: CustomPaint(painter: _GPainter()));
}

class _GPainter extends CustomPainter {
  const _GPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(size.width * .1, size.height * .1, size.width * .8, size.height * .8);
    final w = size.width * .2;
    Paint p(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;
    const deg = 3.14159265 / 180;
    canvas.drawArc(r, -40 * deg, -100 * deg, false, p(const Color(0xFFEA4335)));
    canvas.drawArc(r, -140 * deg, -90 * deg, false, p(const Color(0xFFFBBC05)));
    canvas.drawArc(r, -230 * deg, -95 * deg, false, p(const Color(0xFF34A853)));
    canvas.drawArc(r, 25 * deg, -65 * deg, false, p(const Color(0xFF4285F4)));
    canvas.drawRect(
      Rect.fromLTWH(size.width * .5, size.height * .5 - w / 2, size.width * .4, w),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(context.l.or, style: TextStyle(color: context.pulse.inkSoft)),
            ),
            const Expanded(child: Divider()),
          ],
        ),
      );
}

final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

void showError(BuildContext context, String message) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(message), backgroundColor: context.scheme.error));
