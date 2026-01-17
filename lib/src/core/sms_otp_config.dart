/// Configuration model for SMS OTP behavior.
///
/// This class provides comprehensive configuration options for OTP handling,
/// including timeout, retry logic, and platform-specific settings.
class SmsOtpConfig {
  /// The expected length of the OTP code.
  /// Defaults to 6 digits which is the most common format.
  final int otpLength;

  /// Maximum time to wait for OTP detection.
  /// After this duration, the listener will timeout.
  final Duration timeout;

  /// Maximum number of OTP requests allowed.
  /// Used for rate limiting to prevent abuse.
  final int maxRetries;

  /// Cooldown period between retry attempts.
  /// Enforces a waiting period between OTP resend requests.
  final Duration retryCooldown;

  /// Whether to automatically submit when OTP is complete.
  /// If true, triggers [onCompleted] immediately when all digits are filled.
  final bool autoSubmit;

  /// Filter incoming SMS by sender phone number or short code.
  /// Only messages from this sender will be processed.
  final String? senderFilter;

  /// Whether to use haptic feedback on input.
  final bool hapticFeedback;

  /// Whether the OTP input should be obscured (like a password).
  final bool obscureText;

  /// Custom regex pattern to extract OTP from SMS.
  /// If null, uses default pattern matching [otpLength] digits.
  final String? customOtpPattern;

  /// Creates a new [SmsOtpConfig] with the specified parameters.
  const SmsOtpConfig({
    this.otpLength = 6,
    this.timeout = const Duration(minutes: 5),
    this.maxRetries = 3,
    this.retryCooldown = const Duration(seconds: 30),
    this.autoSubmit = true,
    this.senderFilter,
    this.hapticFeedback = true,
    this.obscureText = false,
    this.customOtpPattern,
  }) : assert(otpLength >= 4 && otpLength <= 8,
            'OTP length must be between 4 and 8 digits');

  /// Creates a copy with modified fields.
  SmsOtpConfig copyWith({
    int? otpLength,
    Duration? timeout,
    int? maxRetries,
    Duration? retryCooldown,
    bool? autoSubmit,
    String? senderFilter,
    bool? hapticFeedback,
    bool? obscureText,
    String? customOtpPattern,
  }) {
    return SmsOtpConfig(
      otpLength: otpLength ?? this.otpLength,
      timeout: timeout ?? this.timeout,
      maxRetries: maxRetries ?? this.maxRetries,
      retryCooldown: retryCooldown ?? this.retryCooldown,
      autoSubmit: autoSubmit ?? this.autoSubmit,
      senderFilter: senderFilter ?? this.senderFilter,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      obscureText: obscureText ?? this.obscureText,
      customOtpPattern: customOtpPattern ?? this.customOtpPattern,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SmsOtpConfig &&
        other.otpLength == otpLength &&
        other.timeout == timeout &&
        other.maxRetries == maxRetries &&
        other.retryCooldown == retryCooldown &&
        other.autoSubmit == autoSubmit &&
        other.senderFilter == senderFilter &&
        other.hapticFeedback == hapticFeedback &&
        other.obscureText == obscureText &&
        other.customOtpPattern == customOtpPattern;
  }

  @override
  int get hashCode => Object.hash(
        otpLength,
        timeout,
        maxRetries,
        retryCooldown,
        autoSubmit,
        senderFilter,
        hapticFeedback,
        obscureText,
        customOtpPattern,
      );

  @override
  String toString() {
    return 'SmsOtpConfig(otpLength: $otpLength, timeout: $timeout, '
        'maxRetries: $maxRetries, retryCooldown: $retryCooldown, '
        'autoSubmit: $autoSubmit, senderFilter: $senderFilter)';
  }
}
