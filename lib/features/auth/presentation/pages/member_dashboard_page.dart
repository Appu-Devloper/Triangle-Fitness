import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triangle_fitness/core/theme/app_colors.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_payment.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/cubit/member_dashboard_cubit.dart';

class MemberDashboardPage extends StatelessWidget {
  const MemberDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MemberDashboardCubit(context.read<AuthRepository>())..load(),
      child: const _MemberDashboardView(),
    );
  }
}

class _MemberDashboardView extends StatelessWidget {
  const _MemberDashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MemberDashboardCubit, MemberDashboardState>(
      listener: (context, state) {
        if (state.status == MemberDashboardStatus.signedOut) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          return;
        }
        if (state.status == MemberDashboardStatus.failure &&
            state.dashboard != null &&
            state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        final signingOut = state.status == MemberDashboardStatus.signingOut;
        return Scaffold(
          backgroundColor: AppColors.ink,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            toolbarHeight: 72,
            backgroundColor: AppColors.ink.withValues(alpha: 0.96),
            surfaceTintColor: Colors.transparent,
            titleSpacing: 18,
            title: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 520;
                return Row(
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: compact ? 122 : 150,
                      height: 46,
                      fit: BoxFit.contain,
                    ),
                    const Spacer(),
                    if (compact)
                      IconButton(
                        onPressed: signingOut
                            ? null
                            : context.read<MemberDashboardCubit>().signOut,
                        tooltip: 'Log out',
                        icon: signingOut
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.logout_rounded),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: signingOut
                            ? null
                            : context.read<MemberDashboardCubit>().signOut,
                        icon: signingOut
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.logout_rounded, size: 18),
                        label: Text(signingOut ? 'SIGNING OUT...' : 'LOG OUT'),
                      ),
                  ],
                );
              },
            ),
          ),
          body: _DashboardBody(state: state),
        );
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.state});

  final MemberDashboardState state;

  @override
  Widget build(BuildContext context) {
    final dashboard = state.dashboard;
    if (dashboard != null) return _DashboardContent(dashboard: dashboard);
    if (state.status == MemberDashboardStatus.failure) {
      return _DashboardError(
        message: state.message ?? 'Unable to load member data.',
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.dashboard});

  final MemberDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final subscriptionStatus = dashboard.subscriptionStatusFor(now);
    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 30, 18, 64),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _PageHeading(),
                const SizedBox(height: 26),
                _MembershipHero(
                  dashboard: dashboard,
                  subscriptionStatus: subscriptionStatus,
                  now: now,
                ),
                const SizedBox(height: 18),
                _MetricGrid(dashboard: dashboard, now: now),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final profile = _ProfileCard(dashboard: dashboard);
                    final membership = _SubscriptionCard(
                      dashboard: dashboard,
                      status: subscriptionStatus,
                      now: now,
                    );
                    if (constraints.maxWidth >= 880) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: profile),
                          const SizedBox(width: 18),
                          Expanded(flex: 5, child: membership),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        profile,
                        const SizedBox(height: 18),
                        membership,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                _PaymentHistory(payments: dashboard.payments),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 32, height: 3, color: AppColors.red),
            const SizedBox(width: 10),
            const Text(
              'MEMBER DASHBOARD',
              style: TextStyle(
                color: AppColors.red,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.7,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'YOUR FITNESS MEMBERSHIP',
          style: TextStyle(
            color: AppColors.paper,
            fontSize: 30,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.9,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Everything you need to know about your Triangle Fitness account.',
          style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}

class _MembershipHero extends StatelessWidget {
  const _MembershipHero({
    required this.dashboard,
    required this.subscriptionStatus,
    required this.now,
  });

  final MemberDashboard dashboard;
  final String subscriptionStatus;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final active = subscriptionStatus == 'Active';
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: BoxConstraints(minHeight: compact ? 310 : 248),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF222529), Color(0xFF111315)],
              ),
            ),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _HeroPainter()),
                ),
                Padding(
                  padding: EdgeInsets.all(compact ? 24 : 32),
                  child: compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MemberIdentity(dashboard: dashboard),
                            const SizedBox(height: 28),
                            _PlanSummary(
                              dashboard: dashboard,
                              status: subscriptionStatus,
                              active: active,
                              now: now,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _MemberIdentity(dashboard: dashboard),
                            ),
                            Container(
                              width: 1,
                              height: 132,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            const SizedBox(width: 38),
                            Expanded(
                              child: _PlanSummary(
                                dashboard: dashboard,
                                status: subscriptionStatus,
                                active: active,
                                now: now,
                              ),
                            ),
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

class _MemberIdentity extends StatelessWidget {
  const _MemberIdentity({required this.dashboard});

  final MemberDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final initial = dashboard.name == 'Not available'
        ? 'M'
        : dashboard.name.trim().substring(0, 1).toUpperCase();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.red.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WELCOME BACK',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                dashboard.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.paper,
                  fontSize: 27,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'MEMBER CODE  ${dashboard.memberCode}',
                style: const TextStyle(
                  color: Color(0xFFD0D2D4),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({
    required this.dashboard,
    required this.status,
    required this.active,
    required this.now,
  });

  final MemberDashboard dashboard;
  final String status;
  final bool active;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatusBadge(value: status, active: active),
            const Spacer(),
            const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.red,
              size: 28,
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'CURRENT PLAN',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dashboard.planName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.paper,
            fontSize: 23,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${dashboard.expirySummaryFor(now)}  •  Ends ${_formatDate(dashboard.endDate)}',
          style: const TextStyle(
            color: Color(0xFFD0D2D4),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.dashboard, required this.now});

  final MemberDashboard dashboard;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1040
            ? 5
            : constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 520
            ? 2
            : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final metrics = [
          _Metric(Icons.monitor_weight_outlined, 'WEIGHT', dashboard.weight),
          _Metric(Icons.height_rounded, 'HEIGHT', dashboard.height),
          _Metric(
            Icons.receipt_long_outlined,
            'RECEIPT NO',
            dashboard.receiptNo,
          ),
          _Metric(Icons.payments_outlined, 'PAYMENT', dashboard.paymentStatus),
          _Metric(
            Icons.hourglass_bottom_rounded,
            'EXPIRES IN',
            dashboard.expiresInFor(now),
          ),
        ];
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: _MetricCard(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: const Color(0xFF272A2D)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(metric.icon, color: AppColors.red, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.paper,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.dashboard});

  final MemberDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.person_outline_rounded,
      eyebrow: 'PROFILE',
      title: 'Personal information',
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'Full name',
            value: dashboard.name,
          ),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone number',
            value: dashboard.phone,
          ),
          _InfoRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email address',
            value: dashboard.email,
          ),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: dashboard.address,
          ),
          _InfoRow(
            icon: Icons.verified_user_outlined,
            label: 'Member status',
            value: dashboard.status,
            last: true,
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.dashboard,
    required this.status,
    required this.now,
  });

  final MemberDashboard dashboard;
  final String status;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final progress = _subscriptionProgress(
      dashboard.startDate,
      dashboard.endDate,
      now,
    );
    return _SectionCard(
      icon: Icons.calendar_month_outlined,
      eyebrow: 'MEMBERSHIP',
      title: 'Subscription overview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SmallLabel('PLAN NAME'),
                    const SizedBox(height: 7),
                    Text(
                      dashboard.planName,
                      style: const TextStyle(
                        color: AppColors.paper,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const _SmallLabel('AMOUNT'),
                  const SizedBox(height: 7),
                  Text(
                    dashboard.amount,
                    style: const TextStyle(
                      color: AppColors.paper,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 26),
          LayoutBuilder(
            builder: (context, constraints) {
              final expiry = Text(
                dashboard.expirySummaryFor(now),
                style: TextStyle(
                  color: status == 'Active'
                      ? const Color(0xFF62D58D)
                      : AppColors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              );
              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SmallLabel('SUBSCRIPTION PROGRESS'),
                    const SizedBox(height: 6),
                    expiry,
                  ],
                );
              }
              return Row(
                children: [
                  const _SmallLabel('SUBSCRIPTION PROGRESS'),
                  const Spacer(),
                  expiry,
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress,
              backgroundColor: const Color(0xFF2B2E31),
              valueColor: AlwaysStoppedAnimation<Color>(
                status == 'Active' ? AppColors.red : const Color(0xFF5B5E62),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _DateBlock(
                  label: 'START DATE',
                  value: _formatDate(dashboard.startDate),
                  icon: Icons.play_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateBlock(
                  label: 'END DATE',
                  value: _formatDate(dashboard.endDate),
                  icon: Icons.flag_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0F11),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.muted,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Payment status',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ),
                Text(
                  dashboard.paymentStatus,
                  style: const TextStyle(
                    color: AppColors.paper,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentHistory extends StatelessWidget {
  const _PaymentHistory({required this.payments});

  final List<MemberPayment> payments;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.receipt_long_outlined,
      eyebrow: 'PAYMENTS',
      title: 'Payment history',
      child: payments.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  'No payment records found',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          : _MemberPaymentsTable(payments: payments),
    );
  }
}

class _MemberPaymentsTable extends StatefulWidget {
  const _MemberPaymentsTable({required this.payments});

  final List<MemberPayment> payments;

  @override
  State<_MemberPaymentsTable> createState() => _MemberPaymentsTableState();
}

class _MemberPaymentsTableState extends State<_MemberPaymentsTable> {
  static const _availableRowsPerPage = [5, 10, 20];

  int _rowsPerPage = 5;
  int? _sortColumnIndex = 4;
  bool _sortAscending = false;
  late List<MemberPayment> _payments;

  @override
  void initState() {
    super.initState();
    _payments = List.of(widget.payments);
    _applySort();
  }

  @override
  void didUpdateWidget(covariant _MemberPaymentsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.payments != widget.payments) {
      _payments = List.of(widget.payments);
      _applySort();
    }
  }

  void _applySort() {
    if (_sortColumnIndex == 1) {
      _payments.sort((a, b) {
        final result = a.amount.compareTo(b.amount);
        return _sortAscending ? result : -result;
      });
      return;
    }
    if (_sortColumnIndex == 4) {
      _payments.sort((a, b) {
        final aDate = a.paymentDate?.millisecondsSinceEpoch ?? -1;
        final bDate = b.paymentDate?.millisecondsSinceEpoch ?? -1;
        final result = aDate.compareTo(bDate);
        return _sortAscending ? result : -result;
      });
    }
  }

  void _sortBy(int columnIndex) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }
      _applySort();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        cardColor: const Color(0xFF0D0F11),
        dividerColor: const Color(0xFF292C2F),
      ),
      child: DataTableTheme(
        data: const DataTableThemeData(
          headingTextStyle: TextStyle(
            color: AppColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
          dataTextStyle: TextStyle(
            color: AppColors.paper,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: PaginatedDataTable(
          key: const Key('member-payments-table'),
          header: Text(
            '${widget.payments.length} ${widget.payments.length == 1 ? 'record' : 'records'}',
            style: const TextStyle(
              color: AppColors.paper,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          headingRowColor: const WidgetStatePropertyAll(Color(0xFF111417)),
          horizontalMargin: 16,
          columnSpacing: 26,
          dataRowMinHeight: 66,
          dataRowMaxHeight: 74,
          dividerThickness: 0.7,
          showCheckboxColumn: false,
          showFirstLastButtons: true,
          showEmptyRows: false,
          rowsPerPage: _rowsPerPage,
          availableRowsPerPage: _availableRowsPerPage,
          onRowsPerPageChanged: (value) {
            if (value == null) return;
            setState(() => _rowsPerPage = value);
          },
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          source: _MemberPaymentsDataSource(_payments),
          columns: [
            const DataColumn(label: Text('RECEIPT NO')),
            DataColumn(
              numeric: true,
              label: const Text('AMOUNT'),
              onSort: (columnIndex, _) => _sortBy(columnIndex),
            ),
            const DataColumn(label: Text('MODE')),
            const DataColumn(label: Text('STATUS')),
            DataColumn(
              label: const Text('PAYMENT DATE'),
              onSort: (columnIndex, _) => _sortBy(columnIndex),
            ),
            const DataColumn(label: Text('SUBSCRIPTION PERIOD')),
          ],
        ),
      ),
    );
  }
}

class _MemberPaymentsDataSource extends DataTableSource {
  _MemberPaymentsDataSource(this.payments);

  final List<MemberPayment> payments;

  @override
  DataRow? getRow(int index) {
    if (index >= payments.length) return null;
    final payment = payments[index];
    return DataRow(
      key: ValueKey('member-payment-${payment.id}'),
      cells: [
        DataCell(
          Text(
            payment.receiptNo,
            style: const TextStyle(
              color: AppColors.red,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        DataCell(
          Text(
            _formatCurrency(payment.amount),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        DataCell(Text(payment.paymentMode)),
        DataCell(_MemberPaymentStatus(status: payment.paymentStatus)),
        DataCell(Text(_formatDate(payment.paymentDate))),
        DataCell(
          SizedBox(
            width: 170,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MemberPaymentDateLine(
                  label: 'START',
                  value: _formatDate(payment.subscriptionStartDate),
                ),
                const SizedBox(height: 5),
                _MemberPaymentDateLine(
                  label: 'END',
                  value: _formatDate(payment.subscriptionEndDate),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => payments.length;

  @override
  int get selectedRowCount => 0;
}

class _MemberPaymentStatus extends StatelessWidget {
  const _MemberPaymentStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final paid = status.trim().toUpperCase() == 'PAID';
    final color = paid ? const Color(0xFF62D58D) : const Color(0xFFFFC66D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MemberPaymentDateLine extends StatelessWidget {
  const _MemberPaymentDateLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label  ',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: const Color(0xFF272A2D)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: AppColors.red, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: const TextStyle(
                        color: AppColors.red,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.paper,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFF292C2F))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.muted, size: 20),
          const SizedBox(width: 14),
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.paper,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBlock extends StatelessWidget {
  const _DateBlock({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F11),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.red, size: 18),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.paper,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.value, required this.active});

  final String value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF62D58D) : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            value.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallLabel extends StatelessWidget {
  const _SmallLabel(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _Metric {
  const _Metric(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

class _HeroPainter extends CustomPainter {
  const _HeroPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final red = Paint()..color = AppColors.red.withValues(alpha: 0.08);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final triangle = Path()
      ..moveTo(size.width * 0.68, -40)
      ..lineTo(size.width + 50, size.height * 0.46)
      ..lineTo(size.width * 0.72, size.height + 80)
      ..close();
    canvas.drawPath(triangle, red);

    for (var i = 0; i < 4; i++) {
      final inset = i * 26.0;
      final outline = Path()
        ..moveTo(size.width * 0.78 + inset, -30)
        ..lineTo(size.width + 80 + inset, size.height * 0.48)
        ..lineTo(size.width * 0.80 + inset, size.height + 60)
        ..close();
      canvas.drawPath(outline, line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: const Color(0xFF2A2D30)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.red,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'MEMBER DETAILS UNAVAILABLE',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: context.read<MemberDashboardCubit>().load,
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

double? _subscriptionProgress(
  DateTime? startDate,
  DateTime? endDate,
  DateTime now,
) {
  if (startDate == null || endDate == null || !endDate.isAfter(startDate)) {
    return null;
  }
  final total = endDate.difference(startDate).inMinutes;
  final elapsed = now.difference(startDate).inMinutes;
  return math.max(0, math.min(1, elapsed / total));
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Not available';
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
  final day = date.day.toString().padLeft(2, '0');
  return '$day ${months[date.month - 1]} ${date.year}';
}

String _formatCurrency(double amount) {
  final value = amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
  return 'Rs. $value';
}
