import 'package:bloc/bloc.dart';

import '../../../shared/repositories/task_repository.dart';
import '../../../shared/services/fake_api_service.dart';
import 'task_detail_event.dart';
import 'task_detail_state.dart';

class TaskDetailBloc extends Bloc<TaskDetailEvent, TaskDetailState> {
  TaskDetailBloc({
    required TaskRepository repository,
    required FakeApiService apiService,
  })  : _repository = repository,
        _apiService = apiService,
        super(const TaskDetailState()) {
    on<TaskDetailStarted>(_onStarted);
    on<TaskDetailToggled>(_onToggled);
    on<TaskDetailDeleted>(_onDeleted);
  }

  final TaskRepository _repository;
  final FakeApiService _apiService;

  Future<void> _onStarted(TaskDetailStarted event, Emitter<TaskDetailState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      emit(state.copyWith(task: await _repository.getTaskById(event.id), isLoading: false));
    } catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
    }
  }

  Future<void> _onToggled(TaskDetailToggled event, Emitter<TaskDetailState> emit) async {
    final current = state.task;
    if (current == null) return;
    final updated = current.copyWith(isDone: !current.isDone);
    await _repository.updateTask(updated);
    await _apiService.syncTask(updated);
    emit(state.copyWith(task: updated));
  }

  Future<void> _onDeleted(TaskDetailDeleted event, Emitter<TaskDetailState> emit) async {
    final id = state.task?.id;
    if (id == null) return;
    await _repository.deleteTask(id);
    emit(state.copyWith(deleted: true));
  }
}
