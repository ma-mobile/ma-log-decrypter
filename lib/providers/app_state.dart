import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
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
  File? _selectedDbFile;
  List<String> _dbTables = [];
  String _dbTableSearchQuery = '';
  String? _selectedDbTable;
  List<String> _dbColumns = [];
  List<List<String>> _dbRows = [];
  String _dbStatus = '';
  String _dbErrorMessage = '';
  bool _isLoading = false;
  bool _isDbLoading = false;

  // Getters
  File? get selectedFile => _selectedFile;
  File? get privateKeyFile => _privateKeyFile;
  String get password => _password.trim();
  EncryptionMode get encryptionMode => _encryptionMode;
  String get decryptedContent => _decryptedContent;
  String get status => _status;
  String get errorMessage => _errorMessage;
  File? get selectedDbFile => _selectedDbFile;
  List<String> get dbTables => _dbTables;
  String get dbTableSearchQuery => _dbTableSearchQuery;
  List<String> get filteredDbTables {
    final query = _dbTableSearchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _dbTables;
    }
    return _dbTables
        .where((table) => table.toLowerCase().contains(query))
        .toList();
  }

  String? get selectedDbTable => _selectedDbTable;
  List<String> get dbColumns => _dbColumns;
  List<List<String>> get dbRows => _dbRows;
  String get dbStatus => _dbStatus;
  String get dbErrorMessage => _dbErrorMessage;
  bool get isLoading => _isLoading;
  bool get isDbLoading => _isDbLoading;
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
      if (_password.trim().isEmpty) {
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
          _password.trim(),
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
    _selectedDbFile = null;
    _dbTables = [];
    _selectedDbTable = null;
    _dbColumns = [];
    _dbRows = [];
    _dbStatus = '';
    _dbErrorMessage = '';
    _isLoading = false;
    _isDbLoading = false;
    notifyListeners();
  }

  /// Clear only selected file and current decryption result
  void clearSelectedFile() {
    _selectedFile = null;
    _decryptedContent = '';
    _status = '';
    _errorMessage = '';
    notifyListeners();
  }

  /// Clear decrypted content and status
  void clearDecryption() {
    _decryptedContent = '';
    _status = '';
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> selectDatabaseFile() async {
    try {
      _isDbLoading = true;
      _dbErrorMessage = '';
      _dbStatus = 'Selecting database file...';
      notifyListeners();

      final file = await FileService.pickDatabaseFile();
      if (file == null) {
        _dbStatus = '';
        return;
      }

      _selectedDbFile = file;
      _dbStatus =
          'Loading tables from ${FileService.getFileName(file.path)}...';
      notifyListeners();

      _dbTables = DatabaseService.listTables(file);
      _dbTableSearchQuery = '';
      _selectedDbTable = null;
      _dbColumns = [];
      _dbRows = [];
      _dbStatus =
          'Database loaded (${_dbTables.length} table${_dbTables.length == 1 ? '' : 's'})';
    } catch (e) {
      _dbErrorMessage = 'Failed to load database: $e';
      _dbStatus = '';
    } finally {
      _isDbLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectDatabaseTable(String tableName) async {
    if (_selectedDbFile == null) {
      _dbErrorMessage = 'Please upload a database file first';
      notifyListeners();
      return;
    }

    try {
      _isDbLoading = true;
      _dbErrorMessage = '';
      _selectedDbTable = tableName;
      _dbStatus = 'Loading rows from "$tableName"...';
      notifyListeners();

      final tableData = DatabaseService.readTable(_selectedDbFile!, tableName);
      _dbColumns = tableData.columns;
      _dbRows = tableData.rows;
      _dbStatus = 'Showing ${_dbRows.length} rows from "$tableName"';
    } catch (e) {
      _dbColumns = [];
      _dbRows = [];
      _dbErrorMessage = 'Failed to read table: $e';
      _dbStatus = '';
    } finally {
      _isDbLoading = false;
      notifyListeners();
    }
  }

  void clearDatabaseSelection() {
    _selectedDbFile = null;
    _dbTables = [];
    _dbTableSearchQuery = '';
    _selectedDbTable = null;
    _dbColumns = [];
    _dbRows = [];
    _dbStatus = '';
    _dbErrorMessage = '';
    _isDbLoading = false;
    notifyListeners();
  }

  void updateDbTableSearchQuery(String query) {
    _dbTableSearchQuery = query;
    notifyListeners();
  }
}
