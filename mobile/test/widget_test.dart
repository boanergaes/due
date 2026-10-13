import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:due_mobile/main.dart';
import 'package:due_mobile/providers/auth_provider.dart';
import 'package:due_mobile/providers/theme_provider.dart';
import 'package:due_mobile/screens/auth/register_screen.dart';
import 'package:due_mobile/screens/splash_screen.dart';
import 'package:due_mobile/services/api_client.dart';
import 'package:due_mobile/services/token_storage.dart';

void main() {
  testWidgets('AuthGate shows LoginScreen when unauthenticated and validates inputs', (WidgetTester tester) async {
    final tokenStorage = TokenStorage(inMemoryOnly: true);
    final apiClient = ApiClient(tokenStorage: tokenStorage);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider<TokenStorage>.value(value: tokenStorage),
          Provider<ApiClient>.value(value: apiClient),
          ChangeNotifierProxyProvider<ThemeProvider, AuthProvider>(
            create: (context) => AuthProvider(
              apiClient: apiClient,
              tokenStorage: tokenStorage,
              themeProvider: context.read<ThemeProvider>(),
            ),
            update: (context, themeProvider, auth) =>
                auth ??
                AuthProvider(
                  apiClient: apiClient,
                  tokenStorage: tokenStorage,
                  themeProvider: themeProvider,
                ),
          ),
        ],
        child: const DueApp(),
      ),
    );

    // Allow post-frame checkAuth() to execute and transition to LoginScreen
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify LoginScreen is shown
    expect(find.text('Log in to Due'), findsOneWidget);
    expect(find.text('LOG IN'), findsOneWidget);
    expect(find.text('Register now'), findsOneWidget);

    // Tap Log In with empty fields to trigger validation
    await tester.tap(find.text('LOG IN'));
    await tester.pump();

    expect(find.text('Please enter your email address.'), findsOneWidget);
    expect(find.text('Please enter your password.'), findsOneWidget);
  });

  testWidgets('SplashScreen renders sharp architectural brand monogram and typography', (WidgetTester tester) async {
    final tokenStorage = TokenStorage(inMemoryOnly: true);
    final apiClient = ApiClient(tokenStorage: tokenStorage);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider<TokenStorage>.value(value: tokenStorage),
          Provider<ApiClient>.value(value: apiClient),
          ChangeNotifierProvider(
            create: (context) => AuthProvider(
              apiClient: apiClient,
              tokenStorage: tokenStorage,
            ),
          ),
        ],
        child: const MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    expect(find.text('D'), findsOneWidget);
    expect(find.text('D U E'), findsOneWidget);
    expect(find.text('ACADEMIC WORKLOAD & DEADLINES'), findsOneWidget);
  });

  testWidgets('RegisterScreen validates required student fields and password confirmation', (WidgetTester tester) async {
    final tokenStorage = TokenStorage(inMemoryOnly: true);
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final authProvider = AuthProvider(apiClient: apiClient, tokenStorage: tokenStorage);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider<TokenStorage>.value(value: tokenStorage),
          Provider<ApiClient>.value(value: apiClient),
          ChangeNotifierProvider.value(value: authProvider),
        ],
        child: const MaterialApp(
          home: RegisterScreen(),
        ),
      ),
    );

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);

    // Scroll into view and tap submit with empty fields
    await tester.ensureVisible(find.text('CREATE ACCOUNT'));
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pump();

    expect(find.text('Please enter your full name.'), findsOneWidget);
    expect(find.text('Please enter your email address.'), findsOneWidget);
    expect(find.text('Please enter a password.'), findsOneWidget);
  });

  testWidgets('AuthenticatedHomeScreen renders student profile and active session', (WidgetTester tester) async {
    final tokenStorage = TokenStorage(inMemoryOnly: true);
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final themeProvider = ThemeProvider();

    final authProvider = AuthProvider(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
      themeProvider: themeProvider,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          Provider<TokenStorage>.value(value: tokenStorage),
          Provider<ApiClient>.value(value: apiClient),
          ChangeNotifierProvider.value(value: authProvider),
        ],
        child: const MaterialApp(
          home: AuthenticatedHomeScreen(),
        ),
      ),
    );

    expect(find.text('ACTIVE (SANCTUM)'), findsOneWidget);
    expect(find.text('LOG OUT OF DUE'), findsOneWidget);
  });
}
