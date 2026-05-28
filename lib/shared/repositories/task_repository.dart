import 'dart:async';

import '../models/task.dart';

enum TaskFilter { all, pending, done }

enum TaskSort { createdAtDesc, priorityDesc }

abstract class TaskRepository {
  Future<List<Task>> getTasks();
  Future<Task?> getTaskById(int id);
  Future<Task> createTask(Task task);
  Future<Task> updateTask(Task task);
  Future<void> deleteTask(int id);
  Future<void> clear();
  Future<void> seed(int count);
  int get estimatedCount;
}

class InMemoryTaskRepository implements TaskRepository {
  final List<Task> _tasks = [];
  int _nextId = 1;

  @override
  int get estimatedCount => _tasks.length;

  @override
  Future<List<Task>> getTasks() async {
    return List<Task>.unmodifiable(_tasks);
  }

  @override
  Future<Task?> getTaskById(int id) async {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  @override
  Future<Task> createTask(Task task) async {
    final saved = task.copyWith(id: _nextId++);
    _tasks.add(saved);
    return saved;
  }

  @override
  Future<Task> updateTask(Task task) async {
    final id = task.id;
    if (id == null) {
      throw StateError('A tarefa precisa ter id para ser atualizada.');
    }
    final index = _tasks.indexWhere((item) => item.id == id);
    if (index == -1) {
      throw StateError('Tarefa $id nao encontrada.');
    }
    _tasks[index] = task;
    return task;
  }

  @override
  Future<void> deleteTask(int id) async {
    _tasks.removeWhere((task) => task.id == id);
  }

  @override
  Future<void> clear() async {
    _tasks.clear();
    _nextId = 1;
  }

  @override
  Future<void> seed(int count) async {
    await clear();
    for (var i = 0; i < count; i++) {
      await createTask(
        Task(
          title: 'Tarefa ${i + 1}',
          description: 'Descricao gerada para a tarefa ${i + 1}.',
          isDone: i % 3 == 0,
          createdAt: DateTime.now().subtract(Duration(minutes: i * 7)),
          priority: (i % 5) + 1,
        ),
      );
    }
  }
}

List<Task> applyTaskQuery({
  required List<Task> tasks,
  required TaskFilter filter,
  required String search,
  required TaskSort sort,
}) {
  var result = tasks.where((task) {
    final statusMatches = switch (filter) {
      TaskFilter.all => true,
      TaskFilter.pending => !task.isDone,
      TaskFilter.done => task.isDone,
    };
    final term = search.trim().toLowerCase();
    final searchMatches = term.isEmpty ||
        task.title.toLowerCase().contains(term) ||
        task.description.toLowerCase().contains(term);
    return statusMatches && searchMatches;
  }).toList();

  result.sort((a, b) {
    return switch (sort) {
      TaskSort.createdAtDesc => b.createdAt.compareTo(a.createdAt),
      TaskSort.priorityDesc => b.priority.compareTo(a.priority),
    };
  });
  return result;
}
