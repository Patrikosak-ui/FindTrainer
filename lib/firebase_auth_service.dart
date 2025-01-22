import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger logger = Logger();

 Future<User?> registerUser(String email, String password) async {
  try {
    // Pokus o registraci uživatele s e-mailem a heslem
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Úspěšná registrace - logování UID uživatele
    logger.i('User registered successfully: ${userCredential.user?.uid}');
    
    // Vrácení uživatele
    return userCredential.user;
  } on FirebaseAuthException catch (e) {
    // Chyba při registraci - FirebaseAuthException
    logger.e('FirebaseAuthException during registration: ${e.code} - ${e.message}');
    
    // Zpracování chyby Firebase Auth
    _handleFirebaseAuthError(e);
    
    // Vracení null v případě chyby
    return null;
  } catch (e) {
    // Neočekávaná chyba při registraci
    logger.e('Unexpected error during registration: $e');
    
    // Vracení null v případě neočekávané chyby
    return null;
  }
}


  Future<User?> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      logger.i('User logged in successfully: ${userCredential.user?.uid}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      logger.e('FirebaseAuthException during login: ${e.code} - ${e.message}');
      _handleFirebaseAuthError(e);
      return null;
    } catch (e) {
      logger.e('Unexpected error during login: $e');
      return null;
    }
  }

  void _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        logger.w('The email address is already in use by another account.');
        break;
      case 'invalid-email':
        logger.w('The email address is not valid.');
        break;
      case 'weak-password':
        logger.w('The password is too weak.');
        break;
      case 'user-not-found':
        logger.w('No user found for the given email.');
        break;
      case 'wrong-password':
        logger.w('Incorrect password provided for the email.');
        break;
      case 'configuration-not-found':
        logger.w(
            'Firebase configuration not found. Check your Firebase project settings and ensure google-services.json is included.');
        break;
      default:
        logger.e('An unknown error occurred: ${e.message}');
    }
  }
}
