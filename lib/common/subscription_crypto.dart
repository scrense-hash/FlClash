import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

Uint8List decryptSubscription(Uint8List body, String password) {
  if (password.isEmpty) {
    return body;
  }
  final key = Uint8List.fromList(md5.convert(utf8.encode(password)).bytes);
  final raw = base64.decode(utf8.decode(body));
  if (raw.length < 16) {
    throw const FormatException('subscription data too short');
  }
  final iv = Uint8List.fromList(raw.sublist(0, 16));
  final cipherText = Uint8List.fromList(raw.sublist(16));
  final cipher = PaddedBlockCipherImpl(
    PKCS7Padding(),
    CBCBlockCipher(AESEngine()),
  )
    ..init(
      false,
      PaddedBlockCipherParameters<CipherParameters, CipherParameters>(
        ParametersWithIV<KeyParameter>(KeyParameter(key), iv),
        null,
      ),
    );
  return Uint8List.fromList(cipher.process(cipherText));
}
