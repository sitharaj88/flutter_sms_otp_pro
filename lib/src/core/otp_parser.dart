/// Utility class for extracting OTP codes from SMS messages.
///
/// Provides intelligent OTP extraction with support for various message formats
/// and customizable patterns.
class OtpParser {
  /// Default patterns to match common OTP formats in SMS messages.
  static const List<String> _defaultPatterns = [
    // "Your OTP is 123456" or "Your code is 123456"
    r'(?:code|otp|password|pin|verification)\s*(?:is|:)?\s*(\d{4,8})',
    // "123456 is your OTP"
    r'(\d{4,8})\s*(?:is\s+your|is\s+the)',
    // "<#> Your code is 123456..." (SMS Retriever format)
    r'<#>\s*.*?(\d{4,8})',
    // Standalone code patterns like "Code: 123456"
    r'(?:code|otp|pin)\s*[-:]\s*(\d{4,8})',
    // General pattern for isolated numeric codes
    r'\b(\d{4,8})\b',
  ];

  /// Extracts an OTP code from an SMS message.
  ///
  /// [message] The raw SMS message text.
  /// [expectedLength] Expected length of the OTP (optional, for validation).
  /// [customPattern] Custom regex pattern to use instead of defaults.
  ///
  /// Returns the extracted OTP or null if not found.
  static String? extractOtp(
    String message, {
    int? expectedLength,
    String? customPattern,
  }) {
    if (message.isEmpty) return null;

    // Normalize the message
    final normalizedMessage = message.toLowerCase().trim();

    // Use custom pattern if provided
    if (customPattern != null) {
      final match = RegExp(customPattern, caseSensitive: false)
          .firstMatch(normalizedMessage);
      if (match != null && match.groupCount >= 1) {
        return _validateOtp(match.group(1), expectedLength);
      }
    }

    // Try default patterns in order of specificity
    for (final pattern in _defaultPatterns) {
      final match =
          RegExp(pattern, caseSensitive: false).firstMatch(normalizedMessage);
      if (match != null && match.groupCount >= 1) {
        final otp = _validateOtp(match.group(1), expectedLength);
        if (otp != null) return otp;
      }
    }

    // Last resort: find any sequence of digits matching expected length
    if (expectedLength != null) {
      final allDigits = RegExp(r'\d{$expectedLength}')
          .allMatches(normalizedMessage)
          .map((m) => m.group(0))
          .where((d) => d != null)
          .toList();

      // If exactly one match, use it
      if (allDigits.length == 1) {
        return allDigits.first;
      }
    }

    return null;
  }

  /// Validates an extracted OTP against expected criteria.
  static String? _validateOtp(String? otp, int? expectedLength) {
    if (otp == null || otp.isEmpty) return null;

    // Clean the OTP
    final cleaned = otp.replaceAll(RegExp(r'\s+'), '');

    // Check if it's all digits
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return null;

    // Check length if specified
    if (expectedLength != null && cleaned.length != expectedLength) {
      return null;
    }

    // Check reasonable length (4-8 digits)
    if (cleaned.length < 4 || cleaned.length > 8) return null;

    return cleaned;
  }

  /// Checks if a message contains a likely OTP code.
  static bool containsOtp(String message, {int? expectedLength}) {
    return extractOtp(message, expectedLength: expectedLength) != null;
  }

  /// Extracts all potential OTP codes from a message.
  ///
  /// Useful when multiple codes might be present.
  static List<String> extractAllPotentialOtps(
    String message, {
    int? expectedLength,
  }) {
    final results = <String>{};
    final normalizedMessage = message.toLowerCase().trim();

    for (final pattern in _defaultPatterns) {
      final matches =
          RegExp(pattern, caseSensitive: false).allMatches(normalizedMessage);
      for (final match in matches) {
        final otp = _validateOtp(match.group(1), expectedLength);
        if (otp != null) {
          results.add(otp);
        }
      }
    }

    return results.toList();
  }

  /// Detects the format/source of an OTP message.
  static OtpMessageFormat detectFormat(String message) {
    final normalizedMessage = message.toLowerCase().trim();

    if (message.contains('<#>')) {
      return OtpMessageFormat.smsRetriever;
    }

    if (normalizedMessage.contains('verification') ||
        normalizedMessage.contains('verify')) {
      return OtpMessageFormat.verification;
    }

    if (normalizedMessage.contains('login') ||
        normalizedMessage.contains('sign in')) {
      return OtpMessageFormat.login;
    }

    if (normalizedMessage.contains('transaction') ||
        normalizedMessage.contains('payment')) {
      return OtpMessageFormat.transaction;
    }

    if (normalizedMessage.contains('reset') ||
        normalizedMessage.contains('recover')) {
      return OtpMessageFormat.passwordReset;
    }

    return OtpMessageFormat.unknown;
  }
}

/// Represents the detected format/purpose of an OTP message.
enum OtpMessageFormat {
  /// SMS Retriever API format (starts with <#>).
  smsRetriever,

  /// Account verification OTP.
  verification,

  /// Login/authentication OTP.
  login,

  /// Transaction/payment confirmation OTP.
  transaction,

  /// Password reset OTP.
  passwordReset,

  /// Unknown format.
  unknown,
}
