import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triangle_fitness/core/theme/app_colors.dart';
import 'package:triangle_fitness/features/auth/domain/entities/subscription_plan.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/member_management_repository.dart';
import 'package:triangle_fitness/features/auth/shared/member_identifier_formatter.dart';
import 'package:triangle_fitness/features/auth/presentation/pages/member_details_page.dart';

class EditMemberPage extends StatefulWidget {
  const EditMemberPage({super.key, required this.memberId});

  final String memberId;

  @override
  State<EditMemberPage> createState() => _EditMemberPageState();
}

enum _LoadStatus { loading, ready, notFound, error, submitting }

class _EditMemberPageState extends State<EditMemberPage> {
  final _formKey = GlobalKey<FormState>();

  final _memberCode = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _receiptNo = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _subscriptionAmount = TextEditingController();

  String _status = 'ACTIVE';
  String _paymentStatus = 'PAID';
  String? _uid;
  String? _errorMessage;
  String? _selectedPlanId;
  String? _selectedPlanName;
  DateTime? _subscriptionStartDate;
  DateTime? _subscriptionEndDate;
  String _currentReceiptNo = '';
  _LoadStatus _statusLoad = _LoadStatus.loading;
  late Future<List<SubscriptionPlan>> _plansFuture;

  @override
  void initState() {
    super.initState();
    _plansFuture = context.read<MemberManagementRepository>().getActiveSubscriptionPlans();
    _loadMember();
  }

  Future<void> _loadMember() async {
    setState(() => _statusLoad = _LoadStatus.loading);
    try {
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('members').doc(widget.memberId).get();
      if (!doc.exists || doc.data() == null) {
        setState(() => _statusLoad = _LoadStatus.notFound);
        return;
      }
      final data = doc.data()!;
      _memberCode.text = editableMemberCodeValue(
        (data['memberCode'] ?? '').toString(),
      );
      _name.text = (data['name'] ?? '').toString();
      _phone.text = (data['phone'] ?? '').toString();
      _email.text = (data['email'] ?? '').toString();
      _address.text = (data['address'] ?? '').toString();
      _receiptNo.text = editableReceiptNoValue(
        (data['receiptNo'] ?? '').toString(),
      );
      _currentReceiptNo = normalizeReceiptNo(_receiptNo.text);
      _weight.text = data['weightKg']?.toString() ?? '';
      _height.text = data['heightCm']?.toString() ?? '';
      _status = (data['status'] ?? 'ACTIVE').toString();
      _uid = data['uid'] as String?;
      final subscription = data['subscription'] as Map<String, dynamic>?;
      _selectedPlanId = subscription?['planId']?.toString();
      _selectedPlanName = (subscription?['planName'] ?? subscription?['name'])?.toString();
      _subscriptionStartDate = _date(subscription?['startDate']);
      _subscriptionEndDate = _date(subscription?['endDate']);
      _subscriptionAmount.text = subscription?['amount']?.toString() ?? '';
      _paymentStatus = (subscription?['paymentStatus'] ?? 'PAID').toString().trim().toUpperCase();
      setState(() => _statusLoad = _LoadStatus.ready);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _statusLoad = _LoadStatus.error;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final oldReceiptNo = _currentReceiptNo;
    final newReceiptNo = normalizeReceiptNo(_receiptNo.text);
    final confirm = await _confirmSave(oldReceiptNo);
    if (!confirm || !mounted) return;
    setState(() => _statusLoad = _LoadStatus.submitting);
    try {
      final memberRef = FirebaseFirestore.instance
          .collection('members')
          .doc(widget.memberId);
      final paymentRef = await _findRelatedPaymentRef(
        memberId: widget.memberId,
        receiptNo: oldReceiptNo,
      );

      final weight = _nullableNumber(_weight.text);
      final height = _nullableNumber(_height.text);
      final planAmount = _nullableNumber(_subscriptionAmount.text);
      final paymentStatus = _paymentStatus;
      final subscriptionStatus = _status.trim().isEmpty ? 'ACTIVE' : _status.trim().toUpperCase();
      final planName = _selectedPlanName ?? '';
      final planId = _selectedPlanId;
      final startDate = _subscriptionStartDate;
      final endDate = _subscriptionEndDate;

      if (paymentRef == null) {
        final proceed = await _confirmNoPaymentFound();
        if (!proceed || !mounted) {
          setState(() => _statusLoad = _LoadStatus.ready);
          return;
        }
      }

      final updates = <String, dynamic>{
        'memberCode': normalizeMemberCode(_memberCode.text),
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'address': _address.text.trim(),
        'receiptNo': newReceiptNo,
        'weightKg': weight,
        'heightCm': height,
        'status': _status,
        'subscription': {
          'planId': planId,
          'planName': planName,
          'startDate': startDate == null ? null : Timestamp.fromDate(startDate),
          'endDate': endDate == null ? null : Timestamp.fromDate(endDate),
          'status': subscriptionStatus,
          'amount': planAmount,
          'paymentStatus': paymentStatus,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await memberRef.update(updates);

      if (paymentRef != null) {
        await paymentRef.update({
          'receiptNo': newReceiptNo,
          'amount': planAmount,
          'paymentStatus': paymentStatus,
          'subscriptionStartDate': startDate == null ? null : Timestamp.fromDate(startDate),
          'subscriptionEndDate': endDate == null ? null : Timestamp.fromDate(endDate),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // update linked userCredentials if uid exists
      if (_uid != null && _uid!.isNotEmpty) {
        final credRef = FirebaseFirestore.instance.collection('userCredentials').doc(_uid);
        await credRef.set({
          'memberCode': normalizeMemberCode(_memberCode.text),
          'phone': _phone.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription and receipt payment corrected successfully')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => MemberDetailsPage(memberId: widget.memberId),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _statusLoad = _LoadStatus.error;
      });
    }
  }

  Future<bool> _confirmSave(String oldReceiptNo) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm correction'),
        content: Text(
          'This will update the member subscription and the payment record linked with receipt number $oldReceiptNo. No new payment will be created.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _confirmNoPaymentFound() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No matching payment found'),
        content: const Text(
          'No matching payment found for this receipt number. Only member subscription will be updated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<DocumentReference<Map<String, dynamic>>?> _findRelatedPaymentRef({
    required String memberId,
    required String receiptNo,
  }) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('memberId', isEqualTo: memberId)
        .where('receiptNo', isEqualTo: receiptNo)
        .get();
    if (snapshot.docs.isEmpty) return null;
    if (snapshot.docs.length == 1) {
      return snapshot.docs.first.reference;
    }
    QueryDocumentSnapshot<Map<String, dynamic>> latest = snapshot.docs.first;
    for (final doc in snapshot.docs.skip(1)) {
      if (_isLaterPayment(doc.data(), latest.data())) {
        latest = doc;
      }
    }
    return latest.reference;
  }

  bool _isLaterPayment(
    Map<String, dynamic> candidate,
    Map<String, dynamic> current,
  ) {
    final candidateDate = _paymentSortDate(candidate);
    final currentDate = _paymentSortDate(current);
    if (candidateDate != null && currentDate != null) {
      return candidateDate.isAfter(currentDate);
    }
    if (candidateDate != null) return true;
    return false;
  }

  DateTime? _paymentSortDate(Map<String, dynamic> data) {
    final paymentDate = _date(data['paymentDate']);
    if (paymentDate != null) return paymentDate;
    return _date(data['createdAt']);
  }

  @override
  void dispose() {
    _memberCode.dispose();
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _receiptNo.dispose();
    _weight.dispose();
    _height.dispose();
    _subscriptionAmount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = Theme.of(context).copyWith(
      scaffoldBackgroundColor: AppColors.ink,
      cardColor: AppColors.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D0F11),
        labelStyle: const TextStyle(color: AppColors.muted, fontSize: 12),
        hintStyle: const TextStyle(color: Color(0xFF81878E), fontSize: 12),
        prefixIconColor: const Color(0xFF81878E),
        suffixIconColor: const Color(0xFF81878E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFF272A2D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFF272A2D)),
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('EDIT MEMBER', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.paper,
          surfaceTintColor: Colors.transparent,
        ),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_statusLoad == _LoadStatus.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.red));
    }
    if (_statusLoad == _LoadStatus.notFound) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 44),
              const SizedBox(height: 12),
              const Text('Member not found', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }
    if (_statusLoad == _LoadStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 44),
              const SizedBox(height: 12),
              Text(_errorMessage ?? 'An error occurred'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadMember,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final submitting = _statusLoad == _LoadStatus.submitting;

    return FutureBuilder<List<SubscriptionPlan>>(
      future: _plansFuture,
      builder: (context, snapshot) {
        final plans = snapshot.data ?? const <SubscriptionPlan>[];
        final activePlan = _resolveSelectedPlan(plans);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FormSection(
                      number: '01',
                      title: 'Identity',
                      subtitle: 'Basic membership identification',
                      icon: Icons.badge_outlined,
                      child: _ResponsiveFields(
                        children: [
                          _FieldSlot(
                            child: _input(
                              _memberCode,
                              'Member Code',
                              Icons.tag_rounded,
                              prefixText: '$memberCodePrefix ',
                              validator: (v) => hasMeaningfulMemberCode(v ?? '')
                                  ? null
                                  : 'Enter member code.',
                            ),
                          ),
                          _FieldSlot(
                            child: _input(
                              _name,
                              'Name',
                              Icons.person_outline_rounded,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter name.' : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FormSection(
                      number: '02',
                      title: 'Contact details',
                      subtitle: 'How the gym can reach this member',
                      icon: Icons.contact_phone_outlined,
                      child: _ResponsiveFields(
                        children: [
                          _FieldSlot(
                            child: _input(
                              _phone,
                              'Phone',
                              Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter phone.' : null,
                            ),
                          ),
                          _FieldSlot(
                            child: _input(
                              _email,
                              'Email (optional)',
                              Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          _FieldSlot(
                            fullWidth: true,
                            child: _input(
                              _address,
                              'Address',
                              Icons.location_on_outlined,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FormSection(
                      number: '03',
                      title: 'Fitness profile',
                      subtitle: 'Current measurements for tracking',
                      icon: Icons.monitor_weight_outlined,
                      child: _ResponsiveFields(
                        children: [
                          _FieldSlot(
                            child: _input(
                              _weight,
                              'Weight Kg',
                              Icons.fitness_center_rounded,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: _optionalPositiveNumber('Enter a valid weight in Kg.'),
                            ),
                          ),
                          _FieldSlot(
                            child: _input(
                              _height,
                              'Height Cm',
                              Icons.height_rounded,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: _optionalPositiveNumber('Enter a valid height in Cm.'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FormSection(
                      number: '04',
                      title: 'Status and receipt',
                      subtitle: 'Administrative status and initial receipt',
                      icon: Icons.admin_panel_settings_outlined,
                      child: _ResponsiveFields(
                        children: [
                          _FieldSlot(
                            child: _input(
                              _receiptNo,
                              'Receipt No',
                              Icons.receipt_long_outlined,
                              prefixText: '$receiptNoPrefix ',
                              validator: (v) => hasMeaningfulReceiptNo(v ?? '')
                                  ? null
                                  : 'Enter receipt number.',
                            ),
                          ),
                          _FieldSlot(
                            child: DropdownButtonFormField<String>(
                              initialValue: _status,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                prefixIcon: Icon(Icons.toggle_on_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                                DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE')),
                                DropdownMenuItem(value: 'BLOCKED', child: Text('BLOCKED')),
                              ],
                              onChanged: submitting ? null : (v) => setState(() => _status = v ?? 'ACTIVE'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Select status.' : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FormSection(
                      number: '05',
                      title: 'Subscription corrections',
                      subtitle: 'Fix the subscription plan and dates',
                      icon: Icons.card_membership_rounded,
                      child: _ResponsiveFields(
                        children: [
                          _FieldSlot(
                            child: DropdownButtonFormField<SubscriptionPlan>(
                              initialValue: activePlan,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Wrong Plan',
                                prefixIcon: Icon(Icons.workspace_premium_outlined),
                              ),
                              items: plans
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
                              onChanged: submitting
                                  ? null
                                  : (plan) {
                                      if (plan == null) return;
                                      setState(() {
                                        _selectedPlanId = plan.id;
                                        _selectedPlanName = plan.name;
                                        _subscriptionAmount.text = _numberText(plan.price);
                                        if (_subscriptionStartDate != null) {
                                          _subscriptionEndDate =
                                              _subscriptionStartDate!.add(Duration(days: plan.durationDays));
                                        }
                                      });
                                    },
                              validator: (value) => value == null ? 'Select the correct plan.' : null,
                            ),
                          ),
                          _FieldSlot(
                            child: _DateField(
                              label: 'Wrong Start Date',
                              value: _subscriptionStartDate,
                              onTap: submitting ? null : () => _pickSubscriptionStartDate(activePlan),
                            ),
                          ),
                          _FieldSlot(
                            child: _DateField(
                              label: 'Wrong End Date',
                              value: _subscriptionEndDate,
                              onTap: submitting ? null : () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _subscriptionEndDate ?? _subscriptionStartDate ?? DateTime.now(),
                                  firstDate: DateTime(DateTime.now().year - 1),
                                  lastDate: DateTime(DateTime.now().year + 10),
                                );
                                if (date != null && mounted) {
                                  setState(() => _subscriptionEndDate = date);
                                }
                              },
                            ),
                          ),
                          _FieldSlot(
                            child: _input(
                              _subscriptionAmount,
                              'Plan Amount',
                              Icons.currency_rupee_rounded,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: _optionalPositiveNumber('Enter a valid amount.'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        TextButton(
                          onPressed: submitting ? null : () => Navigator.of(context).pop(),
                          child: const Text('CANCEL'),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: submitting ? null : _submit,
                          icon: submitting
                              ? const SizedBox.square(
                                  dimension: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(submitting ? 'UPDATING...' : 'UPDATE MEMBER'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  SubscriptionPlan? _resolveSelectedPlan(List<SubscriptionPlan> plans) {
    if (_selectedPlanId != null) {
      for (final plan in plans) {
        if (plan.id == _selectedPlanId) return plan;
      }
    }
    if (_selectedPlanName != null) {
      for (final plan in plans) {
        if (plan.name == _selectedPlanName) return plan;
      }
    }
    return null;
  }

  Future<void> _pickSubscriptionStartDate(SubscriptionPlan? plan) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _subscriptionStartDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (date != null && mounted) {
      setState(() {
        _subscriptionStartDate = date;
        if (plan != null) {
          _subscriptionEndDate = date.add(Duration(days: plan.durationDays));
        }
      });
    }
  }

  Widget _input(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        prefixText: prefixText,
      ),
      validator: validator,
    );
  }
}

String _numberText(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

DateTime? _date(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String? Function(String?) _optionalPositiveNumber(String message) {
  return (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final number = double.tryParse(text);
    return number == null || number <= 0 ? message : null;
  };
}

double? _nullableNumber(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

String _formatDate(DateTime date) {
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: onTap == null ? null : const Icon(Icons.edit_outlined),
        ),
        child: Text(
          value == null ? 'Not set' : _formatDate(value!),
          style: TextStyle(
            color: value == null ? AppColors.muted : AppColors.paper,
          ),
        ),
      ),
    );
  }
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
        color: AppColors.surface,
        border: Border.all(color: const Color(0xFF272A2D)),
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
                        color: AppColors.paper,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFF272A2D)),
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
