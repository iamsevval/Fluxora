import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Girdi Doğrulama (Validation) Testleri', () {
    test('Geçerli Ad Soyad Testi', () {
      final nameRegExp = RegExp(r"^[a-zA-ZğüşıöçĞÜŞİÖÇ]+(?:\s+[a-zA-ZğüşıöçĞÜŞİÖÇ]+)+$");
      expect(nameRegExp.hasMatch('Ahmet Yılmaz'), isTrue);
      expect(nameRegExp.hasMatch('Şevval Arslan'), isTrue);
    });

    test('Geçersiz Ad Soyad Testi (Tek kelime veya sayı içeriyor)', () {
      final nameRegExp = RegExp(r"^[a-zA-ZğüşıöçĞÜŞİÖÇ]+(?:\s+[a-zA-ZğüşıöçĞÜŞİÖÇ]+)+$");
      expect(nameRegExp.hasMatch('Ahmet'), isFalse);
      expect(nameRegExp.hasMatch('Ahmet123 Yılmaz'), isFalse);
      expect(nameRegExp.hasMatch(''), isFalse);
    });

    test('Geçerli Kullanıcı Adı Testi', () {
      final usernameRegExp = RegExp(r"^[a-zA-Z0-9_]+$");
      expect(usernameRegExp.hasMatch('sevval_123'), isTrue);
      expect(usernameRegExp.hasMatch('yazek_hsd'), isTrue);
    });

    test('Geçersiz Kullanıcı Adı Testi (Boşluk veya özel karakter içeriyor)', () {
      final usernameRegExp = RegExp(r"^[a-zA-Z0-9_]+$");
      expect(usernameRegExp.hasMatch('sevval 123'), isFalse);
      expect(usernameRegExp.hasMatch('yazek-hsd!'), isFalse);
    });
  });
}
