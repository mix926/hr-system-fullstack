// lib/core/rbac/rbac_route_guard.dart
//
// Route-level access control.
//
// Use as the `redirect` callback in GoRouter, or wrap any route
// entry-point widget:
//
//   GoRoute(
//     path: '/employees',
//     builder: (_, __) => RBACRouteGuard(
//       requiredPermission: Permission.employeeReadAll,
//       child: EmployeeListScreen(),
//     ),
//   )
//
// If the user is unauthenticated → redirect to login.
// If the user is authenticated but lacks the permission → show 403 screen.

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/auth/presentation/login.dart';
import 'auth_session.dart';
import 'permission.dart';

/// Wraps a screen and enforces that the current user holds [requiredPermission].
/// If not logged in → pushes [LoginScreen].
/// If logged in but unauthorized → shows an inline 403 widget.
class RBACRouteGuard extends StatelessWidget {
  final Permission requiredPermission;
  final Widget child;

  const RBACRouteGuard({
    super.key,
    required this.requiredPermission,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final session = AuthSession.instance;

    // Not logged in → go to login
    if (!session.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      });
      return const SizedBox.shrink();
    }

    // Logged in but lacks permission → 403
    if (!session.hasPermission(requiredPermission)) {
      return _AccessDeniedScreen(permission: requiredPermission);
    }

    return child;
  }
}

/// Shown when an authenticated user reaches a route they lack permission for.
class _AccessDeniedScreen extends StatelessWidget {
  final Permission permission;

  const _AccessDeniedScreen({required this.permission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Access Denied')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded,
                    size: 40, color: AppColors.error),
              ),
              const SizedBox(height: 24),
              Text('403 — Forbidden', style: AppTextStyles.displaySmall),
              const SizedBox(height: 8),
              Text(
                'Your role (${AuthSession.instance.role.value}) does not '
                'have permission to view this page.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
