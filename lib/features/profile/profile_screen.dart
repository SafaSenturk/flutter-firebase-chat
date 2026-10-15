import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _about = TextEditingController();
  int? _color;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _about.dispose();
    super.dispose();
  }

  void _load(AppUser me) {
    if (_loaded) return;
    _loaded = true;
    _name.text = me.name;
    _about.text = me.about;
    _color = me.colorIndex;
  }

  Future<void> _save(AppUser me) async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(chatRepositoryProvider).updateProfile(
            me.uid,
            name: _name.text,
            about: _about.text,
            colorIndex: _color ?? me.colorIndex,
          );
      if (mounted) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l.profileSaved)));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l.errorUnknown)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut(String uid) async {
    final repo = ref.read(chatRepositoryProvider);
    await NotificationService.instance.unregisterDevice(uid, repo);
    try {
      await repo.setPresence(uid, online: false);
    } catch (_) {}
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final me = ref.watch(meProvider).value;
    final settings = ref.watch(settingsProvider);
    if (me == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    _load(me);
    final preview = AppUser(
      uid: me.uid,
      name: _name.text.isEmpty ? me.name : _name.text,
      email: me.email,
      colorIndex: _color ?? me.colorIndex,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.profile)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Center(child: Avatar(user: preview, size: 112, showOnline: false)),
          const SizedBox(height: 10),
          Center(child: Text(me.email, style: TextStyle(color: context.pulse.inkSoft))),
          const SizedBox(height: 22),
          Text(l.avatarColor, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < PulseTheme.avatarGradients.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _color = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: PulseTheme.avatarGradients[i]),
                      border: Border.all(
                        color: (_color ?? me.colorIndex) == i ? context.scheme.onSurface : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: (_color ?? me.colorIndex) == i
                        ? const Icon(Icons.check_rounded, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _name,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l.fullName, prefixIcon: const Icon(Icons.person_outline_rounded)),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _about,
            maxLength: 120,
            decoration: InputDecoration(
              labelText: l.about,
              hintText: l.aboutHint,
              prefixIcon: const Icon(Icons.info_outline_rounded),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _saving ? null : () => _save(me),
            child: _saving
                ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : Text(l.save),
          ),
          const SizedBox(height: 28),
          Text(l.language, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'tr', label: Text('🇹🇷  Türkçe')),
              ButtonSegment(value: 'en', label: Text('🇬🇧  English')),
            ],
            selected: {context.lang},
            onSelectionChanged: (s) => ref.read(settingsProvider.notifier).setLocale(Locale(s.first)),
          ),
          const SizedBox(height: 20),
          Text(l.theme, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: ThemeMode.system, label: Text(l.themeSystem)),
              ButtonSegment(value: ThemeMode.light, label: Text(l.themeLight)),
              ButtonSegment(value: ThemeMode.dark, label: Text(l.themeDark)),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => ref.read(settingsProvider.notifier).setThemeMode(s.first),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: context.scheme.error),
            onPressed: () => _signOut(me.uid),
            icon: const Icon(Icons.logout_rounded),
            label: Text(l.signOut),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(l.poweredBy, style: TextStyle(color: context.pulse.inkSoft, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
