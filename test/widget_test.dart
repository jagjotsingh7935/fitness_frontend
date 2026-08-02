// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_metabolism_app/injection_container.dart';
import 'package:fitness_metabolism_app/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await InjectionContainer.init();
  });

  tearDownAll(() async {
    await InjectionContainer.sl.reset();
  });

  testWidgets('App boots to login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    // Basic interaction: ensure the sign-in button exists and is tappable.
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    // We should still be on login because form validation prevents empty submit.
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
