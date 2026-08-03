// ignore_for_file: use_build_context_synchronously
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/encryption_service.dart';

enum _ToolMode { decryptor, databaseViewer }

class DecryptorScreen extends StatefulWidget {
  const DecryptorScreen({super.key});

  @override
  State<DecryptorScreen> createState() => _DecryptorScreenState();
}

class _DecryptorScreenState extends State<DecryptorScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _passwordController;
  late TextEditingController _decryptedContentController;
  late TextEditingController _dbTableSearchController;
  late ScrollController _dbHorizontalScrollController;
  late ScrollController _dbVerticalScrollController;
  late AnimationController _partyController;
  final Random _random = Random();
  List<_PartyParticle> _partyParticles = [];
  int _footerTapCount = 0;
  DateTime? _lastFooterTapAt;
  bool _obscurePassword = true;
  _ToolMode _selectedMode = _ToolMode.decryptor;
  bool _isDbTableViewExpanded = false;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _decryptedContentController = TextEditingController();
    _dbTableSearchController = TextEditingController();
    _dbHorizontalScrollController = ScrollController();
    _dbVerticalScrollController = ScrollController();
    _partyController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1300),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            setState(() {
              _partyParticles = [];
            });
          }
        });
  }

  @override
  void dispose() {
    _partyController.dispose();
    _passwordController.dispose();
    _decryptedContentController.dispose();
    _dbTableSearchController.dispose();
    _dbHorizontalScrollController.dispose();
    _dbVerticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Log File Decryptor',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          Container(
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
              child: Consumer<AppState>(
                builder: (context, appState, _) {
                  if (_selectedMode == _ToolMode.decryptor) {
                    _decryptedContentController.text =
                        appState.decryptedContent;
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final isWide = width >= 1040;
                      final horizontalPadding = width >= 1200 ? 32.0 : 18.0;

                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          18,
                          horizontalPadding,
                          24,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1240),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeaderCard(context),
                                const SizedBox(height: 18),
                                _buildModeMenu(context),
                                const SizedBox(height: 18),
                                if (_selectedMode == _ToolMode.decryptor &&
                                    isWide)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: _buildControlPanel(
                                          context,
                                          appState,
                                        ),
                                      ),
                                      const SizedBox(width: 18),
                                      Expanded(
                                        flex: 6,
                                        child: _buildContentCard(
                                          context,
                                          appState,
                                        ),
                                      ),
                                    ],
                                  )
                                else if (_selectedMode == _ToolMode.decryptor)
                                  Column(
                                    children: [
                                      _buildControlPanel(context, appState),
                                      const SizedBox(height: 18),
                                      _buildContentCard(context, appState),
                                    ],
                                  ),
                                if (_selectedMode == _ToolMode.databaseViewer &&
                                    isWide)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: _buildDbViewerPanel(
                                          context,
                                          appState,
                                        ),
                                      ),
                                      const SizedBox(width: 18),
                                      Expanded(
                                        flex: 7,
                                        child: _buildDbTableContentCard(
                                          context,
                                          appState,
                                        ),
                                      ),
                                    ],
                                  )
                                else if (_selectedMode ==
                                    _ToolMode.databaseViewer)
                                  Column(
                                    children: [
                                      _buildDbViewerPanel(context, appState),
                                      const SizedBox(height: 18),
                                      _buildDbTableContentCard(
                                        context,
                                        appState,
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 100),
                                _buildFooter(context),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          if (_partyParticles.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _partyController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _PartyPopPainter(
                        progress: _partyController.value,
                        particles: _partyParticles,
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.shield_rounded, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Decrypt logs or inspect SQLite databases',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Use the menu below to switch between decryption and DB table viewing.',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeMenu(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SegmentedButton<_ToolMode>(
          segments: const [
            ButtonSegment<_ToolMode>(
              value: _ToolMode.decryptor,
              icon: Icon(Icons.lock_open_rounded),
              label: Text('Decrypt Logs'),
            ),
            ButtonSegment<_ToolMode>(
              value: _ToolMode.databaseViewer,
              icon: Icon(Icons.table_view_rounded),
              label: Text('DB Viewer'),
            ),
          ],
          selected: {_selectedMode},
          onSelectionChanged: (selectedModes) {
            setState(() {
              _selectedMode = selectedModes.first;
            });
          },
        ),
      ),
    );
  }

  void _onFooterIconTap() {
    final now = DateTime.now();
    if (_lastFooterTapAt == null ||
        now.difference(_lastFooterTapAt!) > const Duration(seconds: 2)) {
      _footerTapCount = 1;
    } else {
      _footerTapCount += 1;
    }
    _lastFooterTapAt = now;

    if (_footerTapCount >= 3) {
      _footerTapCount = 0;
      _launchPartyPop();
    }
  }

  void _launchPartyPop() {
    final colors = <Color>[
      const Color(0xFF0F5D55),
      const Color(0xFF1B8A5A),
      const Color(0xFF42B883),
      const Color(0xFF6BCB77),
      const Color(0xFF8FD694),
    ];

    setState(() {
      _partyParticles = List.generate(52, (index) {
        final horizontalSpread = (_random.nextDouble() - 0.5) * 300;
        final velocityX = (_random.nextDouble() - 0.5) * 190;
        final velocityY = -260 - _random.nextDouble() * 260;
        final size = 3 + _random.nextDouble() * 4.8;
        final color = colors[_random.nextInt(colors.length)];
        return _PartyParticle(
          horizontalSpread: horizontalSpread,
          velocityX: velocityX,
          velocityY: velocityY,
          size: size,
          color: color,
        );
      });
    });

    _partyController.forward(from: 0);
  }

  Widget _buildControlPanel(BuildContext context, AppState appState) {
    return Column(
      children: [
        _buildFileSection(context, appState),
        const SizedBox(height: 14),
        _buildPasswordSection(context, appState),
        const SizedBox(height: 14),
        _buildButtonsSection(context, appState),
        if (appState.status.isNotEmpty || appState.errorMessage.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildStatusSection(context, appState),
        ],
      ],
    );
  }

  Widget _buildDbViewerPanel(BuildContext context, AppState appState) {
    return Column(
      children: [
        _buildDbFileSection(context, appState),
        const SizedBox(height: 14),
        _buildDbTableListSection(context, appState),
        if (appState.dbStatus.isNotEmpty ||
            appState.dbErrorMessage.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildDbStatusSection(context, appState),
        ],
      ],
    );
  }

  Widget _buildDbFileSection(BuildContext context, AppState appState) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 1 · Upload database file',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
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
                  const SizedBox(width: 8),
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
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

  Widget _buildDbTableListSection(BuildContext context, AppState appState) {
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 2 · Choose table',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
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
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
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
                          horizontal: 12,
                          vertical: 10,
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
                            const SizedBox(width: 8),
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

  Widget _buildDbStatusSection(BuildContext context, AppState appState) {
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
        padding: const EdgeInsets.all(12),
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

  Widget _buildFileSection(BuildContext context, AppState appState) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 1 · Select encrypted file',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
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
                  const SizedBox(width: 8),
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
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

  Widget _buildPasswordSection(BuildContext context, AppState appState) {
    final isRsaMode =
        appState.encryptionMode == EncryptionMode.rsaChunkedBase64;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 2 · Provide decryption details',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 8),
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

  Widget _buildRsaKeySection(AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (appState.privateKeyFile != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.vpn_key, size: 18),
                const SizedBox(width: 8),
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

  Widget _buildButtonsSection(BuildContext context, AppState appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
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

  Future<void> _handleSaveAs(BuildContext context, AppState appState) async {
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

  Widget _buildStatusSection(BuildContext context, AppState appState) {
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
        padding: const EdgeInsets.all(12),
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

  Widget _buildContentCard(BuildContext context, AppState appState) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewportHeight = MediaQuery.of(context).size.height;
    final contentHeight = viewportHeight < 760 ? 300.0 : 430.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Decrypted Content',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
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
            const SizedBox(height: 12),
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
                  contentPadding: const EdgeInsets.all(12),
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

  Widget _buildDbTableContentCard(BuildContext context, AppState appState) {
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
        padding: const EdgeInsets.all(16),
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
                if (hasTableSelection)
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
                      '${appState.dbRows.length} rows',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 11.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
            const SizedBox(height: 12),
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
                            columns: appState.dbColumns
                                .map(
                                  (column) => DataColumn(label: Text(column)),
                                )
                                .toList(),
                            rows: appState.dbRows
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
          ],
        ),
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
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.outline),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _onFooterIconTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/app_icon.png',
                width: 58,
                height: 58,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartyParticle {
  const _PartyParticle({
    required this.horizontalSpread,
    required this.velocityX,
    required this.velocityY,
    required this.size,
    required this.color,
  });

  final double horizontalSpread;
  final double velocityX;
  final double velocityY;
  final double size;
  final Color color;
}

class _PartyPopPainter extends CustomPainter {
  const _PartyPopPainter({required this.progress, required this.particles});

  final double progress;
  final List<_PartyParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    const gravity = 520.0;
    final centerX = size.width / 2;
    final baseY = size.height - 86;

    for (final particle in particles) {
      final dx = centerX + particle.horizontalSpread + (particle.velocityX * t);
      final dy = baseY + (particle.velocityY * t) + (0.5 * gravity * t * t);
      final alpha = ((1.0 - t) * 255).clamp(0.0, 255.0).toInt();
      final paint = Paint()..color = particle.color.withAlpha(alpha);
      canvas.drawCircle(Offset(dx, dy), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PartyPopPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.particles != particles;
  }
}
