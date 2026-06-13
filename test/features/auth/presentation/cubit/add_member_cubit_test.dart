import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_fitness/features/auth/domain/entities/create_member_request.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_member.dart';
import 'package:triangle_fitness/features/auth/domain/entities/subscription_plan.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/member_management_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/cubit/add_member_cubit.dart';

void main() {
  const plan = SubscriptionPlan(
    id: 'gold',
    name: 'Gold Monthly',
    durationDays: 30,
    price: 1500,
  );

  blocTest<AddMemberCubit, AddMemberState>(
    'loads active subscription plans',
    build: () => AddMemberCubit(_MemberManagementRepository(plans: [plan])),
    act: (cubit) => cubit.loadPlans(),
    expect: () => [
      const AddMemberState(status: AddMemberStatus.loading),
      const AddMemberState(status: AddMemberStatus.ready, plans: [plan]),
    ],
  );

  test('calculates end date from selected plan duration', () {
    final cubit = AddMemberCubit(_MemberManagementRepository(plans: [plan]));
    addTearDown(cubit.close);

    cubit.selectPlan(plan);
    cubit.selectStartDate(DateTime(2026, 6, 13));

    expect(cubit.state.selectedPlan, plan);
    expect(cubit.state.endDate, DateTime(2026, 7, 13));
  });

  final creationRepository = _MemberManagementRepository(plans: [plan]);
  blocTest<AddMemberCubit, AddMemberState>(
    'creates the member and reports success',
    build: () => AddMemberCubit(creationRepository),
    act: (cubit) => cubit.submit(_request(plan)),
    expect: () => [
      const AddMemberState(status: AddMemberStatus.submitting),
      const AddMemberState(status: AddMemberStatus.success),
    ],
    verify: (_) => expect(creationRepository.createdRequest, _request(plan)),
  );
}

CreateMemberRequest _request(SubscriptionPlan plan) {
  return CreateMemberRequest(
    memberCode: 'TF001',
    name: 'Test Member',
    phone: '9876543210',
    email: '',
    address: 'KRS Road',
    receiptNo: 'REC001',
    weightKg: 75,
    heightCm: 174,
    plan: plan,
    startDate: DateTime(2026, 6, 13),
    endDate: DateTime(2026, 7, 13),
    amount: 1500,
    paymentMode: 'CASH',
    paymentStatus: 'PAID',
    memberStatus: 'ACTIVE',
  );
}

class _MemberManagementRepository implements MemberManagementRepository {
  _MemberManagementRepository({required this.plans});

  final List<SubscriptionPlan> plans;
  CreateMemberRequest? createdRequest;

  @override
  Future<void> createMember(CreateMemberRequest request) async {
    createdRequest = request;
  }

  @override
  Future<List<SubscriptionPlan>> getActiveSubscriptionPlans() async => plans;

  @override
  Future<AdminMember> getMember(String memberId) => throw UnimplementedError();

  @override
  Stream<List<AdminMember>> watchMembers() => const Stream.empty();
}
