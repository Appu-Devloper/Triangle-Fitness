import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triangle_fitness/core/theme/app_colors.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_member.dart';
import 'package:triangle_fitness/features/auth/domain/entities/membership_expiry.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/member_management_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/cubit/members_list_cubit.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/add_member_page.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/member_details_page.dart';

const _membersBackground = AppColors.ink;
const _membersCard = AppColors.surface;
const _membersText = AppColors.paper;
const _membersMuted = AppColors.muted;
const _membersLine = Color(0xFF272A2D);

class MembersListPage extends StatelessWidget {
  const MembersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MembersListCubit(context.read<MemberManagementRepository>())..watch(),
      child: const _MembersListView(),
    );
  }
}

class _MembersListView extends StatelessWidget {
  const _MembersListView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(
      scaffoldBackgroundColor: _membersBackground,
      cardColor: _membersCard,
    );
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _membersCard,
          foregroundColor: _membersText,
          surfaceTintColor: Colors.transparent,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MEMBERS',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              Text(
                'Search and manage gym memberships',
                style: TextStyle(color: _membersMuted, fontSize: 10),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('add-member-fab'),
          onPressed: () => _openAddMember(context),
          backgroundColor: AppColors.red,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text(
            'ADD MEMBER',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: BlocBuilder<MembersListCubit, MembersListState>(
          builder: (context, state) {
            return Column(
              children: [
                _MembersToolbar(state: state),
                Expanded(child: _MembersBody(state: state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openAddMember(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const AddMemberPage()),
    );
    if (!context.mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
  }
}

class _MembersToolbar extends StatelessWidget {
  const _MembersToolbar({required this.state});

  final MembersListState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _membersCard,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('member-search'),
                onChanged: context.read<MembersListCubit>().search,
                style: const TextStyle(color: _membersText, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name, phone or member code',
                  hintStyle: const TextStyle(color: _membersMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: _membersMuted),
                  filled: true,
                  fillColor: _membersBackground,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _membersLine),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _membersLine),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.red, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 13),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in MembersFilter.values) ...[
                      _FilterChip(
                        filter: filter,
                        selected: state.filter == filter,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.filter, required this.selected});

  final MembersFilter filter;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(filter.name.toUpperCase()),
      selected: selected,
      onSelected: (_) => context.read<MembersListCubit>().filterBy(filter),
      selectedColor: AppColors.red,
      backgroundColor: _membersCard,
      side: BorderSide(color: selected ? AppColors.red : _membersLine),
      labelStyle: TextStyle(
        color: selected ? Colors.white : _membersText,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
      showCheckmark: false,
    );
  }
}

class _MembersBody extends StatelessWidget {
  const _MembersBody({required this.state});

  final MembersListState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == MembersListStatus.loading ||
        state.status == MembersListStatus.initial) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.red),
      );
    }
    if (state.status == MembersListStatus.failure) {
      return _MembersError(message: state.message ?? 'Unable to load members');
    }
    final members = state.visibleMembers(DateTime.now());
    if (members.isEmpty) return const _EmptyMembers();
    return LayoutBuilder(
      builder: (context, constraints) {
        final useMobile = constraints.maxWidth < 800;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: useMobile
                  ? _MobileMembersList(members: members)
                  : _MembersTable(
                      members: members,
                      resetKey:
                          '${state.searchQuery}-${state.filter.name}-${members.length}',
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _MembersTable extends StatefulWidget {
  const _MembersTable({required this.members, required this.resetKey});

  final List<AdminMember> members;
  final String resetKey;

  @override
  State<_MembersTable> createState() => _MembersTableState();
}

class _MembersTableState extends State<_MembersTable> {
  static const _availableRowsPerPage = [5, 10, 20];

  int _rowsPerPage = 10;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  late List<AdminMember> _sortedMembers;

  @override
  void initState() {
    super.initState();
    _sortedMembers = List.of(widget.members);
    // default: sort by expires-in (soonest first)
    final now = DateTime.now();
    _sortedMembers.sort((a, b) {
      final ad = daysUntilMembershipExpiry(a.subscriptionEndDate, now) ?? 9999999;
      final bd = daysUntilMembershipExpiry(b.subscriptionEndDate, now) ?? 9999999;
      return ad.compareTo(bd);
    });
    _sortColumnIndex = 5; // EXPIRES IN column index
    _sortAscending = true;
  }

  @override
  void didUpdateWidget(covariant _MembersTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetKey != widget.resetKey) {
      // rebuild sorted list when underlying members change
      _sortedMembers = List.of(widget.members);
      // reapply previous sort (if any)
      _applyCurrentSort();
    }
  }

  void _applyCurrentSort() {
    final now = DateTime.now();
    if (_sortColumnIndex == 1) {
      _sortedMembers.sort((a, b) {
        final order = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return _sortAscending ? order : -order;
      });
    } else if (_sortColumnIndex == 5) {
      _sortedMembers.sort((a, b) {
        final ad = daysUntilMembershipExpiry(a.subscriptionEndDate, now) ?? 9999999;
        final bd = daysUntilMembershipExpiry(b.subscriptionEndDate, now) ?? 9999999;
        final order = ad.compareTo(bd);
        return _sortAscending ? order : -order;
      });
    }
  }

  void _sort<T>(int columnIndex, Comparable<T> Function(AdminMember m) getField) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }
      _sortedMembers.sort((a, b) {
        final av = getField(a);
        final bv = getField(b);
        final order = Comparable.compare(av, bv);
        return _sortAscending ? order : -order;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Card(
      margin: EdgeInsets.zero,
      color: _membersCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: _membersLine),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: DataTableTheme(
        data: const DataTableThemeData(
          headingTextStyle: TextStyle(
            color: _membersMuted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
          dataTextStyle: TextStyle(
            color: _membersText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: PaginatedDataTable(
          key: ValueKey('members-table-${widget.resetKey}'),
          header: Row(
            children: [
              const Icon(Icons.groups_2_outlined, color: AppColors.red),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Member directory',
                  style: TextStyle(
                    color: _membersText,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${widget.members.length} ${widget.members.length == 1 ? 'member' : 'members'}',
                style: const TextStyle(
                  color: _membersMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          headingRowColor: const WidgetStatePropertyAll(_membersBackground),
          horizontalMargin: 18,
          columnSpacing: 28,
          dataRowMinHeight: 64,
          dataRowMaxHeight: 64,
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
          source: _MembersDataSource(
            context: context,
            members: _sortedMembers,
            now: now,
          ),
          columns: [
            const DataColumn(label: Text('MEMBER CODE')),
            DataColumn(
              label: const Text('NAME'),
              onSort: (ci, _) => _sort<String>(ci, (m) => m.name.toLowerCase()),
            ),
            const DataColumn(label: Text('PHONE')),
            const DataColumn(label: Text('PLAN')),
            const DataColumn(label: Text('END DATE')),
            DataColumn(
              label: const Text('EXPIRES IN'),
              onSort: (ci, _) => _sort<num?>(
                ci,
                (m) => daysUntilMembershipExpiry(m.subscriptionEndDate, now) ?? double.maxFinite.toInt(),
              ),
            ),
            const DataColumn(label: Text('STATUS')),
          ],
        ),
      ),
    );
  }
}

class _MembersDataSource extends DataTableSource {
  _MembersDataSource({
    required this.context,
    required this.members,
    required this.now,
  });

  final BuildContext context;
  final List<AdminMember> members;
  final DateTime now;

  @override
  DataRow? getRow(int index) {
    if (index >= members.length) return null;
    final member = members[index];
    final status = member.effectiveStatusOn(now);
    return DataRow.byIndex(
      index: index,
      onSelectChanged: (_) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MemberDetailsPage(memberId: member.id),
          ),
        );
      },
      cells: [
        DataCell(
          Text(
            member.memberCode,
            style: const TextStyle(
              color: AppColors.red,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MemberAvatar(name: member.name),
              const SizedBox(width: 11),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(member.phone)),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              member.planName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(_formatDate(member.subscriptionEndDate))),
        DataCell(_ExpiryValue(value: member.expiresInOn(now), status: status)),
        DataCell(_MemberStatus(status: status)),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => members.length;

  @override
  int get selectedRowCount => 0;
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ExpiryValue extends StatelessWidget {
  const _ExpiryValue({required this.value, required this.status});

  final String value;
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'EXPIRED'
        ? const Color(0xFFFF777C)
        : status == 'ACTIVE'
        ? const Color(0xFF55CA82)
        : const Color(0xFFFFC66D);
    return Text(
      value,
      style: TextStyle(color: color, fontWeight: FontWeight.w800),
    );
  }
}

class _MemberStatus extends StatelessWidget {
  const _MemberStatus({required this.status});

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
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _EmptyMembers extends StatelessWidget {
  const _EmptyMembers();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_off_outlined, color: _membersMuted, size: 50),
          SizedBox(height: 13),
          Text(
            'No members found',
            style: TextStyle(
              color: _membersText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MembersError extends StatelessWidget {
  const _MembersError({required this.message});

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
              style: const TextStyle(color: _membersText),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: context.read<MembersListCubit>().watch,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('TRY AGAIN'),
            ),
          ],
        ),
      ),
    );
  }
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

class _MobileMembersList extends StatelessWidget {
  const _MobileMembersList({required this.members});

  final List<AdminMember> members;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final member = members[index];
        return _MemberCardItem(member: member);
      },
    );
  }
}

class _MemberCardItem extends StatelessWidget {
  const _MemberCardItem({required this.member});

  final AdminMember member;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = member.effectiveStatusOn(now);
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MemberDetailsPage(memberId: member.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _membersCard,
          border: Border.all(color: _membersLine),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _MemberAvatar(name: member.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          color: _membersText,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.memberCode,
                        style: const TextStyle(
                          color: AppColors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                _MemberStatus(status: status),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: _membersLine),
            const SizedBox(height: 14),
            _MobileInfoRow(
              icon: Icons.phone_outlined,
              label: 'PHONE',
              value: member.phone,
            ),
            const SizedBox(height: 10),
            _MobileInfoRow(
              icon: Icons.workspace_premium_outlined,
              label: 'PLAN',
              value: member.planName,
            ),
            const SizedBox(height: 10),
            _MobileInfoRow(
              icon: Icons.event_outlined,
              label: 'EXPIRES',
              value: '${_formatDate(member.subscriptionEndDate)} (${member.expiresInOn(now)})',
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileInfoRow extends StatelessWidget {
  const _MobileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _membersMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: _membersMuted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _membersText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
