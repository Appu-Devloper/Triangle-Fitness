import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triangle_fitness/core/theme/app_colors.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_member.dart';
import 'package:triangle_fitness/features/auth/domain/entities/subscription_plan.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/member_management_repository.dart';

class RenewSubscriptionPage extends StatefulWidget {
  const RenewSubscriptionPage({super.key, required this.memberId});

  final String memberId;

  @override
  State<RenewSubscriptionPage> createState() => _RenewSubscriptionPageState();
}

class _RenewSubscriptionPageState extends State<RenewSubscriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _receiptNo = TextEditingController();
  final _amount = TextEditingController();
  String _paymentMode = 'CASH';
  String _paymentStatus = 'PAID';
  String? _errorMessage;
  SubscriptionPlan? _selectedPlan;
  DateTime? _startDate;
  DateTime? _endDate;
  late Future<List<SubscriptionPlan>> _plansFuture;
  late Future<AdminMember> _memberFuture;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final repository = context.read<MemberManagementRepository>();
    _plansFuture = repository.getActiveSubscriptionPlans();
    _memberFuture = repository.getMember(widget.memberId);
  }

  @override
  void dispose() {
    _receiptNo.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit(AdminMember member) async {
    if (!_formKey.currentState!.validate()) return;
    final plan = _selectedPlan;
    final startDate = _startDate;
    final endDate = _endDate;
    if (plan == null || startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a plan and subscription dates.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final firestore = FirebaseFirestore.instance;
      final memberRef = firestore.collection('members').doc(member.id);
      final paymentRef = firestore.collection('payments').doc();
      final now = FieldValue.serverTimestamp();
      final startTimestamp = Timestamp.fromDate(startDate);
      final endTimestamp = Timestamp.fromDate(endDate);
      final amount = double.parse(_amount.text.trim());
      final receiptNo = _receiptNo.text.trim();

      await firestore.runTransaction((transaction) async {
        transaction.set(paymentRef, {
          'memberId': member.id,
          'memberCode': member.memberCode,
          'memberName': member.name,
          'phone': member.phone,
          'receiptNo': receiptNo,
          'amount': amount,
          'paymentMode': _paymentMode.trim().isEmpty ? 'CASH' : _paymentMode.trim().toUpperCase(),
          'paymentStatus': _paymentStatus.trim().isEmpty ? 'PAID' : _paymentStatus.trim().toUpperCase(),
          'paymentDate': now,
          'subscriptionStartDate': startTimestamp,
          'subscriptionEndDate': endTimestamp,
          'collectedBy': FirebaseAuth.instance.currentUser?.uid,
          'createdAt': now,
          'updatedAt': now,
        });
        transaction.update(memberRef, {
          'status': 'ACTIVE',
          'subscription': {
            'planId': plan.id,
            'planName': plan.name,
            'startDate': startTimestamp,
            'endDate': endTimestamp,
            'status': 'ACTIVE',
            'amount': amount,
            'paymentStatus': _paymentStatus.trim().isEmpty ? 'PAID' : _paymentStatus.trim().toUpperCase(),
          },
          'updatedAt': now,
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription renewed successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _submitting = false;
      });
    }
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (date != null && mounted) {
      setState(() {
        _startDate = date;
        if (_selectedPlan != null) {
          _endDate = date.add(Duration(days: _selectedPlan!.durationDays));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        title: const Text('RENEW SUBSCRIPTION', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_memberFuture, _plansFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.red));
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text(snapshot.error?.toString() ?? 'Unable to load renewal data'));
          }
          final member = snapshot.data![0] as AdminMember;
          final plans = snapshot.data![1] as List<SubscriptionPlan>;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) ...[
                        Text(_errorMessage!, style: const TextStyle(color: AppColors.red)),
                        const SizedBox(height: 12),
                      ],
                      _card(
                        title: 'Renew for ${member.name}',
                        child: Column(
                          children: [
                            _planField(plans),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(child: _dateField('Start Date', _startDate, _pickStartDate)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _dateField(
                                    'End Date',
                                    _endDate,
                                    _selectedPlan == null
                                        ? null
                                        : () async {
                                            final date = await showDatePicker(
                                              context: context,
                                              initialDate: _endDate ?? _startDate ?? DateTime.now(),
                                              firstDate: DateTime(DateTime.now().year - 1),
                                              lastDate: DateTime(DateTime.now().year + 10),
                                            );
                                            if (date != null && mounted) {
                                              setState(() => _endDate = date);
                                            }
                                          },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _receiptNo,
                              decoration: const InputDecoration(
                                labelText: 'Receipt No',
                                prefixIcon: Icon(Icons.receipt_long_outlined),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty ? 'Enter receipt number.' : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _amount,
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                                prefixIcon: Icon(Icons.currency_rupee_rounded),
                                prefixText: 'Rs. ',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                              validator: (value) {
                                final amount = double.tryParse(value?.trim() ?? '');
                                return amount == null || amount <= 0 ? 'Enter a valid amount.' : null;
                              },
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(child: _dropdown('Payment Mode', _paymentMode, const ['CASH', 'UPI', 'CARD', 'BANK'], (value) => setState(() => _paymentMode = value))),
                                const SizedBox(width: 12),
                                Expanded(child: _dropdown('Payment Status', _paymentStatus, const ['PAID', 'PENDING'], (value) => setState(() => _paymentStatus = value))),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                                  child: const Text('CANCEL'),
                                ),
                                const Spacer(),
                                FilledButton.icon(
                                  onPressed: _submitting ? null : () => _submit(member),
                                  icon: _submitting
                                      ? const SizedBox.square(
                                          dimension: 17,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.autorenew_rounded),
                                  label: Text(_submitting ? 'RENEWING...' : 'RENEW SUBSCRIPTION'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _planField(List<SubscriptionPlan> plans) {
    return DropdownButtonFormField<SubscriptionPlan>(
      initialValue: _selectedPlan,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Subscription Plan',
        prefixIcon: Icon(Icons.workspace_premium_outlined),
      ),
      items: plans
          .map(
            (plan) => DropdownMenuItem(
              value: plan,
              child: Text('${plan.name} (${plan.durationDays} days)', overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: _submitting
          ? null
          : (plan) {
              if (plan == null) return;
              setState(() {
                _selectedPlan = plan;
                _amount.text = _numberText(plan.price);
                if (_startDate != null) {
                  _endDate = _startDate!.add(Duration(days: plan.durationDays));
                }
              });
            },
      validator: (value) => value == null ? 'Select a plan.' : null,
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: onTap == null ? null : const Icon(Icons.edit_outlined),
        ),
        child: Text(value == null ? 'Not set' : _formatDate(value)),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.toggle_on_outlined),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: _submitting
          ? null
          : (value) {
              if (value != null) onChanged(value);
            },
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF272A2D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(color: AppColors.paper, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

String _numberText(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

String _formatDate(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}
