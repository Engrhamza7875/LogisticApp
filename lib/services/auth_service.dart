import 'package:sabcargo/services/logger_service.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'local_registration_store.dart';

class AuthService {
  static final ValueNotifier<int> profileUpdateNotifier = ValueNotifier<int>(0);

  static void notifyProfileUpdate() {
    profileUpdateNotifier.value++;
  }

  static const String _pinKey = 'sabcargo_pin';
  static const String _isLoggedIn = 'sabcargo_logged_in';
  static const String _userName = 'sabcargo_user_name';
  static const String _userEmail = 'sabcargo_user_email';
  static const String _userPhone = 'sabcargo_user_phone';
  static const String _userPhoto = 'sabcargo_user_photo';
  static const String _userId = 'sabcargo_user_id';
  static const String _userBranch = 'sabcargo_user_branch';
  static const String _emailVerificationCode = 'sabcargo_verification_code';
  static const String _authToken = 'sabcargo_auth_token';   // JWT
  static const String _userRole  = 'sabcargo_user_role';    // 'User' | 'Admin' | 'SuperAdmin'
  static const String _isImpersonating = 'sabcargo_is_impersonating';
  static const String _backupAdminData = 'sabcargo_backup_admin_data';

  /// Generates a random 6-digit PIN, saves it, and returns it
  static Future<String> generateAndSavePin({
    String name = 'John Doe',
    String email = 'user@sabcargo.com',
    String phone = '+1234567890',
  }) async {
    final random = Random.secure();
    final pin = (100000 + random.nextInt(900000)).toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    await prefs.setString(_userName, name);
    await prefs.setString(_userEmail, email);
    await prefs.setString(_userPhone, phone);

    // Always keep a local JSON history of registrations.
    await LocalRegistrationStore.saveRegistration(
      name: name,
      email: email,
      phone: phone,
      pin: pin,
    );

    // Save PIN to backend (best effort). Backend stores it hashed.
    try {
      await ApiService.setPin(email: email, pin: pin)
          .timeout(const Duration(seconds: 5));
      appLogger.i('✓ PIN saved to backend successfully');
    } catch (e) {
      appLogger.i('⚠️ Failed to save PIN to backend (using local storage only): $e');
    }

    return pin;
  }

  /// Sets a custom 6-digit PIN and saves it
  static Future<void> saveCustomPin(
    String pin, {
    String name = 'John Doe',
    String email = 'user@sabcargo.com',
    String phone = '+1234567890',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    await prefs.setString(_userName, name);
    await prefs.setString(_userEmail, email);
    await prefs.setString(_userPhone, phone);

  }

  /// Checks if a PIN has been set up
  static Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pinKey);
  }

  /// Returns whether user is currently logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedIn) ?? false;
  }

  /// Verifies entered PIN against stored PIN.
  /// On success, persists the JWT token and role returned by the server.
  static Future<bool> verifyPin(String enteredPin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = await getUserEmail();
      appLogger.i('[AUTH] Verifying PIN...');

      // Verify PIN through the backend; the response includes the token and role.
      final result = await ApiService.verifyPin(email, enteredPin);
      appLogger.i('[AUTH] Result from server: ${result['valid']} | role: ${result['role']}');

      if (result['valid'] == true) {
        await prefs.setBool(_isLoggedIn, true);

        // Persist user details
        if (result['user'] != null) {
          final u = result['user'];
          if (u['id'] != null) await prefs.setInt(_userId, u['id']);
          if (u['fullName'] != null) await prefs.setString(_userName, u['fullName']);
          if (u['email'] != null) await prefs.setString(_userEmail, u['email']);
          if (u['branch'] != null) await prefs.setString(_userBranch, u['branch']);
        }

        // Persist JWT token for subsequent API calls
        final token = result['token'] as String?;
        if (token != null && token.isNotEmpty) {
          await prefs.setString(_authToken, token);
          appLogger.i('[AUTH] JWT token stored successfully.');
        }

        // Persist role (User / Admin / SuperAdmin)
        final role = result['role'] as String? ?? 'User';
        await prefs.setString(_userRole, role);
        appLogger.i('[AUTH] Role stored: $role');

        return true;
      }
      return false;
    } catch (e) {
      appLogger.i('PIN verification failed: $e');
      return false;
    }
  }

  /// Silently pulls a transparently up-to-date token and role from backend
  /// and updates the local storage blindly behind the scenes.
  static Future<void> syncRoleSilently() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_authToken)) return;

      final result = await ApiService.syncAuthStatus();
      if (result['token'] != null && result['role'] != null) {
        await prefs.setString(_authToken, result['token']);
        await prefs.setString(_userRole, result['role']);
        appLogger.i('[AUTH] Role synced silently in background: ${result['role']}');
      }
    } catch (e) {
      appLogger.i('Silent role sync failed (network error ignored): $e');
    }
  }

  /// Returns the stored JWT token, or null if not logged in.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authToken);
  }

  /// Returns the stored role string: 'User', 'Admin', or 'SuperAdmin'.
  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRole) ?? 'User';
  }

  /// Returns the display-friendly role name
  static Future<String> getDisplayRole() async {
    final role = await getUserRole();
    if (role == 'Admin') return 'Office Admin';
    return role;
  }

  /// Returns true only if the current user has Admin or SuperAdmin role.
  static Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 'Admin' || role == 'SuperAdmin';
  }

  /// Returns true only if the current user is an Office Admin (regular Admin).
  static Future<bool> isOfficeAdmin() async {
    final role = await getUserRole();
    return role == 'Admin';
  }

  /// Returns true only if the current user is a SuperAdmin.
  static Future<bool> isSuperAdmin() async {
    final role = await getUserRole();
    return role == 'SuperAdmin';
  }

  /// Retrieve the stored PIN (for display on setup screen)
  static Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey);
  }

  /// Get stored user email
  static Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_userEmail) ?? '';
    if (email.isEmpty) {
      appLogger.i('[AUTH] Warning: No email found in local storage.');
    }
    return email;
  }

  /// Get all user details
  static Future<Map<String, dynamic>> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getInt(_userId) ?? 0,
      'name': prefs.getString(_userName) ?? '',
      'email': prefs.getString(_userEmail) ?? '',
      'phone': prefs.getString(_userPhone) ?? '',
      'photo': prefs.getString(_userPhoto) ?? '',
      'branch': prefs.getString(_userBranch) ?? '',
    };
  }

  /// Save profile basics after registration/verification
  static Future<void> saveProfileBasics({
    required String name,
    required String email,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userName, name);
    await prefs.setString(_userEmail, email);
    await prefs.setString(_userPhone, phone);
    appLogger.i('[AUTH] Profile basics saved locally for: $email');
    notifyProfileUpdate();
  }

  /// Update user profile both locally and on the backend
  static Future<void> updateUserProfile({
    required String name,
    required String phone,
    String? photo,
  }) async {
    // 1. Update on backend
    await ApiService.updateProfile(name, phone, photo: photo);

    // 2. Update locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userName, name);
    await prefs.setString(_userPhone, phone);
    if (photo != null) await prefs.setString(_userPhoto, photo);

    appLogger.i('[AUTH] Profile updated successfully for user.');
    notifyProfileUpdate();
  }

  /// Update user photo (Base64 string)
  static Future<void> updateUserPhoto(String base64Image) async {
    final details = await getUserDetails();
    await updateUserProfile(
      name: details['name'],
      phone: details['phone'],
      photo: base64Image,
    );
  }

  /// Get user photo
  static Future<String?> getUserPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoto);
  }

  /// Generate a mock 4-digit email verification code and store it temporarily
  static Future<String> generateEmailVerificationCode() async {
    final random = Random.secure();
    final code = (1000 + random.nextInt(9000)).toString(); // 4 digit code
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailVerificationCode, code);
    return code;
  }

  /// Verify the 4-digit code
  static Future<bool> verifyEmailCode(String enteredCode) async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_emailVerificationCode);
    if (savedCode == enteredCode) {
      await prefs.remove(_emailVerificationCode); // clear it after use
      return true;
    }
    return false;
  }

  /// Impersonate a user
  static Future<void> loginAsUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Backup current admin data if not already impersonating
    if (!(prefs.getBool(_isImpersonating) ?? false)) {
      final backup = {
        'role': prefs.getString(_userRole),
        'token': prefs.getString(_authToken),
        'email': prefs.getString(_userEmail),
        'name': prefs.getString(_userName),
        'id': prefs.getInt(_userId),
      };
      await prefs.setString(_backupAdminData, (backup).toString());
    }

    // 2. Set user data
    await prefs.setString(_userRole, 'User');
    await prefs.setString(_userEmail, user['email'] ?? '');
    await prefs.setString(_userName, user['name'] ?? '');
    if (user['id'] != null) await prefs.setInt(_userId, user['id']);
    await prefs.setBool(_isImpersonating, true);
    
    notifyProfileUpdate();
  }

  /// Exit impersonation and restore admin session
  static Future<void> exitImpersonation() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_isImpersonating) ?? false)) return;

    // This is a mock restoration logic for the demo/prototype
    // In a real app, we would parse the stored backup JSON
    await prefs.setBool(_isImpersonating, false);
    await prefs.setString(_userRole, 'SuperAdmin'); // Restore to SuperAdmin for safety in this mock
    
    notifyProfileUpdate();
  }

  static Future<bool> isImpersonating() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isImpersonating) ?? false;
  }

  /// Log out the current user — clears session token and role.
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedIn, false);
    await prefs.remove(_authToken);
    await prefs.remove(_userRole);
    appLogger.i('[AUTH] Session cleared — token and role removed.');
  }

  /// Reset everything (wipe PIN and login status)
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.remove(_isLoggedIn);
    await prefs.remove(_authToken);
    await prefs.remove(_userRole);
    // Note: We don't remove user profile info here, just login states.
    // That way, if they reset PIN, their name/photo remain.
  }

  /// Permanently delete account
  static Future<void> deleteAccount() async {
    final email = await getUserEmail();
    final details = await getUserDetails();
    final id = details['id'] as int;
    
    // 1. Delete from backend
    await ApiService.deleteUserAccount(id, email);
    
    // 2. Clear local storage
    await resetAll();
  }
}
