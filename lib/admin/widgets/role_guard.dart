// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/colors.dart';

/// Wraps any widget and only renders it if the current user
/// satisfies [allowedRoles]. Otherwise shows [fallback] (defaults
/// to a friendly "Permission Denied" message).
///
/// Usage:
///   RoleGuard(
///     allowedRoles: ['Admin', 'SuperAdmin'],
///     child: MyAdminWidget(),
///   )
class RoleGuard extends StatefulWidget {
  final List<String> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  String _role = 'User';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await AuthService.getUserRole();
    if (mounted) setState(() { _role = role; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (widget.allowedRoles.contains(_role)) {
      return widget.child;
    }
    return widget.fallback ?? _defaultDenied(context);
  }

  Widget _defaultDenied(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, color: AppColors.error, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Access Restricted',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your role ($_role) does not have permission to access this section.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// A standalone page guard — navigates away immediately if role is insufficient.
/// Use this in initState or as a wrapper around a full screen route.
///
/// Usage:
///   class _MyScreenState extends State {
///     @override
///     void initState() {
///       super.initState();
///       RoleGuardPage.enforce(context, allowedRoles: ['SuperAdmin']);
///     }
///   }
class RoleGuardPage {
  static Future<void> enforce(
    BuildContext context, {
    required List<String> allowedRoles,
    String? message,
  }) async {
    final role = await AuthService.getUserRole();
    if (!allowedRoles.contains(role)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message ?? 'Permission denied. Requires: ${allowedRoles.join(' or ')}. Your role: $role',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }
}

/// A route-level guard that prevents unauthorized users from ever seeing [child].
///
/// Use this as the widget for a named route (e.g. `/admin`, `/superadmin`).
class RoleGate extends StatelessWidget {
  final List<String> allowedRoles;
  final Widget child;

  const RoleGate({
    super.key,
    required this.allowedRoles,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: AuthService.getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final role = snapshot.data ?? 'User';
        if (allowedRoles.contains(role)) return child;

        // Keep behavior aligned with existing app patterns: snack + return to previous route.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Permission denied. Requires: ${allowedRoles.join(' or ')}. Your role: $role',
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
          }
        });

        // Lightweight placeholder while redirecting away.
        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }
}
