// lib/features/employee/presentation/staff_main_screen.dart
//
// StaffMainScreen — shell for STAFF role.
// Bottom nav: Dashboard / Attendance / Leaves / Profile
// Drawer: My Payslips, My Reviews
// No team data, no management actions — personal data only.

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/login.dart';
import '../../attendance/presentation/attendance_screen.dart';
import '../../leave/data/leave_api_service.dart';
import '../../leave/presentation/leave_screen.dart';
import '../../payroll/presentation/payroll_screen.dart';
import '../../performance/presentation/performance_screen.dart';
import 'staff_dashboard.dart';

class StaffMainScreen extends StatefulWidget {
  const StaffMainScreen({super.key});

  @override
  State<StaffMainScreen> createState() => _StaffMainScreenState();
}

class _StaffMainScreenState extends State<StaffMainScreen> {
  int _navIndex = 0;
  int? _drawerIndex; // null = bottom-nav; 0 = Payslips, 1 = My Reviews

  String _userRole = 'STAFF';
  String _userEmail = '';
  String _firstName = '';
  String _lastName = '';
  int _pendingLeaves = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final LeaveApiService _leaveApiService = GetIt.instance<LeaveApiService>();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userRole = prefs.getString('role') ?? 'STAFF';
      _userEmail = prefs.getString('email') ?? '';
      _firstName = prefs.getString('first_name') ?? '';
      _lastName = prefs.getString('last_name') ?? '';
    });
    _refreshPendingLeaves();
  }

  Future<void> _refreshPendingLeaves() async {
    final result = await _leaveApiService.getLeaveStats();
    result.fold((_) {}, (stats) {
      if (mounted) setState(() => _pendingLeaves = stats['pending'] ?? 0);
    });
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  Widget get _activePage {
    if (_drawerIndex == 0) return const PayrollScreen();
    if (_drawerIndex == 1) return const PerformanceScreen();
    return switch (_navIndex) {
      0 => StaffDashboardScreen(onMenuTap: _openDrawer),
      1 => const AttendanceScreen(),
      2 => const LeaveScreen(),
      3 => _ProfilePage(
            userRole: _userRole,
            userEmail: _userEmail,
            firstName: _firstName,
            lastName: _lastName,
            onLogout: _logout,
          ),
      _ => StaffDashboardScreen(onMenuTap: _openDrawer),
    };
  }

  Future<void> _logout() async {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.errorLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 28),
        ),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of HR System?'),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
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
      key: _scaffoldKey,
      drawer: _StaffDrawer(
        userRole: _userRole,
        userEmail: _userEmail,
        firstName: _firstName,
        lastName: _lastName,
        drawerIndex: _drawerIndex,
        onSelectDrawer: (i) {
          setState(() => _drawerIndex = i);
          Navigator.pop(context);
        },
        onReload: () {
          setState(() { _drawerIndex = null; _navIndex = 0; });
          Navigator.pop(context);
        },
        onLogout: _logout,
      ),
      body: _activePage,
      bottomNavigationBar: _StaffBottomNav(
        currentIndex: _drawerIndex != null ? -1 : _navIndex,
        pendingLeaves: _pendingLeaves,
        onTap: (i) => setState(() { _navIndex = i; _drawerIndex = null; }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Drawer
// ─────────────────────────────────────────────────────────────────
class _StaffDrawer extends StatelessWidget {
  final String userRole, userEmail, firstName, lastName;
  final int? drawerIndex;
  final ValueChanged<int> onSelectDrawer;
  final VoidCallback onReload;
  final VoidCallback onLogout;

  const _StaffDrawer({
    required this.userRole,
    required this.userEmail,
    required this.firstName,
    required this.lastName,
    required this.drawerIndex,
    required this.onSelectDrawer,
    required this.onReload,
    required this.onLogout,
  });

  String get _displayName => firstName.isNotEmpty
      ? '$firstName $lastName'.trim()
      : userEmail.split('@').first;

  String get _initials {
    if (firstName.isNotEmpty) {
      return (firstName[0] + (lastName.isNotEmpty ? lastName[0] : '')).toUpperCase();
    }
    return userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'S';
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4), width: 2),
                        ),
                        child: Center(
                          child: Text(_initials,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_displayName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(userEmail,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppTheme.roleBadge(userRole),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('MY FEATURES',
                  style: AppTextStyles.labelBold
                      .copyWith(color: AppColors.textHint, letterSpacing: 1)),
            ),
            _DrawerItem(
              icon: Icons.payments_outlined,
              selectedIcon: Icons.payments_rounded,
              label: 'My Payslips',
              color: const Color(0xFF7C3AED),
              selected: drawerIndex == 0,
              onTap: () => onSelectDrawer(0),
            ),
            _DrawerItem(
              icon: Icons.star_outline_rounded,
              selectedIcon: Icons.star_rounded,
              label: 'My Reviews',
              color: AppColors.primary,
              selected: drawerIndex == 1,
              onTap: () => onSelectDrawer(1),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text('ACTIONS',
                  style: AppTextStyles.labelBold
                      .copyWith(color: AppColors.textHint, letterSpacing: 1)),
            ),
            _DrawerItem(
              icon: Icons.refresh_outlined,
              selectedIcon: Icons.refresh_rounded,
              label: 'Reload Dashboard',
              color: AppColors.success,
              selected: false,
              onTap: onReload,
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(),
            ),
            _DrawerItem(
              icon: Icons.logout_outlined,
              selectedIcon: Icons.logout_rounded,
              label: 'Sign Out',
              color: AppColors.error,
              selected: false,
              onTap: onLogout,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon, selectedIcon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.15)
                        : color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    color: color, size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: selected ? color : AppColors.textPrimary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      )),
                ),
                if (selected)
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Bottom Navigation
// ─────────────────────────────────────────────────────────────────
class _StaffBottomNav extends StatelessWidget {
  final int currentIndex;
  final int pendingLeaves;
  final ValueChanged<int> onTap;

  const _StaffBottomNav({
    required this.currentIndex,
    required this.pendingLeaves,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = currentIndex < 0 ? 0 : currentIndex;
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: NavigationBar(
        selectedIndex: active,
        onDestinationSelected: onTap,
        animationDuration: const Duration(milliseconds: 350),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
            tooltip: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.fingerprint_outlined),
            selectedIcon: Icon(Icons.fingerprint_rounded),
            label: 'Attendance',
            tooltip: 'Attendance',
          ),
          NavigationDestination(
            icon: _LeaveIcon(count: pendingLeaves, selected: false),
            selectedIcon: _LeaveIcon(count: pendingLeaves, selected: true),
            label: 'Leaves',
            tooltip: 'Leave Requests',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
            tooltip: 'My Profile',
          ),
        ],
      ),
    );
  }
}

class _LeaveIcon extends StatelessWidget {
  final int count;
  final bool selected;
  const _LeaveIcon({required this.count, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          selected ? Icons.beach_access_rounded : Icons.beach_access_outlined,
          color: selected ? AppColors.primary : AppColors.textHint,
        ),
        if (count > 0)
          Positioned(
            right: -8, top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 16),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Profile Page
// ─────────────────────────────────────────────────────────────────
class _ProfilePage extends StatelessWidget {
  final String userRole, userEmail, firstName, lastName;
  final VoidCallback onLogout;

  const _ProfilePage({
    required this.userRole,
    required this.userEmail,
    required this.firstName,
    required this.lastName,
    required this.onLogout,
  });

  String get _displayName => firstName.isNotEmpty
      ? '$firstName $lastName'.trim()
      : userEmail.split('@').first;

  String get _initials {
    if (firstName.isNotEmpty) {
      return (firstName[0] + (lastName.isNotEmpty ? lastName[0] : '')).toUpperCase();
    }
    return userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'S';
  }

  @override
  Widget build(BuildContext context) {
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  children: [
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
                        child: Text(_initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(_displayName, style: AppTextStyles.displaySmall),
                    const SizedBox(height: 4),
                    Text(userEmail, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 12),
                    AppTheme.roleBadge(userRole),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _SectionLabel('Account'),
                    const SizedBox(height: 10),
                    _InfoCard(children: [
                      _InfoRow(Icons.email_outlined, 'Email', userEmail),
                      const Divider(height: 1),
                      _InfoRow(Icons.badge_outlined, 'Role', userRole),
                    ]),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: AppTheme.dangerButtonStyle(radius: 12),
                        onPressed: onLogout,
                        icon: const Icon(Icons.logout_rounded,
                            size: 18, color: Colors.white),
                        label: const Text('Sign Out',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Text(label.toUpperCase(),
            style: AppTextStyles.labelBold
                .copyWith(color: AppColors.textHint, letterSpacing: 1)),
      );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        decoration: AppTheme.cardDecoration(radius: 14),
        child: Column(children: children),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textHint),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.bodyMedium),
            const Spacer(),
            Text(value,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
