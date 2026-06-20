part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

final class HomeNavigationRequested extends HomeEvent {
  const HomeNavigationRequested(this.section);

  final HomeSection section;

  @override
  List<Object> get props => [section];
}

final class HomeExternalActionRequested extends HomeEvent {
  const HomeExternalActionRequested(this.action);

  final ExternalAction action;

  @override
  List<Object> get props => [action];
}

final class HomeExternalUrlRequested extends HomeEvent {
  const HomeExternalUrlRequested(this.url);

  final String url;

  @override
  List<Object> get props => [url];
}
