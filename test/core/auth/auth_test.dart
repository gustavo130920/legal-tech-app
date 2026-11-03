import 'package:flutter_test/flutter_test.dart';
import 'package:legal_flow/app_state.dart';
import 'package:legal_flow/core/auth/auth_redirect.dart';
import 'package:legal_flow/core/auth/password_policy.dart';
import 'package:legal_flow/flutter_flow/nav/nav.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  String? redirect(String path, {bool loggedIn = false, bool recovery = false}) =>
      resolveAuthRedirect(path: path, isLoggedIn: loggedIn, isPasswordRecovery: recovery);

  group('proteção de rotas', () {
    test('sem sessão, rotas restritas vão para o login', () {
      for (final path in ['/mainMenu', '/areaWorkspace', '/addTopicModal']) {
        expect(redirect(path), '/login', reason: path);
      }
    });

    test('sem sessão, rotas públicas abrem normalmente', () {
      for (final path in ['/', '/login', '/register', '/recoverPassword']) {
        expect(redirect(path), isNull, reason: path);
      }
    });

    test('com sessão, rotas restritas abrem normalmente', () {
      for (final path in ['/mainMenu', '/areaWorkspace', '/addTopicModal']) {
        expect(redirect(path, loggedIn: true), isNull, reason: path);
      }
    });

    test('com sessão, telas de entrada vão para o menu', () {
      for (final path in ['/', '/login', '/register', '/recoverPassword']) {
        expect(redirect(path, loggedIn: true), '/mainMenu', reason: path);
      }
    });

    test('em recuperação de senha, toda rota leva à troca de senha', () {
      for (final path in ['/', '/login', '/mainMenu', '/areaWorkspace']) {
        expect(redirect(path, loggedIn: true, recovery: true), '/updatePassword', reason: path);
      }
      expect(redirect('/updatePassword', loggedIn: true, recovery: true), isNull);
    });

    test('a tela de troca de senha nunca é redirecionada', () {
      expect(redirect('/updatePassword'), isNull);
      expect(redirect('/updatePassword', loggedIn: true), isNull);
    });
  });

  group('limpeza de memória da sessão', () {
    void fillMemory() {
      globalCurrentArea = 'Penal';
      globalSelectedPeca = 'PEÇA SIGILOSA';
      globalSavedAreas = {'Penal'};
      globalAreaDatabase['Penal']['pecas'] = <String>['PEÇA SIGILOSA'];
      globalAreaDatabase['Penal']['topics'] = <Map<String, dynamic>>[
        {'id': 1, 'title': 'Tópico sigiloso'},
      ];
    }

    void expectMemoryClean() {
      expect(globalCurrentArea, isEmpty);
      expect(globalSelectedPeca, isNull);
      expect(globalSavedAreas, isEmpty);
      globalAreaDatabase.forEach((area, value) {
        expect(value['pecas'], isEmpty, reason: area);
        expect(value['topics'], isEmpty, reason: area);
      });
    }

    test('clearSessionMemory apaga os dados do usuário', () {
      fillMemory();
      clearSessionMemory();
      expectMemoryClean();
    });

    test('perder a sessão por qualquer motivo limpa a memória', () {
      fillMemory();
      AppStateNotifier.instance.handleAuthEvent(AuthChangeEvent.signedOut);
      expectMemoryClean();
    });

    test('renovar o token não apaga os dados nem avisa as rotas', () {
      fillMemory();
      var notified = false;
      void listener() => notified = true;
      AppStateNotifier.instance.addListener(listener);
      AppStateNotifier.instance.handleAuthEvent(AuthChangeEvent.tokenRefreshed);
      AppStateNotifier.instance.removeListener(listener);
      expect(globalCurrentArea, 'Penal');
      expect(notified, isFalse);
      clearSessionMemory();
    });

    test('o estado de recuperação de senha acompanha os eventos', () {
      final notifier = AppStateNotifier.instance;
      notifier.handleAuthEvent(AuthChangeEvent.passwordRecovery);
      expect(notifier.isPasswordRecovery, isTrue);
      notifier.finishPasswordRecovery();
      expect(notifier.isPasswordRecovery, isFalse);

      notifier.handleAuthEvent(AuthChangeEvent.passwordRecovery);
      notifier.handleAuthEvent(AuthChangeEvent.signedOut);
      expect(notifier.isPasswordRecovery, isFalse);
    });
  });

  group('política de senha', () {
    test('aceita senha forte', () {
      expect(validatePassword('Forte#123'), isNull);
    });

    test('recusa cada regra não atendida', () {
      expect(validatePassword('Ab#1'), contains('8 caracteres'));
      expect(validatePassword('fraca#123'), contains('maiúscula'));
      expect(validatePassword('FRACA#123'), contains('minúscula'));
      expect(validatePassword('Fraca#abc'), contains('número'));
      expect(validatePassword('Fraca1234'), contains('especial'));
    });
  });
}
