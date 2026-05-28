import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../benchmark/benchmark_runner.dart';
import '../../shared/models/task.dart';
import '../../shared/repositories/task_repository.dart';
import '../../shared/services/fake_api_service.dart';
import '../../shared/utils/rebuild_counter.dart';
import '../blocs/task_list/task_list_bloc.dart';
import '../blocs/task_list/task_list_event.dart';
import '../blocs/task_list/task_list_state.dart';
import 'settings_screen.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';
import 'task_stats_screen.dart';

class MviTaskListScreen extends StatefulWidget {
  const MviTaskListScreen({
    super.key,
    required this.repository,
    required this.apiService,
    required this.onArchitectureChanged,
  });

  final TaskRepository repository;
  final FakeApiService apiService;
  final VoidCallback onArchitectureChanged;

  @override
  State<MviTaskListScreen> createState() => _MviTaskListScreenState();
}

class _MviTaskListScreenState extends State<MviTaskListScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    RebuildCounter.increment();
    return BlocProvider(
      create: (_) => TaskListBloc(
        repository: widget.repository,
        apiService: widget.apiService,
      )..add(const TaskListStarted()),
      child: Builder(
        builder: (context) {
          final pages = [
            _TaskListTab(repository: widget.repository, apiService: widget.apiService),
            const MviTaskStatsScreen(),
            const MviSettingsScreen(),
          ];
          return Scaffold(
            appBar: AppBar(
              title: const Text('Tarefas - MVI'),
              actions: [
                IconButton(
                  tooltip: 'Benchmark',
                  icon: const Icon(Icons.speed_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BenchmarkScreen()),
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.onArchitectureChanged,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('MVVM'),
                ),
              ],
            ),
            body: IndexedStack(index: _index, children: pages),
            floatingActionButton: _index == 0
                ? FloatingActionButton.extended(
                    onPressed: () => _createTask(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Nova'),
                  )
                : null,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.list_alt_outlined), label: 'Lista'),
                NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Estatisticas'),
                NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Ajustes'),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _createTask(BuildContext context) async {
    final bloc = context.read<TaskListBloc>();
    final created = await Navigator.of(context).push<Task>(
      MaterialPageRoute(builder: (_) => const MviTaskFormScreen()),
    );
    if (created != null) bloc.add(TaskCreated(created));
  }
}

class _TaskListTab extends StatelessWidget {
  const _TaskListTab({required this.repository, required this.apiService});

  final TaskRepository repository;
  final FakeApiService apiService;

  @override
  Widget build(BuildContext context) {
    RebuildCounter.increment();
    return BlocBuilder<TaskListBloc, TaskListState>(
      builder: (context, state) {
        final bloc = context.read<TaskListBloc>();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Buscar tarefas',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => bloc.add(TaskSearchChanged(value)),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<TaskFilter>(
                    selected: {state.filter},
                    onSelectionChanged: (value) => bloc.add(TaskFilterChanged(value.first)),
                    segments: const [
                      ButtonSegment(value: TaskFilter.all, label: Text('Todas')),
                      ButtonSegment(value: TaskFilter.pending, label: Text('Pendentes')),
                      ButtonSegment(value: TaskFilter.done, label: Text('Concluidas')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DropdownButton<TaskSort>(
                        value: state.sort,
                        onChanged: (value) {
                          if (value != null) bloc.add(TaskSortChanged(value));
                        },
                        items: const [
                          DropdownMenuItem(value: TaskSort.createdAtDesc, child: Text('Data')),
                          DropdownMenuItem(value: TaskSort.priorityDesc, child: Text('Prioridade')),
                        ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (state.isLoading) return const Center(child: CircularProgressIndicator());
                  if (state.visibleTasks.isEmpty) return const Center(child: Text('Nenhuma tarefa encontrada.'));
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: state.visibleTasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final task = state.visibleTasks[index];
                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: task.isDone,
                            onChanged: (_) => bloc.add(TaskToggled(task)),
                          ),
                          title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('Prioridade ${task.priority}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            final changed = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => MviTaskDetailScreen(
                                  taskId: task.id!,
                                  repository: repository,
                                  apiService: apiService,
                                ),
                              ),
                            );
                            if (changed == true && context.mounted) {
                              context.read<TaskListBloc>().add(const TaskListStarted(seedIfEmpty: false));
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
