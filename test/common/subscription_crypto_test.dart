import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:fl_clash/common/subscription_crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';

Uint8List encryptSubscription(Uint8List body, String password) {
  final key = Uint8List.fromList(md5.convert(utf8.encode(password)).bytes);
  final iv = Uint8List.fromList(
    List.generate(16, (i) => i * 3 % 256),
  );
  final cipher = PaddedBlockCipherImpl(
    PKCS7Padding(),
    CBCBlockCipher(AESEngine()),
  )
    ..init(
      true,
      PaddedBlockCipherParameters<CipherParameters, CipherParameters>(
        ParametersWithIV<KeyParameter>(KeyParameter(key), iv),
        null,
      ),
    );
  final encrypted = cipher.process(body);
  return Uint8List.fromList([...iv, ...encrypted]);
}

void main() {
  test('decryptSubscription returns body unchanged when password empty', () {
    final body = Uint8List.fromList(utf8.encode('hello'));
    expect(decryptSubscription(body, ''), body);
  });

  test('decryptSubscription round-trips AES-128-CBC encrypted data', () {
    const password = 'secret';
    const plain = 'subscription config content';
    final encrypted = encryptSubscription(
      Uint8List.fromList(utf8.encode(plain)),
      password,
    );
    final encoded = utf8.encode(base64.encode(encrypted));
    final decrypted = decryptSubscription(
      Uint8List.fromList(encoded),
      password,
    );
    expect(utf8.decode(decrypted), plain);
  });

  test('decryptSubscription throws on short ciphertext', () {
    final body = Uint8List.fromList(utf8.encode(base64.encode(List.filled(8, 1))));
    expect(() => decryptSubscription(body, 'p'), throwsFormatException);
  });
}
