import 'package:flutter/foundation.dart';

import '../../shared/models/task.dart';
import '../../shared/repositories/task_repository.dart';
import '../../shared/services/fake_api_service.dart';

class TaskListViewModel extends ChangeNotifier {
  TaskListViewModel({
    required TaskRepository repository,
    required FakeApiService apiService,
  })  : _repository = repository,
        _apiService = apiService;

  final TaskRepository _repository;
  final FakeApiService _apiService;

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  TaskFilter _filter = TaskFilter.all;
  TaskSort _sort = TaskSort.createdAtDesc;
  String _search = '';

  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get visibleTasks => applyTaskQuery(
        tasks: _tasks,
        filter: _filter,
        search: _search,
        sort: _sort,
      );
  bool get isLoading => _isLoading;
  String? get error => _error;
  TaskFilter get filter => _filter;
  TaskSort get sort => _sort;
  String get search => _search;

  int get total => _tasks.length;
  int get done => _tasks.where((task) => task.isDone).length;
  int get pending => total - done;
  double get averagePriority {
    if (_tasks.isEmpty) return 0;
    return _tasks.map((task) => task.priority).reduce((a, b) => a + b) / _tasks.length;
  }

  Future<void> load({bool seedIfEmpty = true}) async {
    _setLoading(true);
    try {
      if (seedIfEmpty && _repository.estimatedCount == 0) {
        await _repository.seed(20);
      }
      _tasks = await _repository.getTasks();
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> syncFromApi() async {
    _setLoading(true);
    try {
      final remoteTasks = await _apiService.fetchTasks(count: 12);
      await _repository.clear();
      for (final task in remoteTasks) {
        await _repository.createTask(task.copyWith(id: null));
      }
      await load(seedIfEmpty: false);
    } catch (error) {
      _error = error.toString();
      _setLoading(false);
    }
  }

  Future<void> saveTask(Task task) async {
    if (task.id == null) {
      await _repository.createTask(task);
    } else {
      await _repository.updateTask(task);
    }
    await load(seedIfEmpty: false);
  }

  Future<void> toggleDone(Task task) async {
    await _repository.updateTask(task.copyWith(isDone: !task.isDone));
    await _apiService.syncTask(task);
    await load(seedIfEmpty: false);
  }

  Future<void> deleteTask(int id) async {
    await _repository.deleteTask(id);
    await load(seedIfEmpty: false);
  }

  Future<void> clearAll() async {
    await _repository.clear();
    await load(seedIfEmpty: false);
  }

  void setFilter(TaskFilter value) {
    _filter = value;
    notifyListeners();
  }

  void setSort(TaskSort value) {
    _sort = value;
    notifyListeners();
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
