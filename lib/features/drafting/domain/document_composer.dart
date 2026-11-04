/// Monta a peça a partir do cabeçalho, dos tópicos e dos dados informados.
///
/// Este arquivo não depende de Flutter nem de Supabase: texto simples, HTML e
/// prévia saem da mesma composição, para que nunca fiquem diferentes entre si.
library;

class DocumentTopic {
  const DocumentTopic({required this.title, required this.content});

  final String title;
  final String content;
}

class DocumentInput {
  const DocumentInput({
    required this.headerTemplate,
    required this.topics,
    this.enderecamento = '',
    this.nomeCliente = '',
    this.cpf = '',
    this.reu = '',
    this.processo = '',
    this.customVariables = const {},
  });

  final String headerTemplate;
  final List<DocumentTopic> topics;
  final String enderecamento;
  final String nomeCliente;
  final String cpf;
  final String reu;
  final String processo;
  final Map<String, String> customVariables;
}

class DocumentSpan {
  const DocumentSpan(this.text, {this.isTitle = false});

  final String text;
  final bool isTitle;
}

/// Variáveis com campo fixo na tela, incluindo os nomes alternativos aceitos.
const List<String> standardVariableNames = [
  'NOME_CLIENTE', 'nome_cliente',
  'CPF', 'cpf',
  'REU', 'reu_destinatario',
  'PROCESSO', 'numero_processo',
  'ENDEREÇAMENTO', 'endereçamento',
];

const String _laborAppealHeader =
    'EXCELENTÍSSIMO(A) SENHOR(A) DOUTOR(A) JUIZ(A) DE DIREITO {{ENDEREÇAMENTO}}.\n\n'
    'Processo nº.   {{PROCESSO}}\n\n'
    '{{REU}}, por seus advogados e procuradores infra-assinados, nos autos da ação trabalhista em epígrafe, movida por {{NOME_CLIENTE}}, inconformada com a r. decisão proferida por este douto Juízo, vem, respeitosamente, à presença de Vossa Excelência, com fulcro no artigo 895, inciso I da Consolidação das Leis do Trabalho, interpor.';

const String _neutralCourtHeader =
    'EXCELENTÍSSIMO(A) SENHOR(A) DOUTOR(A) JUIZ(A) DE DIREITO {{ENDEREÇAMENTO}}.\n\n'
    'Processo nº.   {{PROCESSO}}\n\n'
    '{{NOME_CLIENTE}}, por seus advogados e procuradores infra-assinados, em face de {{REU}}, vem, respeitosamente, à presença de Vossa Excelência, expor e requerer o que segue.';

const String _contractHeader =
    'Pelo presente instrumento particular, de um lado {{NOME_CLIENTE}}, inscrito(a) no CPF sob o nº {{CPF}}, e de outro {{REU}}, têm entre si justo e acordado o que segue.';

/// Cabeçalho usado quando a peça ainda não tem um modelo próprio salvo.
String defaultHeaderForArea(String area) {
  switch (area) {
    case 'Trabalhista':
      return _laborAppealHeader;
    case 'Contratos':
      return _contractHeader;
    default:
      return _neutralCourtHeader;
  }
}

final RegExp _variablePattern = RegExp(r'\{\{(.*?)\}\}');

/// Nomes das variáveis `{{NOME}}` de um texto, sem repetição.
List<String> extractVariables(String text) => _variablePattern
    .allMatches(text)
    .map((match) => match.group(1)!.trim())
    .toSet()
    .toList();

String _orPlaceholder(String value, String placeholder) =>
    value.isNotEmpty ? value : placeholder;

/// Substitui as variáveis em uma única passada: um valor digitado que contenha
/// `{{OUTRA}}` é mantido como texto e não é substituído de novo.
String applyVariables(String text, DocumentInput input) {
  final values = <String, String>{
    'NOME_CLIENTE': _orPlaceholder(input.nomeCliente, '[NOME DO CLIENTE]'),
    'nome_cliente': _orPlaceholder(input.nomeCliente, '[NOME DO CLIENTE]'),
    'CPF': _orPlaceholder(input.cpf, '[CPF]'),
    'cpf': _orPlaceholder(input.cpf, '[CPF]'),
    'REU': _orPlaceholder(input.reu, '[RÉU / DESTINATÁRIO]'),
    'reu_destinatario': _orPlaceholder(input.reu, '[RÉU / DESTINATÁRIO]'),
    'PROCESSO': _orPlaceholder(input.processo, '[NÚMERO DO PROCESSO]'),
    'numero_processo': _orPlaceholder(input.processo, '[NÚMERO DO PROCESSO]'),
    'ENDEREÇAMENTO': _orPlaceholder(input.enderecamento, '[ENDEREÇAMENTO]'),
    'endereçamento': _orPlaceholder(input.enderecamento, '[ENDEREÇAMENTO]'),
  };

  return text.replaceAllMapped(_variablePattern, (match) {
    final key = match.group(1)!.trim();
    final standard = values[key];
    if (standard != null) return standard;
    final custom = input.customVariables[key];
    return custom != null && custom.isNotEmpty ? custom : match.group(0)!;
  });
}

String _composeHeader(DocumentInput input) =>
    applyVariables(input.headerTemplate, input);

String composePlainText(DocumentInput input) {
  final header = _composeHeader(input);
  if (input.topics.isEmpty) return '$header\n\n\n';

  final document = StringBuffer('$header\n\n');
  for (final topic in input.topics) {
    document.write(
      '\n${topic.title.toUpperCase()}\n\n${applyVariables(topic.content, input)}\n',
    );
  }
  return document.toString().trim();
}

List<DocumentSpan> composeSpans(DocumentInput input) {
  final spans = <DocumentSpan>[DocumentSpan('${_composeHeader(input)}\n')];
  for (final topic in input.topics) {
    spans.add(DocumentSpan('\n${topic.title.toUpperCase()}\n', isTitle: true));
    spans.add(DocumentSpan('${applyVariables(topic.content, input)}\n'));
  }
  return spans;
}

const String _paragraphStyle =
    "font-family: 'Calibri', sans-serif; font-size: 11pt; color: #000000; margin: 0 0 12pt 0; line-height: 1.15;";
const String _titleStyle =
    "font-family: 'Calibri', sans-serif; font-size: 11pt; color: #000000; margin: 12pt 0 6pt 0; line-height: 1.15; font-weight: bold;";

/// O texto vem do usuário e é tratado como texto, nunca como marcação.
String escapeHtml(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

/// HTML com parágrafos formais, mantendo Calibri 11pt ao colar no Word e no
/// Google Docs. Mudanças aqui precisam continuar passando em
/// test/features/drafting/document_composer_test.dart.
String composeHtml(DocumentInput input) {
  final html = StringBuffer(
    '''      <div style="font-family: 'Calibri', sans-serif; font-size: 11pt; color: #000000; line-height: 1.15;">\n''',
  );

  final headerParagraphs = _composeHeader(input)
      .split(RegExp(r'\n\s*\n'))
      .where((paragraph) => paragraph.trim().isNotEmpty);
  for (final paragraph in headerParagraphs) {
    final text = escapeHtml(paragraph.trim()).replaceAll('   ', ' &nbsp; ');
    html.write('        <p style="$_paragraphStyle">$text</p>\n');
  }
  html.write('    ');

  for (final topic in input.topics) {
    final title = escapeHtml(topic.title.toUpperCase());
    final paragraphs = applyVariables(topic.content, input)
        .split('\n')
        .where((paragraph) => paragraph.trim().isNotEmpty)
        .map((paragraph) =>
            '<p style="$_paragraphStyle">${escapeHtml(paragraph.trim())}</p>')
        .join('');

    html.write('          <p style="$_titleStyle"><b>$title</b></p>\n');
    html.write('          $paragraphs\n');
    html.write('        ');
  }

  html.write('</div>');
  return html.toString();
}

/// Arquivo que o Word abre como documento, gerado a partir do mesmo HTML.
String composeWordDocument(DocumentInput input) => '''
      <html xmlns:o='urn:schemas-microsoft-com:office:office' xmlns:w='urn:schemas-microsoft-com:office:word' xmlns='http://www.w3.org/TR/REC-html40'>
      <head><meta charset='utf-8'></head>
      <body>${composeHtml(input)}</body>
      </html>
    ''';

/// Texto curto mostrado no cartão do tópico.
String topicPreview(String content) =>
    content.length > 40 ? '${content.substring(0, 40)}...' : content;
