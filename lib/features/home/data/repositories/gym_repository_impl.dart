import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:triangle_fitness/core/services/firebase_initializer.dart';
import 'package:triangle_fitness/features/home/domain/entities/equipment.dart';
import 'package:triangle_fitness/features/home/domain/entities/gym_content.dart';
import 'package:triangle_fitness/features/home/domain/entities/gym_profile.dart';
import 'package:triangle_fitness/features/home/domain/entities/program.dart';
import 'package:triangle_fitness/features/home/domain/entities/public_subscription_plan.dart';
import 'package:triangle_fitness/features/home/domain/entities/public_transformation.dart';
import 'package:triangle_fitness/features/home/domain/repositories/gym_repository.dart';

class GymRepositoryImpl implements GymRepository {
  GymRepositoryImpl({required FirebaseInitializer initializer})
    : _initializer = initializer;

  final FirebaseInitializer _initializer;

  @override
  Future<GymContent> getContent() async {
    try {
      await _initializer.initialize();
      final firestore = FirebaseFirestore.instance;
      final profileDocument = await firestore
          .collection('settings')
          .doc('gymProfile')
          .get();
      final plansSnapshot = await firestore
          .collection('subscriptions')
          .where('isActive', isEqualTo: true)
          .get();
      final transformationsSnapshot = await firestore
          .collection('transformations')
          .where('isPublished', isEqualTo: true)
          .get();

      final profileData = profileDocument.data() ?? const <String, dynamic>{};
      final plans = plansSnapshot.docs.map((document) {
        final data = document.data();
        return PublicSubscriptionPlan(
          id: document.id,
          name: _text(data['name'] ?? data['planName']),
          durationDays: _integer(data['durationDays']),
          price: _number(data['price']),
        );
      }).toList()..sort((a, b) => a.durationDays.compareTo(b.durationDays));
      final transformations = transformationsSnapshot.docs.map((document) {
        final data = document.data();
        return PublicTransformation(
          id: document.id,
          name: _text(data['name']),
          title: _text(data['title']),
          description: _text(data['description']),
          weightBeforeKg: _nullableNumber(data['weightBeforeKg']),
          weightAfterKg: _nullableNumber(data['weightAfterKg']),
          durationText: _text(data['durationText']),
          displayOrder: _integer(data['displayOrder']),
        );
      }).toList()..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      return GymContent(
        programs: _baseContent.programs,
        equipment: _baseContent.equipment,
        profile: GymProfile(
          gymName: _text(profileData['gymName']),
          ownerName: _text(profileData['ownerName']),
          phone: _text(profileData['phone']),
          email: _text(profileData['email']),
          address: _text(profileData['address']),
          openingTime: _text(profileData['openingTime']),
          closingTime: _text(profileData['closingTime']),
          instagramUrl: _text(profileData['instagramUrl']),
          facebookUrl: _text(profileData['facebookUrl']),
          whatsappNumber: _text(profileData['whatsappNumber']),
        ),
        subscriptionPlans: plans,
        transformations: transformations,
      );
    } on Object catch (error, stackTrace) {
      debugPrint('Load public Firestore content failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return _baseContent;
    }
  }
}

String _text(Object? value) => value?.toString().trim() ?? '';

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _number(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _nullableNumber(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

const _baseContent = GymContent(
  programs: [
    Program(
      name: 'Weight training',
      type: ProgramType.weightTraining,
      category: 'STRENGTH',
      description:
          'Build power, muscle and confidence with progressive resistance training.',
    ),
    Program(
      name: 'CrossFit',
      type: ProgramType.crossFit,
      category: 'CONDITIONING',
      description:
          'Fast-paced functional workouts designed to challenge your whole body.',
    ),
    Program(
      name: 'Personal training',
      type: ProgramType.personalTraining,
      category: 'COACHING',
      description:
          'One-to-one guidance and a focused plan built around your goals.',
    ),
    Program(
      name: 'Aerobics',
      type: ProgramType.aerobics,
      category: 'CARDIO',
      description:
          'High-energy movement that improves stamina, rhythm and coordination.',
    ),
    Program(
      name: 'Cycling',
      type: ProgramType.cycling,
      category: 'ENDURANCE',
      description:
          'Low-impact indoor rides with climbs, sprints and serious energy.',
    ),
    Program(
      name: 'Yoga classes',
      type: ProgramType.yoga,
      category: 'MIND & BODY',
      description:
          'Improve mobility, balance and recovery through guided movement.',
    ),
    Program(
      name: 'Zumba',
      type: ProgramType.zumba,
      category: 'DANCE',
      description:
          'A lively full-body cardio session powered by music and movement.',
    ),
    Program(
      name: 'Dance fitness',
      type: ProgramType.danceFitness,
      category: 'GROUP FITNESS',
      description:
          'Fun choreographed sessions that make every workout feel different.',
    ),
    Program(
      name: 'Aquatics',
      type: ProgramType.aquatics,
      category: 'LOW IMPACT',
      description:
          'Water-based exercise for conditioning with less stress on joints.',
    ),
    Program(
      name: 'Adult sports',
      type: ProgramType.adultSports,
      category: 'ACTIVE PLAY',
      description:
          'Stay competitive, social and active through recreational sport.',
    ),
  ],
  equipment: [
    Equipment(
      name: 'Leg Press & Hack Squat',
      category: 'PLATE LOADED',
      image: 'assets/Hack-Squat-Leg-press.png',
      description:
          'Dual-station lower-body machine designed for heavy leg press and hack squat training.',
      specs: ['2400 × 1850 × 1500 mm', 'Net weight: 232 kg', 'Black finish'],
    ),
    Equipment(
      name: 'Hercules TMA60 Treadmill',
      category: 'CARDIO',
      image: 'assets/tma60.png',
      description:
          'Fully commercial motorized treadmill with auto incline and integrated MP3 support.',
      specs: [
        '6.0 HP A.C. motor',
        'Motorized auto incline',
        'Commercial grade',
      ],
    ),
    Equipment(
      name: 'Hercules SB90 Bike',
      category: 'CARDIO',
      image: 'assets/diorSB90-1.png',
      description:
          'A stable commercial bike with advanced magnetic resistance for controlled, high-output rides.',
      specs: ['22 kg flywheel', 'Max user: 180 kg', '5-level adjustment'],
    ),
    Equipment(
      name: 'Weight Assisted Chin & Dip',
      category: 'PIN LOADED',
      image: 'assets/Weight-Assisted-Chin-Dip.png',
      description:
          'Dual-station assisted chin-up and dip unit for scalable upper-body strength training.',
      specs: [
        '80 kg weight stack',
        '1707 × 1304 × 2290 mm',
        'Net weight: 251 kg',
      ],
    ),
    Equipment(
      name: 'Pec Fly & Rear Delt',
      category: 'PIN LOADED',
      image: 'assets/Pec-Fly-Rear-Delt.png',
      description:
          'Dual-function station for controlled chest fly and rear-deltoid isolation work.',
      specs: [
        '100 kg weight stack',
        '1688 × 1065 × 1994 mm',
        'Net weight: 232 kg',
      ],
    ),
    Equipment(
      name: 'Adjustable Fitness Bench',
      category: 'FREE WEIGHTS',
      image: 'assets/MP100-RH.png',
      description:
          'Flat, incline and decline bench with thick padding for lifting and abdominal training.',
      specs: [
        'Multi-angle adjustment',
        'Cushioned support',
        'Ab crunch compatible',
      ],
    ),
    Equipment(
      name: 'Lat Pulldown & Mid Row',
      category: 'PIN LOADED',
      image: 'assets/Lat-Pull-down-Mid-row.png',
      description:
          'Dual-station back machine for vertical pulls and strong, controlled seated rows.',
      specs: [
        '100 kg weight stack',
        '1860 × 1220 × 1930 mm',
        'Net weight: 221 kg',
      ],
    ),
    Equipment(
      name: 'Abdominal Machine Plate',
      category: 'PLATE LOADED',
      image: 'assets/NewEquip/ABDOMINAL-Machine-Plate.png',
      description:
          'Plate-loaded abdominal station for controlled core flexion and progressive resistance training.',
      specs: ['Adjustable resistance', 'Core isolation', 'Commercial frame'],
    ),
    Equipment(
      name: 'Adjustable Olympic Dumbbells',
      category: 'FREE WEIGHTS',
      image: 'assets/NewEquip/adjustableolympic.png',
      description:
          'Space-saving adjustable Olympic dumbbells for strength work across multiple training loads.',
      specs: ['Adjustable loading', 'Olympic plate compatible', 'Knurled grip'],
    ),
    Equipment(
      name: 'Dumbbells',
      category: 'FREE WEIGHTS',
      image: 'assets/NewEquip/dumbells.png',
      description:
          'Versatile dumbbell set for presses, rows, curls, raises and full-body accessory training.',
      specs: [
        'Multiple weight options',
        'Strength and accessory work',
        'Easy-grip handles',
      ],
    ),
    Equipment(
      name: 'Elliptical Trainer',
      category: 'CARDIO',
      image: 'assets/NewEquip/elliptical_trainer.jpg',
      description:
          'Low-impact cardio trainer for smooth endurance sessions with reduced joint stress.',
      specs: ['Full-body cardio', 'Low-impact stride', 'Endurance training'],
    ),
    Equipment(
      name: 'Hyper Extension',
      category: 'BODYWEIGHT',
      image: 'assets/NewEquip/Hyper-Extension.png',
      description:
          'Back-extension bench for posterior-chain training, core control and lower-back strength.',
      specs: [
        'Adjustable support',
        'Posterior-chain focus',
        'Bodyweight strength',
      ],
    ),
    Equipment(
      name: 'Kettlebell',
      category: 'FREE WEIGHTS',
      image: 'assets/NewEquip/kettlebell.png',
      description:
          'Compact kettlebell for swings, carries, squats and explosive conditioning workouts.',
      specs: [
        'Functional training',
        'Grip and core work',
        'Conditioning friendly',
      ],
    ),
    Equipment(
      name: 'Lateral Raise Machine',
      category: 'PIN LOADED',
      image: 'assets/NewEquip/LATERAL-RAISE.png',
      description:
          'Shoulder isolation machine for strict lateral raises and controlled deltoid development.',
      specs: ['Deltoid isolation', 'Guided movement path', 'Adjustable seat'],
    ),
    Equipment(
      name: 'Leg Curl & Extension',
      category: 'PIN LOADED',
      image: 'assets/NewEquip/leg-curlandextension.png',
      description:
          'Dual-function leg station for hamstring curls and quadriceps extensions in one machine.',
      specs: [
        'Two-in-one leg training',
        'Adjustable pads',
        'Controlled isolation',
      ],
    ),
    Equipment(
      name: 'Multi Press',
      category: 'PIN LOADED',
      image: 'assets/NewEquip/Multi-Press-New.png',
      description:
          'Guided press station for chest, shoulder and upper-body strength with stable support.',
      specs: [
        'Multi-angle pressing',
        'Upper-body strength',
        'Guided resistance',
      ],
    ),
    Equipment(
      name: 'Multi Adjustable Bench',
      category: 'FREE WEIGHTS',
      image: 'assets/NewEquip/multiadjustablebench.png',
      description:
          'Adjustable bench for flat, incline and upright lifting positions during free-weight training.',
      specs: ['Multiple bench angles', 'Free-weight support', 'Stable base'],
    ),
    Equipment(
      name: 'Weight Plates',
      category: 'FREE WEIGHTS',
      image: 'assets/NewEquip/plates.png',
      description:
          'Durable plates for barbells, plate-loaded machines and progressive strength training.',
      specs: [
        'Progressive loading',
        'Barbell compatible',
        'Machine compatible',
      ],
    ),
    Equipment(
      name: 'Power Rack',
      category: 'FREE WEIGHTS',
      image: 'assets/NewEquip/power-rack.png',
      description:
          'Heavy-duty rack for squats, presses, pull-ups and barbell training with safety support.',
      specs: [
        'Squat and press station',
        'Safety supports',
        'Pull-up compatible',
      ],
    ),
    Equipment(
      name: 'Preacher Curl',
      category: 'FREE WEIGHTS',
      image: 'assets/NewEquip/Preacher-Curl.png',
      description:
          'Arm-training bench that supports strict preacher curls and focused biceps isolation.',
      specs: ['Biceps isolation', 'Angled arm pad', 'Curl support'],
    ),
    Equipment(
      name: 'Utility Bench',
      category: 'FREE WEIGHTS',
      image: 'assets/NewEquip/utilitybench.png',
      description:
          'Compact bench for dumbbell work, seated movements and accessory strength exercises.',
      specs: ['Accessory training', 'Compact footprint', 'Stable support'],
    ),
  ],
);
