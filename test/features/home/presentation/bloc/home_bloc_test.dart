import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_fitness/features/home/domain/entities/gym_content.dart';
import 'package:triangle_fitness/features/home/domain/entities/home_action.dart';
import 'package:triangle_fitness/features/home/domain/repositories/external_link_repository.dart';
import 'package:triangle_fitness/features/home/domain/repositories/gym_repository.dart';
import 'package:triangle_fitness/features/home/domain/usecases/get_gym_content.dart';
import 'package:triangle_fitness/features/home/domain/usecases/open_external_link.dart';
import 'package:triangle_fitness/features/home/presentation/bloc/home_bloc.dart';

void main() {
  const content = GymContent(programs: [], equipment: []);

  HomeBloc buildBloc({bool linkOpens = true}) {
    return HomeBloc(
      getGymContent: GetGymContent(_FakeGymRepository(content)),
      openExternalLink: OpenExternalLink(
        _FakeExternalLinkRepository(linkOpens),
      ),
    );
  }

  blocTest<HomeBloc, HomeState>(
    'loads gym content when started',
    build: buildBloc,
    act: (bloc) => bloc.add(const HomeStarted()),
    expect: () => const [
      HomeState(status: HomeStatus.loading),
      HomeState(status: HomeStatus.success, content: content),
    ],
  );

  blocTest<HomeBloc, HomeState>(
    'increments the request id for repeated navigation',
    build: buildBloc,
    act: (bloc) {
      bloc
        ..add(const HomeNavigationRequested(HomeSection.programs))
        ..add(const HomeNavigationRequested(HomeSection.programs));
    },
    expect: () => const [
      HomeState(section: HomeSection.programs, navigationRequestId: 1),
      HomeState(section: HomeSection.programs, navigationRequestId: 2),
    ],
  );

  blocTest<HomeBloc, HomeState>(
    'exposes a user message when an external link cannot open',
    build: () => buildBloc(linkOpens: false),
    act: (bloc) =>
        bloc.add(const HomeExternalActionRequested(ExternalAction.call)),
    expect: () => const [
      HomeState(message: 'Could not open this link.', messageRequestId: 1),
    ],
  );

  blocTest<HomeBloc, HomeState>(
    'exposes a user message when an external url cannot open',
    build: () => buildBloc(linkOpens: false),
    act: (bloc) =>
        bloc.add(const HomeExternalUrlRequested('https://instagram.com/test')),
    expect: () => const [
      HomeState(message: 'Could not open this link.', messageRequestId: 1),
    ],
  );
}

class _FakeGymRepository implements GymRepository {
  const _FakeGymRepository(this.content);

  final GymContent content;

  @override
  Future<GymContent> getContent() async => content;
}

class _FakeExternalLinkRepository implements ExternalLinkRepository {
  const _FakeExternalLinkRepository(this.result);

  final bool result;

  @override
  Future<bool> open(ExternalAction action) async => result;

  @override
  Future<bool> openUrl(String url) async => result;
}
