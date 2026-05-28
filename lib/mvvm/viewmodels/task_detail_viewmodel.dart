import 'package:flutter/foundation.dart';

import '../../shared/models/task.dart';
import '../../shared/repositories/task_repository.dart';
import '../../shared/services/fake_api_service.dart';

class TaskDetailViewModel extends ChangeNotifier {
  TaskDetailViewModel({
    required TaskRepository repository,
    required FakeApiService apiService,
  })  : _repository = repository,
        _apiService = apiService;

  final TaskRepository _repository;
  final FakeApiService _apiService;

  Task? _task;
  bool _isLoading = false;
  String? _error;

  Task? get task => _task;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load(int id) async {
    _setLoading(true);
    try {
      _task = await _repository.getTaskById(id);
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleDone() async {
    final current = _task;
    if (current == null) return;
    final updated = current.copyWith(isDone: !current.isDone);
    _task = await _repository.updateTask(updated);
    await _apiService.syncTask(updated);
    notifyListeners();
  }

  Future<void> save(Task task) async {
    _task = await _repository.updateTask(task);
    notifyListeners();
  }

  Future<void> delete() async {
    final id = _task?.id;
    if (id == null) return;
    await _repository.deleteTask(id);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
