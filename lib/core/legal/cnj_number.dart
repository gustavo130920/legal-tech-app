enum CnjStatus { empty, incomplete, invalid, valid }

class CnjCheck {
  const CnjCheck(this.status, {this.description});

  final CnjStatus status;

  /// Ramo e tribunal, quando o número é válido. Ex: Justiça do Trabalho · TRT-2.
  final String? description;
}

const Map<String, String> _branches = {
  '1': 'Supremo Tribunal Federal',
  '2': 'Conselho Nacional de Justiça',
  '3': 'Superior Tribunal de Justiça',
  '4': 'Justiça Federal',
  '5': 'Justiça do Trabalho',
  '6': 'Justiça Eleitoral',
  '7': 'Justiça Militar da União',
  '8': 'Justiça Estadual',
  '9': 'Justiça Militar Estadual',
};

const List<String> _stateCourts = [
  'TJAC', 'TJAL', 'TJAP', 'TJAM', 'TJBA', 'TJCE', 'TJDFT', 'TJES', 'TJGO',
  'TJMA', 'TJMT', 'TJMS', 'TJMG', 'TJPA', 'TJPB', 'TJPR', 'TJPE', 'TJPI',
  'TJRJ', 'TJRN', 'TJRS', 'TJRO', 'TJRR', 'TJSC', 'TJSE', 'TJSP', 'TJTO',
];

String? _courtName(String branch, int region) {
  if (branch == '4' && region >= 1 && region <= 6) return 'TRF-$region';
  if (branch == '5' && region >= 1 && region <= 24) return 'TRT-$region';
  if (branch == '8' && region >= 1 && region <= _stateCourts.length) {
    return _stateCourts[region - 1];
  }
  return null;
}

/// Confere o número no padrão CNJ (NNNNNNN-DD.AAAA.J.TR.OOOO) pelo dígito
/// verificador. Isso detecta erro de digitação, mas não prova que o processo
/// existe.
CnjCheck checkCnjNumber(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return const CnjCheck(CnjStatus.empty);
  if (digits.length < 20) return const CnjCheck(CnjStatus.incomplete);
  if (digits.length > 20) return const CnjCheck(CnjStatus.invalid);

  final informed = digits.substring(7, 9);
  final base = digits.substring(0, 7) + digits.substring(9);
  final calculated = 98 - (BigInt.parse('${base}00') % BigInt.from(97)).toInt();
  if (calculated.toString().padLeft(2, '0') != informed) {
    return const CnjCheck(CnjStatus.invalid);
  }

  final branchCode = digits[13];
  final branch = _branches[branchCode];
  if (branch == null) return const CnjCheck(CnjStatus.invalid);

  final court = _courtName(branchCode, int.parse(digits.substring(14, 16)));
  return CnjCheck(
    CnjStatus.valid,
    description: court == null ? branch : '$branch · $court',
  );
}
