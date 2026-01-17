import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/otp_result.dart';
import '../core/sms_otp_config.dart';
import '../services/platform_service.dart';

/// Represents the current state of OTP operations.
@immutable
class OtpState {
  /// The current OTP value (may be partial).
  final String otp;

  /// Whether OTP listening is active.
  final bool isListening;

  /// Whether the OTP is complete (all digits filled).
  final bool isComplete;

  /// Whether an error has occurred.
  final bool hasError;

  /// The error message if any.
  final String? errorMessage;

  /// The current retry count.
  final int retryCount;

  /// Whether the user can request a new OTP.
  final bool canRetry;

  /// Time remaining until retry is allowed.
  final Duration? retryWaitTime;

  /// Timestamp when the current OTP operation started.
  final DateTime? startedAt;

  /// The last received OTP result.
  final OtpResult? lastResult;

  const OtpState({
    this.otp = '',
    this.isListening = false,
    this.isComplete = false,
    this.hasError = false,
    this.errorMessage,
    this.retryCount = 0,
    this.canRetry = true,
    this.retryWaitTime,
    this.startedAt,
    this.lastResult,
  });

  /// Creates a copy with modified fields.
  OtpState copyWith({
    String? otp,
    bool? isListening,
    bool? isComplete,
    bool? hasError,
    String? errorMessage,
    int? retryCount,
    bool? canRetry,
    Duration? retryWaitTime,
    DateTime? startedAt,
    OtpResult? lastResult,
  }) {
    return OtpState(
      otp: otp ?? this.otp,
      isListening: isListening ?? this.isListening,
      isComplete: isComplete ?? this.isComplete,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      canRetry: canRetry ?? this.canRetry,
      retryWaitTime: retryWaitTime ?? this.retryWaitTime,
      startedAt: startedAt ?? this.startedAt,
      lastResult: lastResult ?? this.lastResult,
    );
  }

  /// Initial state factory.
  factory OtpState.initial() => const OtpState();

  /// Loading state factory.
  factory OtpState.listening() => const OtpState(
        isListening: true,
        startedAt: null, // Will be set by controller
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OtpState &&
        other.otp == otp &&
        other.isListening == isListening &&
        other.isComplete == isComplete &&
        other.hasError == hasError &&
        other.errorMessage == errorMessage &&
        other.retryCount == retryCount &&
        other.canRetry == canRetry;
  }

  @override
  int get hashCode => Object.hash(
        otp,
        isListening,
        isComplete,
        hasError,
        errorMessage,
        retryCount,
        canRetry,
      );

  @override
  String toString() => 'OtpState(otp: ${otp.isEmpty ? "empty" : "***"}, '
      'isListening: $isListening, isComplete: $isComplete, '
      'retryCount: $retryCount)';
}

/// Controller for managing OTP state and operations.
///
/// This controller handles the full lifecycle of OTP operations including:
/// - Starting/stopping SMS listeners
/// - Managing OTP input state
/// - Handling retries with cooldown
/// - Error recovery
class OtpController extends ValueNotifier<OtpState> {
  /// Configuration for OTP behavior.
  final SmsOtpConfig config;

  /// Platform service for SMS operations.
  final SmsOtpPlatformService _platformService;

  StreamSubscription<OtpResult>? _subscription;
  Timer? _retryTimer;
  Timer? _countdownTimer;

  /// Creates a new [OtpController] with the given configuration.
  OtpController({
    SmsOtpConfig? config,
    SmsOtpPlatformService? platformService,
  })  : config = config ?? const SmsOtpConfig(),
        _platformService = platformService ?? SmsOtpPlatformServiceImpl(),
        super(OtpState.initial());

  /// Whether the platform supports automatic SMS reading.
  bool get supportsAutoRead => _platformService.supportsAutoRead;

  /// Gets the app signature for SMS Retriever API.
  ///
  /// This is needed to include in your SMS message for automatic
  /// OTP detection on Android.
  Future<String?> getAppSignature() => _platformService.getAppSignature();

  /// Starts listening for incoming OTP SMS.
  ///
  /// Call this when you send the OTP request to your server.
  Future<void> startListening() async {
    if (value.isListening) return;

    // Check retry limit
    if (value.retryCount >= config.maxRetries && !value.canRetry) {
      value = value.copyWith(
        hasError: true,
        errorMessage: 'Maximum retry limit reached. Please try again later.',
      );
      return;
    }

    value = value.copyWith(
      isListening: true,
      hasError: false,
      errorMessage: null,
      startedAt: DateTime.now(),
    );

    final stream = _platformService.startListening(config);

    _subscription = stream.listen(
      _handleResult,
      onError: (error) {
        value = value.copyWith(
          isListening: false,
          hasError: true,
          errorMessage: error.toString(),
        );
      },
      onDone: () {
        if (value.isListening) {
          value = value.copyWith(isListening: false);
        }
      },
    );
  }

  void _handleResult(OtpResult result) {
    result.when(
      success: (otp) {
        value = value.copyWith(
          otp: otp,
          isListening: false,
          isComplete: otp.length >= config.otpLength,
          lastResult: result,
        );
      },
      timeout: (message) {
        value = value.copyWith(
          isListening: false,
          hasError: true,
          errorMessage: message,
          lastResult: result,
        );
      },
      error: (exception) {
        value = value.copyWith(
          isListening: false,
          hasError: true,
          errorMessage: exception.message,
          lastResult: result,
        );
      },
      cancelled: () {
        value = value.copyWith(
          isListening: false,
          lastResult: result,
        );
      },
    );
  }

  /// Stops the SMS listener.
  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
    await _platformService.stopListening();
    value = value.copyWith(isListening: false);
  }

  /// Sets the OTP value manually.
  ///
  /// Use this when the user types the OTP manually.
  void setOtp(String otp) {
    final sanitized = otp.replaceAll(RegExp(r'[^0-9]'), '');
    final truncated = sanitized.length > config.otpLength
        ? sanitized.substring(0, config.otpLength)
        : sanitized;

    value = value.copyWith(
      otp: truncated,
      isComplete: truncated.length >= config.otpLength,
      hasError: false,
      errorMessage: null,
    );
  }

  /// Appends a digit to the current OTP.
  void appendDigit(String digit) {
    if (value.otp.length >= config.otpLength) return;
    if (!RegExp(r'^[0-9]$').hasMatch(digit)) return;

    setOtp(value.otp + digit);
  }

  /// Removes the last digit from the OTP.
  void removeLastDigit() {
    if (value.otp.isEmpty) return;
    setOtp(value.otp.substring(0, value.otp.length - 1));
  }

  /// Clears the current OTP.
  void clear() {
    value = value.copyWith(
      otp: '',
      isComplete: false,
      hasError: false,
      errorMessage: null,
    );
  }

  /// Requests a new OTP (increments retry count).
  Future<void> requestNewOtp() async {
    if (!value.canRetry) {
      return;
    }

    final newRetryCount = value.retryCount + 1;
    final canRetryAgain = newRetryCount < config.maxRetries;

    value = value.copyWith(
      otp: '',
      isComplete: false,
      hasError: false,
      errorMessage: null,
      retryCount: newRetryCount,
      canRetry: false,
      retryWaitTime: config.retryCooldown,
    );

    // Start cooldown timer
    _startCooldownTimer(canRetryAgain);

    // Start listening for new OTP
    await startListening();
  }

  void _startCooldownTimer(bool enableRetryAfter) {
    _retryTimer?.cancel();
    _countdownTimer?.cancel();

    var remaining = config.retryCooldown;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining -= const Duration(seconds: 1);
      if (remaining.inSeconds <= 0) {
        timer.cancel();
        if (enableRetryAfter) {
          value = value.copyWith(
            canRetry: true,
            retryWaitTime: null,
          );
        }
      } else {
        value = value.copyWith(retryWaitTime: remaining);
      }
    });
  }

  /// Validates the current OTP.
  ///
  /// Returns true if the OTP is complete and valid.
  bool validate() {
    if (value.otp.length != config.otpLength) {
      value = value.copyWith(
        hasError: true,
        errorMessage: 'Please enter all ${config.otpLength} digits',
      );
      return false;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(value.otp)) {
      value = value.copyWith(
        hasError: true,
        errorMessage: 'OTP must contain only digits',
      );
      return false;
    }

    return true;
  }

  /// Resets the controller to initial state.
  void reset() {
    stopListening();
    _retryTimer?.cancel();
    _countdownTimer?.cancel();
    value = OtpState.initial();
  }

  @override
  void dispose() {
    stopListening();
    _retryTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
