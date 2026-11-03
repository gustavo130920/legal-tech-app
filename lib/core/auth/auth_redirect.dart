const String loginPath = '/login';
const String mainMenuPath = '/mainMenu';
const String updatePasswordPath = '/updatePassword';

const Set<String> _protectedPaths = {mainMenuPath, '/addTopicModal', '/areaWorkspace'};
const Set<String> _guestOnlyPaths = {'/', loginPath, '/register', '/recoverPassword'};

/// Decide para onde a navegação deve ir conforme o estado da sessão.
/// Retorna null quando a rota pedida pode ser aberta.
String? resolveAuthRedirect({
  required String path,
  required bool isLoggedIn,
  required bool isPasswordRecovery,
}) {
  if (path == updatePasswordPath) return null;
  if (isPasswordRecovery) return updatePasswordPath;
  if (!isLoggedIn && _protectedPaths.contains(path)) return loginPath;
  if (isLoggedIn && _guestOnlyPaths.contains(path)) return mainMenuPath;
  return null;
}
