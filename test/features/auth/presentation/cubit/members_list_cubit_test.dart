import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_member.dart';
import 'package:triangle_fitness/features/auth/domain/entities/create_member_request.dart';
import 'package:triangle_fitness/features/auth/domain/entities/subscription_plan.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/member_management_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/cubit/members_list_cubit.dart';

void main() {
  final members = _members();

  blocTest<MembersListCubit, MembersListState>(
    'loads members from the repository stream',
    build: () => MembersListCubit(_Repository(members)),
    act: (cubit) => cubit.watch(),
    wait: Duration.zero,
    expect: () => [
      const MembersListState(status: MembersListStatus.loading),
      MembersListState(status: MembersListStatus.success, members: members),
    ],
  );

  test('search matches name, phone and member code', () {
    final state = MembersListState(
      status: MembersListStatus.success,
      members: members,
      searchQuery: '98765',
    );
    expect(state.visibleMembers(DateTime(2026, 6, 13)).single.name, 'Arun Rao');

    final codeSearch = MembersListState(
      status: MembersListStatus.success,
      members: members,
      searchQuery: 'TF002',
    );
    expect(
      codeSearch.visibleMembers(DateTime(2026, 6, 13)).single.name,
      'Meera K',
    );
  });

  test('expired filter overrides active member status', () {
    final state = MembersListState(
      status: MembersListStatus.success,
      members: members,
      filter: MembersFilter.expired,
    );
    final visible = state.visibleMembers(DateTime(2026, 6, 13));
    expect(visible.single.name, 'Expired Member');
    expect(visible.single.status, 'ACTIVE');
  });
}

List<AdminMember> _members() => [
  _member(
    id: 'one',
    code: 'TF001',
    name: 'Arun Rao',
    phone: '9876543210',
    status: 'ACTIVE',
    endDate: DateTime(2026, 7, 13),
  ),
  _member(
    id: 'two',
    code: 'TF002',
    name: 'Meera K',
    phone: '9000000000',
    status: 'INACTIVE',
    endDate: DateTime(2026, 8, 1),
  ),
  _member(
    id: 'three',
    code: 'TF003',
    name: 'Expired Member',
    phone: '8000000000',
    status: 'ACTIVE',
    endDate: DateTime(2026, 6, 12),
  ),
];

AdminMember _member({
  required String id,
  required String code,
  required String name,
  required String phone,
  required String status,
  required DateTime endDate,
}) {
  return AdminMember(
    id: id,
    memberCode: code,
    name: name,
    phone: phone,
    email: '',
    address: '',
    receiptNo: '',
    weightKg: null,
    heightCm: null,
    planName: 'Monthly',
    subscriptionStartDate: DateTime(2026, 5, 13),
    subscriptionEndDate: endDate,
    subscriptionAmount: 1000,
    paymentStatus: 'PAID',
    status: status,
  );
}

class _Repository implements MemberManagementRepository {
  _Repository(this.members);

  final List<AdminMember> members;

  @override
  Stream<List<AdminMember>> watchMembers() => Stream.value(members);

  @override
  Future<AdminMember> getMember(String memberId) async =>
      members.firstWhere((member) => member.id == memberId);

  @override
  Future<void> createMember(CreateMemberRequest request) async {}

  @override
  Future<List<SubscriptionPlan>> getActiveSubscriptionPlans() async => const [];
}
