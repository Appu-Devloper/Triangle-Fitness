import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triangle_fitness/core/theme/app_colors.dart';
import 'package:triangle_fitness/features/auth/domain/entities/create_member_request.dart';
import 'package:triangle_fitness/features/auth/domain/entities/subscription_plan.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/member_management_repository.dart';
import 'package:triangle_fitness/features/auth/presentation/cubit/add_member_cubit.dart';
import 'package:triangle_fitness/features/auth/shared/member_identifier_formatter.dart';
import 'package:triangle_fitness/features/auth/presentation/widgets/admin_workspace.dart';

const _pageBackground = AdminWorkspaceColors.background;
const _card = AdminWorkspaceColors.surface;
const _fieldFill = AdminWorkspaceColors.field;
const _fieldBorder = AdminWorkspaceColors.border;
const _text = AdminWorkspaceColors.text;
const _muted = AdminWorkspaceColors.muted;
const _success = AdminWorkspaceColors.success;

class AddMemberPage extends StatelessWidget {
  const AddMemberPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AddMemberCubit(context.read<MemberManagementRepository>())
            ..loadPlans(),
      child: const _AddMemberView(),
    );
  }
}

class _AddMemberView extends StatefulWidget {
  const _AddMemberView();

  @override
  State<_AddMemberView> createState() => _AddMemberViewState();
}

class _AddMemberViewState extends State<_AddMemberView> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _memberCode = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _receiptNo = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _amount = TextEditingController();
  final _identityKey = GlobalKey();
  final _contactKey = GlobalKey();
  final _fitnessKey = GlobalKey();
  final _membershipKey = GlobalKey();
  final _paymentKey = GlobalKey();

  String _paymentMode = 'CASH';
  String _paymentStatus = 'PAID';
  String _memberStatus = 'ACTIVE';

  @override
  void initState() {
    super.initState();
    _memberCode.text = memberCodePrefix;
    _receiptNo.text = receiptNoPrefix;
    _memberCode.addListener(_refreshPreview);
    _memberCode.addListener(_normalizeMemberCodeField);
    _name.addListener(_refreshPreview);
    _phone.addListener(_refreshPreview);
    _receiptNo.addListener(_normalizeReceiptNoField);
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  void _normalizeMemberCodeField() {
    _applyNormalizedValue(
      _memberCode,
      normalizeMemberCode(_memberCode.text, keepPrefixOnEmpty: true),
    );
  }

  void _normalizeReceiptNoField() {
    _applyNormalizedValue(
      _receiptNo,
      normalizeReceiptNo(_receiptNo.text, keepPrefixOnEmpty: true),
    );
  }

  void _applyNormalizedValue(
    TextEditingController controller,
    String normalized,
  ) {
    if (controller.text == normalized) return;
    var offset = controller.selection.baseOffset;
    if (offset < 0) offset = normalized.length;
    if (offset > normalized.length) offset = normalized.length;
    controller.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  Future<void> _jumpToSection(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _memberCode.removeListener(_refreshPreview);
    _name.removeListener(_refreshPreview);
    _phone.removeListener(_refreshPreview);
    _memberCode.dispose();
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _receiptNo.dispose();
    _weight.dispose();
    _height.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate(AddMemberState state) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: state.startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (date != null && mounted) {
      context.read<AddMemberCubit>().selectStartDate(date);
    }
  }

  void _selectPlan(SubscriptionPlan? plan) {
    if (plan == null) return;
    context.read<AddMemberCubit>().selectPlan(plan);
    _amount.text = _numberText(plan.price);
  }

  void _submit(AddMemberState state) {
    if (!_formKey.currentState!.validate()) return;
    final plan = state.selectedPlan;
    final startDate = state.startDate;
    final endDate = state.endDate;
    if (plan == null || startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a plan and subscription start date.'),
        ),
      );
      return;
    }

    context.read<AddMemberCubit>().submit(
      CreateMemberRequest(
        memberCode: normalizeMemberCode(_memberCode.text),
        name: _name.text.trim(),
        phone: _phone.text.replaceAll(RegExp(r'\D'), ''),
        email: _email.text.trim(),
        address: _address.text.trim(),
        receiptNo: normalizeReceiptNo(_receiptNo.text),
        weightKg: _nullableNumber(_weight.text),
        heightCm: _nullableNumber(_height.text),
        plan: plan,
        startDate: startDate,
        endDate: endDate,
        amount: double.parse(_amount.text.trim()),
        paymentMode: _paymentMode.trim().isEmpty
            ? 'CASH'
            : _paymentMode.trim().toUpperCase(),
        paymentStatus: _paymentStatus.trim().isEmpty
            ? 'PAID'
            : _paymentStatus.trim().toUpperCase(),
        memberStatus: _memberStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = Theme.of(context).copyWith(
      scaffoldBackgroundColor: _pageBackground,
      cardColor: _card,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _fieldFill,
        labelStyle: const TextStyle(color: _muted, fontSize: 12),
        hintStyle: const TextStyle(color: Color(0xFF81878E), fontSize: 12),
        prefixIconColor: const Color(0xFF81878E),
        suffixIconColor: const Color(0xFF81878E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 17,
        ),
      ),
    );

    return Theme(
      data: darkTheme,
      child: BlocConsumer<AddMemberCubit, AddMemberState>(
        listener: (context, state) {
          if (state.status == AddMemberStatus.success) {
            Navigator.of(context).pop('Member created successfully');
          }
        },
        builder: (context, state) {
          final submitting = state.status == AddMemberStatus.submitting;
          return AdminWorkspaceScaffold(
            section: AdminWorkspaceSection.addMember,
            title: 'ADD MEMBER',
            subtitle: 'Create a profile, subscription and member login',
            headerActions: const [_SecureBadge()],
            body: state.status == AddMemberStatus.loading
                ? const _LoadingPlans()
                : _buildWorkspace(state, submitting),
            bottomNavigationBar: state.status == AddMemberStatus.loading
                ? null
                : _ActionBar(
                    submitting: submitting,
                    onCancel: () => Navigator.of(context).pop(),
                    onSubmit: () => _submit(state),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildWorkspace(AddMemberState state, bool submitting) {
    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 980;
          final mobile = !desktop;
          final preview = _RegistrationPreview(
            name: _name.text.trim(),
            memberCode: hasMeaningfulMemberCode(_memberCode.text)
                ? normalizeMemberCode(_memberCode.text)
                : '',
            phone: _phone.text.trim(),
            state: state,
            memberStatus: _memberStatus,
            compact: mobile,
          );
          final form = _buildFormSections(state, submitting);

          return SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              desktop ? 28 : 16,
              24,
              desktop ? 28 : 16,
              34,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: desktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 286, child: preview),
                          const SizedBox(width: 20),
                          Expanded(child: form),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _MobileFormNavigator(
                            onSelect: (section) {
                              switch (section) {
                                case _MemberFormSection.identity:
                                  _jumpToSection(_identityKey);
                                  return;
                                case _MemberFormSection.contact:
                                  _jumpToSection(_contactKey);
                                  return;
                                case _MemberFormSection.fitness:
                                  _jumpToSection(_fitnessKey);
                                  return;
                                case _MemberFormSection.membership:
                                  _jumpToSection(_membershipKey);
                                  return;
                                case _MemberFormSection.payment:
                                  _jumpToSection(_paymentKey);
                                  return;
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          preview,
                          const SizedBox(height: 16),
                          form,
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormSections(AddMemberState state, bool submitting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.message != null) ...[
          _MessageBox(message: state.message!),
          const SizedBox(height: 14),
        ],
        _SectionAnchor(
          key: _identityKey,
          child: _FormSection(
            number: '01',
            title: 'Identity',
            subtitle: 'Basic membership identification',
            icon: Icons.badge_outlined,
            child: _ResponsiveFields(
              children: [
                _input(
                  _memberCode,
                  'Member Code',
                  icon: Icons.tag_rounded,
                  hint: 'Example: TF001',
                  prefixText: ' ',
                  inputFormatters: [_memberCodeFormatter()],
                  validator: (value) {
                    return hasMeaningfulMemberCode(value ?? '')
                        ? null
                        : 'Enter member code.';
                  },
                ),
                _input(
                  _name,
                  'Name',
                  icon: Icons.person_outline_rounded,
                  hint: 'Full member name',
                  validator: _required('Enter member name.'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _SectionAnchor(
          key: _contactKey,
          child: _FormSection(
            number: '02',
            title: 'Contact details',
            subtitle: 'How the gym can reach this member',
            icon: Icons.contact_phone_outlined,
            child: _ResponsiveFields(
              children: [
                _input(
                  _phone,
                  'Phone Number',
                  icon: Icons.phone_outlined,
                  hint: '10-digit mobile number',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    final phone = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                    return phone.length == 10
                        ? null
                        : 'Enter a valid 10-digit phone number.';
                  },
                ),
                _input(
                  _email,
                  'Email (optional)',
                  icon: Icons.alternate_email_rounded,
                  hint: 'Personal email address',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isNotEmpty && !email.contains('@')) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
                _input(
                  _address,
                  'Address',
                  icon: Icons.location_on_outlined,
                  hint: 'Residential address',
                  maxLines: 2,
                  fullWidth: true,
                  validator: _required('Enter address.'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _SectionAnchor(
          key: _fitnessKey,
          child: _FormSection(
            number: '03',
            title: 'Fitness profile',
            subtitle: 'Starting measurements for progress tracking',
            icon: Icons.monitor_weight_outlined,
            child: _ResponsiveFields(
              children: [
                _input(
                  _weight,
                  'Weight Kg',
                  icon: Icons.fitness_center_rounded,
                  hint: 'Example: 75',
                  suffixText: 'kg',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _optionalPositiveNumber('Enter weight in Kg.'),
                ),
                _input(
                  _height,
                  'Height Cm',
                  icon: Icons.height_rounded,
                  hint: 'Example: 174',
                  suffixText: 'cm',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _optionalPositiveNumber('Enter height in Cm.'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _SectionAnchor(
          key: _membershipKey,
          child: _FormSection(
            number: '04',
            title: 'Membership plan',
            subtitle: 'Choose plan and membership period',
            icon: Icons.card_membership_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ResponsiveFields(
                  children: [
                    _FieldSlot(
                      child: DropdownButtonFormField<SubscriptionPlan>(
                        initialValue: state.selectedPlan,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Subscription Plan',
                          prefixIcon: Icon(Icons.workspace_premium_outlined),
                        ),
                        items: state.plans
                            .map(
                              (plan) => DropdownMenuItem(
                                value: plan,
                                child: Text(
                                  '${plan.name} (${plan.durationDays} days)',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: submitting ? null : _selectPlan,
                        validator: (value) => value == null
                            ? 'Select a subscription plan.'
                            : null,
                      ),
                    ),
                    _FieldSlot(
                      child: _DateField(
                        label: 'Subscription Start Date',
                        value: state.startDate,
                        onTap: submitting ? null : () => _pickStartDate(state),
                      ),
                    ),
                    _FieldSlot(
                      child: _DateField(
                        label: 'Subscription End Date',
                        value: state.endDate,
                      ),
                    ),
                    _dropdown(
                      label: 'Member Status',
                      value: _memberStatus,
                      icon: Icons.toggle_on_outlined,
                      options: const ['ACTIVE', 'INACTIVE'],
                      onChanged: (value) {
                        setState(() => _memberStatus = value);
                      },
                    ),
                  ],
                ),
                if (state.selectedPlan != null) ...[
                  const SizedBox(height: 14),
                  _SelectedPlanBanner(
                    plan: state.selectedPlan!,
                    startDate: state.startDate,
                    endDate: state.endDate,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _SectionAnchor(
          key: _paymentKey,
          child: _FormSection(
            number: '05',
            title: 'Payment and login',
            subtitle: 'Receipt, collection and first-login access',
            icon: Icons.payments_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ResponsiveFields(
                  children: [
                    _input(
                      _receiptNo,
                      'Receipt No / Initial Password',
                      icon: Icons.receipt_long_outlined,
                      hint: 'Example: REC-1001',
                      prefixText: ' ',
                      inputFormatters: [_receiptFormatter()],
                      validator: (value) {
                        final receipt = value ?? '';
                        if (!hasMeaningfulReceiptNo(receipt)) {
                          return 'Enter receipt number.';
                        }
                        final normalized = normalizeReceiptNo(receipt);
                        if (normalized.length < 6) {
                          return 'Receipt number must be at least 6 characters.';
                        }
                        return null;
                      },
                    ),
                    _input(
                      _amount,
                      'Amount',
                      icon: Icons.currency_rupee_rounded,
                      hint: 'Plan amount',
                      prefixText: 'Rs. ',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _positiveNumber('Enter a valid amount.'),
                    ),
                    _dropdown(
                      label: 'Payment Mode',
                      value: _paymentMode,
                      icon: Icons.account_balance_wallet_outlined,
                      options: const ['CASH', 'UPI', 'CARD', 'BANK'],
                      onChanged: (value) {
                        setState(() => _paymentMode = value);
                      },
                      validator: _required('Select payment mode.'),
                    ),
                    _dropdown(
                      label: 'Payment Status',
                      value: _paymentStatus,
                      icon: Icons.verified_outlined,
                      options: const ['PAID', 'PENDING'],
                      onChanged: (value) {
                        setState(() => _paymentStatus = value);
                      },
                      validator: _required('Select payment status.'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _LoginNotice(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _FieldSlot _input(
    TextEditingController controller,
    String label, {
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    String? suffixText,
    int maxLines = 1,
    bool fullWidth = false,
    String? Function(String?)? validator,
  }) {
    return _FieldSlot(
      fullWidth: fullWidth,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          prefixText: prefixText,
          suffixText: suffixText,
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  _FieldSlot _dropdown({
    required String label,
    required String value,
    required IconData icon,
    required List<String> options,
    required ValueChanged<String> onChanged,
    String? Function(String?)? validator,
  }) {
    return _FieldSlot(
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        items: options
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (item) {
          if (item != null) onChanged(item);
        },
        validator: validator,
      ),
    );
  }

  String? Function(String?) _required(String message) {
    return (value) => value == null || value.trim().isEmpty ? message : null;
  }

  String? Function(String?) _positiveNumber(String message) {
    return (value) {
      final number = double.tryParse(value?.trim() ?? '');
      return number == null || number <= 0 ? message : null;
    };
  }

  String? Function(String?) _optionalPositiveNumber(String message) {
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return null;
      final number = double.tryParse(text);
      return number == null || number <= 0 ? message : null;
    };
  }
  TextInputFormatter _memberCodeFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      final editable = editableMemberCodeValue(newValue.text);
      return TextEditingValue(
        text: editable,
        selection: TextSelection.collapsed(offset: editable.length),
      );
    });
  }
  TextInputFormatter _receiptFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      final editable = editableReceiptNoValue(newValue.text);
      return TextEditingValue(
        text: editable,
        selection: TextSelection.collapsed(offset: editable.length),
      );
    });
  }
}

class _SecureBadge extends StatelessWidget {
  const _SecureBadge();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (MediaQuery.sizeOf(context).width < 620) {
          return const Icon(Icons.shield_outlined, color: _success, size: 21);
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: _success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: _success, size: 15),
              SizedBox(width: 6),
              Text(
                'SECURE ADMIN ACTION',
                style: TextStyle(
                  color: _success,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _MemberFormSection { identity, contact, fitness, membership, payment }

class _MobileFormNavigator extends StatelessWidget {
  const _MobileFormNavigator({required this.onSelect});

  final ValueChanged<_MemberFormSection> onSelect;

  @override
  Widget build(BuildContext context) {
    const items = [
      (_MemberFormSection.identity, 'Identity', Icons.badge_outlined),
      (_MemberFormSection.contact, 'Contact', Icons.phone_outlined),
      (_MemberFormSection.fitness, 'Fitness', Icons.monitor_weight_outlined),
      (
        _MemberFormSection.membership,
        'Plan',
        Icons.card_membership_rounded,
      ),
      (_MemberFormSection.payment, 'Payment', Icons.payments_outlined),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _fieldBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK JUMP',
            style: TextStyle(
              color: AppColors.red,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.05,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Jump directly to any section while filling the member form on mobile.',
            style: TextStyle(color: _muted, fontSize: 11, height: 1.45),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in items) ...[
                  ActionChip(
                    onPressed: () => onSelect(item.$1),
                    avatar: Icon(item.$3, color: AppColors.red, size: 16),
                    label: Text(item.$2.toUpperCase()),
                    backgroundColor: _fieldFill,
                    side: const BorderSide(color: _fieldBorder),
                    labelStyle: const TextStyle(
                      color: _text,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistrationPreview extends StatelessWidget {
  const _RegistrationPreview({
    required this.name,
    required this.memberCode,
    required this.phone,
    required this.state,
    required this.memberStatus,
    this.compact = false,
  });

  final String name;
  final String memberCode;
  final String phone;
  final AddMemberState state;
  final String memberStatus;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF25282D), Color(0xFF0B0C0E)],
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
          Padding(
            padding: EdgeInsets.all(compact ? 18 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 112,
                      height: 38,
                      fit: BoxFit.contain,
                    ),
                    const Spacer(),
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: memberStatus == 'ACTIVE'
                            ? const Color(0xFF55CA82)
                            : const Color(0xFFFFC66D),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 18 : 26),
                Container(
                  width: compact ? 54 : 62,
                  height: compact ? 54 : 62,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 14 : 18),
                const Text(
                  'NEW GYM MEMBER',
                  style: TextStyle(
                    color: Color(0xFFFF777C),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  name.isEmpty ? 'Member name' : name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: name.isEmpty
                        ? const Color(0xFF777C82)
                        : Colors.white,
                    fontSize: compact ? 20 : 24,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  hasMeaningfulMemberCode(memberCode)
                      ? memberCode
                      : 'Member code not entered',
                  style: const TextStyle(
                    color: Color(0xFFACB0B5),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    phone,
                    style: const TextStyle(
                      color: Color(0xFF7D8288),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(compact ? 16 : 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.055),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(18),
              ),
            ),
            child: Column(
              children: [
                _PreviewRow(
                  label: 'PLAN',
                  value: state.selectedPlan?.name ?? 'Not selected',
                ),
                const SizedBox(height: 13),
                _PreviewRow(
                  label: 'PERIOD',
                  value: state.endDate == null
                      ? 'Select start date'
                      : 'Until ${_dateText(state.endDate!)}',
                ),
                const SizedBox(height: 13),
                _PreviewRow(label: 'STATUS', value: memberStatus),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, compact ? 14 : 18, 20, 22),
            child: compact
                ? const _CompactRegistrationSteps()
                : const _RegistrationSteps(),
          ),
        ],
      ),
    );
  }
}

class _CompactRegistrationSteps extends StatelessWidget {
  const _CompactRegistrationSteps();

  @override
  Widget build(BuildContext context) {
    const labels = ['Identity', 'Contact', 'Fitness', 'Plan', 'Payment'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final label in labels)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFB4B8BD),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF686D73),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFFD4D6D9),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _RegistrationSteps extends StatelessWidget {
  const _RegistrationSteps();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('01', 'Identity'),
      ('02', 'Contact'),
      ('03', 'Fitness'),
      ('04', 'Membership'),
      ('05', 'Payment'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'REGISTRATION CHECKLIST',
          style: TextStyle(
            color: Color(0xFF777C82),
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 13),
        for (final step in steps)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              children: [
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    step.$1,
                    style: const TextStyle(
                      color: Color(0xFFFF777C),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  step.$2,
                  style: const TextStyle(
                    color: Color(0xFFB4B8BD),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionAnchor extends StatelessWidget {
  const _SectionAnchor({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _fieldBorder),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(icon, color: AppColors.red, size: 20),
                    Positioned(
                      right: 4,
                      bottom: 3,
                      child: Text(
                        number,
                        style: const TextStyle(
                          color: AppColors.red,
                          fontSize: 6,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: _fieldBorder),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});

  final List<_FieldSlot> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 620;
        const gap = 14.0;
        final fieldWidth = twoColumns
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final field in children)
              SizedBox(
                width: field.fullWidth ? constraints.maxWidth : fieldWidth,
                child: field.child,
              ),
          ],
        );
      },
    );
  }
}

class _FieldSlot {
  const _FieldSlot({required this.child, this.fullWidth = false});

  final Widget child;
  final bool fullWidth;
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, this.onTap});

  final String label;
  final DateTime? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: Icon(
            onTap == null ? Icons.lock_outline_rounded : Icons.expand_more,
          ),
        ),
        child: Text(
          value == null ? 'Select date' : _dateText(value!),
          style: TextStyle(color: value == null ? _muted : _text, fontSize: 12),
        ),
      ),
    );
  }
}

class _SelectedPlanBanner extends StatelessWidget {
  const _SelectedPlanBanner({
    required this.plan,
    required this.startDate,
    required this.endDate,
  });

  final SubscriptionPlan plan;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.red.withValues(alpha: 0.15),
            AppColors.red.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          _PlanFact(label: 'SELECTED PLAN', value: plan.name),
          _PlanFact(label: 'DURATION', value: '${plan.durationDays} days'),
          _PlanFact(label: 'START', value: _dateTextOrDash(startDate)),
          _PlanFact(label: 'END', value: _dateTextOrDash(endDate)),
        ],
      ),
    );
  }
}

class _PlanFact extends StatelessWidget {
  const _PlanFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.red,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _text,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginNotice extends StatelessWidget {
  const _LoginNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF3159C7).withValues(alpha: 0.12),
        border: Border.all(
          color: const Color(0xFF3159C7).withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF82A3FF), size: 20),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'The member will sign in with their phone number. For first login, use the receipt number like REC-1001 as the temporary password.',
              style: TextStyle(
                color: Color(0xFFD0DFFF),
                fontSize: 11,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.submitting,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool submitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          compact ? 14 : 24,
          12,
          compact ? 14 : 24,
          12,
        ),
        decoration: const BoxDecoration(
          color: _card,
          border: Border(top: BorderSide(color: _fieldBorder)),
          boxShadow: [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 18,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Review the form, then create the member account.',
                    style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: submitting ? null : onSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    icon: submitting
                        ? const SizedBox.square(
                            dimension: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: Text(
                      submitting ? 'CREATING...' : 'CREATE MEMBER',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: submitting ? null : onCancel,
                    style: TextButton.styleFrom(foregroundColor: _muted),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Review all details before creating the member account.',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  ),
                  TextButton(
                    onPressed: submitting ? null : onCancel,
                    style: TextButton.styleFrom(foregroundColor: _muted),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: submitting ? null : onSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    icon: submitting
                        ? const SizedBox.square(
                            dimension: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: Text(
                      submitting ? 'CREATING...' : 'CREATE MEMBER',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _LoadingPlans extends StatelessWidget {
  const _LoadingPlans();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.red),
          SizedBox(height: 14),
          Text(
            'Loading membership plans...',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.07),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _dateText(DateTime date) {
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

String _dateTextOrDash(DateTime? date) =>
    date == null ? 'Not selected' : _dateText(date);

String _numberText(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

double? _nullableNumber(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'NM';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}




