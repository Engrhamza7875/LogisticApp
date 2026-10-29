import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'base_repository.dart';

class AuthRepository extends BaseRepository {
  /// Fetches the current logged-in user profile
  Future<AppUser?> getCurrentUser() async {
    return await safeCall(() async {
      final details = await AuthService.getUserDetails();
      if (details['email'] == null || (details['email'] as String).isEmpty) return null;
      
      final role = await AuthService.getUserRole();
      
      // Map legacy role strings to UserRole enum
      UserRole userRole;
      switch (role) {
        case 'SuperAdmin':
          userRole = UserRole.superAdmin;
          break;
        case 'Admin':
          userRole = UserRole.officeAdmin;
          break;
        case 'Driver':
          userRole = UserRole.driver;
          break;
        default:
          userRole = UserRole.user;
      }

      return AppUser(
        id: details['id']?.toString() ?? '0',
        name: details['name'] ?? '',
        email: details['email'] ?? '',
        phone: details['phone'] ?? '',
        role: userRole,
        branchId: details['branch'], // This should be a unique ID, currently mapping from 'branch'
        branchName: details['branch'],
        photoUrl: details['photo'],
      );
    });
  }

  /// Syncs auth status with backend
  Future<void> syncAuthStatus() async {
    await safeCall(() => AuthService.syncRoleSilently());
  }

  /// Logout
  Future<void> logout() async {
    await safeCall(() => AuthService.logout());
  }
}
