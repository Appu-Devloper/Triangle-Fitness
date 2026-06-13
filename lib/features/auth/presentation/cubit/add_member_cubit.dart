import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triangle_fitness/features/auth/domain/entities/create_member_request.dart';
import 'package:triangle_fitness/features/auth/domain/entities/subscription_plan.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/member_management_repository.dart';

enum AddMemberStatus { initial, loading, ready, submitting, success, failure }

class AddMemberState extends Equatable {
  const AddMemberState({
    this.status = AddMemberStatus.initial,
    this.plans = const [],
    this.selectedPlan,
    this.startDate,
    this.endDate,
    this.message,
  });

  final AddMemberStatus status;
  final List<SubscriptionPlan> plans;
  final SubscriptionPlan? selectedPlan;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? message;

  AddMemberState copyWith({
    AddMemberStatus? status,
    List<SubscriptionPlan>? plans,
    SubscriptionPlan? selectedPlan,
    DateTime? startDate,
    DateTime? endDate,
    String? message,
    bool clearMessage = false,
  }) {
    return AddMemberState(
      status: status ?? this.status,
      plans: plans ?? this.plans,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
    status,
    plans,
    selectedPlan,
    startDate,
    endDate,
    message,
  ];
}

class AddMemberCubit extends Cubit<AddMemberState> {
  AddMemberCubit(this._repository) : super(const AddMemberState());

  final MemberManagementRepository _repository;

  Future<void> loadPlans() async {
    emit(state.copyWith(status: AddMemberStatus.loading, clearMessage: true));
    try {
      final plans = await _repository.getActiveSubscriptionPlans();
      emit(
        state.copyWith(
          status: AddMemberStatus.ready,
          plans: plans,
          message: plans.isEmpty
              ? 'No active subscription plans are available.'
              : null,
          clearMessage: plans.isNotEmpty,
        ),
      );
    } on MemberManagementFailure catch (error) {
      emit(
        state.copyWith(status: AddMemberStatus.failure, message: error.message),
      );
    } on Object catch (error) {
      emit(
        state.copyWith(
          status: AddMemberStatus.failure,
          message: error.toString(),
        ),
      );
    }
  }

  void selectPlan(SubscriptionPlan plan) {
    final startDate = state.startDate;
    emit(
      state.copyWith(
        status: AddMemberStatus.ready,
        selectedPlan: plan,
        endDate: startDate?.add(Duration(days: plan.durationDays)),
        clearMessage: true,
      ),
    );
  }

  void selectStartDate(DateTime startDate) {
    final plan = state.selectedPlan;
    emit(
      state.copyWith(
        status: AddMemberStatus.ready,
        startDate: startDate,
        endDate: plan == null
            ? null
            : startDate.add(Duration(days: plan.durationDays)),
        clearMessage: true,
      ),
    );
  }

  Future<void> submit(CreateMemberRequest request) async {
    emit(
      state.copyWith(status: AddMemberStatus.submitting, clearMessage: true),
    );
    try {
      await _repository.createMember(request);
      emit(state.copyWith(status: AddMemberStatus.success));
    } on MemberManagementFailure catch (error) {
      emit(
        state.copyWith(status: AddMemberStatus.failure, message: error.message),
      );
    } on Object catch (error) {
      emit(
        state.copyWith(
          status: AddMemberStatus.failure,
          message: error.toString(),
        ),
      );
    }
  }
}
