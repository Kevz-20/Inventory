import 'app_user_profile.dart';
import 'organization_membership_model.dart';

class AuthenticatedSession {
  final String userId;
  final String? email;
  final AppUserProfile profile;
  final List<OrganizationMembershipModel> memberships;

  const AuthenticatedSession({
    required this.userId,
    required this.email,
    required this.profile,
    required this.memberships,
  });
}
