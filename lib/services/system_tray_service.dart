import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

class SystemTrayService extends WindowListener {
  static final SystemTrayService _instance = SystemTrayService._internal();
  factory SystemTrayService() => _instance;
  SystemTrayService._internal();

  final SystemTray _systemTray = SystemTray();
  final Menu _menu = Menu();
  bool _initialized = false;

  bool get isDesktop =>
      !kIsWeb &&
      [
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.linux,
      ].contains(defaultTargetPlatform);

  Future<void> initialize() async {
    if (_initialized || !isDesktop) return;

    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);

    String iconPath;
    if (Platform.isWindows) {
      iconPath = 'assets/app_icon.ico';
    } else if (Platform.isMacOS) {
      iconPath = 'AppIcon';
    } else {
      iconPath = 'assets/logo.png';
    }

    await _systemTray.initSystemTray(
      iconPath: iconPath,
      title: 'Water Tasks',
      toolTip: 'Water Tasks',
    );

    await _buildDefaultMenu();
    await _systemTray.setContextMenu(_menu);

    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        windowManager.show();
      }
    });

    _initialized = true;
  }

  @override
  void onWindowClose() {
    windowManager.hide();
  }

  Future<void> setSessionActive(String taskTitle) async {
    if (!_initialized) return;
    await _systemTray.setToolTip('Focusing: $taskTitle');

    await _menu.buildFrom([
      MenuItemLabel(
        label: 'Show Window',
        onClicked: (_) => windowManager.show(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'End Session',
        onClicked: (_) => windowManager.show(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Quit',
        onClicked: (_) {
          windowManager.destroy();
        },
      ),
    ]);
    await _systemTray.setContextMenu(_menu);
  }

  Future<void> clearSession() async {
    if (!_initialized) return;
    await _systemTray.setToolTip('Water Tasks');
    await _buildDefaultMenu();
    await _systemTray.setContextMenu(_menu);
  }

  Future<void> _buildDefaultMenu() async {
    await _menu.buildFrom([
      MenuItemLabel(
        label: 'Show Window',
        onClicked: (_) => windowManager.show(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Quit',
        onClicked: (_) {
          windowManager.destroy();
        },
      ),
    ]);
  }

  Future<void> destroy() async {
    if (!_initialized) return;
    await _systemTray.destroy();
    _initialized = false;
  }
}
