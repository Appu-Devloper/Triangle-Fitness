part of 'auth_cubit.dart';

enum AuthStatus { initial, loading, success, failure }

enum AuthDestination {
  home,
  memberLogin,
  changePassword,
  memberDashboard,
  adminDashboard,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.destination,
    this.memberId,
    this.message,
  });

  final AuthStatus status;
  final AuthDestination? destination;
  final String? memberId;
  final String? message;

  @override
  List<Object?> get props => [status, destination, memberId, message];
}
