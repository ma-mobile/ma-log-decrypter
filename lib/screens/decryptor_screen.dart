// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/encryption_service.dart';

class DecryptorScreen extends StatefulWidget {
  const DecryptorScreen({super.key});

  @override
  State<DecryptorScreen> createState() => _DecryptorScreenState();
}

class _DecryptorScreenState extends State<DecryptorScreen> {
  late TextEditingController _passwordController;
  late TextEditingController _decryptedContentController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _decryptedContentController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _decryptedContentController.dispose();
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
      body: Container(
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
              _decryptedContentController.text = appState.decryptedContent;

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
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _buildControlPanel(context, appState),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    flex: 6,
                                    child: _buildContentCard(context, appState),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _buildControlPanel(context, appState),
                                  const SizedBox(height: 18),
                                  _buildContentCard(context, appState),
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
                    'Decrypt encrypted log files securely',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Supports AES and RSA chunked formats with desktop-friendly controls.',
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
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    appState.selectedFile == null ? Icons.insert_drive_file_outlined : Icons.check_circle,
                    size: 18,
                    color: appState.selectedFile == null ? colorScheme.outline : colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appState.selectedFile?.path ?? 'No file selected',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: appState.selectedFile == null ? colorScheme.outline : colorScheme.onSurface,
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
    final isRsaMode = appState.encryptionMode == EncryptionMode.rsaChunkedBase64;

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
                    tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
            if (appState.isLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
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
      suggestedFileName = 'decrypted_log_${DateTime.now().millisecondsSinceEpoch}.txt';
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
          ? Color.alphaBlend(Colors.red.withValues(alpha: 0.08), colorScheme.surface)
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
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

  Widget _buildFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/app_icon.png',
              width: 58,
              height: 58,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Developed and designed by mobile team',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
