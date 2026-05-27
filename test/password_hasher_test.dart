import 'package:flutter_test/flutter_test.dart';
import 'package:soaksafe/core/security/password_hasher.dart';

void main() {
  test('password hash verifies round trip', () {
    final hash = PasswordHasher.hash('secret123');
    expect(PasswordHasher.isModernStoredForm(hash), isTrue);
    expect(PasswordHasher.verify(hash, 'secret123'), isTrue);
    expect(PasswordHasher.verify(hash, 'wrong'), isFalse);
  });
}
