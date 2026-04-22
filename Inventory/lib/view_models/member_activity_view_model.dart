import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/member_activity_repository.dart';
import '../services/db_service.dart';

enum MemberDateFilter { today, week, month, custom }

class MemberActivityState {
  final List<MemberActivitySummary> members;
  final MemberDateFilter filter;
  final DateTime fromDate;
  final DateTime toDate;
  final bool isLoading;
  final String? error;

  const MemberActivityState({
    this.members = const [],
    this.filter = MemberDateFilter.today,
    required this.fromDate,
    required this.toDate,
    this.isLoading = false,
    this.error,
  });

  MemberActivityState copyWith({
    List<MemberActivitySummary>? members,
    MemberDateFilter? filter,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isLoading,
    String? error,
  }) =>
      MemberActivityState(
        members: members ?? this.members,
        filter: filter ?? this.filter,
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class MemberActivityNotifier
    extends StateNotifier<MemberActivityState> {
  MemberActivityNotifier()
      : super(MemberActivityState(
          fromDate: DateTime.now(),
          toDate: DateTime.now(),
        )) {
    load();
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final db = await DBService.instance.database;
      final result = await MemberActivityRepository(db).getActivity(
        fromDate: _fmt(state.fromDate),
        toDate: _fmt(state.toDate),
      );
      state = state.copyWith(members: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(MemberDateFilter filter) {
    if (filter == MemberDateFilter.custom) return;
    final now = DateTime.now();
    DateTime from;
    switch (filter) {
      case MemberDateFilter.today:
        from = now;
      case MemberDateFilter.week:
        from = now.subtract(Duration(days: now.weekday - 1));
      case MemberDateFilter.month:
        from = DateTime(now.year, now.month, 1);
      case MemberDateFilter.custom:
        return;
    }
    state = state.copyWith(filter: filter, fromDate: from, toDate: now);
    load();
  }

  Future<void> setCustomRange(DateTime from, DateTime to) async {
    state = state.copyWith(
      filter: MemberDateFilter.custom,
      fromDate: from,
      toDate: to,
    );
    await load();
  }
}

final memberActivityProvider = StateNotifierProvider.autoDispose<
    MemberActivityNotifier, MemberActivityState>(
  (_) => MemberActivityNotifier(),
);
