class OrganizationMemberSummary {
  final String membershipId;
  final String userId;
  final String fullName;
  final String? mobileNumber;
  final String roleCode;
  final String status;

  const OrganizationMemberSummary({
    required this.membershipId,
    required this.userId,
    required this.fullName,
    required this.mobileNumber,
    required this.roleCode,
    required this.status,
  });
}
