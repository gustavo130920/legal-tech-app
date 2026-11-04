import 'package:flutter/foundation.dart';

import '/app_state.dart';
import '/features/drafting/domain/document_composer.dart';
import '/features/drafting/domain/workspace_draft.dart';
import '/features/library/data/library_repository.dart';
import '/features/library/domain/library_models.dart';
import '/platform/browser_session.dart' as browser;

/// Onde o rascunho da sessão fica guardado.
abstract class DraftStore {
  String? read(String key);
  void write(String key, String content);
  void remove(String key);
  void setLeaveGuard(bool enabled);
}

class BrowserDraftStore implements DraftStore {
  const BrowserDraftStore();

  @override
  String? read(String key) => browser.readDraft(key);

  @override
  void write(String key, String content) => browser.writeDraft(key, content);

  @override
  void remove(String key) => browser.removeDraft(key);

  @override
  void setLeaveGuard(bool enabled) => browser.setLeaveGuard(enabled);
}

enum ClientField { enderecamento, nomeCliente, cpf, reu, processo }

/// Regras da tela de montagem, sem depender de widgets.
class WorkspaceViewModel extends ChangeNotifier {
  WorkspaceViewModel({
    required LibraryRepository repository,
    required this.area,
    required String? Function() currentUserId,
    DraftStore drafts = const BrowserDraftStore(),
  })  : _repository = repository,
        _currentUserId = currentUserId,
        _drafts = drafts;

  final LibraryRepository _repository;
  final String? Function() _currentUserId;
  final DraftStore _drafts;
  final String area;

  List<PecaItem> _pecas = const [];
  List<TopicItem> _topics = const [];
  List<TopicKit> _kits = const [];
  String? _selectedPeca;
  final List<int> _selectedTopicIds = [];
  final Map<ClientField, String> _fields = {};
  final Map<String, String> _customValues = {};
  String _searchQuery = '';
  bool _isLoading = false;
  bool _draftReady = false;
  bool _disposed = false;

  List<PecaItem> get pecas => _pecas;
  String? get selectedPeca => _selectedPeca;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  List<int> get selectedTopicIds => List.unmodifiable(_selectedTopicIds);

  String fieldValue(ClientField field) => _fields[field] ?? '';
  String customValue(String name) => _customValues[name] ?? '';

  List<TopicItem> get topicsOfSelectedPeca =>
      _topics.where((topic) => topic.pecaName == _selectedPeca).toList();

  List<TopicKit> get kitsOfSelectedPeca =>
      _kits.where((kit) => kit.pecaName == _selectedPeca).toList();

  /// Tópicos do kit que ainda existem nesta peça.
  int availableTopicsInKit(TopicKit kit) {
    final idsOfPeca = topicsOfSelectedPeca.map((topic) => topic.id).toSet();
    return kit.topicIds.where(idsOfPeca.contains).length;
  }

  /// Tópicos da peça que combinam com a busca, por título ou conteúdo.
  List<TopicItem> get visibleTopics {
    final query = _normalize(_searchQuery);
    if (query.isEmpty) return topicsOfSelectedPeca;
    return topicsOfSelectedPeca
        .where((topic) =>
            _normalize(topic.title).contains(query) ||
            _normalize(topic.content).contains(query))
        .toList();
  }

  /// Tópicos selecionados, na ordem em que entram no documento.
  List<TopicItem> get selectedTopics {
    final byId = {for (final topic in _topics) topic.id: topic};
    return [
      for (final id in _selectedTopicIds)
        if (byId[id] != null) byId[id]!,
    ];
  }

  String get currentHeaderTemplate {
    for (final peca in _pecas) {
      if (peca.name == _selectedPeca) {
        final saved = peca.headerTemplate;
        if (saved != null && saved.trim().isNotEmpty) return saved;
      }
    }
    return defaultHeaderForArea(area);
  }

  String headerTemplateFor(String pecaName) {
    for (final peca in _pecas) {
      if (peca.name == pecaName && peca.headerTemplate != null) return peca.headerTemplate!;
    }
    return defaultHeaderForArea(area);
  }

  /// Variáveis próprias usadas no documento, que precisam de um campo na tela.
  List<String> get customVariableNames {
    final names = <String>{...extractVariables(currentHeaderTemplate)};
    for (final topic in selectedTopics) {
      names.addAll(topic.variables);
    }
    names.removeWhere(standardVariableNames.contains);
    return names.toList();
  }

  DocumentInput get documentInput => DocumentInput(
        headerTemplate: currentHeaderTemplate,
        topics: selectedTopics
            .map((topic) => DocumentTopic(title: topic.title, content: topic.content))
            .toList(),
        enderecamento: fieldValue(ClientField.enderecamento),
        nomeCliente: fieldValue(ClientField.nomeCliente),
        cpf: fieldValue(ClientField.cpf),
        reu: fieldValue(ClientField.reu),
        processo: fieldValue(ClientField.processo),
        customVariables: Map.unmodifiable(_customValues),
      );

  List<String> get pendingFields => findPendingFields(documentInput);

  /// Carrega a biblioteca. Resposta de uma sessão anterior é descartada, para
  /// nunca entrar na memória da conta atual. Retorna false nesse caso.
  Future<bool> load() async {
    final userId = _currentUserId();
    if (userId == null) return false;

    _isLoading = true;
    _notify();

    try {
      final library = await _repository.loadArea(userId: userId, area: area);
      if (_disposed || _currentUserId() != userId) return false;

      _pecas = library.pecas;
      _topics = library.topics;
      _kits = library.kits;

      final names = _pecas.map((peca) => peca.name).toList();
      if (!names.contains(_selectedPeca)) {
        _selectedPeca = names.isNotEmpty ? names.first : null;
      }
      final validIds = _topics.map((topic) => topic.id).toSet();
      _selectedTopicIds.removeWhere((id) => !validIds.contains(id));
      _pruneCustomValues();
      _syncSharedMemory();
      return true;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Restaura o rascunho desta sessão e passa a gravá-lo. Retorna true se havia
  /// trabalho a recuperar.
  bool restoreDraft() {
    final userId = _currentUserId();
    final draft = userId == null
        ? null
        : WorkspaceDraft.decode(_drafts.read(workspaceDraftKey(userId, area)));

    var restored = false;
    if (draft != null && !draft.isEmpty) {
      if (_pecas.any((peca) => peca.name == draft.peca)) _selectedPeca = draft.peca;

      final idsOfPeca = topicsOfSelectedPeca.map((topic) => topic.id).toSet();
      _selectedTopicIds
        ..clear()
        ..addAll(draft.topicIds.where(idsOfPeca.contains));
      _fields[ClientField.enderecamento] = draft.enderecamento;
      _fields[ClientField.nomeCliente] = draft.nomeCliente;
      _fields[ClientField.cpf] = draft.cpf;
      _fields[ClientField.reu] = draft.reu;
      _fields[ClientField.processo] = draft.processo;
      _customValues
        ..clear()
        ..addAll(draft.customVariables);
      _pruneCustomValues();
      restored = true;
    }

    _draftReady = true;
    _syncSharedMemory();
    _saveDraft();
    _notify();
    return restored;
  }

  void setField(ClientField field, String value) {
    if (fieldValue(field) == value) return;
    _fields[field] = value;
    _saveDraft();
    _notify();
  }

  void setCustomValue(String name, String value) {
    if (customValue(name) == value) return;
    _customValues[name] = value;
    _saveDraft();
    _notify();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _notify();
  }

  void selectPeca(String name) {
    if (_selectedPeca == name) return;
    _selectedPeca = name;
    _selectedTopicIds.clear();
    _searchQuery = '';
    _pruneCustomValues();
    _syncSharedMemory();
    _saveDraft();
    _notify();
  }

  void toggleTopic(int id) {
    if (!_selectedTopicIds.remove(id)) _selectedTopicIds.add(id);
    _pruneCustomValues();
    _saveDraft();
    _notify();
  }

  /// Recebe os índices como o ReorderableListView os entrega: ao mover para
  /// baixo, o destino ainda conta o item que está saindo.
  void moveSelectedTopic(int oldIndex, int newIndex) {
    final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    if (target == oldIndex) return;
    final id = _selectedTopicIds.removeAt(oldIndex);
    _selectedTopicIds.insert(target, id);
    _saveDraft();
    _notify();
  }

  /// Troca a seleção pelos tópicos do kit, na ordem salva. Retorna quantos
  /// tópicos do kit não existem mais.
  int applyKit(TopicKit kit) {
    final idsOfPeca = topicsOfSelectedPeca.map((topic) => topic.id).toSet();
    final available = kit.topicIds.where(idsOfPeca.contains).toList();
    _selectedTopicIds
      ..clear()
      ..addAll(available);
    _pruneCustomValues();
    _saveDraft();
    _notify();
    return kit.topicIds.length - available.length;
  }

  Future<void> saveSelectionAsKit(String rawName) async {
    final userId = _currentUserId();
    final name = rawName.trim();
    final peca = _selectedPeca;
    if (userId == null || peca == null || name.isEmpty || _selectedTopicIds.isEmpty) return;

    final kit = await _repository.createKit(
      userId: userId,
      area: area,
      pecaName: peca,
      name: name,
      topicIds: List.of(_selectedTopicIds),
    );
    _kits = [..._kits, kit]..sort((a, b) => a.name.compareTo(b.name));
    _notify();
  }

  Future<void> deleteKit(int id) async {
    await _repository.deleteKit(id);
    _kits = _kits.where((kit) => kit.id != id).toList();
    _notify();
  }

  void clearClientData() {
    _fields.clear();
    _customValues.clear();
    _selectedTopicIds.clear();
    _saveDraft();
    _notify();
  }

  Future<void> createPeca(String rawName) async {
    final userId = _currentUserId();
    final name = rawName.trim().toUpperCase();
    if (userId == null || name.isEmpty) return;

    await _repository.createPeca(userId: userId, area: area, name: name);
    _pecas = [..._pecas, PecaItem(name: name)];
    _selectedPeca = name;
    _selectedTopicIds.clear();
    _pruneCustomValues();
    _syncSharedMemory();
    _saveDraft();
    _notify();
  }

  /// Guardar o texto padrão faria a peça não receber correções futuras dele.
  Future<void> updatePeca({
    required String oldName,
    required String rawName,
    required String rawHeader,
  }) async {
    final userId = _currentUserId();
    final newName = rawName.trim().toUpperCase();
    final headerText = rawHeader.trim();
    final header = headerText.isEmpty || headerText == defaultHeaderForArea(area) ? null : headerText;
    if (userId == null || newName.isEmpty) return;

    final current = _pecas.where((peca) => peca.name == oldName);
    final unchanged = newName == oldName && current.isNotEmpty && current.first.headerTemplate == header;
    if (unchanged) return;

    await _repository.updatePeca(
      userId: userId,
      area: area,
      oldName: oldName,
      newName: newName,
      headerTemplate: header,
    );

    _pecas = [
      for (final peca in _pecas)
        peca.name == oldName ? PecaItem(name: newName, headerTemplate: header) : peca,
    ];
    if (newName != oldName) {
      _topics = [
        for (final topic in _topics)
          topic.pecaName == oldName
              ? TopicItem(
                  id: topic.id,
                  pecaName: newName,
                  title: topic.title,
                  content: topic.content,
                  preview: topic.preview,
                  variables: topic.variables,
                )
              : topic,
      ];
      _kits = [
        for (final kit in _kits)
          kit.pecaName == oldName
              ? TopicKit(id: kit.id, pecaName: newName, name: kit.name, topicIds: kit.topicIds)
              : kit,
      ];
      if (_selectedPeca == oldName) _selectedPeca = newName;
    }
    _pruneCustomValues();
    _syncSharedMemory();
    _saveDraft();
    _notify();
  }

  Future<void> deletePeca(String name) async {
    final userId = _currentUserId();
    if (userId == null) return;

    await _repository.deletePeca(userId: userId, area: area, name: name);
    _pecas = _pecas.where((peca) => peca.name != name).toList();
    _topics = _topics.where((topic) => topic.pecaName != name).toList();
    _kits = _kits.where((kit) => kit.pecaName != name).toList();
    if (_selectedPeca == name) {
      _selectedPeca = _pecas.isNotEmpty ? _pecas.first.name : null;
      _selectedTopicIds.clear();
    }
    _pruneCustomValues();
    _syncSharedMemory();
    _saveDraft();
    _notify();
  }

  Future<void> updateTopic({
    required int id,
    required String rawTitle,
    required String rawContent,
  }) async {
    final title = rawTitle.trim();
    final content = rawContent.trim();
    if (title.isEmpty || content.isEmpty) return;

    final preview = topicPreview(content);
    final variables = extractVariables(content);
    await _repository.updateTopic(
      id: id,
      title: title,
      content: content,
      preview: preview,
      variables: variables,
    );

    _topics = [
      for (final topic in _topics)
        topic.id == id
            ? TopicItem(
                id: id,
                pecaName: topic.pecaName,
                title: title,
                content: content,
                preview: preview,
                variables: variables,
              )
            : topic,
    ];
    _pruneCustomValues();
    _syncSharedMemory();
    _saveDraft();
    _notify();
  }

  Future<void> deleteTopic(int id) async {
    await _repository.deleteTopic(id);
    _topics = _topics.where((topic) => topic.id != id).toList();
    _selectedTopicIds.remove(id);
    _pruneCustomValues();
    _syncSharedMemory();
    _saveDraft();
    _notify();
  }

  void _pruneCustomValues() {
    final needed = customVariableNames.toSet();
    _customValues.removeWhere((name, _) => !needed.contains(name));
  }

  // O menu e a tela de novo tópico ainda leem esta memória compartilhada.
  void _syncSharedMemory() {
    final shared = globalAreaDatabase[area];
    if (shared == null) return;
    shared['pecas'] = _pecas.map((peca) => peca.name).toList();
    shared['topics'] = <Map<String, dynamic>>[
      for (final topic in _topics)
        {
          'id': topic.id,
          'title': topic.title,
          'content': topic.content,
          'preview': topic.preview,
          'variables': topic.variables,
          'peca': topic.pecaName,
        },
    ];
    globalSelectedPeca = _selectedPeca;
  }

  void _saveDraft() {
    final userId = _currentUserId();
    if (!_draftReady || userId == null) return;

    final key = workspaceDraftKey(userId, area);
    final draft = WorkspaceDraft(
      peca: _selectedPeca,
      topicIds: List.of(_selectedTopicIds),
      enderecamento: fieldValue(ClientField.enderecamento),
      nomeCliente: fieldValue(ClientField.nomeCliente),
      cpf: fieldValue(ClientField.cpf),
      reu: fieldValue(ClientField.reu),
      processo: fieldValue(ClientField.processo),
      customVariables: Map.of(_customValues),
    );

    if (draft.isEmpty) {
      _drafts.remove(key);
      _drafts.setLeaveGuard(false);
    } else {
      _drafts.write(key, draft.encode());
      _drafts.setLeaveGuard(true);
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _drafts.setLeaveGuard(false);
    super.dispose();
  }
}

const Map<String, String> _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c',
};

String _normalize(String text) {
  final lower = text.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString();
}
