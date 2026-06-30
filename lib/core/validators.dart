class Validators {
  Validators._();
  static final _emailRegex = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value, {bool isNewPassword = false}) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (isNewPassword) {
      if (value.length < 8) return 'Password must be at least 8 characters';
      if (!value.contains(RegExp(r'[A-Z]'))) {
        return 'Password must contain an uppercase letter';
      }
      if (!value.contains(RegExp(r'[a-z]'))) {
        return 'Password must contain a lowercase letter';
      }
      if (!value.contains(RegExp(r'[0-9]'))) {
        return 'Password must contain a number';
      }
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    if (value.trim().length > 50) return 'Name is too long';
    return null;
  }

  static String? confirmPassword(String? value, String? original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }
}
