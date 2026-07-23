import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/encryption_service.dart';
import '../services/file_service.dart';

class AppState extends ChangeNotifier {
  static const String _bundledRsaPrivateKeyPath =
      'keys/private_key_decrypted.pem';
  File? _selectedFile;
  File? _privateKeyFile;
  String _password = '';
  EncryptionMode _encryptionMode = EncryptionMode.aesGcm;
  String _decryptedContent = '';
  String _status = '';
  String _errorMessage = '';
  bool _isLoading = false;

  // Getters
  File? get selectedFile => _selectedFile;
  File? get privateKeyFile => _privateKeyFile;
  String get password => _password.trim();
  EncryptionMode get encryptionMode => _encryptionMode;
  String get decryptedContent => _decryptedContent;
  String get status => _status;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get hasDecryptedContent => _decryptedContent.isNotEmpty;

  /// Select an encrypted file
  Future<void> selectFile() async {
    try {
      _errorMessage = '';
      _status = 'Selecting file...';
      notifyListeners();

      final file = await FileService.pickEncryptedFile();
      if (file != null) {
        _selectedFile = file;
        _status = 'File selected: ${FileService.getFileName(file.path)}';
      } else {
        _status = '';
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = '';
    }
    notifyListeners();
  }

  /// Update password
  void updatePassword(String newPassword) {
    _password = newPassword;
    _errorMessage = '';
    notifyListeners();
  }

  /// Update encryption mode used for decryption
  void updateEncryptionMode(EncryptionMode mode) {
    _encryptionMode = mode;
    _errorMessage = '';
    notifyListeners();
  }

  /// Select RSA private key file (PEM)
  Future<void> selectPrivateKeyFile() async {
    try {
      _errorMessage = '';
      _status = 'Selecting private key...';
      notifyListeners();

      final file = await FileService.pickPrivateKeyFile();
      if (file != null) {
        _privateKeyFile = file;
        _status = 'Private key selected: ${FileService.getFileName(file.path)}';
      } else {
        _status = '';
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = '';
    }
    notifyListeners();
  }

  /// Decrypt the selected file
  Future<void> decryptFile() async {
    if (_selectedFile == null) {
      _errorMessage = 'Please select a file first';
      notifyListeners();
      return;
    }

    if (_encryptionMode != EncryptionMode.rsaChunkedBase64) {
      if (_password.isEmpty) {
        _errorMessage = 'Please enter a password';
        notifyListeners();
        return;
      }
    }

    try {
      _isLoading = true;
      _errorMessage = '';
      _status = 'Decrypting file...';
      notifyListeners();

      // Read file
      final encryptedBytes = await FileService.readFileAsBytes(_selectedFile!);

      // Decrypt
      late final Uint8List decryptedBytes;
      if (_encryptionMode == EncryptionMode.rsaChunkedBase64) {
        final privateKeyPem = await _resolveRsaPrivateKeyPem();
        decryptedBytes = EncryptionService.decryptRsaChunkedData(
          encryptedBytes,
          privateKeyPem,
        );
      } else {
        decryptedBytes = EncryptionService.decryptData(
          encryptedBytes,
          _password,
          _encryptionMode,
        );
      }

      // Convert to string
      _decryptedContent = utf8.decode(decryptedBytes);

      _status =
          'File decrypted successfully (${_decryptedContent.length} characters)';
    } catch (e) {
      _decryptedContent = '';
      _errorMessage = 'Decryption failed: ${e.toString()}';
      _status = '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> _resolveRsaPrivateKeyPem() async {
    if (_privateKeyFile != null) {
      return _privateKeyFile!.readAsString();
    }

    try {
      return await rootBundle.loadString(_bundledRsaPrivateKeyPath);
    } catch (e) {
      throw Exception(
        'Bundled RSA private key not found at $_bundledRsaPrivateKeyPath. '
        'Select a private key file manually. ($e)',
      );
    }
  }

  /// Save decrypted content
  Future<void> saveDecryptedContent({String? suggestedFileName}) async {
    if (_decryptedContent.isEmpty) {
      _errorMessage = 'No decrypted content to save';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _errorMessage = '';
      _status = 'Saving file...';
      notifyListeners();

      final filePath = await FileService.saveDecryptedFile(
        _decryptedContent,
        suggestedFileName: suggestedFileName,
      );
      _status = 'File saved successfully to: $filePath';
    } catch (e) {
      _errorMessage = 'Failed to save file: ${e.toString()}';
      _status = '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all
  void reset() {
    _selectedFile = null;
    _privateKeyFile = null;
    _password = '';
    _decryptedContent = '';
    _status = '';
    _errorMessage = '';
    _isLoading = false;
    notifyListeners();
  }

  /// Clear decrypted content and status
  void clearDecryption() {
    _decryptedContent = '';
    _status = '';
    _errorMessage = '';
    notifyListeners();
  }
}
