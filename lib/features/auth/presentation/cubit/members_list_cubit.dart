import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_member.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/member_management_repository.dart';

enum MembersListStatus { initial, loading, success, failure }

enum MembersFilter { all, active, inactive, expired }

class MembersListState extends Equatable {
  const MembersListState({
    this.status = MembersListStatus.initial,
    this.members = const [],
    this.searchQuery = '',
    this.filter = MembersFilter.all,
    this.message,
  });

  final MembersListStatus status;
  final List<AdminMember> members;
  final String searchQuery;
  final MembersFilter filter;
  final String? message;

  List<AdminMember> visibleMembers(DateTime now) {
    return members.where((member) {
      if (!member.matchesSearch(searchQuery)) return false;
      if (filter == MembersFilter.all) return true;
      return member.effectiveStatusOn(now) == filter.name.toUpperCase();
    }).toList();
  }

  MembersListState copyWith({
    MembersListStatus? status,
    List<AdminMember>? members,
    String? searchQuery,
    MembersFilter? filter,
    String? message,
    bool clearMessage = false,
  }) {
    return MembersListState(
      status: status ?? this.status,
      members: members ?? this.members,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, members, searchQuery, filter, message];
}

class MembersListCubit extends Cubit<MembersListState> {
  MembersListCubit(this._repository) : super(const MembersListState());

  final MemberManagementRepository _repository;
  StreamSubscription<List<AdminMember>>? _subscription;

  Future<void> watch() async {
    emit(state.copyWith(status: MembersListStatus.loading, clearMessage: true));
    await _subscription?.cancel();
    _subscription = _repository.watchMembers().listen(
      (members) => emit(
        state.copyWith(
          status: MembersListStatus.success,
          members: members,
          clearMessage: true,
        ),
      ),
      onError: (Object error) {
        final message = error is MemberManagementFailure
            ? error.message
            : error.toString();
        emit(
          state.copyWith(status: MembersListStatus.failure, message: message),
        );
      },
    );
  }

  void search(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void filterBy(MembersFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
