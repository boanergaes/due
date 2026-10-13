import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:due_mobile/main.dart';
import 'package:due_mobile/models/assignment.dart';
import 'package:due_mobile/models/course_class.dart';
import 'package:due_mobile/models/course_workload.dart';
import 'package:due_mobile/models/dashboard_metrics.dart';
import 'package:due_mobile/providers/auth_provider.dart';
import 'package:due_mobile/providers/dashboard_provider.dart';
import 'package:due_mobile/providers/theme_provider.dart';
import 'package:due_mobile/screens/auth/register_screen.dart';
import 'package:due_mobile/screens/dashboard/dashboard_screen.dart';
import 'package:due_mobile/screens/main_navigation_screen.dart';
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

  testWidgets('DashboardScreen renders 2-column metrics grid and upcoming deadlines feed', (WidgetTester tester) async {
    final tokenStorage = TokenStorage(inMemoryOnly: true);
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final themeProvider = ThemeProvider();
    final authProvider = AuthProvider(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
      themeProvider: themeProvider,
    );

    final testAssignment = Assignment(
      id: 1,
      classId: 10,
      title: 'Operating Systems Kernel Lab',
      status: 'pending',
      deadline: DateTime.now().add(const Duration(days: 2)),
      urgency: {
        'label': 'DUE SOON',
        'color': 'yellow',
        'is_overdue': false,
        'days_remaining': 2,
      },
      courseClass: CourseClass(
        id: 10,
        userId: 1,
        courseName: 'CS 401: OS',
      ),
    );

    final dashboardProvider = DashboardProvider(
      apiClient: apiClient,
      initialMetrics: DashboardMetrics(
        total: 12,
        pending: 5,
        inProgress: 3,
        completed: 4,
        overdue: 0,
        dueToday: 1,
        completionRate: 33.3,
        onTimeRate: 100.0,
        completedRecently: 2,
      ),
      initialUpcoming: [testAssignment],
      initialWorkload: [
        CourseWorkload(
          id: 10,
          courseName: 'CS 401: OS',
          creditHours: 4,
          totalAssignments: 5,
          activeAssignments: 2,
          completedAssignments: 3,
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: dashboardProvider),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify Dashboard Title and Sections
    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(find.text('COURSEWORK METRICS'), findsOneWidget);
    expect(find.text('PERFORMANCE ANALYSIS'), findsOneWidget);
    expect(find.text('COMPLETION RATE'), findsOneWidget);
    expect(find.text('ON-TIME RATE'), findsOneWidget);
    expect(find.text('WORKLOAD BY COURSE'), findsOneWidget);
    expect(find.text('UPCOMING DEADLINES'), findsOneWidget);

    // Verify Metric Cards in 2-column grid
    expect(find.text('12'), findsOneWidget); // Total
    expect(find.text('5'), findsOneWidget);  // Pending
    expect(find.text('3'), findsOneWidget);  // In Progress
    expect(find.text('4'), findsOneWidget);  // Completed

    // Verify Course Workload details
    expect(find.text('4 CH'), findsOneWidget);
    expect(find.text('100.0% ON-TIME'), findsOneWidget);

    // Verify Upcoming Assignment Feed & Course Badge
    expect(find.text('Operating Systems Kernel Lab'), findsOneWidget);
    expect(find.text('CS 401: OS'), findsAtLeast(1));
    expect(find.text('DUE SOON'), findsOneWidget);
  });

  testWidgets('DashboardScreen displays overdue alert banner when overdue coursework exists', (WidgetTester tester) async {
    final tokenStorage = TokenStorage(inMemoryOnly: true);
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final themeProvider = ThemeProvider();
    final authProvider = AuthProvider(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
      themeProvider: themeProvider,
    );

    final dashboardProvider = DashboardProvider(
      apiClient: apiClient,
      initialMetrics: DashboardMetrics(
        total: 8,
        pending: 2,
        inProgress: 1,
        completed: 3,
        overdue: 2,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: dashboardProvider),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify Overdue Alert Banner
    expect(find.text('OVERDUE ATTENTION REQUIRED (2)'), findsOneWidget);
    expect(find.text('VIEW OVERDUE ASSIGNMENTS'), findsOneWidget);
  });

  testWidgets('MainNavigationScreen switches tabs between Dashboard, Courses, Assignments, and Settings', (WidgetTester tester) async {
    final tokenStorage = TokenStorage(inMemoryOnly: true);
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final themeProvider = ThemeProvider();
    final authProvider = AuthProvider(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
      themeProvider: themeProvider,
    );
    final dashboardProvider = DashboardProvider(apiClient: apiClient);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: dashboardProvider),
        ],
        child: const MaterialApp(
          home: MainNavigationScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify Bottom Navigation Bar tabs
    expect(find.text('DASHBOARD'), findsAtLeast(1));
    expect(find.text('COURSES'), findsOneWidget);
    expect(find.text('ASSIGNMENTS'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);

    // Switch to Settings tab
    await tester.tap(find.text('SETTINGS'));
    await tester.pump();

    expect(find.text('APPEARANCE & THEME'), findsOneWidget);
    expect(find.text('LOG OUT OF DUE'), findsOneWidget);
  });
}
