import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';

enum MemberDashboardStatus {
  initial,
  loading,
  success,
  failure,
  signingOut,
  signedOut,
}

class MemberDashboardState extends Equatable {
  const MemberDashboardState({
    this.status = MemberDashboardStatus.initial,
    this.dashboard,
    this.message,
  });

  final MemberDashboardStatus status;
  final MemberDashboard? dashboard;
  final String? message;

  @override
  List<Object?> get props => [status, dashboard, message];
}

class MemberDashboardCubit extends Cubit<MemberDashboardState> {
  MemberDashboardCubit(this._repository) : super(const MemberDashboardState());

  final AuthRepository _repository;

  Future<void> load() async {
    emit(const MemberDashboardState(status: MemberDashboardStatus.loading));
    try {
      final dashboard = await _repository.getCurrentMemberDashboard();
      emit(
        MemberDashboardState(
          status: MemberDashboardStatus.success,
          dashboard: dashboard,
        ),
      );
    } on AuthFailure catch (error) {
      emit(
        MemberDashboardState(
          status: MemberDashboardStatus.failure,
          message: error.message,
        ),
      );
    } on Object catch (error) {
      emit(
        MemberDashboardState(
          status: MemberDashboardStatus.failure,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> signOut() async {
    emit(
      MemberDashboardState(
        status: MemberDashboardStatus.signingOut,
        dashboard: state.dashboard,
      ),
    );
    try {
      await _repository.signOut();
      emit(const MemberDashboardState(status: MemberDashboardStatus.signedOut));
    } on Object catch (error) {
      emit(
        MemberDashboardState(
          status: MemberDashboardStatus.failure,
          dashboard: state.dashboard,
          message: error.toString(),
        ),
      );
    }
  }
}
