import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triangle_fitness/core/theme/app_colors.dart';
import 'package:triangle_fitness/features/auth/presentation/widgets/admin_workspace.dart';

const _paymentsBackground = AdminWorkspaceColors.background;
const _paymentsCard = AdminWorkspaceColors.surface;
const _paymentsText = AdminWorkspaceColors.text;
const _paymentsMuted = AdminWorkspaceColors.muted;
const _paymentsLine = AdminWorkspaceColors.border;
const _paidColor = AdminWorkspaceColors.success;
const _pendingColor = AdminWorkspaceColors.warning;

enum PaymentStatusFilter { all, paid, pending }

enum PaymentModeFilter { all, cash, upi, card, bank }

enum PaymentDateFilter { today, thisMonth, all }

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.receiptNo,
    required this.memberCode,
    required this.memberName,
    required this.phone,
    required this.amount,
    required this.paymentMode,
    required this.paymentStatus,
    required this.paymentDate,
    required this.subscriptionStartDate,
    required this.subscriptionEndDate,
  });

  factory PaymentRecord.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final paymentMode = _normalizedValue(data['paymentMode'], fallback: 'CASH');
    final paymentStatus = _normalizedValue(
      data['paymentStatus'],
      fallback: 'PAID',
    );
    return PaymentRecord(
      id: document.id,
      receiptNo: _text(data['receiptNo']),
      memberCode: _text(data['memberCode']),
      memberName: _text(data['memberName']),
      phone: _text(data['phone']),
      amount: _amount(data['amount']),
      paymentMode: paymentMode,
      paymentStatus: paymentStatus,
      paymentDate: _date(data['paymentDate']),
      subscriptionStartDate: _date(data['subscriptionStartDate']),
      subscriptionEndDate: _date(data['subscriptionEndDate']),
    );
  }

  final String id;
  final String receiptNo;
  final String memberCode;
  final String memberName;
  final String phone;
  final double amount;
  final String paymentMode;
  final String paymentStatus;
  final DateTime? paymentDate;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;

  static String _text(Object? value) => value?.toString().trim() ?? '';

  static String _normalizedValue(Object? value, {required String fallback}) {
    final text = value?.toString().trim().toUpperCase() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static double _amount(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class PaymentsListPage extends StatefulWidget {
  const PaymentsListPage({super.key, this.paymentsStream});

  final Stream<List<PaymentRecord>>? paymentsStream;

  @override
  State<PaymentsListPage> createState() => _PaymentsListPageState();
}

class _PaymentsListPageState extends State<PaymentsListPage> {
  late Stream<List<PaymentRecord>> _paymentsStream;
  String _searchQuery = '';
  PaymentStatusFilter _statusFilter = PaymentStatusFilter.all;
  PaymentModeFilter _modeFilter = PaymentModeFilter.all;
  PaymentDateFilter _dateFilter = PaymentDateFilter.all;

  @override
  void initState() {
    super.initState();
    _paymentsStream = widget.paymentsStream ?? _firestorePayments();
  }

  Stream<List<PaymentRecord>> _firestorePayments() async* {
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError('You must be signed in to view payments.');
    }

    yield* FirebaseFirestore.instance
        .collection('payments')
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(PaymentRecord.fromFirestore)
              .toList(growable: false),
        );
  }

  void _retry() {
    setState(() {
      _paymentsStream = widget.paymentsStream ?? _firestorePayments();
    });
  }

  List<PaymentRecord> _visiblePayments(List<PaymentRecord> payments) {
    final query = _searchQuery.trim().toLowerCase();
    final now = DateTime.now();

    return payments
        .where((payment) {
          final matchesSearch =
              query.isEmpty ||
              payment.receiptNo.toLowerCase().contains(query) ||
              payment.memberCode.toLowerCase().contains(query) ||
              payment.memberName.toLowerCase().contains(query) ||
              payment.phone.toLowerCase().contains(query);
          final matchesStatus =
              _statusFilter == PaymentStatusFilter.all ||
              payment.paymentStatus == _statusFilter.name.toUpperCase();
          final matchesMode =
              _modeFilter == PaymentModeFilter.all ||
              payment.paymentMode == _modeFilter.name.toUpperCase();
          final matchesDate = _matchesDate(payment.paymentDate, now);
          return matchesSearch && matchesStatus && matchesMode && matchesDate;
        })
        .toList(growable: false);
  }

  bool _matchesDate(DateTime? date, DateTime now) {
    if (_dateFilter == PaymentDateFilter.all) return true;
    if (date == null) return false;
    if (_dateFilter == PaymentDateFilter.today) {
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }
    return date.year == now.year && date.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    return AdminWorkspaceScaffold(
      section: AdminWorkspaceSection.payments,
      title: 'Payments',
      subtitle: 'Track collections, pending balances and payment activity',
      body: StreamBuilder<List<PaymentRecord>>(
        stream: _paymentsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _PaymentsError(error: snapshot.error, onRetry: _retry);
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.red),
            );
          }

          final payments = _visiblePayments(snapshot.data!);
          return _PaymentsContent(
            payments: payments,
            statusFilter: _statusFilter,
            modeFilter: _modeFilter,
            dateFilter: _dateFilter,
            onSearchChanged: (value) {
              setState(() => _searchQuery = value);
            },
            onStatusChanged: (value) {
              setState(() => _statusFilter = value);
            },
            onModeChanged: (value) {
              setState(() => _modeFilter = value);
            },
            onDateChanged: (value) {
              setState(() => _dateFilter = value);
            },
          );
        },
      ),
    );
  }
}

class _PaymentsContent extends StatelessWidget {
  const _PaymentsContent({
    required this.payments,
    required this.statusFilter,
    required this.modeFilter,
    required this.dateFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onModeChanged,
    required this.onDateChanged,
  });

  final List<PaymentRecord> payments;
  final PaymentStatusFilter statusFilter;
  final PaymentModeFilter modeFilter;
  final PaymentDateFilter dateFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<PaymentStatusFilter> onStatusChanged;
  final ValueChanged<PaymentModeFilter> onModeChanged;
  final ValueChanged<PaymentDateFilter> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final total = payments.fold<double>(
      0,
      (currentTotal, item) => currentTotal + item.amount,
    );
    final paid = payments
        .where((item) => item.paymentStatus == 'PAID')
        .fold<double>(0, (currentTotal, item) => currentTotal + item.amount);
    final pending = payments
        .where((item) => item.paymentStatus == 'PENDING')
        .fold<double>(0, (currentTotal, item) => currentTotal + item.amount);

    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryGrid(
                  total: total,
                  paid: paid,
                  pending: pending,
                  count: payments.length,
                ),
                const SizedBox(height: 18),
                _PaymentsToolbar(
                  statusFilter: statusFilter,
                  modeFilter: modeFilter,
                  dateFilter: dateFilter,
                  onSearchChanged: onSearchChanged,
                  onStatusChanged: onStatusChanged,
                  onModeChanged: onModeChanged,
                  onDateChanged: onDateChanged,
                ),
                const SizedBox(height: 18),
                if (payments.isEmpty)
                  const _EmptyPayments()
                else
                  _PaymentsTable(
                    key: ValueKey(
                      'payments-table-${payments.map((item) => item.id).join('-')}',
                    ),
                    payments: payments,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.total,
    required this.paid,
    required this.pending,
    required this.count,
  });

  final double total;
  final double paid;
  final double pending;
  final int count;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem(
        label: 'Total Collection',
        value: _formatCurrency(total),
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF5E8BFF),
      ),
      _SummaryItem(
        label: 'Paid Collection',
        value: _formatCurrency(paid),
        icon: Icons.check_circle_rounded,
        color: _paidColor,
      ),
      _SummaryItem(
        label: 'Pending Amount',
        value: _formatCurrency(pending),
        icon: Icons.schedule_rounded,
        color: _pendingColor,
      ),
      _SummaryItem(
        label: 'Total Payments Count',
        value: count.toString(),
        icon: Icons.receipt_long_rounded,
        color: AppColors.red,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 940
            ? 4
            : constraints.maxWidth >= 560
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
                child: _SummaryCard(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('summary-${item.label}'),
      height: 112,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _paymentsCard,
        border: Border.all(color: _paymentsLine),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _paymentsText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _paymentsMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentsToolbar extends StatelessWidget {
  const _PaymentsToolbar({
    required this.statusFilter,
    required this.modeFilter,
    required this.dateFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onModeChanged,
    required this.onDateChanged,
  });

  final PaymentStatusFilter statusFilter;
  final PaymentModeFilter modeFilter;
  final PaymentDateFilter dateFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<PaymentStatusFilter> onStatusChanged;
  final ValueChanged<PaymentModeFilter> onModeChanged;
  final ValueChanged<PaymentDateFilter> onDateChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _paymentsCard,
        border: Border.all(color: _paymentsLine),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('payment-search'),
            onChanged: onSearchChanged,
            style: const TextStyle(color: _paymentsText, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by receipt, member code, name or phone',
              hintStyle: const TextStyle(color: _paymentsMuted, fontSize: 13),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: _paymentsMuted,
              ),
              filled: true,
              fillColor: _paymentsBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              border: _searchBorder(_paymentsLine),
              enabledBorder: _searchBorder(_paymentsLine),
              focusedBorder: _searchBorder(AppColors.red, width: 1.5),
            ),
          ),
          const SizedBox(height: 15),
          _FilterRow<PaymentStatusFilter>(
            label: 'Payment Status',
            values: PaymentStatusFilter.values,
            selected: statusFilter,
            itemLabel: (value) => value.name.toUpperCase(),
            onSelected: onStatusChanged,
          ),
          const SizedBox(height: 12),
          _FilterRow<PaymentModeFilter>(
            label: 'Payment Mode',
            values: PaymentModeFilter.values,
            selected: modeFilter,
            itemLabel: (value) => value.name.toUpperCase(),
            onSelected: onModeChanged,
          ),
          const SizedBox(height: 12),
          _FilterRow<PaymentDateFilter>(
            label: 'Payment Date',
            values: PaymentDateFilter.values,
            selected: dateFilter,
            itemLabel: _dateFilterLabel,
            onSelected: onDateChanged,
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _searchBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _FilterRow<T> extends StatelessWidget {
  const _FilterRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.itemLabel,
    required this.onSelected,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T value) itemLabel;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: _paymentsMuted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 7),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final value in values) ...[
                ChoiceChip(
                  key: ValueKey('$label-${itemLabel(value)}'),
                  label: Text(itemLabel(value)),
                  selected: selected == value,
                  onSelected: (_) => onSelected(value),
                  selectedColor: AppColors.red,
                  backgroundColor: _paymentsBackground,
                  side: BorderSide(
                    color: selected == value ? AppColors.red : _paymentsLine,
                  ),
                  labelStyle: TextStyle(
                    color: selected == value ? Colors.white : _paymentsText,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  showCheckmark: false,
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentsTable extends StatefulWidget {
  const _PaymentsTable({super.key, required this.payments});

  final List<PaymentRecord> payments;

  @override
  State<_PaymentsTable> createState() => _PaymentsTableState();
}

class _PaymentsTableState extends State<_PaymentsTable> {
  static const _availableRowsPerPage = [5, 10, 20];

  int _rowsPerPage = 10;
  int? _sortColumnIndex = 6;
  bool _sortAscending = false;
  late List<PaymentRecord> _sortedPayments;

  @override
  void initState() {
    super.initState();
    _sortedPayments = List.of(widget.payments);
    _applySort();
  }

  @override
  void didUpdateWidget(covariant _PaymentsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.payments != widget.payments) {
      _sortedPayments = List.of(widget.payments);
      _applySort();
    }
  }

  void _applySort() {
    if (_sortColumnIndex == 3) {
      _sortedPayments.sort((a, b) {
        final result = a.amount.compareTo(b.amount);
        return _sortAscending ? result : -result;
      });
      return;
    }
    if (_sortColumnIndex == 6) {
      _sortedPayments.sort((a, b) {
        final aDate = a.paymentDate?.millisecondsSinceEpoch ?? -1;
        final bDate = b.paymentDate?.millisecondsSinceEpoch ?? -1;
        final result = aDate.compareTo(bDate);
        return _sortAscending ? result : -result;
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
      color: _paymentsCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: _paymentsLine),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: DataTableTheme(
        data: const DataTableThemeData(
          headingTextStyle: TextStyle(
            color: _paymentsMuted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
          dataTextStyle: TextStyle(
            color: _paymentsText,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: PaginatedDataTable(
          key: const Key('admin-payments-table'),
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
                  Icons.receipt_long_outlined,
                  color: AppColors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  'Payment records',
                  style: TextStyle(
                    color: _paymentsText,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${widget.payments.length} records',
                style: const TextStyle(
                  color: _paymentsMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          headingRowColor: const WidgetStatePropertyAll(_paymentsBackground),
          horizontalMargin: 18,
          columnSpacing: 28,
          dataRowMinHeight: 68,
          dataRowMaxHeight: 76,
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
          source: _PaymentsDataSource(_sortedPayments),
          columns: [
            const DataColumn(label: Text('RECEIPT NO')),
            const DataColumn(label: Text('MEMBER')),
            const DataColumn(label: Text('PHONE')),
            DataColumn(
              numeric: true,
              label: const Text('AMOUNT'),
              onSort: (columnIndex, _) => _sortBy(columnIndex),
            ),
            const DataColumn(label: Text('MODE')),
            const DataColumn(label: Text('STATUS')),
            DataColumn(
              label: const Text('PAYMENT DATE'),
              onSort: (columnIndex, _) => _sortBy(columnIndex),
            ),
            const DataColumn(label: Text('SUBSCRIPTION PERIOD')),
          ],
        ),
      ),
    );
  }
}

class _PaymentsDataSource extends DataTableSource {
  _PaymentsDataSource(this.payments);

  final List<PaymentRecord> payments;

  @override
  DataRow? getRow(int index) {
    if (index >= payments.length) return null;
    final payment = payments[index];
    return DataRow(
      key: ValueKey('payment-${payment.id}'),
      cells: [
        DataCell(
          Text(
            _display(payment.receiptNo),
            style: const TextStyle(
              color: AppColors.red,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _display(payment.memberName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _display(payment.memberCode),
                  style: const TextStyle(color: _paymentsMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
        DataCell(Text(_display(payment.phone))),
        DataCell(
          Text(
            _formatCurrency(payment.amount),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        DataCell(Text(_display(payment.paymentMode))),
        DataCell(_PaymentStatusPill(status: payment.paymentStatus)),
        DataCell(
          SizedBox(
            width: 122,
            child: Text(
              _formatDate(payment.paymentDate, includeTime: true),
              maxLines: 2,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 174,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TableDateLine(
                  label: 'START',
                  value: _formatDate(payment.subscriptionStartDate),
                ),
                const SizedBox(height: 5),
                _TableDateLine(
                  label: 'END',
                  value: _formatDate(payment.subscriptionEndDate),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => payments.length;

  @override
  int get selectedRowCount => 0;
}

class _PaymentStatusPill extends StatelessWidget {
  const _PaymentStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'PAID' ? _paidColor : _pendingColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _display(status),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TableDateLine extends StatelessWidget {
  const _TableDateLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label  ',
            style: const TextStyle(
              color: _paymentsMuted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _EmptyPayments extends StatelessWidget {
  const _EmptyPayments();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 54),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, color: _paymentsMuted, size: 50),
          SizedBox(height: 13),
          Text(
            'No payment records found',
            style: TextStyle(
              color: _paymentsText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentsError extends StatelessWidget {
  const _PaymentsError({required this.error, required this.onRetry});

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
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.red,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load payments: ${_errorMessage(error)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _paymentsText),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('TRY AGAIN'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

String _dateFilterLabel(PaymentDateFilter filter) {
  return switch (filter) {
    PaymentDateFilter.today => 'Today',
    PaymentDateFilter.thisMonth => 'This Month',
    PaymentDateFilter.all => 'All',
  };
}

String _formatCurrency(double amount) {
  final value = amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
  return 'Rs. $value';
}

String _formatDate(DateTime? date, {bool includeTime = false}) {
  if (date == null) return 'Not available';
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
  final day = date.day.toString().padLeft(2, '0');
  final formattedDate = '$day ${months[date.month - 1]} ${date.year}';
  if (!includeTime) return formattedDate;

  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '$formattedDate, $hour:$minute $period';
}

String _display(String value) => value.isEmpty ? 'Not available' : value;

String _errorMessage(Object? error) {
  if (error == null) return 'Unknown Firestore error.';
  return error.toString().replaceFirst('Bad state: ', '');
}
