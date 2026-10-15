import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_screens.dart';
import '../features/chat/chat_screen.dart';
import '../features/chats/chats_screen.dart';
import '../features/people/people_screen.dart';
import '../features/profile/profile_screen.dart';
import 'providers.dart';

/// Redirects between the auth screens and the app whenever sign-in changes.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  const authRoutes = {'/sign-in', '/sign-up', '/forgot'};

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      if (auth.isLoading) return null;
      final signedIn = auth.value != null;
      final atAuth = authRoutes.contains(state.matchedLocation);
      if (!signedIn && !atAuth) return '/sign-in';
      if (signedIn && atAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const ChatsScreen()),
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/sign-up', builder: (_, _) => const SignUpScreen()),
      GoRoute(path: '/forgot', builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: '/people', builder: (_, _) => const PeopleScreen()),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(
        path: '/chat/:uid',
        builder: (_, state) => ChatScreen(otherUid: state.pathParameters['uid']!),
      ),
    ],
  );
});
