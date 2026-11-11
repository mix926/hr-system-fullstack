// lib/features/employee/presentation/admin_main_screen.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/login.dart';
import '../../attendance/presentation/attendance_screen.dart';
import '../../leave/data/leave_api_service.dart';
import '../../leave/presentation/leave_screen.dart';
import '../../performance/presentation/performance_screen.dart';
import '../../payroll/presentation/payroll_screen.dart';
import 'admin_dashboard.dart';

// ─────────────────────────────────────────────────────────────────
//  Shell — hosts BottomNav + Drawer + page switching
// ─────────────────────────────────────────────────────────────────
class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  // 0=Dashboard  1=Attendance  2=Leaves  3=Profile
  int _navIndex = 0;

  // null = bottom-nav controls content
  // 0   = Reviews   1 = Payroll
  int? _drawerIndex;

  String _userRole  = '';
  String _userEmail = '';
  String _firstName = '';
  String _lastName  = '';
  int    _pendingLeaves = 0;

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
      _userRole  = prefs.getString('role')       ?? 'STAFF';
      _userEmail = prefs.getString('email')      ?? '';
      _firstName = prefs.getString('first_name') ?? '';
      _lastName  = prefs.getString('last_name')  ?? '';
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

  // ── Page resolver ─────────────────────────────────────────────
  Widget get _activePage {
    if (_drawerIndex == 0) return const PerformanceScreen();
    if (_drawerIndex == 1) return const PayrollScreen();
    return switch (_navIndex) {
      0 => AdminDashboardScreen(onMenuTap: _openDrawer),
      1 => const AttendanceScreen(),
      2 => const LeaveScreen(),
      3 => _ProfilePage(
            userRole: _userRole,
            userEmail: _userEmail,
            firstName: _firstName,
            lastName: _lastName,
            onLogout: _logout,
          ),
      _ => AdminDashboardScreen(onMenuTap: _openDrawer),
    };
  }

  Future<void> _logout() async {
    // Close drawer if open
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.errorLight, shape: BoxShape.circle,
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
      drawer: _Drawer(
        userRole: _userRole,
        userEmail: _userEmail,
        firstName: _firstName,
        lastName: _lastName,
        drawerIndex: _drawerIndex,
        onSelectDrawer: (i) {
          setState(() { _drawerIndex = i; });
          Navigator.pop(context);
        },
        onReload: () {
          setState(() { _drawerIndex = null; _navIndex = 0; });
          Navigator.pop(context);
        },
        onLogout: _logout,
      ),
      body: _activePage,
      bottomNavigationBar: _BottomNav(
        currentIndex: _drawerIndex != null ? -1 : _navIndex,
        pendingLeaves: _pendingLeaves,
        onTap: (i) => setState(() { _navIndex = i; _drawerIndex = null; }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Navigation Drawer
// ─────────────────────────────────────────────────────────────────
class _Drawer extends StatelessWidget {
  final String userRole, userEmail, firstName, lastName;
  final int? drawerIndex;
  final ValueChanged<int> onSelectDrawer;
  final VoidCallback onReload;
  final VoidCallback onLogout;

  const _Drawer({
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
    return userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // ── User Header ───────────────────────────────────
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
                      // Avatar
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

            // ── Section: More Features ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('MORE FEATURES',
                  style: AppTextStyles.labelBold
                      .copyWith(color: AppColors.textHint, letterSpacing: 1)),
            ),

            _DrawerItem(
              icon: Icons.star_outline_rounded,
              selectedIcon: Icons.star_rounded,
              label: 'Performance Reviews',
              color: AppColors.primary,
              selected: drawerIndex == 0,
              onTap: () => onSelectDrawer(0),
            ),
            _DrawerItem(
              icon: Icons.payments_outlined,
              selectedIcon: Icons.payments_rounded,
              label: 'Payroll',
              color: const Color(0xFF7C3AED),
              selected: drawerIndex == 1,
              onTap: () => onSelectDrawer(1),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(),
            ),

            // ── Section: Actions ──────────────────────────────
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

            // ── Sign Out ──────────────────────────────────────
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
//  Bottom Navigation Bar
// ─────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;   // -1 when drawer page is active
  final int pendingLeaves;
  final ValueChanged<int> onTap;

  const _BottomNav({
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
    return userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U';
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
              // ── Hero ─────────────────────────────────────────
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

              // ── Info ─────────────────────────────────────────
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
                    const SizedBox(height: 20),

                    _SectionLabel('Settings'),
                    const SizedBox(height: 10),
                    _InfoCard(children: [
                      _TileRow(
                        icon: Icons.lock_outline_rounded,
                        label: 'Change Password',
                        onTap: () => _comingSoon(context, 'Change Password'),
                      ),
                      const Divider(height: 1),
                      _TileRow(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        onTap: () => _comingSoon(context, 'Notifications'),
                      ),
                      const Divider(height: 1),
                      _TileRow(
                        icon: Icons.language_outlined,
                        label: 'Language',
                        trailing: Text('English',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textHint)),
                        onTap: () => _comingSoon(context, 'Language'),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    _SectionLabel('About'),
                    const SizedBox(height: 10),
                    _InfoCard(children: [
                      _InfoRow(Icons.info_outline_rounded, 'Version', '1.0.0'),
                      const Divider(height: 1),
                      _InfoRow(Icons.corporate_fare_rounded,
                          'System', 'HR Management'),
                    ]),
                    const SizedBox(height: 28),

                    // Sign out
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

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature — coming soon'),
      backgroundColor: AppColors.warning,
    ));
  }
}

// ─── Profile sub-widgets ──────────────────────────────────────────
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

class _TileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  const _TileRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textHint),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
              trailing ??
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.textHint),
            ],
          ),
        ),
      );
}
