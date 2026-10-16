import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/api_config.dart';
import 'providers/ai_chat_provider.dart';
import 'providers/assignment_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/resource_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';
import 'services/token_storage.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/zero_button.dart';
import 'widgets/zero_card.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();
  final savedBaseUrl = await tokenStorage.getBaseUrl();
  if (savedBaseUrl != null && savedBaseUrl.trim().isNotEmpty) {
    ApiConfig.setBaseUrl(savedBaseUrl.trim());
  }

  final apiClient = ApiClient(tokenStorage: tokenStorage);

  runApp(
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
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(apiClient: apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => CourseProvider(apiClient: apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => AssignmentProvider(apiClient: apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => SubscriptionProvider(apiClient: apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => ResourceProvider(apiClient: apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => AiChatProvider(apiClient: apiClient),
        ),
      ],
      child: const DueApp(),
    ),
  );
}

class DueApp extends StatelessWidget {
  const DueApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Due',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const AuthGate(),
    );
  }
}

/// Reactive Auth Gate directing user to Splash, Login, or Main Navigation
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    switch (authProvider.status) {
      case AuthStatus.uninitialized:
        return const SplashScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticating:
        if (authProvider.user == null) {
          return const LoginScreen();
        }
        return const MainNavigationScreen();
      case AuthStatus.authenticated:
        return const MainNavigationScreen();
    }
  }
}

/// Authenticated Home View (Phase M3 Session Verification Screen)
class AuthenticatedHomeScreen extends StatelessWidget {
  const AuthenticatedHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              color: AppColors.coral,
              margin: const EdgeInsets.only(right: 8),
            ),
            const Text(
              'DUE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              final nextTheme = themeProvider.isDarkMode ? 'light' : 'dark';
              authProvider.updateAppearance(nextTheme);
            },
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Greeting Card
            ZeroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        color: AppColors.coral,
                        child: Center(
                          child: Text(
                            (user?.name.isNotEmpty ?? false)
                                ? user!.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Student',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.darkTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SESSION STATUS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Text(
                          'ACTIVE (SANCTUM)',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Action
            ZeroButton(
              label: 'LOG OUT OF DUE',
              variant: ZeroButtonVariant.outline,
              onPressed: () => authProvider.logout(),
            ),
          ],
        ),
      ),
    );
  }
}
