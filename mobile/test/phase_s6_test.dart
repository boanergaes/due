import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:due_mobile/models/assignment.dart';
import 'package:due_mobile/models/course_class.dart';
import 'package:due_mobile/models/study_resource.dart';
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
import 'package:due_mobile/widgets/assignment_ai_chat_sheet.dart';
import 'package:due_mobile/widgets/resource_preview_modal.dart';
import 'package:due_mobile/widgets/upgrade_plan_dialog.dart';

void main() {
  group('Phase S6: Mobile Subscription & Quota', () {
    test('SubscriptionInfo correctly resolves abilities and feature gating', () {
      final freeInfo = SubscriptionInfo.fromJson({
        'tier': 'free',
        'tier_label': 'Free Tier',
        'is_admin': false,
        'abilities': ['feature:core'],
        'storage': {
          'used_bytes': 0,
          'limit_bytes': 0,
          'used_formatted': '0 B',
          'limit_formatted': '0 B',
          'percentage': 0,
        },
      });

      expect(freeInfo.isFree, isTrue);
      expect(freeInfo.isScholar, isFalse);
      expect(freeInfo.isGenius, isFalse);
      expect(freeInfo.canUploadResources, isFalse);
      expect(freeInfo.canUseAi, isFalse);

      final scholarInfo = SubscriptionInfo.fromJson({
        'tier': 'basic',
        'tier_label': 'Scholar',
        'is_admin': false,
        'abilities': ['feature:core', 'feature:resources'],
        'storage': {
          'used_bytes': 1048576,
          'limit_bytes': 524288000,
          'used_formatted': '1.0 MB',
          'limit_formatted': '500 MB',
          'percentage': 0.2,
        },
      });

      expect(scholarInfo.isScholar, isTrue);
      expect(scholarInfo.canUploadResources, isTrue);
      expect(scholarInfo.canUseAi, isFalse);

      final geniusInfo = SubscriptionInfo.fromJson({
        'tier': 'premium',
        'tier_label': 'Genius',
        'is_admin': false,
        'abilities': ['feature:core', 'feature:resources', 'feature:ai'],
        'storage': {
          'used_bytes': 104857600,
          'limit_bytes': 5368709120,
          'used_formatted': '100 MB',
          'limit_formatted': '5 GB',
          'percentage': 1.9,
        },
      });

      expect(geniusInfo.isGenius, isTrue);
      expect(geniusInfo.canUploadResources, isTrue);
      expect(geniusInfo.canUseAi, isTrue);
    });

    testWidgets('UpgradePlanDialog displays sharp plan tiers, test card, and zero-radius borders', (WidgetTester tester) async {
      final tokenStorage = TokenStorage(inMemoryOnly: true);
      final apiClient = ApiClient(tokenStorage: tokenStorage);
      final subProvider = SubscriptionProvider(apiClient: apiClient);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: subProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: UpgradePlanDialog(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('UPGRADE SUBSCRIPTION'), findsOneWidget);
      expect(find.text('MONTHLY BILLING'), findsOneWidget);
      expect(find.text('ANNUAL (SAVE 18%)'), findsOneWidget);
      expect(find.text('SCHOLAR'), findsOneWidget);
      expect(find.text('GENIUS'), findsOneWidget);
      expect(find.text('TEST PAYMENT METHOD'), findsOneWidget);
      expect(find.text('SIMULATED'), findsOneWidget);

      // Verify zero-radius architecture on Dialog
      final dialogFinder = find.byType(Dialog);
      expect(dialogFinder, findsOneWidget);
      final dialog = tester.widget<Dialog>(dialogFinder);
      final shape = dialog.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, equals(BorderRadius.zero));
    });

    testWidgets('Settings screen renders Subscription & Storage quota card', (WidgetTester tester) async {
      final tokenStorage = TokenStorage(inMemoryOnly: true);
      final apiClient = ApiClient(tokenStorage: tokenStorage);
      final themeProvider = ThemeProvider();
      final authProvider = AuthProvider(apiClient: apiClient, tokenStorage: tokenStorage);
      final dashboardProvider = DashboardProvider(apiClient: apiClient);
      final courseProvider = CourseProvider(apiClient: apiClient);
      final assignmentProvider = AssignmentProvider(apiClient: apiClient);
      final subProvider = SubscriptionProvider(apiClient: apiClient);
      final resourceProvider = ResourceProvider(apiClient: apiClient);
      final aiChatProvider = AiChatProvider(apiClient: apiClient);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: dashboardProvider),
            ChangeNotifierProvider.value(value: courseProvider),
            ChangeNotifierProvider.value(value: assignmentProvider),
            ChangeNotifierProvider.value(value: subProvider),
            ChangeNotifierProvider.value(value: resourceProvider),
            ChangeNotifierProvider.value(value: aiChatProvider),
          ],
          child: const MaterialApp(
            home: MainNavigationScreen(initialIndex: 3), // Settings tab
          ),
        ),
      );

      await tester.pump();

      expect(find.text('SETTINGS & PROFILE'), findsOneWidget);
      expect(find.text('SUBSCRIPTION & STORAGE'), findsOneWidget);
      expect(find.text('FREE TIER'), findsOneWidget);
      expect(find.text('UPGRADE TO SCHOLAR / GENIUS'), findsOneWidget);
    });
  });

  group('Phase S6: Study Resources & Viewers', () {
    test('StudyResource parses PDF, Image, and Extracted Text metadata', () {
      final resource = StudyResource.fromJson({
        'id': 42,
        'title': 'Lecture 03 Slides',
        'file_name': 'lecture3.pdf',
        'mime_type': 'application/pdf',
        'file_size_bytes': 2097152,
        'formatted_size': '2.0 MB',
        'is_image': false,
        'is_pdf': true,
        'is_text': false,
        'has_extracted_text': true,
        'extracted_text': 'Virtual Memory and Paging mechanisms...',
        'created_at': '2026-10-15T12:00:00Z',
      });

      expect(resource.id, equals(42));
      expect(resource.fileName, equals('lecture3.pdf'));
      expect(resource.isPdf, isTrue);
      expect(resource.hasExtractedText, isTrue);
      expect(resource.extractedText, contains('Virtual Memory'));
    });

    testWidgets('ResourcePreviewModal displays extracted text with zero-radius dialog', (WidgetTester tester) async {
      const resource = StudyResource(
        id: 10,
        title: 'Project Requirements Specification',
        fileName: 'spec.txt',
        mimeType: 'text/plain',
        fileSizeBytes: 1024,
        formattedSize: '1.0 KB',
        isImage: false,
        isPdf: false,
        isText: true,
        hasExtractedText: true,
        extractedText: 'Phase 1: Database schemas\nPhase 2: API routes\nPhase 3: Unit testing',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResourcePreviewModal(resource: resource),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Project Requirements Specification'), findsOneWidget);
      expect(find.text('TXT'), findsOneWidget);
      expect(find.textContaining('Phase 1: Database schemas'), findsOneWidget);
      expect(find.text('COPY TEXT'), findsOneWidget);
      expect(find.text('CLOSE'), findsOneWidget);

      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      final shape = dialog.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, equals(BorderRadius.zero));
    });
  });

  group('Phase S6: Gemini AI Study Assistant', () {
    final testCourse = CourseClass(
      id: 1,
      courseName: 'Distributed Systems',
      teacherName: 'Dr. Leslie Lamport',
      creditHours: 4,
      ects: 6.0,
    );

    final testAssignment = Assignment(
      id: 99,
      classId: 1,
      title: 'Raft Consensus Implementation',
      description: 'Implement leader election and log replication.',
      status: 'in_progress',
      deadline: DateTime.now().add(const Duration(days: 3)),
      urgency: {'label': 'UPCOMING', 'color': 'gray', 'is_overdue': false},
      courseClass: testCourse,
    );

    testWidgets('AssignmentAiChatSheet shows locked state when user lacks Genius tier', (WidgetTester tester) async {
      final tokenStorage = TokenStorage(inMemoryOnly: true);
      final apiClient = ApiClient(tokenStorage: tokenStorage);
      final subProvider = SubscriptionProvider(apiClient: apiClient);
      final aiChatProvider = AiChatProvider(apiClient: apiClient);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: subProvider),
            ChangeNotifierProvider.value(value: aiChatProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AssignmentAiChatSheet(assignment: testAssignment),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('DUE COPILOT'), findsOneWidget);
      expect(find.text('GEMINI 1.5 FLASH'), findsOneWidget);
      expect(find.text('GENIUS TIER REQUIRED'), findsOneWidget);
      expect(find.text('UPGRADE TO GENIUS (\$9.99/MO)'), findsOneWidget);
    });

    testWidgets('AssignmentAiChatSheet renders chat interface when user has Genius tier', (WidgetTester tester) async {
      final tokenStorage = TokenStorage(inMemoryOnly: true);
      final apiClient = ApiClient(tokenStorage: tokenStorage);
      final aiChatProvider = AiChatProvider(apiClient: apiClient);

      expect(aiChatProvider.messages, isEmpty);
      expect(aiChatProvider.totalTokens, equals(0));
    });
  });
}
