// lib/features/attendance/presentation/attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../core/theme/app_theme.dart';
import '../data/models/attendance_model.dart';
import 'bloc/attendance_bloc.dart';
import 'bloc/attendance_event.dart';
import 'bloc/attendance_state.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          GetIt.instance<AttendanceBloc>()..add(LoadAttendancesEvent()),
      child: const _AttendanceBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Body
// ─────────────────────────────────────────────────────────────────────────────
class _AttendanceBody extends StatelessWidget {
  const _AttendanceBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceOperationSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(state.message)),
              ]),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ));
          } else if (state is AttendanceErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(state.message)),
              ]),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                context
                    .read<AttendanceBloc>()
                    .add(LoadAttendancesEvent());
              },
              child: CustomScrollView(
                slivers: [
                  // ── App Bar ──────────────────────────────────
                  SliverToBoxAdapter(child: _buildHeader()),

                  // ── Today card ───────────────────────────────
                  SliverToBoxAdapter(
                    child: _buildTodayCard(context, state),
                  ),

                  // ── Section label ────────────────────────────
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                      child: Text(
                        'HISTORY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHint,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),

                  // ── History list ─────────────────────────────
                  if (state is AttendanceLoadingState)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      ),
                    )
                  else if (state is AttendanceLoadedState)
                    _buildHistoryList(state.attendances)
                  else if (state is AttendanceErrorState)
                    SliverFillRemaining(
                      child: _buildErrorView(context, state.message),
                    )
                  else
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────
  Widget _buildHeader() {
    final now = DateTime.now();
    final dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fingerprint_rounded,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Attendance', style: AppTextStyles.titleLarge),
                  Text(
                    '${dayNames[now.weekday - 1]}, ${monthNames[now.month - 1]} ${now.day}, ${now.year}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Today Check-in/out Card ──────────────────────────────────
  Widget _buildTodayCard(BuildContext context, AttendanceState state) {
    AttendanceModel? today;
    bool isLoading = false;

    if (state is AttendanceLoadedState) {
      today = state.todayAttendance;
    } else if (state is AttendanceLoadingState) {
      isLoading = true;
    }

    final hasCheckedIn  = today?.checkInTime  != null;
    final hasCheckedOut = today?.checkOutTime != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              hasCheckedOut
                  ? '✅ Completed'
                  : hasCheckedIn
                      ? '🟢 Checked In'
                      : '⚪ Not Started',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Times row
          Row(
            children: [
              _timeBox(
                label: 'Check In',
                time: today?.checkInTime != null
                    ? _formatTime(today!.checkInTime!)
                    : '--:--',
                icon: Icons.login_rounded,
              ),
              const SizedBox(width: 12),
              _timeBox(
                label: 'Check Out',
                time: today?.checkOutTime != null
                    ? _formatTime(today!.checkOutTime!)
                    : '--:--',
                icon: Icons.logout_rounded,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action buttons
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            Row(
              children: [
                if (!hasCheckedIn)
                  Expanded(
                    child: _actionButton(
                      label: 'Check In',
                      icon: Icons.login_rounded,
                      color: Colors.white,
                      textColor: AppColors.primary,
                      onTap: () => _confirmAction(
                        context,
                        title: 'Check In',
                        message: 'Confirm your attendance check-in for today?',
                        onConfirm: () => context
                            .read<AttendanceBloc>()
                            .add(CheckInEvent()),
                      ),
                    ),
                  ),
                if (hasCheckedIn && !hasCheckedOut) ...[
                  Expanded(
                    child: _actionButton(
                      label: 'Check Out',
                      icon: Icons.logout_rounded,
                      color: AppColors.error,
                      textColor: Colors.white,
                      onTap: () => _confirmAction(
                        context,
                        title: 'Check Out',
                        message:
                            'Confirm your attendance check-out for today?',
                        onConfirm: () => context
                            .read<AttendanceBloc>()
                            .add(CheckOutEvent()),
                      ),
                    ),
                  ),
                ],
                if (hasCheckedOut)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Attendance Complete',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _timeBox({
    required String label,
    required String time,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 10),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── History List ─────────────────────────────────────────────
  Widget _buildHistoryList(List<AttendanceModel> attendances) {
    if (attendances.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_outlined,
                  size: 56, color: AppColors.textHint),
              SizedBox(height: 12),
              Text('No attendance records yet',
                  style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      );
    }

    // Sort newest first
    final sorted = [...attendances]
      ..sort((a, b) => b.date.compareTo(a.date));

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _AttendanceCard(record: sorted[index]),
          childCount: sorted.length,
        ),
      ),
    );
  }

  // ── Error View ───────────────────────────────────────────────
  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 56, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(message, style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: AppTheme.primaryButtonStyle(radius: 10),
            onPressed: () =>
                context.read<AttendanceBloc>().add(LoadAttendancesEvent()),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ── Confirm dialog ───────────────────────────────────────────
  void _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: AppTextStyles.titleLarge),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: AppTheme.primaryButtonStyle(radius: 10),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(title),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────
  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final h  = dt.hour.toString().padLeft(2, '0');
      final m  = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return isoString.length >= 16 ? isoString.substring(11, 16) : isoString;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Attendance History Card
// ─────────────────────────────────────────────────────────────────────────────
class _AttendanceCard extends StatelessWidget {
  final AttendanceModel record;

  const _AttendanceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(record.status);
    final statusBg    = _statusBg(record.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(radius: 14),
      child: Row(
        children: [
          // Date badge
          Container(
            width: 46,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _dayNumber(record.date),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _monthAbbr(record.date),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Time info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.date, style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.login_rounded,
                        size: 13, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      record.checkInTime != null
                          ? _formatTime(record.checkInTime!)
                          : '--:--',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.logout_rounded,
                        size: 13, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text(
                      record.checkOutTime != null
                          ? _formatTime(record.checkOutTime!)
                          : '--:--',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              record.status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT': return AppColors.success;
      case 'LATE':    return AppColors.warning;
      case 'ABSENT':  return AppColors.error;
      default:        return AppColors.textHint;
    }
  }

  Color _statusBg(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT': return AppColors.successLight;
      case 'LATE':    return AppColors.warningLight;
      case 'ABSENT':  return AppColors.errorLight;
      default:        return AppColors.divider;
    }
  }

  String _dayNumber(String date) {
    try { return date.split('-')[2]; } catch (_) { return '??'; }
  }

  String _monthAbbr(String date) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    try {
      final m = int.parse(date.split('-')[1]) - 1;
      return months[m];
    } catch (_) { return '---'; }
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final h  = dt.hour.toString().padLeft(2, '0');
      final m  = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return isoString.length >= 16 ? isoString.substring(11, 16) : isoString;
    }
  }
}
