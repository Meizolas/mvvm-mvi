import 'package:equatable/equatable.dart';

class Task extends Equatable {
  const Task({
    this.id,
    required this.title,
    required this.description,
    required this.isDone,
    required this.createdAt,
    required this.priority,
  });

  final int? id;
  final String title;
  final String description;
  final bool isDone;
  final DateTime createdAt;
  final int priority;

  Task copyWith({
    int? id,
    String? title,
    String? description,
    bool? isDone,
    DateTime? createdAt,
    int? priority,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isDone': isDone ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'priority': priority,
    };
  }

  factory Task.fromMap(Map<String, Object?> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      isDone: (map['isDone'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      priority: map['priority'] as int,
    );
  }

  @override
  List<Object?> get props => [id, title, description, isDone, createdAt, priority];
}
