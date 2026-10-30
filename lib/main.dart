import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';
import 'controller/decryptor_controller.dart';
import 'controller/theme_provider.dart';
import 'screens/decryptor_screen.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  final savedBounds = await SettingsService.loadWindowBounds();
  final windowOptions = WindowOptions(
    size: savedBounds != null
        ? Size(
            (savedBounds['width'] as num?)?.toDouble() ?? 1200,
            (savedBounds['height'] as num?)?.toDouble() ?? 860,
          )
        : const Size(1200, 860),
    center: savedBounds == null,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    if (savedBounds != null) {
      final x = (savedBounds['x'] as num?)?.toDouble();
      final y = (savedBounds['y'] as num?)?.toDouble();
      if (x != null && y != null) {
        await windowManager.setPosition(Offset(x, y));
      }
    }
    await windowManager.show();
    await windowManager.focus();
  });

  Get.put(ThemeController());
  Get.put(DecryptorController());

  runApp(const WindowBoundsListener(child: MyApp()));
}

class WindowBoundsListener extends StatefulWidget {
  const WindowBoundsListener({required this.child, super.key});

  final Widget child;

  @override
  State<WindowBoundsListener> createState() => _WindowBoundsListenerState();
}

class _WindowBoundsListenerState extends State<WindowBoundsListener>
    with WindowListener {
  DateTime? _lastSave;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMoved() => _saveBounds();

  @override
  void onWindowResized() => _saveBounds();

  Future<void> _saveBounds() async {
    final now = DateTime.now();
    if (_lastSave != null && now.difference(_lastSave!) < const Duration(seconds: 1)) {
      return;
    }
    _lastSave = now;
    final bounds = await windowManager.getBounds();
    await SettingsService.saveWindowBounds({
      'x': bounds.left,
      'y': bounds.top,
      'width': bounds.width,
      'height': bounds.height,
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Eye-comfort primary color: Soft teal with reduced saturation
  static const Color _primaryTeal = Color(0xFF1B7A74);

  /// Eye-comfort light background: Warm white with slight green tint
  static const Color _lightBackground = Color(0xFFF7FBFA);

  /// Eye-comfort light surface: Soft cream to reduce blue light
  static const Color _lightSurface = Color(0xFFFAFCFB);

  /// Eye-comfort dark background: Soft charcoal instead of pure black
  static const Color _darkBackground = Color(0xFF1A1F1E);

  /// Eye-comfort dark surface: Slightly lighter than background for contrast
  static const Color _darkSurface = Color(0xFF232928);

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    /// Custom color scheme with eye-comfort colors
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryTeal,
      brightness: brightness,
      /// Override high-contrast secondary for softer feel
      surface: isDark ? _darkSurface : _lightSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? _darkBackground : _lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? const Color(0xFF3A4341)
                : const Color(0xFFE0E8E7),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? const Color(0xFF2E3432).withValues(alpha: 0.8)
            : const Color(0xFFF0F4F3).withValues(alpha: 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF3A4341)
                : const Color(0xFFDEE5E4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF3A4341)
                : const Color(0xFFDEE5E4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.4,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(
          color: isDark
              ? const Color(0xFF8A9391).withValues(alpha: 0.7)
              : const Color(0xFF7A8886).withValues(alpha: 0.7),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          backgroundColor: WidgetStatePropertyAll(colorScheme.primary),
          foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimary),
        ),
      ),
      /// Soft text theme for reduced eye strain
      textTheme: TextTheme(
        bodyMedium: TextStyle(
          color: isDark ? const Color(0xFFD4DDD9) : const Color(0xFF2A3230),
          letterSpacing: 0.15,
        ),
        bodySmall: TextStyle(
          color: isDark ? const Color(0xFFA0A9A6) : const Color(0xFF5F6764),
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          color: isDark ? const Color(0xFFE8F0ED) : const Color(0xFF1B2220),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (controller) => GetMaterialApp(
        title: 'LogVault - Encrypted Log Viewer',
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: controller.themeMode,
        home: const DecryptorScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class TitleBar extends StatelessWidget {
  const TitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 40,
      color: theme.colorScheme.surface,
      child: DragToMoveArea(
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'LogVault - Encrypted Log Viewer',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.minimize, size: 18),
              onPressed: () => windowManager.minimize(),
              tooltip: 'Minimize',
            ),
            IconButton(
              icon: const Icon(Icons.crop_square, size: 16),
              onPressed: () async {
                if (await windowManager.isMaximized()) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
              tooltip: 'Maximize',
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => windowManager.close(),
              tooltip: 'Close',
            ),
          ],
        ),
      ),
    );
  }
}
