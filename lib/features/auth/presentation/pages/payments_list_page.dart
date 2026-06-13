import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triangle_fitness/core/theme/app_colors.dart';

const _paymentsBackground = AppColors.ink;
const _paymentsCard = AppColors.surface;
const _paymentsText = AppColors.paper;
const _paymentsMuted = AppColors.muted;
const _paymentsLine = Color(0xFF272A2D);
const _paidColor = Color(0xFF55CA82);
const _pendingColor = Color(0xFFFFC66D);

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
    return PaymentRecord(
      id: document.id,
      receiptNo: _text(data['receiptNo']),
      memberCode: _text(data['memberCode']),
      memberName: _text(data['memberName']),
      phone: _text(data['phone']),
      amount: _amount(data['amount']),
      paymentMode: _text(data['paymentMode']).toUpperCase(),
      paymentStatus: _text(data['paymentStatus']).toUpperCase(),
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
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _paymentsBackground,
        cardColor: _paymentsCard,
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _paymentsCard,
          foregroundColor: _paymentsText,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Payments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
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
                  _PaymentsList(payments: payments),
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

class _PaymentsList extends StatelessWidget {
  const _PaymentsList({required this.payments});

  final List<PaymentRecord> payments;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _PaymentCard(payment: payments[index]),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final PaymentRecord payment;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('payment-${payment.id}'),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _paymentsCard,
        border: Border.all(color: _paymentsLine),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.red,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RECEIPT NO',
                      style: TextStyle(
                        color: _paymentsMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _display(payment.receiptNo),
                      style: const TextStyle(
                        color: _paymentsText,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatCurrency(payment.amount),
                style: const TextStyle(
                  color: _paymentsText,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, color: _paymentsLine),
          const SizedBox(height: 15),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 960
                  ? 3
                  : constraints.maxWidth >= 560
                  ? 2
                  : 1;
              const gap = 14.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              final details = [
                _PaymentDetail('Member Code', payment.memberCode),
                _PaymentDetail('Member Name', payment.memberName),
                _PaymentDetail('Phone', payment.phone),
                _PaymentDetail('Amount', _formatCurrency(payment.amount)),
                _PaymentDetail('Payment Mode', payment.paymentMode),
                _PaymentDetail('Payment Status', payment.paymentStatus),
                _PaymentDetail(
                  'Payment Date',
                  _formatDate(payment.paymentDate, includeTime: true),
                ),
                _PaymentDetail(
                  'Subscription Start Date',
                  _formatDate(payment.subscriptionStartDate),
                ),
                _PaymentDetail(
                  'Subscription End Date',
                  _formatDate(payment.subscriptionEndDate),
                ),
              ];
              return Wrap(
                spacing: gap,
                runSpacing: 14,
                children: [
                  for (final detail in details)
                    SizedBox(
                      width: width,
                      child: detail.label == 'Payment Status'
                          ? _StatusDetail(payment.paymentStatus)
                          : _DetailValue(detail: detail),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.detail});

  final _PaymentDetail detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.label.toUpperCase(),
          style: const TextStyle(
            color: _paymentsMuted,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _display(detail.value),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _paymentsText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusDetail extends StatelessWidget {
  const _StatusDetail(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'PAID' ? _paidColor : _pendingColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PAYMENT STATUS',
          style: TextStyle(
            color: _paymentsMuted,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
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
        ),
      ],
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

class _PaymentDetail {
  const _PaymentDetail(this.label, this.value);

  final String label;
  final String value;
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
