import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sharp Architectural Brand Symbol
            Container(
              width: 56,
              height: 56,
              color: AppColors.coral,
              child: const Center(
                child: Text(
                  'D',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Wordmark
            const Text(
              'D U E',
              style: TextStyle(
                color: AppColors.darkTextPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'ACADEMIC WORKLOAD & DEADLINES',
              style: TextStyle(
                color: AppColors.darkTextMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 48),

            // Minimal Progress Indicator
            const SizedBox(
              width: 140,
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.darkSurfaceHover,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
