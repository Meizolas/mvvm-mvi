import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/utils/rebuild_counter.dart';
import '../../shared/utils/theme_controller.dart';
import '../viewmodels/task_list_viewmodel.dart';

class MvvmSettingsScreen extends StatelessWidget {
  const MvvmSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    RebuildCounter.increment();
    final theme = context.watch<ThemeController>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Configuracoes', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Tema escuro'),
          secondary: const Icon(Icons.dark_mode_outlined),
          value: theme.isDark,
          onChanged: theme.setDark,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.cloud_sync_outlined),
          title: const Text('Sincronizar com API fake'),
          onTap: () => context.read<TaskListViewModel>().syncFromApi(),
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Limpar dados'),
          onTap: () => context.read<TaskListViewModel>().clearAll(),
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('MVVM vs MVI Tasks'),
          subtitle: Text('Projeto academico UNEX - Flutter Web, Material 3 e benchmark automatizado.'),
        ),
      ],
    );
  }
}
