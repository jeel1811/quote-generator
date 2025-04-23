import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        _isInitialized = true;
        _initializeNotifications();
      }
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      // Don't show error dialog here as it might be disruptive on startup
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (_isLoading) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;

    // Use microtask to avoid setState during build
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
    });

    try {
      // Update user preferences in Firestore
      await authProvider.updateUserSettings(notificationsEnabled: value);

      // Toggle notifications
      await _notificationService.toggleNotifications(value);

      // Schedule notification if enabled
      if (value) {
        await _notificationService.scheduleDailyQuoteNotification();
      }
    } catch (e) {
      if (mounted) {
        Future.microtask(() {
          if (mounted) {
            _showErrorDialog('Error updating settings: ${e.toString()}');
          }
        });
      }
    } finally {
      if (mounted) {
        Future.microtask(() {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      }
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Toggle theme
    themeProvider.toggleTheme();

    // Update user preferences if logged in
    if (authProvider.isAuthenticated && authProvider.user != null) {
      try {
        await authProvider.updateUserSettings(isDarkMode: value);
      } catch (e) {
        if (mounted) {
          Future.microtask(() {
            if (mounted) {
              _showErrorDialog('Error updating settings: ${e.toString()}');
            }
          });
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () async {
                  Navigator.pop(context);
                  await authProvider.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.user;

    if (!authProvider.isAuthenticated) {
      return _buildUnauthenticatedState();
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Profile')),
      child: SafeArea(
        child:
            _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // User info card
                        _buildInfoBox(
                          child: Row(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: CupertinoColors.activeBlue,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: CupertinoColors.systemGrey
                                          .withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    user?.displayName != null &&
                                            user!.displayName.isNotEmpty
                                        ? user.displayName
                                            .substring(0, 1)
                                            .toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: CupertinoColors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (user?.displayName != null &&
                                              user!.displayName.isNotEmpty)
                                          ? user.displayName
                                          : 'User',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user?.email ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: CupertinoColors.systemGrey
                                            .resolveFrom(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Settings section
                        _buildSectionHeader('Settings'),

                        // Settings box
                        _buildInfoBox(
                          child: Column(
                            children: [
                              // Dark mode toggle
                              _buildSettingRow(
                                title: 'Dark Mode',
                                subtitle: 'Toggle between light and dark theme',
                                icon:
                                    themeProvider.isDarkMode
                                        ? CupertinoIcons.moon_fill
                                        : CupertinoIcons.sun_max,
                                value: themeProvider.isDarkMode,
                                onChanged: (value) {
                                  // Use microtask to avoid setState during build
                                  Future.microtask(
                                    () => _toggleDarkMode(value),
                                  );
                                },
                              ),

                              _buildDivider(),

                              // Notifications toggle
                              _buildSettingRow(
                                title: 'Daily Quote Notifications',
                                subtitle: 'Receive a daily inspirational quote',
                                icon: CupertinoIcons.bell,
                                value: user?.notificationsEnabled ?? false,
                                onChanged: (value) {
                                  // Use microtask to avoid setState during build
                                  Future.microtask(
                                    () => _toggleNotifications(value),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // App info section
                        _buildSectionHeader('About'),

                        // App info box
                        _buildInfoBox(
                          child: Column(
                            children: [
                              _buildInfoRow(
                                title: 'Version',
                                subtitle: '1.0.0',
                                icon: CupertinoIcons.info_circle,
                              ),

                              _buildDivider(),

                              _buildTappableRow(
                                title: 'Terms of Service',
                                icon: CupertinoIcons.doc_text,
                                onTap: () {
                                  // TODO: Implement terms of service screen
                                },
                              ),

                              _buildDivider(),

                              _buildTappableRow(
                                title: 'Privacy Policy',
                                icon: CupertinoIcons.shield,
                                onTap: () {
                                  // TODO: Implement privacy policy screen
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Logout button
                        CupertinoButton(
                          color: CupertinoColors.destructiveRed,
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          onPressed: () {
                            // Use microtask to avoid potential issues
                            Future.microtask(
                              () => _showLogoutDialog(context, authProvider),
                            );
                          },
                          child: SizedBox(
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(CupertinoIcons.square_arrow_left),
                                SizedBox(width: 8),
                                Text(
                                  'Logout',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildSettingRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: CupertinoTheme.of(context).primaryColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        CupertinoTheme.of(context).brightness == Brightness.dark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: CupertinoTheme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: CupertinoTheme.of(context).primaryColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        CupertinoTheme.of(context).brightness == Brightness.dark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTappableRow({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        // Use microtask to avoid calling during build
        Future.microtask(onTap);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: CupertinoTheme.of(context).primaryColor,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      CupertinoTheme.of(context).brightness == Brightness.dark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: CupertinoTheme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildInfoBox({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color:
            CupertinoTheme.of(context).brightness == Brightness.dark
                ? CupertinoColors.systemBackground.darkColor
                : CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: child,
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: CupertinoColors.systemGrey4.resolveFrom(context),
      height: 1,
    );
  }

  Widget _buildUnauthenticatedState() {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Profile')),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.person_crop_circle_badge_exclam,
                  size: 80,
                  color: CupertinoColors.systemGrey,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Not Logged In',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please log in to view and manage your profile',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CupertinoButton.filled(
                  onPressed:
                      () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
