import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _connectionMessage =
    'Não foi possível conectar ao servidor. Verifique sua internet e tente novamente.';

const Map<String, String> _authMessages = {
  'invalid_credentials': 'E-mail ou senha incorretos.',
  'email_not_confirmed': 'Confirme seu e-mail antes de entrar.',
  'user_already_exists': 'Já existe uma conta com este e-mail.',
  'email_exists': 'Já existe uma conta com este e-mail.',
  'weak_password': 'A senha não atende aos requisitos de segurança.',
  'same_password': 'A nova senha precisa ser diferente da atual.',
  'over_email_send_rate_limit': 'Muitos e-mails enviados. Aguarde alguns minutos e tente novamente.',
  'over_request_rate_limit': 'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
  'validation_failed': 'Verifique os dados informados e tente novamente.',
};

/// Mensagem em português para o usuário. Os detalhes técnicos ficam só no log.
String friendlyError(Object error) {
  debugPrint('Erro: $error');

  if (error is AuthRetryableFetchException) return _connectionMessage;

  if (error is AuthException) {
    final known = _authMessages[error.code];
    if (known != null) return known;
    final message = error.message.toLowerCase();
    if (message.contains('invalid login')) return _authMessages['invalid_credentials']!;
    if (message.contains('not confirmed')) return _authMessages['email_not_confirmed']!;
    if (message.contains('already registered')) return _authMessages['user_already_exists']!;
    return 'Não foi possível validar seu acesso. Tente novamente.';
  }

  if (error is PostgrestException) {
    if (error.code == '23505') return 'Já existe um item com este nome.';
    return error.code == '42501'
        ? 'Sua conta não tem permissão para esta operação.'
        : 'Não foi possível concluir a operação. Tente novamente.';
  }

  final text = error.toString();
  if (text.contains('ClientException') ||
      text.contains('Failed to fetch') ||
      text.contains('SocketException') ||
      text.contains('XMLHttpRequest')) {
    return _connectionMessage;
  }

  return 'Ocorreu um erro inesperado. Tente novamente.';
}
