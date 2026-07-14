import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:triangle_fitness/core/theme/app_colors.dart';
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

  String _status = 'ACTIVE';
  String? _uid;
  String? _errorMessage;
  _LoadStatus _statusLoad = _LoadStatus.loading;

  @override
  void initState() {
    super.initState();
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
      _memberCode.text = editableMemberCodeValue((data['memberCode'] ?? '').toString());
      _name.text = (data['name'] ?? '').toString();
      _phone.text = (data['phone'] ?? '').toString();
      _email.text = (data['email'] ?? '').toString();
      _address.text = (data['address'] ?? '').toString();
      _receiptNo.text = editableReceiptNoValue((data['receiptNo'] ?? '').toString());
      _weight.text = data['weightKg']?.toString() ?? '';
      _height.text = data['heightCm']?.toString() ?? '';
      _status = (data['status'] ?? 'ACTIVE').toString();
      _uid = data['uid'] as String?;
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
    setState(() => _statusLoad = _LoadStatus.submitting);
    try {
      final memberRef = FirebaseFirestore.instance.collection('members').doc(widget.memberId);
      final weight = _nullableNumber(_weight.text);
      final height = _nullableNumber(_height.text);

      await memberRef.update({
        'memberCode': normalizeMemberCode(_memberCode.text),
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'address': _address.text.trim(),
        'receiptNo': normalizeReceiptNo(_receiptNo.text),
        'weightKg': weight,
        'heightCm': height,
        'status': _status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

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
        const SnackBar(content: Text('Member updated successfully')),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
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
                          validator: (v) => hasMeaningfulMemberCode(v ?? '') ? null : 'Enter member code.',
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
                          validator: (v) => hasMeaningfulReceiptNo(v ?? '') ? null : 'Enter receipt number.',
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
        final fieldWidth = twoColumns ? (constraints.maxWidth - gap) / 2 : constraints.maxWidth;
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
