import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sms_otp_pro/src/core/sms_otp_config.dart';

void main() {
  group('SmsOtpConfig', () {
    test('creates with default values', () {
      const config = SmsOtpConfig();

      expect(config.otpLength, 6);
      expect(config.timeout, const Duration(minutes: 5));
      expect(config.maxRetries, 3);
      expect(config.retryCooldown, const Duration(seconds: 30));
      expect(config.autoSubmit, true);
      expect(config.senderFilter, isNull);
      expect(config.hapticFeedback, true);
      expect(config.obscureText, false);
    });

    test('creates with custom values', () {
      const config = SmsOtpConfig(
        otpLength: 4,
        timeout: Duration(minutes: 2),
        maxRetries: 5,
        retryCooldown: Duration(seconds: 60),
        autoSubmit: false,
        senderFilter: '+1234567890',
        hapticFeedback: false,
        obscureText: true,
      );

      expect(config.otpLength, 4);
      expect(config.timeout, const Duration(minutes: 2));
      expect(config.maxRetries, 5);
      expect(config.retryCooldown, const Duration(seconds: 60));
      expect(config.autoSubmit, false);
      expect(config.senderFilter, '+1234567890');
      expect(config.hapticFeedback, false);
      expect(config.obscureText, true);
    });

    test('copyWith creates modified copy', () {
      const original = SmsOtpConfig();
      final modified = original.copyWith(
        otpLength: 8,
        autoSubmit: false,
      );

      expect(modified.otpLength, 8);
      expect(modified.autoSubmit, false);
      // Unchanged values
      expect(modified.timeout, original.timeout);
      expect(modified.maxRetries, original.maxRetries);
    });

    test('equality works correctly', () {
      const config1 = SmsOtpConfig();
      const config2 = SmsOtpConfig();
      const config3 = SmsOtpConfig(otpLength: 8);

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('hashCode is consistent', () {
      const config1 = SmsOtpConfig();
      const config2 = SmsOtpConfig();

      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('toString returns readable string', () {
      const config = SmsOtpConfig();
      final string = config.toString();

      expect(string, contains('SmsOtpConfig'));
      expect(string, contains('otpLength: 6'));
    });
  });
}
