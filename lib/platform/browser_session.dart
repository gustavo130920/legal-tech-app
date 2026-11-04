// Armazenamento da sessão e aviso de saída, isolados para que o restante do
// app também compile fora da web, como acontece nos testes.
export 'browser_session_stub.dart'
    if (dart.library.html) 'browser_session_web.dart';
