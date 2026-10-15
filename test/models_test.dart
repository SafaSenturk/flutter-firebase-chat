import 'package:flutter_test/flutter_test.dart';
import 'package:pulsechat/data/auth_repository.dart';
import 'package:pulsechat/data/models.dart';
import 'package:pulsechat/features/auth/auth_screens.dart';

void main() {
  group('Chat', () {
    test('one-to-one chat ids do not depend on who starts the chat', () {
      expect(Chat.idFor('alice', 'bob'), 'alice_bob');
      expect(Chat.idFor('bob', 'alice'), 'alice_bob');
    });

    test('finds the other member and their unread count', () {
      const chat = Chat(id: 'a_b', members: ['a', 'b'], unread: {'a': 3});
      expect(chat.otherMember('a'), 'b');
      expect(chat.otherMember('b'), 'a');
      expect(chat.unreadFor('a'), 3);
      expect(chat.unreadFor('b'), 0);
    });

    test('typing expires after a few seconds without a new ping', () {
      final now = DateTime(2026, 10, 16, 12);
      final chat = Chat(id: 'a_b', members: const ['a', 'b'], typing: {'b': now.subtract(const Duration(seconds: 2))});
      expect(chat.isTyping('b', now: now), isTrue);
      expect(chat.isTyping('b', now: now.add(const Duration(seconds: 10))), isFalse);
      expect(chat.isTyping('a', now: now), isFalse);
    });
  });

  test('initials use the first and last name', () {
    AppUser user(String name) => AppUser(uid: 'u', name: name, email: '');
    expect(user('Deniz Arslan').initials, 'DA');
    expect(user('Can Öztürk Demir').initials, 'CD');
    expect(user('mert').initials, 'M');
    expect(user('  ').initials, '?');
  });

  test('password strength grows with length, mixed case, digits and symbols', () {
    expect(passwordScore('abc'), 0);
    expect(passwordScore('abcdef'), 1);
    expect(passwordScore('Abcdef12'), 2);
    expect(passwordScore('Abcdef12!long'), 3);
  });

  test('maps Firebase Auth error codes to friendly kinds', () {
    expect(AuthFailure.fromCode('invalid-credential').kind, AuthErrorKind.invalidCredentials);
    expect(AuthFailure.fromCode('wrong-password').kind, AuthErrorKind.invalidCredentials);
    expect(AuthFailure.fromCode('email-already-in-use').kind, AuthErrorKind.emailInUse);
    expect(AuthFailure.fromCode('network-request-failed').kind, AuthErrorKind.network);
    expect(AuthFailure.fromCode('something-new').kind, AuthErrorKind.unknown);
  });
}
