part of 'home_bloc.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.content,
    this.section = HomeSection.home,
    this.navigationRequestId = 0,
    this.message,
    this.messageRequestId = 0,
  });

  final HomeStatus status;
  final GymContent? content;
  final HomeSection section;
  final int navigationRequestId;
  final String? message;
  final int messageRequestId;

  HomeState copyWith({
    HomeStatus? status,
    GymContent? content,
    HomeSection? section,
    int? navigationRequestId,
    String? message,
    int? messageRequestId,
    bool clearMessage = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      content: content ?? this.content,
      section: section ?? this.section,
      navigationRequestId: navigationRequestId ?? this.navigationRequestId,
      message: clearMessage ? null : message ?? this.message,
      messageRequestId: messageRequestId ?? this.messageRequestId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    content,
    section,
    navigationRequestId,
    message,
    messageRequestId,
  ];
}
