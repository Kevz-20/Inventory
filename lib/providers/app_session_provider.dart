import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_organization.dart';
import '../models/app_session_state.dart';
import 'auth_provider.dart';

final currentAppSessionProvider = FutureProvider<AppSessionState>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  if (!repository.isAvailable) {
    return const AppSessionState(
      authenticatedSession: null,
      selectedOrganization: null,
      organizations: [],
      isBackendMode: false,
    );
  }

  final session = await repository.loadAuthenticatedSession();
  if (session == null) {
    return const AppSessionState(
      authenticatedSession: null,
      selectedOrganization: null,
      organizations: [],
      isBackendMode: true,
    );
  }

  final prefs = await SharedPreferences.getInstance();
  final savedOrganizationId = prefs.getString('selectedOrganizationId');
  final membershipOrgIds = session.memberships
      .map((membership) => membership.organizationId)
      .toSet()
      .toList();

  final organizations = await repository.getOrganizationsByIds(membershipOrgIds);

  AppOrganization? selectedOrganization;
  if (savedOrganizationId != null && savedOrganizationId.isNotEmpty) {
    for (final organization in organizations) {
      if (organization.id == savedOrganizationId) {
        selectedOrganization = organization;
        break;
      }
    }
  }

  selectedOrganization ??=
      organizations.isNotEmpty ? organizations.first : null;

  if (selectedOrganization != null &&
      selectedOrganization.id != savedOrganizationId) {
    await prefs.setString('selectedOrganizationId', selectedOrganization.id);
  }

  return AppSessionState(
    authenticatedSession: session,
    selectedOrganization: selectedOrganization,
    organizations: organizations,
    isBackendMode: true,
  );
});

class SelectedOrganizationNotifier extends AsyncNotifier<AppOrganization?> {
  @override
  Future<AppOrganization?> build() async {
    final session = await ref.watch(currentAppSessionProvider.future);
    return session.selectedOrganization;
  }

  Future<void> setSelectedOrganization(AppOrganization organization) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedOrganizationId', organization.id);
    state = AsyncData(organization);
    ref.invalidate(currentAppSessionProvider);
  }
}

final selectedOrganizationProvider =
    AsyncNotifierProvider<SelectedOrganizationNotifier, AppOrganization?>(
      SelectedOrganizationNotifier.new,
    );
