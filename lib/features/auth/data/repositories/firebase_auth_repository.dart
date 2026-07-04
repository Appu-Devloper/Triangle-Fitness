import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:triangle_fitness/core/services/firebase_initializer.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_dashboard.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_payment.dart';
import 'package:triangle_fitness/features/auth/domain/entities/member_session.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:triangle_fitness/features/auth/shared/member_identifier_formatter.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({required FirebaseInitializer initializer})
    : _initializer = initializer;

  final FirebaseInitializer _initializer;

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static String memberEmailFromPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return '$digits@trianglefitness.local';
  }

  static String measurementDisplay(Object? value, String unit) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return 'Not added';
    if (text.toLowerCase().contains(unit.toLowerCase())) return text;
    return '$text $unit';
  }

  @override
  Future<MemberSession> signInMember({
    required String phone,
    required String password,
  }) async {
    try {
      await _initializer.initialize();
      final credential = await _signInMemberWithReceiptFallback(
        phone,
        password,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        throw const AuthFailure('Unable to identify this member account.');
      }

      final credentialsDocument = await _firestore
          .collection('userCredentials')
          .doc(uid)
          .get();
      final credentials = credentialsDocument.data();
      if (!credentialsDocument.exists || credentials == null) {
        await _auth.signOut();
        throw const AuthFailure('Member login record not found');
      }
      if (credentials['isActive'] != true) {
        await _auth.signOut();
        throw const AuthFailure('Member account is inactive');
      }

      final memberId = credentials['memberId'];
      if (memberId is! String || memberId.trim().isEmpty) {
        await _auth.signOut();
        throw const AuthFailure('Member profile not found');
      }

      final memberDocument = await _firestore
          .collection('members')
          .doc(memberId)
          .get();
      final member = memberDocument.data();
      if (!memberDocument.exists || member == null) {
        await _auth.signOut();
        throw const AuthFailure('Member profile not found');
      }

      await credentialsDocument.reference.update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return MemberSession(
        memberId: memberId,
        mustChangePassword: credentials['mustChangePassword'] == true,
      );
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (error, stackTrace) {
      _logMemberLoginError(error, stackTrace);
      throw AuthFailure(_firebaseErrorMessage(error));
    } on FirebaseException catch (error, stackTrace) {
      await _safeSignOut();
      _logMemberLoginError(error, stackTrace);
      throw AuthFailure(_firebaseErrorMessage(error));
    } on Object catch (error, stackTrace) {
      await _safeSignOut();
      _logMemberLoginError(error, stackTrace);
      throw AuthFailure(error.toString());
    }
  }

  @override
  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    try {
      await _initializer.initialize();
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        await _safeSignOut();
        throw const AuthFailure('Admin access denied');
      }

      final adminDocument = await _firestore
          .collection('admins')
          .doc(uid)
          .get();
      final admin = adminDocument.data();
      if (!adminDocument.exists || admin?['isActive'] != true) {
        await _safeSignOut();
        throw const AuthFailure('Admin access denied');
      }
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (error, stackTrace) {
      _logFirebaseError('Admin login', error, stackTrace);
      throw AuthFailure(_firebaseErrorMessage(error));
    } on FirebaseException catch (error, stackTrace) {
      await _safeSignOut();
      _logFirebaseError('Admin verification', error, stackTrace);
      throw AuthFailure(_firebaseErrorMessage(error));
    } on Object catch (error, stackTrace) {
      await _safeSignOut();
      _logFirebaseError('Admin login', error, stackTrace);
      throw AuthFailure(error.toString());
    }
  }

  @override
  Future<void> changePassword(String newPassword) async {
    try {
      await _initializer.initialize();
    } on Object catch (error, stackTrace) {
      _logFirebaseError('Change password initialization', error, stackTrace);
      throw AuthFailure(error.toString());
    }
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthenticationRequiredFailure(
        'Your session has expired. Please log in again.',
      );
    }

    try {
      await user.updatePassword(newPassword);
      await _firestore.collection('userCredentials').doc(user.uid).update({
        'mustChangePassword': false,
        'passwordChanged': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (error, stackTrace) {
      _logFirebaseError('Change password', error, stackTrace);
      throw AuthFailure(_firebaseErrorMessage(error));
    } on FirebaseException catch (error, stackTrace) {
      _logFirebaseError('Change password Firestore update', error, stackTrace);
      throw AuthFailure(_firebaseErrorMessage(error));
    } on Object catch (error, stackTrace) {
      _logFirebaseError('Change password', error, stackTrace);
      throw AuthFailure(error.toString());
    }
  }

  @override
  Future<MemberDashboard> getCurrentMemberDashboard() async {
    try {
      await _initializer.initialize();
      final user = _auth.currentUser;
      if (user == null) {
        throw const AuthenticationRequiredFailure(
          'Your session has expired. Please log in again.',
        );
      }

      final credentialsDocument = await _firestore
          .collection('userCredentials')
          .doc(user.uid)
          .get();
      final credentials = credentialsDocument.data();
      if (!credentialsDocument.exists || credentials == null) {
        throw const AuthFailure('Member login record not found');
      }

      final memberId = credentials['memberId'];
      if (memberId is! String || memberId.trim().isEmpty) {
        throw const AuthFailure('Member profile not found');
      }

      final memberDocument = await _firestore
          .collection('members')
          .doc(memberId)
          .get();
      final member = memberDocument.data();
      if (!memberDocument.exists || member == null) {
        throw const AuthFailure('Member profile not found');
      }

      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('memberId', isEqualTo: memberId)
          .get();
      final payments =
          paymentsSnapshot.docs.map((document) {
            final payment = document.data();
            return MemberPayment(
              id: document.id,
              receiptNo: _displayValue(payment['receiptNo']),
              amount: _numberValue(
                payment['amount'] ??
                    payment['paymentAmount'] ??
                    payment['paidAmount'],
              ),
              paymentMode: _paymentModeValue(payment['paymentMode']),
              paymentStatus: _paymentStatusValue(payment['paymentStatus']),
              paymentDate: _dateValue(payment['paymentDate']),
              subscriptionStartDate: _dateValue(
                payment['subscriptionStartDate'],
              ),
              subscriptionEndDate: _dateValue(payment['subscriptionEndDate']),
            );
          }).toList()..sort((a, b) {
            final aDate =
                a.paymentDate ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                b.paymentDate ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

      final subscription = _mapValue(member['subscription']);
      return MemberDashboard(
        memberId: memberId,
        memberCode: _displayValue(
          member['memberCode'] ?? member['code'] ?? memberId,
        ),
        name: _displayValue(member['name']),
        phone: _displayValue(member['phone']),
        email: _displayValue(member['email']),
        address: _displayValue(member['address']),
        receiptNo: _displayValue(
          member['receiptNo'] ?? member['receiptNumber'],
        ),
        weight: measurementDisplay(
          member['weightKg'] ?? member['weight'],
          'kg',
        ),
        height: measurementDisplay(
          member['heightCm'] ?? member['height'],
          'cm',
        ),
        status: _displayValue(member['status']),
        planName: _displayValue(
          subscription['planName'] ?? subscription['name'],
        ),
        amount: _displayValue(subscription['amount']),
        paymentStatus: _paymentStatusValue(subscription['paymentStatus']),
        subscriptionStatus: _displayValue(
          subscription['subscriptionStatus'] ?? subscription['status'],
        ),
        startDate: _dateValue(subscription['startDate']),
        endDate: _dateValue(subscription['endDate']),
        payments: payments,
      );
    } on AuthFailure {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      _logFirebaseError('Load member dashboard', error, stackTrace);
      throw AuthFailure(_firebaseErrorMessage(error));
    } on Object catch (error, stackTrace) {
      _logFirebaseError('Load member dashboard', error, stackTrace);
      throw AuthFailure(error.toString());
    }
  }

  @override
  Future<AdminDashboard> getCurrentAdminDashboard({
    DateTime? periodStart,
  }) async {
    try {
      await _initializer.initialize();
      final user = _auth.currentUser;
      if (user == null) {
        throw const AuthenticationRequiredFailure(
          'Your session has expired. Please log in again.',
        );
      }

      final adminDocument = await _firestore
          .collection('admins')
          .doc(user.uid)
          .get();
      final admin = adminDocument.data();
      if (!adminDocument.exists || admin == null) {
        throw const AuthFailure('Admin profile not found');
      }
      if (admin['isActive'] != true) {
        throw const AuthFailure('Admin access denied');
      }

      final collectionPeriodStart = _collectionPeriodStart(
        periodStart ?? DateTime.now(),
      );
      final collectionPeriodEnd = DateTime(
        collectionPeriodStart.year,
        collectionPeriodStart.month + 1,
        10,
      );

      final results = await Future.wait([
        _firestore.collection('members').get(),
        _firestore
            .collection('payments')
            .where(
              'paymentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(collectionPeriodStart),
            )
            .where(
              'paymentDate',
              isLessThan: Timestamp.fromDate(collectionPeriodEnd),
            )
            .get(),
        _firestore.collection('transformations').get(),
      ]);
      final members = results[0];
      final payments = results[1];
      final transformations = results[2];
      final todayValue = DateTime.now();
      final today = DateTime(todayValue.year, todayValue.month, todayValue.day);

      var activeMembers = 0;
      var expiredMembers = 0;
      for (final document in members.docs) {
        final member = document.data();
        if (_upperValue(member['status']) == 'ACTIVE') {
          activeMembers += 1;
        }

        final subscription = _mapValue(member['subscription']);
        final subscriptionStatus = _upperValue(
          subscription['status'] ?? subscription['subscriptionStatus'],
        );
        final endDate = _dateValue(subscription['endDate']);
        final endDay = endDate == null
            ? null
            : DateTime(endDate.year, endDate.month, endDate.day);
        if (subscriptionStatus == 'EXPIRED' ||
            (endDay != null && endDay.isBefore(today))) {
          expiredMembers += 1;
        }
      }

      var totalPaymentAmount = 0.0;
      for (final document in payments.docs) {
        final payment = document.data();
        totalPaymentAmount += _numberValue(
          payment['amount'] ??
              payment['paymentAmount'] ??
              payment['paidAmount'],
        );
      }

      return AdminDashboard(
        adminName: _displayValue(
          admin['name'] ??
              admin['displayName'] ??
              user.displayName ??
              user.email,
        ),
        totalMembers: members.docs.length,
        activeMembers: activeMembers,
        expiredMembers: expiredMembers,
        totalPayments: payments.docs.length,
        totalPaymentAmount: totalPaymentAmount,
        collectionPeriodStart: collectionPeriodStart,
        collectionPeriodEnd: collectionPeriodEnd,
        totalTransformations: transformations.docs.length,
      );
    } on AuthFailure {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      _logFirebaseError('Load admin dashboard', error, stackTrace);
      throw AuthFailure(_firebaseErrorMessage(error));
    } on Object catch (error, stackTrace) {
      _logFirebaseError('Load admin dashboard', error, stackTrace);
      throw AuthFailure(error.toString());
    }
  }

  @override
  Future<void> signOut() async {
    await _initializer.initialize();
    await _auth.signOut();
  }

  Map<String, dynamic> _mapValue(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const {};
  }

  String _displayValue(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? 'Not available' : text;
  }

  String _paymentModeValue(Object? value) {
    final text = value?.toString().trim().toUpperCase() ?? '';
    return text.isEmpty ? 'CASH' : text;
  }

  String _paymentStatusValue(Object? value) {
    final text = value?.toString().trim().toUpperCase() ?? '';
    return text.isEmpty ? 'PAID' : text;
  }

  String _upperValue(Object? value) =>
      value?.toString().trim().toUpperCase() ?? '';

  double _numberValue(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0;
    }
    return 0;
  }

  DateTime? _dateValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  DateTime _collectionPeriodStart(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);
    if (day.day >= 10) return DateTime(day.year, day.month, 10);
    return DateTime(day.year, day.month - 1, 10);
  }

  Future<void> _safeSignOut() async {
    try {
      await _auth.signOut();
    } on Object {
      // Preserve the original authentication error.
    }
  }

  Future<UserCredential> _signInMemberWithReceiptFallback(
    String phone,
    String password,
  ) async {
    final email = memberEmailFromPhone(phone);
    final candidates = receiptPasswordCandidates(password);
    if (candidates.isEmpty) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }

    for (var index = 0; index < candidates.length; index += 1) {
      final candidate = candidates[index];
      try {
        return await _auth.signInWithEmailAndPassword(
          email: email,
          password: candidate,
        );
      } on FirebaseAuthException catch (error) {
        final retryable =
            error.code == 'invalid-credential' ||
            error.code == 'wrong-password' ||
            error.code == 'invalid-login-credentials';
        final isLast = index == candidates.length - 1;
        if (!retryable || isLast) rethrow;
      }
    }

    throw FirebaseAuthException(code: 'invalid-credential');
  }

  String _firebaseErrorMessage(FirebaseException error) {
    final message = error.message?.trim();
    return message == null || message.isEmpty
        ? error.code
        : '${error.code}: $message';
  }

  void _logMemberLoginError(Object error, StackTrace stackTrace) {
    debugPrint('Member login Firebase error: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  void _logFirebaseError(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('$operation Firebase error: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
