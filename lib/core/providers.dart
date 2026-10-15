import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/auth_repository.dart';
import '../data/chat_repository.dart';
import '../data/models.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((_) => throw UnimplementedError());

final authRepositoryProvider = Provider<AuthRepository>(
  (_) => AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance),
);

final chatRepositoryProvider = Provider<ChatRepository>((_) => ChatRepository(FirebaseFirestore.instance));

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// The signed-in user's id, or null when signed out.
final uidProvider = Provider<String?>((ref) => ref.watch(authStateProvider).value?.uid);

final userProvider = StreamProvider.family<AppUser?, String>(
  (ref, uid) => ref.watch(chatRepositoryProvider).watchUser(uid),
);

final meProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(chatRepositoryProvider).watchUser(uid);
});

final chatsProvider = StreamProvider<List<Chat>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(chatRepositoryProvider).watchChats(uid);
});

final chatProvider = StreamProvider.autoDispose.family<Chat?, String>(
  (ref, chatId) => ref.watch(chatRepositoryProvider).watchChat(chatId),
);

final messagesProvider = StreamProvider.autoDispose.family<List<Message>, String>(
  (ref, chatId) => ref.watch(chatRepositoryProvider).watchMessages(chatId),
);

class PeopleSearch extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final peopleSearchProvider = NotifierProvider<PeopleSearch, String>(PeopleSearch.new);

final peopleProvider = StreamProvider.autoDispose<List<AppUser>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(chatRepositoryProvider).watchPeople(exceptUid: uid, search: ref.watch(peopleSearchProvider));
});

/// The chat currently on screen, so we don't notify about messages the user is reading.
class OpenChat extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? chatId) => state = chatId;
}

final openChatProvider = NotifierProvider<OpenChat, String?>(OpenChat.new);

@immutable
class AppSettings {
  const AppSettings({this.locale, this.themeMode = ThemeMode.system});

  final Locale? locale;
  final ThemeMode themeMode;
}

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final code = prefs.getString('locale');
    return AppSettings(
      locale: code == null ? null : Locale(code),
      themeMode: ThemeMode.values.asNameMap()[prefs.getString('theme')] ?? ThemeMode.system,
    );
  }

  void setLocale(Locale l) {
    state = AppSettings(locale: l, themeMode: state.themeMode);
    ref.read(sharedPreferencesProvider).setString('locale', l.languageCode);
  }

  void setThemeMode(ThemeMode m) {
    state = AppSettings(locale: state.locale, themeMode: m);
    ref.read(sharedPreferencesProvider).setString('theme', m.name);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
