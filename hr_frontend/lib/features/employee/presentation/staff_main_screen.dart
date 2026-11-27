// lib/features/employee/presentation/staff_main_screen.dart
//
// StaffMainScreen — shell for STAFF role.
// Bottom nav: Dashboard / Attendance / Leaves / Profile
// Drawer: My Payslips, My Reviews
// No team data, no management actions — personal data only.

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../main.dart' show themeNotifier;
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
  String _userId = '';
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
      _userId = prefs.getString('user_id') ?? '';
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
            userId: _userId,
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
                      .copyWith(color: AppTheme.textSecondary(context), letterSpacing: 1)),
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
                      .copyWith(color: AppTheme.textSecondary(context), letterSpacing: 1)),
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
                        color: selected ? color : AppTheme.textPrimary(context),
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
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border(context), width: 0.5)),
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
          color: selected ? AppColors.primary : AppTheme.textSecondary(context),
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
class _ProfilePage extends StatefulWidget {
  final String userId, userRole, userEmail, firstName, lastName;
  final VoidCallback onLogout;

  const _ProfilePage({
    required this.userId,
    required this.userRole,
    required this.userEmail,
    required this.firstName,
    required this.lastName,
    required this.onLogout,
  });

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  bool _uploading = false;
  String? _photoPath; // local path returned by server

  @override
  void initState() {
    super.initState();
    _loadExistingPhoto();
  }

  Future<void> _loadExistingPhoto() async {
    if (widget.userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      final dio = GetIt.instance<Dio>();
      final res = await dio.get(
        AppConstants.employeeProfileEndpoint(widget.userId),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final path = res.data['photo_path'] as String?;
      if (mounted && path != null && path.isNotEmpty) {
        setState(() => _photoPath = path);
      }
    } catch (_) {
      // Silently ignore — just show initials if profile can't be fetched
    }
  }

  String get _displayName => widget.firstName.isNotEmpty
      ? '${widget.firstName} ${widget.lastName}'.trim()
      : widget.userEmail.split('@').first;

  String get _initials {
    if (widget.firstName.isNotEmpty) {
      return (widget.firstName[0] +
              (widget.lastName.isNotEmpty ? widget.lastName[0] : ''))
          .toUpperCase();
    }
    return widget.userEmail.isNotEmpty
        ? widget.userEmail[0].toUpperCase()
        : 'S';
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      final dio = GetIt.instance<Dio>();

      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          picked.path,
          filename: picked.name,
        ),
      });

      final res = await dio.post(
        AppConstants.employeePhotoEndpoint(widget.userId),
        data: form,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (mounted) {
        setState(() => _photoPath = res.data['photo_path']);
        _snack('Photo updated', isError: false);
      }
    } catch (_) {
      if (mounted) _snack('Upload failed — try again');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removePhoto() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove photo?'),
        content: const Text('Your profile photo will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _uploading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      final dio = GetIt.instance<Dio>();
      await dio.delete(
        AppConstants.employeePhotoEndpoint(widget.userId),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (mounted) {
        setState(() => _photoPath = null);
        _snack('Photo removed', isError: false);
      }
    } catch (_) {
      if (mounted) _snack('Failed to remove photo');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _snack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  Future<void> _toggleTheme() async {
    final isDark = themeNotifier.value == ThemeMode.dark;
    themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', isDark ? 'light' : 'dark');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E2130) : AppColors.surface;
    final borderColor = isDark ? const Color(0xFF334155) : AppColors.border;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Avatar section ────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(bottom: BorderSide(color: borderColor)),
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        // Avatar circle
                        Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            gradient: _photoPath == null
                                ? const LinearGradient(
                                    colors: [AppColors.primary, AppColors.primaryDark],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: _photoPath != null ? Colors.transparent : null,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 16, offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _uploading
                                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : (_photoPath != null
                                    ? Image.network(
                                        '${AppConstants.baseUrl}/uploads/photos/${_photoPath!.split('/').last}',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => _initialsWidget(),
                                      )
                                    : _initialsWidget()),
                          ),
                        ),
                        // Camera button
                        GestureDetector(
                          onTap: _uploading ? null : _pickAndUpload,
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: surfaceColor, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    if (_photoPath != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _uploading ? null : _removePhoto,
                        icon: const Icon(Icons.delete_outline, size: 14, color: AppColors.error),
                        label: const Text('Remove photo',
                            style: TextStyle(fontSize: 12, color: AppColors.error)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(_displayName, style: AppTextStyles.displaySmall),
                    const SizedBox(height: 4),
                    Text(widget.userEmail, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 12),
                    AppTheme.roleBadge(widget.userRole),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // ── Account info ──────────────────────────
                    _SectionLabel('Account'),
                    const SizedBox(height: 10),
                    _InfoCard(children: [
                      _InfoRow(Icons.email_outlined, 'Email', widget.userEmail),
                      const Divider(height: 1),
                      _InfoRow(Icons.badge_outlined, 'Role', widget.userRole),
                    ]),
                    const SizedBox(height: 20),

                    // ── Appearance ────────────────────────────
                    _SectionLabel('Appearance'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: AppTheme.cardDecorationOf(context, radius: 14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Icon(
                              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              size: 18, color: AppTheme.textSecondary(context),
                            ),
                            const SizedBox(width: 12),
                            Text('Dark Mode', style: AppTextStyles.bodyMedium),
                            const Spacer(),
                            ValueListenableBuilder<ThemeMode>(
                              valueListenable: themeNotifier,
                              builder: (_, mode, _) => Switch.adaptive(
                                value: mode == ThemeMode.dark,
                                onChanged: (_) => _toggleTheme(),
                                activeThumbColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Sign out ──────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: AppTheme.dangerButtonStyle(radius: 12),
                        onPressed: widget.onLogout,
                        icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white),
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

  Widget _initialsWidget() => Center(
        child: Text(_initials,
            style: const TextStyle(
                color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
      );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Text(label.toUpperCase(),
            style: AppTextStyles.labelBold
                .copyWith(color: AppTheme.textSecondary(context), letterSpacing: 1)),
      );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        decoration: AppTheme.cardDecorationOf(context, radius: 14),
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
            Icon(icon, size: 18, color: AppTheme.textSecondary(context)),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.bodyMedium),
            const Spacer(),
            Text(value,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
