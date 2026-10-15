// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Pulse';

  @override
  String get tagline => 'Firebase ile gerçek zamanlı sohbet';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get fullName => 'Adın';

  @override
  String get confirmPassword => 'Şifre tekrar';

  @override
  String get signIn => 'Giriş yap';

  @override
  String get signUp => 'Hesap oluştur';

  @override
  String get continueWithGoogle => 'Google ile devam et';

  @override
  String get or => 'veya';

  @override
  String get forgotPassword => 'Şifremi unuttum';

  @override
  String get noAccount => 'Pulse\'ta yeni misin?';

  @override
  String get haveAccount => 'Zaten hesabın var mı?';

  @override
  String get resetPassword => 'Şifreyi sıfırla';

  @override
  String get resetPasswordBody =>
      'E-posta adresini yaz, yeni şifre belirlemen için bir bağlantı gönderelim.';

  @override
  String get sendResetLink => 'Bağlantıyı gönder';

  @override
  String resetSent(String email) {
    return 'Gelen kutunu kontrol et — sıfırlama bağlantısı $email adresine gönderildi.';
  }

  @override
  String get backToSignIn => 'Girişe dön';

  @override
  String get validationRequired => 'Zorunlu alan';

  @override
  String get validationEmail => 'Geçerli bir e-posta gir';

  @override
  String get validationPasswordLength => 'En az 6 karakter';

  @override
  String get validationPasswordMatch => 'Şifreler eşleşmiyor';

  @override
  String get passwordWeak => 'Zayıf';

  @override
  String get passwordOk => 'Fena değil';

  @override
  String get passwordStrong => 'Güçlü';

  @override
  String get errorInvalidCredentials => 'E-posta ya da şifre hatalı.';

  @override
  String get errorEmailInUse => 'Bu e-postayla zaten bir hesap var.';

  @override
  String get errorWeakPassword => 'Daha güçlü bir şifre seç.';

  @override
  String get errorInvalidEmail => 'Bu e-posta adresi hatalı görünüyor.';

  @override
  String get errorTooManyRequests => 'Çok fazla deneme yapıldı. Biraz bekle.';

  @override
  String get errorNetwork => 'İnternet bağlantısı yok.';

  @override
  String get errorUnknown => 'Bir şeyler ters gitti. Tekrar dene.';

  @override
  String get errorLoad => 'Şu an yüklenemedi.';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get chats => 'Sohbetler';

  @override
  String get searchChats => 'Sohbetlerde ara';

  @override
  String get noChatsTitle => 'Henüz sohbet yok';

  @override
  String get noChatsBody =>
      'Birini bul ve merhaba de — mesajlar burada anında görünür.';

  @override
  String get findPeople => 'Kişi bul';

  @override
  String get newChat => 'Yeni sohbet';

  @override
  String get people => 'Kişiler';

  @override
  String get searchPeople => 'İsimle ara';

  @override
  String get noPeople => 'Kimse bulunamadı';

  @override
  String get you => 'Sen';

  @override
  String get typing => 'yazıyor…';

  @override
  String get online => 'çevrimiçi';

  @override
  String lastSeen(String time) {
    return 'son görülme $time';
  }

  @override
  String get yesterday => 'Dün';

  @override
  String get today => 'Bugün';

  @override
  String get messageHint => 'Mesaj';

  @override
  String sayHello(String name) {
    return '$name ile merhabalaş 👋';
  }

  @override
  String get messageDeleted => 'Bu mesaj silindi';

  @override
  String get edited => 'düzenlendi';

  @override
  String get copy => 'Kopyala';

  @override
  String get copied => 'Kopyalandı';

  @override
  String get edit => 'Düzenle';

  @override
  String get delete => 'Sil';

  @override
  String get deleteMessageTitle => 'Mesaj silinsin mi?';

  @override
  String get deleteMessageBody => 'Sohbetteki herkes için kaldırılacak.';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get save => 'Kaydet';

  @override
  String get editing => 'Mesaj düzenleniyor';

  @override
  String get profile => 'Profil';

  @override
  String get about => 'Hakkımda';

  @override
  String get aboutHint => 'Kendinden birkaç kelime';

  @override
  String get avatarColor => 'Profil rengi';

  @override
  String get language => 'Dil';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get profileSaved => 'Profil güncellendi';

  @override
  String notificationsTitle(String name) {
    return '$name sana yazdı';
  }

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yeni mesaj',
    );
    return '$_temp0';
  }

  @override
  String get poweredBy => 'Firebase Auth · Cloud Firestore · Cloud Messaging';
}
