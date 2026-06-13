import 'package:flutter/material.dart';
import 'package:triangle_fitness/app/app.dart';
import 'package:triangle_fitness/core/services/firebase_initializer.dart';

export 'package:triangle_fitness/app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseInitializer.instance.startInBackground();
  runApp(const TriangleFitnessApp());
}
