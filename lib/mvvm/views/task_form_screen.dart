import 'package:flutter/material.dart';

import '../../shared/models/task.dart';
import '../../shared/utils/rebuild_counter.dart';

class MvvmTaskFormScreen extends StatefulWidget {
  const MvvmTaskFormScreen({
    super.key,
    this.task,
  });

  final Task? task;

  @override
  State<MvvmTaskFormScreen> createState() => _MvvmTaskFormScreenState();
}

class _MvvmTaskFormScreenState extends State<MvvmTaskFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late int _priority;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _priority = task?.priority ?? 3;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    RebuildCounter.increment();
    final isEditing = widget.task != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar tarefa' : 'Nova tarefa')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Titulo', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Descricao', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Text('Prioridade: $_priority', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _priority.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$_priority',
            onChanged: (value) => setState(() => _priority = value.round()),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final base = widget.task;
    Navigator.of(context).pop(
      Task(
        id: base?.id,
        title: title,
        description: _descriptionController.text.trim(),
        isDone: base?.isDone ?? false,
        createdAt: base?.createdAt ?? DateTime.now(),
        priority: _priority,
      ),
    );
  }
}
