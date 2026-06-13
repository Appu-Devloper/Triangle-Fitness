import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triangle_fitness/core/theme/app_colors.dart';
import 'package:triangle_fitness/features/auth/presentation/widgets/admin_workspace.dart';

const _background = AdminWorkspaceColors.background;
const _card = AdminWorkspaceColors.surface;
const _text = AdminWorkspaceColors.text;
const _muted = AdminWorkspaceColors.muted;
const _line = AdminWorkspaceColors.border;
const _published = AdminWorkspaceColors.success;

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
  const TransformationsManagementPage({super.key, this.transformationsStream});

  final Stream<List<TransformationRecord>>? transformationsStream;

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
    _transformationsStream =
        widget.transformationsStream ?? _watchTransformations();
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
    setState(() {
      _transformationsStream =
          widget.transformationsStream ?? _watchTransformations();
    });
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
    return AdminWorkspaceScaffold(
      section: AdminWorkspaceSection.transformations,
      title: 'Transformations',
      subtitle: 'Curate member progress stories for the public website',
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-transformation'),
        onPressed: _openForm,
        icon: const Icon(Icons.add_chart_rounded),
        label: const Text('ADD TRANSFORMATION'),
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
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1280),
                            child: _TransformationsTable(
                              key: ValueKey(
                                'transformations-table-${records.map((record) => record.id).join('-')}',
                              ),
                              records: records,
                              onEdit: _openForm,
                              onUnpublish: _unpublish,
                            ),
                          ),
                        ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: AdminSurface(
            padding: const EdgeInsets.all(16),
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
      ),
    );
  }
}

class _TransformationsTable extends StatefulWidget {
  const _TransformationsTable({
    super.key,
    required this.records,
    required this.onEdit,
    required this.onUnpublish,
  });

  final List<TransformationRecord> records;
  final ValueChanged<TransformationRecord> onEdit;
  final ValueChanged<TransformationRecord> onUnpublish;

  @override
  State<_TransformationsTable> createState() => _TransformationsTableState();
}

class _TransformationsTableState extends State<_TransformationsTable> {
  static const _availableRowsPerPage = [5, 10, 20];

  int _rowsPerPage = 10;
  int? _sortColumnIndex = 5;
  bool _sortAscending = true;
  late List<TransformationRecord> _records;

  @override
  void initState() {
    super.initState();
    _records = List.of(widget.records);
    _applySort();
  }

  @override
  void didUpdateWidget(covariant _TransformationsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.records != widget.records) {
      _records = List.of(widget.records);
      _applySort();
    }
  }

  void _applySort() {
    if (_sortColumnIndex == 0) {
      _records.sort((a, b) {
        final result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return _sortAscending ? result : -result;
      });
      return;
    }
    if (_sortColumnIndex == 5) {
      _records.sort((a, b) {
        final result = a.displayOrder.compareTo(b.displayOrder);
        if (result != 0) return _sortAscending ? result : -result;
        final aCreated = a.createdAt?.millisecondsSinceEpoch ?? -1;
        final bCreated = b.createdAt?.millisecondsSinceEpoch ?? -1;
        return bCreated.compareTo(aCreated);
      });
    }
  }

  void _sortBy(int columnIndex) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }
      _applySort();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: _card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: _line),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: DataTableTheme(
        data: const DataTableThemeData(
          headingTextStyle: TextStyle(
            color: _muted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
          dataTextStyle: TextStyle(
            color: _text,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: PaginatedDataTable(
          key: const Key('admin-transformations-table'),
          header: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.insights_outlined,
                  color: AppColors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  'Transformation records',
                  style: TextStyle(
                    color: _text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${widget.records.length} records',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          headingRowColor: const WidgetStatePropertyAll(_background),
          horizontalMargin: 18,
          columnSpacing: 26,
          dataRowMinHeight: 78,
          dataRowMaxHeight: 86,
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
          source: _TransformationsDataSource(
            records: _records,
            onEdit: widget.onEdit,
            onUnpublish: widget.onUnpublish,
          ),
          columns: [
            DataColumn(
              label: const Text('MEMBER'),
              onSort: (columnIndex, _) => _sortBy(columnIndex),
            ),
            const DataColumn(label: Text('STORY')),
            const DataColumn(label: Text('PROGRESS')),
            const DataColumn(label: Text('DETAILS')),
            const DataColumn(label: Text('STATUS')),
            DataColumn(
              numeric: true,
              label: const Text('ORDER'),
              onSort: (columnIndex, _) => _sortBy(columnIndex),
            ),
            const DataColumn(label: Text('ACTIONS')),
          ],
        ),
      ),
    );
  }
}

class _TransformationsDataSource extends DataTableSource {
  _TransformationsDataSource({
    required this.records,
    required this.onEdit,
    required this.onUnpublish,
  });

  final List<TransformationRecord> records;
  final ValueChanged<TransformationRecord> onEdit;
  final ValueChanged<TransformationRecord> onUnpublish;

  @override
  DataRow? getRow(int index) {
    if (index >= records.length) return null;
    final record = records[index];
    final change = record.weightBeforeKg != null && record.weightAfterKg != null
        ? record.weightAfterKg! - record.weightBeforeKg!
        : null;
    return DataRow(
      key: ValueKey('transformation-${record.id}'),
      cells: [
        DataCell(
          SizedBox(
            width: 135,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _display(record.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  _display(record.memberCode),
                  style: const TextStyle(color: AppColors.red, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 220,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _display(record.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  _display(record.description),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 145,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProgressLine(
                  label: 'BEFORE',
                  value: _measurement(record.weightBeforeKg, 'kg'),
                ),
                const SizedBox(height: 5),
                _ProgressLine(
                  label: 'AFTER',
                  value: _measurement(record.weightAfterKg, 'kg'),
                  color: _published,
                ),
                if (change != null) ...[
                  const SizedBox(height: 5),
                  _ProgressLine(
                    label: 'CHANGE',
                    value:
                        '${change > 0 ? '+' : ''}${_plainNullable(change)} kg',
                    color: AppColors.red,
                  ),
                ],
              ],
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 145,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProgressLine(
                  label: 'HEIGHT',
                  value: _measurement(record.heightCm, 'cm'),
                ),
                const SizedBox(height: 6),
                _ProgressLine(
                  label: 'DURATION',
                  value: _display(record.durationText),
                ),
              ],
            ),
          ),
        ),
        DataCell(_PublishedBadge(isPublished: record.isPublished)),
        DataCell(
          Text(
            record.displayOrder.toString(),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => onEdit(record),
                tooltip: 'Edit transformation',
                icon: const Icon(Icons.edit_outlined, size: 19),
              ),
              if (record.isPublished)
                IconButton(
                  onPressed: () => onUnpublish(record),
                  tooltip: 'Unpublish transformation',
                  icon: const Icon(Icons.visibility_off_outlined, size: 19),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => records.length;

  @override
  int get selectedRowCount => 0;
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.label,
    required this.value,
    this.color = _text,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label  ',
            style: const TextStyle(
              color: _muted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(color: color),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _PublishedBadge extends StatelessWidget {
  const _PublishedBadge({required this.isPublished});

  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    final color = isPublished ? _published : _muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPublished ? 'PUBLISHED' : 'UNPUBLISHED',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
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
