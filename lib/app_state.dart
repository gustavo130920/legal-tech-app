import 'package:flutter/services.dart';


String globalCurrentArea = 'Trabalhista';
Set<String> globalSavedAreas = {};

final Map<String, dynamic> globalAreaDatabase = {
  'Trabalhista': {
    'title': 'Área Trabalhista',
    'pecas': ['PETIÇÃO INICIAL TRABALHISTA'],
    'topics': <Map<String, dynamic>>[]
  },
  'Civil': {
    'title': 'Área Civil',
    'pecas': ['PETIÇÃO INICIAL CÍVEL'],
    'topics': <Map<String, dynamic>>[]
  },
  'Previdenciário': {
    'title': 'Área Previdenciária',
    'pecas': ['AÇÃO PREVIDENCIÁRIA'],
    'topics': <Map<String, dynamic>>[]
  },
  'Penal': {
    'title': 'Área Penal',
    'pecas': ['DEFESA PRÉVIA CRIMINAL'],
    'topics': <Map<String, dynamic>>[]
  },
  'Tributário': {
    'title': 'Área Tributária',
    'pecas': ['AÇÃO ANULATÓRIA FISCAL'],
    'topics': <Map<String, dynamic>>[]
  },
  'Empresarial': {
    'title': 'Área Empresarial',
    'pecas': ['AÇÃO SOCIETÁRIA'],
    'topics': <Map<String, dynamic>>[]
  },
  'Contratos': {
    'title': 'Elaboração de Contratos',
    'pecas': ['INSTRUMENTO PARTICULAR DE CONTRATO'],
    'topics': <Map<String, dynamic>>[]
  }
};

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