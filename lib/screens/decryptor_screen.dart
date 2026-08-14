// ignore_for_file: use_build_context_synchronously
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../main.dart';
import '../controller/decryptor_controller.dart';
import '../controller/theme_provider.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';
import '../services/file_service.dart';
import '../services/settings_service.dart';

enum _ToolMode { decryptor, batchDecryptor, databaseViewer }

class DecryptorScreen extends StatefulWidget {
  const DecryptorScreen({super.key});

  @override
  State<DecryptorScreen> createState() => _DecryptorScreenState();
}

class _DecryptorScreenState extends State<DecryptorScreen> {
  late TextEditingController _passwordController;
  late TextEditingController _decryptedContentController;
  late TextEditingController _logSearchController;
  late TextEditingController _dbTableSearchController;
  late TextEditingController _dbRowSearchController;
  late TextEditingController _sqlQueryController;
  late ScrollController _dbHorizontalScrollController;
  late ScrollController _dbVerticalScrollController;
  bool _obscurePassword = true;
  _ToolMode _selectedMode = _ToolMode.decryptor;
  bool _isDbTableViewExpanded = false;
  bool _isDraggingOver = false;
  bool _showSchemaPanel = false;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _decryptedContentController = TextEditingController();
    _logSearchController = TextEditingController();
    _dbTableSearchController = TextEditingController();
    _dbRowSearchController = TextEditingController();
    _sqlQueryController = TextEditingController();
    _dbHorizontalScrollController = ScrollController();
    _dbVerticalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _decryptedContentController.dispose();
    _logSearchController.dispose();
    _dbTableSearchController.dispose();
    _dbRowSearchController.dispose();
    _sqlQueryController.dispose();
    _dbHorizontalScrollController.dispose();
    _dbVerticalScrollController.dispose();
    super.dispose();
  }

  Future<void> _handleDroppedFiles(List<DropItem> files) async {
    if (files.isEmpty) return;

    final appState = Get.find<DecryptorController>();
    final first = files.first;
    final path = first.path;

    if (FileService.isDatabaseFile(path)) {
      setState(() => _selectedMode = _ToolMode.databaseViewer);
      await appState.openFileByPath(path, isDb: true);
    } else {
      setState(() => _selectedMode = _ToolMode.decryptor);
      await appState.openFileByPath(path, isDb: false);
    }

  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(40),
        child: TitleBar(),
      ),
      body: DropTarget(
        onDragEntered: (_) => setState(() => _isDraggingOver = true),
        onDragExited: (_) => setState(() => _isDraggingOver = false),
        onDragDone: (detail) {
          setState(() => _isDraggingOver = false);
          _handleDroppedFiles(detail.files);
        },
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSidebar(context),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.06),
                          colorScheme.surface,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: _buildMainContent(context),
                    ),
                  ),
                ),
              ],
            ),
          if (_isDraggingOver)
            Positioned.fill(
              child: IgnorePointer(
                child: Builder(
                  builder: (context) {
                    final overlayColor = Theme.of(context).colorScheme;
                    return Container(
                      color: overlayColor.primary.withValues(alpha: 0.15),
                      alignment: Alignment.center,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 20,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_upload_rounded,
                                size: 48,
                                color: overlayColor.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Drop file to open',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: overlayColor.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    ));
  }

  Widget _buildSidebar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeProvider = Get.find<ThemeController>();
    final isExtended = MediaQuery.of(context).size.width >= 1000;

    return NavigationRail(
      extended: isExtended,
      minExtendedWidth: 220,
      backgroundColor: colorScheme.surfaceContainerLowest,
      indicatorColor: colorScheme.primaryContainer,
      selectedIndex: _selectedMode.index,
      onDestinationSelected: (index) {
        setState(() => _selectedMode = _ToolMode.values[index]);
      },
      leading: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: .start,
          children: [
           /* ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/app_icon.png',
                width: 32,
                height: 32,
              ),
            ),*/
            if (isExtended) ...[
              const SizedBox(width: 12),
              const Text(
                'Log Decryptor',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.lock_open_outlined),
          selectedIcon: Icon(Icons.lock_open_rounded),
          label: Text('Decrypt Logs'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.folder_copy_outlined),
          selectedIcon: Icon(Icons.folder_copy_rounded),
          label: Text('Batch Decryption'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.table_view_outlined),
          selectedIcon: Icon(Icons.table_view_rounded),
          label: Text('DB Viewer'),
        ),
      ],
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: IconButton(
              tooltip: 'Toggle theme',
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: () => themeProvider.toggleTheme(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return GetBuilder<DecryptorController>(
      builder: (appState) {
        if (_selectedMode == _ToolMode.decryptor) {
          _decryptedContentController.text =
              appState.filteredDecryptedContent;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWide = width >= 900;
            final horizontalPadding = width >= 1100 ? 32.0 : 20.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                24,
                horizontalPadding,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(context),
                      const SizedBox(height: 24),
                      if (_selectedMode == _ToolMode.decryptor && isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _buildControlPanel(context, appState),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 6,
                              child: _buildContentCard(context, appState),
                            ),
                          ],
                        )
                      else if (_selectedMode == _ToolMode.decryptor)
                        Column(
                          children: [
                            _buildControlPanel(context, appState),
                            const SizedBox(height: 24),
                            _buildContentCard(context, appState),
                          ],
                        ),
                      if (_selectedMode == _ToolMode.databaseViewer && isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: _buildDbViewerPanel(context, appState),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 7,
                              child: _buildDbTableContentCard(
                                context,
                                appState,
                              ),
                            ),
                          ],
                        )
                      else if (_selectedMode == _ToolMode.databaseViewer)
                        Column(
                          children: [
                            _buildDbViewerPanel(context, appState),
                            const SizedBox(height: 24),
                            _buildDbTableContentCard(context, appState),
                          ],
                        ),
                      if (_selectedMode == _ToolMode.batchDecryptor)
                        _buildBatchPanel(context, appState),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (title, subtitle, icon) = switch (_selectedMode) {
      _ToolMode.decryptor => (
          'Decrypt Logs',
          'Decrypt encrypted log files with a password or RSA private key.',
          Icons.lock_open_rounded,
        ),
      _ToolMode.batchDecryptor => (
          'Batch Decryption',
          'Decrypt multiple files at once using the configured password and encryption mode.',
          Icons.folder_copy_rounded,
        ),
      _ToolMode.databaseViewer => (
          'Database Viewer',
          'Open SQLite databases, browse tables, run queries and export data.',
          Icons.table_view_rounded,
        ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context, DecryptorController appState) {
    return Column(
      children: [
        _buildFileSection(context, appState),
        const SizedBox(height: 20),
        _buildRecentItemsSection(context, appState, RecentItemType.log),
        const SizedBox(height: 20),
        _buildPasswordSection(context, appState),
        const SizedBox(height: 20),
        _buildButtonsSection(context, appState),
        if (appState.status.isNotEmpty || appState.errorMessage.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildStatusSection(context, appState),
        ],
      ],
    );
  }

  Widget _buildRecentItemsSection(
    BuildContext context,
    DecryptorController appState,
    RecentItemType type,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = type == RecentItemType.log
        ? appState.recentLogFiles
        : appState.recentDbFiles;

    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type == RecentItemType.log ? 'Recent log files' : 'Recent databases',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      type == RecentItemType.log
                          ? Icons.insert_drive_file_outlined
                          : Icons.storage_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    title: Text(
                      FileService.getFileName(item.path),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      item.path,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.outline,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      tooltip: 'Remove from recent',
                      onPressed: () => appState.removeRecentItem(item.path),
                    ),
                    onTap: () => appState.openFileByPath(
                      item.path,
                      isDb: type == RecentItemType.database,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchPanel(BuildContext context, DecryptorController appState) {
    return Column(
      children: [
        _buildPasswordSection(context, appState),
        const SizedBox(height: 20),
        _buildBatchSection(context, appState),
      ],
    );
  }

  Widget _buildBatchSection(BuildContext context, DecryptorController appState) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasFiles = appState.hasBatchFiles;
    final hasResults = appState.hasBatchResults;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Batch Decryption',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                if (hasFiles)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      '${appState.batchFiles.length} files',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 11.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: appState.isBatchRunning
                      ? null
                      : () => appState.selectBatchFiles(),
                  icon: const Icon(Icons.file_copy_rounded),
                  label: const Text('Select Files'),
                ),
                OutlinedButton.icon(
                  onPressed: appState.isBatchRunning
                      ? null
                      : () => appState.selectBatchFolder(),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Select Folder'),
                ),
                if (hasFiles)
                  OutlinedButton.icon(
                    onPressed: appState.isBatchRunning
                        ? null
                        : () => appState.clearBatch(),
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Clear'),
                  ),
              ],
            ),
            if (hasFiles) ...[
              const SizedBox(height: 16),
              Text(
                'Output folder: ${appState.batchOutputFolder.isEmpty ? 'Same as source (current directory for multi-source)' : appState.batchOutputFolder}',
                style: TextStyle(fontSize: 12, color: colorScheme.outline),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: appState.isBatchRunning
                    ? null
                    : () => appState.setBatchOutputFolder(),
                icon: const Icon(Icons.drive_file_move_outline),
                label: const Text('Choose Output Folder'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: appState.isBatchRunning
                      ? null
                      : () => appState.decryptBatch(),
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text('Decrypt All',style: TextStyle(fontWeight: FontWeight.bold),),
                ),
              ),
            ],
            if (appState.isBatchRunning) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                borderRadius: BorderRadius.circular(8),
              ),
            ],
            if (appState.batchStatus.isNotEmpty ||
                appState.batchErrorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildBatchStatusSection(context, appState),
            ],
            if (hasResults) ...[
              const SizedBox(height: 16),
              _buildBatchResultsSection(context, appState),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBatchStatusSection(BuildContext context, DecryptorController appState) {
    final colorScheme = Theme.of(context).colorScheme;
    final isError = appState.batchErrorMessage.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError
            ? Color.alphaBlend(
                Colors.red.withValues(alpha: 0.08),
                colorScheme.surface,
              )
            : Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.08),
                colorScheme.surface,
              ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: isError ? Colors.red.shade700 : colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isError ? appState.batchErrorMessage : appState.batchStatus,
              style: TextStyle(
                color: isError ? Colors.red.shade800 : colorScheme.onSurface,
                fontSize: 12.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchResultsSection(BuildContext context, DecryptorController appState) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(10),
        itemCount: appState.batchResults.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final result = appState.batchResults[index];
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success ? Colors.green : Colors.red,
              size: 18,
            ),
            title: Text(
              FileService.getFileName(result.inputPath),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5),
            ),
            subtitle: result.success
                ? Text(
                    'Saved: ${result.outputPath}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: colorScheme.outline),
                  )
                : Text(
                    'Error: ${result.error}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: Colors.red.shade700),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildDbViewerPanel(BuildContext context, DecryptorController appState) {
    return Column(
      children: [
        _buildDbFileSection(context, appState),
        const SizedBox(height: 20),
        _buildRecentItemsSection(context, appState, RecentItemType.database),
        const SizedBox(height: 20),
        _buildDbTableListSection(context, appState),
        const SizedBox(height: 20),
        _buildSqlQuerySection(context, appState),
        if (appState.dbStatus.isNotEmpty ||
            appState.dbErrorMessage.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildDbStatusSection(context, appState),
        ],
      ],
    );
  }

  Widget _buildSqlQuerySection(BuildContext context, DecryptorController appState) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasResult = appState.sqlQueryResult != null;

    if (_sqlQueryController.text != appState.sqlQuery) {
      _sqlQueryController.value = TextEditingValue(
        text: appState.sqlQuery,
        selection: TextSelection.collapsed(offset: appState.sqlQuery.length),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SQL Query',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _sqlQueryController,
              onChanged: appState.updateSqlQuery,
              maxLines: 4,
              minLines: 2,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
              decoration: InputDecoration(
                hintText:
                    'SELECT * FROM table_name LIMIT 50',
                suffixIcon: IconButton(
                  tooltip: 'Run query',
                  icon: const Icon(Icons.play_arrow),
                  onPressed: appState.isDbLoading
                      ? null
                      : () => appState.executeSqlQuery(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: appState.isDbLoading
                      ? null
                      : () => appState.executeSqlQuery(),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Run Query'),
                ),
                if (hasResult)
                  OutlinedButton.icon(
                    onPressed: appState.isDbLoading
                        ? null
                        : () => _copyToClipboard(
                              context,
                              DatabaseService.exportToCsv(
                                appState.sqlQueryResult!.columns,
                                appState.sqlQueryResult!.rows,
                              ),
                              'Query result copied as CSV',
                            ),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
              ],
            ),
            if (appState.sqlStatus.isNotEmpty ||
                appState.sqlErrorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSqlStatusSection(context, appState),
            ],
            if (hasResult) ...[
              const SizedBox(height: 16),
              Text(
                'Query Result',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(
                  minHeight: 160,
                  maxHeight: 320,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.18,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: appState.sqlQueryResult!.columns
                            .map((c) => DataColumn(label: Text(c)))
                            .toList(),
                        rows: appState.sqlQueryResult!.rows
                            .map(
                              (row) => DataRow(
                                cells: row
                                    .map(
                                      (value) => DataCell(
                                        SelectableText(
                                          value,
                                          minLines: 1,
                                          maxLines: 1,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSqlStatusSection(BuildContext context, DecryptorController appState) {
    final colorScheme = Theme.of(context).colorScheme;
    final isError = appState.sqlErrorMessage.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError
            ? Color.alphaBlend(
                Colors.red.withValues(alpha: 0.08),
                colorScheme.surface,
              )
            : Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.08),
                colorScheme.surface,
              ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: isError ? Colors.red.shade700 : colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isError ? appState.sqlErrorMessage : appState.sqlStatus,
              style: TextStyle(
                color: isError ? Colors.red.shade800 : colorScheme.onSurface,
                fontSize: 12.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDbFileSection(BuildContext context, DecryptorController appState) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 1 · Upload database file',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    appState.selectedDbFile == null
                        ? Icons.storage_outlined
                        : Icons.check_circle,
                    size: 18,
                    color: appState.selectedDbFile == null
                        ? colorScheme.outline
                        : colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      appState.selectedDbFile?.path ?? 'No .db file selected',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: appState.selectedDbFile == null
                            ? colorScheme.outline
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: appState.isDbLoading
                      ? null
                      : () => appState.selectDatabaseFile(),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Upload .db File'),
                ),
                if (appState.selectedDbFile != null)
                  OutlinedButton.icon(
                    onPressed: appState.isDbLoading
                        ? null
                        : () => appState.clearDatabaseSelection(),
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Clear DB Selection'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDbTableListSection(BuildContext context, DecryptorController appState) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredTables = appState.filteredDbTables;
    if (_dbTableSearchController.text != appState.dbTableSearchQuery) {
      _dbTableSearchController.value = TextEditingValue(
        text: appState.dbTableSearchQuery,
        selection: TextSelection.collapsed(
          offset: appState.dbTableSearchQuery.length,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 2 · Choose table',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dbTableSearchController,
              onChanged: appState.updateDbTableSearchQuery,
              decoration: InputDecoration(
                labelText: 'Search table name',
                hintText: 'Type to filter tables',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: appState.dbTableSearchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _dbTableSearchController.clear();
                          appState.updateDbTableSearchQuery('');
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),
            if (appState.dbTables.isEmpty)
              Text(
                'Upload a database file to view available tables.',
                style: TextStyle(color: colorScheme.outline),
              )
            else if (filteredTables.isEmpty)
              Text(
                'No tables found for "${appState.dbTableSearchQuery}".',
                style: TextStyle(color: colorScheme.outline),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filteredTables.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final tableName = filteredTables[index];
                    final isSelected = appState.selectedDbTable == tableName;
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: appState.isDbLoading
                          ? null
                          : () => appState.selectDatabaseTable(tableName),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.12)
                              : colorScheme.surfaceContainerHighest.withValues(
                                  alpha: 0.2,
                                ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.table_rows_rounded,
                              size: 16,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tableName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDbStatusSection(BuildContext context, DecryptorController appState) {
    final colorScheme = Theme.of(context).colorScheme;
    final isError = appState.dbErrorMessage.isNotEmpty;

    return Card(
      color: isError
          ? Color.alphaBlend(
              Colors.red.withValues(alpha: 0.08),
              colorScheme.surface,
            )
          : Color.alphaBlend(
              colorScheme.primary.withValues(alpha: 0.08),
              colorScheme.surface,
            ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: isError ? Colors.red.shade700 : colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isError ? appState.dbErrorMessage : appState.dbStatus,
                style: TextStyle(
                  color: isError ? Colors.red.shade800 : colorScheme.onSurface,
                  fontSize: 12.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSection(BuildContext context, DecryptorController appState) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 1 · Select encrypted file',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    appState.selectedFile == null
                        ? Icons.insert_drive_file_outlined
                        : Icons.check_circle,
                    size: 18,
                    color: appState.selectedFile == null
                        ? colorScheme.outline
                        : colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      appState.selectedFile?.path ?? 'No file selected',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: appState.selectedFile == null
                            ? colorScheme.outline
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => appState.selectFile(),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Browse File'),
                ),
                if (appState.selectedFile != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      appState.clearSelectedFile();
                      appState.updatePassword('');
                      _passwordController.clear();
                    },
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Clear Selection'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSection(BuildContext context, DecryptorController appState) {
    final isRsaMode =
        appState.encryptionMode == EncryptionMode.rsaChunkedBase64;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 2 · Provide decryption details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<EncryptionMode>(
              initialValue: appState.encryptionMode,
              decoration: const InputDecoration(labelText: 'Encryption mode'),
              items: EncryptionMode.values
                  .map(
                    (mode) => DropdownMenuItem<EncryptionMode>(
                      value: mode,
                      child: Text(mode.label),
                    ),
                  )
                  .toList(),
              onChanged: (mode) {
                if (mode != null) {
                  appState.updateEncryptionMode(mode);
                }
              },
            ),
            const SizedBox(height: 16),
            if (!isRsaMode)
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  appState.updatePassword(value);
                },
              ),
            if (isRsaMode) _buildRsaKeySection(appState),
            const SizedBox(height: 10),
            Text(
              isRsaMode
                  ? 'RSA mode uses the bundled private key by default. You can choose a .pem key manually.'
                  : 'Password is case-sensitive. Make sure mode matches how the file was encrypted.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRsaKeySection(DecryptorController appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (appState.privateKeyFile != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.vpn_key, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    appState.privateKeyFile!.path,
                    style: const TextStyle(fontSize: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => appState.selectPrivateKeyFile(),
          icon: const Icon(Icons.key),
          label: const Text('Select Private Key (.pem)'),
        ),
      ],
    );
  }

  Widget _buildButtonsSection(BuildContext context, DecryptorController appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: appState.isLoading || appState.selectedFile == null
                  ? null
                  : () => appState.decryptFile(),
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('Decrypt'),
            ),
            if (appState.hasDecryptedContent)
              OutlinedButton.icon(
                onPressed: appState.isLoading
                    ? null
                    : () => _handleSaveAs(context, appState),
                icon: const Icon(Icons.save_alt_rounded),
                label: const Text('Save As'),
              ),
            if (appState.isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSaveAs(BuildContext context, DecryptorController appState) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Save decrypted file'),
          content: const Text(
            'Choose whether to save with the app-provided filename or enter your own filename.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('app'),
              child: const Text('App name'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('custom'),
              child: const Text('Custom name'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (!mounted || choice == null) {
      return;
    }

    final currentContext = this.context;
    String? suggestedFileName;
    if (choice == 'app') {
      suggestedFileName =
          'decrypted_log_${DateTime.now().millisecondsSinceEpoch}.txt';
    } else if (choice == 'custom') {
      final controller = TextEditingController(
        text: 'decrypted_log_${DateTime.now().millisecondsSinceEpoch}.txt',
      );
      try {
        suggestedFileName = await showDialog<String>(
          context: currentContext,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Custom filename'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'File name',
                  hintText: 'example.txt',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    Navigator.of(dialogContext).pop(value);
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      } finally {
        controller.dispose();
      }

      if (suggestedFileName == null || suggestedFileName.trim().isEmpty) {
        return;
      }
    }

    await appState.saveDecryptedContent(suggestedFileName: suggestedFileName);
  }

  Widget _buildStatusSection(BuildContext context, DecryptorController appState) {
    final colorScheme = Theme.of(context).colorScheme;
    final isError = appState.errorMessage.isNotEmpty;

    return Card(
      color: isError
          ? Color.alphaBlend(
              Colors.red.withValues(alpha: 0.08),
              colorScheme.surface,
            )
          : Color.alphaBlend(
              colorScheme.primary.withValues(alpha: 0.08),
              colorScheme.surface,
            ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: isError ? Colors.red.shade700 : colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isError ? appState.errorMessage : appState.status,
                style: TextStyle(
                  color: isError ? Colors.red.shade800 : colorScheme.onSurface,
                  fontSize: 12.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, DecryptorController appState) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewportHeight = MediaQuery.of(context).size.height;
    final contentHeight = viewportHeight < 760 ? 300.0 : 430.0;
    final hasContent = appState.decryptedContent.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Decrypted Content',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                if (hasContent) ...[
                  IconButton(
                    tooltip: 'Copy to clipboard',
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () => _copyToClipboard(
                      context,
                      appState.decryptedContent,
                      'Decrypted content copied',
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    '${appState.decryptedContent.length} chars',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 11.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (hasContent)
              TextField(
                controller: _logSearchController,
                onChanged: appState.updateLogSearchQuery,
                decoration: InputDecoration(
                  labelText: 'Search in decrypted log',
                  hintText: 'Filter lines...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: appState.logSearchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _logSearchController.clear();
                            appState.updateLogSearchQuery('');
                          },
                        ),
                ),
              ),
            if (hasContent) const SizedBox(height: 16),
            Container(
              height: contentHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.18,
                ),
              ),
              child: TextField(
                controller: _decryptedContentController,
                readOnly: true,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                  hintText: 'Decrypted content will appear here',
                  hintStyle: TextStyle(color: colorScheme.outline),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(
    BuildContext context,
    String text,
    String successMessage,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage), duration: const Duration(seconds: 2)),
      );
    }
  }

  Widget _buildDbTableContentCard(BuildContext context, DecryptorController appState) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasTableSelection = appState.selectedDbTable != null;
    final hasColumns = appState.dbColumns.isNotEmpty;
    final viewportHeight = MediaQuery.of(context).size.height;
    final contentMinHeight = _isDbTableViewExpanded ? 480.0 : 300.0;
    final contentMaxHeight = _isDbTableViewExpanded
        ? viewportHeight * 0.78
        : 460.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    hasTableSelection
                        ? 'Table: ${appState.selectedDbTable}'
                        : 'Table Content',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (hasTableSelection) ...[
                  IconButton(
                    tooltip: 'Copy rows as CSV',
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () => _copyToClipboard(
                      context,
                      DatabaseService.exportToCsv(
                        appState.filteredDbColumns,
                        appState.filteredDbRows,
                      ),
                      'Table data copied as CSV',
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: _showSchemaPanel ? 'Hide schema' : 'Show schema',
                    icon: Icon(
                      _showSchemaPanel
                          ? Icons.schema_rounded
                          : Icons.table_chart_outlined,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _showSchemaPanel = !_showSchemaPanel;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildExportMenu(context, appState),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      '${appState.filteredDbRows.length} / ${appState.dbRows.length} rows',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 11.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                IconButton(
                  tooltip: _isDbTableViewExpanded
                      ? 'Collapse table view'
                      : 'Expand table view',
                  onPressed: () {
                    setState(() {
                      _isDbTableViewExpanded = !_isDbTableViewExpanded;
                    });
                  },
                  icon: Icon(
                    _isDbTableViewExpanded
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (hasTableSelection) ...[
              TextField(
                controller: _dbRowSearchController,
                onChanged: appState.updateDbRowSearchQuery,
                decoration: InputDecoration(
                  labelText: 'Filter rows or columns',
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: appState.dbRowSearchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _dbRowSearchController.clear();
                            appState.updateDbRowSearchQuery('');
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (!hasTableSelection)
              _buildDbContentHint(
                context,
                message:
                    'Upload a .db file and choose a table to view its contents.',
                minHeight: contentMinHeight,
              )
            else if (!hasColumns)
              _buildDbContentHint(
                context,
                message: 'The selected table has no columns to display.',
                minHeight: contentMinHeight,
              )
            else
              Container(
                constraints: BoxConstraints(
                  minHeight: contentMinHeight,
                  maxHeight: contentMaxHeight,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.18,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Scrollbar(
                    controller: _dbHorizontalScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: SingleChildScrollView(
                      controller: _dbHorizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: Scrollbar(
                        controller: _dbVerticalScrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        child: SingleChildScrollView(
                          controller: _dbVerticalScrollController,
                          child: DataTable(
                            columns: appState.filteredDbColumns
                                .map(
                                  (column) => DataColumn(label: Text(column)),
                                )
                                .toList(),
                            rows: appState.filteredDbRows
                                .map(
                                  (row) => DataRow(
                                    cells: row
                                        .map(
                                          (value) => DataCell(
                                            SelectableText(
                                              value,
                                              minLines: 1,
                                              maxLines: 1,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (hasTableSelection && _showSchemaPanel) ...[
              const SizedBox(height: 16),
              _buildSchemaPanel(context, appState),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExportMenu(BuildContext context, DecryptorController appState) {
    final tableName = appState.selectedDbTable ?? 'query_result';
    final columns = appState.filteredDbColumns;
    final rows = appState.filteredDbRows;

    return PopupMenuButton<String>(
      tooltip: 'Export table',
      icon: const Icon(Icons.download, size: 18),
      onSelected: (format) => appState.exportDbResults(
        columns: columns,
        rows: rows,
        tableName: tableName,
        format: format,
      ),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'csv', child: Text('Export as CSV')),
        PopupMenuItem(value: 'json', child: Text('Export as JSON')),
        PopupMenuItem(value: 'sql', child: Text('Export as SQL INSERTs')),
      ],
    );
  }

  Widget _buildSchemaPanel(BuildContext context, DecryptorController appState) {
    final colorScheme = Theme.of(context).colorScheme;
    final schema = appState.tableSchema;

    if (schema == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schema',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          if (schema.ddl.isNotEmpty) ...[
            SelectableText(
              schema.ddl,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 16),
          ],
          if (schema.indexes.isNotEmpty) ...[
            Text(
              'Indexes',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            ...schema.indexes.map(
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: SelectableText(
                  index['sql'] ?? index['name'] ?? '',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (schema.foreignKeys.isNotEmpty) ...[
            Text(
              'Foreign Keys',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            ...schema.foreignKeys.map(
              (fk) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: SelectableText(
                  '${fk['from']} → ${fk['table']}.${fk['to']}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDbContentHint(
    BuildContext context, {
    required String message,
    required double minHeight,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.outline),
        ),
      ),
    );
  }

}


