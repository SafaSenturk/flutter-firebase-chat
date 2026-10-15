// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Pulse';

  @override
  String get tagline => 'Real-time chat, built on Firebase';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Your name';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get or => 'or';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get noAccount => 'New to Pulse?';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get resetPasswordBody =>
      'Enter your email and we\'ll send you a link to choose a new password.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String resetSent(String email) {
    return 'Check your inbox — a reset link is on its way to $email.';
  }

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get validationRequired => 'Required';

  @override
  String get validationEmail => 'Enter a valid email';

  @override
  String get validationPasswordLength => 'At least 6 characters';

  @override
  String get validationPasswordMatch => 'Passwords don\'t match';

  @override
  String get passwordWeak => 'Weak';

  @override
  String get passwordOk => 'Okay';

  @override
  String get passwordStrong => 'Strong';

  @override
  String get errorInvalidCredentials => 'Email or password is incorrect.';

  @override
  String get errorEmailInUse => 'An account with this email already exists.';

  @override
  String get errorWeakPassword => 'Choose a stronger password.';

  @override
  String get errorInvalidEmail => 'That email address looks wrong.';

  @override
  String get errorTooManyRequests => 'Too many attempts. Please wait a moment.';

  @override
  String get errorNetwork => 'No internet connection.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get errorLoad => 'Couldn\'t load this right now.';

  @override
  String get retry => 'Retry';

  @override
  String get chats => 'Chats';

  @override
  String get searchChats => 'Search chats';

  @override
  String get noChatsTitle => 'No conversations yet';

  @override
  String get noChatsBody =>
      'Find someone and say hi — messages appear here instantly.';

  @override
  String get findPeople => 'Find people';

  @override
  String get newChat => 'New chat';

  @override
  String get people => 'People';

  @override
  String get searchPeople => 'Search by name';

  @override
  String get noPeople => 'Nobody found';

  @override
  String get you => 'You';

  @override
  String get typing => 'typing…';

  @override
  String get online => 'online';

  @override
  String lastSeen(String time) {
    return 'last seen $time';
  }

  @override
  String get yesterday => 'Yesterday';

  @override
  String get today => 'Today';

  @override
  String get messageHint => 'Message';

  @override
  String sayHello(String name) {
    return 'Say hello to $name 👋';
  }

  @override
  String get messageDeleted => 'This message was deleted';

  @override
  String get edited => 'edited';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get deleteMessageTitle => 'Delete message?';

  @override
  String get deleteMessageBody =>
      'It will be removed for everyone in this chat.';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get editing => 'Editing message';

  @override
  String get profile => 'Profile';

  @override
  String get about => 'About';

  @override
  String get aboutHint => 'A few words about you';

  @override
  String get avatarColor => 'Avatar colour';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get signOut => 'Sign out';

  @override
  String get profileSaved => 'Profile updated';

  @override
  String notificationsTitle(String name) {
    return 'New message from $name';
  }

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new messages',
      one: '1 new message',
    );
    return '$_temp0';
  }

  @override
  String get poweredBy => 'Firebase Auth · Cloud Firestore · Cloud Messaging';
}
