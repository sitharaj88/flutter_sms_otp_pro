import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sms_otp_pro/flutter_sms_otp_pro.dart';

void main() {
  group('CountdownTimer Widget Tests', () {
    testWidgets('renders countdown timer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CountdownTimer(
              duration: Duration(seconds: 30),
            ),
          ),
        ),
      );

      expect(find.byType(CountdownTimer), findsOneWidget);
    });

    testWidgets('shows countdown text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CountdownTimer(
              duration: Duration(seconds: 30),
              countdownText: 'Didn\'t receive the code?',
            ),
          ),
        ),
      );

      expect(find.text('Didn\'t receive the code?'), findsOneWidget);
    });

    testWidgets('calls onComplete when timer finishes', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownTimer(
              duration: const Duration(seconds: 1),
              onComplete: () => completed = true,
            ),
          ),
        ),
      );

      // Wait for timer to complete
      await tester.pump(const Duration(seconds: 2));

      expect(completed, true);
    });

    testWidgets('shows resend button after countdown', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CountdownTimer(
              duration: Duration(seconds: 1),
              resendText: 'Resend OTP',
            ),
          ),
        ),
      );

      // Wait for timer to complete
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Resend OTP'), findsOneWidget);
    });

    testWidgets('calls onResend when button pressed', (tester) async {
      bool resendCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownTimer(
              duration: const Duration(seconds: 1),
              onResend: () => resendCalled = true,
              resendText: 'Resend OTP',
            ),
          ),
        ),
      );

      // Wait for timer to complete
      await tester.pump(const Duration(seconds: 2));

      // Tap resend button
      await tester.tap(find.text('Resend OTP'));
      await tester.pump();

      expect(resendCalled, true);
    });

    testWidgets('uses custom builder when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownTimer(
              duration: const Duration(seconds: 30),
              builder: (remaining, canResend) {
                return Text('Custom: ${remaining.inSeconds}s');
              },
            ),
          ),
        ),
      );

      expect(find.textContaining('Custom:'), findsOneWidget);
    });
  });

  group('PhoneField Widget Tests', () {
    testWidgets('renders phone field', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhoneField(),
          ),
        ),
      );

      expect(find.byType(PhoneField), findsOneWidget);
    });

    testWidgets('shows label text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhoneField(
              labelText: 'Phone Number',
            ),
          ),
        ),
      );

      expect(find.text('Phone Number'), findsOneWidget);
    });

    testWidgets('shows hint text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhoneField(
              hintText: 'Enter phone number',
            ),
          ),
        ),
      );

      expect(find.text('Enter phone number'), findsOneWidget);
    });

    testWidgets('calls onChanged when text changes', (tester) async {
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneField(
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      // Find the phone input TextField
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      // Enter phone number in the phone field (skip country code field)
      await tester.enterText(textFields.last, '1234567890');
      await tester.pump();

      expect(changedValue, isNotNull);
    });

    testWidgets('shows country code by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhoneField(
              initialCountryCode: '+1',
            ),
          ),
        ),
      );

      expect(find.text('+1'), findsOneWidget);
    });
  });
}
