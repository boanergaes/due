import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:due_mobile/main.dart';
import 'package:due_mobile/providers/theme_provider.dart';
import 'package:due_mobile/services/api_client.dart';
import 'package:due_mobile/services/token_storage.dart';

void main() {
  testWidgets('DueApp loads architectural system smoke test', (WidgetTester tester) async {
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(tokenStorage: tokenStorage);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider<TokenStorage>.value(value: tokenStorage),
          Provider<ApiClient>.value(value: apiClient),
        ],
        child: const DueApp(),
      ),
    );

    // Verify brand title and architectural subtitle
    expect(find.text('DUE'), findsOneWidget);
    expect(find.text('ARCHITECTURAL SYSTEM'), findsOneWidget);
    expect(find.text('Strict 0-Radius Mobile Core'), findsOneWidget);

    // Verify metric cards
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('OVERDUE'), findsAtLeastNWidgets(1));

    // Verify zero buttons
    expect(find.text('PRIMARY BUTTON'), findsOneWidget);
    expect(find.text('OUTLINE'), findsOneWidget);
  });
}
