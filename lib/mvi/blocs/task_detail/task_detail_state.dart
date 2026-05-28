import 'package:equatable/equatable.dart';

import '../../../shared/models/task.dart';

class TaskDetailState extends Equatable {
  const TaskDetailState({
    this.task,
    this.isLoading = false,
    this.error,
    this.deleted = false,
  });

  final Task? task;
  final bool isLoading;
  final String? error;
  final bool deleted;

  TaskDetailState copyWith({
    Task? task,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? deleted,
  }) {
    return TaskDetailState(
      task: task ?? this.task,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      deleted: deleted ?? this.deleted,
    );
  }

  @override
  List<Object?> get props => [task, isLoading, error, deleted];
}
