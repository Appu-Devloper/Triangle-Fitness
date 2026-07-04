import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triangle_fitness/core/theme/app_colors.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/admin_login_page.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/member_login_page.dart';
import 'package:triangle_fitness/features/home/domain/entities/equipment.dart';
import 'package:triangle_fitness/features/home/domain/entities/gym_profile.dart';
import 'package:triangle_fitness/features/home/domain/entities/home_action.dart';
import 'package:triangle_fitness/features/home/domain/entities/program.dart';
import 'package:triangle_fitness/features/home/domain/entities/public_subscription_plan.dart';
import 'package:triangle_fitness/features/home/domain/entities/public_transformation.dart';
import 'package:triangle_fitness/features/home/presentation/bloc/home_bloc.dart';

const _ink = AppColors.ink;
const _surface = AppColors.surface;
const _red = AppColors.red;
const _paper = AppColors.paper;
const _muted = AppColors.muted;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scrollController = ScrollController();
  final _homeKey = GlobalKey();
  final _programsKey = GlobalKey();
  final _equipmentKey = GlobalKey();
  final _aboutKey = GlobalKey();
  final _locationKey = GlobalKey();
  Timer? _logoTapResetTimer;
  int _logoTapCount = 0;

  @override
  void dispose() {
    _logoTapResetTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollTo(HomeSection section) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_scrollController.hasClients) return;

    final key = _keyFor(section);
    final target = key.currentContext;
    final renderObject = target?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final position = _scrollController.position;
    final pinnedHeaderHeight = MediaQuery.paddingOf(context).top + 78;
    final targetY = renderObject.localToGlobal(Offset.zero).dy;
    final destination =
        (_scrollController.offset + targetY - pinnedHeaderHeight - 12)
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();

    await _scrollController.animateTo(
      destination,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  GlobalKey _keyFor(HomeSection section) {
    return switch (section) {
      HomeSection.home => _homeKey,
      HomeSection.programs => _programsKey,
      HomeSection.equipment => _equipmentKey,
      HomeSection.about => _aboutKey,
      HomeSection.location => _locationKey,
    };
  }

  void _navigate(HomeSection section, {bool closeDrawer = false}) {
    if (closeDrawer) {
      Navigator.of(context).pop();
    }
    context.read<HomeBloc>().add(HomeNavigationRequested(section));
  }

  void _open(ExternalAction action) {
    context.read<HomeBloc>().add(HomeExternalActionRequested(action));
  }

  void _openUrl(String url) {
    context.read<HomeBloc>().add(HomeExternalUrlRequested(url));
  }

  Future<void> _openMemberLogin({bool closeDrawer = false}) async {
    if (closeDrawer) {
      Navigator.of(context).pop();
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MemberLoginPage()));
  }

  Future<void> _openAdminLogin() async {
    _logoTapResetTimer?.cancel();
    _logoTapCount = 0;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AdminLoginPage()));
  }

  void _handleLogoTap() {
    _logoTapCount += 1;
    _logoTapResetTimer?.cancel();
    _logoTapResetTimer = Timer(const Duration(seconds: 2), () {
      _logoTapCount = 0;
    });

    if (_logoTapCount >= 5) {
      _openAdminLogin();
      return;
    }
    _navigate(HomeSection.home);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listenWhen: (previous, current) =>
          previous.navigationRequestId != current.navigationRequestId ||
          previous.messageRequestId != current.messageRequestId,
      listener: (context, state) {
        if (state.navigationRequestId > 0) {
          _scrollTo(state.section);
        }
        if (state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        final content = state.content;
        return Scaffold(
          endDrawer: _MobileMenu(
            onNavigate: (section) => _navigate(section, closeDrawer: true),
            onCall: () => _open(ExternalAction.call),
            onMemberLogin: () => _openMemberLogin(closeDrawer: true),
          ),
          body: SelectionArea(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  automaticallyImplyLeading: false,
                  elevation: 0,
                  backgroundColor: _ink.withValues(alpha: 0.96),
                  surfaceTintColor: Colors.transparent,
                  toolbarHeight: 78,
                  titleSpacing: 0,
                  actions: const [SizedBox.shrink()],
                  title: _Header(
                    onLogoTap: _handleLogoTap,
                    onLogoLongPress: _openAdminLogin,
                    onPrograms: () => _navigate(HomeSection.programs),
                    onEquipment: () => _navigate(HomeSection.equipment),
                    onAbout: () => _navigate(HomeSection.about),
                    onLocation: () => _navigate(HomeSection.location),
                    onCall: () => _open(ExternalAction.call),
                    onMemberLogin: _openMemberLogin,
                  ),
                ),
                if (content == null)
                  SliverFillRemaining(
                    child: Center(
                      child: state.status == HomeStatus.failure
                          ? Text(state.message ?? 'Unable to load content.')
                          : const CircularProgressIndicator(),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        KeyedSubtree(
                          key: _homeKey,
                          child: HeroSection(
                            gymName: content.profile.gymName,
                            onCall: () => _open(ExternalAction.call),
                            onDirections: () =>
                                _open(ExternalAction.directions),
                            onMemberLogin: _openMemberLogin,
                          ),
                        ),
                        KeyedSubtree(
                          key: _programsKey,
                          child: ProgramsSection(programs: content.programs),
                        ),
                        const MuscleTargetSection(),
                        SubscriptionPlansSection(
                          plans: content.subscriptionPlans,
                        ),
                        KeyedSubtree(
                          key: _equipmentKey,
                          child: EquipmentSection(equipment: content.equipment),
                        ),
                        KeyedSubtree(
                          key: _aboutKey,
                          child: const ExperienceSection(),
                        ),
                        KeyedSubtree(
                          key: _locationKey,
                          child: LocationSection(
                            profile: content.profile,
                            onDirections: () =>
                                _open(ExternalAction.directions),
                            onCall: () => _open(ExternalAction.call),
                            onWhatsApp: () => _open(ExternalAction.whatsapp),
                            onInstagram: () =>
                                _openUrl(content.profile.instagramUrl),
                          ),
                        ),
                        const SiteFooter(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onLogoTap,
    required this.onLogoLongPress,
    required this.onPrograms,
    required this.onEquipment,
    required this.onAbout,
    required this.onLocation,
    required this.onCall,
    required this.onMemberLogin,
  });

  final VoidCallback onLogoTap;
  final VoidCallback onLogoLongPress;
  final VoidCallback onPrograms;
  final VoidCallback onEquipment;
  final VoidCallback onAbout;
  final VoidCallback onLocation;
  final VoidCallback onCall;
  final VoidCallback onMemberLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              InkWell(
                onTap: onLogoTap,
                onLongPress: onLogoLongPress,
                borderRadius: BorderRadius.circular(4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 172,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const Spacer(),
              if (MediaQuery.sizeOf(context).width >= 1120) ...[
                _NavButton(label: 'PROGRAMS', onTap: onPrograms),
                _NavButton(label: 'EQUIPMENT', onTap: onEquipment),
                _NavButton(label: 'WHY US', onTap: onAbout),
                _NavButton(label: 'LOCATION', onTap: onLocation),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onMemberLogin,
                  icon: const Icon(Icons.person_outline_rounded, size: 18),
                  label: const Text('MEMBER LOGIN'),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: const Text('JOIN NOW'),
                ),
              ] else
                Builder(
                  builder: (context) => IconButton(
                    onPressed: Scaffold.of(context).openEndDrawer,
                    tooltip: 'Open menu',
                    icon: const Icon(Icons.menu_rounded, size: 30),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: _paper,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _MobileMenu extends StatelessWidget {
  const _MobileMenu({
    required this.onNavigate,
    required this.onCall,
    required this.onMemberLogin,
  });

  final ValueChanged<HomeSection> onNavigate;
  final VoidCallback onCall;
  final VoidCallback onMemberLogin;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Home', HomeSection.home),
      ('Programs', HomeSection.programs),
      ('Equipment', HomeSection.equipment),
      ('Why us', HomeSection.about),
      ('Location', HomeSection.location),
    ];
    return Drawer(
      backgroundColor: _surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('assets/logo.png', height: 100, fit: BoxFit.cover),
              const SizedBox(height: 28),
              for (final item in items)
                ListTile(
                  onTap: () => onNavigate(item.$2),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  title: Text(
                    item.$1.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward, size: 18),
                ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onMemberLogin,
                icon: const Icon(Icons.person_outline_rounded),
                label: const Text('MEMBER LOGIN'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.call_outlined),
                label: const Text('CALL NANDHI'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.gymName,
    required this.onCall,
    required this.onDirections,
    required this.onMemberLogin,
  });

  final String gymName;
  final VoidCallback onCall;
  final VoidCallback onDirections;
  final VoidCallback onMemberLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_ink, Color(0xFF111315)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SectionShell(
        verticalPadding: 62,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final copy = _HeroCopy(
              gymName: gymName,
              onCall: onCall,
              onDirections: onDirections,
              onMemberLogin: onMemberLogin,
            );
            final visual = const _HeroVisual();
            return wide
                ? Row(
                    children: [
                      Expanded(flex: 10, child: copy),
                      const SizedBox(width: 54),
                      Expanded(flex: 9, child: visual),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [copy, const SizedBox(height: 42), visual],
                  );
          },
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.gymName,
    required this.onCall,
    required this.onDirections,
    required this.onMemberLogin,
  });

  final String gymName;
  final VoidCallback onCall;
  final VoidCallback onDirections;
  final VoidCallback onMemberLogin;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final headlineSize = width < 430 ? 48.0 : (width < 900 ? 64.0 : 76.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(
          text: gymName.isEmpty
              ? 'KRS ROAD  /  KRISHNARAJASAGARA'
              : gymName.toUpperCase(),
        ),
        const SizedBox(height: 20),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'BUILD YOUR\n'),
              TextSpan(
                text: 'STRONGEST',
                style: TextStyle(
                  color: _red,
                  shadows: [
                    Shadow(color: _red.withValues(alpha: 0.25), blurRadius: 24),
                  ],
                ),
              ),
              const TextSpan(text: ' SELF.'),
            ],
          ),
          style: TextStyle(
            height: 0.94,
            fontSize: headlineSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -3,
          ),
        ),
        const SizedBox(height: 26),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 590),
          child: const Text(
            'Serious equipment. Expert coaching. A motivating community built for every level of fitness.',
            style: TextStyle(
              color: _muted,
              fontSize: 18,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 34),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onCall,
              icon: const Icon(Icons.bolt_rounded, size: 20),
              label: const Text('START TRAINING'),
            ),
            OutlinedButton.icon(
              onPressed: onDirections,
              icon: const Icon(Icons.near_me_outlined, size: 19),
              label: const Text('GET DIRECTIONS'),
            ),
            OutlinedButton.icon(
              onPressed: onMemberLogin,
              icon: const Icon(Icons.person_outline_rounded, size: 19),
              label: const Text('MEMBER LOGIN'),
            ),
          ],
        ),
        const SizedBox(height: 44),
        const Wrap(
          spacing: 28,
          runSpacing: 20,
          children: [
            _HeroStat(value: '10+', label: 'TRAINING STYLES'),
            _HeroStat(value: 'PRO', label: 'COACHING'),
            _HeroStat(value: '100%', label: 'COMMITMENT'),
          ],
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.18,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2B2E31)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/logo.png', fit: BoxFit.cover),
            ),
          ),
          Positioned(
            left: -12,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(color: _red),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_outlined, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'KRS SERVICES  •  571607',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProgramsSection extends StatelessWidget {
  const ProgramsSection({super.key, required this.programs});

  final List<Program> programs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F11),
        border: Border.symmetric(
          horizontal: BorderSide(color: Color(0xFF222529)),
        ),
      ),
      child: SectionShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(
              eyebrow: 'FIND YOUR TRAINING STYLE',
              title: 'ONE GYM.\nMORE WAYS TO MOVE.',
              description:
                  'Train for strength, fitness, mobility or pure enjoyment. Choose one style or build a routine that combines them.',
            ),
            const SizedBox(height: 34),
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ProgramFilterLabel(
                  icon: Icons.fitness_center_rounded,
                  label: 'STRENGTH',
                ),
                _ProgramFilterLabel(
                  icon: Icons.favorite_border_rounded,
                  label: 'CARDIO',
                ),
                _ProgramFilterLabel(
                  icon: Icons.groups_2_outlined,
                  label: 'GROUP CLASSES',
                ),
                _ProgramFilterLabel(
                  icon: Icons.self_improvement_rounded,
                  label: 'MIND & BODY',
                ),
              ],
            ),
            const SizedBox(height: 42),
            LayoutBuilder(
              builder: (context, constraints) {
                final count = constraints.maxWidth >= 760 ? 2 : 1;
                return GridView.builder(
                  itemCount: programs.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: count == 2 ? 2.55 : 2.35,
                  ),
                  itemBuilder: (context, index) {
                    final item = programs[index];
                    return _ProgramTile(program: item);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramFilterLabel extends StatelessWidget {
  const _ProgramFilterLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF15181B),
        border: Border.all(color: const Color(0xFF2A2E32)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _red, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: _paper,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramTile extends StatefulWidget {
  const _ProgramTile({required this.program});

  final Program program;

  @override
  State<_ProgramTile> createState() => _ProgramTileState();
}

class _ProgramTileState extends State<_ProgramTile> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        transform: Matrix4.translationValues(0, hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: hovered ? const Color(0xFF1B1E21) : const Color(0xFF141719),
          border: Border.all(color: hovered ? _red : const Color(0xFF292D31)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 92,
              color: hovered ? _red : const Color(0xFF202327),
              child: Center(
                child: Icon(
                  widget.program.type.icon,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 14, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.program.category,
                      style: const TextStyle(
                        color: _red,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      widget.program.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _paper,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      widget.program.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              padding: EdgeInsets.only(right: hovered ? 14 : 18),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hovered ? _red : const Color(0xFF3C4044),
                  ),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: hovered ? _red : _muted,
                  size: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on ProgramType {
  IconData get icon => switch (this) {
    ProgramType.weightTraining => Icons.fitness_center_rounded,
    ProgramType.crossFit => Icons.timer_outlined,
    ProgramType.personalTraining => Icons.person_outline_rounded,
    ProgramType.aerobics => Icons.directions_run_rounded,
    ProgramType.cycling => Icons.directions_bike_rounded,
    ProgramType.yoga => Icons.self_improvement_rounded,
    ProgramType.zumba => Icons.music_note_rounded,
    ProgramType.danceFitness => Icons.nightlife_rounded,
    ProgramType.aquatics => Icons.pool_rounded,
    ProgramType.adultSports => Icons.sports_handball_rounded,
  };
}

class MuscleTargetSection extends StatelessWidget {
  const MuscleTargetSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF101214),
      child: SectionShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(
              eyebrow: 'EXERCISE MUSCLE GUIDE',
              title: 'MUSCLE-WISE\nEXERCISE GROUPING.',
              description:
                  'Choose a muscle group and follow a clear exercise list with sets and reps.',
            ),
            const SizedBox(height: 34),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1180
                    ? 2
                    : constraints.maxWidth >= 760
                    ? 2
                    : 1;
                const gap = 16.0;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final entry in _muscleGroups.indexed)
                      SizedBox(
                        width: width,
                        child: _MuscleGroupCard(
                          index: entry.$1 + 1,
                          group: entry.$2,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MuscleGroupCard extends StatefulWidget {
  const _MuscleGroupCard({required this.index, required this.group});

  final int index;
  final _MuscleGroup group;

  @override
  State<_MuscleGroupCard> createState() => _MuscleGroupCardState();
}

class _MuscleGroupCardState extends State<_MuscleGroupCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        transform: Matrix4.translationValues(0, hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: const Color(0xFF111417),
          border: Border.all(
            color: hovered ? group.color : const Color(0xFF2A2E32),
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: hovered
              ? [
                  BoxShadow(
                    color: group.color.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WorkoutCardHeader(index: widget.index, group: group),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0C0E10),
                border: Border(
                  top: BorderSide(color: Color(0xFF24282D)),
                  bottom: BorderSide(color: Color(0xFF24282D)),
                ),
              ),
              child: _MuscleChipWrap(
                label: 'TARGET MUSCLES',
                muscles: group.muscles,
                color: group.color,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171A1D),
                      border: Border.all(color: const Color(0xFF25292D)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          child: Text(
                            'EXERCISE',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'SETS x REPS',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ExercisePrescriptionList(
                    exercises: group.exercises,
                    color: group.color,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutCardHeader extends StatelessWidget {
  const _WorkoutCardHeader({required this.index, required this.group});

  final int index;
  final _MuscleGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            group.color.withValues(alpha: 0.24),
            const Color(0xFF111417),
            const Color(0xFF0B0D0F),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: group.color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: group.color.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(group.icon, color: Colors.white, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.focus,
                      style: TextStyle(
                        color: group.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      group.title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _paper,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                index.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.1),
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  height: 0.9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            group.description,
            style: const TextStyle(
              color: Color(0xFFC7CBD0),
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _WorkoutStatPill(
                value: group.exercises.length.toString(),
                label: 'moves',
                color: group.color,
              ),
              const SizedBox(width: 10),
              _WorkoutStatPill(
                value: group.totalSets.toString(),
                label: 'sets',
                color: group.color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WorkoutStatPill(
                  value: group.intensity,
                  label: 'focus',
                  color: group.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkoutStatPill extends StatelessWidget {
  const _WorkoutStatPill({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.26),
        border: Border.all(color: color.withValues(alpha: 0.34)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _paper,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExercisePrescriptionList extends StatelessWidget {
  const _ExercisePrescriptionList({
    required this.exercises,
    required this.color,
  });

  final List<_GroupedExercise> exercises;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F11),
        border: Border.all(color: const Color(0xFF25292D)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (final entry in exercises.indexed) ...[
            _ExercisePrescriptionRow(
              index: entry.$1 + 1,
              exercise: entry.$2,
              color: color,
            ),
            if (entry.$1 != exercises.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.white.withValues(alpha: 0.06),
              ),
          ],
        ],
      ),
    );
  }
}

class _ExercisePrescriptionRow extends StatelessWidget {
  const _ExercisePrescriptionRow({
    required this.index,
    required this.exercise,
    required this.color,
  });

  final int index;
  final _GroupedExercise exercise;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              index.toString().padLeft(2, '0'),
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              exercise.name,
              style: const TextStyle(
                color: _paper,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 132),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                exercise.prescription,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleChipWrap extends StatelessWidget {
  const _MuscleChipWrap({
    required this.label,
    required this.muscles,
    required this.color,
  });

  final String label;
  final List<String> muscles;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final muscle in muscles)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  muscle,
                  style: const TextStyle(
                    color: _paper,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MuscleGroup {
  const _MuscleGroup({
    required this.title,
    required this.focus,
    required this.description,
    required this.icon,
    required this.color,
    required this.muscles,
    required this.totalSets,
    required this.intensity,
    required this.exercises,
  });

  final String title;
  final String focus;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> muscles;
  final int totalSets;
  final String intensity;
  final List<_GroupedExercise> exercises;
}

class _GroupedExercise {
  const _GroupedExercise(this.name, this.prescription);

  final String name;
  final String prescription;
}

const _muscleGroups = [
  _MuscleGroup(
    title: 'Chest',
    focus: 'PUSH STRENGTH',
    description:
        'Pressing and fly movements for upper, mid and lower chest development.',
    icon: Icons.fitness_center_rounded,
    color: Color(0xFFE3242B),
    muscles: ['Upper Chest', 'Mid Chest', 'Lower Chest', 'Triceps'],
    totalSets: 21,
    intensity: 'push',
    exercises: [
      _GroupedExercise('Barbell Bench Press', '4 sets x 6-8 reps'),
      _GroupedExercise('Incline Dumbbell Press', '3 sets x 8-10 reps'),
      _GroupedExercise('Decline Hammer Strength Press', '3 sets x 10 reps'),
      _GroupedExercise('Incline Dumbbell Flyes', '3 sets x 12 reps'),
      _GroupedExercise('Low-to-High Cable Flyes', '3 sets x 12 reps'),
      _GroupedExercise('Chest Dips', '3 sets x failure'),
      _GroupedExercise('Push-ups Finisher', '2 sets x failure'),
    ],
  ),
  _MuscleGroup(
    title: 'Back',
    focus: 'WIDTH & THICKNESS',
    description:
        'Heavy pulls, rows and pulldowns for lats, mid back and lower back.',
    icon: Icons.rowing_rounded,
    color: Color(0xFF3F8CFF),
    muscles: ['Lats', 'Mid Back', 'Lower Back', 'Rear Delts', 'Biceps'],
    totalSets: 27,
    intensity: 'pull',
    exercises: [
      _GroupedExercise('Deadlifts', '4 sets x 5 reps'),
      _GroupedExercise('Barbell Rows', '4 sets x 8 reps'),
      _GroupedExercise('Wide-Grip Lat Pulldowns', '3 sets x 10-12 reps'),
      _GroupedExercise('Seated Cable Rows', '3 sets x 10 reps'),
      _GroupedExercise('Single-Arm Dumbbell Rows', '3 sets x 10 reps'),
      _GroupedExercise('Straight-Arm Pulldowns', '3 sets x 12 reps'),
      _GroupedExercise('Hyperextensions', '3 sets x 15 reps'),
      _GroupedExercise('Pull-ups', '3 sets x failure'),
    ],
  ),
  _MuscleGroup(
    title: 'Legs',
    focus: 'LOWER BODY',
    description:
        'Squats, hinges, presses and isolation work for complete leg training.',
    icon: Icons.airline_seat_legroom_extra,
    color: Color(0xFFFF8A3D),
    muscles: ['Quads', 'Hamstrings', 'Glutes', 'Calves'],
    totalSets: 27,
    intensity: 'power',
    exercises: [
      _GroupedExercise('Barbell Back Squats', '4 sets x 6-8 reps'),
      _GroupedExercise('Romanian Deadlifts', '4 sets x 8-10 reps'),
      _GroupedExercise('Leg Press', '3 sets x 10-12 reps'),
      _GroupedExercise('Leg Extensions', '3 sets x 15 reps'),
      _GroupedExercise('Lying Leg Curls', '3 sets x 15 reps'),
      _GroupedExercise('Standing Calf Raises', '4 sets x 15 reps'),
      _GroupedExercise('Seated Calf Raises', '3 sets x 20 reps'),
      _GroupedExercise('Walking Lunges', '3 sets x 12 steps per leg'),
    ],
  ),
  _MuscleGroup(
    title: 'Shoulders',
    focus: 'DELTS & TRAPS',
    description:
        'Pressing, raises and rear-delt work for round shoulders and strong traps.',
    icon: Icons.accessibility_new_rounded,
    color: Color(0xFF28A86B),
    muscles: ['Front Delts', 'Side Delts', 'Rear Delts', 'Traps'],
    totalSets: 25,
    intensity: 'delts',
    exercises: [
      _GroupedExercise('Overhead Barbell Press', '4 sets x 6-8 reps'),
      _GroupedExercise('Seated Dumbbell Shoulder Press', '3 sets x 10 reps'),
      _GroupedExercise('Dumbbell Lateral Raises', '4 sets x 12-15 reps'),
      _GroupedExercise('Cable Lateral Raises', '3 sets x 15 reps'),
      _GroupedExercise('Rear Delt Dumbbell Flyes', '4 sets x 12 reps'),
      _GroupedExercise('Face Pulls', '3 sets x 15 reps'),
      _GroupedExercise('Barbell Shrugs', '4 sets x 10-12 reps'),
    ],
  ),
  _MuscleGroup(
    title: 'Arms',
    focus: 'BICEPS & TRICEPS',
    description:
        'Curl and extension variations for balanced biceps, triceps and forearms.',
    icon: Icons.sports_gymnastics_rounded,
    color: Color(0xFF8A63FF),
    muscles: ['Biceps', 'Triceps', 'Brachialis', 'Forearms'],
    totalSets: 23,
    intensity: 'arms',
    exercises: [
      _GroupedExercise('Barbell Bicep Curls', '3 sets x 8-10 reps'),
      _GroupedExercise('Close-Grip Bench Press', '3 sets x 8-10 reps'),
      _GroupedExercise('Incline Dumbbell Curls', '3 sets x 10-12 reps'),
      _GroupedExercise('Tricep Overhead Extension', '3 sets x 10-12 reps'),
      _GroupedExercise('Hammer Curls', '3 sets x 12 reps'),
      _GroupedExercise('Tricep Cable Pushdowns', '3 sets x 12-15 reps'),
      _GroupedExercise('EZ-Bar Preacher Curls', '3 sets x 12 reps'),
      _GroupedExercise('Diamond Push-ups', '2 sets x failure'),
    ],
  ),
];

class SubscriptionPlansSection extends StatelessWidget {
  const SubscriptionPlansSection({super.key, required this.plans});

  final List<PublicSubscriptionPlan> plans;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _ink,
      child: SectionShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(
              eyebrow: 'MEMBERSHIP OFFERS',
              title: 'SIMPLE PLANS.\nBETTER SAVINGS.',
              description:
                  'Discounts are calculated against ₹1500 per month, so every offer is easy to compare.',
            ),
            const SizedBox(height: 36),
            if (plans.isEmpty)
              const _PublicEmptyState(
                icon: Icons.card_membership_outlined,
                message: 'No plans available',
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1120
                      ? 3
                      : constraints.maxWidth >= 720
                      ? 2
                      : 1;
                  const gap = 18.0;
                  final width =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  final rankedPlans = _rankPlans(plans);
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final entry in rankedPlans.indexed)
                        SizedBox(
                          width: width,
                          child: _PublicPlanCard(
                            plan: entry.$2,
                            position: entry.$1 + 1,
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PublicPlanCard extends StatefulWidget {
  const _PublicPlanCard({required this.plan, required this.position});

  final PublicSubscriptionPlan plan;
  final int position;

  @override
  State<_PublicPlanCard> createState() => _PublicPlanCardState();
}

class _PublicPlanCardState extends State<_PublicPlanCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final offer = _PlanOffer.fromPlan(plan);
    final isBestValue = widget.position == 1 && offer.savings > 0;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
        height: 330,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _hovered ? const Color(0xFF251517) : const Color(0xFF191C20),
              isBestValue ? const Color(0xFF15100F) : _surface,
            ],
          ),
          border: Border.all(
            color: isBestValue || _hovered ? _red : const Color(0xFF2A2D30),
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: _red.withValues(alpha: 0.18),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBestValue)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                color: _red,
                child: const Text(
                  'BEST VALUE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              )
            else
              Container(height: 4, color: const Color(0xFF2A2D30)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _red.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _red.withValues(alpha: 0.28),
                            ),
                          ),
                          child: const Icon(
                            Icons.local_offer_outlined,
                            color: _red,
                            size: 24,
                          ),
                        ),
                        const Spacer(),
                        _DiscountBadge(offer: offer),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      plan.name.isEmpty ? 'Subscription Plan' : plan.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _paper,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.03,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: _muted,
                          size: 15,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${offer.months} month${offer.months == 1 ? '' : 's'} membership',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${_publicNumber(plan.price)}',
                          style: const TextStyle(
                            color: _paper,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '₹${_publicNumber(offer.effectiveMonthly)}/mo',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SavingsStrip(offer: offer),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const MemberLoginPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                        label: const Text('CHOOSE PLAN'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _hovered || isBestValue
                              ? _red
                              : const Color(0xFF25292E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.offer});

  final _PlanOffer offer;

  @override
  Widget build(BuildContext context) {
    final label = offer.discountPercent > 0
        ? '${offer.discountPercent}% OFF'
        : 'MONTHLY';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _red,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _red.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SavingsStrip extends StatelessWidget {
  const _SavingsStrip({required this.offer});

  final _PlanOffer offer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.1),
        border: Border.all(color: _red.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        offer.savings > 0
            ? 'Save ₹${_publicNumber(offer.savings)}  •  Worth ₹${_publicNumber(offer.basePrice)}'
            : 'Calculated from ₹1500/month',
        style: const TextStyle(
          color: Color(0xFFFFC7C9),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
      ),
    );
  }
}

class _PlanOffer {
  const _PlanOffer({
    required this.months,
    required this.basePrice,
    required this.savings,
    required this.discountPercent,
    required this.effectiveMonthly,
  });

  final int months;
  final double basePrice;
  final double savings;
  final int discountPercent;
  final double effectiveMonthly;

  static const monthlyBasePrice = 1500.0;

  factory _PlanOffer.fromPlan(PublicSubscriptionPlan plan) {
    final months = (plan.durationDays / 30).round().clamp(1, 36);
    final basePrice = monthlyBasePrice * months;
    final savings = (basePrice - plan.price)
        .clamp(0, double.infinity)
        .toDouble();
    final discountPercent = basePrice <= 0
        ? 0
        : ((savings / basePrice) * 100).round();
    final effectiveMonthly = plan.price / months;
    return _PlanOffer(
      months: months,
      basePrice: basePrice,
      savings: savings,
      discountPercent: discountPercent,
      effectiveMonthly: effectiveMonthly,
    );
  }
}

List<PublicSubscriptionPlan> _rankPlans(List<PublicSubscriptionPlan> plans) {
  final ranked = List<PublicSubscriptionPlan>.of(plans);
  ranked.sort((a, b) {
    final aOffer = _PlanOffer.fromPlan(a);
    final bOffer = _PlanOffer.fromPlan(b);
    final savingsResult = bOffer.savings.compareTo(aOffer.savings);
    if (savingsResult != 0) return savingsResult;
    final discountResult = bOffer.discountPercent.compareTo(
      aOffer.discountPercent,
    );
    if (discountResult != 0) return discountResult;
    return a.durationDays.compareTo(b.durationDays);
  });
  return ranked;
}

class TransformationsSection extends StatelessWidget {
  const TransformationsSection({super.key, required this.transformations});

  final List<PublicTransformation> transformations;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F11),
        border: Border.symmetric(
          horizontal: BorderSide(color: Color(0xFF222529)),
        ),
      ),
      child: SectionShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(
              eyebrow: 'REAL MEMBER PROGRESS',
              title: 'TRANSFORMATIONS',
              description:
                  'Results built through consistent training and commitment.',
            ),
            const SizedBox(height: 36),
            if (transformations.isEmpty)
              const _PublicEmptyState(
                icon: Icons.insights_outlined,
                message: 'No transformations available',
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900 ? 3 : 1;
                  const gap = 16.0;
                  final width =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final item in transformations)
                        SizedBox(
                          width: width,
                          child: _PublicTransformationCard(item: item),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PublicTransformationCard extends StatefulWidget {
  const _PublicTransformationCard({required this.item});

  final PublicTransformation item;

  @override
  State<_PublicTransformationCard> createState() =>
      _PublicTransformationCardState();
}

class _PublicTransformationCardState extends State<_PublicTransformationCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final change = item.weightBeforeKg != null && item.weightAfterKg != null
        ? item.weightAfterKg! - item.weightBeforeKg!
        : null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
        height: 370,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _surface,
          border: Border.all(color: _hovered ? _red : const Color(0xFF2A2D30)),
          borderRadius: BorderRadius.circular(14),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.32),
                    blurRadius: 26,
                    offset: const Offset(0, 13),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _red.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: _red,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name.isEmpty
                            ? 'MEMBER STORY'
                            : item.name.toUpperCase(),
                        style: const TextStyle(
                          color: _red,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.title.isEmpty
                            ? 'Member transformation'
                            : item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _paper,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                item.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, height: 1.55),
              ),
            ],
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0F11),
                border: Border.all(color: const Color(0xFF272A2E)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (item.weightBeforeKg != null)
                    _TransformationMetric(
                      label: 'BEFORE',
                      value: '${_publicNumber(item.weightBeforeKg!)} kg',
                    ),
                  if (item.weightAfterKg != null)
                    _TransformationMetric(
                      label: 'AFTER',
                      value: '${_publicNumber(item.weightAfterKg!)} kg',
                      emphasized: true,
                    ),
                  if (change != null)
                    _TransformationMetric(
                      label: 'CHANGE',
                      value:
                          '${change > 0 ? '+' : ''}${_publicNumber(change)} kg',
                    ),
                ],
              ),
            ),
            if (item.durationText.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: _muted, size: 15),
                  const SizedBox(width: 7),
                  const Text(
                    'ACHIEVED IN',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.durationText,
                    style: const TextStyle(
                      color: _paper,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TransformationMetric extends StatelessWidget {
  const _TransformationMetric({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 78),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: emphasized
            ? _red.withValues(alpha: 0.12)
            : const Color(0xFF15181B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: emphasized ? _red : _paper,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicEmptyState extends StatelessWidget {
  const _PublicEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 42),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: const Color(0xFF2A2D30)),
      ),
      child: Column(
        children: [
          Icon(icon, color: _muted, size: 42),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: _paper, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class EquipmentSection extends StatelessWidget {
  const EquipmentSection({super.key, required this.equipment});

  final List<Equipment> equipment;

  @override
  Widget build(BuildContext context) {
    final groups = _equipmentGroups(equipment);
    return SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            eyebrow: 'COMMERCIAL-GRADE FLOOR',
            title: 'EQUIPMENT THAT\nMEANS BUSINESS.',
            description:
                'A well-maintained mix of cardio, plate-loaded and pin-loaded machines for complete training.',
          ),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth >= 1050
                  ? 3
                  : constraints.maxWidth >= 650
                  ? 2
                  : 1;
              return GridView.builder(
                itemCount: groups.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: count,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: count == 1 ? 1.05 : 0.9,
                ),
                itemBuilder: (context, index) =>
                    _EquipmentGroupCard(group: groups[index]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EquipmentGroup {
  const _EquipmentGroup({
    required this.title,
    required this.category,
    required this.description,
    required this.items,
  });

  final String title;
  final String category;
  final String description;
  final List<Equipment> items;
}

List<_EquipmentGroup> _equipmentGroups(List<Equipment> equipment) {
  List<Equipment> where(bool Function(Equipment equipment) test) =>
      equipment.where(test).toList();

  final groups = [
    _EquipmentGroup(
      title: 'Cardio Zone',
      category: 'CARDIO',
      description:
          'Treadmills, bikes and elliptical training for endurance and low-impact conditioning.',
      items: where((item) => item.category == 'CARDIO'),
    ),
    _EquipmentGroup(
      title: 'Strength Machines',
      category: 'PIN LOADED',
      description:
          'Guided machines for chest, back, shoulders, arms and lower-body isolation.',
      items: where((item) => item.category == 'PIN LOADED'),
    ),
    _EquipmentGroup(
      title: 'Free Weights',
      category: 'FREE WEIGHTS',
      description:
          'Dumbbells, plates, benches and rack work for serious strength training.',
      items: where((item) => item.category == 'FREE WEIGHTS'),
    ),
    _EquipmentGroup(
      title: 'Plate Loaded & Core',
      category: 'PLATE LOADED',
      description:
          'Heavy plate-loaded equipment and core stations for focused power work.',
      items: where(
        (item) =>
            item.category == 'PLATE LOADED' || item.category == 'BODYWEIGHT',
      ),
    ),
  ];

  return groups.where((group) => group.items.isNotEmpty).toList();
}

class _EquipmentGroupCard extends StatefulWidget {
  const _EquipmentGroupCard({required this.group});

  final _EquipmentGroup group;

  @override
  State<_EquipmentGroupCard> createState() => _EquipmentGroupCardState();
}

class _EquipmentGroupCardState extends State<_EquipmentGroupCard> {
  bool hovered = false;

  void _openGroup() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _EquipmentGroupPage(group: widget.group),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewItems = widget.group.items.take(4).toList();
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, hovered ? -5 : 0, 0),
        decoration: BoxDecoration(
          color: _surface,
          border: Border.all(color: hovered ? _red : const Color(0xFF292C2F)),
          boxShadow: hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: _openGroup,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 7,
                child: Container(
                  color: const Color(0xFFEAE8E3),
                  padding: const EdgeInsets.all(10),
                  child: GridView.builder(
                    itemCount: previewItems.length,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemBuilder: (context, index) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          previewItems[index].image,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.group.category,
                        style: const TextStyle(
                          color: _red,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        widget.group.title.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Text(
                          widget.group.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted, height: 1.45),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${widget.group.items.length} ITEMS',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward,
                            color: _red,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EquipmentGroupPage extends StatelessWidget {
  const _EquipmentGroupPage({required this.group});

  final _EquipmentGroup group;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      appBar: AppBar(
        backgroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _paper,
        title: Text(
          group.title.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        child: SectionShell(
          verticalPadding: 42,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(
                eyebrow: group.category,
                title: group.title.toUpperCase(),
                description: group.description,
              ),
              const SizedBox(height: 34),
              LayoutBuilder(
                builder: (context, constraints) {
                  final count = constraints.maxWidth >= 1050
                      ? 3
                      : constraints.maxWidth >= 650
                      ? 2
                      : 1;
                  return GridView.builder(
                    itemCount: group.items.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: count,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                      childAspectRatio: count == 1 ? 0.92 : 0.84,
                    ),
                    itemBuilder: (context, index) =>
                        EquipmentCard(equipment: group.items[index]),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EquipmentCard extends StatefulWidget {
  const EquipmentCard({super.key, required this.equipment});

  final Equipment equipment;

  @override
  State<EquipmentCard> createState() => _EquipmentCardState();
}

class _EquipmentCardState extends State<EquipmentCard> {
  bool hovered = false;

  void _showDetails() {
    showDialog<void>(
      context: context,
      builder: (context) => EquipmentDialog(equipment: widget.equipment),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, hovered ? -5 : 0, 0),
        decoration: BoxDecoration(
          color: _surface,
          border: Border.all(color: hovered ? _red : const Color(0xFF292C2F)),
          boxShadow: hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: _showDetails,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 7,
                child: Container(
                  color: const Color(0xFFEAE8E3),
                  padding: const EdgeInsets.all(16),
                  child: Hero(
                    tag: widget.equipment.image,
                    child: Image.asset(
                      widget.equipment.image,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.equipment.category,
                        style: const TextStyle(
                          color: _red,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        widget.equipment.name.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const Spacer(),
                      const Row(
                        children: [
                          Text(
                            'VIEW DETAILS',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(width: 7),
                          Icon(Icons.arrow_forward, color: _red, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EquipmentDialog extends StatelessWidget {
  const EquipmentDialog({super.key, required this.equipment});

  final Equipment equipment;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final image = Container(
      color: const Color(0xFFEAE8E3),
      padding: const EdgeInsets.all(24),
      child: Hero(
        tag: equipment.image,
        child: Image.asset(equipment.image, fit: BoxFit.contain),
      ),
    );
    final details = Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            equipment.category,
            style: const TextStyle(
              color: _red,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            equipment.name.toUpperCase(),
            style: const TextStyle(
              fontSize: 26,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            equipment.description,
            style: const TextStyle(color: _muted, height: 1.6),
          ),
          const SizedBox(height: 24),
          for (final spec in equipment.specs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: _red, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      spec,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );

    return Dialog(
      backgroundColor: _surface,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 650),
        child: SingleChildScrollView(
          child: wide
              ? SizedBox(
                  height: 480,
                  child: Row(
                    children: [
                      Expanded(child: image),
                      Expanded(child: details),
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 280, child: image),
                    details,
                  ],
                ),
        ),
      ),
    );
  }
}

class ExperienceSection extends StatelessWidget {
  const ExperienceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _red,
      child: SectionShell(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;
            final review = const _ReviewBlock();
            final reasons = const _ReasonsBlock();
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 11, child: review),
                      const SizedBox(width: 72),
                      Expanded(flex: 9, child: reasons),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [review, const SizedBox(height: 56), reasons],
                  );
          },
        ),
      ),
    );
  }
}

class _ReviewBlock extends StatelessWidget {
  const _ReviewBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(text: 'WHAT MEMBERS VALUE', light: true),
        SizedBox(height: 22),
        Icon(Icons.format_quote_rounded, size: 54, color: Colors.white),
        SizedBox(height: 8),
        Text(
          'EXCELLENT EQUIPMENT. KNOWLEDGEABLE COACHES. A WORKOUT ENVIRONMENT THAT KEEPS YOU MOTIVATED.',
          style: TextStyle(
            fontSize: 30,
            height: 1.18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Members consistently highlight the friendly guidance, well-maintained machines and worthwhile training experience.',
          style: TextStyle(
            color: Color(0xFFFFD8D9),
            fontSize: 16,
            height: 1.6,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ReasonsBlock extends StatelessWidget {
  const _ReasonsBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _ink.withValues(alpha: 0.94),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
      ),
      child: const Column(
        children: [
          _Reason(
            number: '01',
            title: 'EQUIPMENT YOU CAN TRUST',
            text:
                'Commercial machines maintained for consistent, confident training.',
          ),
          Divider(height: 40, color: Color(0xFF35383B)),
          _Reason(
            number: '02',
            title: 'COACHING WITH PURPOSE',
            text:
                'Friendly, knowledgeable guidance that meets you at your level.',
          ),
          Divider(height: 40, color: Color(0xFF35383B)),
          _Reason(
            number: '03',
            title: 'RESULTS YOU CAN FEEL',
            text:
                'Focused sessions and a motivating atmosphere built for progress.',
          ),
        ],
      ),
    );
  }
}

class _Reason extends StatelessWidget {
  const _Reason({
    required this.number,
    required this.title,
    required this.text,
  });

  final String number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            color: _red,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(text, style: const TextStyle(color: _muted, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class LocationSection extends StatelessWidget {
  const LocationSection({
    super.key,
    required this.profile,
    required this.onDirections,
    required this.onCall,
    required this.onWhatsApp,
    required this.onInstagram,
  });

  final GymProfile profile;
  final VoidCallback onDirections;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onInstagram;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _paper,
      child: SectionShell(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            final info = _LocationInfo(
              profile: profile,
              onDirections: onDirections,
              onCall: onCall,
              onWhatsApp: onWhatsApp,
              onInstagram: onInstagram,
            );
            final visual = _LocationVisual(gymName: profile.gymName);
            return ConstrainedBox(
              constraints: BoxConstraints(minHeight: wide ? 650 : 0),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: info),
                        const SizedBox(width: 56),
                        Expanded(child: visual),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [info, const SizedBox(height: 40), visual],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _LocationInfo extends StatelessWidget {
  const _LocationInfo({
    required this.profile,
    required this.onDirections,
    required this.onCall,
    required this.onWhatsApp,
    required this.onInstagram,
  });

  final GymProfile profile;
  final VoidCallback onDirections;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onInstagram;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(
          eyebrow: 'COME TRAIN WITH US',
          title: 'YOUR NEXT REP\nSTARTS HERE.',
          darkText: true,
        ),
        const SizedBox(height: 34),
        if (profile.gymName.isNotEmpty || profile.address.isNotEmpty) ...[
          _ContactLine(
            icon: Icons.location_on_outlined,
            title: profile.gymName.isEmpty
                ? 'ADDRESS'
                : profile.gymName.toUpperCase(),
            text: profile.address,
          ),
          const SizedBox(height: 22),
        ],
        if (profile.ownerName.isNotEmpty) ...[
          _ContactLine(
            icon: Icons.person_outline_rounded,
            title: 'OWNER',
            text: profile.ownerName,
          ),
          const SizedBox(height: 22),
        ],
        if (profile.phone.isNotEmpty) ...[
          _ContactLine(
            icon: Icons.call_outlined,
            title: 'PHONE',
            text: profile.phone,
          ),
          const SizedBox(height: 22),
        ],
        if (profile.email.isNotEmpty) ...[
          _ContactLine(
            icon: Icons.email_outlined,
            title: 'EMAIL',
            text: profile.email,
          ),
          const SizedBox(height: 22),
        ],
        if (profile.openingTime.isNotEmpty ||
            profile.closingTime.isNotEmpty) ...[
          _ContactLine(
            icon: Icons.schedule_outlined,
            title: 'OPENING HOURS',
            text: _openingHours(profile),
          ),
          const SizedBox(height: 22),
        ],
        if (profile.whatsappNumber.isNotEmpty) ...[
          _ContactLine(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'WHATSAPP',
            text: profile.whatsappNumber,
          ),
          const SizedBox(height: 22),
        ],
        if (profile.instagramUrl.isNotEmpty) ...[
          _ContactLine(
            icon: Icons.camera_alt_outlined,
            title: 'INSTAGRAM',
            text: profile.instagramUrl,
            onTap: onInstagram,
          ),
          const SizedBox(height: 22),
        ],
        if (profile.facebookUrl.isNotEmpty)
          _ContactLine(
            icon: Icons.public_outlined,
            title: 'FACEBOOK',
            text: profile.facebookUrl,
          ),
        const SizedBox(height: 34),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onDirections,
              icon: const Icon(Icons.near_me_outlined),
              label: const Text('OPEN IN MAPS'),
            ),
            OutlinedButton.icon(
              onPressed: onCall,
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                side: const BorderSide(color: Color(0xFFB8B5AF)),
              ),
              icon: const Icon(Icons.call_outlined),
              label: const Text('CALL NOW'),
            ),
            IconButton.outlined(
              onPressed: onWhatsApp,
              tooltip: 'Chat on WhatsApp',
              style: IconButton.styleFrom(
                foregroundColor: _ink,
                side: const BorderSide(color: Color(0xFFB8B5AF)),
                padding: const EdgeInsets.all(16),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({
    required this.icon,
    required this.title,
    required this.text,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          color: _red,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                text,
                style: TextStyle(
                  color: onTap == null ? const Color(0xFF64666A) : _red,
                  height: 1.5,
                  decoration: onTap == null ? null : TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: content,
      ),
    );
  }
}

class _LocationVisual extends StatelessWidget {
  const _LocationVisual({required this.gymName});

  final String gymName;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.15,
      child: Container(
        decoration: BoxDecoration(
          color: _ink,
          border: Border.all(color: const Color(0xFF26282B), width: 8),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _MapPatternPainter())),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, color: _red, size: 64),
                  SizedBox(height: 8),
                  Text(
                    gymName.isEmpty
                        ? 'TRIANGLE FITNESS'
                        : gymName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'KRS ROAD • HONGAHALLI',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFF26292C)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke;
    final minor = Paint()
      ..color = const Color(0xFF1A1D20)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(-20, size.height * 0.72),
      Offset(size.width + 20, size.height * 0.25),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.18, -20),
      Offset(size.width * 0.72, size.height + 20),
      road,
    );
    canvas.drawLine(
      Offset(-20, size.height * 0.25),
      Offset(size.width * 0.62, size.height + 20),
      minor,
    );
    canvas.drawLine(
      Offset(size.width * 0.52, -20),
      Offset(size.width + 20, size.height * 0.8),
      minor,
    );
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.18), 36, minor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050506),
      child: SectionShell(
        verticalPadding: 42,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 650;
            final logo = Image.asset(
              'assets/logo.png',
              width: 180,
              height: 72,
              fit: BoxFit.cover,
            );
            const copy = Text(
              '© 2026 TRIANGLE FITNESS  •  KRS ROAD, KARNATAKA',
              style: TextStyle(
                color: _muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            );
            return compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [logo, const SizedBox(height: 20), copy],
                  )
                : Row(children: [logo, const Spacer(), copy]);
          },
        ),
      ),
    );
  }
}

class SectionShell extends StatelessWidget {
  const SectionShell({
    super.key,
    required this.child,
    this.verticalPadding = 96,
  });

  final Widget child;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width < 700 ? 20.0 : 36.0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: verticalPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow({super.key, required this.text, this.light = false});

  final String text;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 28, height: 3, color: light ? Colors.white : _red),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: light ? Colors.white : _red,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.7,
            ),
          ),
        ),
      ],
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    this.description,
    this.darkText = false,
  });

  final String eyebrow;
  final String title;
  final String? description;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(text: eyebrow),
        const SizedBox(height: 18),
        Text(
          title,
          style: TextStyle(
            color: darkText ? _ink : _paper,
            fontSize: MediaQuery.sizeOf(context).width < 500 ? 38 : 48,
            height: 0.98,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.6,
          ),
        ),
      ],
    );

    if (description == null) return heading;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading,
              const SizedBox(height: 22),
              _Description(text: description!, darkText: darkText),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(flex: 6, child: heading),
            const SizedBox(width: 50),
            Expanded(
              flex: 4,
              child: _Description(text: description!, darkText: darkText),
            ),
          ],
        );
      },
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({required this.text, required this.darkText});

  final String text;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: darkText ? const Color(0xFF64666A) : _muted,
        fontSize: 16,
        height: 1.65,
      ),
    );
  }
}

String _openingHours(GymProfile profile) {
  if (profile.openingTime.isEmpty) return profile.closingTime;
  if (profile.closingTime.isEmpty) return profile.openingTime;
  return '${profile.openingTime} - ${profile.closingTime}';
}

String _publicNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);
