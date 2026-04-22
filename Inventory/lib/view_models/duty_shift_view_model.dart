import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/current_user.dart';
import '../models/duty_shift_model.dart';
import '../repositories/duty_shift_repository.dart';
import '../services/db_service.dart';

class DutyShiftState {
  final DutyShift? activeShift;
  final List<DutyShift> history;
  final bool isLoading;
  final String? error;

  const DutyShiftState({
    this.activeShift,
    this.history = const [],
    this.isLoading = false,
    this.error,
  });
}

class DutyShiftNotifier extends StateNotifier<DutyShiftState> {
  DutyShiftNotifier() : super(const DutyShiftState(isLoading: true)) {
    load();
  }

  Future<DutyShiftRepository> _repo() async {
    final db = await DBService.instance.database;
    return DutyShiftRepository(db);
  }

  Future<void> load() async {
    final accountId = CurrentUser.accountId;
    if (accountId == null) {
      state = const DutyShiftState();
      return;
    }
    state = const DutyShiftState(isLoading: true);
    try {
      final repo = await _repo();
      final active = await repo.getActiveShift(accountId);
      final history = await repo.getHistory(accountId);
      state = DutyShiftState(activeShift: active, history: history);
    } catch (e) {
      state = DutyShiftState(error: e.toString());
    }
  }

  Future<void> startShift() async {
    final memberId = CurrentUser.memberId;
    final accountId = CurrentUser.accountId;
    if (memberId == null || accountId == null) return;

    final parts = [
      CurrentUser.firstName ?? '',
      if ((CurrentUser.middleName ?? '').isNotEmpty) CurrentUser.middleName!,
      CurrentUser.lastName ?? '',
    ].where((s) => s.isNotEmpty);
    final memberName = parts.join(' ');

    try {
      final repo = await _repo();
      await repo.startShift(
        memberId: memberId,
        accountId: accountId,
        memberName: memberName,
      );
      await load();
    } catch (e) {
      state = DutyShiftState(
        activeShift: state.activeShift,
        history: state.history,
        error: e.toString(),
      );
    }
  }

  Future<void> endShift() async {
    final shiftId = state.activeShift?.id;
    if (shiftId == null) return;
    try {
      final repo = await _repo();
      await repo.endShift(shiftId);
      await load();
    } catch (e) {
      state = DutyShiftState(
        activeShift: state.activeShift,
        history: state.history,
        error: e.toString(),
      );
    }
  }
}

final dutyShiftProvider =
    StateNotifierProvider.autoDispose<DutyShiftNotifier, DutyShiftState>(
  (_) => DutyShiftNotifier(),
);
