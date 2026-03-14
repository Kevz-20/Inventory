class OrganizationMembershipModel {
  final String id;
  final String organizationId;
  final String userId;
  final String roleCode;
  final String status;

  const OrganizationMembershipModel({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.roleCode,
    required this.status,
  });

  factory OrganizationMembershipModel.fromMap(Map<String, dynamic> map) {
    final role = map['roles'];
    final roleCode = role is Map<String, dynamic>
        ? (role['code'] as String? ?? '')
        : map['role_code'] as String? ?? '';

    return OrganizationMembershipModel(
      id: map['id'] as String,
      organizationId: map['organization_id'] as String,
      userId: map['user_id'] as String,
      roleCode: roleCode,
      status: map['status'] as String? ?? 'active',
    );
  }
}
