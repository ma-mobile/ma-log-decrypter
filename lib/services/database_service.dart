import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:sqlite3/sqlite3.dart';

class DatabaseTableData {
  const DatabaseTableData({required this.columns, required this.rows});

  final List<String> columns;
  final List<List<String>> rows;
}

class QueryResult {
  const QueryResult({required this.columns, required this.rows});

  final List<String> columns;
  final List<List<String>> rows;
}

class TableSchema {
  const TableSchema({
    required this.ddl,
    required this.indexes,
    required this.foreignKeys,
  });

  final String ddl;
  final List<Map<String, String>> indexes;
  final List<Map<String, String>> foreignKeys;
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

  static QueryResult executeQuery(File databaseFile, String sql) {
    final trimmed = sql.trim();
    if (trimmed.isEmpty) {
      throw Exception('SQL query is empty');
    }

    final upper = trimmed.toUpperCase();
    if (!(upper.startsWith('SELECT ') ||
        upper.startsWith('WITH ') ||
        upper.startsWith('EXPLAIN ') ||
        upper.startsWith('PRAGMA '))) {
      throw Exception(
        'Only read-only queries are allowed (SELECT, WITH, EXPLAIN, PRAGMA).',
      );
    }

    final db = sqlite3.open(databaseFile.path);
    try {
      final result = db.select(trimmed);
      final columns = result.columnNames;
      final rows = result
          .map(
            (row) => List<String>.generate(
              columns.length,
              (index) => _formatCellValue(row.columnAt(index)),
            ),
          )
          .toList();
      return QueryResult(columns: columns, rows: rows);
    } finally {
      db.dispose();
    }
  }

  static TableSchema readTableSchema(File databaseFile, String tableName) {
    final db = sqlite3.open(databaseFile.path);
    try {
      final escapedTableName = tableName.replaceAll('"', '""');

      final ddlResult = db.select('''
        SELECT sql
        FROM sqlite_master
        WHERE type = 'table' AND name = ?
      ''', [tableName]);
      final ddl = ddlResult.isEmpty
          ? ''
          : (ddlResult.first['sql'] as String? ?? '');

      final indexResult = db.select('''
        SELECT name, sql
        FROM sqlite_master
        WHERE type = 'index' AND tbl_name = ?
        ORDER BY name
      ''', [tableName]);
      final indexes = indexResult
          .map(
            (row) => {
              'name': row['name'] as String? ?? '',
              'sql': row['sql'] as String? ?? '',
            },
          )
          .toList();

      final fkResult = db.select(
        'PRAGMA foreign_key_list("$escapedTableName")',
      );
      final foreignKeys = fkResult
          .map(
            (row) => {
              'id': row['id'].toString(),
              'seq': row['seq'].toString(),
              'table': row['table'] as String? ?? '',
              'from': row['from'] as String? ?? '',
              'to': row['to'] as String? ?? '',
              'on_update': row['on_update'] as String? ?? '',
              'on_delete': row['on_delete'] as String? ?? '',
            },
          )
          .toList();

      return TableSchema(ddl: ddl, indexes: indexes, foreignKeys: foreignKeys);
    } finally {
      db.dispose();
    }
  }

  static String exportToCsv(List<String> columns, List<List<String>> rows) {
    final list = <List<String>>[
      columns,
      ...rows,
    ];
    return const ListToCsvConverter().convert(list);
  }

  static String exportToJson(List<String> columns, List<List<String>> rows) {
    final objects = rows.map((row) {
      final map = <String, String>{};
      for (var i = 0; i < columns.length; i++) {
        map[columns[i]] = i < row.length ? row[i] : '';
      }
      return map;
    }).toList();
    return const JsonEncoder.withIndent('  ').convert(objects);
  }

  static String exportToSqlInserts(
    String tableName,
    List<String> columns,
    List<List<String>> rows,
  ) {
    final escapedColumns = columns.map(_escapeIdentifier).join(', ');
    final buffer = StringBuffer();
    for (final row in rows) {
      final values = row.map(_escapeSqlLiteral).join(', ');
      buffer.writeln(
        'INSERT INTO ${_escapeIdentifier(tableName)} ($escapedColumns) VALUES ($values);',
      );
    }
    return buffer.toString();
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

  static String _escapeIdentifier(String identifier) {
    return '"${identifier.replaceAll('"', '""')}"';
  }

  static String _escapeSqlLiteral(String value) {
    if (value == 'NULL') return 'NULL';
    return "'${value.replaceAll("'", "''")}'";
  }
}
