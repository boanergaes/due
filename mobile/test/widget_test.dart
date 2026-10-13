import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:due_mobile/main.dart';
import 'package:due_mobile/models/assignment.dart';
import 'package:due_mobile/models/assignment_note.dart';
import 'package:due_mobile/models/course_class.dart';
import 'package:due_mobile/models/course_workload.dart';
import 'package:due_mobile/models/dashboard_metrics.dart';
import 'package:due_mobile/providers/assignment_provider.dart';
import 'package:due_mobile/providers/auth_provider.dart';
import 'package:due_mobile/providers/course_provider.dart';
import 'package:due_mobile/providers/dashboard_provider.dart';
import 'package:due_mobile/providers/theme_provider.dart';
import 'package:due_mobile/screens/assignments/assignment_detail_screen.dart';
import 'package:due_mobile/screens/assignments/assignment_form_screen.dart';
import 'package:due_mobile/screens/assignments/assignments_list_screen.dart';
import 'package:due_mobile/screens/assignments/note_form_dialog.dart';
import 'package:due_mobile/screens/auth/register_screen.dart';
import 'package:due_mobile/screens/courses/course_detail_screen.dart';
import 'package:due_mobile/screens/courses/courses_list_screen.dart';
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
    expect(find.text('4.0 CH'), findsOneWidget);
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
    final courseProvider = CourseProvider(apiClient: apiClient);
    final assignmentProvider = AssignmentProvider(apiClient: apiClient);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: dashboardProvider),
          ChangeNotifierProvider.value(value: courseProvider),
          ChangeNotifierProvider.value(value: assignmentProvider),
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

  testWidgets('CoursesListScreen renders courses list, CH/ECTS badges, and add course button', (WidgetTester tester) async {
    final tokenStorage = TokenStorage(inMemoryOnly: true);
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final themeProvider = ThemeProvider();

    final testCourse = CourseClass(
      id: 1,
      courseName: 'Distributed Systems',
      teacherName: 'Dr. Leslie Lamport',
      creditHours: 4,
      ects: 6.0,
      assignmentsCount: 3,
    );

    final courseProvider = CourseProvider(
      apiClient: apiClient,
      initialCourses: [testCourse],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: courseProvider),
        ],
        child: const MaterialApp(
          home: CoursesListScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('COURSES'), findsOneWidget);
    expect(find.text('1 REGISTERED COURSE'), findsOneWidget);
    expect(find.text('Distributed Systems'), findsOneWidget);
    expect(find.text('Dr. Leslie Lamport'), findsOneWidget);
    expect(find.text('4.0 CH'), findsOneWidget);
    expect(find.text('6.0 ECTS'), findsOneWidget);
    expect(find.text('3 TASKS'), findsOneWidget);
    expect(find.text('NEW COURSE'), findsOneWidget);
  });

  testWidgets('CourseDetailScreen displays course info, credits, and linked coursework', (WidgetTester tester) async {
    final tokenStorage = TokenStorage(inMemoryOnly: true);
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final themeProvider = ThemeProvider();

    final testCourse = CourseClass(
      id: 2,
      courseName: 'Algorithms & Complexity',
      teacherName: 'Prof. Donald Knuth',
      teacherContact: 'knuth@cs.stanford.edu',
      creditHours: 5,
      ects: 7.5,
      assignmentsCount: 1,
    );

    final testAssignment = Assignment(
      id: 50,
      classId: 2,
      title: 'Dynamic Programming Problem Set',
      status: 'pending',
      deadline: DateTime.now().add(const Duration(days: 3)),
      urgency: {'label': 'UPCOMING', 'color': 'gray', 'is_overdue': false},
    );

    final courseProvider = CourseProvider(
      apiClient: apiClient,
      initialSelectedCourse: testCourse,
      initialAssignments: [testAssignment],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: courseProvider),
        ],
        child: const MaterialApp(
          home: CourseDetailScreen(
            courseId: 2,
            courseName: 'Algorithms & Complexity',
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Algorithms & Complexity'), findsAtLeast(1));
    expect(find.text('Prof. Donald Knuth'), findsOneWidget);
    expect(find.text('knuth@cs.stanford.edu'), findsOneWidget);
    expect(find.text('5.0 CH'), findsOneWidget);
    expect(find.text('7.5 ECTS'), findsOneWidget);
    expect(find.text('COURSE ASSIGNMENTS'), findsOneWidget);
    expect(find.text('Dynamic Programming Problem Set'), findsOneWidget);
  });

  testWidgets('Deletion safeguard blocks deleting courses with existing assignments', (WidgetTester tester) async {
    final tokenStorage = TokenStorage(inMemoryOnly: true);
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final themeProvider = ThemeProvider();

    final courseWithAssignments = CourseClass(
      id: 3,
      courseName: 'Compiler Construction',
      assignmentsCount: 2,
    );

    final courseProvider = CourseProvider(
      apiClient: apiClient,
      initialCourses: [courseWithAssignments],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: courseProvider),
        ],
        child: const MaterialApp(
          home: CoursesListScreen(),
        ),
      ),
    );

    await tester.pump();

    // Tap delete button on course card
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // Safeguard dialog should be shown
    expect(find.text('Deletion Safeguard'), findsOneWidget);
    expect(find.text('UNDERSTOOD'), findsOneWidget);

    // Tap UNDERSTOOD to dismiss
    await tester.tap(find.text('UNDERSTOOD'));
    await tester.pumpAndSettle();

    expect(find.text('Deletion Safeguard'), findsNothing);
  });

  testWidgets('AssignmentsListScreen renders filter tabs, search bar, and assignment cards', (WidgetTester tester) async {
    final tokenStorage = TokenStorage(inMemoryOnly: true);
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final themeProvider = ThemeProvider();

    final testCourse = CourseClass(
      id: 5,
      courseName: 'Computer Networks',
      creditHours: 3.0,
      ects: 5.0,
    );

    final testAssignment = Assignment(
      id: 101,
      classId: 5,
      title: 'TCP Reno Congestion Control Analysis',
      description: 'Implement simulation in ns-3 and report throughput graphs.',
      status: 'pending',
      deadline: DateTime.now().add(const Duration(days: 4)),
      urgency: {'label': 'UPCOMING', 'color': 'gray', 'is_overdue': false},
      courseClass: testCourse,
    );

    final courseProvider = CourseProvider(
      apiClient: apiClient,
      initialCourses: [testCourse],
    );

    final assignmentProvider = AssignmentProvider(
      apiClient: apiClient,
      initialAssignments: [testAssignment],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: courseProvider),
          ChangeNotifierProvider.value(value: assignmentProvider),
        ],
        child: const MaterialApp(
          home: AssignmentsListScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify Title and Subtitle
    expect(find.text('ASSIGNMENTS'), findsOneWidget);
    expect(find.text('1 TASK LISTED'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);

    // Verify Status Filter Tabs
    expect(find.text('ALL'), findsOneWidget);
    expect(find.text('PENDING'), findsAtLeast(1));
    expect(find.text('IN PROGRESS'), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);

    // Verify Assignment Card Details
    expect(find.text('TCP Reno Congestion Control Analysis'), findsOneWidget);
    expect(find.text('Computer Networks'), findsAtLeast(1));
    expect(find.text('UPCOMING'), findsOneWidget);
  });

  testWidgets('AssignmentDetailScreen renders deadline countdown, status segment, and full description', (WidgetTester tester) async {
    final tokenStorage = TokenStorage(inMemoryOnly: true);
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final themeProvider = ThemeProvider();

    final testCourse = CourseClass(
      id: 7,
      courseName: 'Database Internals',
      teacherName: 'Dr. Michael Stonebraker',
    );

    final testAssignment = Assignment(
      id: 202,
      classId: 7,
      title: 'B+ Tree Concurrency & Latching',
      description: 'Implement lock coupling and crabbing for leaf page insertions.',
      status: 'in_progress',
      deadline: DateTime.now().add(const Duration(days: 1)),
      urgency: {'label': 'DUE SOON', 'color': 'yellow', 'is_overdue': false},
      courseClass: testCourse,
    );

    final assignmentProvider = AssignmentProvider(
      apiClient: apiClient,
      initialSelectedAssignment: testAssignment,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: assignmentProvider),
        ],
        child: MaterialApp(
          home: AssignmentDetailScreen(
            assignmentId: 202,
            initialAssignment: testAssignment,
          ),
        ),
      ),
    );

    await tester.pump();

    // Header & Title
    expect(find.text('ASSIGNMENT DETAIL'), findsOneWidget);
    expect(find.text('B+ Tree Concurrency & Latching'), findsOneWidget);
    expect(find.text('Database Internals'), findsOneWidget);
    expect(find.text('Dr. Michael Stonebraker'), findsOneWidget);

    // Urgency & Status
    expect(find.text('ACTIVE DEADLINE: DUE SOON'), findsOneWidget);
    expect(find.text('STATUS WORKFLOW'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('IN PROGRESS'), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);

    // Description & Schedule
    expect(find.text('Implement lock coupling and crabbing for leaf page insertions.'), findsOneWidget);
    expect(find.text('SCHEDULE & DEADLINE'), findsOneWidget);
  });

  testWidgets('AssignmentFormScreen displays course dropdown, inputs, and validates required title', (WidgetTester tester) async {
    final tokenStorage = TokenStorage(inMemoryOnly: true);
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final themeProvider = ThemeProvider();

    final testCourse = CourseClass(
      id: 9,
      courseName: 'Cryptography & Security',
    );

    final courseProvider = CourseProvider(
      apiClient: apiClient,
      initialCourses: [testCourse],
    );

    final assignmentProvider = AssignmentProvider(
      apiClient: apiClient,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: courseProvider),
          ChangeNotifierProvider.value(value: assignmentProvider),
        ],
        child: const MaterialApp(
          home: AssignmentFormScreen(preselectedClassId: 9),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('NEW ASSIGNMENT'), findsOneWidget);
    expect(find.text('COURSE CLASS'), findsOneWidget);
    expect(find.text('ASSIGNMENT TITLE'), findsOneWidget);
    expect(find.text('DESCRIPTION (OPTIONAL)'), findsOneWidget);
    expect(find.text('STATUS'), findsOneWidget);
    expect(find.text('DUE DATE & TIME'), findsOneWidget);
    expect(find.text('CREATE ASSIGNMENT'), findsOneWidget);

    // Tap submit with empty title to trigger validation
    await tester.tap(find.text('CREATE ASSIGNMENT'));
    await tester.pump();

    expect(find.text('Assignment title is required'), findsOneWidget);
  });

  testWidgets('AssignmentDetailScreen embeds notes list and triggers note creation dialog', (WidgetTester tester) async {
    final tokenStorage = TokenStorage(inMemoryOnly: true);
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final themeProvider = ThemeProvider();

    final testNote1 = AssignmentNote(
      id: 11,
      assignmentId: 303,
      content: 'Refer to chapter 5 regarding Paxos state machine replication.',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    );

    final testNote2 = AssignmentNote(
      id: 12,
      assignmentId: 303,
      content: 'Edge case: handles partition across majority nodes.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    );

    final testAssignment = Assignment(
      id: 303,
      classId: 1,
      title: 'Distributed Systems Raft Consensus Lab',
      status: 'pending',
      deadline: DateTime.now().add(const Duration(days: 5)),
      urgency: {'label': 'UPCOMING', 'color': 'gray', 'is_overdue': false},
      notes: [testNote1, testNote2],
    );

    final assignmentProvider = AssignmentProvider(
      apiClient: apiClient,
      initialSelectedAssignment: testAssignment,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: assignmentProvider),
        ],
        child: MaterialApp(
          home: AssignmentDetailScreen(
            assignmentId: 303,
            initialAssignment: testAssignment,
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify Notes Header and Notes count
    expect(find.text('COURSEWORK NOTES (2)'), findsOneWidget);
    expect(find.text('ADD NOTE'), findsOneWidget);

    // Verify Notes Content
    expect(find.text('Refer to chapter 5 regarding Paxos state machine replication.'), findsOneWidget);
    expect(find.text('Edge case: handles partition across majority nodes.'), findsOneWidget);

    // Tap ADD NOTE button to trigger modal
    await tester.tap(find.text('ADD NOTE'));
    await tester.pumpAndSettle();

    // Verify Modal Dialog is displayed
    expect(find.text('NEW STUDY NOTE'), findsOneWidget);
    expect(find.text('NOTE CONTENT'), findsOneWidget);
    expect(find.text('SAVE'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();

    expect(find.text('NEW STUDY NOTE'), findsNothing);
  });

  testWidgets('NoteFormDialog validates required content and supports editing', (WidgetTester tester) async {
    final existingNote = AssignmentNote(
      id: 25,
      assignmentId: 303,
      content: 'Verify edge cases in Byzantine fault tolerance.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  NoteFormDialog.show(context, note: existingNote);
                },
                child: const Text('OPEN DIALOG'),
              );
            },
          ),
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('OPEN DIALOG'));
    await tester.pumpAndSettle();

    // Verify Edit Mode Title and Pre-filled Content
    expect(find.text('EDIT STUDY NOTE'), findsOneWidget);
    expect(find.text('Verify edge cases in Byzantine fault tolerance.'), findsOneWidget);
    expect(find.text('UPDATE'), findsOneWidget);

    // Clear content and tap UPDATE to test validation
    await tester.enterText(find.byType(TextFormField), '');
    await tester.tap(find.text('UPDATE'));
    await tester.pump();

    expect(find.text('Note content cannot be empty'), findsOneWidget);
  });
}
