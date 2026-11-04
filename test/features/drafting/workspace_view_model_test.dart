import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:legal_flow/app_state.dart';
import 'package:legal_flow/features/drafting/ui/workspace_view_model.dart';
import 'package:legal_flow/features/library/data/library_repository.dart';
import 'package:legal_flow/features/library/domain/library_models.dart';

class FakeRepository implements LibraryRepository {
  AreaLibrary library = const AreaLibrary(pecas: [], topics: []);
  Completer<AreaLibrary>? pendingLoad;
  final calls = <String>[];
  bool failNext = false;

  void _maybeFail() {
    if (failNext) {
      failNext = false;
      throw Exception('falha');
    }
  }

  @override
  Future<AreaLibrary> loadArea({required String userId, required String area}) async {
    calls.add('load:$userId:$area');
    _maybeFail();
    final pending = pendingLoad;
    if (pending != null) return await pending.future;
    return library;
  }

  @override
  Future<void> createPeca({required String userId, required String area, required String name}) async {
    _maybeFail();
    calls.add('createPeca:$name');
  }

  @override
  Future<void> updatePeca({
    required String userId,
    required String area,
    required String oldName,
    required String newName,
    required String? headerTemplate,
  }) async {
    _maybeFail();
    calls.add('updatePeca:$oldName>$newName:$headerTemplate');
  }

  @override
  Future<void> deletePeca({required String userId, required String area, required String name}) async {
    _maybeFail();
    calls.add('deletePeca:$name');
  }

  @override
  Future<void> updateTopic({
    required int id,
    required String title,
    required String content,
    required String preview,
    required List<String> variables,
  }) async {
    _maybeFail();
    calls.add('updateTopic:$id:$variables');
  }

  @override
  Future<void> deleteTopic(int id) async {
    _maybeFail();
    calls.add('deleteTopic:$id');
  }
}

class FakeDraftStore implements DraftStore {
  final data = <String, String>{};
  bool guard = false;

  @override
  String? read(String key) => data[key];

  @override
  void write(String key, String content) => data[key] = content;

  @override
  void remove(String key) => data.remove(key);

  @override
  void setLeaveGuard(bool enabled) => guard = enabled;
}

TopicItem topic(int id, String peca, String title, {String? content, List<String> variables = const []}) =>
    TopicItem(
      id: id,
      pecaName: peca,
      title: title,
      content: content ?? 'Texto $id',
      preview: 'Texto $id',
      variables: variables,
    );

void main() {
  late FakeRepository repository;
  late FakeDraftStore drafts;
  String? userId;

  WorkspaceViewModel build() => WorkspaceViewModel(
        repository: repository,
        area: 'Civil',
        currentUserId: () => userId,
        drafts: drafts,
      );

  setUp(() {
    userId = 'conta-a';
    drafts = FakeDraftStore();
    repository = FakeRepository()
      ..library = AreaLibrary(
        pecas: const [PecaItem(name: 'PEÇA 1'), PecaItem(name: 'PEÇA 2', headerTemplate: 'Cabeçalho {{COMARCA}}')],
        topics: [
          topic(1, 'PEÇA 1', 'Dos fatos', content: 'Texto com {{DATA}}', variables: const ['DATA']),
          topic(2, 'PEÇA 1', 'Do direito', content: 'Indenização por dano'),
          topic(3, 'PEÇA 1', 'Do pedido'),
          topic(4, 'PEÇA 2', 'Outro'),
        ],
      );
  });

  tearDown(clearSessionMemory);

  group('carregamento', () {
    test('seleciona a primeira peça e atualiza a memória compartilhada', () async {
      final vm = build();
      expect(await vm.load(), isTrue);
      expect(vm.selectedPeca, 'PEÇA 1');
      expect(vm.topicsOfSelectedPeca.map((t) => t.id), [1, 2, 3]);
      expect(globalAreaDatabase['Civil']['pecas'], ['PEÇA 1', 'PEÇA 2']);
      expect(globalAreaDatabase['Civil']['topics'], hasLength(4));
    });

    test('resposta que chega depois da troca de conta é descartada', () async {
      final vm = build();
      repository.pendingLoad = Completer();
      final loading = vm.load();

      userId = 'conta-b';
      clearSessionMemory();
      repository.pendingLoad!.complete(repository.library);

      expect(await loading, isFalse);
      expect(vm.pecas, isEmpty);
      expect(globalAreaDatabase['Civil']['pecas'], isEmpty);
      expect(globalAreaDatabase['Civil']['topics'], isEmpty);
    });

    test('resposta que chega depois da saída é descartada', () async {
      final vm = build();
      repository.pendingLoad = Completer();
      final loading = vm.load();

      userId = null;
      clearSessionMemory();
      repository.pendingLoad!.complete(repository.library);

      expect(await loading, isFalse);
      expect(globalAreaDatabase['Civil']['pecas'], isEmpty);
    });

    test('resposta que chega depois de sair da tela é descartada', () async {
      final vm = build();
      repository.pendingLoad = Completer();
      final loading = vm.load();

      vm.dispose();
      repository.pendingLoad!.complete(repository.library);

      expect(await loading, isFalse);
      expect(globalAreaDatabase['Civil']['pecas'], isEmpty);
    });

    test('sem sessão não consulta o banco', () async {
      userId = null;
      expect(await build().load(), isFalse);
      expect(repository.calls, isEmpty);
    });

    test('falha no carregamento encerra o estado de carga', () async {
      final vm = build();
      repository.failNext = true;
      await expectLater(vm.load(), throwsException);
      expect(vm.isLoading, isFalse);
    });
  });

  group('ordem dos tópicos', () {
    test('segue a ordem de seleção e entra assim no documento', () async {
      final vm = build();
      await vm.load();
      vm.toggleTopic(3);
      vm.toggleTopic(1);
      expect(vm.selectedTopics.map((t) => t.id), [3, 1]);
      expect(vm.documentInput.topics.map((t) => t.title), ['Do pedido', 'Dos fatos']);
    });

    test('move para cima e para baixo com os índices da lista', () async {
      final vm = build();
      await vm.load();
      [1, 2, 3].forEach(vm.toggleTopic);

      vm.moveSelectedTopic(0, 3);
      expect(vm.selectedTopicIds, [2, 3, 1]);

      vm.moveSelectedTopic(2, 0);
      expect(vm.selectedTopicIds, [1, 2, 3]);

      vm.moveSelectedTopic(1, 2);
      expect(vm.selectedTopicIds, [1, 2, 3]);
    });

    test('desmarcar remove do documento', () async {
      final vm = build();
      await vm.load();
      vm.toggleTopic(1);
      vm.toggleTopic(1);
      expect(vm.selectedTopics, isEmpty);
    });

    test('trocar de peça limpa a seleção e a busca', () async {
      final vm = build();
      await vm.load();
      vm.toggleTopic(1);
      vm.setSearchQuery('pedido');
      vm.selectPeca('PEÇA 2');
      expect(vm.selectedTopics, isEmpty);
      expect(vm.searchQuery, isEmpty);
      expect(vm.topicsOfSelectedPeca.map((t) => t.id), [4]);
    });
  });

  group('busca', () {
    test('encontra por título e conteúdo, sem diferenciar acentos', () async {
      final vm = build();
      await vm.load();

      vm.setSearchQuery('PEDIDO');
      expect(vm.visibleTopics.map((t) => t.id), [3]);

      vm.setSearchQuery('indenizacao');
      expect(vm.visibleTopics.map((t) => t.id), [2]);

      vm.setSearchQuery('não existe');
      expect(vm.visibleTopics, isEmpty);

      vm.setSearchQuery('');
      expect(vm.visibleTopics, hasLength(3));
    });

    test('não busca em outras peças', () async {
      final vm = build();
      await vm.load();
      vm.setSearchQuery('outro');
      expect(vm.visibleTopics, isEmpty);
    });

    test('filtrar não altera os tópicos selecionados', () async {
      final vm = build();
      await vm.load();
      vm.toggleTopic(1);
      vm.setSearchQuery('pedido');
      expect(vm.selectedTopics.map((t) => t.id), [1]);
    });
  });

  group('variáveis e documento', () {
    test('lista variáveis próprias do cabeçalho e dos tópicos', () async {
      final vm = build();
      await vm.load();
      expect(vm.customVariableNames, isEmpty);
      vm.toggleTopic(1);
      expect(vm.customVariableNames, ['DATA']);
      vm.selectPeca('PEÇA 2');
      expect(vm.customVariableNames, ['COMARCA']);
    });

    test('valor sai do documento quando a variável deixa de ser usada', () async {
      final vm = build();
      await vm.load();
      vm.toggleTopic(1);
      vm.setCustomValue('DATA', '01/01');
      expect(vm.documentInput.customVariables, {'DATA': '01/01'});
      vm.toggleTopic(1);
      expect(vm.documentInput.customVariables, isEmpty);
    });

    test('usa o cabeçalho salvo ou o padrão da área', () async {
      final vm = build();
      await vm.load();
      expect(vm.currentHeaderTemplate, isNot(contains('Consolidação')));
      vm.selectPeca('PEÇA 2');
      expect(vm.currentHeaderTemplate, 'Cabeçalho {{COMARCA}}');
    });

    test('pendências acompanham o preenchimento', () async {
      final vm = build();
      await vm.load();
      vm.selectPeca('PEÇA 2');
      expect(vm.pendingFields, ['Comarca']);
      vm.setCustomValue('COMARCA', 'Santos');
      expect(vm.pendingFields, isEmpty);
    });
  });

  group('alterações na biblioteca', () {
    test('cria peça em maiúsculas e seleciona', () async {
      final vm = build();
      await vm.load();
      await vm.createPeca('  nova peça ');
      expect(repository.calls, contains('createPeca:NOVA PEÇA'));
      expect(vm.selectedPeca, 'NOVA PEÇA');
      expect(globalAreaDatabase['Civil']['pecas'], contains('NOVA PEÇA'));
    });

    test('renomear mantém os tópicos e a seleção da peça', () async {
      final vm = build();
      await vm.load();
      await vm.updatePeca(oldName: 'PEÇA 1', rawName: 'novo nome', rawHeader: '');
      expect(vm.selectedPeca, 'NOVO NOME');
      expect(vm.topicsOfSelectedPeca, hasLength(3));
    });

    test('cabeçalho padrão não é gravado como personalizado', () async {
      final vm = build();
      await vm.load();
      await vm.updatePeca(oldName: 'PEÇA 1', rawName: 'PEÇA 1', rawHeader: vm.currentHeaderTemplate);
      expect(repository.calls.where((call) => call.startsWith('updatePeca')), isEmpty);
    });

    test('cabeçalho próprio é gravado', () async {
      final vm = build();
      await vm.load();
      await vm.updatePeca(oldName: 'PEÇA 1', rawName: 'PEÇA 1', rawHeader: 'Novo {{X}}');
      expect(repository.calls, contains('updatePeca:PEÇA 1>PEÇA 1:Novo {{X}}'));
      expect(vm.customVariableNames, ['X']);
    });

    test('excluir peça remove os tópicos e seleciona a próxima', () async {
      final vm = build();
      await vm.load();
      vm.toggleTopic(1);
      await vm.deletePeca('PEÇA 1');
      expect(vm.selectedPeca, 'PEÇA 2');
      expect(vm.selectedTopics, isEmpty);
      expect(globalAreaDatabase['Civil']['topics'], hasLength(1));
    });

    test('falha ao excluir mantém a biblioteca', () async {
      final vm = build();
      await vm.load();
      repository.failNext = true;
      await expectLater(vm.deletePeca('PEÇA 1'), throwsException);
      expect(vm.pecas, hasLength(2));
    });

    test('editar tópico recalcula variáveis e prévia', () async {
      final vm = build();
      await vm.load();
      vm.toggleTopic(2);
      await vm.updateTopic(id: 2, rawTitle: ' Título ', rawContent: 'Valor {{VALOR}}');
      expect(repository.calls, contains('updateTopic:2:[VALOR]'));
      expect(vm.selectedTopics.single.title, 'Título');
      expect(vm.customVariableNames, ['VALOR']);
    });

    test('excluir tópico tira da seleção', () async {
      final vm = build();
      await vm.load();
      vm.toggleTopic(1);
      await vm.deleteTopic(1);
      expect(vm.selectedTopics, isEmpty);
      expect(vm.topicsOfSelectedPeca.map((t) => t.id), [2, 3]);
    });
  });

  group('rascunho da sessão', () {
    test('não grava antes de restaurar', () async {
      final vm = build();
      await vm.load();
      vm.setField(ClientField.nomeCliente, 'Ana');
      expect(drafts.data, isEmpty);
    });

    test('recupera dados, peça e ordem dos tópicos', () async {
      final first = build();
      await first.load();
      first.restoreDraft();
      first.selectPeca('PEÇA 1');
      first.toggleTopic(3);
      first.toggleTopic(1);
      first.setField(ClientField.nomeCliente, 'Ana');
      first.setCustomValue('DATA', '01/01');
      expect(drafts.guard, isTrue);

      final second = build();
      await second.load();
      expect(second.restoreDraft(), isTrue);
      expect(second.selectedTopicIds, [3, 1]);
      expect(second.fieldValue(ClientField.nomeCliente), 'Ana');
      expect(second.customValue('DATA'), '01/01');
    });

    test('ignora tópico que não existe mais', () async {
      final first = build();
      await first.load();
      first.restoreDraft();
      first.toggleTopic(1);
      first.toggleTopic(2);

      repository.library = AreaLibrary(
        pecas: repository.library.pecas,
        topics: repository.library.topics.where((t) => t.id != 1).toList(),
      );
      final second = build();
      await second.load();
      second.restoreDraft();
      expect(second.selectedTopicIds, [2]);
    });

    test('rascunho de uma conta não aparece em outra', () async {
      final first = build();
      await first.load();
      first.restoreDraft();
      first.setField(ClientField.nomeCliente, 'Cliente da conta A');

      userId = 'conta-b';
      final second = build();
      await second.load();
      expect(second.restoreDraft(), isFalse);
      expect(second.fieldValue(ClientField.nomeCliente), isEmpty);
    });

    test('limpar remove rascunho e aviso de saída', () async {
      final vm = build();
      await vm.load();
      vm.restoreDraft();
      vm.toggleTopic(1);
      vm.setField(ClientField.cpf, '1');
      vm.clearClientData();
      expect(vm.selectedTopics, isEmpty);
      expect(vm.fieldValue(ClientField.cpf), isEmpty);
      expect(drafts.data, isEmpty);
      expect(drafts.guard, isFalse);
    });

    test('sair da tela desliga o aviso de saída', () async {
      final vm = build();
      await vm.load();
      vm.restoreDraft();
      vm.setField(ClientField.cpf, '1');
      vm.dispose();
      expect(drafts.guard, isFalse);
      expect(drafts.data, isNotEmpty);
    });
  });
}
