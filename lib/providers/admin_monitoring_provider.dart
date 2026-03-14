import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_financial_summary.dart';
import '../models/admin_organization_summary.dart';
import '../models/organization_member_summary.dart';
import 'app_session_provider.dart';
import 'auth_provider.dart';

final adminOrganizationSummariesProvider =
    FutureProvider<Map<String, AdminOrganizationSummary>>((ref) async {
      final repository = ref.watch(authRepositoryProvider);
      if (!repository.isAvailable) {
        return const {};
      }

      final session = await ref.watch(currentAppSessionProvider.future);
      final organizationIds = session.organizations
          .map((organization) => organization.id)
          .where((id) => id.isNotEmpty)
          .toList();

      if (organizationIds.isEmpty) {
        return const {};
      }

      return repository.getAdminOrganizationSummaries(organizationIds);
    });

final organizationMembersProvider =
    FutureProvider.family<List<OrganizationMemberSummary>, String>((
      ref,
      organizationId,
    ) async {
      final repository = ref.watch(authRepositoryProvider);
      if (!repository.isAvailable || organizationId.isEmpty) {
        return const [];
      }

      return repository.getOrganizationMembers(organizationId);
    });

final adminFinancialSummaryProvider =
    FutureProvider.family<AdminFinancialSummary, String>((ref, organizationId) async {
      final repository = ref.watch(authRepositoryProvider);
      if (!repository.isAvailable || organizationId.isEmpty) {
        return AdminFinancialSummary(organizationId: organizationId);
      }

      return repository.getAdminFinancialSummary(organizationId);
    });
