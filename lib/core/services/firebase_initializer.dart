import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:triangle_fitness/firebase_options.dart';

class FirebaseInitializer {
  FirebaseInitializer._();

  static final instance = FirebaseInitializer._();

  Future<FirebaseApp>? _initialization;

  Future<FirebaseApp> initialize() {
    return _initialization ??= Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  void startInBackground() {
    unawaited(initialize().then<void>((_) {}, onError: (_, __) {}));
  }
}
