import 'dart:io';
import 'dart:typed_data';
import 'package:sqlite3/sqlite3.dart';

class DatabaseTableData {
  const DatabaseTableData({required this.columns, required this.rows});

  final List<String> columns;
  final List<List<String>> rows;
}

class DatabaseService {
  static const int _defaultRowLimit = 200;

  static List<String> listTables(File databaseFile) {
    final db = sqlite3.open(databaseFile.path);
    try {
      final result = db.select('''
        SELECT name
        FROM sqlite_master
        WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
        ORDER BY name
      ''');
      return result.map((row) => row['name'] as String).toList();
    } finally {
      db.dispose();
    }
  }

  static DatabaseTableData readTable(
    File databaseFile,
    String tableName, {
    int rowLimit = _defaultRowLimit,
  }) {
    final db = sqlite3.open(databaseFile.path);
    try {
      final escapedTableName = tableName.replaceAll('"', '""');
      final result = db.select('SELECT * FROM "$escapedTableName" LIMIT ?', [
        rowLimit,
      ]);

      final columns = result.columnNames;
      final rows = result
          .map(
            (row) => List<String>.generate(
              columns.length,
              (index) => _formatCellValue(row.columnAt(index)),
            ),
          )
          .toList();

      return DatabaseTableData(columns: columns, rows: rows);
    } finally {
      db.dispose();
    }
  }

  static String _formatCellValue(Object? value) {
    if (value == null) {
      return 'NULL';
    }
    if (value is Uint8List) {
      return '<BLOB ${value.length} bytes>';
    }
    return value.toString();
  }
}
