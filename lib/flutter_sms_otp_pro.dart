/// SMS OTP - Enterprise-grade SMS OTP library for Flutter
///
/// A comprehensive Flutter plugin for SMS OTP verification with:
/// - Auto-read SMS on Android via SMS Retriever API
/// - Native iOS autofill support
/// - Beautiful, customizable OTP input widgets
/// - Phone number validation and formatting
/// - State management with retry logic
/// - Full accessibility support
///
/// ## Quick Start
///
/// ```dart
/// import 'package:flutter_sms_otp_pro/flutter_sms_otp_pro.dart';
///
/// // Simple OTP input
/// OtpField(
///   length: 6,
///   onCompleted: (otp) => verifyOtp(otp),
/// )
///
/// // With custom styling
/// OtpField(
///   length: 6,
///   style: OtpFieldStyle.glassmorphism(),
///   autoListen: true,
///   onCompleted: (otp) => verifyOtp(otp),
/// )
/// ```
///
/// ## Features
///
/// - **OtpField**: Customizable OTP input widget with multiple style presets
/// - **PhoneField**: International phone number input with country picker
/// - **CountdownTimer**: Animated countdown for OTP resend
/// - **OtpController**: State management for OTP operations
/// - **PhoneValidator**: International phone number validation
/// - **OtpParser**: Intelligent OTP extraction from SMS messages
library flutter_sms_otp_pro;

// Core
export 'src/core/otp_parser.dart';
export 'src/core/otp_result.dart';
export 'src/core/phone_validator.dart';
export 'src/core/sms_otp_config.dart';

// Services
export 'src/services/platform_service.dart' show PermissionStatus;

// State
export 'src/state/otp_controller.dart';

// Widgets
export 'src/widgets/countdown_timer.dart';
export 'src/widgets/otp_field.dart';
export 'src/widgets/otp_field_style.dart';
export 'src/widgets/phone_field.dart';
