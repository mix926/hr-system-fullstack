// Location: lib/features/employee/presentation/employee_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../data/models/employee_model.dart';

class EmployeeDetailScreen extends StatelessWidget {
  final Employee employee;
  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final initials =
        (employee.firstName.isNotEmpty ? employee.firstName[0] : '') +
            (employee.lastName.isNotEmpty ? employee.lastName[0] : '');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Employee Profile'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Hero ──────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border:
                      Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
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
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(employee.fullName, style: AppTextStyles.displayMedium),
                    const SizedBox(height: 4),
                    Text(employee.position, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 12),
                    AppTheme.roleBadge(employee.role),
                  ],
                ),
              ),

              // ── Info ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _sectionLabel('Contact'),
                    const SizedBox(height: 10),
                    _infoCard([
                      InkWell(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: employee.email));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Row(children: [
                              const Icon(Icons.check_circle_outline,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Email copied: ${employee.email}')),
                            ]),
                            backgroundColor: AppColors.success,
                          ));
                        },
                        child: _row(
                            Icons.email_outlined, 'Email', employee.email,
                            valueColor: AppColors.primary),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _sectionLabel('Employment'),
                    const SizedBox(height: 10),
                    _infoCard([
                      _row(Icons.work_outline_rounded, 'Position',
                          employee.position),
                      const Divider(height: 1),
                      _row(Icons.badge_outlined, 'Role', employee.role),
                      if (employee.departmentId != null) ...[
                        const Divider(height: 1),
                        _row(Icons.corporate_fare_rounded, 'Department ID',
                            employee.departmentId!),
                      ],
                      if (employee.id != null) ...[
                        const Divider(height: 1),
                        _row(Icons.fingerprint_rounded, 'Employee ID',
                            employee.id!),
                      ],
                    ]),
                    const SizedBox(height: 20),
                    _sectionLabel('Status'),
                    const SizedBox(height: 10),
                    _infoCard([
                      _row(
                        Icons.circle,
                        'Account Status',
                        'Active',
                        valueColor: AppColors.success,
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelBold.copyWith(
            color: AppColors.textHint, letterSpacing: 1),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      decoration: AppTheme.cardDecoration(radius: 14),
      child: Column(children: children),
    );
  }

  Widget _row(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textHint),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.bodyMedium),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
