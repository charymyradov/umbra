import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:umbra/app.dart';
import 'package:umbra/data/firebase/firebase_providers.dart';

void main() {
  testWidgets('Umbra app renders the sign-in screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWith((ref) => Stream.value(null))],
        child: const UmbraApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Umbra'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
