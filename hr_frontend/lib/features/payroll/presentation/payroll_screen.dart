// lib/features/payroll/presentation/payroll_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../employee/data/employee_api_service.dart';
import '../../employee/data/models/employee_model.dart';
import '../data/models/payroll_model.dart';
import '../data/payroll_api_service.dart';
import 'bloc/payroll_bloc.dart';
import 'bloc/payroll_event.dart';
import 'bloc/payroll_state.dart';

class PayrollScreen extends StatelessWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PayrollBloc(GetIt.instance<PayrollApiService>())
            ..add(LoadPayrollStatsEvent()),
      child: const _PayrollView(),
    );
  }
}

class _PayrollView extends StatefulWidget {
  const _PayrollView();

  @override
  State<_PayrollView> createState() => _PayrollViewState();
}

class _PayrollViewState extends State<_PayrollView> {
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userRole = prefs.getString('role') ?? 'STAFF';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payroll'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: BlocConsumer<PayrollBloc, PayrollState>(
        listener: (context, state) {
          if (state is PayrollOperationSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(state.message)),
              ]),
              backgroundColor: AppColors.success,
            ));
          }
          if (state is PayrollErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.error_outline,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(state.message)),
              ]),
              backgroundColor: AppColors.error,
            ));
          }
        },
        builder: (context, state) {
          if (state is PayrollLoadingState ||
              state is PayrollInitialState) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is PayrollErrorState) {
            return _buildError(context, state.message);
          }

          // Stats-loaded state (admin/manager)
          if (state is PayrollStatsLoadedState) {
            if (state.payrolls.isEmpty) {
              return _buildEmpty(withStats: state.stats);
            }
            return _buildContent(context, state.payrolls, stats: state.stats);
          }

          // Plain loaded state (staff)
          if (state is PayrollLoadedState) {
            if (state.payrolls.isEmpty) {
              return _buildEmpty();
            }
            return _buildContent(context, state.payrolls);
          }

          return _buildEmpty();
        },
      ),
      floatingActionButton: _userRole == 'ADMIN'
          ? FloatingActionButton.extended(
              heroTag: 'add_payroll',
              onPressed: () => _showCreateDialog(context),
              backgroundColor: AppColors.primary,
              elevation: 2,
              icon: const Icon(Icons.payments_rounded, color: Colors.white),
              label: const Text('New Payroll',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  // ── Content with optional stats ───────────────────────────────
  Widget _buildContent(
    BuildContext context,
    List<PayrollModel> payrolls, {
    Map<String, dynamic>? stats,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        if (_userRole == 'ADMIN' || _userRole == 'MANAGER') {
          context.read<PayrollBloc>().add(LoadPayrollStatsEvent());
        } else {
          context.read<PayrollBloc>().add(LoadPayrollsEvent());
        }
      },
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        itemCount: (stats != null ? 1 : 0) + payrolls.length,
        itemBuilder: (context, i) {
          if (stats != null && i == 0) {
            return _buildStatsSummary(stats);
          }
          final index = stats != null ? i - 1 : i;
          return _buildPayrollCard(context, payrolls[index]);
        },
      ),
    );
  }

  // ── Stats Summary Cards ───────────────────────────────────────
  Widget _buildStatsSummary(Map<String, dynamic> stats) {
    final total   = stats['total']   ?? 0;
    final pending = stats['pending'] ?? 0;
    final paid    = stats['paid']    ?? 0;
    final cancelled = stats['cancelled'] ?? 0;
    final totalPaid = (stats['total_paid_amount'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.insights_rounded, size: 14, color: AppColors.textHint),
            const SizedBox(width: 6),
            Text('Payroll Overview', style: AppTextStyles.labelBold.copyWith(
                color: AppColors.textHint, letterSpacing: 1)),
          ]),
          const SizedBox(height: 12),
          // Total paid amount hero card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12, offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Paid Amount',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(
                  '\$${totalPaid.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 30,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Status row
          Row(
            children: [
              Expanded(child: _statCard('Total', '$total', Icons.receipt_long_rounded, AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(child: _statCard('Pending', '$pending', Icons.hourglass_top_rounded, AppColors.warning)),
              const SizedBox(width: 10),
              Expanded(child: _statCard('Paid', '$paid', Icons.check_circle_rounded, AppColors.success)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _statCard('Cancelled', '$cancelled', Icons.cancel_rounded, AppColors.error)),
              const SizedBox(width: 10),
              const Expanded(child: SizedBox()),
              const SizedBox(width: 10),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 8),
          Text('Payroll Records', style: AppTextStyles.titleMedium),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.displayMedium.copyWith(
              color: color, fontSize: 20)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: color)),
        ],
      ),
    );
  }

  // ── Payroll Card ──────────────────────────────────────────────
  Widget _buildPayrollCard(BuildContext context, PayrollModel payroll) {
    final statusColor = _statusColor(payroll.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration(radius: 14),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            // Status badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _statusIcon(payroll.status),
                color: statusColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payroll.monthYear, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '\$${payroll.netSalary.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Status pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                payroll.status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        children: [
          _sectionRow(Icons.monetization_on_outlined, 'Base Salary',
              '\$${payroll.baseSalary.toStringAsFixed(2)}', AppColors.primary),
          _sectionRow(Icons.card_giftcard_rounded, 'Bonus',
              '\$${payroll.bonus.toStringAsFixed(2)}', AppColors.success),
          _sectionRow(Icons.remove_circle_outline, 'Deductions',
              '\$${payroll.deductions.toStringAsFixed(2)}', AppColors.error),
          _sectionRow(Icons.account_balance_wallet_rounded, 'Net Salary',
              '\$${payroll.netSalary.toStringAsFixed(2)}', AppColors.primary),
          const Divider(height: 20),
          _sectionRow(Icons.person_outline_rounded, 'Employee',
              payroll.employeeId ?? '—', AppColors.textSecondary),
          if (payroll.createdAt != null)
            _sectionRow(Icons.schedule_outlined, 'Created',
                payroll.createdAt!, AppColors.textSecondary),

          // Admin actions
          if (_userRole == 'ADMIN') ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditSalaryDialog(context, payroll),
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.primary),
                  label: const Text('Edit Salary',
                      style: TextStyle(color: AppColors.primary)),
                ),
                if (payroll.status == PayrollModel.statusPending)
                  TextButton.icon(
                    onPressed: () => _showStatusDialog(context, payroll),
                    icon: const Icon(Icons.published_with_changes_rounded,
                        size: 18, color: AppColors.warning),
                    label: const Text('Update Status',
                        style: TextStyle(color: AppColors.warning)),
                  ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context, payroll.id ?? 0),
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.error),
                  label: const Text('Delete',
                      style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.bodyMedium),
          const Spacer(),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Create Payroll Dialog ─────────────────────────────────────
  void _showCreateDialog(BuildContext context) async {
    final bloc = context.read<PayrollBloc>();
    final messenger = ScaffoldMessenger.of(context);
    List<Employee> employees = [];

    final empService = GetIt.instance<EmployeeApiService>();
    final result = await empService.getEmployees();
    result.fold(
      (_) => employees = [],
      (emps) => employees = emps,
    );

    if (!mounted || !context.mounted) return;

    if (employees.isEmpty) {
      messenger.showSnackBar(const SnackBar(
        content: Text('No employees found to create payroll'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    Employee? selectedEmployee;
    final monthYearController = TextEditingController();
    final baseSalaryController = TextEditingController(text: '0.0');
    final bonusController = TextEditingController(text: '0.0');
    final deductionsController = TextEditingController(text: '0.0');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('New Payroll Record',
              style: AppTextStyles.titleLarge),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Employee dropdown
                DropdownButtonFormField<Employee>(
                  decoration: AppTheme.inputDecoration('Select Employee',
                      icon: Icons.person_outline_rounded),
                  items: employees
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.fullName,
                                style: AppTextStyles.bodyMedium),
                          ))
                      .toList(),
                  onChanged: (emp) =>
                      setState(() => selectedEmployee = emp),
                ),
                const SizedBox(height: 12),

                // Month/Year
                TextField(
                  controller: monthYearController,
                  decoration: AppTheme.inputDecoration('Month/Year',
                      icon: Icons.calendar_today_outlined,
                      suffix: Text('e.g. 2026-10',
                          style: AppTextStyles.bodySmall)),
                ),
                const SizedBox(height: 12),

                // Base Salary
                TextField(
                  controller: baseSalaryController,
                  keyboardType: TextInputType.number,
                  decoration: AppTheme.inputDecoration('Base Salary',
                      icon: Icons.monetization_on_outlined,
                      suffix: Text('\$', style: AppTextStyles.bodyMedium)),
                ),
                const SizedBox(height: 12),

                // Bonus
                TextField(
                  controller: bonusController,
                  keyboardType: TextInputType.number,
                  decoration: AppTheme.inputDecoration('Bonus',
                      icon: Icons.card_giftcard_rounded,
                      suffix: Text('\$', style: AppTextStyles.bodyMedium)),
                ),
                const SizedBox(height: 12),

                // Deductions
                TextField(
                  controller: deductionsController,
                  keyboardType: TextInputType.number,
                  decoration: AppTheme.inputDecoration('Deductions',
                      icon: Icons.remove_circle_outline,
                      suffix: Text('\$', style: AppTextStyles.bodyMedium)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: AppTheme.primaryButtonStyle(radius: 10),
              onPressed: () {
                if (selectedEmployee == null ||
                    monthYearController.text.trim().isEmpty) {
                  messenger.showSnackBar(const SnackBar(
                    content: Text('Please select an employee and month/year'),
                    backgroundColor: AppColors.warning,
                  ));
                  return;
                }

                final base = double.tryParse(baseSalaryController.text) ?? 0.0;
                final bonus = double.tryParse(bonusController.text) ?? 0.0;
                final deductions =
                    double.tryParse(deductionsController.text) ?? 0.0;

                if (base < 0 || bonus < 0 || deductions < 0) {
                  messenger.showSnackBar(const SnackBar(
                    content: Text('Values cannot be negative'),
                    backgroundColor: AppColors.error,
                  ));
                  return;
                }

                final payroll = PayrollModel(
                  employeeId: selectedEmployee!.id,
                  monthYear: monthYearController.text.trim(),
                  baseSalary: base,
                  bonus: bonus,
                  deductions: deductions,
                  netSalary: base + bonus - deductions,
                  status: PayrollModel.statusPending,
                );
                bloc.add(CreatePayrollEvent(payroll));
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit Salary Dialog ────────────────────────────────────────
  void _showEditSalaryDialog(BuildContext context, PayrollModel payroll) {
    final bloc = context.read<PayrollBloc>();
    final baseSalaryController =
        TextEditingController(text: payroll.baseSalary.toStringAsFixed(2));
    final bonusController =
        TextEditingController(text: payroll.bonus.toStringAsFixed(2));
    final deductionsController =
        TextEditingController(text: payroll.deductions.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Edit Salary', style: AppTextStyles.titleLarge),
            const SizedBox(height: 4),
            Text(
              payroll.monthYear,
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: baseSalaryController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: AppTheme.inputDecoration(
                  'Base Salary',
                  icon: Icons.monetization_on_outlined,
                  suffix: Text('\$', style: AppTextStyles.bodyMedium),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bonusController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: AppTheme.inputDecoration(
                  'Bonus',
                  icon: Icons.card_giftcard_rounded,
                  suffix: Text('\$', style: AppTextStyles.bodyMedium),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: deductionsController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: AppTheme.inputDecoration(
                  'Deductions',
                  icon: Icons.remove_circle_outline,
                  suffix: Text('\$', style: AppTextStyles.bodyMedium),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: AppTheme.primaryButtonStyle(radius: 10),
            onPressed: () {
              final base =
                  double.tryParse(baseSalaryController.text.trim());
              final bonus =
                  double.tryParse(bonusController.text.trim());
              final deductions =
                  double.tryParse(deductionsController.text.trim());

              if (base == null || bonus == null || deductions == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Please enter valid numeric values'),
                  backgroundColor: AppColors.error,
                ));
                return;
              }

              if (base < 0 || bonus < 0 || deductions < 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Values cannot be negative'),
                  backgroundColor: AppColors.error,
                ));
                return;
              }

              bloc.add(UpdatePayrollEvent(
                payrollId: payroll.id ?? 0,
                baseSalary: base,
                bonus: bonus,
                deductions: deductions,
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  // ── Status Update Dialog ──────────────────────────────────────
  void _showStatusDialog(BuildContext context, PayrollModel payroll) {
    String? selectedStatus = payroll.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Update Status', style: AppTextStyles.titleLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: PayrollModel.statuses.map((status) {
              final color = _statusColor(status);
              final isSelected = selectedStatus == status;
              return InkWell(
                onTap: () => setState(() => selectedStatus = status),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? color
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(_statusIcon(status), color: color, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(status, style: AppTextStyles.bodyMedium),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            color: color, size: 18),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: AppTheme.primaryButtonStyle(radius: 10),
              onPressed: () {
                if (selectedStatus != null &&
                    selectedStatus != payroll.status) {
                  context
                      .read<PayrollBloc>()
                      .add(UpdatePayrollStatusEvent(payroll.id ?? 0, selectedStatus!));
                }
                Navigator.pop(ctx);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete Confirmation ───────────────────────────────────────
  void _confirmDelete(BuildContext context, int payrollId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
              color: AppColors.errorLight, shape: BoxShape.circle),
          child: const Icon(Icons.delete_forever_rounded,
              color: AppColors.error, size: 28),
        ),
        title: const Text('Delete Payroll', style: AppTextStyles.titleLarge),
        content: Text(
          'This action cannot be undone. The payroll record will be permanently deleted.',
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: AppTheme.dangerButtonStyle(),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PayrollBloc>().add(DeletePayrollEvent(payrollId));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return Icons.check_circle_rounded;
      case 'CANCELLED':
        return Icons.cancel_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  Widget _buildEmpty({Map<String, dynamic>? withStats}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.payments_outlined,
              size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text('No payroll records yet', style: AppTextStyles.bodyMedium),
          if (_userRole == 'ADMIN') ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: AppTheme.primaryButtonStyle(),
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create First Payroll'),
            ),
          ],
        ],
      ),
    );
  }

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
                  color: AppColors.errorLight, shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(message,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: AppTheme.primaryButtonStyle(),
              onPressed: () {
                if (_userRole == 'ADMIN' || _userRole == 'MANAGER') {
                  context.read<PayrollBloc>().add(LoadPayrollStatsEvent());
                } else {
                  context.read<PayrollBloc>().add(LoadPayrollsEvent());
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
