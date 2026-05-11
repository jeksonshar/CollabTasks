import 'package:collab_tasks/di/service_locator.dart';
import 'package:collab_tasks/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('MyApp renders main navigation', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    final sharedPreferences = await SharedPreferences.getInstance();
    setupLocator(sharedPreferences);

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Groups'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
