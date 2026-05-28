import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/utils/rebuild_counter.dart';
import '../blocs/task_list/task_list_bloc.dart';
import '../blocs/task_list/task_list_state.dart';

class MviTaskStatsScreen extends StatelessWidget {
  const MviTaskStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    RebuildCounter.increment();
    return BlocBuilder<TaskListBloc, TaskListState>(
      builder: (context, state) {
        final total = state.total == 0 ? 1 : state.total;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Estatisticas', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricCard(label: 'Total', value: '${state.total}', icon: Icons.list_alt_outlined),
                _MetricCard(label: 'Concluidas', value: '${state.done}', icon: Icons.check_circle_outline),
                _MetricCard(label: 'Pendentes', value: '${state.pending}', icon: Icons.pending_actions_outlined),
                _MetricCard(label: 'Prioridade media', value: state.averagePriority.toStringAsFixed(1), icon: Icons.trending_up),
              ],
            ),
            const SizedBox(height: 24),
            Text('Distribuicao', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _Bar(label: 'Concluidas', value: state.done / total, color: Colors.green),
            _Bar(label: 'Pendentes', value: state.pending / total, color: Colors.orange),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(value, style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: value, color: color, minHeight: 12),
        ],
      ),
    );
  }
}
