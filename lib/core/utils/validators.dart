/// Centralised form validators. Every form screen uses these so error copy stays
/// consistent.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final RegExp _phone = RegExp(r'^[6-9]\d{9}$');
  static final RegExp _digits = RegExp(r'^\d+$');
  static final RegExp _upi = RegExp(r'^[\w.\-]{2,}@[a-zA-Z]{2,}$');
  static final RegExp _nameLetters = RegExp(r"^[A-Za-z][A-Za-z\s.'-]*$");

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required';
    if (value.trim().length < 3) return 'Enter your full name';
    if (!_nameLetters.hasMatch(value.trim())) {
      return 'Use letters only';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    final String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return 'Enter a 10-digit mobile number';
    if (!_phone.hasMatch(digits)) return 'Enter a valid Indian mobile number';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_email.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? optionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return email(value);
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'Include at least one letter';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Include at least one number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Re-enter your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.isEmpty) return 'Enter the 6-digit code';
    if (value.length != 6) return 'The code has 6 digits';
    if (!_digits.hasMatch(value)) return 'Code must be digits only';
    return null;
  }

  static String? numeric(String? value, {String field = 'Value'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    if (!_digits.hasMatch(value.trim())) return 'Enter digits only';
    return null;
  }

  static String? amount(String? value, {int min = 1, int? max}) {
    final String? base = numeric(value, field: 'Amount');
    if (base != null) return base;
    final int parsed = int.parse(value!.trim());
    if (parsed < min) return 'Minimum $min';
    if (max != null && parsed > max) return 'Maximum $max';
    return null;
  }

  static String? minLength(
    String? value,
    int length, {
    String field = 'This field',
  }) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    if (value.trim().length < length) {
      return 'Use at least $length characters';
    }
    return null;
  }

  static String? upiId(String? value) {
    if (value == null || value.trim().isEmpty) return 'UPI ID is required';
    if (!_upi.hasMatch(value.trim())) return 'Format: name@bank';
    return null;
  }
}
