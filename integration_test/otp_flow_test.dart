// Integration test example for SMS OTP library
//
// To run integration tests:
// flutter test integration_test/
//
// For real device testing:
// flutter drive --target=integration_test/otp_flow_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sms_otp_pro/flutter_sms_otp_pro.dart';

void main() {
  // IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('OTP Flow Integration Tests', () {
    testWidgets('Complete OTP entry flow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Enter OTP'),
                  const SizedBox(height: 24),
                  OtpField(
                    length: 6,
                    style: OtpFieldStyle.rounded(),
                    onCompleted: (otp) {
                      debugPrint('OTP completed: $otp');
                    },
                  ),
                  const SizedBox(height: 24),
                  const CountdownTimer(
                    duration: Duration(seconds: 30),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify widgets are rendered
      expect(find.byType(OtpField), findsOneWidget);
      expect(find.byType(CountdownTimer), findsOneWidget);

      // Enter OTP digits
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(6));

      // Enter each digit
      await tester.enterText(textFields.at(0), '1');
      await tester.pumpAndSettle();

      await tester.enterText(textFields.at(1), '2');
      await tester.pumpAndSettle();

      await tester.enterText(textFields.at(2), '3');
      await tester.pumpAndSettle();

      await tester.enterText(textFields.at(3), '4');
      await tester.pumpAndSettle();

      await tester.enterText(textFields.at(4), '5');
      await tester.pumpAndSettle();

      await tester.enterText(textFields.at(5), '6');
      await tester.pumpAndSettle();

      // OTP should be complete now
      await tester.pumpAndSettle();
    });

    testWidgets('Phone number entry with validation', (tester) async {
      PhoneValidationResult? validationResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: PhoneField(
                initialCountryCode: '+1',
                showValidation: true,
                onValidated: (result) {
                  validationResult = result;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify PhoneField is rendered
      expect(find.byType(PhoneField), findsOneWidget);

      // Find phone number input field
      final textFields = find.byType(TextField);

      // Enter valid phone number
      await tester.enterText(textFields.last, '2025551234');
      await tester.pumpAndSettle();

      // Validation should have been called
      expect(validationResult, isNotNull);
    });

    testWidgets('All OTP style themes render correctly', (tester) async {
      final styles = [
        OtpFieldStyle.rounded(),
        OtpFieldStyle.underlined(),
        OtpFieldStyle.boxed(),
        OtpFieldStyle.circular(),
        OtpFieldStyle.glassmorphism(),
        OtpFieldStyle.dark(),
      ];

      for (final style in styles) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OtpField(
                length: 6,
                style: style,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // All styles should render without errors
        expect(find.byType(OtpField), findsOneWidget);
        expect(find.byType(TextField), findsNWidgets(6));
      }
    });

    testWidgets('OtpController state management', (tester) async {
      final controller = OtpController(
        config: const SmsOtpConfig(
          otpLength: 6,
          timeout: Duration(minutes: 5),
          maxRetries: 3,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                OtpField(
                  length: 6,
                  controller: controller,
                ),
                ValueListenableBuilder<OtpState>(
                  valueListenable: controller,
                  builder: (context, state, _) {
                    return Text('OTP: ${state.otp}');
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Set OTP via controller
      controller.setOtp('123456');
      await tester.pumpAndSettle();

      // State should be updated
      expect(controller.value.otp, '123456');
      expect(controller.value.isComplete, true);

      // Clear OTP
      controller.clear();
      await tester.pumpAndSettle();

      expect(controller.value.otp, '');
      expect(controller.value.isComplete, false);

      // Clean up
      controller.dispose();
    });
  });
}
