import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';
import '../services/file_service.dart';
import '../services/settings_service.dart';

class BatchResult {
  BatchResult({
    required this.inputPath,
    this.outputPath,
    this.error,
    this.durationMs,
  });

  final String inputPath;
  final String? outputPath;
  final String? error;
  final int? durationMs;

  bool get success => error == null && outputPath != null;
}

class AppState extends ChangeNotifier {
  static const String _bundledRsaPrivateKeyPath =
      'keys/private_key_decrypted.pem';
  File? _selectedFile;
  File? _privateKeyFile;
  String _password = '';
  EncryptionMode _encryptionMode = EncryptionMode.autoDetect;
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
  List<RecentItem> _recentItems = [];
  String _logSearchQuery = '';
  String _dbRowSearchQuery = '';
  String _sqlQuery = '';
  QueryResult? _sqlQueryResult;
  String _sqlStatus = '';
  String _sqlErrorMessage = '';
  TableSchema? _tableSchema;
  List<File> _batchFiles = [];
  List<BatchResult> _batchResults = [];
  String _batchStatus = '';
  String _batchErrorMessage = '';
  bool _isBatchRunning = false;
  String _batchOutputFolder = '';

  AppState() {
    _loadRecentItems();
  }

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
  List<RecentItem> get recentItems => _recentItems;
  List<RecentItem> get recentLogFiles => _recentItems
      .where((item) => item.type == RecentItemType.log)
      .toList();
  List<RecentItem> get recentDbFiles => _recentItems
      .where((item) => item.type == RecentItemType.database)
      .toList();
  String get logSearchQuery => _logSearchQuery;
  String get dbRowSearchQuery => _dbRowSearchQuery;
  String get sqlQuery => _sqlQuery;
  QueryResult? get sqlQueryResult => _sqlQueryResult;
  String get sqlStatus => _sqlStatus;
  String get sqlErrorMessage => _sqlErrorMessage;
  TableSchema? get tableSchema => _tableSchema;
  List<File> get batchFiles => _batchFiles;
  List<BatchResult> get batchResults => _batchResults;
  String get batchStatus => _batchStatus;
  String get batchErrorMessage => _batchErrorMessage;
  bool get isBatchRunning => _isBatchRunning;
  bool get hasBatchFiles => _batchFiles.isNotEmpty;
  bool get hasBatchResults => _batchResults.isNotEmpty;
  String get batchOutputFolder => _batchOutputFolder;

  List<String> get filteredDbColumns {
    final query = _dbRowSearchQuery.trim().toLowerCase();
    if (query.isEmpty) return _dbColumns;
    return _dbColumns
        .where((col) => col.toLowerCase().contains(query))
        .toList();
  }

  List<List<String>> get filteredDbRows {
    final query = _dbRowSearchQuery.trim().toLowerCase();
    if (query.isEmpty) return _dbRows;
    return _dbRows.where((row) {
      return row.any((cell) => cell.toLowerCase().contains(query));
    }).toList();
  }

  String get filteredDecryptedContent {
    final query = _logSearchQuery.trim();
    if (query.isEmpty) return _decryptedContent;
    return _decryptedContent
        .split('\n')
        .where((line) => line.toLowerCase().contains(query.toLowerCase()))
        .join('\n');
  }

  Future<void> _loadRecentItems() async {
    _recentItems = await SettingsService.loadRecentItems();
    notifyListeners();
  }

  Future<void> _addRecentLogFile(String path) async {
    final item = RecentItem(
      path: path,
      type: RecentItemType.log,
      openedAt: DateTime.now(),
    );
    await SettingsService.addRecentItem(item);
    _recentItems = await SettingsService.loadRecentItems();
    notifyListeners();
  }

  Future<void> _addRecentDbFile(String path) async {
    final item = RecentItem(
      path: path,
      type: RecentItemType.database,
      openedAt: DateTime.now(),
    );
    await SettingsService.addRecentItem(item);
    _recentItems = await SettingsService.loadRecentItems();
    notifyListeners();
  }

  Future<void> removeRecentItem(String path) async {
    await SettingsService.removeRecentItem(path);
    _recentItems = await SettingsService.loadRecentItems();
    notifyListeners();
  }

  Future<void> openFileByPath(String path, {bool isDb = false}) async {
    final file = File(path);
    if (!await file.exists()) {
      if (isDb) {
        _dbErrorMessage = 'File not found: $path';
      } else {
        _errorMessage = 'File not found: $path';
      }
      notifyListeners();
      return;
    }

    if (isDb) {
      await _setDatabaseFile(file);
    } else {
      _selectedFile = file;
      _decryptedContent = '';
      _status = 'File selected: ${FileService.getFileName(file.path)}';
      _errorMessage = '';
      await _addRecentLogFile(file.path);
      notifyListeners();
    }
  }

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
        await _addRecentLogFile(file.path);
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
    _logSearchQuery = '';
    _dbRowSearchQuery = '';
    _sqlQuery = '';
    _sqlQueryResult = null;
    _sqlStatus = '';
    _sqlErrorMessage = '';
    _tableSchema = null;
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

  Future<void> selectBatchFiles() async {
    try {
      _batchErrorMessage = '';
      _batchStatus = 'Selecting files...';
      notifyListeners();

      final files = await FileService.pickEncryptedFiles();
      if (files.isNotEmpty) {
        _batchFiles = files;
        _batchResults = [];
        _batchStatus =
            '${files.length} file${files.length == 1 ? '' : 's'} selected';
        for (final file in files) {
          await _addRecentLogFile(file.path);
        }
      } else {
        _batchStatus = '';
      }
    } catch (e) {
      _batchErrorMessage = e.toString();
      _batchStatus = '';
    }
    notifyListeners();
  }

  Future<void> selectBatchFolder() async {
    try {
      _batchErrorMessage = '';
      _batchStatus = 'Selecting folder...';
      notifyListeners();

      final directory = await FileService.pickEncryptedFolder();
      if (directory == null) {
        _batchStatus = '';
        notifyListeners();
        return;
      }

      _batchStatus = 'Scanning folder...';
      notifyListeners();

      final files = await FileService.findEncryptedFiles(directory);
      if (files.isNotEmpty) {
        _batchFiles = files;
        _batchResults = [];
        _batchStatus =
            'Found ${files.length} encrypted file${files.length == 1 ? '' : 's'}';
        for (final file in files) {
          await _addRecentLogFile(file.path);
        }
      } else {
        _batchFiles = [];
        _batchResults = [];
        _batchStatus = 'No .txt files found in selected folder';
      }
    } catch (e) {
      _batchErrorMessage = e.toString();
      _batchStatus = '';
    }
    notifyListeners();
  }

  Future<void> setBatchOutputFolder() async {
    try {
      _batchErrorMessage = '';
      _batchStatus = 'Selecting output folder...';
      notifyListeners();

      final directory = await FileService.pickEncryptedFolder();
      if (directory == null) {
        _batchStatus = '';
        notifyListeners();
        return;
      }

      _batchOutputFolder = directory.path;
      _batchStatus = 'Output folder: ${directory.path}';
    } catch (e) {
      _batchErrorMessage = e.toString();
      _batchStatus = '';
    }
    notifyListeners();
  }

  Future<void> decryptBatch() async {
    if (_batchFiles.isEmpty) {
      _batchErrorMessage = 'Please select files or a folder first';
      notifyListeners();
      return;
    }

    if (_encryptionMode != EncryptionMode.rsaChunkedBase64) {
      if (_password.trim().isEmpty) {
        _batchErrorMessage = 'Please enter a password';
        notifyListeners();
        return;
      }
    }

    _isBatchRunning = true;
    _batchResults = [];
    _batchErrorMessage = '';
    _batchStatus = 'Starting batch decryption...';
    notifyListeners();

    String? privateKeyPem;
    if (_encryptionMode == EncryptionMode.rsaChunkedBase64) {
      try {
        privateKeyPem = await _resolveRsaPrivateKeyPem();
      } catch (e) {
        _batchErrorMessage = e.toString();
        _batchStatus = '';
        _isBatchRunning = false;
        notifyListeners();
        return;
      }
    }

    final outputDir = _batchOutputFolder.isEmpty
        ? Directory.current.path
        : _batchOutputFolder;

    final results = <BatchResult>[];
    for (var i = 0; i < _batchFiles.length; i++) {
      final file = _batchFiles[i];
      final stopwatch = Stopwatch()..start();
      _batchStatus =
          'Decrypting ${i + 1} / ${_batchFiles.length}: ${FileService.getFileName(file.path)}';
      notifyListeners();

      try {
        final encryptedBytes = await FileService.readFileAsBytes(file);
        late final Uint8List decryptedBytes;
        if (_encryptionMode == EncryptionMode.rsaChunkedBase64) {
          decryptedBytes = EncryptionService.decryptRsaChunkedData(
            encryptedBytes,
            privateKeyPem!,
          );
        } else {
          decryptedBytes = EncryptionService.decryptData(
            encryptedBytes,
            _password.trim(),
            _encryptionMode,
          );
        }
        final content = utf8.decode(decryptedBytes);

        final baseName = FileService.getFileName(file.path);
        final nameWithoutExt = baseName.contains('.')
            ? baseName.substring(0, baseName.lastIndexOf('.'))
            : baseName;
        final outputName = '${nameWithoutExt}_decrypted.txt';
        final outputPath = '$outputDir${Platform.pathSeparator}$outputName';
        await File(outputPath).writeAsString(content);

        results.add(
          BatchResult(
            inputPath: file.path,
            outputPath: outputPath,
            durationMs: stopwatch.elapsedMilliseconds,
          ),
        );
      } catch (e) {
        results.add(
          BatchResult(
            inputPath: file.path,
            error: e.toString(),
            durationMs: stopwatch.elapsedMilliseconds,
          ),
        );
      }
    }

    _batchResults = results;
    final successCount = results.where((r) => r.success).length;
    _batchStatus =
        'Batch complete: $successCount / ${results.length} files decrypted';
    _isBatchRunning = false;
    notifyListeners();
  }

  void clearBatch() {
    _batchFiles = [];
    _batchResults = [];
    _batchStatus = '';
    _batchErrorMessage = '';
    _isBatchRunning = false;
    _batchOutputFolder = '';
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
        _isDbLoading = false;
        notifyListeners();
        return;
      }

      await _setDatabaseFile(file);
    } catch (e) {
      _dbErrorMessage = 'Failed to load database: $e';
      _dbStatus = '';
      _isDbLoading = false;
      notifyListeners();
    }
  }

  Future<void> _setDatabaseFile(File file) async {
    _selectedDbFile = file;
    _dbStatus =
        'Loading tables from ${FileService.getFileName(file.path)}...';
    _dbErrorMessage = '';
    notifyListeners();

    _dbTables = DatabaseService.listTables(file);
    _dbTableSearchQuery = '';
    _selectedDbTable = null;
    _dbColumns = [];
    _dbRows = [];
    _dbStatus =
        'Database loaded (${_dbTables.length} table${_dbTables.length == 1 ? '' : 's'})';
    await _addRecentDbFile(file.path);
    _isDbLoading = false;
    notifyListeners();
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
      _tableSchema = DatabaseService.readTableSchema(_selectedDbFile!, tableName);
      _dbStatus = 'Showing ${_dbRows.length} rows from "$tableName"';
    } catch (e) {
      _dbColumns = [];
      _dbRows = [];
      _tableSchema = null;
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
    _tableSchema = null;
    notifyListeners();
  }

  void updateDbTableSearchQuery(String query) {
    _dbTableSearchQuery = query;
    notifyListeners();
  }

  void updateLogSearchQuery(String query) {
    _logSearchQuery = query;
    notifyListeners();
  }

  void updateDbRowSearchQuery(String query) {
    _dbRowSearchQuery = query;
    notifyListeners();
  }

  void updateSqlQuery(String query) {
    _sqlQuery = query;
    notifyListeners();
  }

  Future<void> executeSqlQuery() async {
    if (_selectedDbFile == null) {
      _sqlErrorMessage = 'Please upload a database file first';
      notifyListeners();
      return;
    }

    if (_sqlQuery.trim().isEmpty) {
      _sqlErrorMessage = 'Please enter a SQL query';
      notifyListeners();
      return;
    }

    try {
      _isDbLoading = true;
      _sqlErrorMessage = '';
      _sqlStatus = 'Executing query...';
      notifyListeners();

      final result = DatabaseService.executeQuery(_selectedDbFile!, _sqlQuery);
      _sqlQueryResult = result;
      _sqlStatus = 'Query returned ${result.rows.length} rows';
    } catch (e) {
      _sqlQueryResult = null;
      _sqlErrorMessage = 'Query failed: $e';
      _sqlStatus = '';
    } finally {
      _isDbLoading = false;
      notifyListeners();
    }
  }

  Future<void> exportDbResults({
    required List<String> columns,
    required List<List<String>> rows,
    required String tableName,
    required String format,
  }) async {
    if (columns.isEmpty) {
      _dbErrorMessage = 'No data to export';
      notifyListeners();
      return;
    }

    try {
      _isDbLoading = true;
      _dbErrorMessage = '';
      _dbStatus = 'Exporting...';
      notifyListeners();

      late final String content;
      late final String extension;
      late final String dialogTitle;
      switch (format.toLowerCase()) {
        case 'json':
          content = DatabaseService.exportToJson(columns, rows);
          extension = 'json';
          dialogTitle = 'Export as JSON';
          break;
        case 'sql':
          content = DatabaseService.exportToSqlInserts(tableName, columns, rows);
          extension = 'sql';
          dialogTitle = 'Export as SQL';
          break;
        case 'csv':
        default:
          content = DatabaseService.exportToCsv(columns, rows);
          extension = 'csv';
          dialogTitle = 'Export as CSV';
          break;
      }

      final filePath = await FileService.saveTextFile(
        content,
        suggestedFileName: '${tableName}_export_${DateTime.now().millisecondsSinceEpoch}.$extension',
        dialogTitle: dialogTitle,
        allowedExtensions: [extension],
        defaultExtension: extension,
      );
      _dbStatus = filePath == null ? 'Export cancelled' : 'Exported to: $filePath';
    } catch (e) {
      _dbErrorMessage = 'Export failed: $e';
      _dbStatus = '';
    } finally {
      _isDbLoading = false;
      notifyListeners();
    }
  }
}
