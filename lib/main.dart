import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'screens/home_screen.dart';

const Color navy = Color(0xFF1A237E);
const Color darkNavy = Color(0xFF0D1B2A);
const Color purple = Color(0xFF7B2D8B);
const Color deepPurple = Color(0xFF4A148C);
const Color gold = Color(0xFFFFD700);

ColorScheme _buildColorScheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return ColorScheme(
    brightness: brightness,
    primary: purple,
    onPrimary: Colors.white,
    primaryContainer: deepPurple,
    onPrimaryContainer: Colors.white,
    secondary: navy,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFF283593),
    onSecondaryContainer: Colors.white,
    tertiary: gold,
    onTertiary: Colors.black,
    tertiaryContainer: const Color(0xFFFFF176),
    onTertiaryContainer: navy,
    error: const Color(0xFFCF6679),
    onError: Colors.black,
    surface: isDark ? darkNavy : const Color(0xFFF8F9FA),
    onSurface: isDark ? Colors.white : navy,
    surfaceContainerHighest: isDark
        ? const Color(0xFF1B2838)
        : const Color(0xFFE8EAF6),
    onSurfaceVariant:
        isDark ? const Color(0xFFB0BEC5) : const Color(0xFF455A64),
    outline: isDark ? const Color(0xFF546E7A) : const Color(0xFF90A4AE),
    outlineVariant:
        isDark ? const Color(0xFF37474F) : const Color(0xFFCFD8DC),
    shadow: Colors.black26,
    scrim: Colors.black,
    inverseSurface: isDark ? const Color(0xFFECEFF1) : darkNavy,
    onInverseSurface: isDark ? darkNavy : Colors.white,
    inversePrimary: isDark ? Colors.white70 : deepPurple,
  );
}

ThemeData _buildTheme(Brightness brightness) {
  final colorScheme = _buildColorScheme(brightness);
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: gold,
      foregroundColor: Colors.black,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest,
      contentTextStyle: TextStyle(color: colorScheme.onSurface),
    ),
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WaterTasksApp());
}

class WaterTasksApp extends StatelessWidget {
  const WaterTasksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaskProvider()..checkActiveSession(),
      child: MaterialApp(
        title: 'Water Tasks',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
