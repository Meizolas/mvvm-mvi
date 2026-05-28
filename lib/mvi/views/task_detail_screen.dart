import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../shared/models/task.dart';
import '../../shared/repositories/task_repository.dart';
import '../../shared/services/fake_api_service.dart';
import '../../shared/utils/rebuild_counter.dart';
import '../blocs/task_detail/task_detail_bloc.dart';
import '../blocs/task_detail/task_detail_event.dart';
import '../blocs/task_detail/task_detail_state.dart';
import 'task_form_screen.dart';

class MviTaskDetailScreen extends StatelessWidget {
  const MviTaskDetailScreen({
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
    return BlocProvider(
      create: (_) => TaskDetailBloc(repository: repository, apiService: apiService)..add(TaskDetailStarted(taskId)),
      child: _MviTaskDetailBody(repository: repository),
    );
  }
}

class _MviTaskDetailBody extends StatelessWidget {
  const _MviTaskDetailBody({required this.repository});

  final TaskRepository repository;

  @override
  Widget build(BuildContext context) {
    RebuildCounter.increment();
    return BlocListener<TaskDetailBloc, TaskDetailState>(
      listenWhen: (previous, current) => previous.deleted != current.deleted,
      listener: (context, state) {
        if (state.deleted) Navigator.of(context).pop(true);
      },
      child: BlocBuilder<TaskDetailBloc, TaskDetailState>(
        builder: (context, state) {
          final task = state.task;
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
            body: switch ((state.isLoading, task)) {
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
                        final bloc = context.read<TaskDetailBloc>()..add(const TaskDetailToggled());
                        await bloc.stream.first;
                        if (context.mounted) Navigator.of(context).pop(true);
                      },
                      icon: const Icon(Icons.done_outline),
                      label: Text(task.isDone ? 'Marcar como pendente' : 'Marcar como concluida'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => context.read<TaskDetailBloc>().add(const TaskDetailDeleted()),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Excluir'),
                    ),
                  ],
                ),
            },
          );
        },
      ),
    );
  }

  Future<void> _edit(BuildContext context, Task task) async {
    final updated = await Navigator.of(context).push<Task>(
      MaterialPageRoute(builder: (_) => MviTaskFormScreen(task: task)),
    );
    if (updated == null) return;
    await repository.updateTask(updated);
    if (context.mounted) Navigator.of(context).pop(true);
  }
}
