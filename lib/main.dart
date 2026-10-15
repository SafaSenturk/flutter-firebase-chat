import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/notifications.dart';
import 'core/providers.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'data/models.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  await NotificationService.instance.init();
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    retry: (_, _) => null,
    child: const PulseApp(),
  ));
}

class PulseApp extends ConsumerStatefulWidget {
  const PulseApp({super.key});

  @override
  ConsumerState<PulseApp> createState() => _PulseAppState();
}

class _PulseAppState extends ConsumerState<PulseApp> with WidgetsBindingObserver {
  StreamSubscription<String>? _taps;

  /// Newest message time seen per chat, to spot genuinely new messages.
  final _seen = <String, DateTime>{};
  bool _chatsPrimed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _taps = NotificationService.instance.taps.listen(_openChat);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _taps?.cancel();
    super.dispose();
  }

  /// Online/last-seen presence follows the app's lifecycle.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final uid = ref.read(uidProvider);
    if (uid == null) return;
    final online = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed || state == AppLifecycleState.paused) {
      ref.read(chatRepositoryProvider).setPresence(uid, online: online).ignore();
    }
  }

  void _openChat(String chatId) {
    final me = ref.read(uidProvider);
    if (me == null) return;
    final other = chatId.split('_').firstWhere((id) => id != me, orElse: () => me);
    ref.read(routerProvider).push('/chat/$other');
  }

  /// Shows a local notification for an incoming message in a chat that is not
  /// on screen. With the Cloud Function from `functions/` deployed, FCM covers
  /// the app-closed case as well; both use the same id, so nothing doubles up.
  void _onChats(List<Chat> chats) {
    final me = ref.read(uidProvider);
    if (me == null) return;
    final open = ref.read(openChatProvider);
    for (final chat in chats) {
      final last = chat.lastMessage;
      final at = last?.sentAt;
      if (last == null || at == null) continue;
      final previous = _seen[chat.id];
      _seen[chat.id] = at;
      if (!_chatsPrimed || (previous != null && !at.isAfter(previous))) continue;
      if (last.senderId == me || chat.id == open || last.deleted) continue;
      _notify(chat.id, last.senderId, last.text);
    }
    _chatsPrimed = true;
  }

  Future<void> _notify(String chatId, String senderId, String text) async {
    // The sender's profile may not be loaded yet the first time they write.
    final sender = await ref.read(userProvider(senderId).future).catchError((_) => null);
    await NotificationService.instance.showMessage(
      chatId: chatId,
      title: _strings.notificationsTitle(sender?.name ?? ''),
      body: text,
    );
  }

  /// This widget sits above MaterialApp, so there is no Localizations in its
  /// context; resolve the strings from the chosen (or device) language instead.
  AppLocalizations get _strings {
    final code = (ref.read(settingsProvider).locale ?? WidgetsBinding.instance.platformDispatcher.locale).languageCode;
    return lookupAppLocalizations(Locale(code == 'tr' ? 'tr' : 'en'));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    ref.listen(uidProvider, (previous, uid) {
      _seen.clear();
      _chatsPrimed = false;
      if (uid != null) {
        final repo = ref.read(chatRepositoryProvider);
        repo.setPresence(uid, online: true).ignore();
        NotificationService.instance.registerDevice(uid, repo);
      }
    });
    ref.listen(chatsProvider, (_, next) {
      if (next.value case final chats?) _onChats(chats);
    });

    return MaterialApp.router(
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      theme: PulseTheme.light(),
      darkTheme: PulseTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
