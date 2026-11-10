// lib/features/employee/presentation/dashboard.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../data/employee_api_service.dart';
import '../data/models/employee_model.dart';
import '../../leave/data/leave_api_service.dart';
import 'add_employee.dart';
import 'employee_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const DashboardScreen({super.key, this.onMenuTap});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final EmployeeApiService   _empService   = GetIt.instance<EmployeeApiService>();
  final LeaveApiService      _leaveService = GetIt.instance<LeaveApiService>();
  final TextEditingController _searchCtrl  = TextEditingController();

  List<Employee> _all      = [];
  List<Employee> _filtered = [];
  bool   _loading  = true;
  String _error    = '';
  String _userRole = '';
  String _userName = '';

  int _leavePending  = 0;
  int _leaveApproved = 0;
  int _leaveRejected = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userRole = prefs.getString('role')  ?? 'STAFF';
      _userName = prefs.getString('first_name') ??
          (prefs.getString('email')?.split('@').first ?? 'User');
    });
    await Future.wait([_loadEmployees(), _loadLeaveStats()]);
  }

  Future<void> _loadEmployees() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = ''; });
    final result = await _empService.getEmployees();
    if (!mounted) return;
    result.fold(
      (f) => setState(() { _loading = false; _error = f.message; }),
      (list) => setState(() {
        _loading  = false;
        _all      = list;
        _filtered = list;
      }),
    );
  }

  Future<void> _loadLeaveStats() async {
    final result = await _leaveService.getLeaveStats();
    if (!mounted) return;
    result.fold((_) {}, (stats) => setState(() {
      _leavePending  = stats['pending']  ?? 0;
      _leaveApproved = stats['approved'] ?? 0;
      _leaveRejected = stats['rejected'] ?? 0;
    }));
  }

  Future<void> _refresh() async {
    await Future.wait([_loadEmployees(), _loadLeaveStats()]);
  }

  void _search(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filtered = _all.where((e) =>
          e.fullName.toLowerCase().contains(lower) ||
          e.email.toLowerCase().contains(lower) ||
          e.position.toLowerCase().contains(lower)).toList();
    });
  }

  Future<void> _deleteEmployee(String id) async {
    final result = await _empService.deleteEmployee(id);
    if (!mounted) return;
    result.fold(
      (f) => _snack(f.message, isError: true),
      (_) { _snack('Employee removed'); _loadEmployees(); },
    );
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  int get _adminCount   => _all.where((e) => e.role == 'ADMIN').length;
  int get _managerCount => _all.where((e) => e.role == 'MANAGER').length;
  int get _staffCount   => _all.where((e) => e.role == 'STAFF').length;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) return _loadingView();
    if (_error.isNotEmpty) return _errorView();
    return _body();
  }

  // ── Main body ─────────────────────────────────────────────────
  Widget _body() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            // ── Sliver App Bar (collapsible hero) ─────────────
            SliverAppBar(
              expandedHeight: 172,
              floating: false,
              pinned: true,
              snap: false,
              backgroundColor: AppColors.primary,
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
                      colors: [AppColors.primaryDark, AppColors.primary],
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
                              AppTheme.roleBadge(_userRole),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Summary stat cards ─────────────────────────────
            SliverToBoxAdapter(
              child: _StatSection(
                total: _all.length,
                admins: _adminCount,
                managers: _managerCount,
                staff: _staffCount,
              ),
            ),

            // ── Leave overview ─────────────────────────────────
            SliverToBoxAdapter(
              child: _LeaveOverview(
                pending: _leavePending,
                approved: _leaveApproved,
                rejected: _leaveRejected,
              ),
            ),

            // ── Search bar ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _search,
                  decoration: AppTheme.inputDecoration(
                    'Search by name, email or position…',
                    icon: Icons.search_rounded,
                    suffix: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _search('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // ── Directory header ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Employee Directory',
                          style: AppTextStyles.titleMedium),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_filtered.length} members',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Employee list ──────────────────────────────────
            _filtered.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppTheme.emptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No employees found',
                      subtitle: 'Try a different search term',
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _EmployeeCard(
                          employee: _filtered[i],
                          userRole: _userRole,
                          onDelete: _confirmDelete,
                        ),
                        childCount: _filtered.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
      floatingActionButton: _userRole == 'ADMIN'
          ? FloatingActionButton.extended(
              heroTag: 'add_emp',
              onPressed: () async {
                final added = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEmployeeScreen()),
                );
                if (added == true && mounted) _loadEmployees();
              },
              icon: const Icon(Icons.person_add_rounded, color: Colors.white),
              label: const Text('Add Employee',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
              color: AppColors.errorLight, shape: BoxShape.circle),
          child: const Icon(Icons.delete_forever_rounded,
              color: AppColors.error, size: 28),
        ),
        title: const Text('Remove Employee'),
        content: const Text(
          'This action cannot be undone. The employee record will be permanently deleted.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: AppTheme.dangerButtonStyle(),
            onPressed: () { Navigator.pop(ctx); _deleteEmployee(id); },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _loadingView() => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

  Widget _errorView() => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: AppTheme.errorState(
            message: _error,
            onRetry: _loadEmployees,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────
//  Stat Section
// ─────────────────────────────────────────────────────────────────
class _StatSection extends StatelessWidget {
  final int total, admins, managers, staff;
  const _StatSection({
    required this.total,
    required this.admins,
    required this.managers,
    required this.staff,
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
              Text('WORKFORCE OVERVIEW',
                  style: AppTextStyles.labelBold
                      .copyWith(color: AppColors.textHint, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard('Total', '$total',
                  Icons.groups_rounded, AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard('Admins', '$admins',
                  Icons.shield_rounded, AppColors.secondary)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard('Managers', '$managers',
                  Icons.manage_accounts_rounded, const Color(0xFFEA580C))),
              const SizedBox(width: 10),
              Expanded(child: _StatCard('Staff', '$staff',
                  Icons.person_rounded, AppColors.success)),
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
//  Leave Overview
// ─────────────────────────────────────────────────────────────────
class _LeaveOverview extends StatelessWidget {
  final int pending, approved, rejected;
  const _LeaveOverview({
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
              Text('LEAVE OVERVIEW',
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
//  Employee Card
// ─────────────────────────────────────────────────────────────────
class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final String userRole;
  final ValueChanged<String> onDelete;

  const _EmployeeCard({
    required this.employee,
    required this.userRole,
    required this.onDelete,
  });

  String get _initials =>
      ((employee.firstName.isNotEmpty ? employee.firstName[0] : '') +
       (employee.lastName.isNotEmpty  ? employee.lastName[0]  : '')).toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration(radius: 14),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EmployeeDetailScreen(employee: employee)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // ── Avatar ─────────────────────────────────────
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(_initials,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 15)),
                ),
                const SizedBox(width: 14),

                // ── Info ───────────────────────────────────────
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

                // ── Trailing ───────────────────────────────────
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppTheme.roleBadge(employee.role),
                    if (userRole == 'ADMIN') ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => onDelete(employee.id ?? ''),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              size: 16, color: AppColors.error),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
