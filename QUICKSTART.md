# Log File Decryptor - Quick Start Guide for Support Engineers

## Overview

The Log File Decryptor is a Windows desktop application designed to decrypt password-protected log files received from users. It's compatible with the mobile app's encryption standard.

## Quick Links

- **Executable**: `C:\log_decryptor\build\windows\x64\runner\Release\log_decryptor.exe`
- **Source Code**: `C:\log_decryptor\`
- **Test File Generator**: `dart run lib/utils/encrypt_test_file.dart`

## Getting Started (First Time Only)

### For Running from Pre-built Executable

1. Navigate to: `C:\log_decryptor\build\windows\x64\runner\Release\`
2. Double-click `log_decryptor.exe`
3. Application will launch immediately

### For Development/Building from Source

1. Open PowerShell and navigate to the project:
   ```powershell
   cd C:\log_decryptor
   ```

2. Get dependencies:
   ```powershell
   flutter pub get
   ```

3. Run the application:
   ```powershell
   flutter run -d windows
   ```

## Typical Usage Workflow

### Scenario 1: User Submits Encrypted Log File

**Situation**: A user reports an issue and provides an encrypted log file with a temporary password.

**Steps**:
1. Launch the Log File Decryptor application
2. Click **Browse File** → Select the encrypted `.txt` file
3. Enter the password provided by the user
4. Click **Decrypt**
5. Review the decrypted log to investigate the issue
6. Click **Save As** to save a copy for your records
7. Analyze the logs and provide support

### Scenario 2: Testing the Application

**Situation**: You want to verify the application is working correctly.

**Steps**:
1. Generate a test encrypted file:
   ```powershell
   cd C:\log_decryptor
   dart run lib/utils/encrypt_test_file.dart
   ```
   This creates: `C:\log_decryptor\test_encrypted_log.txt`

2. Launch the application and test:
   - Browse to the test file
   - Enter password: `TestPassword123`
   - Click Decrypt
   - Verify the content appears

### Scenario 3: Troubleshooting Decryption Issues

**Problem**: "Decryption failed" error message

**Check**:
- [ ] Is the password correct? (Passwords are case-sensitive)
- [ ] Is the file a valid `.txt` file?
- [ ] Was the file corrupted during transfer?
- [ ] Does the file follow the format: [IV (16 bytes)] + [Encrypted Data]?

**Solution**:
- Ask the user to re-verify the password
- Request they resend the file
- Ensure the file wasn't corrupted in download/email

## Common Tasks

### How to Decrypt a Log File

1. **Select File**: Click "Browse File" button
2. **Enter Password**: Type the decryption password
3. **Decrypt**: Click "Decrypt" button
4. **View**: Scroll through the decrypted content
5. **Save**: Click "Save As" to export (optional)

### How to Save Decrypted Content

1. After successful decryption, click **Save As**
2. File will be saved to `C:\Users\[YourName]\Documents\decrypted_log_[timestamp].txt`
3. The notification will show the exact file path

### How to Clear and Start Over

1. Click **Clear Selection** button (if visible)
2. Or simply:
   - Select a different file
   - Clear the password field
   - Click Decrypt again

## Keyboard Shortcuts

| Action | Key |
|--------|-----|
| Focus Password Field | Tab |
| Enter Password | Type password |
| Decrypt | Enter (when focused) or Click button |
| Select All in Text Area | Ctrl+A |
| Copy from Text Area | Ctrl+C |

## File Management

### Where Decrypted Files Are Saved

All saved decrypted files go to your Documents folder:
```
C:\Users\[YourUsername]\Documents\decrypted_log_[timestamp].txt
```

Example: `decrypted_log_1720601325000.txt`

### File Naming Convention

Saved files use the format: `decrypted_log_[milliseconds_since_epoch].txt`

This ensures unique filenames and chronological ordering.

## Error Messages & Solutions

| Error Message | Cause | Solution |
|---------------|-------|----------|
| "Please select a file first" | No file selected | Click Browse File button |
| "Please enter a password" | Password field empty | Type the password |
| "Decryption failed: ..." | Wrong password or corrupted file | Verify password and file |
| "Invalid encrypted data: too short" | File is too small | Verify file format |
| "File does not exist" | File was moved or deleted | Re-select the file |
| "Failed to save file: ..." | Disk full or permission issue | Check disk space and permissions |

## Encryption Details (For Reference)

### Algorithm Specifications

- **Algorithm**: AES-256
- **Mode**: CBC (Cipher Block Chaining)
- **Padding**: PKCS7
- **Key Derivation**: SHA256(password)
- **IV Length**: 16 bytes (randomly generated per file)

### File Format

Encrypted files contain:
```
Bytes 0-15:   Initialization Vector (IV)
Bytes 16+:    Encrypted content (AES-CBC-PKCS7)
```

### Why This Matters

The IV (Initialization Vector) is unique for every encryption operation, even with the same password. This means the same plaintext encrypted twice produces different ciphertext (both are valid and can be decrypted with the same password).

## Troubleshooting Guide

### Application Won't Start

**Check**:
- [ ] Is Windows 10 or later installed?
- [ ] Is the executable accessible?
- [ ] Are there any Windows error dialogs?

**Fix**:
```powershell
# Verify from source
cd C:\log_decryptor
flutter pub get
flutter run -d windows
```

### Can't Select a File

**Check**:
- [ ] File exists and is readable
- [ ] File extension is `.txt`
- [ ] File path doesn't contain special characters

**Fix**:
- Try moving the file to Desktop
- Rename to simpler name (e.g., `log.txt`)
- Ensure you have read permissions

### Decryption Always Fails

**Check**:
- [ ] Password is exactly correct (case-sensitive)
- [ ] File wasn't modified after encryption
- [ ] File came from the correct source

**Fix**:
```
1. Double-check password with user
2. Request file resend
3. Verify checksum if available
```

### Can't Save Decrypted File

**Check**:
- [ ] Disk has free space (at least 100MB)
- [ ] You have write permissions to Documents folder

**Fix**:
```powershell
# Check disk space
Get-PSDrive | where {$_.Name -eq "C"}

# Or save to a different location by using Windows file manager
# Navigate to Documents manually
```

## Advanced Usage

### Building a New Version

To rebuild the application after making code changes:

```powershell
cd C:\log_decryptor
flutter clean
flutter pub get
flutter build windows --release
```

New executable: `build/windows/x64/runner/Release/log_decryptor.exe`

### Running in Debug Mode (for developers)

```powershell
cd C:\log_decryptor
flutter run -d windows
```

In debug mode:
- Hot reload works (press 'r')
- More verbose error messages
- Slower performance

### Creating a Distribution Package

To create an installer or portable version:

1. Build release version (see above)
2. Locate the executable at: `build/windows/x64/runner/Release/log_decryptor.exe`
3. Package with an installer tool like NSIS or InnoSetup (optional)
4. Distribute to support team

## Best Practices

✅ **Do**:
- Keep the application in `C:\log_decryptor\` for easy access
- Request passwords separately from encrypted files
- Save important decrypted logs with timestamps
- Test with sample files regularly
- Keep Windows and Flutter updated

❌ **Don't**:
- Share or expose decryption passwords
- Distribute decrypted files unnecessarily
- Keep decrypted files on shared drives
- Leave decrypted data in the text area after use
- Modify encrypted files before decryption

## Performance Notes

| Operation | Time |
|-----------|------|
| Load application | < 2 seconds |
| Select file | < 1 second |
| Decrypt small file (< 1MB) | < 1 second |
| Decrypt large file (10MB) | 2-5 seconds |
| Save decrypted file | < 1 second |

Actual times depend on:
- File size
- File location (local SSD vs network drive)
- System specifications

## Additional Resources

- **Flutter Documentation**: https://flutter.dev/docs
- **Encryption Package**: https://pub.dev/packages/encrypt
- **File Picker Package**: https://pub.dev/packages/file_picker

## Getting Help

### Check These First:
1. Read the error message carefully
2. Review the "Error Messages & Solutions" table above
3. Check the "Troubleshooting Guide" section
4. Verify file format and encryption algorithm

### Common Issues:
- Ensure password is case-sensitive
- Verify file is in correct format (binary encrypted data)
- Check that file wasn't corrupted during transfer
- Make sure Windows firewall isn't blocking the app

## Contact & Support

For questions or issues:
1. Check this guide
2. Review application README.md
3. Contact the development team

---

**Document Version**: 1.0  
**Last Updated**: 2026-07-10  
**Application Version**: 1.0.0
