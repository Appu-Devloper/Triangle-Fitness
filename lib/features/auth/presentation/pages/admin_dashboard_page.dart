import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triangle_fitness/core/theme/app_colors.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/cubit/admin_dashboard_cubit.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/add_member_page.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/members_list_page.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/payments_list_page.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/settings_page.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/subscriptions_management_page.dart';
import 'package:triangle_fitness/features/auth/presentation/widgets/admin_workspace.dart';

const _workspace = AdminWorkspaceColors.background;
const _card = AdminWorkspaceColors.surface;
const _darkText = AdminWorkspaceColors.text;
const _softText = AdminWorkspaceColors.muted;
const _line = AdminWorkspaceColors.border;
const _success = AdminWorkspaceColors.success;
const _warning = AdminWorkspaceColors.warning;

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
        final signingOut = state.status == AdminDashboardStatus.signingOut;
        return LayoutBuilder(
          builder: (context, constraints) => AdminWorkspaceScaffold(
            section: AdminWorkspaceSection.overview,
            title: 'ADMIN DASHBOARD',
            subtitle: 'Business performance and management overview',
            adminName: state.dashboard?.adminName,
            signingOut: signingOut,
            onSignOut: signingOut
                ? null
                : context.read<AdminDashboardCubit>().signOut,
            onDestinationSelected: (destination) {
              if (destination == AdminWorkspaceSection.overview) return;
              _openSection(context, destination.label);
            },
            body: _DashboardBody(
              state: state,
              showQuickActions: constraints.maxWidth < 1050,
            ),
          ),
        );
      },
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
    final periodStart = dashboard.collectionPeriodStart;
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
        label: 'MONTH PAYMENTS',
        value: dashboard.totalPayments.toString(),
        caption: _formatPeriodRange(
          dashboard.collectionPeriodStart,
          dashboard.collectionPeriodEnd,
        ),
        icon: Icons.account_balance_wallet_rounded,
        color: _warning,
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
                _CollectionPeriodSelector(
                  selected: periodStart,
                  onSelected: (value) => context
                      .read<AdminDashboardCubit>()
                      .load(periodStart: value),
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

class _CollectionPeriodSelector extends StatelessWidget {
  const _CollectionPeriodSelector({
    required this.selected,
    required this.onSelected,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List<int>.generate(
      currentYear - 2025 + 1,
      (index) => currentYear - index,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'COLLECTION MONTH',
                style: TextStyle(
                  color: _darkText,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatPeriodRange(
                  selected,
                  DateTime(selected.year, selected.month + 1, 10),
                ),
                style: const TextStyle(
                  color: _softText,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          );
          final controls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PeriodDropdown<int>(
                label: 'MONTH',
                icon: Icons.calendar_month_rounded,
                value: selected.month,
                items: [
                  for (var month = 1; month <= 12; month += 1)
                    PopupMenuItem<int>(
                      value: month,
                      child: Text(_monthName(month)),
                    ),
                ],
                displayValue: _monthName(selected.month),
                onSelected: (month) =>
                    onSelected(DateTime(selected.year, month, 11)),
              ),
              const SizedBox(width: 10),
              _PeriodDropdown<int>(
                label: 'YEAR',
                icon: Icons.event_rounded,
                value: selected.year,
                items: [
                  for (final year in years)
                    PopupMenuItem<int>(
                      value: year,
                      child: Text(year.toString()),
                    ),
                ],
                displayValue: selected.year.toString(),
                onSelected: (year) =>
                    onSelected(DateTime(year, selected.month, 11)),
              ),
            ],
          );
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                title,
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: controls,
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 16),
              controls,
            ],
          );
        },
      ),
    );
  }
}

class _PeriodDropdown<T> extends StatelessWidget {
  const _PeriodDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.displayValue,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final T value;
  final List<PopupMenuEntry<T>> items;
  final String displayValue;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: 'Select ${label.toLowerCase()}',
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (context) => items,
      child: Container(
        width: 156,
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: AdminWorkspaceColors.field,
          border: Border.all(color: AdminWorkspaceColors.borderStrong),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.red, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _softText,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    displayValue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _darkText,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.expand_more_rounded, color: _softText, size: 18),
          ],
        ),
      ),
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
              backgroundColor: AdminWorkspaceColors.borderStrong,
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
            title: 'Monthly collection',
            subtitle: 'Payments received from 11th to 10th',
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
            '${dashboard.totalPayments} payment records  •  ${_formatPeriodRange(dashboard.collectionPeriodStart, dashboard.collectionPeriodEnd)}',
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
  _AdminAction('All Transactions', Icons.payments_rounded),
  _AdminAction('Subscriptions', Icons.card_membership_rounded),
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
  if (title == 'All Transactions' || title == 'Payments') {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PaymentsListPage()));
    return;
  }
  if (title == 'Subscriptions') {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SubscriptionsManagementPage(),
      ),
    );
    return;
  }
  if (title == 'Settings') {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
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

String _formatPeriodRange(DateTime start, DateTime end) {
  return '${_formatDayMonth(start)} - ${_formatDayMonth(end)}';
}

String _formatDayMonth(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}';

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}
