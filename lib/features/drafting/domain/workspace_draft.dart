import 'dart:convert';

/// Trabalho em andamento na tela de montagem. Fica só na sessão do navegador,
/// para sobreviver a um F5 sem levar dados do cliente para o banco.
class WorkspaceDraft {
  const WorkspaceDraft({
    this.peca,
    this.topicIds = const [],
    this.enderecamento = '',
    this.nomeCliente = '',
    this.cpf = '',
    this.reu = '',
    this.processo = '',
    this.customVariables = const {},
  });

  final String? peca;
  final List<int> topicIds;
  final String enderecamento;
  final String nomeCliente;
  final String cpf;
  final String reu;
  final String processo;
  final Map<String, String> customVariables;

  /// Sem nada digitado ou selecionado não há trabalho a proteger.
  bool get isEmpty =>
      topicIds.isEmpty &&
      [enderecamento, nomeCliente, cpf, reu, processo, ...customVariables.values]
          .every((value) => value.trim().isEmpty);

  String encode() => jsonEncode({
        'peca': peca,
        'topicIds': topicIds,
        'enderecamento': enderecamento,
        'nomeCliente': nomeCliente,
        'cpf': cpf,
        'reu': reu,
        'processo': processo,
        'customVariables': customVariables,
      });

  /// Retorna null quando o conteúdo salvo não pode ser lido.
  static WorkspaceDraft? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return WorkspaceDraft(
        peca: data['peca'] as String?,
        topicIds: (data['topicIds'] as List? ?? const []).cast<int>(),
        enderecamento: data['enderecamento'] as String? ?? '',
        nomeCliente: data['nomeCliente'] as String? ?? '',
        cpf: data['cpf'] as String? ?? '',
        reu: data['reu'] as String? ?? '',
        processo: data['processo'] as String? ?? '',
        customVariables:
            (data['customVariables'] as Map? ?? const {}).cast<String, String>(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Cada conta e cada área têm o próprio rascunho.
String workspaceDraftKey(String userId, String area) => '$userId.$area';
