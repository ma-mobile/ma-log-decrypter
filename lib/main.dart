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

  static const Color _primaryGreen = Color(0xFF0F5D55);

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryGreen,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F1515) : const Color(0xFFF4F8F8),
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
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: const ElevatedButtonThemeData(
        style: ButtonStyle(
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (controller) => GetMaterialApp(
        title: 'Log File Decryptor',
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
                'Log File Decryptor',
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
