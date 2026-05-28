import 'package:equatable/equatable.dart';

abstract class TaskDetailEvent extends Equatable {
  const TaskDetailEvent();

  @override
  List<Object?> get props => [];
}

class TaskDetailStarted extends TaskDetailEvent {
  const TaskDetailStarted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class TaskDetailToggled extends TaskDetailEvent {
  const TaskDetailToggled();
}

class TaskDetailDeleted extends TaskDetailEvent {
  const TaskDetailDeleted();
}
