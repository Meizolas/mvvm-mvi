import '../repositories/task_repository.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final TaskRepository repository = InMemoryTaskRepository();

  // Projeto focado em Flutter Web: armazenamento em memoria evita incompatibilidades
  // de SQLite no Chrome e mantem a camada de dados compartilhada pelas arquiteturas.
  static Future<TaskRepository> openRepository() async => repository;
}
