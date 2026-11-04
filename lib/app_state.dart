import 'package:flutter/services.dart';


String globalCurrentArea = '';
String? globalSelectedPeca;
Set<String> globalSavedAreas = {};

final Map<String, dynamic> globalAreaDatabase = {
  'Trabalhista': {
    'title': 'Área Trabalhista',
    'pecas': <String>[],
    'topics': <Map<String, dynamic>>[]
  },
  'Civil': {
    'title': 'Área Civil',
    'pecas': <String>[],
    'topics': <Map<String, dynamic>>[]
  },
  'Previdenciário': {
    'title': 'Área Previdenciária',
    'pecas': <String>[],
    'topics': <Map<String, dynamic>>[]
  },
  'Penal': {
    'title': 'Área Penal',
    'pecas': <String>[],
    'topics': <Map<String, dynamic>>[]
  },
  'Tributário': {
    'title': 'Área Tributária',
    'pecas': <String>[],
    'topics': <Map<String, dynamic>>[]
  },
  'Empresarial': {
    'title': 'Área Empresarial',
    'pecas': <String>[],
    'topics': <Map<String, dynamic>>[]
  },
  'Contratos': {
    'title': 'Elaboração de Contratos',
    'pecas': <String>[],
    'topics': <Map<String, dynamic>>[]
  }
};

/// Apaga da memória os dados do usuário para evitar vazamento entre contas.
void clearSessionMemory() {
  globalCurrentArea = '';
  globalSelectedPeca = null;
  globalSavedAreas = {};
  globalAreaDatabase.forEach((key, value) {
    value['pecas'] = <String>[];
    value['topics'] = <Map<String, dynamic>>[];
  });
}

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 11) text = text.substring(0, 11);

    var formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) formatted += '.';
      else if (i == 9) formatted += '-';
      formatted += text[i];
    }
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

class ProcessoInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 20) text = text.substring(0, 20);

    var formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 7) formatted += '-';
      else if (i == 9 || i == 13 || i == 14 || i == 16) formatted += '.';
      formatted += text[i];
    }
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}