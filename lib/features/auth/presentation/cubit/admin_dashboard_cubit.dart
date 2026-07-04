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
    this.periodStart,
  });

  final AdminDashboardStatus status;
  final AdminDashboard? dashboard;
  final String? message;
  final DateTime? periodStart;

  @override
  List<Object?> get props => [status, dashboard, message, periodStart];
}

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit(this._repository) : super(const AdminDashboardState());

  final AuthRepository _repository;

  Future<void> load({DateTime? periodStart}) async {
    final selectedPeriod = _collectionPeriodStart(
      periodStart ?? state.periodStart ?? DateTime.now(),
    );
    emit(
      AdminDashboardState(
        status: AdminDashboardStatus.loading,
        dashboard: state.dashboard,
        periodStart: selectedPeriod,
      ),
    );
    try {
      final dashboard = await _repository.getCurrentAdminDashboard(
        periodStart: selectedPeriod,
      );
      emit(
        AdminDashboardState(
          status: AdminDashboardStatus.success,
          dashboard: dashboard,
          periodStart: selectedPeriod,
        ),
      );
    } on AuthFailure catch (error) {
      emit(
        AdminDashboardState(
          status: AdminDashboardStatus.failure,
          message: error.message,
          periodStart: selectedPeriod,
        ),
      );
    } on Object catch (error) {
      emit(
        AdminDashboardState(
          status: AdminDashboardStatus.failure,
          message: error.toString(),
          periodStart: selectedPeriod,
        ),
      );
    }
  }

  Future<void> signOut() async {
    emit(
      AdminDashboardState(
        status: AdminDashboardStatus.signingOut,
        dashboard: state.dashboard,
        periodStart: state.periodStart,
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
          periodStart: state.periodStart,
        ),
      );
    }
  }

  DateTime _collectionPeriodStart(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);
    if (day.day >= 10) return DateTime(day.year, day.month, 10);
    return DateTime(day.year, day.month - 1, 10);
  }
}
