import 'package:equatable/equatable.dart';

class MemberSession extends Equatable {
  const MemberSession({
    required this.memberId,
    required this.mustChangePassword,
  });

  final String memberId;
  final bool mustChangePassword;

  @override
  List<Object> get props => [memberId, mustChangePassword];
}
