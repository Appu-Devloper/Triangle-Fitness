import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:triangle_fitness/core/theme/app_colors.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_member.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/member_management_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/edit_member_page.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/renew_subscription_page.dart';

const _detailsBackground = AppColors.ink;
const _detailsText = AppColors.paper;
const _detailsMuted = AppColors.muted;
const _detailsLine = Color(0xFF272A2D);

class MemberDetailsPage extends StatelessWidget {
  const MemberDetailsPage({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context),
      child: Scaffold(
        backgroundColor: _detailsBackground,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: _detailsText,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'MEMBER DETAILS',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          actions: [
            IconButton(
              tooltip: 'Renew subscription',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RenewSubscriptionPage(memberId: memberId),
                  ),
                );
              },
              icon: const Icon(Icons.autorenew_rounded, color: Color(0xFF55CA82)),
            ),
            IconButton(
              tooltip: 'Edit member details',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EditMemberPage(memberId: memberId),
                  ),
                );
              },
              icon: const Icon(Icons.edit_rounded, color: AppColors.red),
            ),
            IconButton(
              tooltip: 'Copy phone',
              onPressed: () async {
                final member = await context.read<MemberManagementRepository>().getMember(memberId);
                await Clipboard.setData(ClipboardData(text: member.phone));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phone number copied')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded),
            ),
          ],
        ),
        body: FutureBuilder<AdminMember>(
          future: context.read<MemberManagementRepository>().getMember(
            memberId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.red),
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              final error = snapshot.error;
              final message = error is MemberManagementFailure
                  ? error.message
                  : error?.toString() ?? 'Member profile not found';
              return _DetailsError(message: message);
            }
            return _MemberDetails(member: snapshot.data!);
          },
        ),
      ),
    );
  }
}

class _MemberDetails extends StatelessWidget {
  const _MemberDetails({required this.member});

  final AdminMember member;

  @override
  Widget build(BuildContext context) {
    final status = member.effectiveStatusOn(DateTime.now());
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF22252A), Color(0xFF0B0C0E)],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          width: 102,
                          height: 34,
                          fit: BoxFit.contain,
                        ),
                        const Spacer(),
                        _StatusBadge(status: status),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: AppColors.red.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.red, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initials(member.name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                member.memberCode,
                                style: const TextStyle(
                                  color: AppColors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _DetailsCard(
                title: 'Member information',
                icon: Icons.person_outline_rounded,
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.tag_rounded,
                      label: 'Member Code',
                      value: member.memberCode,
                    ),
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Full Name',
                      value: member.name,
                    ),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone number',
                      value: member.phone,
                    ),
                    _InfoRow(
                      icon: Icons.alternate_email_rounded,
                      label: 'Email address',
                      value: _fallback(member.email),
                    ),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: _fallback(member.address),
                    ),
                    _InfoRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'Receipt No',
                      value: _fallback(member.receiptNo),
                      last: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            icon: Icons.fitness_center_rounded,
                            label: 'WEIGHT',
                            value: _measurement(member.weightKg, 'kg'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatBox(
                            icon: Icons.height_rounded,
                            label: 'HEIGHT',
                            value: _measurement(member.heightCm, 'cm'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _DetailsCard(
                title: 'Subscription',
                icon: Icons.card_membership_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InfoRow(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Plan Name',
                      value: member.planName,
                    ),
                    _InfoRow(
                      icon: Icons.play_circle_outline_rounded,
                      label: 'Start Date',
                      value: _formatDate(member.subscriptionStartDate),
                    ),
                    _InfoRow(
                      icon: Icons.flag_outlined,
                      label: 'End Date',
                      value: _formatDate(member.subscriptionEndDate),
                    ),
                    _InfoRow(
                      icon: Icons.currency_rupee_rounded,
                      label: 'Amount Paid',
                      value: member.subscriptionAmount == null
                          ? 'Not available'
                          : 'Rs. ${_number(member.subscriptionAmount!)}',
                    ),
                    _InfoRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Payment Status',
                      value: member.paymentStatus,
                    ),
                    _InfoRow(
                      icon: Icons.verified_user_outlined,
                      label: 'Member Status',
                      value: status,
                      last: true,
                    ),
                    if (member.subscriptionStartDate != null &&
                        member.subscriptionEndDate != null) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'SUBSCRIPTION PROGRESS',
                        style: TextStyle(
                          color: _detailsMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: _subscriptionProgress(
                            member.subscriptionStartDate,
                            member.subscriptionEndDate,
                            DateTime.now(),
                          ),
                          backgroundColor: const Color(0xFF272A2D),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            status == 'ACTIVE' ? AppColors.red : const Color(0xFF5B5E62),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: _detailsLine),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.red, size: 21),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: _detailsText,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _DetailsError extends StatelessWidget {
  const _DetailsError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.red,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _detailsText),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'ACTIVE'
        ? const Color(0xFF55CA82)
        : status == 'EXPIRED'
        ? const Color(0xFFFF777C)
        : const Color(0xFFFFC66D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

String _fallback(String value) =>
    value.trim().isEmpty ? 'Not available' : value;

String _measurement(double? value, String unit) {
  return value == null ? 'Not added' : '${_number(value)} $unit';
}

String _number(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'M';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
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
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: _detailsMuted),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: _detailsMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: _detailsText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (!last) const Divider(height: 1, color: _detailsLine),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _detailsBackground,
        border: Border.all(color: _detailsLine),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.red),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _detailsMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: _detailsText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

double _subscriptionProgress(DateTime? start, DateTime? end, DateTime now) {
  if (start == null || end == null) return 0.0;
  final total = end.difference(start).inSeconds;
  if (total <= 0) return 0.0;
  final elapsed = now.difference(start).inSeconds;
  return (elapsed / total).clamp(0.0, 1.0);
}
