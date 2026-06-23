import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_repository.dart';

/// Concrete example implementation using `firebase_auth`.
/// Requires proper platform configuration (GoogleService-Info.plist on iOS)
/// and `firebase_core` initialization before use.
class FirebaseAuthRepository implements AuthRepository {
  Future<void> _ensureInit() async {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // If already initialized, ignore.
    }
  }

  @override
  Future<String> signInAnonymously() async {
    await _ensureInit();
    final userCred = await FirebaseAuth.instance.signInAnonymously();
    final uid = userCred.user?.uid;
    if (uid == null)
      throw FirebaseAuthException(
          code: 'NO_UID', message: 'No user id returned');
    return uid;
  }

  @override
  Future<String> signInWithEmail(String email, String password) async {
    await _ensureInit();
    final userCred = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    final uid = userCred.user?.uid;
    if (uid == null)
      throw FirebaseAuthException(
          code: 'NO_UID', message: 'No user id returned');
    return uid;
  }

  @override
  Future<void> signOut() async {
    await _ensureInit();
    await FirebaseAuth.instance.signOut();
  }
}
