import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@immutable
class PulseColors extends ThemeExtension<PulseColors> {
  const PulseColors({
    required this.muted,
    required this.inkSoft,
    required this.border,
    required this.bubbleOther,
    required this.online,
  });

  final Color muted;
  final Color inkSoft;
  final Color border;
  final Color bubbleOther;
  final Color online;

  static const light = PulseColors(
    muted: Color(0xFFE9EFEE),
    inkSoft: Color(0xFF5F6F75),
    border: Color(0xFFDDE5E4),
    bubbleOther: Colors.white,
    online: Color(0xFF22C55E),
  );

  static const dark = PulseColors(
    muted: Color(0xFF1B272C),
    inkSoft: Color(0xFF8FA3A9),
    border: Color(0xFF243238),
    bubbleOther: Color(0xFF1A262B),
    online: Color(0xFF34D399),
  );

  @override
  PulseColors copyWith() => this;

  @override
  PulseColors lerp(PulseColors? other, double t) => other == null
      ? this
      : PulseColors(
          muted: Color.lerp(muted, other.muted, t)!,
          inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
          border: Color.lerp(border, other.border, t)!,
          bubbleOther: Color.lerp(bubbleOther, other.bubbleOther, t)!,
          online: Color.lerp(online, other.online, t)!,
        );
}

extension ThemeX on BuildContext {
  PulseColors get pulse => Theme.of(this).extension<PulseColors>()!;
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

abstract final class PulseTheme {
  static const accent = Color(0xFF0FB9A0);
  static const accent2 = Color(0xFF12A4C9);
  static const brandGradient = LinearGradient(
    colors: [accent, accent2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Avatar backgrounds the user can choose from.
  static const avatarGradients = [
    [Color(0xFF0FB9A0), Color(0xFF12A4C9)],
    [Color(0xFFFF7A59), Color(0xFFFF4D8D)],
    [Color(0xFF7C5CFF), Color(0xFF4F7BFF)],
    [Color(0xFFFFB020), Color(0xFFFF7A1A)],
    [Color(0xFF22C55E), Color(0xFF9BD93B)],
    [Color(0xFF3B82F6), Color(0xFF38BDF8)],
  ];

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final tokens = dark ? PulseColors.dark : PulseColors.light;
    final bg = dark ? const Color(0xFF0B1215) : const Color(0xFFF4F7F6);
    final surface = dark ? const Color(0xFF131D21) : Colors.white;
    final ink = dark ? const Color(0xFFE8F1F2) : const Color(0xFF0F1A1C);

    final scheme = ColorScheme(
      brightness: b,
      primary: accent,
      onPrimary: Colors.white,
      secondary: accent2,
      onSecondary: Colors.white,
      error: const Color(0xFFE5484D),
      onError: Colors.white,
      surface: surface,
      onSurface: ink,
      surfaceContainerHighest: tokens.muted,
      outline: tokens.border,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Figtree',
      extensions: [tokens],
    );
    final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    const btnText = TextStyle(fontFamily: 'Figtree', fontWeight: FontWeight.w700, fontSize: 16);

    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        titleTextStyle: TextStyle(fontFamily: 'Figtree', fontSize: 24, fontWeight: FontWeight.w800, color: ink),
        systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: rounded, textStyle: btnText),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: rounded,
          textStyle: btnText,
          foregroundColor: ink,
          side: BorderSide(color: tokens.border, width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: tokens.border)),
        enabledBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: tokens.border)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accent, width: 1.6),
        ),
        hintStyle: TextStyle(color: tokens.inkSoft),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: rounded,
        backgroundColor: dark ? const Color(0xFF243238) : ink,
        contentTextStyle: TextStyle(fontFamily: 'Figtree', color: dark ? ink : Colors.white, fontWeight: FontWeight.w600),
      ),
      dividerTheme: DividerThemeData(color: tokens.border, thickness: 1, space: 1),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      }),
    );
  }
}
