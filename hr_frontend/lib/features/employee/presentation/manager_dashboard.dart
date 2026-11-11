// lib/features/employee/presentation/manager_dashboard.dart
//
// ManagerDashboard — team-oriented overview for MANAGER role.
// Shows workforce stats, pending leave approvals, attendance summary,
// and quick links to performance & payroll.  Manager can see all team
// data but cannot add/delete employees (ADMIN-only).

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../data/employee_api_service.dart';
import '../data/models/employee_model.dart';
import '../../leave/data/leave_api_service.dart';
import '../../attendance/data/attendance_api_service.dart';
import '../../attendance/data/models/attendance_model.dart';

class ManagerDashboardScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const ManagerDashboardScreen({super.key, this.onMenuTap});

  @override
  State<ManagerDashboardScreen> createState() =>
      _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  final EmployeeApiService _empService = GetIt.instance<EmployeeApiService>();
  final LeaveApiService _leaveService = GetIt.instance<LeaveApiService>();
  final AttendanceApiService _attService =
      GetIt.instance<AttendanceApiService>();

  List<Employee> _employees = [];
  List<AttendanceModel> _attendances = [];
  bool _loading = true;
  String _error = '';
  String _userName = '';

  int _leavePending = 0;
  int _leaveApproved = 0;
  int _leaveRejected = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('first_name') ??
          (prefs.getString('email')?.split('@').first ?? 'Manager');
    });
    await Future.wait([_loadEmployees(), _loadLeaveStats(), _loadAttendances()]);
  }

  Future<void> _loadEmployees() async {
    final result = await _empService.getEmployees();
    if (!mounted) return;
    result.fold(
      (f) => setState(() { _loading = false; _error = f.message; }),
      (list) => setState(() { _employees = list; _loading = false; }),
    );
  }

  Future<void> _loadLeaveStats() async {
    final result = await _leaveService.getLeaveStats();
    if (!mounted) return;
    result.fold((_) {}, (stats) => setState(() {
          _leavePending = stats['pending'] ?? 0;
          _leaveApproved = stats['approved'] ?? 0;
          _leaveRejected = stats['rejected'] ?? 0;
        }));
  }

  Future<void> _loadAttendances() async {
    final result = await _attService.getAttendances();
    if (!mounted) return;
    result.fold((_) {}, (list) => setState(() => _attendances = list));
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await Future.wait([_loadEmployees(), _loadLeaveStats(), _loadAttendances()]);
  }

  int get _managerCount =>
      _employees.where((e) => e.role == 'MANAGER').length;
  int get _staffCount => _employees.where((e) => e.role == 'STAFF').length;
  int get _presentToday =>
      _attendances.where((a) => a.status == 'PRESENT').length;
  int get _lateToday =>
      _attendances.where((a) => a.status == 'LATE').length;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _loadingView();
    if (_error.isNotEmpty) return _errorView();
    return _body();
  }

  Widget _body() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: const Color(0xFFEA580C),
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 172,
              floating: false,
              pinned: true,
              snap: false,
              backgroundColor: const Color(0xFFEA580C),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: widget.onMenuTap,
                tooltip: 'Menu',
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: _refresh,
                  tooltip: 'Refresh',
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFC2410C), Color(0xFFEA580C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('$_greeting 👋',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              )),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _userName.length > 1
                                      ? '${_userName[0].toUpperCase()}${_userName.substring(1)}'
                                      : _userName.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              AppTheme.roleBadge('MANAGER'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Team overview stats ──────────────────────────────
            SliverToBoxAdapter(
              child: _TeamStatSection(
                totalStaff: _staffCount,
                managers: _managerCount,
                presentToday: _presentToday,
                lateToday: _lateToday,
              ),
            ),

            // ── Leave approval queue ─────────────────────────────
            SliverToBoxAdapter(
              child: _LeaveApprovalSection(
                pending: _leavePending,
                approved: _leaveApproved,
                rejected: _leaveRejected,
              ),
            ),

            // ── Quick actions ─────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildQuickActions(context),
            ),

            // ── Team directory preview ──────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Team Members',
                          style: AppTextStyles.titleMedium),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_employees.length} total',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFFEA580C),
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _TeamMemberCard(employee: _employees[i]),
                  childCount: _employees.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 13, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text('QUICK ACTIONS',
                  style: AppTextStyles.labelBold
                      .copyWith(color: AppColors.textHint, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionChip(
                  icon: Icons.beach_access_rounded,
                  label: 'Review\nLeaves',
                  color: const Color(0xFFEA580C),
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionChip(
                  icon: Icons.star_rounded,
                  label: 'Performance',
                  color: AppColors.primary,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionChip(
                  icon: Icons.payments_rounded,
                  label: 'Payroll',
                  color: const Color(0xFF7C3AED),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _loadingView() => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFEA580C)),
        ),
      );

  Widget _errorView() => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: AppTheme.errorState(
            message: _error,
            onRetry: _refresh,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────
//  Team stat section
// ─────────────────────────────────────────────────────────────────
class _TeamStatSection extends StatelessWidget {
  final int totalStaff, managers, presentToday, lateToday;
  const _TeamStatSection({
    required this.totalStaff,
    required this.managers,
    required this.presentToday,
    required this.lateToday,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_rounded, size: 13, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text('TEAM OVERVIEW',
                  style: AppTextStyles.labelBold
                      .copyWith(color: AppColors.textHint, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard('Staff', '$totalStaff',
                  Icons.person_rounded, const Color(0xFF16A34A))),
              const SizedBox(width: 10),
              Expanded(child: _StatCard('Managers', '$managers',
                  Icons.manage_accounts_rounded, const Color(0xFFEA580C))),
              const SizedBox(width: 10),
              Expanded(child: _StatCard('Present', '$presentToday',
                  Icons.check_circle_rounded, AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard('Late', '$lateToday',
                  Icons.schedule_rounded, AppColors.warning)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: AppTheme.statCardDecoration(color),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.1)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.captionText,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Leave approval section
// ─────────────────────────────────────────────────────────────────
class _LeaveApprovalSection extends StatelessWidget {
  final int pending, approved, rejected;
  const _LeaveApprovalSection({
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.beach_access_rounded,
                  size: 13, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text('LEAVE APPROVAL QUEUE',
                  style: AppTextStyles.labelBold
                      .copyWith(color: AppColors.textHint, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _LeaveChip('Pending', pending, AppColors.warning)),
              const SizedBox(width: 10),
              Expanded(child: _LeaveChip('Approved', approved, AppColors.success)),
              const SizedBox(width: 10),
              Expanded(child: _LeaveChip('Rejected', rejected, AppColors.error)),
            ],
          ),
          if (pending > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions_rounded,
                      size: 18, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$pending leave request(s) awaiting your approval',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LeaveChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _LeaveChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text('$count',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.1)),
          const SizedBox(height: 3),
          Text(label,
              style: AppTextStyles.captionText.copyWith(color: color),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Action chip
// ─────────────────────────────────────────────────────────────────
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: AppTheme.cardDecoration(radius: 14),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Team member card
// ─────────────────────────────────────────────────────────────────
class _TeamMemberCard extends StatelessWidget {
  final Employee employee;
  const _TeamMemberCard({required this.employee});

  String get _initials =>
      ((employee.firstName.isNotEmpty ? employee.firstName[0] : '') +
              (employee.lastName.isNotEmpty ? employee.lastName[0] : ''))
          .toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration(radius: 14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFEA580C).withValues(alpha: 0.1),
              child: Text(_initials,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEA580C),
                      fontSize: 15)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(employee.fullName, style: AppTextStyles.titleSmall),
                  const SizedBox(height: 2),
                  Text(employee.position, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 2),
                  Text(employee.email,
                      style: AppTextStyles.captionText,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            AppTheme.roleBadge(employee.role),
          ],
        ),
      ),
    );
  }
}
