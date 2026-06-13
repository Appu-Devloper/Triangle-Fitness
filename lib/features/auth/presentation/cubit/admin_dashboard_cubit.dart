import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';

enum AdminDashboardStatus {
  initial,
  loading,
  success,
  failure,
  signingOut,
  signedOut,
}

class AdminDashboardState extends Equatable {
  const AdminDashboardState({
    this.status = AdminDashboardStatus.initial,
    this.dashboard,
    this.message,
  });

  final AdminDashboardStatus status;
  final AdminDashboard? dashboard;
  final String? message;

  @override
  List<Object?> get props => [status, dashboard, message];
}

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit(this._repository) : super(const AdminDashboardState());

  final AuthRepository _repository;

  Future<void> load() async {
    emit(const AdminDashboardState(status: AdminDashboardStatus.loading));
    try {
      final dashboard = await _repository.getCurrentAdminDashboard();
      emit(
        AdminDashboardState(
          status: AdminDashboardStatus.success,
          dashboard: dashboard,
        ),
      );
    } on AuthFailure catch (error) {
      emit(
        AdminDashboardState(
          status: AdminDashboardStatus.failure,
          message: error.message,
        ),
      );
    } on Object catch (error) {
      emit(
        AdminDashboardState(
          status: AdminDashboardStatus.failure,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> signOut() async {
    emit(
      AdminDashboardState(
        status: AdminDashboardStatus.signingOut,
        dashboard: state.dashboard,
      ),
    );
    try {
      await _repository.signOut();
      emit(const AdminDashboardState(status: AdminDashboardStatus.signedOut));
    } on Object catch (error) {
      emit(
        AdminDashboardState(
          status: AdminDashboardStatus.failure,
          dashboard: state.dashboard,
          message: error.toString(),
        ),
      );
    }
  }
}
