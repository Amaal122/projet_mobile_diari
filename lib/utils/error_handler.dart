/// Error Handler
/// ==============
/// Global error handling utilities

import 'package:flutter/material.dart';

class ErrorHandler {
  /// Show error snackbar
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'إغلاق',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: const Color(0xFFEE8C2B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show info snackbar
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Parse API error message
  static String parseApiError(dynamic error) {
    if (error == null) return 'حدث خطأ غير متوقع';
    
    final errorStr = error.toString().toLowerCase();
    
    // Network errors
    if (errorStr.contains('socket') || errorStr.contains('network')) {
      return 'خطأ في الاتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى.';
    }
    
    if (errorStr.contains('timeout')) {
      return 'انتهت مهلة الاتصال. حاول مرة أخرى.';
    }
    
    // Auth errors
    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return 'يرجى تسجيل الدخول مرة أخرى.';
    }
    
    if (errorStr.contains('forbidden') || errorStr.contains('403')) {
      return 'ليس لديك صلاحية للوصول إلى هذا المورد.';
    }
    
    // Not found
    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return 'العنصر المطلوب غير موجود.';
    }
    
    // Server errors
    if (errorStr.contains('500') || errorStr.contains('server error')) {
      return 'خطأ في الخادم. حاول مرة أخرى لاحقاً.';
    }
    
    // Firebase errors
    if (errorStr.contains('permission-denied')) {
      return 'ليس لديك صلاحية لتنفيذ هذا الإجراء.';
    }
    
    if (errorStr.contains('user-not-found')) {
      return 'المستخدم غير موجود.';
    }
    
    if (errorStr.contains('wrong-password')) {
      return 'كلمة المرور غير صحيحة.';
    }
    
    if (errorStr.contains('email-already-in-use')) {
      return 'البريد الإلكتروني مستخدم بالفعل.';
    }
    
    if (errorStr.contains('weak-password')) {
      return 'كلمة المرور ضعيفة. استخدم 6 أحرف على الأقل.';
    }
    
    if (errorStr.contains('invalid-email')) {
      return 'البريد الإلكتروني غير صالح.';
    }
    
    // Default
    return 'حدث خطأ. حاول مرة أخرى.';
  }

  /// Show error dialog
  static Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    if (!context.mounted) return;
    
    return showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(title, textAlign: TextAlign.right),
          content: Text(message, textAlign: TextAlign.right),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً'),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle async operation with loading and error handling
  static Future<T?> handleAsync<T>({
    required BuildContext context,
    required Future<T> Function() operation,
    String? loadingMessage,
    String? successMessage,
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) {
        // Show loading indicator if needed
      }
      
      final result = await operation();
      
      if (successMessage != null && context.mounted) {
        showSuccess(context, successMessage);
      }
      
      return result;
    } catch (e) {
      if (context.mounted) {
        final errorMessage = parseApiError(e);
        showError(context, errorMessage);
      }
      return null;
    }
  }
}
