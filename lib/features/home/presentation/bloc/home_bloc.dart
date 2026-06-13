import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triangle_fitness/features/home/domain/entities/gym_content.dart';
import 'package:triangle_fitness/features/home/domain/entities/home_action.dart';
import 'package:triangle_fitness/features/home/domain/usecases/get_gym_content.dart';
import 'package:triangle_fitness/features/home/domain/usecases/open_external_link.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required GetGymContent getGymContent,
    required OpenExternalLink openExternalLink,
  }) : _getGymContent = getGymContent,
       _openExternalLink = openExternalLink,
       super(const HomeState()) {
    on<HomeStarted>(_onStarted);
    on<HomeNavigationRequested>(_onNavigationRequested);
    on<HomeExternalActionRequested>(_onExternalActionRequested);
  }

  final GetGymContent _getGymContent;
  final OpenExternalLink _openExternalLink;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final content = await _getGymContent();
      emit(state.copyWith(status: HomeStatus.success, content: content));
    } on Object {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          message: 'Unable to load gym content.',
        ),
      );
    }
  }

  void _onNavigationRequested(
    HomeNavigationRequested event,
    Emitter<HomeState> emit,
  ) {
    emit(
      state.copyWith(
        section: event.section,
        navigationRequestId: state.navigationRequestId + 1,
        clearMessage: true,
      ),
    );
  }

  Future<void> _onExternalActionRequested(
    HomeExternalActionRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final opened = await _openExternalLink(event.action);
      if (!opened) {
        emit(
          state.copyWith(
            message: 'Could not open this link.',
            messageRequestId: state.messageRequestId + 1,
          ),
        );
      }
    } on Object {
      emit(
        state.copyWith(
          message: 'Could not open this link.',
          messageRequestId: state.messageRequestId + 1,
        ),
      );
    }
  }
}
