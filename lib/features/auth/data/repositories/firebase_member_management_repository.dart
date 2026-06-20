import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:triangle_fitness/core/services/firebase_initializer.dart';
import 'package:triangle_fitness/features/auth/domain/entities/admin_member.dart';
import 'package:triangle_fitness/features/auth/domain/entities/create_member_request.dart';
import 'package:triangle_fitness/features/auth/domain/entities/subscription_plan.dart';
import 'package:triangle_fitness/features/auth/domain/repositories/member_management_repository.dart';
import 'package:triangle_fitness/features/auth/shared/member_identifier_formatter.dart';
import 'package:triangle_fitness/firebase_options.dart';

class FirebaseMemberManagementRepository implements MemberManagementRepository {
  FirebaseMemberManagementRepository({required FirebaseInitializer initializer})
    : _initializer = initializer;

  final FirebaseInitializer _initializer;

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  Stream<List<AdminMember>> watchMembers() async* {
    try {
      await _initializer.initialize();
      yield* _firestore
          .collection('members')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((document) => _memberFromDocument(document))
                .toList(),
          );
    } on FirebaseException catch (error, stackTrace) {
      _logError('Watch members', error, stackTrace);
      throw MemberManagementFailure(_firebaseErrorMessage(error));
    } on Object catch (error, stackTrace) {
      _logError('Watch members', error, stackTrace);
      throw MemberManagementFailure(error.toString());
    }
  }

  @override
  Future<AdminMember> getMember(String memberId) async {
    try {
      await _initializer.initialize();
      final document = await _firestore
          .collection('members')
          .doc(memberId)
          .get();
      if (!document.exists || document.data() == null) {
        throw const MemberManagementFailure('Member profile not found');
      }
      return _memberFromDocument(document);
    } on MemberManagementFailure {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      _logError('Load member details', error, stackTrace);
      throw MemberManagementFailure(_firebaseErrorMessage(error));
    } on Object catch (error, stackTrace) {
      _logError('Load member details', error, stackTrace);
      throw MemberManagementFailure(error.toString());
    }
  }

  @override
  Future<List<SubscriptionPlan>> getActiveSubscriptionPlans() async {
    try {
      await _initializer.initialize();
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('isActive', isEqualTo: true)
          .get();
      final plans = snapshot.docs.map((document) {
        final data = document.data();
        return SubscriptionPlan(
          id: document.id,
          name: _text(
            data['planName'] ?? data['name'] ?? data['title'],
            fallback: document.id,
          ),
          durationDays: _integer(
            data['durationDays'] ??
                data['durationInDays'] ??
                data['duration'] ??
                data['days'],
          ),
          price: _number(data['price'] ?? data['planPrice'] ?? data['amount']),
        );
      }).toList()..sort((a, b) => a.name.compareTo(b.name));
      return plans;
    } on FirebaseException catch (error, stackTrace) {
      _logError('Load subscription plans', error, stackTrace);
      throw MemberManagementFailure(_firebaseErrorMessage(error));
    } on Object catch (error, stackTrace) {
      _logError('Load subscription plans', error, stackTrace);
      throw MemberManagementFailure(error.toString());
    }
  }

  @override
  Future<void> createMember(CreateMemberRequest request) async {
    FirebaseAuth? secondaryAuth;
    var memberAccountCreated = false;
    var loginEmail = '';
    final receiptNo = normalizeReceiptNo(request.receiptNo);
    final authPassword = memberAuthPasswordFromReceipt(receiptNo);
    try {
      await _initializer.initialize();
      final admin = _auth.currentUser;
      if (admin == null) {
        throw const MemberManagementFailure(
          'Your admin session has expired. Please login again.',
        );
      }
      final adminUid = admin.uid;
      final phone = request.phone.replaceAll(RegExp(r'\D'), '');
      final memberCode = normalizeMemberCode(request.memberCode);
      loginEmail = '$phone@trianglefitness.local';

      final secondaryApp = await _secondaryApp();
      secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final memberCredential = await secondaryAuth
          .createUserWithEmailAndPassword(
            email: loginEmail,
            password: authPassword,
          );
      memberAccountCreated = true;
      final memberUid = memberCredential.user?.uid;
      if (memberUid == null) {
        throw const MemberManagementFailure(
          'Firebase did not return the new member UID.',
        );
      }
      await secondaryAuth.signOut();

      final memberReference = _firestore.collection('members').doc();
      final credentialsReference = _firestore
          .collection('userCredentials')
          .doc(memberUid);
      final paymentReference = _firestore.collection('payments').doc();
      final batch = _firestore.batch();
      final serverTimestamp = FieldValue.serverTimestamp();
      final startTimestamp = Timestamp.fromDate(request.startDate);
      final endTimestamp = Timestamp.fromDate(request.endDate);
      final paymentMode = _paymentMode(request.paymentMode);
      final paymentStatus = _paymentStatus(request.paymentStatus);

      batch.set(memberReference, {
        'uid': memberUid,
        'memberCode': memberCode,
        'name': request.name,
        'phone': phone,
        'email': request.email,
        'address': request.address,
        'receiptNo': receiptNo,
        'weightKg': request.weightKg,
        'heightCm': request.heightCm,
        'subscription': {
          'planId': request.plan.id,
          'planName': request.plan.name,
          'startDate': startTimestamp,
          'endDate': endTimestamp,
          'status': 'ACTIVE',
          'amount': request.amount,
          'paymentStatus': paymentStatus,
        },
        'status': request.memberStatus,
        'createdBy': adminUid,
        'createdAt': serverTimestamp,
        'updatedAt': serverTimestamp,
      });
      batch.set(credentialsReference, {
        'uid': memberUid,
        'memberId': memberReference.id,
        'memberCode': memberCode,
        'phone': phone,
        'loginEmail': loginEmail,
        'initialLoginType': 'RECEIPT_NO',
        'mustChangePassword': true,
        'passwordChanged': false,
        'role': 'MEMBER',
        'isActive': true,
        'lastLoginAt': null,
        'createdAt': serverTimestamp,
        'updatedAt': serverTimestamp,
      });
      batch.set(paymentReference, {
        'memberId': memberReference.id,
        'memberCode': memberCode,
        'memberName': request.name,
        'phone': phone,
        'receiptNo': receiptNo,
        'amount': request.amount,
        'paymentMode': paymentMode,
        'paymentStatus': paymentStatus,
        'paymentDate': serverTimestamp,
        'subscriptionStartDate': startTimestamp,
        'subscriptionEndDate': endTimestamp,
        'collectedBy': adminUid,
        'createdAt': serverTimestamp,
        'updatedAt': serverTimestamp,
      });
      await batch.commit();
    } on MemberManagementFailure {
      await _cleanUpAfterFailure(
        secondaryAuth: secondaryAuth,
        memberAccountCreated: memberAccountCreated,
        loginEmail: loginEmail,
        password: authPassword,
      );
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      _logError('Create member', error, stackTrace);
      await _cleanUpAfterFailure(
        secondaryAuth: secondaryAuth,
        memberAccountCreated: memberAccountCreated,
        loginEmail: loginEmail,
        password: authPassword,
      );
      throw MemberManagementFailure(_firebaseErrorMessage(error));
    } on Object catch (error, stackTrace) {
      _logError('Create member', error, stackTrace);
      await _cleanUpAfterFailure(
        secondaryAuth: secondaryAuth,
        memberAccountCreated: memberAccountCreated,
        loginEmail: loginEmail,
        password: authPassword,
      );
      throw MemberManagementFailure(error.toString());
    }
  }

  Future<FirebaseApp> _secondaryApp() async {
    try {
      return Firebase.app('SecondaryApp');
    } on Object {
      return Firebase.initializeApp(
        name: 'SecondaryApp',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  AdminMember _memberFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final subscription = _map(data['subscription']);
    return AdminMember(
      id: document.id,
      memberCode: _text(
        data['memberCode'] ?? data['code'],
        fallback: document.id,
      ),
      name: _text(data['name'], fallback: 'Unnamed member'),
      phone: _text(data['phone'], fallback: 'Not available'),
      email: _text(data['email'], fallback: ''),
      address: _text(data['address'], fallback: ''),
      receiptNo: _text(
        data['receiptNo'] ?? data['receiptNumber'],
        fallback: '',
      ),
      weightKg: _nullableNumber(data['weightKg'] ?? data['weight']),
      heightCm: _nullableNumber(data['heightCm'] ?? data['height']),
      planName: _text(
        subscription['planName'] ?? subscription['name'],
        fallback: 'No plan',
      ),
      subscriptionStartDate: _date(subscription['startDate']),
      subscriptionEndDate: _date(subscription['endDate']),
      subscriptionAmount: _nullableNumber(subscription['amount']),
      paymentStatus: _text(
        subscription['paymentStatus'],
        fallback: 'PAID',
      ),
      status: _text(data['status'], fallback: 'INACTIVE').toUpperCase(),
    );
  }

  Future<void> _cleanUpAfterFailure({
    required FirebaseAuth? secondaryAuth,
    required bool memberAccountCreated,
    required String loginEmail,
    required String password,
  }) async {
    if (!memberAccountCreated || secondaryAuth == null) return;
    try {
      final memberUser =
          secondaryAuth.currentUser ??
          (await secondaryAuth.signInWithEmailAndPassword(
            email: loginEmail,
            password: password,
          )).user;
      await memberUser?.delete();
    } on Object {
      // Preserve the original creation error if account cleanup fails.
    } finally {
      try {
        await secondaryAuth.signOut();
      } on Object {
        // The primary admin Auth instance is unaffected.
      }
    }
  }

  String _text(Object? value, {required String fallback}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(
          value?.toString().replaceAll(RegExp(r'[^0-9.-]'), '') ?? '',
        ) ??
        0;
  }

  double? _nullableNumber(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(
      value.toString().replaceAll(RegExp(r'[^0-9.-]'), ''),
    );
  }

  DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const {};
  }

  String _firebaseErrorMessage(FirebaseException error) {
    final message = error.message?.trim();
    return message == null || message.isEmpty
        ? error.code
        : '${error.code}: $message';
  }

  void _logError(String operation, Object error, StackTrace stackTrace) {
    debugPrint('$operation Firebase error: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  String _paymentMode(Object? value) {
    final text = value?.toString().trim().toUpperCase() ?? '';
    return text.isEmpty ? 'CASH' : text;
  }

  String _paymentStatus(Object? value) {
    final text = value?.toString().trim().toUpperCase() ?? '';
    return text.isEmpty ? 'PAID' : text;
  }
}
