class AppOrganization {
  final String id;
  final String code;
  final String name;
  final String status;

  const AppOrganization({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
  });

  factory AppOrganization.fromMap(Map<String, dynamic> map) {
    return AppOrganization(
      id: map['id'] as String,
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
    );
  }
}
