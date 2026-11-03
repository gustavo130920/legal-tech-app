/// Regra de senha forte usada no cadastro e na redefinição de senha.
/// Retorna a mensagem do problema encontrado ou null quando a senha é válida.
String? validatePassword(String password) {
  if (password.length < 8) {
    return 'Segurança: A senha deve ter pelo menos 8 caracteres.';
  }
  if (!password.contains(RegExp(r'[A-Z]'))) {
    return 'Segurança: A senha deve conter pelo menos 1 letra maiúscula.';
  }
  if (!password.contains(RegExp(r'[a-z]'))) {
    return 'Segurança: A senha deve conter pelo menos 1 letra minúscula.';
  }
  if (!password.contains(RegExp(r'[0-9]'))) {
    return 'Segurança: A senha deve conter pelo menos 1 número.';
  }
  // Verifica se há pelo menos um caractere que NÃO seja letra ou número
  if (!password.contains(RegExp(r'[^a-zA-Z0-9]'))) {
    return 'Segurança: A senha deve conter pelo menos 1 caractere especial (ex: @, #, !, &, etc).';
  }
  return null;
}
