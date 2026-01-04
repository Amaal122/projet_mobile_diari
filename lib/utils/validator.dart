/// Input Validator
/// ================
/// Validation utilities for forms

class Validator {
  /// Validate email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'البريد الإلكتروني غير صالح';
    }
    
    return null;
  }

  /// Validate password
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    
    if (value.length < minLength) {
      return 'كلمة المرور يجب أن تحتوي على $minLength أحرف على الأقل';
    }
    
    return null;
  }

  /// Validate phone number
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'رقم الهاتف مطلوب';
    }
    
    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');
    
    // Tunisian phone: 8 digits or international format
    final phoneRegex = RegExp(r'^\+?216?\d{8}$|^\d{8}$');
    
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'رقم الهاتف غير صالح';
    }
    
    return null;
  }

  /// Validate required field
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'هذا الحقل'} مطلوب';
    }
    return null;
  }

  /// Validate min length
  static String? minLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.isEmpty) return null;
    
    if (value.length < min) {
      return '${fieldName ?? 'هذا الحقل'} يجب أن يحتوي على $min أحرف على الأقل';
    }
    
    return null;
  }

  /// Validate max length
  static String? maxLength(String? value, int max, {String? fieldName}) {
    if (value == null || value.isEmpty) return null;
    
    if (value.length > max) {
      return '${fieldName ?? 'هذا الحقل'} يجب ألا يتجاوز $max حرف';
    }
    
    return null;
  }

  /// Validate number
  static String? number(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) return null;
    
    if (double.tryParse(value) == null) {
      return '${fieldName ?? 'هذا الحقل'} يجب أن يكون رقماً';
    }
    
    return null;
  }

  /// Validate positive number
  static String? positiveNumber(String? value, {String? fieldName}) {
    final numberError = number(value, fieldName: fieldName);
    if (numberError != null) return numberError;
    
    final numValue = double.parse(value!);
    if (numValue <= 0) {
      return '${fieldName ?? 'هذا الحقل'} يجب أن يكون رقماً موجباً';
    }
    
    return null;
  }

  /// Validate price
  static String? price(String? value) {
    if (value == null || value.isEmpty) {
      return 'السعر مطلوب';
    }
    
    final numValue = double.tryParse(value);
    if (numValue == null || numValue < 0) {
      return 'السعر غير صالح';
    }
    
    return null;
  }

  /// Validate address
  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'العنوان مطلوب';
    }
    
    if (value.trim().length < 5) {
      return 'العنوان قصير جداً';
    }
    
    return null;
  }

  /// Validate rating (1-5)
  static String? rating(int? value) {
    if (value == null) {
      return 'التقييم مطلوب';
    }
    
    if (value < 1 || value > 5) {
      return 'التقييم يجب أن يكون بين 1 و 5';
    }
    
    return null;
  }

  /// Combine multiple validators
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// Sanitize input (remove dangerous characters)
  static String sanitize(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('`', '')
        .trim();
  }
}
