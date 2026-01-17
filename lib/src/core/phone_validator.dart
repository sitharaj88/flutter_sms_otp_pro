/// Utility class for phone number validation and formatting.
///
/// Provides comprehensive phone number handling including validation,
/// formatting, and country code detection.
class PhoneValidator {
  // Common country codes with their expected phone number lengths
  static const Map<String, PhoneNumberFormat> _countryFormats = {
    '+1': PhoneNumberFormat(
        code: '+1', name: 'US/Canada', minLength: 10, maxLength: 10),
    '+44': PhoneNumberFormat(
        code: '+44', name: 'UK', minLength: 10, maxLength: 11),
    '+91': PhoneNumberFormat(
        code: '+91', name: 'India', minLength: 10, maxLength: 10),
    '+86': PhoneNumberFormat(
        code: '+86', name: 'China', minLength: 11, maxLength: 11),
    '+81': PhoneNumberFormat(
        code: '+81', name: 'Japan', minLength: 10, maxLength: 11),
    '+49': PhoneNumberFormat(
        code: '+49', name: 'Germany', minLength: 10, maxLength: 12),
    '+33': PhoneNumberFormat(
        code: '+33', name: 'France', minLength: 9, maxLength: 10),
    '+61': PhoneNumberFormat(
        code: '+61', name: 'Australia', minLength: 9, maxLength: 9),
    '+55': PhoneNumberFormat(
        code: '+55', name: 'Brazil', minLength: 10, maxLength: 11),
    '+7': PhoneNumberFormat(
        code: '+7', name: 'Russia', minLength: 10, maxLength: 10),
    '+82': PhoneNumberFormat(
        code: '+82', name: 'South Korea', minLength: 9, maxLength: 10),
    '+39': PhoneNumberFormat(
        code: '+39', name: 'Italy', minLength: 9, maxLength: 11),
    '+34': PhoneNumberFormat(
        code: '+34', name: 'Spain', minLength: 9, maxLength: 9),
    '+31': PhoneNumberFormat(
        code: '+31', name: 'Netherlands', minLength: 9, maxLength: 9),
    '+46': PhoneNumberFormat(
        code: '+46', name: 'Sweden', minLength: 7, maxLength: 13),
    '+41': PhoneNumberFormat(
        code: '+41', name: 'Switzerland', minLength: 9, maxLength: 9),
    '+65': PhoneNumberFormat(
        code: '+65', name: 'Singapore', minLength: 8, maxLength: 8),
    '+971': PhoneNumberFormat(
        code: '+971', name: 'UAE', minLength: 9, maxLength: 9),
    '+966': PhoneNumberFormat(
        code: '+966', name: 'Saudi Arabia', minLength: 9, maxLength: 9),
    '+27': PhoneNumberFormat(
        code: '+27', name: 'South Africa', minLength: 9, maxLength: 9),
  };

  /// Validates a phone number.
  ///
  /// Returns a [PhoneValidationResult] with validation status and details.
  static PhoneValidationResult validate(String phoneNumber) {
    // Remove all whitespace and common separators
    final cleaned = _cleanPhoneNumber(phoneNumber);

    if (cleaned.isEmpty) {
      return const PhoneValidationResult(
        isValid: false,
        error: PhoneValidationError.empty,
        message: 'Phone number is required',
      );
    }

    // Check for valid characters
    if (!RegExp(r'^\+?[0-9]+$').hasMatch(cleaned)) {
      return const PhoneValidationResult(
        isValid: false,
        error: PhoneValidationError.invalidCharacters,
        message: 'Phone number contains invalid characters',
      );
    }

    // Detect country code
    final countryFormat = _detectCountryFormat(cleaned);

    if (countryFormat != null) {
      final nationalNumber = cleaned.substring(countryFormat.code.length);

      if (nationalNumber.length < countryFormat.minLength) {
        return PhoneValidationResult(
          isValid: false,
          error: PhoneValidationError.tooShort,
          message: 'Phone number is too short for ${countryFormat.name}',
          countryCode: countryFormat.code,
          formattedNumber: cleaned,
        );
      }

      if (nationalNumber.length > countryFormat.maxLength) {
        return PhoneValidationResult(
          isValid: false,
          error: PhoneValidationError.tooLong,
          message: 'Phone number is too long for ${countryFormat.name}',
          countryCode: countryFormat.code,
          formattedNumber: cleaned,
        );
      }

      return PhoneValidationResult(
        isValid: true,
        countryCode: countryFormat.code,
        countryName: countryFormat.name,
        nationalNumber: nationalNumber,
        formattedNumber: _formatPhoneNumber(countryFormat.code, nationalNumber),
        e164Format: cleaned,
      );
    }

    // No country code detected - check minimum viable length
    if (cleaned.length < 7) {
      return const PhoneValidationResult(
        isValid: false,
        error: PhoneValidationError.tooShort,
        message: 'Phone number is too short',
      );
    }

    if (cleaned.length > 15) {
      return const PhoneValidationResult(
        isValid: false,
        error: PhoneValidationError.tooLong,
        message: 'Phone number is too long',
      );
    }

    // Valid but without recognized country code
    return PhoneValidationResult(
      isValid: true,
      formattedNumber: cleaned,
      nationalNumber: cleaned,
    );
  }

  /// Formats a phone number in E.164 format.
  static String? toE164(String phoneNumber, {String? defaultCountryCode}) {
    final cleaned = _cleanPhoneNumber(phoneNumber);

    if (cleaned.startsWith('+')) {
      return cleaned;
    }

    if (defaultCountryCode != null) {
      final code = defaultCountryCode.startsWith('+')
          ? defaultCountryCode
          : '+$defaultCountryCode';
      return '$code$cleaned';
    }

    return null;
  }

  /// Cleans a phone number by removing formatting characters.
  static String _cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[\s\-\(\)\.]+'), '').trim();
  }

  /// Detects the country format for a phone number.
  static PhoneNumberFormat? _detectCountryFormat(String phoneNumber) {
    if (!phoneNumber.startsWith('+')) return null;

    // Sort by code length descending to match longest codes first
    final sortedCodes = _countryFormats.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final code in sortedCodes) {
      if (phoneNumber.startsWith(code)) {
        return _countryFormats[code];
      }
    }

    return null;
  }

  /// Formats a phone number for display.
  static String _formatPhoneNumber(String countryCode, String nationalNumber) {
    // Simple formatting - can be enhanced for country-specific formats
    if (nationalNumber.length >= 10) {
      return '$countryCode ${nationalNumber.substring(0, 3)} '
          '${nationalNumber.substring(3, 6)} '
          '${nationalNumber.substring(6)}';
    }
    return '$countryCode $nationalNumber';
  }

  /// Gets all supported country codes.
  static List<PhoneNumberFormat> get supportedCountries =>
      _countryFormats.values.toList();
}

/// Represents the format rules for a country's phone numbers.
class PhoneNumberFormat {
  /// The country code (e.g., '+1', '+44').
  final String code;

  /// The country or region name.
  final String name;

  /// Minimum length of the national number (excluding country code).
  final int minLength;

  /// Maximum length of the national number (excluding country code).
  final int maxLength;

  const PhoneNumberFormat({
    required this.code,
    required this.name,
    required this.minLength,
    required this.maxLength,
  });

  @override
  String toString() => 'PhoneNumberFormat($code, $name)';
}

/// Result of phone number validation.
class PhoneValidationResult {
  /// Whether the phone number is valid.
  final bool isValid;

  /// The detected country code (e.g., '+1').
  final String? countryCode;

  /// The country or region name.
  final String? countryName;

  /// The national number (without country code).
  final String? nationalNumber;

  /// The formatted phone number for display.
  final String? formattedNumber;

  /// The phone number in E.164 format.
  final String? e164Format;

  /// Validation error type if invalid.
  final PhoneValidationError? error;

  /// Human-readable error or status message.
  final String? message;

  const PhoneValidationResult({
    required this.isValid,
    this.countryCode,
    this.countryName,
    this.nationalNumber,
    this.formattedNumber,
    this.e164Format,
    this.error,
    this.message,
  });

  @override
  String toString() => isValid
      ? 'PhoneValidationResult(valid: $formattedNumber)'
      : 'PhoneValidationResult(invalid: $error - $message)';
}

/// Types of phone validation errors.
enum PhoneValidationError {
  /// Phone number is empty.
  empty,

  /// Phone number contains invalid characters.
  invalidCharacters,

  /// Phone number is too short.
  tooShort,

  /// Phone number is too long.
  tooLong,

  /// Country code is not recognized.
  unknownCountryCode,
}
