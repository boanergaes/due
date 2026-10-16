import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/due_copilot_drawer.dart';
import '../widgets/upgrade_plan_dialog.dart';
import '../widgets/zero_button.dart';
import '../widgets/zero_card.dart';
import '../widgets/zero_text_field.dart';
import 'assignments/assignments_list_screen.dart';
import 'courses/courses_list_screen.dart';
import 'dashboard/dashboard_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      DashboardScreen(
        onNavigateToAssignments: () => _onTabSelected(2),
        onNavigateToCourses: () => _onTabSelected(1),
      ),
      const CoursesListScreen(),
      const AssignmentsListScreen(),
      const _SettingsScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const DueCopilotDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                label: 'DASHBOARD',
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
              ),
              _buildNavItem(
                index: 1,
                label: 'COURSES',
                icon: Icons.school_outlined,
                activeIcon: Icons.school,
              ),
              _buildNavItem(
                index: 2,
                label: 'ASSIGNMENTS',
                icon: Icons.assignment_outlined,
                activeIcon: Icons.assignment,
              ),
              _buildNavItem(
                index: 3,
                label: 'SETTINGS',
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isSelected ? AppColors.coral : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 20,
                color: isSelected
                    ? AppColors.coral
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  letterSpacing: 0.5,
                  fontFamily: 'monospace',
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsScreen extends StatefulWidget {
  const _SettingsScreen();

  @override
  State<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
  // Profile CRUD
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isUpdatingProfile = false;
  String? _profileError;
  String? _profileSuccess;

  // Password CRUD
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isUpdatingPassword = false;
  String? _passwordError;
  String? _passwordSuccess;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().fetchSubscription();
      final user = context.read<AuthProvider>().user;
      if (user != null && !_initialized) {
        _nameController.text = user.name;
        _emailController.text = user.email;
        _initialized = true;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      setState(() {
        _profileError = 'Name and email cannot be blank.';
        _profileSuccess = null;
      });
      return;
    }

    setState(() {
      _isUpdatingProfile = true;
      _profileError = null;
      _profileSuccess = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(name: name, email: email);

    if (!mounted) return;
    setState(() {
      _isUpdatingProfile = false;
      if (success) {
        _profileSuccess = 'Profile updated successfully.';
        _profileError = null;
      } else {
        _profileError = auth.errorMessage ?? 'Failed to update profile.';
        _profileSuccess = null;
      }
    });
  }

  Future<void> _handleUpdatePassword() async {
    final current = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      setState(() {
        _passwordError = 'All password fields are required.';
        _passwordSuccess = null;
      });
      return;
    }

    if (newPass.length < 8) {
      setState(() {
        _passwordError = 'New password must be at least 8 characters.';
        _passwordSuccess = null;
      });
      return;
    }

    if (newPass != confirm) {
      setState(() {
        _passwordError = 'New password and confirmation do not match.';
        _passwordSuccess = null;
      });
      return;
    }

    setState(() {
      _isUpdatingPassword = true;
      _passwordError = null;
      _passwordSuccess = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.updatePassword(
      currentPassword: current,
      newPassword: newPass,
      confirmPassword: confirm,
    );

    if (!mounted) return;
    setState(() {
      _isUpdatingPassword = false;
      if (success) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _passwordSuccess = 'Password updated successfully.';
        _passwordError = null;
      } else {
        _passwordError = auth.errorMessage ?? 'Failed to update password.';
        _passwordSuccess = null;
      }
    });
  }


  Future<void> _handleDeleteAccount() async {
    final passwordController = TextEditingController();
    String? dialogError;
    bool isDeleting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'DELETE ACCOUNT',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Once your student account is deleted, all courses, coursework assignments, study notes, and storage resources are permanently eradicated. This action cannot be undone.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Enter your password to confirm deletion:',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ZeroTextField(
                      controller: passwordController,
                      obscureText: true,
                      hintText: 'Current password',
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        dialogError!,
                        style: const TextStyle(color: AppColors.danger, fontFamily: 'monospace', fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.of(dialogCtx).pop(),
                  child: const Text('CANCEL', style: TextStyle(fontFamily: 'monospace')),
                ),
                ZeroButton(
                  label: isDeleting ? 'DELETING...' : 'DELETE PERMANENTLY',
                  variant: ZeroButtonVariant.danger,
                  onPressed: isDeleting
                      ? null
                      : () async {
                          final pass = passwordController.text;
                          if (pass.isEmpty) {
                            setDialogState(() {
                              dialogError = 'Password is required.';
                            });
                            return;
                          }
                          setDialogState(() {
                            isDeleting = true;
                            dialogError = null;
                          });

                          final auth = context.read<AuthProvider>();
                          final nav = Navigator.of(dialogCtx);
                          final success = await auth.deleteAccount(password: pass);

                          if (success) {
                            nav.pop();
                          } else {
                            setDialogState(() {
                              isDeleting = false;
                              dialogError = auth.errorMessage ?? 'Failed to delete account.';
                            });
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleCancelSubscription() async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Cancel Subscription?',
      message: 'Are you sure you want to cancel your plan? Your account will return to the Free tier at period end.',
      confirmText: 'CONFIRM CANCELLATION',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      final success = await context.read<SubscriptionProvider>().cancelSubscription();
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Subscription cancelled. Returned to Free tier.',
              style: TextStyle(fontFamily: 'monospace'),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final subProvider = context.watch<SubscriptionProvider>();

    final user = authProvider.user;
    final isDark = themeProvider.isDarkMode;
    final subInfo = subProvider.subscriptionInfo;

    // Sync controllers if user name changed externally and fields are pristine
    if (user != null && !_initialized) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SETTINGS & PROFILE',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 15,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Due Copilot (Gemini AI)',
            icon: const Icon(Icons.smart_toy_outlined, color: AppColors.coral),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: Student Profile Information
            ZeroCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PROFILE INFORMATION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: AppColors.coral.withValues(alpha: 0.12),
                        child: const Text(
                          'STUDENT',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.coral,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Update your full name and primary university email address.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_profileError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: AppColors.danger.withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _profileError!,
                              style: const TextStyle(color: AppColors.danger, fontFamily: 'monospace', fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_profileSuccess != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: AppColors.success.withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _profileSuccess!,
                              style: const TextStyle(color: AppColors.success, fontFamily: 'monospace', fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  ZeroTextField(
                    label: 'FULL NAME',
                    controller: _nameController,
                    hintText: 'Full name',
                  ),
                  const SizedBox(height: 12),

                  ZeroTextField(
                    label: 'EMAIL ADDRESS',
                    controller: _emailController,
                    hintText: 'Email address',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  ZeroButton(
                    label: _isUpdatingProfile ? 'SAVING...' : 'SAVE PROFILE',
                    variant: ZeroButtonVariant.primary,
                    icon: Icons.check,
                    onPressed: _isUpdatingProfile ? null : _handleUpdateProfile,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 2: Security & Password Update
            ZeroCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SECURITY & PASSWORD',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ensure your account uses a secure password of 8+ characters.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_passwordError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: AppColors.danger.withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _passwordError!,
                              style: const TextStyle(color: AppColors.danger, fontFamily: 'monospace', fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_passwordSuccess != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: AppColors.success.withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _passwordSuccess!,
                              style: const TextStyle(color: AppColors.success, fontFamily: 'monospace', fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  ZeroTextField(
                    label: 'CURRENT PASSWORD',
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrent,
                    hintText: 'Enter current password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                      onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ZeroTextField(
                    label: 'NEW PASSWORD',
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    hintText: 'Minimum 8 characters',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ZeroTextField(
                    label: 'CONFIRM PASSWORD',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    hintText: 'Re-enter new password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ZeroButton(
                    label: _isUpdatingPassword ? 'UPDATING...' : 'UPDATE PASSWORD',
                    variant: ZeroButtonVariant.outline,
                    icon: Icons.lock_outline,
                    onPressed: _isUpdatingPassword ? null : _handleUpdatePassword,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 4: Subscription & Cloud Storage
            ZeroCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SUBSCRIPTION & STORAGE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: subProvider.isGenius
                              ? AppColors.coral.withValues(alpha: 0.15)
                              : subProvider.isScholar
                                  ? AppColors.info.withValues(alpha: 0.15)
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          border: Border.all(
                            color: subProvider.isGenius
                                ? AppColors.coral
                                : subProvider.isScholar
                                    ? AppColors.info
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                        ),
                        child: Text(
                          subProvider.tierLabel.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: subProvider.isGenius
                                ? AppColors.coral
                                : subProvider.isScholar
                                    ? AppColors.info
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Storage Meter
                  if (subInfo != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'STORAGE QUOTA',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        Text(
                          '${subInfo.storage.usedFormatted} / ${subInfo.storage.limitFormatted} (${subInfo.storage.percentage}%)',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: LinearProgressIndicator(
                        value: (subInfo.storage.percentage / 100.0).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          subInfo.storage.percentage > 90 ? AppColors.danger : AppColors.coral,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Plan Perks Overview
                  Text(
                    subProvider.isGenius
                        ? 'Genius Tier active: Full study resources storage (5 GB) & unlimited Gemini AI assignment tutoring.'
                        : subProvider.isScholar
                            ? 'Scholar Tier active: Unlimited coursework resources storage (500 MB). Upgrade to Genius for Gemini AI.'
                            : 'Free Tier active: Core coursework management. Upgrade to unlock resources storage and Gemini AI.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: ZeroButton(
                          label: subProvider.isFree
                              ? 'UPGRADE TO SCHOLAR / GENIUS'
                              : 'CHANGE / MANAGE PLAN',
                          icon: Icons.bolt,
                          onPressed: () => UpgradePlanDialog.show(context),
                        ),
                      ),
                      if (!subProvider.isFree && subInfo?.activeSubscription != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined, size: 20, color: AppColors.danger),
                          tooltip: 'Cancel Subscription',
                          onPressed: _handleCancelSubscription,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 5: Appearance Preference (DB Synced)
            ZeroCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'APPEARANCE & THEME',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Synchronized across web and mobile via your student account.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            side: BorderSide(
                              color: isDark ? AppColors.coral : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              width: isDark ? 2 : 1,
                            ),
                          ),
                          onPressed: () => authProvider.updateAppearance('dark'),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.dark_mode_outlined, size: 16),
                              SizedBox(width: 6),
                              Text('DARK'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            side: BorderSide(
                              color: !isDark ? AppColors.coral : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              width: !isDark ? 2 : 1,
                            ),
                          ),
                          onPressed: () => authProvider.updateAppearance('light'),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.light_mode_outlined, size: 16),
                              SizedBox(width: 6),
                              Text('LIGHT'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 6: Danger Zone (Account Deletion)
            ZeroCard(
              backgroundColor: AppColors.danger.withValues(alpha: 0.08),
              borderColor: AppColors.danger.withValues(alpha: 0.4),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'DANGER ZONE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontFamily: 'monospace',
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Permanently delete your student account and all linked courses, assignments, and study materials.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.danger,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ZeroButton(
                    label: 'DELETE ACCOUNT',
                    variant: ZeroButtonVariant.danger,
                    icon: Icons.delete_forever,
                    onPressed: _handleDeleteAccount,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 7: Log Out Action
            ZeroButton(
              label: 'LOG OUT OF DUE',
              variant: ZeroButtonVariant.outline,
              icon: Icons.logout_outlined,
              onPressed: () => authProvider.logout(),
            ),
          ],
        ),
      ),
    );
  }
}

