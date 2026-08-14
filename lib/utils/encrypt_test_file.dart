// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

/// Test utility to create encrypted files for testing the decryptor
void main() async {
  print('=== Log File Decryptor - Test File Generator ===\n');

  // Test data
  const String testPassword = 'TestPassword123';
  const String testContent = '''
[2026-07-10 14:23:45] INFO: Application started
[2026-07-10 14:23:46] DEBUG: Initializing database connection
[2026-07-10 14:23:47] DEBUG: Database connection established
[2026-07-10 14:23:48] INFO: Loading configuration
[2026-07-10 14:23:49] WARNING: Deprecated API endpoint detected
[2026-07-10 14:23:50] INFO: Configuration loaded successfully
[2026-07-10 14:23:51] ERROR: Failed to connect to external service
[2026-07-10 14:23:52] ERROR: Retrying connection attempt 1/3
[2026-07-10 14:23:53] INFO: Connection established on retry
[2026-07-10 14:23:54] DEBUG: User authentication successful
[2026-07-10 14:23:55] INFO: Processing user request
[2026-07-10 14:23:56] DEBUG: Query executed in 125ms
[2026-07-10 14:23:57] INFO: Response sent to client
[2026-07-10 14:23:58] INFO: Application ready for requests
''';

  try {
    print('Creating test encrypted file...\n');
    print('Test Password: $testPassword');
    print('Content Length: ${testContent.length} characters\n');

    // Encrypt
    final encrypted = encryptTestData(testContent, testPassword);
    print('✓ Content encrypted successfully');
    print('  Encrypted data size: ${encrypted.length} bytes');
    print('  IV: First 16 bytes');
    print('  Ciphertext: Remaining ${encrypted.length - 16} bytes\n');

    // Save to file
    final filePath = 'C:\\log_decryptor\\test_encrypted_log.txt';
    final file = File(filePath);
    await file.writeAsBytes(encrypted);
    print('✓ Test file saved to: $filePath\n');

    // Verify by decrypting
    print('Verifying encryption...');
    final decrypted = decryptTestData(encrypted, testPassword);
    final decryptedContent = String.fromCharCodes(decrypted);

    if (decryptedContent == testContent) {
      print('✓ Verification successful! File can be decrypted with password: $testPassword\n');
    } else {
      print('✗ Verification failed! Decrypted content does not match original\n');
    }

    print('=== Test Instructions ===\n');
    print('1. Open the Log File Decryptor application');
    print('2. Click "Browse File" and select: $filePath');
    print('3. Enter password: $testPassword');
    print('4. Click "Decrypt"');
    print('5. Verify the content matches the original test content\n');

    print('=== Test Complete ===');
  } catch (e) {
    print('✗ Error: $e');
  }
}

/// Encrypt test data using the same algorithm as the mobile app
Uint8List encryptTestData(String plainText, String password) {
  final plainBytes = Uint8List.fromList(utf8.encode(plainText));
  final key = encrypt.Key(deriveKey(password));

  // Generate random IV
  final ivBytes = Uint8List(16);
  final rnd = encrypt.SecureRandom(16);
  for (int i = 0; i < ivBytes.length; i++) {
    ivBytes[i] = rnd.bytes[i];
  }

  final iv = encrypt.IV(ivBytes);
  final encrypter = encrypt.Encrypter(
    encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
  );

  final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);
  return Uint8List.fromList(ivBytes + encrypted.bytes);
}

/// Decrypt test data
Uint8List decryptTestData(Uint8List encryptedData, String password) {
  final key = encrypt.Key(deriveKey(password));
  final ivBytes = encryptedData.sublist(0, 16);
  final cipherText = encryptedData.sublist(16);
  final iv = encrypt.IV(ivBytes);

  final encrypter = encrypt.Encrypter(
    encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
  );

  return Uint8List.fromList(
    encrypter.decryptBytes(encrypt.Encrypted(cipherText), iv: iv),
  );
}

/// Derive key from password using SHA256
Uint8List deriveKey(String password) {
  return Uint8List.fromList(sha256.convert(utf8.encode(password)).bytes);
}
