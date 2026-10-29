enum UserRole { superAdmin, officeAdmin, driver, user }

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? branchId;  // Null for SuperAdmin
  final String? branchName;
  final bool isActive;
  final String? photoUrl;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.branchId,
    this.branchName,
    this.isActive = true,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.index,
        'branchId': branchId,
        'branchName': branchName,
        'isActive': isActive,
        'photoUrl': photoUrl,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        role: UserRole.values[int.tryParse(json['role']?.toString() ?? '3') ?? 3],
        branchId: json['branchId']?.toString(),
        branchName: json['branchName']?.toString(),
        isActive: json['isActive'] ?? true,
        photoUrl: json['photoUrl']?.toString(),
      );

  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isOfficeAdmin => role == UserRole.officeAdmin;
  bool get isDriver => role == UserRole.driver;
  bool get isUser => role == UserRole.user;
}
