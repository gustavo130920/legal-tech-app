import 'package:flutter_test/flutter_test.dart';
import 'package:legal_flow/core/legal/cnj_number.dart';

void main() {
  test('vazio e incompleto não são tratados como erro de dígito', () {
    expect(checkCnjNumber('').status, CnjStatus.empty);
    expect(checkCnjNumber('0000001-68').status, CnjStatus.incomplete);
  });

  test('aceita número válido e identifica ramo e tribunal', () {
    final state = checkCnjNumber('0000001-68.2026.8.26.0100');
    expect(state.status, CnjStatus.valid);
    expect(state.description, 'Justiça Estadual · TJSP');

    final labor = checkCnjNumber('1234567-03.2025.5.02.0001');
    expect(labor.status, CnjStatus.valid);
    expect(labor.description, 'Justiça do Trabalho · TRT-2');
  });

  test('identifica os tribunais estaduais pelo código oficial', () {
    String numberFor(String court) {
      final base = '1234567' '2025' '8$court' '0001';
      final digit = 98 - (BigInt.parse('${base}00') % BigInt.from(97)).toInt();
      return '1234567${digit.toString().padLeft(2, '0')}20258${court}0001';
    }

    const expected = {
      '01': 'TJAC', '07': 'TJDFT', '13': 'TJMG', '19': 'TJRJ',
      '21': 'TJRS', '24': 'TJSC', '25': 'TJSE', '26': 'TJSP', '27': 'TJTO',
    };
    expected.forEach((code, court) {
      expect(checkCnjNumber(numberFor(code)).description, 'Justiça Estadual · $court');
    });
  });

  test('aceita o número sem máscara', () {
    expect(checkCnjNumber('12345670320255020001').status, CnjStatus.valid);
  });

  test('recusa dígito verificador errado', () {
    expect(checkCnjNumber('1234567-04.2025.5.02.0001').status, CnjStatus.invalid);
  });

  test('recusa um dígito trocado no número', () {
    expect(checkCnjNumber('1234568-03.2025.5.02.0001').status, CnjStatus.invalid);
  });

  test('recusa ramo inexistente mesmo com dígito coerente', () {
    const base = '1234567' '2025' '0' '02' '0001';
    final digit = 98 - (BigInt.parse('${base}00') % BigInt.from(97)).toInt();
    final number = '1234567${digit.toString().padLeft(2, '0')}20250020001';
    expect(checkCnjNumber(number).status, CnjStatus.invalid);
  });

  test('ramo válido sem tabela de tribunal mostra só o ramo', () {
    const base = '1234567' '2025' '6' '26' '0001';
    final digit = 98 - (BigInt.parse('${base}00') % BigInt.from(97)).toInt();
    final number = '1234567${digit.toString().padLeft(2, '0')}20256260001';
    expect(checkCnjNumber(number).description, 'Justiça Eleitoral');
  });
}
