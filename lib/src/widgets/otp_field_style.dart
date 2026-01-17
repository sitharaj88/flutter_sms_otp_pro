import 'package:flutter/material.dart';

/// Styling configuration for [OtpField] widget.
///
/// Provides comprehensive customization options for OTP input fields
/// with pre-built theme presets for common designs.
class OtpFieldStyle {
  /// Decoration for the currently focused field.
  final BoxDecoration activeDecoration;

  /// Decoration for unfocused empty fields.
  final BoxDecoration inactiveDecoration;

  /// Decoration for fields with errors.
  final BoxDecoration errorDecoration;

  /// Decoration for fields that have been filled.
  final BoxDecoration filledDecoration;

  /// Decoration for the selected field (cursor position).
  final BoxDecoration? selectedDecoration;

  /// Text style for the OTP digits.
  final TextStyle textStyle;

  /// Text style for error OTP digits.
  final TextStyle? errorTextStyle;

  /// Width of each input field.
  final double fieldWidth;

  /// Height of each input field.
  final double fieldHeight;

  /// Gap between input fields.
  final double gap;

  /// Border radius for the fields.
  final BorderRadius borderRadius;

  /// Animation curve for field transitions.
  final Curve animationCurve;

  /// Animation duration for field transitions.
  final Duration animationDuration;

  /// Background color for the entire input area.
  final Color? backgroundColor;

  /// Shadow configuration for fields.
  final List<BoxShadow>? shadows;

  /// Cursor color for the active field.
  final Color cursorColor;

  /// Whether to show a blinking cursor in the active field.
  final bool showCursor;

  /// Character to use when obscuring text.
  final String obscureCharacter;

  const OtpFieldStyle({
    required this.activeDecoration,
    required this.inactiveDecoration,
    required this.errorDecoration,
    required this.filledDecoration,
    this.selectedDecoration,
    required this.textStyle,
    this.errorTextStyle,
    this.fieldWidth = 50,
    this.fieldHeight = 56,
    this.gap = 12,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.animationCurve = Curves.easeInOut,
    this.animationDuration = const Duration(milliseconds: 200),
    this.backgroundColor,
    this.shadows,
    this.cursorColor = Colors.blue,
    this.showCursor = true,
    this.obscureCharacter = '●',
  });

  /// Creates a copy with modified fields.
  OtpFieldStyle copyWith({
    BoxDecoration? activeDecoration,
    BoxDecoration? inactiveDecoration,
    BoxDecoration? errorDecoration,
    BoxDecoration? filledDecoration,
    BoxDecoration? selectedDecoration,
    TextStyle? textStyle,
    TextStyle? errorTextStyle,
    double? fieldWidth,
    double? fieldHeight,
    double? gap,
    BorderRadius? borderRadius,
    Curve? animationCurve,
    Duration? animationDuration,
    Color? backgroundColor,
    List<BoxShadow>? shadows,
    Color? cursorColor,
    bool? showCursor,
    String? obscureCharacter,
  }) {
    return OtpFieldStyle(
      activeDecoration: activeDecoration ?? this.activeDecoration,
      inactiveDecoration: inactiveDecoration ?? this.inactiveDecoration,
      errorDecoration: errorDecoration ?? this.errorDecoration,
      filledDecoration: filledDecoration ?? this.filledDecoration,
      selectedDecoration: selectedDecoration ?? this.selectedDecoration,
      textStyle: textStyle ?? this.textStyle,
      errorTextStyle: errorTextStyle ?? this.errorTextStyle,
      fieldWidth: fieldWidth ?? this.fieldWidth,
      fieldHeight: fieldHeight ?? this.fieldHeight,
      gap: gap ?? this.gap,
      borderRadius: borderRadius ?? this.borderRadius,
      animationCurve: animationCurve ?? this.animationCurve,
      animationDuration: animationDuration ?? this.animationDuration,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      shadows: shadows ?? this.shadows,
      cursorColor: cursorColor ?? this.cursorColor,
      showCursor: showCursor ?? this.showCursor,
      obscureCharacter: obscureCharacter ?? this.obscureCharacter,
    );
  }

  // ============================================================
  // PRESET THEMES
  // ============================================================

  /// Modern rounded box style with subtle shadows.
  ///
  /// Best for: Clean, modern UI designs.
  static OtpFieldStyle rounded({
    Color primaryColor = const Color(0xFF2196F3),
    Color backgroundColor = Colors.white,
    Color textColor = const Color(0xFF1A1A1A),
    Color errorColor = const Color(0xFFE53935),
  }) {
    return OtpFieldStyle(
      activeDecoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: primaryColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      inactiveDecoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      errorDecoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: errorColor, width: 2),
      ),
      filledDecoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border:
            Border.all(color: primaryColor.withValues(alpha: 0.5), width: 1.5),
      ),
      textStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 2,
      ),
      errorTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: errorColor,
        letterSpacing: 2,
      ),
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      cursorColor: primaryColor,
      fieldWidth: 52,
      fieldHeight: 60,
      gap: 14,
    );
  }

  /// Underlined style with animated bottom border.
  ///
  /// Best for: Minimalist designs, forms with limited space.
  static OtpFieldStyle underlined({
    Color primaryColor = const Color(0xFF6C63FF),
    Color textColor = const Color(0xFF1A1A1A),
    Color errorColor = const Color(0xFFE53935),
  }) {
    return OtpFieldStyle(
      activeDecoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: primaryColor, width: 3),
        ),
      ),
      inactiveDecoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 2),
        ),
      ),
      errorDecoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: errorColor, width: 3),
        ),
      ),
      filledDecoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: primaryColor.withValues(alpha: 0.5), width: 2),
        ),
      ),
      textStyle: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      errorTextStyle: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: errorColor,
      ),
      borderRadius: BorderRadius.zero,
      cursorColor: primaryColor,
      fieldWidth: 40,
      fieldHeight: 56,
      gap: 16,
      showCursor: false,
    );
  }

  /// Boxed style with sharp corners.
  ///
  /// Best for: Corporate/enterprise applications.
  static OtpFieldStyle boxed({
    Color primaryColor = const Color(0xFF1976D2),
    Color backgroundColor = Colors.white,
    Color textColor = const Color(0xFF1A1A1A),
    Color errorColor = const Color(0xFFD32F2F),
  }) {
    return OtpFieldStyle(
      activeDecoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        border: Border.all(color: primaryColor, width: 2),
      ),
      inactiveDecoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      errorDecoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        border: Border.all(color: errorColor, width: 2),
      ),
      filledDecoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        border: Border.all(color: primaryColor, width: 1),
      ),
      textStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: textColor,
        fontFamily: 'monospace',
      ),
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      cursorColor: primaryColor,
      fieldWidth: 48,
      fieldHeight: 54,
      gap: 10,
    );
  }

  /// Circular/pill style for playful designs.
  ///
  /// Best for: Consumer apps, gaming, entertainment.
  static OtpFieldStyle circular({
    Color primaryColor = const Color(0xFF00BFA5),
    Color backgroundColor = Colors.white,
    Color textColor = const Color(0xFF1A1A1A),
    Color errorColor = const Color(0xFFFF5252),
  }) {
    return OtpFieldStyle(
      activeDecoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: primaryColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      inactiveDecoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      errorDecoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: errorColor, width: 3),
      ),
      filledDecoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: primaryColor, width: 2),
      ),
      textStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      borderRadius:
          BorderRadius.zero, // Cannot have borderRadius with BoxShape.circle
      cursorColor: primaryColor,
      fieldWidth: 54,
      fieldHeight: 54,
      gap: 14,
      showCursor: false,
    );
  }

  /// Glassmorphism style with frosted glass effect.
  ///
  /// Best for: Modern iOS-style apps, premium designs.
  static OtpFieldStyle glassmorphism({
    Color primaryColor = const Color(0xFF6366F1),
    Color textColor = Colors.white,
    Color errorColor = const Color(0xFFF87171),
  }) {
    return OtpFieldStyle(
      activeDecoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      inactiveDecoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      errorDecoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: errorColor, width: 2),
      ),
      filledDecoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      textStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
          ),
        ],
      ),
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      cursorColor: Colors.white,
      fieldWidth: 54,
      fieldHeight: 62,
      gap: 12,
      backgroundColor: Colors.transparent,
    );
  }

  /// Dark theme style.
  ///
  /// Best for: Dark mode applications.
  static OtpFieldStyle dark({
    Color primaryColor = const Color(0xFF8B5CF6),
    Color backgroundColor = const Color(0xFF1F2937),
    Color textColor = Colors.white,
    Color errorColor = const Color(0xFFEF4444),
  }) {
    return OtpFieldStyle(
      activeDecoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: primaryColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      inactiveDecoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: const Color(0xFF4B5563), width: 1),
      ),
      errorDecoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: errorColor, width: 2),
      ),
      filledDecoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border:
            Border.all(color: primaryColor.withValues(alpha: 0.5), width: 1),
      ),
      textStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      errorTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: errorColor,
      ),
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      cursorColor: primaryColor,
      fieldWidth: 50,
      fieldHeight: 58,
      gap: 12,
    );
  }
}
