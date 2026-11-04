// Ações do navegador isoladas para que o restante do app também compile fora
// da web, como acontece nos testes.
export 'document_actions_stub.dart'
    if (dart.library.html) 'document_actions_web.dart';
