import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class FirebaseDatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Logger logger = Logger();

  Future<void> saveUserData(String uid, String name, String role) async {
    try {
      await _db.collection('users').doc(uid).set({
        'name': name,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      logger.i('User data saved successfully for UID: $uid');
    } catch (e) {
      logger.e('Error saving user data: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        logger.i('User data retrieved for UID: $uid');
        return doc.data() as Map<String, dynamic>;
      } else {
        logger.w('No user data found for UID: $uid');
        return null;
      }
    } catch (e) {
      logger.e('Error retrieving user data: $e');
      return null;
    }
  }
}
