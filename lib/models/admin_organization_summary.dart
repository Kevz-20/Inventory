class AdminOrganizationSummary {
  final String organizationId;
  final int memberCount;
  final int auditCount;
  final DateTime? latestAuditAt;
  final String? latestAuditAction;
  final String? latestAuditEntityType;

  const AdminOrganizationSummary({
    required this.organizationId,
    this.memberCount = 0,
    this.auditCount = 0,
    this.latestAuditAt,
    this.latestAuditAction,
    this.latestAuditEntityType,
  });
}
