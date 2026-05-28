import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'mvi/views/task_list_screen.dart';
import 'mvvm/views/task_list_screen.dart';
import 'shared/database/database_helper.dart';
import 'shared/repositories/task_repository.dart';
import 'shared/services/fake_api_service.dart';
import 'shared/utils/theme_controller.dart';

enum Architecture { mvvm, mvi }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await DatabaseHelper.openRepository();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeController(),
      child: TasksExperimentApp(repository: repository),
    ),
  );
}

class TasksExperimentApp extends StatefulWidget {
  const TasksExperimentApp({
    super.key,
    required this.repository,
  });

  final TaskRepository repository;

  @override
  State<TasksExperimentApp> createState() => _TasksExperimentAppState();
}

class _TasksExperimentAppState extends State<TasksExperimentApp> {
  final FakeApiService _apiService = FakeApiService();
  Architecture _architecture = Architecture.mvvm;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MVVM vs MVI Tasks',
      themeMode: theme.mode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F5F8F)),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7AA5D8),
          brightness: Brightness.dark,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
      ),
      home: _architecture == Architecture.mvvm
          ? MvvmTaskListScreen(
              repository: widget.repository,
              apiService: _apiService,
              onArchitectureChanged: _toggleArchitecture,
            )
          : MviTaskListScreen(
              repository: widget.repository,
              apiService: _apiService,
              onArchitectureChanged: _toggleArchitecture,
            ),
    );
  }

  void _toggleArchitecture() {
    setState(() {
      _architecture = _architecture == Architecture.mvvm ? Architecture.mvi : Architecture.mvvm;
    });
  }
}
