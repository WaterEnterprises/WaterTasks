class TaskListModel {
  final int? id;
  final String name;
  final int color;
  final int checkInIntervalSeconds;
  final DateTime createdAt;

  TaskListModel({
    this.id,
    required this.name,
    this.color = 0xFF2196F3,
    this.checkInIntervalSeconds = 120,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color': color,
      'check_in_interval_seconds': checkInIntervalSeconds,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TaskListModel.fromMap(Map<String, dynamic> map) {
    return TaskListModel(
      id: map['id'] as int,
      name: map['name'] as String,
      color: map['color'] as int? ?? 0xFF2196F3,
      checkInIntervalSeconds: map['check_in_interval_seconds'] as int? ?? 120,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  TaskListModel copyWith({
    int? id,
    String? name,
    int? color,
    int? checkInIntervalSeconds,
    DateTime? createdAt,
  }) {
    return TaskListModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      checkInIntervalSeconds: checkInIntervalSeconds ?? this.checkInIntervalSeconds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
