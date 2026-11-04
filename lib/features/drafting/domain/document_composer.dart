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
  const DocumentSpan(this.text, {this.isTitle = false, this.isPending = false});

  final String text;
  final bool isTitle;

  /// Trecho que ainda depende de um campo não preenchido.
  final bool isPending;
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

const Map<String, String> _standardPlaceholders = {
  'NOME_CLIENTE': '[NOME DO CLIENTE]',
  'nome_cliente': '[NOME DO CLIENTE]',
  'CPF': '[CPF]',
  'cpf': '[CPF]',
  'REU': '[RÉU / DESTINATÁRIO]',
  'reu_destinatario': '[RÉU / DESTINATÁRIO]',
  'PROCESSO': '[NÚMERO DO PROCESSO]',
  'numero_processo': '[NÚMERO DO PROCESSO]',
  'ENDEREÇAMENTO': '[ENDEREÇAMENTO]',
  'endereçamento': '[ENDEREÇAMENTO]',
};

const Map<String, String> _standardLabels = {
  'NOME_CLIENTE': 'Nome do cliente',
  'nome_cliente': 'Nome do cliente',
  'CPF': 'CPF',
  'cpf': 'CPF',
  'REU': 'Réu / destinatário',
  'reu_destinatario': 'Réu / destinatário',
  'PROCESSO': 'Número do processo',
  'numero_processo': 'Número do processo',
  'ENDEREÇAMENTO': 'Endereçamento',
  'endereçamento': 'Endereçamento',
};

/// Nome legível de uma variável: `DATA_CONTRATO` vira `Data contrato`.
String variableLabel(String key) {
  final standard = _standardLabels[key];
  if (standard != null) return standard;
  final words = key.replaceAll('_', ' ').trim().toLowerCase();
  if (words.isEmpty) return key;
  return words[0].toUpperCase() + words.substring(1);
}

String _standardValue(String key, DocumentInput input) {
  switch (key) {
    case 'NOME_CLIENTE':
    case 'nome_cliente':
      return input.nomeCliente;
    case 'CPF':
    case 'cpf':
      return input.cpf;
    case 'REU':
    case 'reu_destinatario':
      return input.reu;
    case 'PROCESSO':
    case 'numero_processo':
      return input.processo;
    default:
      return input.enderecamento;
  }
}

/// Valor preenchido para a variável, ou null quando ainda está pendente.
String? _filledValue(String key, DocumentInput input) {
  final value = _standardPlaceholders.containsKey(key)
      ? _standardValue(key, input)
      : input.customVariables[key];
  return value != null && value.trim().isNotEmpty ? value : null;
}

/// Como uma variável pendente aparece no documento.
String _pendingText(String key, String original) =>
    _standardPlaceholders[key] ?? original;

/// Substitui as variáveis em uma única passada: um valor digitado que contenha
/// `{{OUTRA}}` é mantido como texto e não é substituído de novo.
String applyVariables(String text, DocumentInput input) =>
    text.replaceAllMapped(_variablePattern, (match) {
      final key = match.group(1)!.trim();
      return _filledValue(key, input) ?? _pendingText(key, match.group(0)!);
    });

/// Campos usados no documento que ainda não foram preenchidos, sem repetição
/// e na ordem em que aparecem.
List<String> findPendingFields(DocumentInput input) {
  final texts = [input.headerTemplate, ...input.topics.map((topic) => topic.content)];
  final pending = <String>{};
  for (final text in texts) {
    for (final key in extractVariables(text)) {
      if (_filledValue(key, input) == null) pending.add(variableLabel(key));
    }
  }
  return pending.toList();
}

/// Divide o texto em trechos, separando o que depende de campo pendente.
List<DocumentSpan> _splitPending(String text, DocumentInput input) {
  final spans = <DocumentSpan>[];
  var position = 0;
  var filled = StringBuffer();

  for (final match in _variablePattern.allMatches(text)) {
    filled.write(text.substring(position, match.start));
    position = match.end;

    final key = match.group(1)!.trim();
    final value = _filledValue(key, input);
    if (value != null) {
      filled.write(value);
    } else {
      if (filled.isNotEmpty) spans.add(DocumentSpan(filled.toString()));
      filled = StringBuffer();
      spans.add(DocumentSpan(_pendingText(key, match.group(0)!), isPending: true));
    }
  }

  filled.write(text.substring(position));
  if (filled.isNotEmpty) spans.add(DocumentSpan(filled.toString()));
  return spans;
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
  final spans = <DocumentSpan>[
    ..._splitPending(input.headerTemplate, input),
    const DocumentSpan('\n'),
  ];
  for (final topic in input.topics) {
    spans.add(DocumentSpan('\n${topic.title.toUpperCase()}\n', isTitle: true));
    spans.addAll(_splitPending(topic.content, input));
    spans.add(const DocumentSpan('\n'));
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
