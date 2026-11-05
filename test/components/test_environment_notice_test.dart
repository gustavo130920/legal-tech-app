import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legal_flow/components/test_environment_notice.dart';

void main() {
  testWidgets('avisa para usar apenas dados fictícios', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TestEnvironmentNotice())),
    );

    expect(find.textContaining('use apenas dados fictícios'), findsOneWidget);
  });

  testWidgets('quebra a linha em telas estreitas sem estourar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 280.0, child: TestEnvironmentNotice()),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
