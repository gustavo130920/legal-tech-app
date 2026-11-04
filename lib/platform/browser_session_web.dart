import 'dart:async';
import 'dart:html' as web;

const String _prefix = 'legaltech.draft.';

StreamSubscription<web.Event>? _leaveGuard;

// sessionStorage: o conteúdo some ao fechar a aba e nunca vai para o servidor.
String? readDraft(String key) {
  try {
    return web.window.sessionStorage['$_prefix$key'];
  } catch (_) {
    return null;
  }
}

void writeDraft(String key, String content) {
  try {
    web.window.sessionStorage['$_prefix$key'] = content;
  } catch (_) {
    // Sem armazenamento disponível o app continua funcionando, só sem rascunho.
  }
}

void removeDraft(String key) {
  try {
    web.window.sessionStorage.remove('$_prefix$key');
  } catch (_) {}
}

void clearDrafts() {
  try {
    final storage = web.window.sessionStorage;
    storage.keys
        .where((key) => key.startsWith(_prefix))
        .toList()
        .forEach(storage.remove);
  } catch (_) {}
  setLeaveGuard(false);
}

/// Com o aviso ligado, o navegador confirma antes de fechar ou sair da página.
void setLeaveGuard(bool enabled) {
  if (!enabled) {
    _leaveGuard?.cancel();
    _leaveGuard = null;
    return;
  }
  _leaveGuard ??= web.window.onBeforeUnload.listen((event) {
    (event as web.BeforeUnloadEvent).returnValue = '';
    event.preventDefault();
  });
}
