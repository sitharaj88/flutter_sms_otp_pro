import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sms_otp_pro/flutter_sms_otp_pro.dart';

void main() {
  group('OtpField Widget Tests', () {
    testWidgets('renders correct number of fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OtpField(length: 6),
          ),
        ),
      );

      // Should have 6 text fields + 1 hidden field for iOS autofill
      expect(find.byType(TextField), findsNWidgets(7));
    });

    testWidgets('renders 4 fields when length is 4', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OtpField(length: 4),
          ),
        ),
      );

      // Should have 4 text fields + 1 hidden field
      expect(find.byType(TextField), findsNWidgets(5));
    });

    testWidgets('calls onChanged when digit entered', (tester) async {
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpField(
              length: 6,
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      // Enter a digit in first visible field (index 1, as index 0 is hidden)
      await tester.enterText(find.byType(TextField).at(1), '1');
      await tester.pump();

      expect(changedValue, '1');
    });

    testWidgets('calls onCompleted when all digits entered', (tester) async {
      String? completedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpField(
              length: 4,
              onCompleted: (value) => completedValue = value,
            ),
          ),
        ),
      );

      // Enter digits in each visible field (skipping index 0)
      final fields = find.byType(TextField);
      for (int i = 0; i < 4; i++) {
        await tester.enterText(fields.at(i + 1), '${i + 1}');
        await tester.pump();
      }

      expect(completedValue, '1234');
    });

    testWidgets('displays error message when hasError is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OtpField(
              length: 6,
              hasError: true,
              errorMessage: 'Invalid OTP',
            ),
          ),
        ),
      );

      expect(find.text('Invalid OTP'), findsOneWidget);
    });

    testWidgets('fields are disabled when enabled is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OtpField(
              length: 6,
              enabled: false,
            ),
          ),
        ),
      );

      // All TextFields (including hidden one) should be disabled
      // Use at(1) to check a visible field
      final textField = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(textField.enabled, false);
    });

    testWidgets('applies rounded style correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpField(
              length: 6,
              style: OtpFieldStyle.rounded(),
            ),
          ),
        ),
      );

      // Widget should render without errors
      expect(find.byType(OtpField), findsOneWidget);
    });

    testWidgets('applies glassmorphism style correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpField(
              length: 6,
              style: OtpFieldStyle.glassmorphism(),
            ),
          ),
        ),
      );

      expect(find.byType(OtpField), findsOneWidget);
    });

    testWidgets('applies dark style correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpField(
              length: 6,
              style: OtpFieldStyle.dark(),
            ),
          ),
        ),
      );

      expect(find.byType(OtpField), findsOneWidget);
    });
  });

  group('OtpFieldStyle', () {
    test('rounded factory creates valid style', () {
      final style = OtpFieldStyle.rounded();

      expect(style.fieldWidth, isNotNull);
      expect(style.fieldHeight, isNotNull);
      expect(style.gap, greaterThan(0));
    });

    test('underlined factory creates valid style', () {
      final style = OtpFieldStyle.underlined();

      expect(style.fieldWidth, isNotNull);
      expect(style.fieldHeight, isNotNull);
      expect(style.gap, greaterThan(0));
    });

    test('boxed factory creates valid style', () {
      final style = OtpFieldStyle.boxed();

      expect(style.fieldWidth, isNotNull);
      expect(style.fieldHeight, isNotNull);
    });

    test('circular factory creates valid style', () {
      final style = OtpFieldStyle.circular();

      expect(style.fieldWidth, isNotNull);
      expect(style.fieldHeight, isNotNull);
    });

    test('glassmorphism factory creates valid style', () {
      final style = OtpFieldStyle.glassmorphism();

      expect(style.fieldWidth, isNotNull);
      expect(style.fieldHeight, isNotNull);
    });

    test('dark factory creates valid style', () {
      final style = OtpFieldStyle.dark();

      expect(style.fieldWidth, isNotNull);
      expect(style.fieldHeight, isNotNull);
    });

    test('copyWith creates modified copy', () {
      final original = OtpFieldStyle.rounded();
      final modified = original.copyWith(
        fieldWidth: 60,
        gap: 16,
      );

      expect(modified.fieldWidth, 60);
      expect(modified.gap, 16);
      // Unchanged values
      expect(modified.fieldHeight, original.fieldHeight);
    });
  });
}
