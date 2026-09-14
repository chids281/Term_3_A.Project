import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges();
  }

  Future<UserCredential> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await userCredential.user?.updateDisplayName(fullName.trim());
      await userCredential.user?.reload();

      return userCredential;
    } on FirebaseAuthException catch (error) {
      throw Exception(_getFirebaseMessage(error));
    } catch (_) {
      throw Exception(
        'Something went wrong while creating your account.',
      );
    }
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw Exception(_getFirebaseMessage(error));
    } catch (_) {
      throw Exception(
        'Something went wrong while logging in.',
      );
    }
  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (error) {
      throw Exception(_getFirebaseMessage(error));
    }
  }

  Future<void> logout() async {
  await _firebaseAuth.signOut();
}

  String _getFirebaseMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email address.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'weak-password':
        return 'Your password is too weak. Use at least 8 characters.';

      case 'user-not-found':
        return 'No account was found with this email address.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'The email address or password is incorrect.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      case 'operation-not-allowed':
        return 'Email and password authentication is not enabled.';

      default:
        return error.message ?? 'Authentication was unsuccessful.';
    }
  }
}