import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'services/api_client.dart';
import 'services/token_storage.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/metric_card.dart';
import 'widgets/urgency_badge.dart';
import 'widgets/zero_button.dart';
import 'widgets/zero_card.dart';
import 'widgets/zero_text_field.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<ApiClient>.value(value: apiClient),
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
      home: const ArchitectureCoreScreen(),
    );
  }
}

/// Phase M2 Verification Screen demonstrating Due's zero-radius design tokens & components
class ArchitectureCoreScreen extends StatelessWidget {
  const ArchitectureCoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Architectural Header
            const Text(
              'ARCHITECTURAL SYSTEM',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: AppColors.coral,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Strict 0-Radius Mobile Core',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),

            // Metrics Grid
            const Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: 'Pending',
                    value: '12',
                    icon: Icons.access_time,
                    accentColor: AppColors.warning,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    label: 'Overdue',
                    value: '02',
                    icon: Icons.warning_amber,
                    accentColor: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Urgency Badges Showcase
            const ZeroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'URGENCY PROTOCOLS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkTextSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      UrgencyBadge(label: 'OVERDUE', isOverdue: true),
                      UrgencyBadge(label: 'DUE TODAY'),
                      UrgencyBadge(label: 'DUE SOON'),
                      UrgencyBadge(label: 'UPCOMING'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Form Field Showcase
            const ZeroTextField(
              label: 'TEST INPUT',
              hintText: 'Architectural sharp field...',
            ),
            const SizedBox(height: 20),

            // Buttons Showcase
            Row(
              children: [
                Expanded(
                  child: ZeroButton(
                    label: 'PRIMARY BUTTON',
                    variant: ZeroButtonVariant.primary,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ZeroButton(
                    label: 'OUTLINE',
                    variant: ZeroButtonVariant.outline,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
