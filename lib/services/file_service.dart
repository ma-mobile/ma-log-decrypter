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

  /// Pick multiple encrypted files
  static Future<List<File>> pickEncryptedFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        dialogTitle: 'Select Encrypted Log Files',
        allowMultiple: true,
      );

      if (result == null) return [];
      return result.files
          .where((f) => f.path != null)
          .map((f) => File(f.path!))
          .toList();
    } catch (e) {
      throw Exception('Error picking files: $e');
    }
  }

  /// Pick a folder containing encrypted files
  static Future<Directory?> pickEncryptedFolder() async {
    try {
      final path = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select Folder Containing Encrypted .txt Files',
      );
      if (path == null || path.isEmpty) return null;
      return Directory(path);
    } catch (e) {
      throw Exception('Error picking folder: $e');
    }
  }

  /// Recursively find encrypted .txt files in a directory
  static Future<List<File>> findEncryptedFiles(Directory directory) async {
    try {
      if (!await directory.exists()) return [];
      final files = <File>[];
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && getFileExtension(entity.path) == 'txt') {
          files.add(entity);
        }
      }
      return files..sort((a, b) => a.path.compareTo(b.path));
    } catch (e) {
      throw Exception('Error scanning folder: $e');
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
    return saveTextFile(
      content,
      suggestedFileName: suggestedFileName ?? _buildDefaultFileName(),
      dialogTitle: 'Save decrypted log as',
      allowedExtensions: ['txt'],
      defaultExtension: 'txt',
    );
  }

  /// Save generic text content
  static Future<String?> saveTextFile(
    String content, {
    required String suggestedFileName,
    required String dialogTitle,
    required List<String> allowedExtensions,
    required String defaultExtension,
  }) async {
    try {
      final filePath = await FilePicker.saveFile(
        dialogTitle: dialogTitle,
        fileName: suggestedFileName,
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (filePath == null || filePath.isEmpty) {
        return null;
      }

      final normalizedPath = filePath.toLowerCase().endsWith('.$defaultExtension')
          ? filePath
          : '$filePath.$defaultExtension';
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

  static String getFileExtension(String filePath) {
    final name = getFileName(filePath);
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == name.length - 1) return '';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  static bool isDatabaseFile(String filePath) {
    final ext = getFileExtension(filePath);
    return ['db', 'sqlite', 'sqlite3'].contains(ext);
  }
}
