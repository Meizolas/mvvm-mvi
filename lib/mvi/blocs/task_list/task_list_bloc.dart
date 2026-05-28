import 'package:bloc/bloc.dart';

import '../../../shared/repositories/task_repository.dart';
import '../../../shared/services/fake_api_service.dart';
import 'task_list_event.dart';
import 'task_list_state.dart';

class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  TaskListBloc({
    required TaskRepository repository,
    required FakeApiService apiService,
  })  : _repository = repository,
        _apiService = apiService,
        super(const TaskListState()) {
    on<TaskListStarted>(_onStarted);
    on<TaskListSyncedFromApi>(_onSyncedFromApi);
    on<TaskCreated>(_onCreated);
    on<TaskUpdated>(_onUpdated);
    on<TaskToggled>(_onToggled);
    on<TaskDeleted>(_onDeleted);
    on<TaskListCleared>(_onCleared);
    on<TaskFilterChanged>((event, emit) => emit(state.copyWith(filter: event.filter)));
    on<TaskSortChanged>((event, emit) => emit(state.copyWith(sort: event.sort)));
    on<TaskSearchChanged>((event, emit) => emit(state.copyWith(search: event.search)));
  }

  final TaskRepository _repository;
  final FakeApiService _apiService;

  Future<void> _onStarted(TaskListStarted event, Emitter<TaskListState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      if (event.seedIfEmpty && _repository.estimatedCount == 0) {
        await _repository.seed(20);
      }
      emit(state.copyWith(tasks: await _repository.getTasks(), isLoading: false, clearError: true));
    } catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
    }
  }

  Future<void> _onSyncedFromApi(TaskListSyncedFromApi event, Emitter<TaskListState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final remoteTasks = await _apiService.fetchTasks(count: 12);
      await _repository.clear();
      for (final task in remoteTasks) {
        await _repository.createTask(task.copyWith(id: null));
      }
      emit(state.copyWith(tasks: await _repository.getTasks(), isLoading: false));
    } catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
    }
  }

  Future<void> _onCreated(TaskCreated event, Emitter<TaskListState> emit) async {
    await _repository.createTask(event.task);
    emit(state.copyWith(tasks: await _repository.getTasks()));
  }

  Future<void> _onUpdated(TaskUpdated event, Emitter<TaskListState> emit) async {
    await _repository.updateTask(event.task);
    emit(state.copyWith(tasks: await _repository.getTasks()));
  }

  Future<void> _onToggled(TaskToggled event, Emitter<TaskListState> emit) async {
    final updated = event.task.copyWith(isDone: !event.task.isDone);
    await _repository.updateTask(updated);
    await _apiService.syncTask(updated);
    emit(state.copyWith(tasks: await _repository.getTasks()));
  }

  Future<void> _onDeleted(TaskDeleted event, Emitter<TaskListState> emit) async {
    await _repository.deleteTask(event.id);
    emit(state.copyWith(tasks: await _repository.getTasks()));
  }

  Future<void> _onCleared(TaskListCleared event, Emitter<TaskListState> emit) async {
    await _repository.clear();
    emit(state.copyWith(tasks: const []));
  }
}
