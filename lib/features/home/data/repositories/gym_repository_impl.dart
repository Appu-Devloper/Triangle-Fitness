import 'package:triangle_fitness/features/home/domain/entities/equipment.dart';
import 'package:triangle_fitness/features/home/domain/entities/gym_content.dart';
import 'package:triangle_fitness/features/home/domain/entities/program.dart';
import 'package:triangle_fitness/features/home/domain/repositories/gym_repository.dart';

class GymRepositoryImpl implements GymRepository {
  @override
  Future<GymContent> getContent() async => const GymContent(
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
    ],
  );
}
