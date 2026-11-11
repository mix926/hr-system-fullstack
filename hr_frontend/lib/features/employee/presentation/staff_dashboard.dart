// lib/features/employee/presentation/staff_dashboard.dart
//
// StaffDashboard — personal overview for STAFF role.
// Shows the employee's own attendance, leave balance, payslips,
// and performance rating.  Staff sees ONLY their own data — no
// team directories, no management actions.

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../attendance/data/attendance_api_service.dart';
import '../../attendance/data/models/attendance_model.dart';
import '../../leave/data/leave_api_service.dart';
import '../../payroll/data/payroll_api_service.dart';
import '../../payroll/data/models/payroll_model.dart';
import '../../performance/data/performance_api_service.dart';
import '../../performance/data/models/performance_model.dart';

class StaffDashboardScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const StaffDashboardScreen({super.key, this.onMenuTap});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final AttendanceApiService _attService =
      GetIt.instance<AttendanceApiService>();
  final LeaveApiService _leaveService = GetIt.instance<LeaveApiService>();
  final PayrollApiService _payrollService = GetIt.instance<PayrollApiService>();
  final PerformanceApiService _perfService =
      GetIt.instance<PerformanceApiService>();

  bool _loading = true;
  String _userName = '';
  String _userRole = '';
  String _userEmail = '';

  // Personal stats
  List<AttendanceModel> _myAttendance = [];
  int _presentDays = 0;
  int _lateDays = 0;
  int _absentDays = 0;

  int _leavePending = 0;
  int _leaveApproved = 0;
  int _leaveRejected = 0;

  List<PayrollModel> _myPayrolls = [];
  List<PerformanceReview> _myReviews = [];

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
          (prefs.getString('email')?.split('@').first ?? 'Staff');
      _userRole = prefs.getString('role') ?? 'STAFF';
      _userEmail = prefs.getString('email') ?? '';
    });
    await Future.wait([
      _loadAttendance(),
      _loadLeaveStats(),
      _loadPayrolls(),
      _loadReviews(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadAttendance() async {
    final result = await _attService.getAttendances();
    if (!mounted) return;
    result.fold((_) {}, (list) {
      // Filter to current user's records
      setState(() {
        _myAttendance = list;
        _presentDays = list.where((a) => a.status == 'PRESENT').length;
        _lateDays = list.where((a) => a.status == 'LATE').length;
        _absentDays = list.where((a) => a.status == 'ABSENT').length;
      });
    });
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

  Future<void> _loadPayrolls() async {
    final result = await _payrollService.getPayrolls();
    if (!mounted) return;
    result.fold((_) {}, (list) => setState(() => _myPayrolls = list));
  }

  Future<void> _loadReviews() async {
    final result = await _perfService.getReviews();
    if (!mounted) return;
    result.fold((_) {}, (list) => setState(() => _myReviews = list));
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await Future.wait([
      _loadAttendance(),
      _loadLeaveStats(),
      _loadPayrolls(),
      _loadReviews(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  AttendanceModel? get _todayRecord {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    try {
      return _myAttendance.firstWhere((a) => a.date.startsWith(todayStr));
    } catch (_) {
      return null;
    }
  }

  String get _initials {
    if (_userName.isNotEmpty) {
      final parts = _userName.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return _userName[0].toUpperCase();
    }
    return _userEmail.isNotEmpty ? _userEmail[0].toUpperCase() : 'S';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _loadingView();
    return _body();
  }

  Widget _body() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            // ── Hero header ────────────────────────────────────────
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
                              // Avatar
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      width: 2),
                                ),
                                child: Center(
                                  child: Text(_initials,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800)),
                                ),
                              ),
                              const SizedBox(width: 12),
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

            // ── Today attendance card ──────────────────────────────
            SliverToBoxAdapter(
              child: _TodayAttendanceCard(todayRecord: _todayRecord),
            ),

            // ── My attendance stats ───────────────────────────────
            SliverToBoxAdapter(
              child: _MyAttendanceStats(
                present: _presentDays,
                late: _lateDays,
                absent: _absentDays,
              ),
            ),

            // ── My leave summary ───────────────────────────────────
            SliverToBoxAdapter(
              child: _MyLeaveSummary(
                pending: _leavePending,
                approved: _leaveApproved,
                rejected: _leaveRejected,
              ),
            ),

            // ── My payslip preview ────────────────────────────────
            SliverToBoxAdapter(
              child: _MyPayslipPreview(payrolls: _myPayrolls),
            ),

            // ── My performance summary ────────────────────────────
            SliverToBoxAdapter(
              child: _MyPerformanceSummary(reviews: _myReviews),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
      ),
    );
  }

  Widget _loadingView() => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────
//  Today attendance card
// ─────────────────────────────────────────────────────────────────
class _TodayAttendanceCard extends StatelessWidget {
  final AttendanceModel? todayRecord;
  const _TodayAttendanceCard({required this.todayRecord});

  @override
  Widget build(BuildContext context) {
    final hasCheckedIn = todayRecord?.checkInTime != null;
    final hasCheckedOut = todayRecord?.checkOutTime != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fingerprint_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('TODAY\'S ATTENDANCE',
                    style: AppTextStyles.labelBold.copyWith(
                        color: AppColors.textHint, letterSpacing: 0.8)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Check-in
                Expanded(
                  child: _TimeChip(
                    label: 'Check In',
                    time: todayRecord?.checkInTime ?? '--:--',
                    icon: Icons.login_rounded,
                    color: AppColors.success,
                    done: hasCheckedIn,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: AppColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                // Check-out
                Expanded(
                  child: _TimeChip(
                    label: 'Check Out',
                    time: todayRecord?.checkOutTime ?? '--:--',
                    icon: Icons.logout_rounded,
                    color: AppColors.error,
                    done: hasCheckedOut,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (todayRecord != null)
              Row(
                children: [
                  Icon(
                    todayRecord!.status == 'PRESENT'
                        ? Icons.check_circle_rounded
                        : todayRecord!.status == 'LATE'
                            ? Icons.schedule_rounded
                            : Icons.cancel_rounded,
                    size: 16,
                    color: todayRecord!.status == 'PRESENT'
                        ? AppColors.success
                        : todayRecord!.status == 'LATE'
                            ? AppColors.warning
                            : AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Text('Status: ${todayRecord!.status}',
                      style: AppTextStyles.bodyMedium),
                ],
              )
            else
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text('No attendance recorded today',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textHint)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label, time;
  final IconData icon;
  final Color color;
  final bool done;
  const _TimeChip({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: done ? color.withValues(alpha: 0.1) : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: done ? color : AppColors.border,
                width: done ? 1.5 : 1),
          ),
          child: Icon(icon, color: done ? color : AppColors.textHint, size: 20),
        ),
        const SizedBox(height: 8),
        Text(time,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: done ? AppColors.textPrimary : AppColors.textHint,
            )),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.captionText),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  My attendance stats
// ─────────────────────────────────────────────────────────────────
class _MyAttendanceStats extends StatelessWidget {
  final int present, late, absent;
  const _MyAttendanceStats({
    required this.present,
    required this.late,
    required this.absent,
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
              const Icon(Icons.calendar_month_rounded,
                  size: 13, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text('MY ATTENDANCE',
                  style: AppTextStyles.labelBold
                      .copyWith(color: AppColors.textHint, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatChip('Present', present, AppColors.success)),
              const SizedBox(width: 10),
              Expanded(child: _StatChip('Late', late, AppColors.warning)),
              const SizedBox(width: 10),
              Expanded(child: _StatChip('Absent', absent, AppColors.error)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatChip(this.label, this.count, this.color);

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
//  My leave summary
// ─────────────────────────────────────────────────────────────────
class _MyLeaveSummary extends StatelessWidget {
  final int pending, approved, rejected;
  const _MyLeaveSummary({
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
              Text('MY LEAVES',
                  style: AppTextStyles.labelBold
                      .copyWith(color: AppColors.textHint, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatChip('Pending', pending, AppColors.warning)),
              const SizedBox(width: 10),
              Expanded(child: _StatChip('Approved', approved, AppColors.success)),
              const SizedBox(width: 10),
              Expanded(child: _StatChip('Rejected', rejected, AppColors.error)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  My payslip preview
// ─────────────────────────────────────────────────────────────────
class _MyPayslipPreview extends StatelessWidget {
  final List<PayrollModel> payrolls;
  const _MyPayslipPreview({required this.payrolls});

  @override
  Widget build(BuildContext context) {
    final latest = payrolls.isNotEmpty ? payrolls.first : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payments_rounded,
                    size: 18, color: Color(0xFF7C3AED)),
                const SizedBox(width: 8),
                Text('LATEST PAYSLIP',
                    style: AppTextStyles.labelBold.copyWith(
                        color: AppColors.textHint, letterSpacing: 0.8)),
              ],
            ),
            const SizedBox(height: 14),
            if (latest != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Period', style: AppTextStyles.bodyMedium),
                  Text(latest.monthYear,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Net Salary', style: AppTextStyles.bodyMedium),
                  Text('\$${latest.netSalary.toStringAsFixed(2)}',
                      style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: latest.status == 'PAID'
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(latest.status,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: latest.status == 'PAID'
                                ? AppColors.success
                                : AppColors.warning)),
                  ),
                ],
              ),
            ] else
              Text('No payslip records available',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  My performance summary
// ─────────────────────────────────────────────────────────────────
class _MyPerformanceSummary extends StatelessWidget {
  final List<PerformanceReview> reviews;
  const _MyPerformanceSummary({required this.reviews});

  @override
  Widget build(BuildContext context) {
    final latest = reviews.isNotEmpty ? reviews.first : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('MY PERFORMANCE',
                    style: AppTextStyles.labelBold.copyWith(
                        color: AppColors.textHint, letterSpacing: 0.8)),
              ],
            ),
            const SizedBox(height: 14),
            if (latest != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Latest Review', style: AppTextStyles.bodyMedium),
                  Text(latest.reviewPeriod,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Rating:  ', style: AppTextStyles.bodyMedium),
                  ...List.generate(5, (i) {
                    return Icon(
                      i < latest.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 18,
                      color: i < latest.rating
                          ? AppColors.warning
                          : AppColors.textHint,
                    );
                  }),
                  const SizedBox(width: 6),
                  Text('${latest.rating}/5',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ] else
              Text('No performance reviews yet',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}
