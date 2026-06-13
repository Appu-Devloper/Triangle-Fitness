import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triangle_fitness/core/theme/app_colors.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/cubit/admin_dashboard_cubit.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/add_member_page.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/members_list_page.dart';

const _workspace = Color(0xFFF4F5F7);
const _card = Colors.white;
const _darkText = Color(0xFF17191C);
const _softText = Color(0xFF687078);
const _line = Color(0xFFE6E8EB);
const _success = Color(0xFF168A53);
const _warning = Color(0xFFE6962A);

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AdminDashboardCubit(context.read<AuthRepository>())..load(),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminDashboardCubit, AdminDashboardState>(
      listener: (context, state) {
        if (state.status == AdminDashboardStatus.signedOut) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          return;
        }
        if (state.status == AdminDashboardStatus.failure &&
            state.dashboard != null &&
            state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final showSidebar = constraints.maxWidth >= 1080;
            return Scaffold(
              backgroundColor: _workspace,
              body: Row(
                children: [
                  if (showSidebar) _AdminSidebar(state: state),
                  Expanded(
                    child: Column(
                      children: [
                        _TopBar(state: state, compact: !showSidebar),
                        Expanded(
                          child: _DashboardBody(
                            state: state,
                            showQuickActions: !showSidebar,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({required this.state});

  final AdminDashboardState state;

  @override
  Widget build(BuildContext context) {
    final signingOut = state.status == AdminDashboardStatus.signingOut;
    return Container(
      width: 252,
      color: AppColors.ink,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            'assets/logo.png',
            height: 52,
            alignment: Alignment.centerLeft,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 36),
          const _SidebarLabel('WORKSPACE'),
          const SizedBox(height: 10),
          const _SidebarItem(
            label: 'Overview',
            icon: Icons.space_dashboard_rounded,
            selected: true,
          ),
          const SizedBox(height: 5),
          for (final action in _adminActions)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: _SidebarItem(
                label: action.label,
                icon: action.icon,
                onTap: () => _openSection(context, action.label),
              ),
            ),
          const Spacer(),
          const Divider(color: Color(0xFF25282C)),
          const SizedBox(height: 10),
          _SidebarItem(
            label: signingOut ? 'Signing out...' : 'Log out',
            icon: Icons.logout_rounded,
            destructive: true,
            onTap: signingOut
                ? null
                : context.read<AdminDashboardCubit>().signOut,
          ),
        ],
      ),
    );
  }
}

class _SidebarLabel extends StatelessWidget {
  const _SidebarLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF696E74),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.icon,
    this.onTap,
    this.selected = false,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool selected;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFFF777C)
        : selected
        ? Colors.white
        : const Color(0xFFB2B6BB);
    return Material(
      color: selected ? AppColors.red : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              if (!selected && !destructive)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFF53585E),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state, required this.compact});

  final AdminDashboardState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final signingOut = state.status == AdminDashboardStatus.signingOut;
    final name = state.dashboard?.adminName;
    return Container(
      height: 76,
      padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 30),
      decoration: const BoxDecoration(
        color: _card,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          if (compact) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.change_history_rounded,
                color: AppColors.red,
                size: 27,
              ),
            ),
            const SizedBox(width: 12),
          ],
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADMIN DASHBOARD',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _darkText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Triangle Fitness management',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _softText, fontSize: 11),
                ),
              ],
            ),
          ),
          if (!compact && name != null) ...[
            _AdminIdentity(name: name),
            const SizedBox(width: 18),
          ],
          if (compact && MediaQuery.sizeOf(context).width < 520)
            IconButton.filledTonal(
              onPressed: signingOut
                  ? null
                  : context.read<AdminDashboardCubit>().signOut,
              tooltip: 'Log out',
              icon: signingOut
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded, size: 20),
            )
          else
            OutlinedButton.icon(
              onPressed: signingOut
                  ? null
                  : context.read<AdminDashboardCubit>().signOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: _darkText,
                side: const BorderSide(color: _line),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
              ),
              icon: signingOut
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded, size: 18),
              label: Text(signingOut ? 'SIGNING OUT...' : 'LOG OUT'),
            ),
        ],
      ),
    );
  }
}

class _AdminIdentity extends StatelessWidget {
  const _AdminIdentity({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
            color: AppColors.red,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: _darkText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              'Administrator',
              style: TextStyle(color: _softText, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.state, required this.showQuickActions});

  final AdminDashboardState state;
  final bool showQuickActions;

  @override
  Widget build(BuildContext context) {
    final dashboard = state.dashboard;
    if (dashboard != null) {
      return _DashboardContent(
        dashboard: dashboard,
        showQuickActions: showQuickActions,
      );
    }
    if (state.status == AdminDashboardStatus.failure) {
      return _DashboardError(
        message: state.message ?? 'Unable to load admin dashboard.',
      );
    }
    return const Center(child: CircularProgressIndicator(color: AppColors.red));
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.dashboard,
    required this.showQuickActions,
  });

  final AdminDashboard dashboard;
  final bool showQuickActions;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _AdminStat(
        label: 'TOTAL MEMBERS',
        value: dashboard.totalMembers.toString(),
        caption: 'Registered profiles',
        icon: Icons.groups_2_rounded,
        color: const Color(0xFF3159C7),
      ),
      _AdminStat(
        label: 'ACTIVE MEMBERS',
        value: dashboard.activeMembers.toString(),
        caption: 'Currently active',
        icon: Icons.verified_rounded,
        color: _success,
      ),
      _AdminStat(
        label: 'EXPIRED MEMBERS',
        value: dashboard.expiredMembers.toString(),
        caption: 'Need follow-up',
        icon: Icons.event_busy_rounded,
        color: AppColors.red,
      ),
      _AdminStat(
        label: 'TOTAL PAYMENTS',
        value: dashboard.totalPayments.toString(),
        caption: _formatCurrency(dashboard.totalPaymentAmount),
        icon: Icons.account_balance_wallet_rounded,
        color: _warning,
      ),
      _AdminStat(
        label: 'TRANSFORMATIONS',
        value: dashboard.totalTransformations.toString(),
        caption: 'Published stories',
        icon: Icons.insights_rounded,
        color: const Color(0xFF7B4BC7),
      ),
    ];

    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WelcomePanel(dashboard: dashboard),
                const SizedBox(height: 26),
                const _SectionHeading(
                  title: 'Business overview',
                  subtitle: 'Live totals from your Firestore records',
                ),
                const SizedBox(height: 14),
                _StatsGrid(stats: stats),
                const SizedBox(height: 22),
                _InsightRow(dashboard: dashboard),
                if (showQuickActions) ...[
                  const SizedBox(height: 28),
                  const _SectionHeading(
                    title: 'Quick management',
                    subtitle: 'Choose an area to continue',
                  ),
                  const SizedBox(height: 14),
                  const _ActionGrid(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({required this.dashboard});

  final AdminDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final activeRate = dashboard.totalMembers == 0
        ? 0
        : ((dashboard.activeMembers / dashboard.totalMembers) * 100).round();
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF202328), Color(0xFF0B0C0E)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'GYM CONTROL CENTER',
                  style: TextStyle(
                    color: Color(0xFFFF7277),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome, ${dashboard.adminName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Track memberships, payments and gym activity from one clear workspace.',
                style: TextStyle(
                  color: Color(0xFFB7BBC0),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          );
          final rate = Container(
            width: 150,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACTIVE RATE',
                  style: TextStyle(
                    color: Color(0xFF9DA2A8),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$activeRate%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (activeRate / 100).clamp(0, 1),
                    minHeight: 5,
                    backgroundColor: const Color(0xFF3D4146),
                    color: _success,
                  ),
                ),
              ],
            ),
          );

          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [copy, const SizedBox(height: 20), rate],
            );
          }
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 24),
              rate,
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 4,
          height: 37,
          decoration: BoxDecoration(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _darkText,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: _softText, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final List<_AdminStat> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 5
            : constraints.maxWidth >= 700
            ? 3
            : constraints.maxWidth >= 430
            ? 2
            : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final stat in stats)
              SizedBox(
                width: width,
                child: _StatCard(stat: stat),
              ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final _AdminStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 138,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: stat.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(stat.icon, color: stat.color, size: 19),
              ),
              const Spacer(),
              Text(
                stat.value,
                style: const TextStyle(
                  color: _darkText,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _darkText,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            stat.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _softText, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.dashboard});

  final AdminDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final membership = _MembershipHealth(dashboard: dashboard);
        final collection = _CollectionSummary(dashboard: dashboard);
        if (constraints.maxWidth >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: membership),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: collection),
            ],
          );
        }
        return Column(
          children: [membership, const SizedBox(height: 12), collection],
        );
      },
    );
  }
}

class _MembershipHealth extends StatelessWidget {
  const _MembershipHealth({required this.dashboard});

  final AdminDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final activeRatio = dashboard.totalMembers == 0
        ? 0.0
        : dashboard.activeMembers / dashboard.totalMembers;
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InfoTitle(
            icon: Icons.monitor_heart_rounded,
            title: 'Membership health',
            subtitle: 'Active compared with expired memberships',
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: activeRatio.clamp(0, 1),
              minHeight: 10,
              backgroundColor: const Color(0xFFFFDADD),
              color: _success,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _LegendValue(
                  color: _success,
                  label: 'Active',
                  value: dashboard.activeMembers,
                ),
              ),
              Expanded(
                child: _LegendValue(
                  color: AppColors.red,
                  label: 'Expired',
                  value: dashboard.expiredMembers,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionSummary extends StatelessWidget {
  const _CollectionSummary({required this.dashboard});

  final AdminDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InfoTitle(
            icon: Icons.currency_rupee_rounded,
            title: 'Payment collection',
            subtitle: 'Recorded payment value',
          ),
          const SizedBox(height: 20),
          Text(
            _formatCurrency(dashboard.totalPaymentAmount),
            style: const TextStyle(
              color: _darkText,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${dashboard.totalPayments} payment records',
            style: const TextStyle(color: _softText, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _InfoTitle extends StatelessWidget {
  const _InfoTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppColors.red, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _darkText,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: _softText, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendValue extends StatelessWidget {
  const _LegendValue({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          '$label  ',
          style: const TextStyle(color: _softText, fontSize: 11),
        ),
        Text(
          '$value',
          style: const TextStyle(
            color: _darkText,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 3
            : constraints.maxWidth >= 440
            ? 2
            : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final action in _adminActions)
              SizedBox(
                width: width,
                child: _ActionCard(action: action),
              ),
          ],
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});

  final _AdminAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: () => _openSection(context, action.label),
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 82,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(action.icon, color: AppColors.red, size: 20),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  action.label.toUpperCase(),
                  style: const TextStyle(
                    color: _darkText,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: _softText,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: _card,
              border: Border.all(color: _line),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.red,
                    size: 29,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'ADMIN DASHBOARD UNAVAILABLE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _darkText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _softText, height: 1.5),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: context.read<AdminDashboardCubit>().load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('TRY AGAIN'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminSectionPage extends StatelessWidget {
  const _AdminSectionPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _workspace,
      appBar: AppBar(
        backgroundColor: _card,
        foregroundColor: _darkText,
        surfaceTintColor: Colors.transparent,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _card,
              border: Border.all(color: _line),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.construction_rounded,
                  color: AppColors.red,
                  size: 44,
                ),
                const SizedBox(height: 16),
                Text(
                  '$title management',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _darkText,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This section is ready for its management workflow.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _softText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _adminActions = [
  _AdminAction('Members', Icons.groups_2_rounded),
  _AdminAction('Add Member', Icons.person_add_alt_1_rounded),
  _AdminAction('Payments', Icons.payments_rounded),
  _AdminAction('Subscriptions', Icons.card_membership_rounded),
  _AdminAction('Transformations', Icons.insights_rounded),
  _AdminAction('Settings', Icons.settings_rounded),
];

class _AdminStat {
  const _AdminStat({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;
}

class _AdminAction {
  const _AdminAction(this.label, this.icon);

  final String label;
  final IconData icon;
}

Future<void> _openSection(BuildContext context, String title) async {
  if (title == 'Members') {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MembersListPage()));
    return;
  }
  if (title == 'Add Member') {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const AddMemberPage()),
    );
    if (!context.mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    await context.read<AdminDashboardCubit>().load();
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => _AdminSectionPage(title: title)),
  );
}

String _formatCurrency(double amount) {
  final value = amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
  return 'Rs. $value';
}
