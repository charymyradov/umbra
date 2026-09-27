import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';

/// Uygulama boyunca tek Firestore istemcisi.
final Provider<FirebaseFirestore> firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

/// Uygulama boyunca tek Auth istemcisi.
final Provider<FirebaseAuth> firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

/// Kimlik doğrulama durumu. `null` → giriş yapılmamış.
final StreamProvider<User?> sessionProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);

final Provider<String?> currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(sessionProvider).value?.uid;
});

final Provider<bool> isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(currentUserIdProvider) != null,
);

/// App açılışında bir kez çağrılır.
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
