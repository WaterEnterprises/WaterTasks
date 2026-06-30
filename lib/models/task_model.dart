class TaskModel {
  final int? id;
  final int listId;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;

  TaskModel({
    this.id,
    required this.listId,
    required this.title,
    this.description,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCompleted => completedAt != null;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'list_id': listId,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as int,
      listId: map['list_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  TaskModel copyWith({
    int? id,
    int? listId,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearCompleted = false,
  }) {
    return TaskModel(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompleted ? null : (completedAt ?? this.completedAt),
    );
  }
}
