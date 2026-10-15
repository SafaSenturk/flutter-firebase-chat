<div align="center">

<img src="docs/banner.png" alt="Pulse – Flutter Firebase chat app" width="100%" />

# Pulse · Flutter + Firebase Chat

A real-time messaging app with a complete Firebase backend: email and Google sign-in, live one-to-one chats in Cloud Firestore, typing indicators, read receipts, reactions, presence, push notifications and tested security rules.

[![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20·%20Firestore%20·%20FCM-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![State](https://img.shields.io/badge/state-Riverpod%203-6C3BFF)](https://riverpod.dev)
[![CI](https://github.com/SafaSenturk/flutter-firebase-chat/actions/workflows/ci.yml/badge.svg)](https://github.com/SafaSenturk/flutter-firebase-chat/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

**[⬇️ Download the APK](https://github.com/SafaSenturk/flutter-firebase-chat/releases/latest)** · [🇹🇷 Türkçe açıklama](#-türkçe)

</div>

---

## Demo

<p align="center">
  <img src="docs/demo.gif" alt="Sending a message, seeing the other person type, read receipts and a reaction" width="300" />
</p>

<p align="center"><i>Send → the other side reads it (✓✓) → "typing…" → reply arrives → reaction — all live through Firestore.</i></p>

## Features

**Authentication (Firebase Auth)**
- Email & password sign-up / sign-in with validation and a password strength meter
- **Google Sign-In** (Credential Manager on Android)
- Password reset by email, sign out
- Friendly messages for every Auth error (wrong password, email in use, no network…)

**Chat (Cloud Firestore, real time)**
- Chat list ordered by latest activity, with **unread badges** and live previews
- **Typing indicator** (in the list and inside the chat), **online / last seen** presence
- **Read receipts:** sending ⏱ → sent ✓ → read ✓✓
- Long-press a message to **react** (❤️ 😂 👍 😮 😢 🔥), **copy**, **edit** or **delete**
- Day separators, grouped bubbles, smooth enter animations
- Works offline: Firestore's cache shows history and queues messages until the connection is back

**Notifications (FCM)**
- Device tokens are registered per user; tapping a notification **opens the right chat**
- In-app notifications for messages in other chats
- A ready-to-deploy **Cloud Function** ([`functions/index.js`](functions/index.js)) pushes every new message to the recipient's devices and cleans up stale tokens

**Backend quality**
- **Security rules** ([`firestore.rules`](firestore.rules)): users only write their own profile; only the two members can see a chat; messages must be sent as yourself, 1–2000 chars; the recipient can only mark read / react
- **12 rule tests** with the Firebase Emulator ([`rules-tests/`](rules-tests/rules.test.js)), run in CI
- Composite index for the chat list in [`firestore.indexes.json`](firestore.indexes.json)
- The Android API key is restricted to this app's package and signing certificates

**App**
- People directory with name search
- Profile: name, about, avatar colour, **Turkish / English**, **light / dark** theme

## Screenshots

| Sign in | Sign up | Reset password | Chats |
|:---:|:---:|:---:|:---:|
| <img src="docs/screenshots/01_sign_in.jpg" width="200"/> | <img src="docs/screenshots/02_sign_up.jpg" width="200"/> | <img src="docs/screenshots/03_forgot.jpg" width="200"/> | <img src="docs/screenshots/04_chats.jpg" width="200"/> |
| **Conversation** | **Typing indicator** | **React · edit · delete** | **People** |
| <img src="docs/screenshots/05_conversation.jpg" width="200"/> | <img src="docs/screenshots/06_typing.jpg" width="200"/> | <img src="docs/screenshots/07_actions.jpg" width="200"/> | <img src="docs/screenshots/08_people.jpg" width="200"/> |
| **Profile** | **Push notifications** | **Dark · Turkish** | **Dark · Turkish** |
| <img src="docs/screenshots/09_profile.jpg" width="200"/> | <img src="docs/screenshots/10_notifications.jpg" width="200"/> | <img src="docs/screenshots/11_dark_tr_chats.jpg" width="200"/> | <img src="docs/screenshots/12_dark_tr_chat.jpg" width="200"/> |

## Tech stack

| Area | Choice |
|---|---|
| App | Flutter 3.44, Material 3, Riverpod 3 (`StreamProvider`, `Notifier`), go_router with auth redirect |
| Auth | `firebase_auth` (email/password, Google via `google_sign_in` 7) |
| Database | `cloud_firestore` with real-time snapshots, batched writes, `FieldValue.increment` / `serverTimestamp` |
| Push | `firebase_messaging` + `flutter_local_notifications`; Cloud Functions v2 (Node 22) |
| Security | Firestore rules + `@firebase/rules-unit-testing` on the emulator |
| Localization | ARB files + `gen-l10n`, Turkish & English |
| CI | GitHub Actions: `flutter analyze`, `flutter test`, security-rule tests |

## Data model

```
users/{uid}
  name, nameLower, email, about, colorIndex, online, lastSeen, fcmTokens[]

chats/{uidA_uidB}                     ← id = the two user ids, sorted
  members[2], updatedAt
  lastMessage { text, senderId, sentAt, deleted }
  unread { uid: count }               ← incremented by the sender, reset by the reader
  typing { uid: timestamp }           ← "typing…" = pinged in the last few seconds

chats/{chatId}/messages/{id}
  senderId, text, sentAt, readAt, editedAt, deleted, reactions { uid: emoji }
```

Sending a message is **one batched write**: the message plus the chat summary (last message, unread counter, typing cleared). The first message creates the chat in the same batch, which the rules allow through `getAfter()`.

## Project structure

```
lib/
├── main.dart                 # Firebase init, presence, in-app notifications
├── firebase_options.dart
├── core/                     # providers, router, theme, notifications, shared widgets
├── data/                     # models, AuthRepository, ChatRepository
├── features/
│   ├── auth/                 # sign in, sign up, reset password
│   ├── chats/                # chat list
│   ├── chat/                 # conversation, bubbles, composer, actions
│   ├── people/               # user directory
│   └── profile/              # profile, language, theme, sign out
└── l10n/                     # app_en.arb, app_tr.arb
functions/                    # Cloud Function: push on new message
rules-tests/                  # Firestore rules tests (emulator)
firestore.rules · firestore.indexes.json · firebase.json
```

## Run it yourself

```bash
git clone https://github.com/SafaSenturk/flutter-firebase-chat.git
cd flutter-firebase-chat
flutter pub get
flutter run
```

The repo points at the demo Firebase project. To use your own: create a project, enable Email/Password and Google sign-in, run `flutterfire configure`, then `firebase deploy --only firestore` (and `--only functions` on the Blaze plan for server-side pushes).

```bash
flutter test                         # unit tests
cd rules-tests && npm ci && npm test # security rules on the emulator (needs Java)
```

> **Trying the APK:** create an account (any email works for sign-up), then open **People** to start a chat. To see real-time messaging, install it on a second phone — or share it with a friend.

---

## 🇹🇷 Türkçe

**Pulse**, Firebase üzerinde çalışan, uçtan uca gerçek zamanlı bir mesajlaşma uygulamasıdır. "Backend'i de hallederim" sorusunun cevabı.

**Neler var?**
- E-posta/şifre ile kayıt ve giriş, **Google ile giriş**, şifre sıfırlama e-postası
- Firestore ile **anlık mesajlaşma**, okunmamış sayacı, son mesaj önizlemesi
- **Yazıyor…** göstergesi, **çevrimiçi / son görülme**
- **Okundu bilgisi** (⏱ gönderiliyor → ✓ gönderildi → ✓✓ okundu)
- Mesaja uzun basınca **tepki**, kopyala, **düzenle**, **sil**
- **Push bildirimleri (FCM):** bildirime dokununca ilgili sohbet açılır; sunucu tarafı için hazır Cloud Function
- **Güvenlik kuralları:** herkes yalnızca kendi profilini düzenler, sohbeti sadece iki üye görür, mesaj sadece kendi adına gönderilir — Firebase Emulator üzerinde **12 test** ile doğrulanır
- Kişi arama, profil (ad, hakkımda, renk), **Türkçe / İngilizce**, **açık / koyu tema**

**Teknik:** Flutter 3.44 · Riverpod · go_router · Firebase Auth · Cloud Firestore · Cloud Messaging · Cloud Functions · GitHub Actions

**Denemek için:** [Releases](https://github.com/SafaSenturk/flutter-firebase-chat/releases/latest) sayfasından APK'yı indir, bir hesap oluştur ve **Kişiler** ekranından sohbet başlat. Canlı mesajlaşmayı görmek için ikinci bir telefona kurman yeterli.

Kendi uygulaman için giriş, veritabanı, bildirim ve güvenlik kurallarıyla tam bir Firebase altyapısı mı lazım? **[safasenturk.github.io](https://safasenturk.github.io)**

---

<div align="center">

Built by **[Safa Şentürk](https://github.com/SafaSenturk)** · Flutter Mobile Developer · [Portfolio](https://safasenturk.github.io)

</div>
