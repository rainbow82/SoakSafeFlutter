import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Compatible with Android SS1$ PBKDF2-HMAC-SHA256 format.
abstract final class PasswordHasher {
  static const _prefix = 'SS1\$';
  static const _iterations = 200000;
  static const _keyBytes = 32;

  static bool isModernStoredForm(String stored) => stored.startsWith(_prefix);

  static String hash(String plainPassword) {
    final salt = _randomBytes(16);
    final hashBytes = _pbkdf2(plainPassword, salt, _iterations);
    return '$_prefix$_iterations\$${base64Encode(salt)}\$${base64Encode(hashBytes)}';
  }

  static bool verify(String storedPassword, String plainPassword) {
    if (isModernStoredForm(storedPassword)) {
      final parts = storedPassword.split('\$');
      if (parts.length != 4 || parts[0] != 'SS1') return false;
      final iterations = int.tryParse(parts[1]);
      if (iterations == null || iterations < 10000) return false;
      late final Uint8List salt;
      late final Uint8List expected;
      try {
        salt = Uint8List.fromList(base64Decode(parts[2]));
        expected = Uint8List.fromList(base64Decode(parts[3]));
      } on FormatException {
        return false;
      }
      final actual = _pbkdf2(plainPassword, salt, iterations);
      if (expected.length != actual.length) return false;
      var diff = 0;
      for (var i = 0; i < expected.length; i++) {
        diff |= expected[i] ^ actual[i];
      }
      return diff == 0;
    }
    return storedPassword == plainPassword;
  }

  static Uint8List _pbkdf2(String password, Uint8List salt, int iterations) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, _keyBytes));
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }
}
