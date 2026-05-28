import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../mvi/blocs/task_list/task_list_bloc.dart';
import '../mvi/blocs/task_list/task_list_event.dart';
import '../mvi/blocs/task_list/task_list_state.dart';
import '../mvvm/viewmodels/task_list_viewmodel.dart';
import '../shared/models/task.dart';
import '../shared/repositories/task_repository.dart';
import '../shared/services/fake_api_service.dart';
import '../shared/utils/rebuild_counter.dart';
import '../shared/utils/theme_controller.dart';

class BenchmarkResult {
  const BenchmarkResult({
    required this.architecture,
    required this.scenario,
    required this.execution,
    required this.timeMs,
    required this.rebuilds,
    required this.memoryKb,
    required this.timestamp,
  });

  final String architecture;
  final String scenario;
  final int execution;
  final int timeMs;
  final int rebuilds;
  final int memoryKb;
  final DateTime timestamp;

  String toCsvLine() {
    return [
      architecture,
      scenario,
      execution,
      timeMs,
      rebuilds,
      memoryKb,
      timestamp.toIso8601String(),
    ].join(',');
  }
}

class BenchmarkProgress {
  const BenchmarkProgress({
    required this.architecture,
    required this.scenario,
    required this.execution,
    required this.totalExecutions,
  });

  final String architecture;
  final String scenario;
  final int execution;
  final int totalExecutions;
}

typedef ProgressCallback = void Function(BenchmarkProgress progress);

class BenchmarkRunner {
  BenchmarkRunner({required this.themeController});

  final ThemeController themeController;
  static const int runsPerScenario = 30;

  Future<List<BenchmarkResult>> runAll({ProgressCallback? onProgress}) async {
    final results = <BenchmarkResult>[];
    final scenarios = <String, Future<int> Function(String architecture)>{
      'carregamento_100': (architecture) => _initialLoad(architecture, 100),
      'carregamento_500': (architecture) => _initialLoad(architecture, 500),
      'carregamento_1000': (architecture) => _initialLoad(architecture, 1000),
      'navegacao_5_telas': _navigation,
      'crud_criar_50': _createBatch,
      'crud_editar_50': _editBatch,
      'crud_excluir_50': _deleteBatch,
      'sync_10_paralelos': _parallelSync,
      'filtrar_buscar_1000': _filterSearch,
      'alternar_tema_20': _toggleTheme,
    };

    for (final architecture in ['mvvm', 'mvi']) {
      for (final entry in scenarios.entries) {
        for (var execution = 1; execution <= runsPerScenario; execution++) {
          onProgress?.call(
            BenchmarkProgress(
              architecture: architecture,
              scenario: entry.key,
              execution: execution,
              totalExecutions: runsPerScenario,
            ),
          );
          RebuildCounter.reset();
          final stopwatch = Stopwatch()..start();
          final objectCount = await entry.value(architecture);
          stopwatch.stop();
          final rebuilds = RebuildCounter.reset();
          results.add(
            BenchmarkResult(
              architecture: architecture,
              scenario: entry.key,
              execution: execution,
              timeMs: stopwatch.elapsedMilliseconds,
              rebuilds: rebuilds,
              memoryKb: _estimateMemoryKb(objectCount),
              timestamp: DateTime.now(),
            ),
          );
          await Future<void>.delayed(Duration.zero);
        }
      }
    }
    return results;
  }

  Future<int> _initialLoad(String architecture, int count) async {
    final repository = InMemoryTaskRepository();
    final apiService = FakeApiService();
    await repository.seed(count);
    if (architecture == 'mvvm') {
      final vm = TaskListViewModel(repository: repository, apiService: apiService);
      await vm.load(seedIfEmpty: false);
      RebuildCounter.increment();
      return vm.tasks.length;
    }
    final bloc = TaskListBloc(repository: repository, apiService: apiService);
    bloc.add(const TaskListStarted(seedIfEmpty: false));
    final state = await _waitBloc(bloc);
    await bloc.close();
    RebuildCounter.increment();
    return state.tasks.length;
  }

  Future<int> _navigation(String architecture) async {
    final repository = InMemoryTaskRepository();
    await repository.seed(100);
    // Simula a ida e volta entre lista, detalhe, formulario, estatisticas e ajustes.
    for (var i = 0; i < 10; i++) {
      RebuildCounter.increment();
      await Future<void>.delayed(Duration.zero);
    }
    return repository.estimatedCount;
  }

  Future<int> _createBatch(String architecture) async {
    final repository = InMemoryTaskRepository();
    final apiService = FakeApiService();
    if (architecture == 'mvvm') {
      final vm = TaskListViewModel(repository: repository, apiService: apiService);
      for (var i = 0; i < 50; i++) {
        await vm.saveTask(_task(i));
      }
      return vm.tasks.length;
    }
    final bloc = TaskListBloc(repository: repository, apiService: apiService);
    for (var i = 0; i < 50; i++) {
      bloc.add(TaskCreated(_task(i)));
      await _waitBloc(bloc);
      RebuildCounter.increment();
    }
    final count = bloc.state.tasks.length;
    await bloc.close();
    return count;
  }

  Future<int> _editBatch(String architecture) async {
    final repository = InMemoryTaskRepository();
    final apiService = FakeApiService();
    await repository.seed(50);
    if (architecture == 'mvvm') {
      final vm = TaskListViewModel(repository: repository, apiService: apiService);
      await vm.load(seedIfEmpty: false);
      for (final task in vm.tasks) {
        await vm.saveTask(task.copyWith(title: '${task.title} editada'));
      }
      return vm.tasks.length;
    }
    final bloc = TaskListBloc(repository: repository, apiService: apiService);
    bloc.add(const TaskListStarted(seedIfEmpty: false));
    await _waitBloc(bloc);
    for (final task in bloc.state.tasks) {
      bloc.add(TaskUpdated(task.copyWith(title: '${task.title} editada')));
      await _waitBloc(bloc);
      RebuildCounter.increment();
    }
    final count = bloc.state.tasks.length;
    await bloc.close();
    return count;
  }

  Future<int> _deleteBatch(String architecture) async {
    final repository = InMemoryTaskRepository();
    final apiService = FakeApiService();
    await repository.seed(50);
    if (architecture == 'mvvm') {
      final vm = TaskListViewModel(repository: repository, apiService: apiService);
      await vm.load(seedIfEmpty: false);
      for (final task in List<Task>.from(vm.tasks)) {
        await vm.deleteTask(task.id!);
      }
      return vm.tasks.length;
    }
    final bloc = TaskListBloc(repository: repository, apiService: apiService);
    bloc.add(const TaskListStarted(seedIfEmpty: false));
    await _waitBloc(bloc);
    for (final task in List<Task>.from(bloc.state.tasks)) {
      bloc.add(TaskDeleted(task.id!));
      await _waitBloc(bloc);
      RebuildCounter.increment();
    }
    final count = bloc.state.tasks.length;
    await bloc.close();
    return count;
  }

  Future<int> _parallelSync(String architecture) async {
    final apiService = FakeApiService();
    final tasks = List.generate(10, _task);
    await Future.wait(tasks.map(apiService.syncTask));
    RebuildCounter.increment();
    return tasks.length;
  }

  Future<int> _filterSearch(String architecture) async {
    final repository = InMemoryTaskRepository();
    final apiService = FakeApiService();
    await repository.seed(1000);
    if (architecture == 'mvvm') {
      final vm = TaskListViewModel(repository: repository, apiService: apiService);
      await vm.load(seedIfEmpty: false);
      vm.setFilter(TaskFilter.pending);
      vm.setSearch('99');
      vm.setSort(TaskSort.priorityDesc);
      return vm.visibleTasks.length;
    }
    final bloc = TaskListBloc(repository: repository, apiService: apiService);
    bloc.add(const TaskListStarted(seedIfEmpty: false));
    await _waitBloc(bloc);
    bloc.add(const TaskFilterChanged(TaskFilter.pending));
    await _waitBloc(bloc);
    bloc.add(const TaskSearchChanged('99'));
    await _waitBloc(bloc);
    bloc.add(const TaskSortChanged(TaskSort.priorityDesc));
    await _waitBloc(bloc);
    final count = bloc.state.visibleTasks.length;
    await bloc.close();
    return count;
  }

  Future<int> _toggleTheme(String architecture) async {
    for (var i = 0; i < 20; i++) {
      themeController.toggle();
      RebuildCounter.increment();
      await Future<void>.delayed(Duration.zero);
    }
    return 20;
  }

  Task _task(int index) {
    return Task(
      title: 'Benchmark ${index + 1}',
      description: 'Tarefa criada durante o benchmark.',
      isDone: false,
      createdAt: DateTime.now(),
      priority: (index % 5) + 1,
    );
  }

  int _estimateMemoryKb(int taskLikeObjects) {
    return ((taskLikeObjects * 200) / 1024).ceil();
  }

  Future<TaskListState> _waitBloc(TaskListBloc bloc) async {
    return bloc.stream.firstWhere((state) => !state.isLoading).timeout(
      const Duration(seconds: 5),
      onTimeout: () => bloc.state,
    );
  }

  static String toCsv(List<BenchmarkResult> results) {
    return [
      'arquitetura,cenario,execucao_n,tempo_ms,rebuilds,memoria_estimada_kb,timestamp',
      ...results.map((result) => result.toCsvLine()),
    ].join('\n');
  }

  static void downloadCsv(List<BenchmarkResult> results) {
    final csv = toCsv(results);
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = 'benchmark_mvvm_mvi_${DateTime.now().millisecondsSinceEpoch}.csv'
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
}

class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({super.key});

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  List<BenchmarkResult> _results = [];
  BenchmarkProgress? _progress;
  bool _isRunning = false;
  int _progressCount = 0;

  @override
  Widget build(BuildContext context) {
    RebuildCounter.increment();
    final done = _isRunning ? _progressCount : _results.length;
    const total = 2 * 10 * BenchmarkRunner.runsPerScenario;
    return Scaffold(
      appBar: AppBar(title: const Text('Benchmark')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: _isRunning ? null : _run,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Executar Benchmark Completo'),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: _isRunning || done > 0 ? done / total : 0),
          const SizedBox(height: 8),
          Text(_progressLabel(done, total)),
          const SizedBox(height: 16),
          if (_results.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => BenchmarkRunner.downloadCsv(_results),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Baixar CSV'),
            ),
          const SizedBox(height: 16),
          Text('Resultados', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_results.isEmpty)
            const Text('Nenhuma execucao realizada ainda.')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Arquitetura')),
                  DataColumn(label: Text('Cenario')),
                  DataColumn(label: Text('N')),
                  DataColumn(label: Text('Tempo')),
                  DataColumn(label: Text('Rebuilds')),
                  DataColumn(label: Text('Memoria')),
                ],
                rows: _results.take(120).map((result) {
                  return DataRow(
                    cells: [
                      DataCell(Text(result.architecture)),
                      DataCell(Text(result.scenario)),
                      DataCell(Text('${result.execution}')),
                      DataCell(Text('${result.timeMs} ms')),
                      DataCell(Text('${result.rebuilds}')),
                      DataCell(Text('${result.memoryKb} KB')),
                    ],
                  );
                }).toList(),
              ),
            ),
          if (_results.length > 120)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Mostrando as primeiras 120 linhas de ${_results.length}. O CSV contem tudo.'),
            ),
        ],
      ),
    );
  }

  String _progressLabel(int done, int total) {
    final progress = _progress;
    if (_isRunning && progress != null) {
      return 'Rodando ${progress.architecture} / ${progress.scenario} - execucao ${progress.execution} de ${progress.totalExecutions} ($done/$total)';
    }
    if (_results.isNotEmpty) return 'Concluido: $done medicoes geradas.';
    return 'Pronto para iniciar: $total medicoes.';
  }

  Future<void> _run() async {
    setState(() {
      _results = [];
      _progress = null;
      _isRunning = true;
      _progressCount = 0;
    });
    final runner = BenchmarkRunner(themeController: context.read<ThemeController>());
    final results = await runner.runAll(
      onProgress: (progress) {
        if (!mounted) return;
        setState(() {
          _progress = progress;
          _progressCount++;
          _results = List<BenchmarkResult>.from(_results);
        });
      },
    );
    if (!mounted) return;
    setState(() {
      _results = results;
      _isRunning = false;
      _progressCount = results.length;
    });
    BenchmarkRunner.downloadCsv(results);
  }
}
