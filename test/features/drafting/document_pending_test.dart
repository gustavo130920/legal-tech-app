import 'package:flutter_test/flutter_test.dart';
import 'package:legal_flow/features/drafting/domain/document_composer.dart';
import 'package:legal_flow/features/drafting/domain/workspace_draft.dart';

void main() {
  group('campos pendentes', () {
    const template = 'Ao juízo {{ENDEREÇAMENTO}}, {{NOME_CLIENTE}}.';

    test('lista só o que o documento usa', () {
      const input = DocumentInput(
        headerTemplate: template,
        topics: [DocumentTopic(title: 'T', content: 'Em {{DATA_CONTRATO}}.')],
      );
      expect(findPendingFields(input), ['Endereçamento', 'Nome do cliente', 'Data contrato']);
    });

    test('campo fora do documento não é pendência', () {
      const input = DocumentInput(
        headerTemplate: 'Texto {{NOME_CLIENTE}}',
        topics: [],
        nomeCliente: 'Ana',
      );
      expect(findPendingFields(input), isEmpty);
    });

    test('nomes alternativos contam como um só campo', () {
      const input = DocumentInput(headerTemplate: '{{CPF}} {{cpf}}', topics: []);
      expect(findPendingFields(input), ['CPF']);
    });

    test('só espaços continua pendente', () {
      const input = DocumentInput(
        headerTemplate: '{{NOME_CLIENTE}} {{VALOR}}',
        topics: [],
        nomeCliente: '   ',
        customVariables: {'VALOR': ' '},
      );
      expect(findPendingFields(input), ['Nome do cliente', 'Valor']);
      expect(applyVariables('{{NOME_CLIENTE}}', input), '[NOME DO CLIENTE]');
    });

    test('documento completo não tem pendências', () {
      const input = DocumentInput(
        headerTemplate: template,
        topics: [DocumentTopic(title: 'T', content: '{{VALOR}}')],
        enderecamento: 'X',
        nomeCliente: 'Ana',
        customVariables: {'VALOR': '10'},
      );
      expect(findPendingFields(input), isEmpty);
    });
  });

  group('prévia marca as pendências', () {
    test('separa o trecho pendente sem mudar o texto', () {
      const input = DocumentInput(
        headerTemplate: 'Cliente {{NOME_CLIENTE}} em {{DATA}} fim',
        topics: [],
        customVariables: {'DATA': '01/01'},
      );
      final spans = composeSpans(input);
      expect(spans.where((span) => span.isPending).map((span) => span.text), ['[NOME DO CLIENTE]']);
      expect(spans.map((span) => span.text).join(), 'Cliente [NOME DO CLIENTE] em 01/01 fim\n');
    });

    test('variável própria pendente continua visível', () {
      const input = DocumentInput(
        headerTemplate: '',
        topics: [DocumentTopic(title: 'T', content: 'Em {{DATA_X}}.')],
      );
      expect(composeSpans(input).where((span) => span.isPending).single.text, '{{DATA_X}}');
    });
  });

  test('rótulo de variável própria fica legível', () {
    expect(variableLabel('DATA_CONTRATO'), 'Data contrato');
    expect(variableLabel('status'), 'Status');
    expect(variableLabel('reu_destinatario'), 'Réu / destinatário');
  });

  group('rascunho da sessão', () {
    test('mantém os dados ao salvar e ler', () {
      const draft = WorkspaceDraft(
        peca: 'PEÇA',
        topicIds: [1, 2],
        enderecamento: 'E',
        nomeCliente: 'Ana',
        cpf: '1',
        reu: 'R',
        processo: 'P',
        customVariables: {'VALOR': '10'},
      );
      final read = WorkspaceDraft.decode(draft.encode())!;
      expect(read.peca, 'PEÇA');
      expect(read.topicIds, [1, 2]);
      expect(read.nomeCliente, 'Ana');
      expect(read.customVariables, {'VALOR': '10'});
      expect(read.isEmpty, isFalse);
    });

    test('conteúdo inválido é ignorado', () {
      expect(WorkspaceDraft.decode(null), isNull);
      expect(WorkspaceDraft.decode('não é json'), isNull);
      expect(WorkspaceDraft.decode('{"topicIds":"x"}'), isNull);
    });

    test('sem nada digitado ou selecionado está vazio', () {
      expect(const WorkspaceDraft(peca: 'PEÇA', nomeCliente: '  ').isEmpty, isTrue);
      expect(const WorkspaceDraft(topicIds: [1]).isEmpty, isFalse);
    });

    test('cada conta e área têm chave própria', () {
      expect(workspaceDraftKey('a', 'Civil'), isNot(workspaceDraftKey('b', 'Civil')));
      expect(workspaceDraftKey('a', 'Civil'), isNot(workspaceDraftKey('a', 'Penal')));
    });
  });
}
