import 'app_organization.dart';
import 'authenticated_session.dart';

class AppSessionState {
  final AuthenticatedSession? authenticatedSession;
  final AppOrganization? selectedOrganization;
  final List<AppOrganization> organizations;
  final bool isBackendMode;

  const AppSessionState({
    required this.authenticatedSession,
    required this.selectedOrganization,
    this.organizations = const [],
    required this.isBackendMode,
  });
}
