import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sms_otp_pro/src/core/otp_parser.dart';

void main() {
  group('OtpParser', () {
    group('extractOtp', () {
      test('extracts OTP from "Your code is 123456"', () {
        final otp = OtpParser.extractOtp('Your code is 123456');

        expect(otp, '123456');
      });

      test('extracts OTP from "Your OTP is: 123456"', () {
        final otp = OtpParser.extractOtp('Your OTP is: 123456');

        expect(otp, '123456');
      });

      test('extracts OTP from "123456 is your verification code"', () {
        final otp = OtpParser.extractOtp('123456 is your verification code');

        expect(otp, '123456');
      });

      test('extracts OTP from SMS Retriever format', () {
        final otp = OtpParser.extractOtp(
          '<#> Your verification code is 123456\n\nAbCdEfGhIjK',
        );

        expect(otp, '123456');
      });

      test('extracts OTP from "Code: 123456"', () {
        final otp = OtpParser.extractOtp('Code: 123456');

        expect(otp, '123456');
      });

      test('extracts OTP from "PIN - 1234"', () {
        final otp = OtpParser.extractOtp('PIN - 1234', expectedLength: 4);

        expect(otp, '1234');
      });

      test('returns null for message without OTP', () {
        final otp = OtpParser.extractOtp('Hello, how are you?');

        expect(otp, isNull);
      });

      test('returns null for empty message', () {
        final otp = OtpParser.extractOtp('');

        expect(otp, isNull);
      });

      test('respects expected length', () {
        final otp = OtpParser.extractOtp(
          'Your code is 123456',
          expectedLength: 4,
        );

        expect(otp, isNull); // Should not match 6-digit code
      });

      test('uses custom pattern when provided', () {
        final otp = OtpParser.extractOtp(
          'Token: ABC123',
          customPattern: r'Token:\s*([A-Z0-9]+)',
        );

        // Custom pattern might not be digits-only
        expect(otp, isNull); // Our validation requires digits
      });

      test('extracts 8-digit OTP', () {
        final otp = OtpParser.extractOtp(
          'Your verification code is 12345678',
          expectedLength: 8,
        );

        expect(otp, '12345678');
      });
    });

    group('containsOtp', () {
      test('returns true for message with OTP', () {
        final result = OtpParser.containsOtp('Your code is 123456');

        expect(result, true);
      });

      test('returns false for message without OTP', () {
        final result = OtpParser.containsOtp('Hello world');

        expect(result, false);
      });
    });

    group('extractAllPotentialOtps', () {
      test('extracts multiple OTPs from message', () {
        final otps = OtpParser.extractAllPotentialOtps(
          'Your code is 123456 or try backup code 654321',
        );

        expect(otps, containsAll(['123456', '654321']));
      });

      test('returns empty list for message without OTPs', () {
        final otps = OtpParser.extractAllPotentialOtps('Hello world');

        expect(otps, isEmpty);
      });
    });

    group('detectFormat', () {
      test('detects SMS Retriever format', () {
        final format = OtpParser.detectFormat('<#> Your code is 123456');

        expect(format, OtpMessageFormat.smsRetriever);
      });

      test('detects verification format', () {
        final format = OtpParser.detectFormat(
          'Your verification code is 123456',
        );

        expect(format, OtpMessageFormat.verification);
      });

      test('detects login format', () {
        final format = OtpParser.detectFormat(
          'Your login code is 123456',
        );

        expect(format, OtpMessageFormat.login);
      });

      test('detects transaction format', () {
        final format = OtpParser.detectFormat(
          'Your transaction OTP is 123456',
        );

        expect(format, OtpMessageFormat.transaction);
      });

      test('detects password reset format', () {
        final format = OtpParser.detectFormat(
          'Password reset code: 123456',
        );

        expect(format, OtpMessageFormat.passwordReset);
      });

      test('returns unknown for unrecognized format', () {
        final format = OtpParser.detectFormat('Hello 123456');

        expect(format, OtpMessageFormat.unknown);
      });
    });
  });
}
