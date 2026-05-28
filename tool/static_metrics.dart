import 'dart:io';

void main() {
  final rows = <List<Object>>[
    ['arquitetura', 'metrica', 'valor'],
    ..._metricsFor('mvvm', Directory('lib/mvvm'), {
      'linhas_viewmodels': Directory('lib/mvvm/viewmodels'),
      'linhas_views': Directory('lib/mvvm/views'),
    }),
    ..._metricsFor('mvi', Directory('lib/mvi'), {
      'linhas_blocs': Directory('lib/mvi/blocs'),
      'linhas_views': Directory('lib/mvi/views'),
    }),
  ];

  for (final row in rows) {
    stdout.writeln(row.join(','));
  }
}

List<List<Object>> _metricsFor(
  String architecture,
  Directory root,
  Map<String, Directory> layerDirs,
) {
  final files = _dartFiles(root);
  final lines = files.fold<int>(0, (total, file) => total + _lineCount(file));
  final classes = files.fold<int>(0, (total, file) => total + _classCount(file));
  final rows = <List<Object>>[
    [architecture, 'total_linhas', lines],
    [architecture, 'num_classes', classes],
    [architecture, 'num_arquivos', files.length],
  ];

  for (final entry in layerDirs.entries) {
    final layerLines = _dartFiles(entry.value).fold<int>(0, (total, file) => total + _lineCount(file));
    rows.add([architecture, entry.key, layerLines]);
  }
  return rows;
}

List<File> _dartFiles(Directory directory) {
  if (!directory.existsSync()) return [];
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

int _lineCount(File file) => file.readAsLinesSync().length;

int _classCount(File file) {
  final content = file.readAsStringSync();
  return RegExp(r'\b(class|abstract class)\s+\w+').allMatches(content).length;
}
