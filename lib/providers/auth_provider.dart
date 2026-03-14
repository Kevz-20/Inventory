import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/authenticated_session.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const AuthRepository();
});

final currentAuthenticatedSessionProvider =
    FutureProvider<AuthenticatedSession?>((ref) async {
      final repository = ref.watch(authRepositoryProvider);
      if (!repository.isAvailable) {
        return null;
      }
      return repository.loadAuthenticatedSession();
    });
