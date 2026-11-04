class PecaItem {
  const PecaItem({required this.name, this.headerTemplate});

  final String name;

  /// Nulo quando a peça usa o cabeçalho padrão da área.
  final String? headerTemplate;
}

class TopicItem {
  const TopicItem({
    required this.id,
    required this.pecaName,
    required this.title,
    required this.content,
    required this.preview,
    required this.variables,
  });

  final int id;
  final String pecaName;
  final String title;
  final String content;
  final String preview;
  final List<String> variables;
}

class AreaLibrary {
  const AreaLibrary({required this.pecas, required this.topics});

  final List<PecaItem> pecas;
  final List<TopicItem> topics;
}
