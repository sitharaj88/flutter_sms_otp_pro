/// Represents the result of an OTP operation.
///
/// This sealed class provides type-safe handling of OTP outcomes,
/// following functional programming patterns for error handling.
sealed class OtpResult {
  const OtpResult();

  /// Whether the operation was successful.
  bool get isSuccess => this is OtpSuccess;

  /// Whether the operation failed.
  bool get isFailure => !isSuccess;

  /// Pattern matching helper for handling all result types.
  T when<T>({
    required T Function(String otp) success,
    required T Function(String message) timeout,
    required T Function(OtpException exception) error,
    required T Function() cancelled,
  }) {
    return switch (this) {
      OtpSuccess(otp: final otp) => success(otp),
      OtpTimeout(message: final msg) => timeout(msg),
      OtpError(exception: final ex) => error(ex),
      OtpCancelled() => cancelled(),
    };
  }

  /// Pattern matching helper with default fallback.
  T maybeWhen<T>({
    T Function(String otp)? success,
    T Function(String message)? timeout,
    T Function(OtpException exception)? error,
    T Function()? cancelled,
    required T Function() orElse,
  }) {
    return switch (this) {
      OtpSuccess(otp: final otp) => success?.call(otp) ?? orElse(),
      OtpTimeout(message: final msg) => timeout?.call(msg) ?? orElse(),
      OtpError(exception: final ex) => error?.call(ex) ?? orElse(),
      OtpCancelled() => cancelled?.call() ?? orElse(),
    };
  }
}

/// Represents a successful OTP retrieval.
final class OtpSuccess extends OtpResult {
  /// The retrieved OTP code.
  final String otp;

  /// The raw SMS message (if available).
  final String? rawMessage;

  /// The sender of the SMS (if available).
  final String? sender;

  /// Timestamp when the OTP was received.
  final DateTime receivedAt;

  const OtpSuccess({
    required this.otp,
    this.rawMessage,
    this.sender,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? const _Now();

  @override
  String toString() => 'OtpSuccess(otp: $otp, sender: $sender)';
}

/// Helper class to provide default DateTime.now() value
class _Now implements DateTime {
  const _Now();

  DateTime get _now => DateTime.now();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Function.apply(_now as Function, [], invocation.namedArguments);
}

/// Represents an OTP timeout.
final class OtpTimeout extends OtpResult {
  /// Human-readable timeout message.
  final String message;

  /// The duration that was configured for timeout.
  final Duration configuredTimeout;

  const OtpTimeout({
    this.message = 'OTP verification timed out',
    this.configuredTimeout = const Duration(minutes: 5),
  });

  @override
  String toString() => 'OtpTimeout(message: $message)';
}

/// Represents an OTP error.
final class OtpError extends OtpResult {
  /// The exception that caused the error.
  final OtpException exception;

  const OtpError(this.exception);

  @override
  String toString() => 'OtpError(exception: $exception)';
}

/// Represents a cancelled OTP operation.
final class OtpCancelled extends OtpResult {
  /// Optional reason for cancellation.
  final String? reason;

  const OtpCancelled({this.reason});

  @override
  String toString() => 'OtpCancelled(reason: $reason)';
}

/// Base exception class for OTP-related errors.
sealed class OtpException implements Exception {
  /// Human-readable error message.
  final String message;

  /// Technical error code for programmatic handling.
  final String code;

  /// Stack trace when the exception was created.
  final StackTrace? stackTrace;

  const OtpException({
    required this.message,
    required this.code,
    this.stackTrace,
  });

  @override
  String toString() => 'OtpException[$code]: $message';
}

/// Exception thrown when a platform-specific operation fails.
final class SmsOtpPlatformException extends OtpException {
  /// The platform where the error occurred.
  final String platform;

  /// Native error code from the platform.
  final String? nativeCode;

  const SmsOtpPlatformException({
    required super.message,
    required this.platform,
    this.nativeCode,
    super.stackTrace,
  }) : super(code: 'PLATFORM_ERROR');

  @override
  String toString() =>
      'SmsOtpPlatformException[$platform]: $message (native: $nativeCode)';
}

/// Exception thrown when permission is denied.
final class PermissionException extends OtpException {
  /// The permission that was denied.
  final String permission;

  /// Whether the permission was permanently denied.
  final bool isPermanentlyDenied;

  const PermissionException({
    required super.message,
    required this.permission,
    this.isPermanentlyDenied = false,
    super.stackTrace,
  }) : super(code: 'PERMISSION_DENIED');

  @override
  String toString() =>
      'PermissionException[$permission]: $message (permanent: $isPermanentlyDenied)';
}

/// Exception thrown when OTP detection times out.
final class TimeoutException extends OtpException {
  /// The configured timeout duration.
  final Duration timeout;

  const TimeoutException({
    required super.message,
    required this.timeout,
    super.stackTrace,
  }) : super(code: 'TIMEOUT');

  @override
  String toString() => 'TimeoutException[${timeout.inSeconds}s]: $message';
}

/// Exception thrown when OTP format is invalid.
final class InvalidOtpException extends OtpException {
  /// The invalid OTP value.
  final String? invalidValue;

  /// Expected OTP length.
  final int expectedLength;

  const InvalidOtpException({
    required super.message,
    this.invalidValue,
    required this.expectedLength,
    super.stackTrace,
  }) : super(code: 'INVALID_OTP');

  @override
  String toString() =>
      'InvalidOtpException: $message (expected $expectedLength digits)';
}

/// Exception thrown when rate limit is exceeded.
final class RateLimitException extends OtpException {
  /// Time remaining until next request is allowed.
  final Duration retryAfter;

  /// Number of attempts made.
  final int attemptsMade;

  /// Maximum attempts allowed.
  final int maxAttempts;

  const RateLimitException({
    required super.message,
    required this.retryAfter,
    required this.attemptsMade,
    required this.maxAttempts,
    super.stackTrace,
  }) : super(code: 'RATE_LIMITED');

  @override
  String toString() =>
      'RateLimitException: $message (retry in ${retryAfter.inSeconds}s, '
      '$attemptsMade/$maxAttempts attempts)';
}

/// Exception thrown when the service is not available.
final class ServiceUnavailableException extends OtpException {
  /// Whether the service might recover.
  final bool isRecoverable;

  const ServiceUnavailableException({
    required super.message,
    this.isRecoverable = true,
    super.stackTrace,
  }) : super(code: 'SERVICE_UNAVAILABLE');
}
