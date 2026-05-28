import 'package:equatable/equatable.dart';

import '../../../shared/models/task.dart';
import '../../../shared/repositories/task_repository.dart';

abstract class TaskListEvent extends Equatable {
  const TaskListEvent();

  @override
  List<Object?> get props => [];
}

class TaskListStarted extends TaskListEvent {
  const TaskListStarted({this.seedIfEmpty = true});

  final bool seedIfEmpty;

  @override
  List<Object?> get props => [seedIfEmpty];
}

class TaskListSyncedFromApi extends TaskListEvent {
  const TaskListSyncedFromApi();
}

class TaskCreated extends TaskListEvent {
  const TaskCreated(this.task);

  final Task task;

  @override
  List<Object?> get props => [task];
}

class TaskUpdated extends TaskListEvent {
  const TaskUpdated(this.task);

  final Task task;

  @override
  List<Object?> get props => [task];
}

class TaskToggled extends TaskListEvent {
  const TaskToggled(this.task);

  final Task task;

  @override
  List<Object?> get props => [task];
}

class TaskDeleted extends TaskListEvent {
  const TaskDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class TaskListCleared extends TaskListEvent {
  const TaskListCleared();
}

class TaskFilterChanged extends TaskListEvent {
  const TaskFilterChanged(this.filter);

  final TaskFilter filter;

  @override
  List<Object?> get props => [filter];
}

class TaskSortChanged extends TaskListEvent {
  const TaskSortChanged(this.sort);

  final TaskSort sort;

  @override
  List<Object?> get props => [sort];
}

class TaskSearchChanged extends TaskListEvent {
  const TaskSearchChanged(this.search);

  final String search;

  @override
  List<Object?> get props => [search];
}
