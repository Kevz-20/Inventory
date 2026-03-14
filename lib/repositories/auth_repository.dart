import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_organization.dart';
import '../models/admin_financial_summary.dart';
import '../models/admin_organization_summary.dart';
import '../models/app_user_profile.dart';
import '../models/authenticated_session.dart';
import '../models/organization_member_summary.dart';
import '../models/organization_membership_model.dart';
import '../services/supabase_service.dart';

class AuthRepository {
  const AuthRepository();

  bool get isAvailable => SupabaseService.isConfigured;

  Session? get currentSession {
    if (!isAvailable) {
      return null;
    }
    return SupabaseService.client.auth.currentSession;
  }

  User? get currentUser {
    if (!isAvailable) {
      return null;
    }
    return SupabaseService.client.auth.currentUser;
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    String? middleName,
    required String lastName,
    String? mobileNumber,
  }) async {
    return SupabaseService.client.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'mobile_number': mobileNumber,
      },
    );
  }

  Future<void> signOut() async {
    if (!isAvailable) {
      return;
    }
    await SupabaseService.client.auth.signOut();
  }

  Future<AppUserProfile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) {
      return null;
    }

    final row = await SupabaseService.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return AppUserProfile.fromMap(Map<String, dynamic>.from(row));
  }

  Future<List<OrganizationMembershipModel>> getCurrentMemberships() async {
    final user = currentUser;
    if (user == null) {
      return const [];
    }

    final rows = await SupabaseService.client
        .from('organization_memberships')
        .select('id, organization_id, user_id, status, roles(code)')
        .eq('user_id', user.id)
        .eq('status', 'active');

    return rows
        .map<OrganizationMembershipModel>(
          (row) => OrganizationMembershipModel.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  Future<AuthenticatedSession?> loadAuthenticatedSession() async {
    final user = currentUser;
    if (user == null) {
      return null;
    }

    final profile = await getCurrentProfile();
    if (profile == null) {
      return null;
    }

    final memberships = await getCurrentMemberships();

    return AuthenticatedSession(
      userId: user.id,
      email: user.email,
      profile: profile,
      memberships: memberships,
    );
  }

  Future<List<AppOrganization>> getOrganizationsByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return const [];
    }

    final rows = await SupabaseService.client
        .from('organizations')
        .select('id, code, name, status')
        .inFilter('id', ids);

    return rows
        .map<AppOrganization>(
          (row) => AppOrganization.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<Map<String, AdminOrganizationSummary>>
  getAdminOrganizationSummaries(List<String> organizationIds) async {
    if (organizationIds.isEmpty) {
      return const {};
    }

    final summaries = <String, AdminOrganizationSummary>{
      for (final organizationId in organizationIds)
        organizationId: AdminOrganizationSummary(organizationId: organizationId),
    };

    final membershipRows = await SupabaseService.client
        .from('organization_memberships')
        .select('organization_id')
        .inFilter('organization_id', organizationIds)
        .eq('status', 'active');

    final memberCounts = <String, int>{};
    for (final row in membershipRows) {
      final organizationId = (row['organization_id'] ?? '').toString();
      if (organizationId.isEmpty) {
        continue;
      }
      memberCounts[organizationId] = (memberCounts[organizationId] ?? 0) + 1;
    }

    final auditRows = await SupabaseService.client
        .from('audit_logs')
        .select('organization_id, action, entity_type, occurred_at')
        .inFilter('organization_id', organizationIds)
        .order('occurred_at', ascending: false);

    final auditCounts = <String, int>{};
    final latestAuditByOrg = <String, Map<String, dynamic>>{};
    for (final rawRow in auditRows) {
      final row = Map<String, dynamic>.from(rawRow);
      final organizationId = (row['organization_id'] ?? '').toString();
      if (organizationId.isEmpty) {
        continue;
      }
      auditCounts[organizationId] = (auditCounts[organizationId] ?? 0) + 1;
      latestAuditByOrg.putIfAbsent(organizationId, () => row);
    }

    for (final organizationId in organizationIds) {
      final latestAudit = latestAuditByOrg[organizationId];
      summaries[organizationId] = AdminOrganizationSummary(
        organizationId: organizationId,
        memberCount: memberCounts[organizationId] ?? 0,
        auditCount: auditCounts[organizationId] ?? 0,
        latestAuditAt: latestAudit == null
            ? null
            : DateTime.tryParse((latestAudit['occurred_at'] ?? '').toString()),
        latestAuditAction: latestAudit == null
            ? null
            : (latestAudit['action'] ?? '').toString(),
        latestAuditEntityType: latestAudit == null
            ? null
            : (latestAudit['entity_type'] ?? '').toString(),
      );
    }

    return summaries;
  }

  Future<List<OrganizationMemberSummary>> getOrganizationMembers(
    String organizationId,
  ) async {
    if (organizationId.isEmpty) {
      return const [];
    }

    final rows = await SupabaseService.client
        .from('organization_memberships')
        .select(
          'id, user_id, status, roles(code), '
          'profiles!organization_memberships_user_id_fkey('
          'first_name, middle_name, last_name, mobile_number'
          ')',
        )
        .eq('organization_id', organizationId)
        .order('created_at', ascending: true);

    return rows.map<OrganizationMemberSummary>((rawRow) {
      final row = Map<String, dynamic>.from(rawRow);
      final profile = row['profiles'] is Map
          ? Map<String, dynamic>.from(row['profiles'] as Map)
          : const <String, dynamic>{};
      final role = row['roles'] is Map
          ? Map<String, dynamic>.from(row['roles'] as Map)
          : const <String, dynamic>{};

      final firstName = (profile['first_name'] ?? '').toString().trim();
      final middleName = (profile['middle_name'] ?? '').toString().trim();
      final lastName = (profile['last_name'] ?? '').toString().trim();
      final nameParts = [
        firstName,
        if (middleName.isNotEmpty) middleName,
        lastName,
      ].where((part) => part.isNotEmpty).toList();

      return OrganizationMemberSummary(
        membershipId: (row['id'] ?? '').toString(),
        userId: (row['user_id'] ?? '').toString(),
        fullName: nameParts.isEmpty ? 'Unknown member' : nameParts.join(' '),
        mobileNumber: (profile['mobile_number'] ?? '').toString().trim().isEmpty
            ? null
            : (profile['mobile_number'] ?? '').toString().trim(),
        roleCode: (role['code'] ?? '').toString(),
        status: (row['status'] ?? 'active').toString(),
      );
    }).toList();
  }

  Future<AdminFinancialSummary> getAdminFinancialSummary(
    String organizationId,
  ) async {
    if (organizationId.isEmpty) {
      return const AdminFinancialSummary(organizationId: '');
    }

    double asDouble(Object? value) => (value as num?)?.toDouble() ?? 0.0;

    final salesRows = await SupabaseService.client
        .from('sales')
        .select('total_amount')
        .eq('organization_id', organizationId);

    final receivableRows = await SupabaseService.client
        .from('receivables')
        .select('remaining_amount, status')
        .eq('organization_id', organizationId);

    final paymentRows = await SupabaseService.client
        .from('receivable_payments')
        .select('amount')
        .eq('organization_id', organizationId);

    final totalSales = salesRows.fold<double>(
      0,
      (sum, row) => sum + asDouble(row['total_amount']),
    );

    var outstandingReceivables = 0.0;
    var unpaidReceivablesCount = 0;
    for (final row in receivableRows) {
      final remainingAmount = asDouble(row['remaining_amount']);
      final status = (row['status'] ?? '').toString();
      outstandingReceivables += remainingAmount;
      if (remainingAmount > 0 || status == 'unpaid' || status == 'partial') {
        unpaidReceivablesCount += 1;
      }
    }

    final collectedPayments = paymentRows.fold<double>(
      0,
      (sum, row) => sum + asDouble(row['amount']),
    );

    return AdminFinancialSummary(
      organizationId: organizationId,
      totalSales: totalSales,
      outstandingReceivables: outstandingReceivables,
      collectedPayments: collectedPayments,
      salesCount: salesRows.length,
      unpaidReceivablesCount: unpaidReceivablesCount,
    );
  }
}
