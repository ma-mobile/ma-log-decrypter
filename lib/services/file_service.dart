import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class FileService {
  /// Pick an encrypted file from the system
  static Future<File?> pickEncryptedFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        dialogTitle: 'Select Encrypted Log File',
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      throw Exception('Error picking file: $e');
    }
  }

  /// Pick a SQLite database file
  static Future<File?> pickDatabaseFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db', 'sqlite', 'sqlite3'],
        dialogTitle: 'Select SQLite Database File',
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      throw Exception('Error picking database file: $e');
    }
  }

  /// Pick an RSA private key file (PEM)
  static Future<File?> pickPrivateKeyFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pem', 'key', 'txt'],
        dialogTitle: 'Select RSA Private Key File',
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      throw Exception('Error picking private key file: $e');
    }
  }

  /// Read file as bytes
  static Future<Uint8List> readFileAsBytes(File file) async {
    try {
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }
      return await file.readAsBytes();
    } catch (e) {
      throw Exception('Error reading file: $e');
    }
  }

  /// Save decrypted content to a new file
  static Future<String?> saveDecryptedFile(
    String content, {
    String? suggestedFileName,
  }) async {
    try {
      final defaultFileName = suggestedFileName ?? _buildDefaultFileName();
      final filePath = await FilePicker.saveFile(
        dialogTitle: 'Save decrypted log as',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (filePath == null || filePath.isEmpty) {
        return null;
      }

      final normalizedPath = filePath.endsWith('.txt') ? filePath : '$filePath.txt';
      final file = File(normalizedPath);
      await file.writeAsString(content);

      return normalizedPath;
    } catch (e) {
      throw Exception('Error saving file: $e');
    }
  }

  static String _buildDefaultFileName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'decrypted_log_$timestamp.txt';
  }

  /// Get file name from path
  static String getFileName(String filePath) {
    return filePath.split(Platform.pathSeparator).last;
  }
}
