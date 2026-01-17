import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/otp_result.dart';
import '../core/sms_otp_config.dart';

/// Abstract interface for platform-specific SMS operations.
///
/// This class defines the contract that platform implementations must fulfill
/// for SMS OTP functionality across Android and iOS.
abstract class SmsOtpPlatformService {
  /// Starts listening for incoming SMS messages containing OTP.
  ///
  /// Returns a stream of [OtpResult] objects representing received OTPs
  /// or errors that occur during listening.
  Stream<OtpResult> startListening(SmsOtpConfig config);

  /// Stops the SMS listener.
  Future<void> stopListening();

  /// Gets the app signature for SMS Retriever API (Android only).
  ///
  /// Returns the app signature hash that should be included in the SMS
  /// for automatic retrieval without user interaction.
  Future<String?> getAppSignature();

  /// Checks if SMS listening is currently active.
  bool get isListening;

  /// Checks if the platform supports automatic SMS reading.
  bool get supportsAutoRead;

  /// Requests necessary permissions for SMS operations.
  Future<PermissionStatus> requestPermissions();
}

/// Permission status for SMS operations.
enum PermissionStatus {
  /// Permission is granted.
  granted,

  /// Permission is denied.
  denied,

  /// Permission is permanently denied (user must enable in settings).
  permanentlyDenied,

  /// Permission is not required on this platform.
  notRequired,
}

/// Default implementation of [SmsOtpPlatformService] using method channels.
class SmsOtpPlatformServiceImpl implements SmsOtpPlatformService {
  static const MethodChannel _channel = MethodChannel('sms_otp');
  static const EventChannel _eventChannel = EventChannel('sms_otp/events');

  bool _isListening = false;
  StreamSubscription<dynamic>? _subscription;
  StreamController<OtpResult>? _resultController;

  @override
  bool get isListening => _isListening;

  @override
  bool get supportsAutoRead {
    // iOS uses native autofill, not SMS reading
    // Android supports auto-read via SMS Retriever API
    return defaultTargetPlatform == TargetPlatform.android;
  }

  @override
  Stream<OtpResult> startListening(SmsOtpConfig config) {
    if (_isListening) {
      return _resultController?.stream ?? const Stream.empty();
    }

    _resultController = StreamController<OtpResult>.broadcast(
      onCancel: () async {
        await stopListening();
      },
    );

    _startNativeListener(config);
    return _resultController!.stream;
  }

  Future<void> _startNativeListener(SmsOtpConfig config) async {
    _isListening = true;

    try {
      // Start the native SMS listener
      await _channel.invokeMethod('startListening', {
        'timeout': config.timeout.inMilliseconds,
        'sender': config.senderFilter,
        'otpLength': config.otpLength,
      });

      // Listen for events from the native side
      _subscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            _handleEvent(event, config);
          }
        },
        onError: (error) {
          _resultController?.add(OtpError(
            SmsOtpPlatformException(
              message: error.toString(),
              platform: defaultTargetPlatform.name,
            ),
          ));
        },
        onDone: () {
          _isListening = false;
        },
      );

      // Set up timeout
      Future.delayed(config.timeout, () {
        if (_isListening) {
          _resultController?.add(OtpTimeout(
            message:
                'OTP verification timed out after ${config.timeout.inMinutes} minutes',
            configuredTimeout: config.timeout,
          ));
          stopListening();
        }
      });
    } on PlatformException catch (e) {
      _resultController?.add(OtpError(
        SmsOtpPlatformException(
          message: e.message ?? 'Unknown platform error',
          platform: defaultTargetPlatform.name,
          nativeCode: e.code,
        ),
      ));
      _isListening = false;
    }
  }

  void _handleEvent(Map<dynamic, dynamic> event, SmsOtpConfig config) {
    final type = event['type'] as String?;

    switch (type) {
      case 'otp_received':
        final otp = event['otp'] as String?;
        final message = event['message'] as String?;
        final sender = event['sender'] as String?;

        if (otp != null) {
          _resultController?.add(OtpSuccess(
            otp: otp,
            rawMessage: message,
            sender: sender,
          ));
        }
        break;

      case 'timeout':
        _resultController?.add(OtpTimeout(
          message: event['message'] as String? ?? 'Timeout',
          configuredTimeout: config.timeout,
        ));
        break;

      case 'cancelled':
        _resultController?.add(OtpCancelled(
          reason: event['reason'] as String?,
        ));
        break;

      case 'error':
        _resultController?.add(OtpError(
          SmsOtpPlatformException(
            message: event['message'] as String? ?? 'Unknown error',
            platform: defaultTargetPlatform.name,
            nativeCode: event['code'] as String?,
          ),
        ));
        break;
    }
  }

  @override
  Future<void> stopListening() async {
    if (!_isListening) return;

    _isListening = false;
    await _subscription?.cancel();
    _subscription = null;
    await _resultController?.close();
    _resultController = null;

    try {
      await _channel.invokeMethod('stopListening');
    } catch (_) {
      // Ignore errors when stopping
    }
  }

  @override
  Future<String?> getAppSignature() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    try {
      return await _channel.invokeMethod<String>('getAppSignature');
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<PermissionStatus> requestPermissions() async {
    // SMS Retriever API doesn't require explicit SMS permissions
    // The User Consent API requires user interaction but not permissions
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return PermissionStatus.notRequired;
    }

    try {
      final result = await _channel.invokeMethod<String>('requestPermissions');
      return switch (result) {
        'granted' => PermissionStatus.granted,
        'denied' => PermissionStatus.denied,
        'permanently_denied' => PermissionStatus.permanentlyDenied,
        _ => PermissionStatus.notRequired,
      };
    } catch (_) {
      return PermissionStatus.notRequired;
    }
  }
}
