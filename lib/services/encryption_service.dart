import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'dart:convert';

enum EncryptionMode { autoDetect, aesGcm, aesCbcPkcs7, rsaChunkedBase64 }

extension EncryptionModeLabel on EncryptionMode {
  String get label {
    switch (this) {
      case EncryptionMode.autoDetect:
        return 'Auto-detect (AES-GCM / AES-CBC)';
      case EncryptionMode.aesGcm:
        return 'AES-GCM';
      case EncryptionMode.aesCbcPkcs7:
        return 'AES-CBC';
      case EncryptionMode.rsaChunkedBase64:
        return 'RSA Chunked Base64';
    }
  }
}

class EncryptionService {
  static const int _gcmIvLength = 12;
  static const int _cbcIvLength = 16;
  static const String _rsaChunkDelimiter = '\$?';

  /// Derive a key from password using SHA256
  static Uint8List deriveKey(String password) {
    return Uint8List.fromList(sha256.convert(utf8.encode(password)).bytes);
  }

  static Uint8List decryptData(
    Uint8List encryptedData,
    String password,
    EncryptionMode mode,
  ) {
    switch (mode) {
      case EncryptionMode.aesGcm:
        return _decryptAesGcm(encryptedData, password);
      case EncryptionMode.aesCbcPkcs7:
        return _decryptAesCbc(encryptedData, password);
      case EncryptionMode.autoDetect:
        return _decryptAutoDetect(encryptedData, password);
      case EncryptionMode.rsaChunkedBase64:
        throw Exception(
          'RSA mode requires a private key. Use decryptRsaChunkedData().',
        );
    }
  }

  static Uint8List _decryptAutoDetect(Uint8List encryptedData, String password) {
    String firstError = '';
    try {
      return _decryptAesGcm(encryptedData, password);
    } catch (e) {
      firstError = e.toString();
    }
    try {
      return _decryptAesCbc(encryptedData, password);
    } catch (e) {
      throw Exception(
        'Auto-detection failed. GCM error: $firstError; CBC error: $e',
      );
    }
  }

  static Uint8List decryptRsaChunkedData(
    Uint8List encryptedData,
    String privateKeyPem,
  ) {
    final encryptedText = utf8.decode(encryptedData, allowMalformed: true);
    final chunks = encryptedText
        .split(_rsaChunkDelimiter)
        .map((chunk) => chunk.trim())
        .where((chunk) => chunk.isNotEmpty)
        .toList();

    if (chunks.isEmpty) {
      throw Exception('Invalid RSA chunked data: no encrypted chunks found');
    }

    final parser = encrypt.RSAKeyParser();
    final parsedKey = parser.parse(privateKeyPem);
    if (parsedKey is! RSAPrivateKey) {
      throw Exception(
        'Selected key is not an RSA private key. Please select the matching private_key.pem.',
      );
    }

    final encrypter = encrypt.Encrypter(
      encrypt.RSA(privateKey: parsedKey),
    );

    final buffer = StringBuffer();
    for (final chunk in chunks) {
      buffer.write(encrypter.decrypt64(chunk));
    }

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  static Uint8List _decryptAesGcm(Uint8List encryptedData, String password) {
    if (encryptedData.length < _gcmIvLength) {
      throw Exception('Invalid encrypted data: too short');
    }

    final key = encrypt.Key(deriveKey(password));
    final ivBytes = encryptedData.sublist(0, _gcmIvLength);
    final cipherText = encryptedData.sublist(_gcmIvLength);
    final iv = encrypt.IV(ivBytes);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm, padding: null),
    );

    try {
      return Uint8List.fromList(
        encrypter.decryptBytes(encrypt.Encrypted(cipherText), iv: iv),
      );
    } catch (e) {
      throw Exception('Decryption failed: ${e.toString()}');
    }
  }

  static Uint8List _decryptAesCbc(Uint8List encryptedData, String password) {
    if (encryptedData.length < _cbcIvLength) {
      throw Exception('Invalid encrypted data: too short');
    }

    final key = encrypt.Key(deriveKey(password));
    final ivBytes = encryptedData.sublist(0, _cbcIvLength);
    final cipherText = encryptedData.sublist(_cbcIvLength);
    final iv = encrypt.IV(ivBytes);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );

    try {
      return Uint8List.fromList(
        encrypter.decryptBytes(encrypt.Encrypted(cipherText), iv: iv),
      );
    } catch (e) {
      throw Exception('Decryption failed: ${e.toString()}');
    }
  }

  /// Encrypt data (for testing/verification purposes)
  static Uint8List encryptData(
    Uint8List plainData,
    String password,
    EncryptionMode mode,
  ) {
    switch (mode) {
      case EncryptionMode.aesGcm:
        return _encryptAesGcm(plainData, password);
      case EncryptionMode.aesCbcPkcs7:
      case EncryptionMode.autoDetect:
        return _encryptAesCbc(plainData, password);
      case EncryptionMode.rsaChunkedBase64:
        throw Exception('RSA chunked encryption is not supported in this tool.');
    }
  }

  static Uint8List _encryptAesGcm(Uint8List plainData, String password) {
    final key = encrypt.Key(deriveKey(password));
    final ivBytes = Uint8List.fromList(encrypt.SecureRandom(_gcmIvLength).bytes);
    final iv = encrypt.IV(ivBytes);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm, padding: null),
    );
    final encrypted = encrypter.encryptBytes(plainData, iv: iv);
    return Uint8List.fromList(ivBytes + encrypted.bytes);
  }

  static Uint8List _encryptAesCbc(Uint8List plainData, String password) {
    final key = encrypt.Key(deriveKey(password));

    // Generate random IV
    final ivBytes = Uint8List.fromList(encrypt.SecureRandom(_cbcIvLength).bytes);
    final iv = encrypt.IV(ivBytes);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );
    final encrypted = encrypter.encryptBytes(plainData, iv: iv);
    return Uint8List.fromList(ivBytes + encrypted.bytes);
  }
}
