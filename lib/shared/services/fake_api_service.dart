import 'dart:math';

import '../models/task.dart';

class FakeApiService {
  final Random _random = Random(42);

  Future<List<Task>> fetchTasks({int count = 20}) async {
    await Future<void>.delayed(Duration(milliseconds: 200 + _random.nextInt(300)));
    return List.generate(
      count,
      (index) => Task(
        id: index + 1,
        title: 'Tarefa remota ${index + 1}',
        description: 'Registro simulado vindo da API fake.',
        isDone: index % 4 == 0,
        createdAt: DateTime.now().subtract(Duration(hours: index)),
        priority: (index % 5) + 1,
      ),
    );
  }

  Future<void> syncTask(Task task) async {
    await Future<void>.delayed(Duration(milliseconds: 100 + _random.nextInt(200)));
  }
}
