import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legal_flow/core/auth/auth_redirect.dart';
import 'package:legal_flow/flutter_flow/nav/nav.dart';

void main() {
  testWidgets('o app compila com as rotas e o estado de autenticação', (tester) async {
    final notifier = AppStateNotifier.instance;
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: notifier,
        builder: (context, _) => Directionality(
          textDirection: TextDirection.ltr,
          child: Text(resolveAuthRedirect(
                path: '/mainMenu',
                isLoggedIn: false,
                isPasswordRecovery: notifier.isPasswordRecovery,
              ) ??
              ''),
        ),
      ),
    );

    expect(find.text('/login'), findsOneWidget);
  });
}
