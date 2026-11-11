// lib/core/rbac/role_router.dart
//
// RoleRouter — maps a user's role string to the correct MainScreen shell.
//
// Usage:
//   Navigator.pushReplacement(context,
//     MaterialPageRoute(builder: (_) => RoleRouter.forRole(role)),
//   );
//
// This is the single place in the app that decides which shell a user
// sees after login.  Add new role shells here.

import 'package:flutter/widgets.dart';

import '../../features/employee/presentation/admin_main_screen.dart';
import '../../features/employee/presentation/manager_main_screen.dart';
import '../../features/employee/presentation/staff_main_screen.dart';
import 'user_role.dart';

class RoleRouter {
  RoleRouter._();

  /// Returns the appropriate MainScreen widget for the given role string.
  /// Falls back to [StaffMainScreen] for unknown roles (safest default —
  /// least privilege).
  static Widget forRole(String? roleStr) {
    final role = UserRole.fromString(roleStr);

    return switch (role) {
      UserRole.admin => const AdminMainScreen(),
      UserRole.manager => const ManagerMainScreen(),
      UserRole.staff => const StaffMainScreen(),
    };
  }
}
