import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'screens/main_shell.dart';
import 'screens/focus_screen.dart';
import 'services/background_notification_service.dart';
import 'services/system_tray_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const Color navy = Color(0xFF1A237E);
const Color darkNavy = Color(0xFF0A1628);
const Color purple = Color(0xFF7B2D8B);
const Color deepPurple = Color(0xFF4A148C);
const Color accentBlue = Color(0xFF00E5FF);

ColorScheme _buildColorScheme() {
  return ColorScheme.dark(
    primary: accentBlue,
    onPrimary: Colors.black,
    primaryContainer: accentBlue.withValues(alpha: 0.2),
    onPrimaryContainer: accentBlue,
    secondary: navy,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFF283593),
    onSecondaryContainer: Colors.white,
    tertiary: accentBlue,
    onTertiary: Colors.black,
    tertiaryContainer: accentBlue.withValues(alpha: 0.2),
    onTertiaryContainer: accentBlue,
    error: const Color(0xFFCF6679),
    onError: Colors.black,
    surface: Colors.transparent,
    onSurface: Colors.white,
    surfaceContainerHighest: Colors.white.withValues(alpha: 0.06),
    onSurfaceVariant: const Color(0xFFB0BEC5),
    outline: Colors.white.withValues(alpha: 0.2),
    outlineVariant: Colors.white.withValues(alpha: 0.1),
    shadow: Colors.black26,
    scrim: Colors.black54,
    inverseSurface: const Color(0xFFECEFF1),
    onInverseSurface: darkNavy,
    inversePrimary: accentBlue,
  );
}

ThemeData _buildTheme() {
  final colorScheme = _buildColorScheme();
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accentBlue,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentBlue,
      foregroundColor: Colors.black,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: accentBlue, width: 1.5),
      ),
      filled: false,
      fillColor: Colors.transparent,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      indicatorColor: accentBlue.withValues(alpha: 0.25),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(color: accentBlue, fontWeight: FontWeight.w600);
        }
        return TextStyle(color: colorScheme.onSurfaceVariant);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: accentBlue, size: 24);
        }
        return IconThemeData(color: colorScheme.onSurfaceVariant, size: 24);
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.transparent,
      contentTextStyle: TextStyle(color: colorScheme.onSurface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.06),
      thickness: 0.5,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentBlue,
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentBlue;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.black),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: accentBlue,
      linearTrackColor: Colors.white.withValues(alpha: 0.1),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WaterTasksApp());

  // Defer non-critical init to after first frame so app opens instantly
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final notif = BackgroundNotificationService();
    await notif.initialize();
    try {
      await notif.requestPermissions();
    } catch (_) {}

    try {
      await SystemTrayService().initialize();
    } catch (_) {}

    BackgroundNotificationService.onCheckInTapped = () {
      final context = navigatorKey.currentContext;
      if (context == null) return;
      final provider = context.read<TaskProvider>();
      if (provider.hasActiveSession) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const FocusScreen(fromNotification: true),
          ),
        );
      }
    };
  });
}

class WaterTasksApp extends StatelessWidget {
  const WaterTasksApp({super.key});

  static final ThemeData _cachedTheme = _buildTheme();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaskProvider()..checkActiveSession(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Water Tasks',
        debugShowCheckedModeBanner: false,
        theme: _cachedTheme,
        darkTheme: _cachedTheme,
        themeMode: ThemeMode.dark,
        home: const MainShell(),
        builder: (context, child) {
          return Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0A1628),
                      Color(0xFF0D1B2A),
                      Color(0xFF1A237E),
                      Color(0xFF4A148C),
                    ],
                  ),
                ),
              ),
              child!,
            ],
          );
        },
      ),
    );
  }
}
