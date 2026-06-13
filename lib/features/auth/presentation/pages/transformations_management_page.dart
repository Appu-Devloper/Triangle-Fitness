import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triangle_fitness/core/theme/app_colors.dart';

const _background = AppColors.ink;
const _card = AppColors.surface;
const _text = AppColors.paper;
const _muted = AppColors.muted;
const _line = Color(0xFF272A2D);
const _published = Color(0xFF55CA82);

enum TransformationFilter { all, published, unpublished }

class TransformationRecord {
  const TransformationRecord({
    required this.id,
    required this.memberId,
    required this.memberCode,
    required this.name,
    required this.title,
    required this.description,
    required this.weightBeforeKg,
    required this.weightAfterKg,
    required this.heightCm,
    required this.durationText,
    required this.isPublished,
    required this.displayOrder,
    required this.createdAt,
  });

  factory TransformationRecord.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return TransformationRecord(
      id: document.id,
      memberId: _string(data['memberId']),
      memberCode: _string(data['memberCode']),
      name: _string(data['name']),
      title: _string(data['title']),
      description: _string(data['description']),
      weightBeforeKg: _nullableNumber(data['weightBeforeKg']),
      weightAfterKg: _nullableNumber(data['weightAfterKg']),
      heightCm: _nullableNumber(data['heightCm']),
      durationText: _string(data['durationText']),
      isPublished: data['isPublished'] == true,
      displayOrder: _integer(data['displayOrder']),
      createdAt: _date(data['createdAt']),
    );
  }

  final String id;
  final String memberId;
  final String memberCode;
  final String name;
  final String title;
  final String description;
  final double? weightBeforeKg;
  final double? weightAfterKg;
  final double? heightCm;
  final String durationText;
  final bool isPublished;
  final int displayOrder;
  final DateTime? createdAt;
}

class _MemberOption {
  const _MemberOption({
    required this.id,
    required this.memberCode,
    required this.name,
    required this.heightCm,
  });

  final String id;
  final String memberCode;
  final String name;
  final double? heightCm;
}

class TransformationsManagementPage extends StatefulWidget {
  const TransformationsManagementPage({super.key});

  @override
  State<TransformationsManagementPage> createState() =>
      _TransformationsManagementPageState();
}

class _TransformationsManagementPageState
    extends State<TransformationsManagementPage> {
  late Stream<List<TransformationRecord>> _transformationsStream;
  String _search = '';
  TransformationFilter _filter = TransformationFilter.all;

  @override
  void initState() {
    super.initState();
    _transformationsStream = _watchTransformations();
  }

  Stream<List<TransformationRecord>> _watchTransformations() async* {
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError('Your admin session has expired. Please login again.');
    }
    yield* FirebaseFirestore.instance
        .collection('transformations')
        .snapshots()
        .map((snapshot) {
          final records = snapshot.docs
              .map(TransformationRecord.fromDocument)
              .toList();
          records.sort((a, b) {
            final order = a.displayOrder.compareTo(b.displayOrder);
            if (order != 0) return order;
            final aCreated =
                a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bCreated =
                b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bCreated.compareTo(aCreated);
          });
          return records;
        });
  }

  List<TransformationRecord> _visible(List<TransformationRecord> records) {
    final query = _search.trim().toLowerCase();
    return records
        .where((record) {
          final matchesSearch =
              query.isEmpty ||
              record.memberCode.toLowerCase().contains(query) ||
              record.name.toLowerCase().contains(query) ||
              record.title.toLowerCase().contains(query);
          final matchesFilter = switch (_filter) {
            TransformationFilter.all => true,
            TransformationFilter.published => record.isPublished,
            TransformationFilter.unpublished => !record.isPublished,
          };
          return matchesSearch && matchesFilter;
        })
        .toList(growable: false);
  }

  void _retry() {
    setState(() => _transformationsStream = _watchTransformations());
  }

  Future<void> _openForm([TransformationRecord? record]) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TransformationDialog(record: record),
    );
  }

  Future<void> _unpublish(TransformationRecord record) async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        throw StateError('Your admin session has expired. Please login again.');
      }
      await FirebaseFirestore.instance
          .collection('transformations')
          .doc(record.id)
          .update({
            'isPublished': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transformation unpublished')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to unpublish transformation: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Transformations',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: _card,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-transformation'),
        onPressed: _openForm,
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_chart_rounded),
        label: const Text(
          'ADD TRANSFORMATION',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<List<TransformationRecord>>(
        stream: _transformationsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _TransformationsError(
              error: snapshot.error,
              onRetry: _retry,
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.red),
            );
          }
          final records = _visible(snapshot.data!);
          return Column(
            children: [
              _Toolbar(
                filter: _filter,
                onSearchChanged: (value) => setState(() => _search = value),
                onFilterChanged: (value) => setState(() => _filter = value),
              ),
              Expanded(
                child: records.isEmpty
                    ? const _EmptyTransformations()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                        itemCount: records.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1100),
                              child: _TransformationCard(
                                record: record,
                                onEdit: () => _openForm(record),
                                onUnpublish: record.isPublished
                                    ? () => _unpublish(record)
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.filter,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  final TransformationFilter filter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<TransformationFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _card,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('transformation-search'),
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search by member code, name or title',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final value in TransformationFilter.values) ...[
                      ChoiceChip(
                        label: Text(value.name.toUpperCase()),
                        selected: filter == value,
                        onSelected: (_) => onFilterChanged(value),
                        selectedColor: AppColors.red,
                        backgroundColor: _background,
                        side: BorderSide(
                          color: filter == value ? AppColors.red : _line,
                        ),
                        showCheckmark: false,
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

class _TransformationCard extends StatelessWidget {
  const _TransformationCard({
    required this.record,
    required this.onEdit,
    required this.onUnpublish,
  });

  final TransformationRecord record;
  final VoidCallback onEdit;
  final VoidCallback? onUnpublish;

  @override
  Widget build(BuildContext context) {
    final statusColor = record.isPublished ? _published : _muted;
    final details = [
      ('Member Code', record.memberCode),
      ('Name', record.name),
      ('Before Weight', _measurement(record.weightBeforeKg, 'kg')),
      ('After Weight', _measurement(record.weightAfterKg, 'kg')),
      ('Height', _measurement(record.heightCm, 'cm')),
      ('Duration', record.durationText),
      ('Display Order', record.displayOrder.toString()),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _display(record.title),
                      style: const TextStyle(
                        color: _text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (record.description.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        record.description,
                        style: const TextStyle(color: _muted, height: 1.45),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  record.isPublished ? 'PUBLISHED' : 'UNPUBLISHED',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _line),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 850
                  ? 4
                  : constraints.maxWidth >= 520
                  ? 2
                  : 1;
              const gap = 14.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: 14,
                children: [
                  for (final detail in details)
                    SizedBox(
                      width: width,
                      child: _Detail(label: detail.$1, value: detail.$2),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('EDIT'),
              ),
              if (onUnpublish != null)
                TextButton.icon(
                  onPressed: onUnpublish,
                  icon: const Icon(Icons.visibility_off_outlined, size: 17),
                  label: const Text('UNPUBLISH'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: _muted,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _display(value),
          style: const TextStyle(color: _text, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _TransformationDialog extends StatefulWidget {
  const _TransformationDialog({this.record});

  final TransformationRecord? record;

  @override
  State<_TransformationDialog> createState() => _TransformationDialogState();
}

class _TransformationDialogState extends State<_TransformationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Future<List<_MemberOption>> _membersFuture;
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _beforeWeight;
  late final TextEditingController _afterWeight;
  late final TextEditingController _height;
  late final TextEditingController _duration;
  late final TextEditingController _displayOrder;
  String? _selectedMemberId;
  _MemberOption? _selectedMember;
  late bool _isPublished;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _selectedMemberId = record?.memberId;
    _title = TextEditingController(text: record?.title ?? '');
    _description = TextEditingController(text: record?.description ?? '');
    _beforeWeight = TextEditingController(
      text: _plainNullable(record?.weightBeforeKg),
    );
    _afterWeight = TextEditingController(
      text: _plainNullable(record?.weightAfterKg),
    );
    _height = TextEditingController(text: _plainNullable(record?.heightCm));
    _duration = TextEditingController(text: record?.durationText ?? '');
    _displayOrder = TextEditingController(
      text: record?.displayOrder.toString() ?? '0',
    );
    _isPublished = record?.isPublished ?? false;
    _membersFuture = _loadMembers();
  }

  Future<List<_MemberOption>> _loadMembers() async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError('Your admin session has expired. Please login again.');
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('members')
        .get();
    final members = snapshot.docs.map((document) {
      final data = document.data();
      return _MemberOption(
        id: document.id,
        memberCode: _string(data['memberCode']),
        name: _string(data['name']),
        heightCm: _nullableNumber(data['heightCm']),
      );
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
    final record = widget.record;
    if (record != null &&
        !members.any((member) => member.id == record.memberId)) {
      members.insert(
        0,
        _MemberOption(
          id: record.memberId,
          memberCode: record.memberCode,
          name: record.name,
          heightCm: record.heightCm,
        ),
      );
    }
    return members;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _beforeWeight.dispose();
    _afterWeight.dispose();
    _height.dispose();
    _duration.dispose();
    _displayOrder.dispose();
    super.dispose();
  }

  void _selectMember(_MemberOption? member) {
    setState(() {
      _selectedMember = member;
      _selectedMemberId = member?.id;
      if (member?.heightCm != null) {
        _height.text = _plainNullable(member!.heightCm);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final member = _selectedMember;
    if (member == null) {
      setState(() => _error = 'Select a member.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('Your admin session has expired. Please login again.');
      }
      final values = <String, dynamic>{
        'memberId': member.id,
        'memberCode': member.memberCode,
        'name': member.name,
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'weightBeforeKg': double.parse(_beforeWeight.text.trim()),
        'weightAfterKg': double.parse(_afterWeight.text.trim()),
        'heightCm': double.parse(_height.text.trim()),
        'durationText': _duration.text.trim(),
        'isPublished': _isPublished,
        'displayOrder': int.parse(_displayOrder.text.trim()),
        'uploadedBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final collection = FirebaseFirestore.instance.collection(
        'transformations',
      );
      if (widget.record == null) {
        await collection.add({
          ...values,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await collection.doc(widget.record!.id).update(values);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Unable to save transformation: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _card,
      title: Text(
        widget.record == null ? 'Add Transformation' : 'Edit Transformation',
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 650),
        child: FutureBuilder<List<_MemberOption>>(
          future: _membersFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Unable to load members: ${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final members = snapshot.data!;
            if (_selectedMember == null && _selectedMemberId != null) {
              for (final member in members) {
                if (member.id == _selectedMemberId) {
                  _selectedMember = member;
                  break;
                }
              }
            }
            return SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<_MemberOption>(
                      initialValue: _selectedMember,
                      decoration: const InputDecoration(
                        labelText: 'Select Member',
                      ),
                      isExpanded: true,
                      items: [
                        for (final member in members)
                          DropdownMenuItem(
                            value: member,
                            child: Text(
                              '${member.memberCode} - ${member.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _selectMember,
                      validator: (value) =>
                          value == null ? 'Select a member.' : null,
                    ),
                    const SizedBox(height: 12),
                    _Field(controller: _title, label: 'Title', required: true),
                    const SizedBox(height: 12),
                    _Field(
                      controller: _description,
                      label: 'Description',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    _NumberFields(
                      before: _beforeWeight,
                      after: _afterWeight,
                      height: _height,
                    ),
                    const SizedBox(height: 12),
                    _Field(controller: _duration, label: 'Duration Text'),
                    const SizedBox(height: 12),
                    _Field(
                      controller: _displayOrder,
                      label: 'Display Order',
                      keyboardType: TextInputType.number,
                      validator: _integerValidator,
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Published'),
                      subtitle: const Text(
                        'Published transformations appear on the public website.',
                        style: TextStyle(color: _muted, fontSize: 11),
                      ),
                      value: _isPublished,
                      onChanged: (value) {
                        setState(() => _isPublished = value);
                      },
                    ),
                    if (_error != null)
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.red),
                      ),
                  ],
                ),
              ),
            );
          },
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

class _NumberFields extends StatelessWidget {
  const _NumberFields({
    required this.before,
    required this.after,
    required this.height,
  });

  final TextEditingController before;
  final TextEditingController after;
  final TextEditingController height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 520
            ? (constraints.maxWidth - 20) / 3
            : constraints.maxWidth;
        return Wrap(
          spacing: 10,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: _Field(
                controller: before,
                label: 'Before Weight Kg',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _numberValidator,
              ),
            ),
            SizedBox(
              width: width,
              child: _Field(
                controller: after,
                label: 'After Weight Kg',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _numberValidator,
              ),
            ),
            SizedBox(
              width: width,
              child: _Field(
                controller: height,
                label: 'Height Cm',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _numberValidator,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator:
          validator ??
          (required
              ? (value) => value == null || value.trim().isEmpty
                    ? 'This field is required.'
                    : null
              : null),
    );
  }
}

class _EmptyTransformations extends StatelessWidget {
  const _EmptyTransformations();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights_outlined, color: _muted, size: 50),
          SizedBox(height: 12),
          Text(
            'No transformations found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _TransformationsError extends StatelessWidget {
  const _TransformationsError({required this.error, required this.onRetry});

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
              'Unable to load transformations: $error',
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

String? _numberValidator(String? value) {
  final parsed = double.tryParse(value?.trim() ?? '');
  return parsed == null || parsed < 0 ? 'Enter a valid number.' : null;
}

String? _integerValidator(String? value) {
  return int.tryParse(value?.trim() ?? '') == null
      ? 'Enter a whole number.'
      : null;
}

String _string(Object? value) => value?.toString().trim() ?? '';

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _nullableNumber(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _date(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

String _plainNullable(double? value) {
  if (value == null) return '';
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

String _measurement(double? value, String unit) {
  final number = _plainNullable(value);
  return number.isEmpty ? 'Not available' : '$number $unit';
}

String _display(String value) => value.isEmpty ? 'Not available' : value;
