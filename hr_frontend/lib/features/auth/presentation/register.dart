import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/theme/app_theme.dart';
import '../../employee/data/models/employee_model.dart';
import '../data/auth_api_service.dart';
import 'login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _authService = GetIt.instance<AuthApiService>();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _emailController     = TextEditingController();
  final _passwordController  = TextEditingController();
  final _positionController  = TextEditingController();

  String _role             = 'STAFF';
  bool   _isLoading        = false;
  bool   _obscurePassword  = true;

  static const List<Map<String, dynamic>> _roleOptions = [
    {'value': 'STAFF',   'label': 'Staff',   'icon': Icons.person_rounded,           'color': Color(0xFF2563EB)},
    {'value': 'MANAGER', 'label': 'Manager', 'icon': Icons.manage_accounts_rounded,  'color': Color(0xFFEA580C)},
    {'value': 'ADMIN',   'label': 'Admin',   'icon': Icons.shield_rounded,           'color': Color(0xFF7C3AED)},
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await _authService.registerEmployee(Employee(
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
              Text('Account created! Please sign in.'),
            ]),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
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
        title: const Text('Create Account'),
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
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    _buildSectionHeader(
                      icon: Icons.corporate_fare_rounded,
                      title: 'New Account Registration',
                      subtitle: 'Fill in the details below to create your HR System account.',
                    ),
                    const SizedBox(height: 28),

                    // ── Section 1: Personal Info ──────────────────────
                    _buildSectionLabel('Personal Information'),
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

                    // ── Section 2: Security ───────────────────────────
                    _buildSectionLabel('Security'),
                    const SizedBox(height: 12),
                    Container(
                      decoration: AppTheme.cardDecoration(),
                      padding: const EdgeInsets.all(20),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: AppTheme.inputDecoration(
                          'Password',
                          icon: Icons.lock_outline_rounded,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: AppColors.textHint,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          if (v.length < 8) return 'Minimum 8 characters required';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Section 3: Job Info ───────────────────────────
                    _buildSectionLabel('Job Details'),
                    const SizedBox(height: 12),
                    Container(
                      decoration: AppTheme.cardDecoration(),
                      padding: const EdgeInsets.all(20),
                      child: TextFormField(
                        controller: _positionController,
                        textInputAction: TextInputAction.done,
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

                    // ── Section 4: Role Selector ──────────────────────
                    _buildSectionLabel('System Role'),
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
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 4),
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
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected ? color : AppColors.textSecondary,
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
                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: AppTheme.primaryButtonStyle(),
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading
                            ? AppTheme.loadingIndicator()
                            : const Text('Create Account'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sign in link
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: AppTextStyles.bodyMedium,
                            children: [
                              TextSpan(
                                text: 'Sign In',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
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
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.titleLarge),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.labelBold.copyWith(
            color: AppColors.textHint,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider()),
      ],
    );
  }
}
