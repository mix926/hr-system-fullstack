import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/theme/app_theme.dart';
import '../../employee/presentation/main_screen.dart';
import '../data/auth_api_service.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthApiService _authApiService = GetIt.instance<AuthApiService>();

  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading      = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await _authApiService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(failure.message)),
            ]),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (_) => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWide ? _buildWideLayout() : _buildMobileLayout(),
    );
  }

  // ── Wide / Desktop Layout (split panel) ──────────────────────
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Left brand panel
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogo(light: true),
                  const Spacer(),
                  const Text(
                    'Manage your\nworkforce smarter.',
                    style: TextStyle(
                      fontSize: 36, fontWeight: FontWeight.w800,
                      color: Colors.white, height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'A unified HR platform for employee records,\nroles, and team management.',
                    style: TextStyle(
                      fontSize: 15, color: Colors.white70, height: 1.6,
                    ),
                  ),
                  const Spacer(),
                  _buildFeatureRow(Icons.groups_rounded,     'Employee Directory'),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.shield_rounded,     'Role-based Access'),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.bar_chart_rounded,  'Live Statistics'),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
        // Right form panel
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildFormCard(showCard: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Mobile Layout ─────────────────────────────────────────────
  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Top brand bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 36),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogo(light: true),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome back 👋',
                    style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to your HR System account',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: _buildFormCard(showCard: true),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared Form ───────────────────────────────────────────────
  Widget _buildFormCard({required bool showCard}) {
    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!showCard) ...[
            _buildLogo(light: false),
            const SizedBox(height: 32),
            Text(
              'Sign in to your account',
              style: AppTextStyles.displayMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your credentials to continue',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 36),
          ],

          // Email
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
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _isLoading ? null : _login(),
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
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
          ),
          const SizedBox(height: 28),

          // Login button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: AppTheme.primaryButtonStyle(),
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? AppTheme.loadingIndicator()
                  : const Text('Sign In'),
            ),
          ),
          const SizedBox(height: 20),

          // Register link
          Center(
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              child: RichText(
                text: TextSpan(
                  text: "Don't have an account? ",
                  style: AppTextStyles.bodyMedium,
                  children: [
                    TextSpan(
                      text: 'Register',
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
        ],
      ),
    );

    if (!showCard) return form;

    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(28),
      child: form,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  Widget _buildLogo({required bool light}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: light ? Colors.white.withValues(alpha: 0.2) : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.corporate_fare_rounded,
            size: 20,
            color: light ? Colors.white : AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'HR System',
          style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800,
            color: light ? Colors.white : AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
