import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../shared/models/task.dart';
import '../../shared/repositories/task_repository.dart';
import '../../shared/services/fake_api_service.dart';
import '../../shared/utils/rebuild_counter.dart';
import '../viewmodels/task_detail_viewmodel.dart';
import 'task_form_screen.dart';

class MvvmTaskDetailScreen extends StatelessWidget {
  const MvvmTaskDetailScreen({
    super.key,
    required this.taskId,
    required this.repository,
    required this.apiService,
  });

  final int taskId;
  final TaskRepository repository;
  final FakeApiService apiService;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaskDetailViewModel(repository: repository, apiService: apiService)..load(taskId),
      child: const _MvvmTaskDetailBody(),
    );
  }
}

class _MvvmTaskDetailBody extends StatelessWidget {
  const _MvvmTaskDetailBody();

  @override
  Widget build(BuildContext context) {
    RebuildCounter.increment();
    final vm = context.watch<TaskDetailViewModel>();
    final task = vm.task;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes'),
        actions: [
          if (task != null)
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(context, task),
            ),
        ],
      ),
      body: switch ((vm.isLoading, task)) {
        (true, _) => const Center(child: CircularProgressIndicator()),
        (_, null) => const Center(child: Text('Tarefa nao encontrada.')),
        (_, final Task task) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Icon(task.isDone ? Icons.check_circle : Icons.radio_button_unchecked),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(task.title, style: Theme.of(context).textTheme.headlineSmall),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(task.description.isEmpty ? 'Sem descricao.' : task.description),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('Prioridade ${task.priority}')),
                  Chip(label: Text(DateFormat('dd/MM/yyyy HH:mm').format(task.createdAt))),
                  Chip(label: Text(task.isDone ? 'Concluida' : 'Pendente')),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await context.read<TaskDetailViewModel>().toggleDone();
                  if (context.mounted) Navigator.of(context).pop(true);
                },
                icon: const Icon(Icons.done_outline),
                label: Text(task.isDone ? 'Marcar como pendente' : 'Marcar como concluida'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await context.read<TaskDetailViewModel>().delete();
                  if (context.mounted) Navigator.of(context).pop(true);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Excluir'),
              ),
            ],
          ),
      },
    );
  }

  Future<void> _edit(BuildContext context, Task task) async {
    final vm = context.read<TaskDetailViewModel>();
    final updated = await Navigator.of(context).push<Task>(
      MaterialPageRoute(builder: (_) => MvvmTaskFormScreen(task: task)),
    );
    if (updated == null) return;
    await vm.save(updated);
    if (context.mounted) Navigator.of(context).pop(true);
  }
}
