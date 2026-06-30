class SessionModel {
  final int? id;
  final int taskId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final int checkInCount;
  final DateTime? lastCheckInTime;

  SessionModel({
    this.id,
    required this.taskId,
    DateTime? startTime,
    this.endTime,
    this.durationSeconds = 0,
    this.checkInCount = 0,
    this.lastCheckInTime,
  }) : startTime = startTime ?? DateTime.now();

  bool get isActive => endTime == null;

  Duration get duration => Duration(seconds: durationSeconds);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'task_id': taskId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'check_in_count': checkInCount,
      'last_check_in_time': lastCheckInTime?.toIso8601String(),
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] as int,
      taskId: map['task_id'] as int,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      checkInCount: map['check_in_count'] as int? ?? 0,
      lastCheckInTime: map['last_check_in_time'] != null
          ? DateTime.parse(map['last_check_in_time'] as String)
          : null,
    );
  }

  SessionModel copyWith({
    int? id,
    int? taskId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    int? checkInCount,
    DateTime? lastCheckInTime,
    bool clearEndTime = false,
  }) {
    return SessionModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      startTime: startTime ?? this.startTime,
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      durationSeconds: durationSeconds ?? this.durationSeconds,
      checkInCount: checkInCount ?? this.checkInCount,
      lastCheckInTime: lastCheckInTime ?? this.lastCheckInTime,
    );
  }
}
