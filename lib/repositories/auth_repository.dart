abstract class AuthRepository {
  Future<String> signInAnonymously();
  Future<String> signInWithEmail(String email, String password);
  Future<void> signOut();
}
