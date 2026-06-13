import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<void> loginMember({
    required String phone,
    required String password,
  }) async {
    emit(const AuthState(status: AuthStatus.loading));
    try {
      final session = await _repository.signInMember(
        phone: phone,
        password: password,
      );
      emit(
        AuthState(
          status: AuthStatus.success,
          destination: session.mustChangePassword
              ? AuthDestination.changePassword
              : AuthDestination.memberDashboard,
          memberId: session.memberId,
        ),
      );
    } on AuthFailure catch (error, stackTrace) {
      debugPrint('Member login failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      emit(AuthState(status: AuthStatus.failure, message: error.message));
    } on Object catch (error, stackTrace) {
      debugPrint('Member login failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      emit(AuthState(status: AuthStatus.failure, message: error.toString()));
    }
  }

  Future<void> loginAdmin({
    required String email,
    required String password,
  }) async {
    emit(const AuthState(status: AuthStatus.loading));
    try {
      await _repository.signInAdmin(email: email, password: password);
      emit(
        const AuthState(
          status: AuthStatus.success,
          destination: AuthDestination.adminDashboard,
        ),
      );
    } on AuthFailure catch (error, stackTrace) {
      debugPrint('Admin login failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      emit(AuthState(status: AuthStatus.failure, message: error.message));
    } on Object catch (error, stackTrace) {
      debugPrint('Admin login failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      emit(AuthState(status: AuthStatus.failure, message: error.toString()));
    }
  }

  Future<void> changePassword({
    required String newPassword,
    required String memberId,
  }) async {
    emit(const AuthState(status: AuthStatus.loading));
    try {
      await _repository.changePassword(newPassword);
      emit(
        AuthState(
          status: AuthStatus.success,
          destination: AuthDestination.memberDashboard,
          memberId: memberId,
        ),
      );
    } on AuthenticationRequiredFailure catch (error, stackTrace) {
      debugPrint('Change password failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      emit(
        AuthState(
          status: AuthStatus.failure,
          destination: AuthDestination.memberLogin,
          message: error.message,
        ),
      );
    } on AuthFailure catch (error, stackTrace) {
      debugPrint('Change password failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      emit(AuthState(status: AuthStatus.failure, message: error.message));
    } on Object catch (error, stackTrace) {
      debugPrint('Change password failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      emit(AuthState(status: AuthStatus.failure, message: error.toString()));
    }
  }

  Future<void> signOut() async {
    emit(const AuthState(status: AuthStatus.loading));
    try {
      await _repository.signOut();
      emit(
        const AuthState(
          status: AuthStatus.success,
          destination: AuthDestination.home,
        ),
      );
    } on Object {
      emit(
        const AuthState(
          status: AuthStatus.failure,
          message: 'Unable to sign out right now.',
        ),
      );
    }
  }
}
