import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triangle_fitness/core/theme/app_colors.dart';
import 'package:triangle_fitness/features/auth/presentation/widgets/admin_workspace.dart';

const _card = AdminWorkspaceColors.surface;
const _text = AdminWorkspaceColors.text;
const _muted = AdminWorkspaceColors.muted;
const _line = AdminWorkspaceColors.border;
const _active = AdminWorkspaceColors.success;

class AdminSubscriptionPlan {
  const AdminSubscriptionPlan({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.price,
    required this.isActive,
  });

  factory AdminSubscriptionPlan.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return AdminSubscriptionPlan(
      id: document.id,
      name: _string(data['name'] ?? data['planName']),
      durationDays: _integer(data['durationDays']),
      price: _number(data['price']),
      isActive: data['isActive'] == true,
    );
  }

  final String id;
  final String name;
  final int durationDays;
  final double price;
  final bool isActive;
}

class SubscriptionsManagementPage extends StatefulWidget {
  const SubscriptionsManagementPage({super.key, this.plansStream});

  final Stream<List<AdminSubscriptionPlan>>? plansStream;

  @override
  State<SubscriptionsManagementPage> createState() =>
      _SubscriptionsManagementPageState();
}

class _SubscriptionsManagementPageState
    extends State<SubscriptionsManagementPage> {
  late Stream<List<AdminSubscriptionPlan>> _plansStream;

  @override
  void initState() {
    super.initState();
    _plansStream = widget.plansStream ?? _watchPlans();
  }

  Stream<List<AdminSubscriptionPlan>> _watchPlans() async* {
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError('Your admin session has expired. Please login again.');
    }
    yield* FirebaseFirestore.instance
        .collection('subscriptions')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AdminSubscriptionPlan.fromDocument)
              .toList(growable: false),
        );
  }

  void _retry() {
    setState(() => _plansStream = widget.plansStream ?? _watchPlans());
  }

  Future<void> _openForm([AdminSubscriptionPlan? plan]) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SubscriptionPlanDialog(plan: plan),
    );
  }

  Future<void> _deactivate(AdminSubscriptionPlan plan) async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        throw StateError('Your admin session has expired. Please login again.');
      }
      await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(plan.id)
          .update({
            'isActive': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${plan.name} deactivated successfully')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to deactivate plan: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminWorkspaceScaffold(
      section: AdminWorkspaceSection.subscriptions,
      title: 'Subscriptions',
      subtitle: 'Create and manage membership plans and pricing',
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-subscription-plan'),
        onPressed: _openForm,
        icon: const Icon(Icons.add_card_rounded),
        label: const Text('ADD SUBSCRIPTION PLAN'),
      ),
      body: StreamBuilder<List<AdminSubscriptionPlan>>(
        stream: _plansStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _PageError(error: snapshot.error, onRetry: _retry);
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.red),
            );
          }
          final plans = snapshot.data!;
          if (plans.isEmpty) {
            return const _EmptyState();
          }
          return _PlansContent(
            plans: plans,
            onEdit: _openForm,
            onDeactivate: _deactivate,
          );
        },
      ),
    );
  }
}

class _PlansContent extends StatelessWidget {
  const _PlansContent({
    required this.plans,
    required this.onEdit,
    required this.onDeactivate,
  });

  final List<AdminSubscriptionPlan> plans;
  final ValueChanged<AdminSubscriptionPlan> onEdit;
  final ValueChanged<AdminSubscriptionPlan> onDeactivate;

  @override
  Widget build(BuildContext context) {
    final activeCount = plans.where((plan) => plan.isActive).length;
    final inactiveCount = plans.length - activeCount;
    final averagePrice = plans.isEmpty
        ? 0.0
        : plans.fold<double>(0, (total, plan) => total + plan.price) /
              plans.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PlansSummary(
                total: plans.length,
                active: activeCount,
                inactive: inactiveCount,
                averagePrice: averagePrice,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MEMBERSHIP CATALOG',
                          style: TextStyle(
                            color: AppColors.red,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.3,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Subscription plans',
                          style: TextStyle(
                            color: _text,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${plans.length} ${plans.length == 1 ? 'plan' : 'plans'}',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1050
                      ? 3
                      : constraints.maxWidth >= 680
                      ? 2
                      : 1;
                  const gap = 16.0;
                  final width =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final entry in plans.indexed)
                        SizedBox(
                          width: width,
                          child: _PlanCard(
                            plan: entry.$2,
                            position: entry.$1 + 1,
                            onEdit: () => onEdit(entry.$2),
                            onDeactivate: entry.$2.isActive
                                ? () => onDeactivate(entry.$2)
                                : null,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlansSummary extends StatelessWidget {
  const _PlansSummary({
    required this.total,
    required this.active,
    required this.inactive,
    required this.averagePrice,
  });

  final int total;
  final int active;
  final int inactive;
  final double averagePrice;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.layers_outlined, 'Total Plans', total.toString(), AppColors.red),
      (Icons.check_circle_outline, 'Active Plans', active.toString(), _active),
      (
        Icons.pause_circle_outline_rounded,
        'Inactive Plans',
        inactive.toString(),
        AdminWorkspaceColors.warning,
      ),
      (
        Icons.payments_outlined,
        'Average Price',
        _currency(averagePrice),
        AdminWorkspaceColors.info,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 540
            ? 2
            : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: AdminSurface(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: item.$4.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(item.$1, color: item.$4, size: 21),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _text,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.$2,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlanCard extends StatefulWidget {
  const _PlanCard({
    required this.plan,
    required this.position,
    required this.onEdit,
    required this.onDeactivate,
  });

  final AdminSubscriptionPlan plan;
  final int position;
  final VoidCallback onEdit;
  final VoidCallback? onDeactivate;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final statusColor = plan.isActive ? _active : _muted;
    final perDay = plan.durationDays > 0 ? plan.price / plan.durationDays : 0.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        key: ValueKey('subscription-plan-${plan.id}'),
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
        height: 350,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _hovered ? const Color(0xFF211416) : _card,
              AdminWorkspaceColors.surfaceRaised,
            ],
          ),
          border: Border.all(color: _hovered ? AppColors.red : _line),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
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
                    color: AppColors.red.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.card_membership_rounded,
                    color: AppColors.red,
                  ),
                ),
                const Spacer(),
                _StatusBadge(
                  label: plan.isActive ? 'ACTIVE' : 'INACTIVE',
                  color: statusColor,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.position.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: AdminWorkspaceColors.borderStrong,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              _display(plan.name),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _text,
                fontSize: 22,
                height: 1.05,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              '${plan.durationDays} days membership',
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              _currency(plan.price),
              style: const TextStyle(
                color: _text,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '${_currency(perDay)} per day',
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: AdminWorkspaceColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'DOC ID  ${plan.id}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: const Text('EDIT'),
                  ),
                ),
                if (widget.onDeactivate != null) ...[
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    onPressed: widget.onDeactivate,
                    tooltip: 'Deactivate plan',
                    icon: const Icon(
                      Icons.pause_circle_outline_rounded,
                      size: 19,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionPlanDialog extends StatefulWidget {
  const _SubscriptionPlanDialog({this.plan});

  final AdminSubscriptionPlan? plan;

  @override
  State<_SubscriptionPlanDialog> createState() =>
      _SubscriptionPlanDialogState();
}

class _SubscriptionPlanDialogState extends State<_SubscriptionPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _durationController;
  late final TextEditingController _priceController;
  late bool _isActive;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.plan != null;

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    _nameController = TextEditingController(text: plan?.name ?? '');
    _durationController = TextEditingController(
      text: plan == null ? '' : plan.durationDays.toString(),
    );
    _priceController = TextEditingController(
      text: plan == null ? '' : _plainNumber(plan.price),
    );
    _isActive = plan?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        throw StateError('Your admin session has expired. Please login again.');
      }
      final values = <String, dynamic>{
        'name': _nameController.text.trim(),
        'durationDays': int.parse(_durationController.text.trim()),
        'price': double.parse(_priceController.text.trim()),
        'isActive': _editing ? _isActive : true,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final collection = FirebaseFirestore.instance.collection('subscriptions');
      if (_editing) {
        await collection.doc(widget.plan!.id).update(values);
      } else {
        await collection.add({
          ...values,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _editing
                ? 'Subscription plan updated successfully'
                : 'Subscription plan added successfully',
          ),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Unable to save subscription plan: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _card,
      title: Text(
        _editing ? 'Edit Subscription Plan' : 'Add Subscription Plan',
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FormField(
                  controller: _nameController,
                  label: 'Plan Name',
                  validator: _required,
                ),
                const SizedBox(height: 14),
                _FormField(
                  controller: _durationController,
                  label: 'Duration Days',
                  keyboardType: TextInputType.number,
                  validator: _positiveInteger,
                ),
                const SizedBox(height: 14),
                _FormField(
                  controller: _priceController,
                  label: 'Price',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _positiveNumber,
                ),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle: Text(
                    _editing
                        ? 'Inactive plans are hidden from member forms.'
                        : 'New plans are active initially.',
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                  value: _isActive,
                  onChanged: _editing
                      ? (value) => setState(() => _isActive = value)
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: AppColors.red)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('SAVE'),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.card_membership_outlined, color: _muted, size: 50),
          SizedBox(height: 12),
          Text(
            'No subscription plans found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _PageError extends StatelessWidget {
  const _PageError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.red, size: 44),
            const SizedBox(height: 12),
            Text(
              'Unable to load subscriptions: $error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('TRY AGAIN'),
            ),
          ],
        ),
      ),
    );
  }
}

String? _required(String? value) {
  return value == null || value.trim().isEmpty
      ? 'This field is required.'
      : null;
}

String? _positiveInteger(String? value) {
  final parsed = int.tryParse(value?.trim() ?? '');
  return parsed == null || parsed <= 0
      ? 'Enter a positive whole number.'
      : null;
}

String? _positiveNumber(String? value) {
  final parsed = double.tryParse(value?.trim() ?? '');
  return parsed == null || parsed < 0 ? 'Enter a valid amount.' : null;
}

String _string(Object? value) => value?.toString().trim() ?? '';

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _number(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _plainNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);

String _currency(double value) => 'Rs. ${_plainNumber(value)}';

String _display(String value) => value.isEmpty ? 'Not available' : value;
