import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../shared/utils/rebuild_counter.dart';
import '../../shared/utils/theme_controller.dart';
import '../blocs/task_list/task_list_bloc.dart';
import '../blocs/task_list/task_list_event.dart';

class MviSettingsScreen extends StatelessWidget {
  const MviSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    RebuildCounter.increment();
    final theme = Provider.of<ThemeController>(context);
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
          onTap: () => BlocProvider.of<TaskListBloc>(context).add(const TaskListSyncedFromApi()),
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Limpar dados'),
          onTap: () => BlocProvider.of<TaskListBloc>(context).add(const TaskListCleared()),
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
