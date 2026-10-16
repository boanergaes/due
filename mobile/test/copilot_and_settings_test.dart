import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:due_mobile/config/api_config.dart';
import 'package:due_mobile/models/ai_message.dart';
import 'package:due_mobile/models/user.dart';
import 'package:due_mobile/models/subscription_info.dart';
import 'package:due_mobile/providers/ai_chat_provider.dart';
import 'package:due_mobile/providers/assignment_provider.dart';
import 'package:due_mobile/providers/auth_provider.dart';
import 'package:due_mobile/providers/course_provider.dart';
import 'package:due_mobile/providers/dashboard_provider.dart';
import 'package:due_mobile/providers/resource_provider.dart';
import 'package:due_mobile/providers/subscription_provider.dart';
import 'package:due_mobile/providers/theme_provider.dart';
import 'package:due_mobile/screens/main_navigation_screen.dart';
import 'package:due_mobile/services/api_client.dart';
import 'package:due_mobile/services/token_storage.dart';
import 'package:due_mobile/widgets/due_copilot_drawer.dart';

void main() {
  group('Global Due Copilot & Mentionables', () {
    test('MentionItem parses course and assignment json correctly', () {
      final courseMention = MentionItem.fromJson({
        'id': 10,
        'type': 'class',
        'name': 'Algorithms & Data Structures',
        'detail': 'CS201',
      });

      expect(courseMention.id, 10);
      expect(courseMention.type, 'class');
      expect(courseMention.isCourse, isTrue);
      expect(courseMention.isAssignment, isFalse);
      expect(courseMention.name, 'Algorithms & Data Structures');

      final taskMention = MentionItem.fromJson({
        'id': 42,
        'type': 'assignment',
        'name': 'Dynamic Programming Lab',
        'detail': 'Due Tomorrow',
      });

      expect(taskMention.id, 42);
      expect(taskMention.type, 'assignment');
      expect(taskMention.isCourse, isFalse);
      expect(taskMention.isAssignment, isTrue);
    });

    test('AiChatProvider manages mention state and focus seamlessly', () {
      final tokenStorage = TokenStorage(inMemoryOnly: true);
      final apiClient = ApiClient(tokenStorage: tokenStorage);
      final aiProvider = AiChatProvider(apiClient: apiClient);

      final item1 = MentionItem(id: 1, type: 'class', name: 'Calculus III');
      final item2 = MentionItem(id: 2, type: 'assignment', name: 'Problem Set 4');

      aiProvider.addMention(item1);
      aiProvider.addMention(item2);
      expect(aiProvider.activeMentions.length, 2);

      // Duplicates are ignored
      aiProvider.addMention(item1);
      expect(aiProvider.activeMentions.length, 2);

      aiProvider.removeMention(1, 'class');
      expect(aiProvider.activeMentions.length, 1);
      expect(aiProvider.activeMentions.first.id, 2);

      aiProvider.clearMentions();
      expect(aiProvider.activeMentions.isEmpty, isTrue);

      aiProvider.setFocus(101, title: 'Final Project Submission');
      expect(aiProvider.currentAssignmentId, 101);
      expect(aiProvider.currentAssignmentTitle, 'Final Project Submission');
    });

    testWidgets('DueCopilotDrawer renders drawer with zero radius and quick prompt chips', (tester) async {
      final tokenStorage = TokenStorage(inMemoryOnly: true);
      final apiClient = ApiClient(tokenStorage: tokenStorage);
      final aiProvider = AiChatProvider(apiClient: apiClient);
      final subProvider = SubscriptionProvider(
        apiClient: apiClient,
        initialInfo: const SubscriptionInfo(
          tier: 'premium',
          tierLabel: 'Genius Tier',
          isAdmin: false,
          abilities: ['feature:ai'],
          storage: StorageQuota(
            usedBytes: 0,
            limitBytes: 0,
            usedFormatted: '0 B',
            limitFormatted: '0 B',
            percentage: 0,
          ),
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: aiProvider),
            ChangeNotifierProvider.value(value: subProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              endDrawer: DueCopilotDrawer(),
            ),
          ),
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openEndDrawer();
      await tester.pumpAndSettle();

      expect(find.text('DUE COPILOT'), findsOneWidget);
      expect(find.text('HOW CAN I HELP YOU TODAY?'), findsOneWidget);
      expect(find.text('Summarize Tasks'), findsOneWidget);
      expect(find.text('Weekly Study Plan'), findsOneWidget);
    });
  });

  group('Web-matching Assignment Filters', () {
    test('AssignmentProvider tracks status, urgency, date range, and reset', () {
      final tokenStorage = TokenStorage(inMemoryOnly: true);
      final apiClient = ApiClient(tokenStorage: tokenStorage);
      final provider = AssignmentProvider(apiClient: apiClient);

      expect(provider.hasActiveFilters, isFalse);

      provider.setStatusFilter('in_progress');
      expect(provider.statusFilter, 'in_progress');
      expect(provider.hasActiveFilters, isTrue);

      provider.setClassFilter(5);
      expect(provider.selectedClassId, 5);

      provider.setUrgencyFilter('overdue');
      expect(provider.urgencyFilter, 'overdue');

      final start = DateTime(2026, 10, 1);
      final end = DateTime(2026, 10, 31);
      provider.setDateRange(start, end);
      expect(provider.startDate, start);
      expect(provider.endDate, end);

      provider.resetFilters();
      expect(provider.statusFilter, 'all');
      expect(provider.selectedClassId, isNull);
      expect(provider.urgencyFilter, isNull);
      expect(provider.startDate, isNull);
      expect(provider.endDate, isNull);
      expect(provider.hasActiveFilters, isFalse);
    });
  });

  group('Mobile Settings & Profile CRUD', () {
    testWidgets('Settings screen renders Profile CRUD, Password CRUD, and Danger zone', (tester) async {
      final tokenStorage = TokenStorage(inMemoryOnly: true);
      final apiClient = ApiClient(tokenStorage: tokenStorage);
      final themeProvider = ThemeProvider();

      final authProvider = AuthProvider(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
        themeProvider: themeProvider,
        initialUser: User(
          id: 1,
          name: 'Jane Doe',
          email: 'jane@university.edu',
          appearance: 'dark',
        ),
      );

      final subProvider = SubscriptionProvider(apiClient: apiClient);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            Provider.value(value: tokenStorage),
            Provider.value(value: apiClient),
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: subProvider),
            ChangeNotifierProvider(create: (_) => DashboardProvider(apiClient: apiClient)),
            ChangeNotifierProvider(create: (_) => CourseProvider(apiClient: apiClient)),
            ChangeNotifierProvider(create: (_) => AssignmentProvider(apiClient: apiClient)),
            ChangeNotifierProvider(create: (_) => ResourceProvider(apiClient: apiClient)),
            ChangeNotifierProvider(create: (_) => AiChatProvider(apiClient: apiClient)),
          ],
          child: const MaterialApp(
            home: MainNavigationScreen(initialIndex: 3), // Settings tab
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Profile Information Card
      expect(find.text('PROFILE INFORMATION'), findsOneWidget);
      expect(find.text('SAVE PROFILE'), findsOneWidget);

      // Security & Password Card
      expect(find.text('SECURITY & PASSWORD'), findsOneWidget);
      expect(find.text('UPDATE PASSWORD'), findsOneWidget);


      // Danger Zone
      expect(find.text('DANGER ZONE'), findsOneWidget);
      expect(find.text('DELETE ACCOUNT'), findsOneWidget);

      // Logout
      expect(find.text('LOG OUT OF DUE'), findsOneWidget);
    });

    test('ApiConfig supports custom base URL setting and persistence', () async {
      final tokenStorage = TokenStorage(inMemoryOnly: true);

      await tokenStorage.saveBaseUrl('http://192.168.1.150:8000/api/v1');
      final loaded = await tokenStorage.getBaseUrl();
      expect(loaded, 'http://192.168.1.150:8000/api/v1');

      ApiConfig.setBaseUrl(loaded!);
      expect(ApiConfig.baseUrl, 'http://192.168.1.150:8000/api/v1');
      expect(ApiConfig.aiChat, 'http://192.168.1.150:8000/api/v1/ai/chat');
      expect(ApiConfig.profile, 'http://192.168.1.150:8000/api/v1/auth/profile');
      expect(ApiConfig.password, 'http://192.168.1.150:8000/api/v1/auth/password');
      expect(ApiConfig.deleteAccount, 'http://192.168.1.150:8000/api/v1/auth/account');

      // Reset to default
      ApiConfig.setBaseUrl('http://127.0.0.1:8000/api/v1');
    });
  });
}
