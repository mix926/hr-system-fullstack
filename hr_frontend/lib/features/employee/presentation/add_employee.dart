import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/theme/app_theme.dart';
import '../data/employee_api_service.dart';
import '../data/models/employee_model.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _apiService = GetIt.instance<EmployeeApiService>();

  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _emailController     = TextEditingController();
  final _positionController  = TextEditingController();
  final _passwordController  = TextEditingController();

  String _role            = 'STAFF';
  bool   _isLoading       = false;
  bool   _obscurePassword = true;

  static const List<Map<String, dynamic>> _roleOptions = [
    {'value': 'STAFF',   'label': 'Staff',   'icon': Icons.person_rounded,          'color': Color(0xFF2563EB)},
    {'value': 'MANAGER', 'label': 'Manager', 'icon': Icons.manage_accounts_rounded, 'color': Color(0xFFEA580C)},
    {'value': 'ADMIN',   'label': 'Admin',   'icon': Icons.shield_rounded,          'color': Color(0xFF7C3AED)},
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _positionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await _apiService.createEmployee(Employee(
      firstName: _firstNameController.text.trim(),
      lastName:  _lastNameController.text.trim(),
      email:     _emailController.text.trim(),
      position:  _positionController.text.trim(),
      password:  _passwordController.text,
      role:      _role,
    ));

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(failure.message)),
          ]),
          backgroundColor: AppColors.error,
        ),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Employee added successfully!'),
            ]),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add New Employee'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isLoading ? null : _submit,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: AppColors.primaryLight,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 16, width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Text('Save',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Page header ───────────────────────────────
                    _buildPageHeader(),
                    const SizedBox(height: 28),

                    // ── Section: Personal Info ────────────────────
                    _sectionLabel('Personal Information'),
                    const SizedBox(height: 12),
                    Container(
                      decoration: AppTheme.cardDecoration(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _firstNameController,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: AppTheme.inputDecoration(
                                    'First Name',
                                    icon: Icons.person_outline_rounded,
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _lastNameController,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: AppTheme.inputDecoration('Last Name'),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: AppTheme.inputDecoration(
                              'Email Address',
                              icon: Icons.email_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Email is required';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Section: Job Details ──────────────────────
                    _sectionLabel('Job Details'),
                    const SizedBox(height: 12),
                    Container(
                      decoration: AppTheme.cardDecoration(),
                      padding: const EdgeInsets.all(20),
                      child: TextFormField(
                        controller: _positionController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: AppTheme.inputDecoration(
                          'Job Position / Title',
                          icon: Icons.work_outline_rounded,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Position is required' : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Section: Role ─────────────────────────────
                    _sectionLabel('System Role'),
                    const SizedBox(height: 12),
                    Container(
                      decoration: AppTheme.cardDecoration(),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: _roleOptions.map((opt) {
                          final isSelected = _role == opt['value'];
                          final color = opt['color'] as Color;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _role = opt['value'] as String),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color.withValues(alpha: 0.1)
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? color : AppColors.border,
                                    width: isSelected ? 1.8 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      opt['icon'] as IconData,
                                      size: 22,
                                      color: isSelected ? color : AppColors.textHint,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      opt['label'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected
                                            ? color : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Section: Password ─────────────────────────
                    _sectionLabel('Temporary Password'),
                    const SizedBox(height: 12),
                    Container(
                      decoration: AppTheme.cardDecoration(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _isLoading ? null : _submit(),
                            decoration: AppTheme.inputDecoration(
                              'Set Initial Password',
                              icon: Icons.lock_outline_rounded,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                  color: AppColors.textHint,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password is required';
                              if (v.length < 8) return 'Minimum 8 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 14, color: AppColors.textHint),
                              const SizedBox(width: 6),
                              Text(
                                'Employee should change this on first login.',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Submit ────────────────────────────────────
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: AppTheme.primaryButtonStyle(),
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox.shrink()
                            : const Icon(Icons.person_add_rounded,
                                size: 18, color: Colors.white),
                        label: _isLoading
                            ? AppTheme.loadingIndicator()
                            : const Text('Add Employee'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.person_add_rounded,
              color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Employee', style: AppTextStyles.titleLarge),
              SizedBox(height: 4),
              Text(
                'Complete all sections to onboard a new team member.',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.labelBold.copyWith(
            color: AppColors.textHint, letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider()),
      ],
    );
  }
}
