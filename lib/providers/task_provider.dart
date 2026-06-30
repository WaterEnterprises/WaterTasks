import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/task_list_model.dart';
import '../models/task_model.dart';
import '../models/session_model.dart';
import '../services/background_notification_service.dart';
import '../services/system_tray_service.dart';

class TaskProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final BackgroundNotificationService _notif = BackgroundNotificationService();

  List<TaskListModel> _taskLists = [];
  List<TaskModel> _currentTasks = [];
  SessionModel? _activeSession;
  TaskModel? _activeTask;
  TaskListModel? _activeTaskList;
  bool _isLoading = false;

  List<TaskListModel> get taskLists => _taskLists;
  List<TaskModel> get currentTasks => _currentTasks;
  SessionModel? get activeSession => _activeSession;
  TaskModel? get activeTask => _activeTask;
  TaskListModel? get activeTaskList => _activeTaskList;
  bool get isLoading => _isLoading;
  bool get hasActiveSession => _activeSession != null;

  Future<void> loadTaskLists() async {
    _isLoading = true;
    notifyListeners();
    _taskLists = await _db.getTaskLists();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTaskList(String name, int color, {int checkInIntervalSeconds = 120}) async {
    final list = TaskListModel(
      name: name,
      color: color,
      checkInIntervalSeconds: checkInIntervalSeconds,
    );
    await _db.insertTaskList(list);
    await loadTaskLists();
  }

  Future<void> updateTaskList(TaskListModel taskList) async {
    await _db.updateTaskList(taskList);
    await loadTaskLists();
  }

  Future<void> deleteTaskList(int id) async {
    await _db.deleteTaskList(id);
    await loadTaskLists();
  }

  Future<void> loadTasks(int listId) async {
    _isLoading = true;
    notifyListeners();
    _currentTasks = await _db.getTasks(listId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTask(int listId, String title, String? description) async {
    final task = TaskModel(listId: listId, title: title, description: description);
    await _db.insertTask(task);
    await loadTasks(listId);
  }

  Future<void> toggleTaskComplete(TaskModel task) async {
    final updated = task.copyWith(
      completedAt: task.isCompleted ? null : DateTime.now(),
      clearCompleted: task.isCompleted,
    );
    await _db.updateTask(updated);
    await loadTasks(task.listId);
  }

  Future<void> deleteTask(TaskModel task) async {
    await _db.deleteTask(task.id!);
    await loadTasks(task.listId);
  }

  Future<void> checkActiveSession() async {
    _activeSession = await _db.getActiveSession();
    if (_activeSession != null) {
      final allTasks = await _db.getAllTasks();
      _activeTask = allTasks.firstWhere(
        (t) => t.id == _activeSession!.taskId,
        orElse: () => allTasks.first,
      );
      if (_activeTask != null) {
        final lists = await _db.getTaskLists();
        _activeTaskList = lists.firstWhere(
          (l) => l.id == _activeTask!.listId,
          orElse: () => lists.first,
        );
        await _notif.showSessionNotification(_activeTask!.title);
        await _notif.scheduleCheckInAlarm(
          _activeTask!.title,
          _activeTaskList!.checkInIntervalSeconds,
        );
        try {
          await SystemTrayService().setSessionActive(_activeTask!.title);
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  Future<void> startTask(TaskModel task, TaskListModel taskList) async {
    if (_activeSession != null) return;
    final session = SessionModel(taskId: task.id!);
    final id = await _db.insertSession(session);
    _activeSession = session.copyWith(id: id);
    _activeTask = task;
    _activeTaskList = taskList;
    await _notif.showSessionNotification(task.title);
    await _notif.scheduleCheckInAlarm(task.title, taskList.checkInIntervalSeconds);
    try {
      await SystemTrayService().setSessionActive(task.title);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> checkIn() async {
    if (_activeSession == null) return;
    final now = DateTime.now();
    final elapsed = now.difference(_activeSession!.startTime).inSeconds;
    _activeSession = _activeSession!.copyWith(
      durationSeconds: elapsed,
      checkInCount: _activeSession!.checkInCount + 1,
      lastCheckInTime: now,
    );
    await _db.updateSession(_activeSession!);
    if (_activeTask != null && _activeTaskList != null) {
      await _notif.updateSessionNotification(
        _activeTask!.title,
        'Check-in ${_activeSession!.checkInCount} — next in ${_activeTaskList!.checkInIntervalSeconds}s',
      );
      await _notif.scheduleCheckInAlarm(
        _activeTask!.title,
        _activeTaskList!.checkInIntervalSeconds,
      );
    }
    notifyListeners();
  }

  int computeSecondsRemaining() {
    if (_activeSession == null || _activeTaskList == null) return 0;
    final interval = _activeTaskList!.checkInIntervalSeconds;
    final reference = _activeSession!.lastCheckInTime ?? _activeSession!.startTime;
    final elapsed = DateTime.now().difference(reference).inSeconds;
    if (elapsed <= 0) return interval;
    final pointInInterval = elapsed % interval;
    return pointInInterval == 0 ? 0 : interval - pointInInterval;
  }

  Future<void> stopTask() async {
    if (_activeSession == null) return;
    final now = DateTime.now();
    final elapsed = now.difference(_activeSession!.startTime).inSeconds;
    _activeSession = _activeSession!.copyWith(
      endTime: now,
      durationSeconds: elapsed,
    );
    await _db.updateSession(_activeSession!);
    await _notif.cancelAll();
    try {
      await SystemTrayService().clearSession();
    } catch (_) {}
    _activeSession = null;
    _activeTask = null;
    _activeTaskList = null;
    notifyListeners();
  }
}
