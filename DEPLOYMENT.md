# Installation & Deployment Guide

## Quick Setup (5 Minutes)

### Option 1: Run Pre-Built Executable (Recommended for Users)

1. **Navigate to executable**:
   ```
   C:\log_decryptor\build\windows\x64\runner\Release\log_decryptor.exe
   ```

2. **Double-click** the `.exe` file

3. **Application launches instantly**

**That's it!** No installation required.

---

## Development Setup (First Time)

### Prerequisites

- **Windows 10/11** (64-bit recommended) **or** **macOS 11+**
- **Flutter SDK**: https://flutter.dev/docs/get-started/install
- **Visual Studio Build Tools** (Windows) or **Xcode 14+** (macOS)
- **Git** (optional, for version control)

### Installation Steps

#### Step 1: Verify Flutter Installation

```powershell
flutter --version
flutter doctor
```

Expected output shows:
- ✓ Flutter version 3.12.2 or higher
- ✓ Dart SDK
- ✓ Windows development tools

#### Step 2: Get the Project

```powershell
# Navigate to your projects directory
cd C:\

# Project already exists at C:\log_decryptor
# Or clone if needed:
git clone [repository-url] log_decryptor
cd log_decryptor
```

#### Step 3: Get Dependencies

```powershell
flutter pub get
```

This downloads and installs:
- encrypt ^5.0.3
- crypto ^3.0.2
- file_picker ^8.0.0
- provider ^6.0.0
- And all transitive dependencies

#### Step 4: Run the Application

```powershell
flutter run -d windows
```

**First build takes 2-3 minutes**, subsequent runs are faster.

---

## Building for Distribution

### Standard Release Build — Windows

```powershell
cd C:\log_decryptor

# Clean previous builds
flutter clean

# Get latest dependencies
flutter pub get

# Build release version
flutter build windows --release
```

**Output**: `build\windows\x64\runner\Release\log_decryptor.exe`

### Standard Release Build — macOS

```bash
cd /path/to/log_decryptor

# Clean previous builds
flutter clean

# Get latest dependencies
flutter pub get

# Build release version
flutter build macos
```

**Output**: `build/macos/Build/Products/Release/log_decryptor.app`

For distribution, sign the `.app` with your Apple Developer ID and optionally package it as a `.dmg` using `create-dmg` or Disk Utility.

### Build Configuration

| Parameter | Value |
|-----------|-------|
| Build type | Release |
| Optimization | Enabled (fast) |
| Debugging | Disabled |
| Size | ~200MB |
| Performance | Optimal |

### Distribution Checklist

- [ ] Run `flutter build windows --release` (Windows) or `flutter build macos` (macOS)
- [ ] Test executable on a clean machine
- [ ] Verify all dependencies work
- [ ] Check file size (~200MB)
- [ ] Test with sample encrypted files
- [ ] Verify save functionality
- [ ] Test on the target operating system version(s)

---

## Advanced Deployment Options

### Option 1: Portable Executable

Simply copy `log_decryptor.exe` to any location:

```
✓ No installation
✓ No admin rights
✓ Works on any Windows 10+ machine
✓ Can run from USB drive
✗ Large file size (~200MB)
```

**Deployment**:
```powershell
Copy-Item -Path "build\windows\x64\runner\Release\log_decryptor.exe" `
          -Destination "E:\tools\log_decryptor.exe"
```

### Option 2: Installer Package (NSIS)

Create a professional installer:

```powershell
# Install NSIS (https://nsis.sourceforge.io)
# Create .nsi script
# Build installer

# Example minimal installer
# save as installer.nsi and build with makensis.exe
```

**Benefits**:
```
✓ Professional installation
✓ System shortcuts
✓ Uninstall support
✓ Automatic updates possible
```

### Option 3: Shared Network Drive

Deploy to team network:

```powershell
# Copy to network location
Copy-Item -Path "build\windows\x64\runner\Release\log_decryptor.exe" `
          -Destination "\\server\tools\log_decryptor.exe"

# Create shortcut on user desktops
# \\server\tools\log_decryptor.exe
```

**Considerations**:
- Network latency may affect file picker
- Ensure all users have read permissions
- Consider bandwidth for updates

### Option 4: Windows Store (Future)

To publish on Microsoft Store:
1. Register as Windows developer
2. Create app submission
3. Follow store guidelines
4. Publish with auto-updates

---

## Environment-Specific Configuration

### Development Environment

```powershell
cd C:\log_decryptor
flutter run -d windows
```

**Features**:
- Hot reload enabled
- Debug information included
- Verbose logging
- Development extensions

### Staging Environment

```powershell
flutter build windows
# Run with: build\windows\x64\runner\Debug\log_decryptor.exe
```

**Use for**: Testing before release

### Production Environment

```powershell
flutter build windows --release
# Run with: build\windows\x64\runner\Release\log_decryptor.exe
```

**Use for**: End-user distribution

---

## System Requirements Verification

### Minimum Requirements

```
OS:       Windows 10 (build 1909) or later
RAM:      2 GB (1 GB free)
Storage:  300 MB free space
Display:  1024x768 or higher
```

### Recommended Requirements

```
OS:       Windows 10/11 latest
RAM:      8 GB or more
Storage:  SSD with 500MB free space
Display:  1920x1080 or higher
CPU:      Intel i5 or equivalent
```

### Check System Requirements

```powershell
# Windows version
[System.Environment]::OSVersion.Version

# Available RAM
(Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB

# Free disk space
(Get-Volume -DriveLetter C).SizeRemaining / 1GB

# Display resolution
(Get-WmiObject Win32_VideoController).VideoMemory
```

---

## Troubleshooting Installation

### Issue: Flutter not found

**Solution**:
```powershell
# Add Flutter to PATH
$env:Path = "C:\flutter\bin;$env:Path"

# Verify
flutter --version
```

### Issue: Build tools missing

**Solution**:
```powershell
flutter doctor -v
# Follow recommendations to install missing tools
```

### Issue: Dependencies won't download

**Solution**:
```powershell
# Clear cache
flutter clean
flutter pub cache repair

# Try again
flutter pub get
```

### Issue: Executable won't start

**Solution**:
```powershell
# Check for Windows compatibility
# Install VC++ Runtime:
# https://support.microsoft.com/en-us/help/2977003

# Or rebuild from source
flutter clean
flutter pub get
flutter build windows --release
```

### Issue: Very slow decryption

**Solution**:
- Close other applications
- Check CPU usage (should spike to 100% during decryption)
- Verify file isn't on network drive
- Try smaller file first

---

## Update Procedures

### Updating Dependencies

```powershell
cd C:\log_decryptor

# Check for updates
flutter pub outdated

# Update to latest compatible versions
flutter pub upgrade

# Or update specific package
flutter pub add encrypt --upgrade

# Rebuild
flutter clean
flutter pub get
flutter build windows --release
```

### Updating Flutter SDK

```powershell
flutter upgrade
flutter upgrade --force  # Force upgrade

# Verify
flutter --version
flutter doctor
```

### Distributing Updates

1. Build new version (see "Building for Distribution")
2. Test thoroughly on Windows 10 and 11
3. Replace `log_decryptor.exe` in distribution location
4. Notify users to re-download/restart

---

## Continuous Integration/Deployment (CI/CD)

### GitHub Actions Example

```yaml
name: Build Windows App

on: [push, pull_request]

jobs:
  build:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.12.2'
      - run: flutter pub get
      - run: flutter build windows --release
      - uses: actions/upload-artifact@v3
        with:
          name: log-decryptor.exe
          path: build/windows/x64/runner/Release/log_decryptor.exe
```

### Local Build Automation

```powershell
# build-release.ps1
param(
    [string]$OutputPath = "C:\releases\"
)

cd C:\log_decryptor
flutter clean
flutter pub get
flutter build windows --release

$date = Get-Date -Format "yyyy-MM-dd_HHmmss"
$output = "$OutputPath\log_decryptor_$date.exe"

Copy-Item -Path "build\windows\x64\runner\Release\log_decryptor.exe" `
          -Destination $output

Write-Host "✓ Build complete: $output"
```

---

## Deployment Checklist

### Pre-Release

- [ ] All code reviewed and tested
- [ ] Dependencies updated and verified
- [ ] `flutter clean && flutter pub get` run successfully
- [ ] `flutter build windows --release` completes without errors
- [ ] Executable is ~200MB
- [ ] No debug symbols in release build
- [ ] `flutter test` passes (if tests exist)

### Release

- [ ] Test executable on clean Windows 10 machine
- [ ] Test executable on Windows 11
- [ ] Verify file picker works
- [ ] Verify encryption/decryption works
- [ ] Verify save functionality works
- [ ] Test with various file sizes
- [ ] Test with various password types

### Post-Release

- [ ] Update version number if distributed
- [ ] Document changes in CHANGELOG
- [ ] Monitor for user issues
- [ ] Collect performance metrics
- [ ] Plan next release improvements

---

## File Structure Reference

```
C:\log_decryptor\
├── lib/
│   ├── main.dart
│   ├── providers/
│   │   └── app_state.dart
│   ├── screens/
│   │   └── decryptor_screen.dart
│   ├── services/
│   │   ├── encryption_service.dart
│   │   └── file_service.dart
│   └── utils/
│       └── encrypt_test_file.dart
├── windows/                    # Windows-specific configuration
├── build/
│   └── windows/
│       └── x64/
│           └── runner/
│               └── Release/
│                   └── log_decryptor.exe  # ← Production executable
├── pubspec.yaml               # Dependencies
├── pubspec.lock               # Locked versions
├── README.md                  # User guide
├── QUICKSTART.md              # Quick reference
├── TECHNICAL.md               # Technical docs
└── DEPLOYMENT.md              # This file
```

---

## Support & Troubleshooting

### Key Commands Reference

```powershell
# Development
flutter run -d windows

# Testing
flutter test

# Building
flutter build windows --release

# Cleaning
flutter clean

# Diagnostics
flutter doctor
flutter doctor -v

# Dependencies
flutter pub get
flutter pub outdated
flutter pub upgrade
```

### Common Paths

```
Project:           C:\log_decryptor\
Executable (Prod): C:\log_decryptor\build\windows\x64\runner\Release\log_decryptor.exe
Executable (Dev):  C:\log_decryptor\build\windows\x64\runner\Debug\log_decryptor.exe
Source Code:       C:\log_decryptor\lib\
Dependencies:      C:\log_decryptor\pubspec.yaml
Documentation:     C:\log_decryptor\*.md
```

### Getting Help

1. Check README.md for user guide
2. Check QUICKSTART.md for common tasks
3. Check TECHNICAL.md for implementation details
4. Run `flutter doctor -v` for diagnostics
5. Check application status messages
6. Review error logs in console output

---

**Document Version**: 1.0  
**Last Updated**: 2026-07-10  
**Compatible With**: Flutter 3.12.2+, Windows 10+
