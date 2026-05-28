import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../benchmark/benchmark_runner.dart';
import '../../shared/models/task.dart';
import '../../shared/repositories/task_repository.dart';
import '../../shared/services/fake_api_service.dart';
import '../../shared/utils/rebuild_counter.dart';
import '../viewmodels/task_list_viewmodel.dart';
import 'settings_screen.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';
import 'task_stats_screen.dart';

class MvvmTaskListScreen extends StatefulWidget {
  const MvvmTaskListScreen({
    super.key,
    required this.repository,
    required this.apiService,
    required this.onArchitectureChanged,
  });

  final TaskRepository repository;
  final FakeApiService apiService;
  final VoidCallback onArchitectureChanged;

  @override
  State<MvvmTaskListScreen> createState() => _MvvmTaskListScreenState();
}

class _MvvmTaskListScreenState extends State<MvvmTaskListScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    RebuildCounter.increment();
    return ChangeNotifierProvider(
      create: (_) => TaskListViewModel(
        repository: widget.repository,
        apiService: widget.apiService,
      )..load(),
      child: Builder(
        builder: (context) {
          final pages = [
            _TaskListTab(repository: widget.repository, apiService: widget.apiService),
            const MvvmTaskStatsScreen(),
            const MvvmSettingsScreen(),
          ];
          return Scaffold(
            appBar: AppBar(
              title: const Text('Tarefas - MVVM'),
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
                  label: const Text('MVI'),
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
    final vm = context.read<TaskListViewModel>();
    final created = await Navigator.of(context).push<Task>(
      MaterialPageRoute(builder: (_) => const MvvmTaskFormScreen()),
    );
    if (created != null) await vm.saveTask(created);
  }
}

class _TaskListTab extends StatelessWidget {
  const _TaskListTab({required this.repository, required this.apiService});

  final TaskRepository repository;
  final FakeApiService apiService;

  @override
  Widget build(BuildContext context) {
    RebuildCounter.increment();
    final vm = context.watch<TaskListViewModel>();
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
                onChanged: vm.setSearch,
              ),
              const SizedBox(height: 8),
              SegmentedButton<TaskFilter>(
                selected: {vm.filter},
                onSelectionChanged: (value) => vm.setFilter(value.first),
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
                    value: vm.sort,
                    onChanged: (value) {
                      if (value != null) vm.setSort(value);
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
              if (vm.isLoading) return const Center(child: CircularProgressIndicator());
              if (vm.visibleTasks.isEmpty) return const Center(child: Text('Nenhuma tarefa encontrada.'));
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: vm.visibleTasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final task = vm.visibleTasks[index];
                  return Card(
                    child: ListTile(
                      leading: Checkbox(
                        value: task.isDone,
                        onChanged: (_) => vm.toggleDone(task),
                      ),
                      title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('Prioridade ${task.priority}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => MvvmTaskDetailScreen(
                              taskId: task.id!,
                              repository: repository,
                              apiService: apiService,
                            ),
                          ),
                        );
                        if (changed == true && context.mounted) {
                          await context.read<TaskListViewModel>().load(seedIfEmpty: false);
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
  }
}
