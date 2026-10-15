import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/login.dart';
import '../../attendance/presentation/attendance_screen.dart';
import '../../leave/data/leave_api_service.dart';
import '../../leave/presentation/leave_screen.dart';
import 'dashboard.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int    _currentIndex = 0;
  String _userRole     = '';
  String _userEmail    = '';
  String _firstName    = '';
  String _lastName     = '';
  int    _pendingLeaves = 0;

  final LeaveApiService _leaveApiService = GetIt.instance<LeaveApiService>();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole  = prefs.getString('role')       ?? 'STAFF';
      _userEmail = prefs.getString('email')      ?? '';
      _firstName = prefs.getString('first_name') ?? '';
      _lastName  = prefs.getString('last_name')  ?? '';
    });
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    final result = await _leaveApiService.getLeaveStats();
    result.fold((_) {}, (stats) {
      if (mounted) setState(() => _pendingLeaves = stats['pending'] ?? 0);
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.errorLight, shape: BoxShape.circle,
          ),
          child: const Icon(Icons.logout_rounded,
              color: AppColors.error, size: 28),
        ),
        title: const Text('Sign Out', style: AppTextStyles.titleLarge),
        content: Text(
          'Are you sure you want to sign out of HR System?',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: AppTheme.dangerButtonStyle(),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const DashboardScreen(),
          const AttendanceScreen(),
          const LeaveScreen(),
          _buildProfilePage(),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  // ── Bottom Navigation Bar ─────────────────────────────────────
  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryLight,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: AppColors.textHint),
            selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.fingerprint_outlined, color: AppColors.textHint),
            selectedIcon: Icon(Icons.fingerprint_rounded, color: AppColors.primary),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: _leaveIcon(false),
            selectedIcon: _leaveIcon(true),
            label: 'Leaves',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: AppColors.textHint),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ── Leave icon with badge ─────────────────────────────────────
  Widget _leaveIcon(bool selected) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          selected ? Icons.beach_access_rounded : Icons.beach_access_outlined,
          color: selected ? AppColors.primary : AppColors.textHint,
        ),
        if (_pendingLeaves > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                _pendingLeaves > 9 ? '9+' : '$_pendingLeaves',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  // ── Profile Page ──────────────────────────────────────────────
  Widget _buildProfilePage() {
    final displayName = _firstName.isNotEmpty
        ? '$_firstName $_lastName'.trim()
        : _userEmail.split('@').first;

    final initials = _firstName.isNotEmpty
        ? (_firstName[0] + (_lastName.isNotEmpty ? _lastName[0] : '')).toUpperCase()
        : _userEmail.isNotEmpty
            ? _userEmail[0].toUpperCase()
            : 'U';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Profile Hero ─────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 16, offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(displayName, style: AppTextStyles.displayMedium),
                    const SizedBox(height: 4),
                    Text(_userEmail,  style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 12),
                    AppTheme.roleBadge(_userRole),
                  ],
                ),
              ),

              // ── Info cards ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Account section
                    _buildSectionLabel('Account'),
                    const SizedBox(height: 10),
                    _buildInfoCard([
                      _infoRow(Icons.email_outlined,   'Email',    _userEmail),
                      const Divider(height: 1),
                      _infoRow(Icons.badge_outlined,   'Role',     _userRole),
                    ]),
                    const SizedBox(height: 20),

                    // Settings section
                    _buildSectionLabel('Settings'),
                    const SizedBox(height: 10),
                    _buildInfoCard([
                      _tileRow(
                        icon: Icons.lock_outline_rounded,
                        label: 'Change Password',
                        onTap: () => _showComingSoon('Change Password'),
                      ),
                      const Divider(height: 1),
                      _tileRow(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        onTap: () => _showComingSoon('Notifications'),
                      ),
                      const Divider(height: 1),
                      _tileRow(
                        icon: Icons.language_outlined,
                        label: 'Language',
                        trailing: Text('English',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textHint)),
                        onTap: () => _showComingSoon('Language'),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // About section
                    _buildSectionLabel('About'),
                    const SizedBox(height: 10),
                    _buildInfoCard([
                      _infoRow(Icons.info_outline_rounded, 'Version', '1.0.0'),
                      const Divider(height: 1),
                      _infoRow(Icons.corporate_fare_rounded, 'System', 'HR Management'),
                    ]),
                    const SizedBox(height: 28),

                    // Logout button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: AppTheme.dangerButtonStyle(radius: 12),
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded,
                            size: 18, color: Colors.white),
                        label: const Text('Sign Out',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profile helpers ───────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelBold.copyWith(
          color: AppColors.textHint, letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: AppTheme.cardDecoration(radius: 14),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textHint),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _tileRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textHint),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
            trailing ?? const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature — coming soon'),
      backgroundColor: AppColors.warning,
    ));
  }
}
