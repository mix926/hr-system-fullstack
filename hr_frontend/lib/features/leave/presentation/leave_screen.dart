// Location: lib/features/leave/presentation/leave_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../core/theme/app_theme.dart';
import '../data/models/leave_model.dart';
import 'bloc/leave_bloc.dart';
import 'bloc/leave_event.dart';
import 'bloc/leave_state.dart';

class LeaveScreen extends StatelessWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<LeaveBloc>()..add(LoadLeavesEvent()),
      child: const _LeaveScreenBody(),
    );
  }
}

class _LeaveScreenBody extends StatelessWidget {
  const _LeaveScreenBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<LeaveBloc, LeaveState>(
        listener: (context, state) {
          if (state is LeaveOperationSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(state.message)),
              ]),
              backgroundColor: AppColors.success,
            ));
          } else if (state is LeaveErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(state.message)),
              ]),
              backgroundColor: AppColors.error,
            ));
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(child: _buildContent(context, state)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'submit_leave',
        onPressed: () => _showSubmitForm(context),
        backgroundColor: AppColors.primary,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Request Leave',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Leaves', style: AppTextStyles.displayMedium),
                SizedBox(height: 2),
                Text('View and manage your leave requests',
                    style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          Material(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () =>
                  context.read<LeaveBloc>().add(LoadLeavesEvent()),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.refresh_rounded,
                    size: 20, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────
  Widget _buildContent(BuildContext context, LeaveState state) {
    if (state is LeaveLoadingState) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state is LeaveErrorState) {
      return _buildError(context, state.message);
    }

    if (state is LeaveLoadedState || state is LeaveOperationSuccessState) {
      final leaves = state is LeaveLoadedState
          ? state.leaves
          : (context.read<LeaveBloc>().state is LeaveLoadedState
              ? (context.read<LeaveBloc>().state as LeaveLoadedState).leaves
              : <LeaveModel>[]);
      return _buildList(context, leaves);
    }

    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  // ── Leave list ────────────────────────────────────────────────
  Widget _buildList(BuildContext context, List<LeaveModel> leaves) {
    if (leaves.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.beach_access_rounded,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('No leave requests yet', style: AppTextStyles.titleMedium),
            const SizedBox(height: 6),
            const Text('Tap + to submit a new request',
                style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<LeaveBloc>().add(LoadLeavesEvent()),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        itemCount: leaves.length,
        itemBuilder: (_, i) => _buildLeaveCard(leaves[i]),
      ),
    );
  }

  // ── Leave card ────────────────────────────────────────────────
  Widget _buildLeaveCard(LeaveModel leave) {
    final statusColor = _statusColor(leave.status);
    final statusBg    = _statusBg(leave.status);
    final statusIcon  = _statusIcon(leave.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration(radius: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: type + status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.beach_access_rounded,
                      size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(leave.leaveType, style: AppTextStyles.titleMedium),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        leave.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Date row
            Row(
              children: [
                _infoChip(Icons.calendar_today_outlined,
                    _formatDate(leave.startDate)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 14, color: AppColors.textHint),
                ),
                _infoChip(
                    Icons.event_outlined, _formatDate(leave.endDate)),
              ],
            ),
            if (leave.reason != null && leave.reason!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(leave.reason!,
                        style: AppTextStyles.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }

  // ── Error state ───────────────────────────────────────────────
  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.errorLight, shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(message,
                style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: AppTheme.primaryButtonStyle(),
              onPressed: () =>
                  context.read<LeaveBloc>().add(LoadLeavesEvent()),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Submit form modal ─────────────────────────────────────────
  void _showSubmitForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<LeaveBloc>(),
        child: const _LeaveFormSheet(),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED': return AppColors.success;
      case 'REJECTED': return AppColors.error;
      default:         return AppColors.warning;
    }
  }

  Color _statusBg(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED': return AppColors.successLight;
      case 'REJECTED': return AppColors.errorLight;
      default:         return AppColors.warningLight;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED': return Icons.check_circle_rounded;
      case 'REJECTED': return Icons.cancel_rounded;
      default:         return Icons.hourglass_empty_rounded;
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

// ─────────────────────────────────────────────
//  Leave Request Form (Bottom Sheet)
// ─────────────────────────────────────────────

class _LeaveFormSheet extends StatefulWidget {
  const _LeaveFormSheet();

  @override
  State<_LeaveFormSheet> createState() => _LeaveFormSheetState();
}

class _LeaveFormSheetState extends State<_LeaveFormSheet> {
  final _formKey = GlobalKey<FormState>();

  String  _leaveType  = 'Annual Leave';
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();

  static const List<String> _leaveTypes = [
    'Annual Leave',
    'Sick Leave',
    'Maternity Leave',
    'Paternity Leave',
    'Emergency Leave',
    'Unpaid Leave',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? now)
          : (_endDate ?? _startDate ?? now),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select start and end dates'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('End date cannot be before start date'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    final leave = LeaveModel(
      leaveType:  _leaveType,
      startDate:  _startDate!.toIso8601String(),
      endDate:    _endDate!.toIso8601String(),
      reason:     _reasonController.text.trim().isEmpty
                    ? null
                    : _reasonController.text.trim(),
      status: 'PENDING',
    );

    context.read<LeaveBloc>().add(CreateLeaveEvent(leave));
    Navigator.pop(context);
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          const Row(
            children: [
              Icon(Icons.beach_access_rounded,
                  color: AppColors.primary, size: 22),
              SizedBox(width: 10),
              Text('New Leave Request', style: AppTextStyles.titleLarge),
            ],
          ),
          const SizedBox(height: 20),

          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Leave type dropdown
                DropdownButtonFormField<String>(
                  value: _leaveType,
                  decoration: AppTheme.inputDecoration(
                    'Leave Type',
                    icon: Icons.category_outlined,
                  ),
                  items: _leaveTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _leaveType = v!),
                ),
                const SizedBox(height: 14),

                // Date row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickDate(isStart: true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 15),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 16, color: AppColors.textHint),
                              const SizedBox(width: 8),
                              Text(
                                _startDate != null
                                    ? _formatDate(_startDate!)
                                    : 'Start Date',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: _startDate != null
                                      ? AppColors.textPrimary
                                      : AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 16, color: AppColors.textHint),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickDate(isStart: false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 15),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_outlined,
                                  size: 16, color: AppColors.textHint),
                              const SizedBox(width: 8),
                              Text(
                                _endDate != null
                                    ? _formatDate(_endDate!)
                                    : 'End Date',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: _endDate != null
                                      ? AppColors.textPrimary
                                      : AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Reason (optional)
                TextFormField(
                  controller: _reasonController,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  decoration: AppTheme.inputDecoration(
                    'Reason (optional)',
                    icon: Icons.notes_rounded,
                  ),
                ),
                const SizedBox(height: 20),

                // Submit button
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: AppTheme.primaryButtonStyle(),
                    onPressed: _submit,
                    icon: const Icon(Icons.send_rounded,
                        size: 18, color: Colors.white),
                    label: const Text('Submit Request'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
