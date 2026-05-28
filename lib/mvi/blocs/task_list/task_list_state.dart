import 'package:equatable/equatable.dart';

import '../../../shared/models/task.dart';
import '../../../shared/repositories/task_repository.dart';

class TaskListState extends Equatable {
  const TaskListState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.filter = TaskFilter.all,
    this.sort = TaskSort.createdAtDesc,
    this.search = '',
  });

  final List<Task> tasks;
  final bool isLoading;
  final String? error;
  final TaskFilter filter;
  final TaskSort sort;
  final String search;

  List<Task> get visibleTasks => applyTaskQuery(
        tasks: tasks,
        filter: filter,
        search: search,
        sort: sort,
      );
  int get total => tasks.length;
  int get done => tasks.where((task) => task.isDone).length;
  int get pending => total - done;
  double get averagePriority {
    if (tasks.isEmpty) return 0;
    return tasks.map((task) => task.priority).reduce((a, b) => a + b) / tasks.length;
  }

  TaskListState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
    bool clearError = false,
    TaskFilter? filter,
    TaskSort? sort,
    String? search,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      search: search ?? this.search,
    );
  }

  @override
  List<Object?> get props => [tasks, isLoading, error, filter, sort, search];
}
