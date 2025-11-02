import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@singleton
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserPhoto = 'user_photo';

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Create a GoogleAuthProvider instance
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Sign in with popup/redirect (web) or native flow (mobile)
      final userCredential = await _firebaseAuth.signInWithProvider(googleProvider);

      // Save login state to SharedPreferences
      if (userCredential.user != null) {
        await _saveLoginState(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      // Clear login state from SharedPreferences
      await _clearLoginState();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveLoginState(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserId, user.uid);
    await prefs.setString(_keyUserEmail, user.email ?? '');
    await prefs.setString(_keyUserName, user.displayName ?? '');
    await prefs.setString(_keyUserPhoto, user.photoURL ?? '');
  }

  Future<void> _clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserPhoto);
  }

  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<Map<String, String?>> getSavedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(_keyUserId),
      'email': prefs.getString(_keyUserEmail),
      'name': prefs.getString(_keyUserName),
      'photo': prefs.getString(_keyUserPhoto),
    };
  }

  String? getUserDisplayName() {
    return currentUser?.displayName;
  }

  String? getUserEmail() {
    return currentUser?.email;
  }

  String? getUserPhotoUrl() {
    return currentUser?.photoURL;
  }

  bool isSignedIn() {
    return currentUser != null;
  }
}
