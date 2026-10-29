enum AdminRole { superAdmin, officeAdmin }

class AdminUser {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final AdminRole role;
  final String branchName; 
  final String? pin;
  final bool isActive;
  final List<String> permissions;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.branchName,
    this.pin,
    this.isActive = true,
    this.permissions = const ['view_shipments', 'create_shipments', 'update_status'],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'role': role.index,
        'branchName': branchName,
        'pin': pin,
        'isActive': isActive,
        'permissions': permissions,
      };

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        phoneNumber: json['phoneNumber'] ?? '',
        role: AdminRole.values[json['role']],
        branchName: json['branchName'],
        pin: json['pin'],
        isActive: json['isActive'] ?? true,
        permissions: List<String>.from(json['permissions'] ?? []),
      );
}
