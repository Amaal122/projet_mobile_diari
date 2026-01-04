/// Auth Service
/// =============
/// Firebase Authentication wrapper for Flutter
/// Handles sign-in, sign-up, token management

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'api_service.dart';
import '../state/app_state.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Current user
  static User? get currentUser => _auth.currentUser;
  
  /// Check if user is logged in
  static bool get isLoggedIn => currentUser != null;
  
  /// Auth state changes stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// Get current ID token
  static Future<String?> getIdToken({bool forceRefresh = false}) async {
    if (currentUser == null) return null;
    return await currentUser!.getIdToken(forceRefresh);
  }
  
  /// Initialize auth - call after Firebase.initializeApp()
  static Future<void> initialize() async {
    // Set up token for API calls if user is already logged in
    if (currentUser != null) {
      final token = await getIdToken();
      if (token != null) {
        ApiService.setAuthToken(token);
      }
      
      // Check if user is chef from Firestore first, then SharedPreferences
      await _checkAndLoadChefStatus();
    }
    
    // Listen for auth changes
    authStateChanges.listen((User? user) async {
      if (user != null) {
        final token = await getIdToken();
        if (token != null) {
          ApiService.setAuthToken(token);
        }
        // Check chef status when user logs in
        await _checkAndLoadChefStatus();
      } else {
        ApiService.clearAuthToken();
        AppState().clearUser();
      }
    });
  }
  
  /// Check if user is a chef in Firestore cookers collection
  static Future<void> _checkAndLoadChefStatus() async {
    if (currentUser == null) return;
    
    try {
      // First check Firestore cookers collection
      final doc = await FirebaseFirestore.instance
          .collection('cookers')
          .doc(currentUser!.uid)
          .get();
      
      if (doc.exists) {
        // User is a chef - update both AppState and SharedPreferences
        AppState().setUserRole('chef');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isChef', true);
        await prefs.setString('userId', currentUser!.uid);
        print('Chef status loaded from Firestore and saved to SharedPreferences');
        return;
      }
      
      // If not in Firestore, check SharedPreferences as fallback
      final prefs = await SharedPreferences.getInstance();
      final isChef = prefs.getBool('isChef') ?? false;
      if (isChef) {
        AppState().setUserRole('chef');
        print('Loaded chef status from SharedPreferences');
      }
    } catch (e) {
      print('Error loading chef status: $e');
      // Fallback to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        final isChef = prefs.getBool('isChef') ?? false;
        if (isChef) {
          AppState().setUserRole('chef');
          print('Loaded chef status from SharedPreferences (fallback)');
        }
      } catch (e2) {
        print('Error loading from SharedPreferences: $e2');
      }
    }
  }
  
  // ==================== Email/Password Auth ====================
  
  /// Sign up with email and password
  static Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name if provided
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
      }
      
      // Get token and set for API
      final token = await credential.user?.getIdToken();
      if (token != null) {
        ApiService.setAuthToken(token);
      }
      
      return AuthResult.success(credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getArabicError(e.code));
    } catch (e) {
      return AuthResult.error('حدث خطأ غير متوقع');
    }
  }
  
  /// Sign in with email and password
  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Get token and set for API
      final token = await credential.user?.getIdToken();
      if (token != null) {
        ApiService.setAuthToken(token);
      }
      
      return AuthResult.success(credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getArabicError(e.code));
    } catch (e) {
      return AuthResult.error('حدث خطأ غير متوقع');
    }
  }
  
  /// Sign out
  static Future<void> signOut() async {
    ApiService.clearAuthToken();
    await _auth.signOut();
  }
  
  /// Send password reset email
  static Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success(null, message: 'تم إرسال رابط إعادة التعيين');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getArabicError(e.code));
    } catch (e) {
      return AuthResult.error('حدث خطأ غير متوقع');
    }
  }
  
  // ==================== Profile Updates ====================
  
  /// Update display name
  static Future<AuthResult> updateDisplayName(String name) async {
    try {
      await currentUser?.updateDisplayName(name);
      return AuthResult.success(currentUser);
    } catch (e) {
      return AuthResult.error('فشل تحديث الاسم');
    }
  }
  
  /// Update email
  static Future<AuthResult> updateEmail(String newEmail) async {
    try {
      await currentUser?.verifyBeforeUpdateEmail(newEmail);
      return AuthResult.success(currentUser, message: 'تم إرسال رابط التحقق');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getArabicError(e.code));
    } catch (e) {
      return AuthResult.error('فشل تحديث البريد');
    }
  }
  
  /// Update password
  static Future<AuthResult> updatePassword(String newPassword) async {
    try {
      await currentUser?.updatePassword(newPassword);
      return AuthResult.success(currentUser, message: 'تم تغيير كلمة المرور');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getArabicError(e.code));
    } catch (e) {
      return AuthResult.error('فشل تغيير كلمة المرور');
    }
  }
  
  // ==================== Helper Methods ====================
  
  /// Convert Firebase error codes to Arabic messages
  static String _getArabicError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقاً';
      case 'operation-not-allowed':
        return 'هذه العملية غير مسموحة';
      case 'requires-recent-login':
        return 'يجب إعادة تسجيل الدخول';
      default:
        return 'حدث خطأ: $code';
    }
  }
}


/// Auth result wrapper
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? error;
  final String? message;
  
  AuthResult._({
    required this.isSuccess,
    this.user,
    this.error,
    this.message,
  });
  
  factory AuthResult.success(User? user, {String? message}) {
    return AuthResult._(isSuccess: true, user: user, message: message);
  }
  
  factory AuthResult.error(String error) {
    return AuthResult._(isSuccess: false, error: error);
  }
}
