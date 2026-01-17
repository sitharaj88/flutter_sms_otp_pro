import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sms_otp_pro/src/core/phone_validator.dart';

void main() {
  group('PhoneValidator', () {
    group('validate', () {
      test('returns invalid for empty string', () {
        final result = PhoneValidator.validate('');

        expect(result.isValid, false);
        expect(result.error, PhoneValidationError.empty);
      });

      test('returns invalid for string with invalid characters', () {
        final result = PhoneValidator.validate('+1abc123');

        expect(result.isValid, false);
        expect(result.error, PhoneValidationError.invalidCharacters);
      });

      test('validates US phone number', () {
        final result = PhoneValidator.validate('+12025551234');

        expect(result.isValid, true);
        expect(result.countryCode, '+1');
        expect(result.countryName, 'US/Canada');
        expect(result.nationalNumber, '2025551234');
      });

      test('validates UK phone number', () {
        final result = PhoneValidator.validate('+447911123456');

        expect(result.isValid, true);
        expect(result.countryCode, '+44');
        expect(result.countryName, 'UK');
      });

      test('validates Indian phone number', () {
        final result = PhoneValidator.validate('+919876543210');

        expect(result.isValid, true);
        expect(result.countryCode, '+91');
        expect(result.countryName, 'India');
        expect(result.nationalNumber, '9876543210');
      });

      test('returns invalid for too short number', () {
        final result = PhoneValidator.validate('+1202');

        expect(result.isValid, false);
        expect(result.error, PhoneValidationError.tooShort);
      });

      test('returns invalid for too long number', () {
        final result = PhoneValidator.validate('+1202555123456789');

        expect(result.isValid, false);
        expect(result.error, PhoneValidationError.tooLong);
      });

      test('cleans phone number with formatting', () {
        final result = PhoneValidator.validate('+1 (202) 555-1234');

        expect(result.isValid, true);
        expect(result.nationalNumber, '2025551234');
      });

      test('validates number without country code', () {
        final result = PhoneValidator.validate('2025551234');

        expect(result.isValid, true);
        expect(result.countryCode, isNull);
      });
    });

    group('toE164', () {
      test('returns phone number if already E.164', () {
        final result = PhoneValidator.toE164('+12025551234');

        expect(result, '+12025551234');
      });

      test('adds default country code', () {
        final result = PhoneValidator.toE164(
          '2025551234',
          defaultCountryCode: '+1',
        );

        expect(result, '+12025551234');
      });

      test('returns null without country code or default', () {
        final result = PhoneValidator.toE164('2025551234');

        expect(result, isNull);
      });
    });

    group('supportedCountries', () {
      test('returns list of supported countries', () {
        final countries = PhoneValidator.supportedCountries;

        expect(countries.isNotEmpty, true);
        expect(countries.any((c) => c.code == '+1'), true);
        expect(countries.any((c) => c.code == '+44'), true);
        expect(countries.any((c) => c.code == '+91'), true);
      });
    });
  });
}
