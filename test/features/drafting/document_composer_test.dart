import 'package:flutter_test/flutter_test.dart';
import 'package:legal_flow/features/drafting/domain/document_composer.dart';

// Cópia literal do código que existia em area_workspace_widget.dart antes da
// extração. É a referência de que a formatação colada no Word não mudou.
const _pStyle =
    "font-family: 'Calibri', sans-serif; font-size: 11pt; color: #000000; margin: 0 0 12pt 0; line-height: 1.15;";
const _boldStyle =
    "font-family: 'Calibri', sans-serif; font-size: 11pt; color: #000000; margin: 12pt 0 6pt 0; line-height: 1.15; font-weight: bold;";

String _legacyHtml(String enderecamento, String processo, String reu,
    String cliente, List<List<String>> topics) {
  String htmlContent = '''
      <div style="font-family: 'Calibri', sans-serif; font-size: 11pt; color: #000000; line-height: 1.15;">
        <p style="$_pStyle">EXCELENTÍSSIMO(A) SENHOR(A) DOUTOR(A) JUIZ(A) DE DIREITO $enderecamento.</p>
        <p style="$_pStyle">Processo nº. &nbsp; $processo</p>
        <p style="$_pStyle">$reu, por seus advogados e procuradores infra-assinados, nos autos da ação trabalhista em epígrafe, movida por $cliente, inconformada com a r. decisão proferida por este douto Juízo, vem, respeitosamente, à presença de Vossa Excelência, com fulcro no artigo 895, inciso I da Consolidação das Leis do Trabalho, interpor.</p>
    ''';

  if (topics.isEmpty) {
    htmlContent += '</div>';
    return htmlContent;
  }

  for (final topic in topics) {
    String topicTitle = topic[0].toUpperCase();
    List<String> paragraphs = topic[1].split('\n');
    String formattedParagraphs = paragraphs
        .where((p) => p.trim().isNotEmpty)
        .map((p) => '<p style="$_pStyle">${p.trim()}</p>')
        .join('');

    htmlContent += '''
          <p style="$_boldStyle"><b>$topicTitle</b></p>
          $formattedParagraphs
        ''';
  }

  htmlContent += '</div>';
  return htmlContent;
}

String _legacyPlain(String enderecamento, String processo, String reu,
    String cliente, List<List<String>> topics) {
  String documentHeader =
      '''EXCELENTÍSSIMO(A) SENHOR(A) DOUTOR(A) JUIZ(A) DE DIREITO $enderecamento.

Processo nº.   $processo

$reu, por seus advogados e procuradores infra-assinados, nos autos da ação trabalhista em epígrafe, movida por $cliente, inconformada com a r. decisão proferida por este douto Juízo, vem, respeitosamente, à presença de Vossa Excelência, com fulcro no artigo 895, inciso I da Consolidação das Leis do Trabalho, interpor.''';

  if (topics.isEmpty) {
    return '$documentHeader\n\n\n';
  }

  String fullDocument = documentHeader + '\n\n';
  for (final topic in topics) {
    fullDocument += '\n${topic[0].toUpperCase()}\n\n${topic[1]}\n';
  }
  return fullDocument.trim();
}

DocumentInput _laborInput(List<DocumentTopic> topics) => DocumentInput(
      headerTemplate: defaultHeaderForArea('Trabalhista'),
      topics: topics,
      enderecamento: 'DA 1ª VARA DO TRABALHO DE SÃO PAULO/SP',
      nomeCliente: 'João da Silva',
      cpf: '123.456.789-00',
      reu: 'Empresa Exemplo Ltda',
      processo: '0000000-00.2026.5.02.0001',
    );

void main() {
  const topics = [
    DocumentTopic(
      title: 'Das horas extras',
      content: 'Primeiro parágrafo.\n\n  Segundo parágrafo com espaços.  \nTerceiro.',
    ),
    DocumentTopic(title: 'Do pedido', content: 'Requer a procedência.'),
  ];
  final legacyTopics =
      topics.map((topic) => [topic.title, topic.content]).toList();

  const enderecamento = 'DA 1ª VARA DO TRABALHO DE SÃO PAULO/SP';
  const processo = '0000000-00.2026.5.02.0001';
  const reu = 'Empresa Exemplo Ltda';
  const cliente = 'João da Silva';

  group('formatação preservada em relação ao código original', () {
    test('HTML idêntico com tópicos', () {
      expect(
        composeHtml(_laborInput(topics)),
        _legacyHtml(enderecamento, processo, reu, cliente, legacyTopics),
      );
    });

    test('HTML idêntico sem tópicos', () {
      expect(
        composeHtml(_laborInput(const [])),
        _legacyHtml(enderecamento, processo, reu, cliente, const []),
      );
    });

    test('texto simples idêntico com e sem tópicos', () {
      expect(
        composePlainText(_laborInput(topics)),
        _legacyPlain(enderecamento, processo, reu, cliente, legacyTopics),
      );
      expect(
        composePlainText(_laborInput(const [])),
        _legacyPlain(enderecamento, processo, reu, cliente, const []),
      );
    });

    test('marcadores aparecem quando os campos estão vazios', () {
      final input = DocumentInput(
        headerTemplate: defaultHeaderForArea('Trabalhista'),
        topics: const [],
      );
      expect(
        composeHtml(input),
        _legacyHtml('[ENDEREÇAMENTO]', '[NÚMERO DO PROCESSO]',
            '[RÉU / DESTINATÁRIO]', '[NOME DO CLIENTE]', const []),
      );
    });

    test('estilo exigido para o Word continua no HTML', () {
      final html = composeHtml(_laborInput(topics));
      expect(html, contains("font-family: 'Calibri', sans-serif"));
      expect(html, contains('font-size: 11pt'));
      expect(html, contains('line-height: 1.15'));
      expect(html, contains('<b>DAS HORAS EXTRAS</b>'));
    });
  });

  group('prévia', () {
    test('tem o mesmo texto do documento e marca os títulos', () {
      final spans = composeSpans(_laborInput(topics));
      expect(spans.where((span) => span.isTitle).map((span) => span.text.trim()),
          ['DAS HORAS EXTRAS', 'DO PEDIDO']);
      final header = _legacyPlain(enderecamento, processo, reu, cliente, const []).trim();
      expect(
        spans.map((span) => span.text).join(),
        '$header\n'
        '\nDAS HORAS EXTRAS\n${topics[0].content}\n'
        '\nDO PEDIDO\n${topics[1].content}\n',
      );
    });
  });

  group('cabeçalho por área', () {
    test('só a área trabalhista cita a CLT por padrão', () {
      expect(defaultHeaderForArea('Trabalhista'), contains('Consolidação das Leis do Trabalho'));
      for (final area in ['Civil', 'Penal', 'Previdenciário', 'Tributário', 'Empresarial', 'Contratos', '']) {
        expect(defaultHeaderForArea(area), isNot(contains('Consolidação das Leis do Trabalho')), reason: area);
        expect(defaultHeaderForArea(area), isNot(contains('trabalhista')), reason: area);
      }
    });

    test('modelo próprio da peça substitui o padrão e aceita variáveis', () {
      const input = DocumentInput(
        headerTemplate: 'AO JUÍZO {{ENDEREÇAMENTO}}\n\nCliente: {{TESTEMUNHA}}',
        topics: [],
        enderecamento: 'CRIMINAL',
        customVariables: {'TESTEMUNHA': 'Maria'},
      );
      expect(composePlainText(input), startsWith('AO JUÍZO CRIMINAL\n\nCliente: Maria'));
    });
  });

  group('variáveis', () {
    test('extrai nomes sem repetição e sem espaços', () {
      expect(extractVariables('{{A}} {{ B }} {{A}} texto'), ['A', 'B']);
    });

    test('aceita os nomes alternativos', () {
      const input = DocumentInput(headerTemplate: '', topics: [], nomeCliente: 'Ana', reu: 'Beta');
      expect(applyVariables('{{nome_cliente}} x {{reu_destinatario}}', input), 'Ana x Beta');
    });

    test('variável sem valor continua visível no texto', () {
      const input = DocumentInput(headerTemplate: '', topics: []);
      expect(applyVariables('{{DATA_AUDIENCIA}}', input), '{{DATA_AUDIENCIA}}');
    });

    test('valor digitado não dispara outra substituição', () {
      const input = DocumentInput(headerTemplate: '', topics: [], nomeCliente: '{{REU}}', reu: 'Beta');
      expect(applyVariables('{{NOME_CLIENTE}}', input), '{{REU}}');
    });

    test('aceita espaços dentro das chaves', () {
      const input = DocumentInput(
        headerTemplate: '',
        topics: [],
        customVariables: {'VALOR': '10'},
      );
      expect(applyVariables('{{ VALOR }}', input), '10');
    });
  });

  group('escape do HTML', () {
    test('marcação digitada vira texto em todo o documento', () {
      const input = DocumentInput(
        headerTemplate: '{{NOME_CLIENTE}}',
        nomeCliente: 'Silva & Souza <script>',
        topics: [DocumentTopic(title: 'a<b', content: 'valor < 10 & mais')],
      );
      final html = composeHtml(input);
      expect(html, contains('Silva &amp; Souza &lt;script&gt;'));
      expect(html, contains('<b>A&lt;B</b>'));
      expect(html, contains('valor &lt; 10 &amp; mais'));
      expect(html, isNot(contains('<script>')));
    });

    test('texto simples e prévia não recebem escape', () {
      const input = DocumentInput(
        headerTemplate: 'R&D <ok>',
        topics: [DocumentTopic(title: 'T', content: 'a < b')],
      );
      expect(composePlainText(input), contains('R&D <ok>'));
      expect(composeSpans(input).map((span) => span.text).join(), contains('a < b'));
    });
  });

  test('documento do Word contém o HTML da peça', () {
    final input = _laborInput(topics);
    final word = composeWordDocument(input);
    expect(word, contains(composeHtml(input)));
    expect(word, contains("xmlns:w='urn:schemas-microsoft-com:office:word'"));
    expect(word, contains("<meta charset='utf-8'>"));
  });

  test('prévia do tópico corta em 40 caracteres', () {
    expect(topicPreview('curto'), 'curto');
    expect(topicPreview('a' * 41), '${'a' * 40}...');
  });
}
