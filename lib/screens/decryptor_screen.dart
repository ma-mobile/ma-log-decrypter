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
  static const Color _primaryGreen = Color(0xFF0D530E);
  static const Color _softGreen = Color(0xFFE8F5E9);
  static const Color _lightGreen = Color(0xFFC8E6C9);
  static const Color _midGreen = Color(0xFF2E7D32);
  static const Color _textGreen = Color(0xFF1B5E20);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log File Decryptor'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          // Update text controllers when content changes
          _decryptedContentController.text = appState.decryptedContent;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File Selection Section
                _buildFileSection(context, appState),
                const SizedBox(height: 32),

                // Decryption details section
                _buildPasswordSection(appState),
                const SizedBox(height: 24),

                // Buttons Section
                _buildButtonsSection(context, appState),
                const SizedBox(height: 24),

                // Status/Error Section
                if (appState.status.isNotEmpty || appState.errorMessage.isNotEmpty)
                  _buildStatusSection(appState),

                const SizedBox(height: 24),

                // Decrypted Content Section
                if (appState.decryptedContent.isNotEmpty)
                  _buildContentSection(appState),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileSection(BuildContext context, AppState appState) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 1: Select Encrypted File',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (appState.selectedFile != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: _midGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appState.selectedFile!.path,
                        style: const TextStyle(color: _midGreen),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => appState.selectFile(),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Browse File'),
                ),
                const SizedBox(width: 12),
                if (appState.selectedFile != null)
                  ElevatedButton(
                    onPressed: () {
                      appState.clearDecryption();
                      _passwordController.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear Selection'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSection(AppState appState) {
    final isRsaMode = appState.encryptionMode == EncryptionMode.rsaChunkedBase64;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 2: Provide Decryption Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<EncryptionMode>(
              initialValue: appState.encryptionMode,
              decoration: InputDecoration(
                labelText: 'Encryption mode',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
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
                  hintText: 'Enter password',
                  prefixIcon: const Icon(Icons.lock),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
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
                  ? 'RSA mode uses bundled key: keys/private_key_decrypted.pem (you can override by selecting another key).'
                  : 'Password is case-sensitive. Select the same mode used during encryption.',
              style: const TextStyle(fontSize: 12, color: _textGreen),
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
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                const Icon(Icons.vpn_key, color: _midGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appState.privateKeyFile!.path,
                    style: const TextStyle(color: _midGreen),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ElevatedButton.icon(
          onPressed: () => appState.selectPrivateKeyFile(),
          icon: const Icon(Icons.key),
          label: const Text('Select Private Key (.pem)'),
        ),
      ],
    );
  }

  Widget _buildButtonsSection(BuildContext context, AppState appState) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: appState.isLoading || appState.selectedFile == null
              ? null
              : () => appState.decryptFile(),
          icon: const Icon(Icons.lock_open),
          label: const Text('Decrypt'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        const SizedBox(width: 12),
        if (appState.hasDecryptedContent)
          ElevatedButton.icon(
            onPressed: appState.isLoading
                ? null
                : () => _handleSaveAs(context, appState),
            icon: const Icon(Icons.save),
            label: const Text('Save As'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        const SizedBox(width: 12),
        if (appState.isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
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

  Widget _buildStatusSection(AppState appState) {
    final isError = appState.errorMessage.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : _softGreen,
        border: Border.all(
          color: isError ? Colors.red.shade200 : _lightGreen,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: isError ? Colors.red : _primaryGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isError ? appState.errorMessage : appState.status,
              style: TextStyle(
                color: isError ? Colors.red : _textGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Decrypted Content',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          height: 400,
          decoration: BoxDecoration(
            border: Border.all(color: _lightGreen),
            borderRadius: BorderRadius.circular(8),
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
              hintStyle: const TextStyle(color: Color.fromARGB(140, 46, 125, 50)),
            ),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${appState.decryptedContent.length} characters',
          style: const TextStyle(fontSize: 12, color: _midGreen),
        ),
      ],
    );
  }
}
