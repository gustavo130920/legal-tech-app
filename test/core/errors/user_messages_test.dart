import 'package:flutter_test/flutter_test.dart';
import 'package:legal_flow/core/errors/user_messages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('login inválido vira mensagem em português', () {
    expect(
      friendlyError(const AuthException('Invalid login credentials', code: 'invalid_credentials')),
      'E-mail ou senha incorretos.',
    );
    expect(
      friendlyError(const AuthException('Invalid login credentials')),
      'E-mail ou senha incorretos.',
    );
  });

  test('erro de banco não expõe detalhes técnicos', () {
    final message = friendlyError(const PostgrestException(
      message: 'relation "public.pecas" does not exist',
      code: '42P01',
    ));
    expect(message, isNot(contains('public.pecas')));
    expect(message, contains('Não foi possível'));
  });

  test('falta de permissão tem mensagem própria', () {
    expect(
      friendlyError(const PostgrestException(message: 'denied', code: '42501')),
      contains('permissão'),
    );
  });

  test('falha de rede orienta a verificar a internet', () {
    expect(friendlyError(Exception('ClientException: Failed to fetch')), contains('internet'));
    expect(friendlyError(AuthRetryableFetchException()), contains('internet'));
  });

  test('erro desconhecido não mostra o texto original', () {
    final message = friendlyError(Exception('supabase stack trace xyz'));
    expect(message, isNot(contains('supabase')));
    expect(message, contains('inesperado'));
  });
}
