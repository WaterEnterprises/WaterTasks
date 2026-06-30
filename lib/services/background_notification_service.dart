import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class BackgroundNotificationService {
  static final BackgroundNotificationService _instance =
      BackgroundNotificationService._internal();
  factory BackgroundNotificationService() => _instance;
  BackgroundNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _sessionChannelId = 'water_tasks_session';
  static const String _sessionChannelName = 'Session Timer';
  static const String _sessionChannelDesc = 'Shows active session status';
  static const String _checkInChannelId = 'water_tasks_checkin';
  static const String _checkInChannelName = 'Check-in Alerts';
  static const String _checkInChannelDesc = 'Alerts for due check-ins';
  static const int _sessionNotificationId = 1001;
  static const int _initialAlarmId = 1002;

  static VoidCallback? onCheckInTapped;

  Timer? _buzzingTimer;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: false,
    );
    const macOSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: false,
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open',
    );
    const windowsSettings = WindowsInitializationSettings(
      appName: 'Water Tasks',
      appUserModelId: 'JV.WaterTasks.Notifications',
      guid: '3a7b8c9d-1e2f-4a5b-8c7d-9e0f1a2b3c4d',
    );
    const webSettings = WebInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macOSettings,
      linux: linuxSettings,
      windows: windowsSettings,
      web: webSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (response.id == _initialAlarmId) {
      onCheckInTapped?.call();
    }
  }

  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final result = await android.requestNotificationsPermission();
        return result ?? false;
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return (await ios.requestPermissions(
          alert: true,
          sound: true,
          badge: false,
        )) ?? false;
      }
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      final macos = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      if (macos != null) {
        return (await macos.requestPermissions(
          alert: true,
          sound: true,
          badge: false,
        )) ?? false;
      }
    }
    return true;
  }

  static const NotificationDetails _checkInDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _checkInChannelId,
      _checkInChannelName,
      channelDescription: _checkInChannelDesc,
      importance: Importance.high,
      priority: Priority.max,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      sound: 'default',
    ),
    macOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      sound: 'default',
    ),
    windows: WindowsNotificationDetails(),
  );

  static const NotificationDetails _sessionDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _sessionChannelId,
      _sessionChannelName,
      channelDescription: _sessionChannelDesc,
      importance: Importance.low,
      priority: Priority.defaultPriority,
      ongoing: true,
      autoCancel: false,
      showProgress: false,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: false,
      presentSound: false,
    ),
    macOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: false,
    ),
    linux: LinuxNotificationDetails(),
    windows: WindowsNotificationDetails(),
  );

  Future<void> showSessionNotification(String taskTitle) async {
    await _plugin.show(
      id: _sessionNotificationId,
      title: 'Focusing: $taskTitle',
      body: 'Session active — check-in coming soon',
      notificationDetails: _sessionDetails,
    );
  }

  Future<void> updateSessionNotification(String taskTitle, String text) async {
    const androidDetails = AndroidNotificationDetails(
      _sessionChannelId,
      _sessionChannelName,
      channelDescription: _sessionChannelDesc,
      importance: Importance.low,
      priority: Priority.defaultPriority,
      ongoing: true,
      autoCancel: false,
      showProgress: false,
    );
    const linuxDetails = LinuxNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      linux: linuxDetails,
    );

    await _plugin.show(
      id: _sessionNotificationId,
      title: 'Focusing: $taskTitle',
      body: text,
      notificationDetails: details,
    );
  }

  static bool _tzInitialized = false;

  Future<void> scheduleCheckInAlarm(String taskTitle, int secondsFromNow) async {
    if (defaultTargetPlatform == TargetPlatform.linux) {
      await startBuzzing(taskTitle);
      return;
    }

    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    }

    final scheduledDate =
        tz.TZDateTime.now(tz.local).add(Duration(seconds: secondsFromNow));

    await _plugin.zonedSchedule(
      id: _initialAlarmId,
      title: 'Check-in Due!',
      body: 'Tap to check in for: $taskTitle',
      scheduledDate: scheduledDate,
      notificationDetails: _checkInDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> startBuzzing(String taskTitle) async {
    stopBuzzing();
    _plugin.show(
      id: _initialAlarmId,
      title: 'Check-in Due!',
      body: 'Tap to check in for: $taskTitle',
      notificationDetails: _checkInDetails,
    ).catchError((_) {});
  }

  void stopBuzzing() {
    _buzzingTimer?.cancel();
    _buzzingTimer = null;
  }

  Future<void> cancelSessionNotification() async {
    await _plugin.cancel(id: _sessionNotificationId);
  }

  Future<void> cancelAll() async {
    stopBuzzing();
    await _plugin.cancel(id: _sessionNotificationId);
    await _plugin.cancel(id: _initialAlarmId);
  }
}
