import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/sms_otp_config.dart';
import '../state/otp_controller.dart';
import 'otp_field_style.dart';

/// A beautiful, customizable OTP input field widget.
///
/// This widget provides a complete OTP input experience with:
/// - Auto-focus navigation between fields
/// - Paste support for full OTP codes
/// - Keyboard management
/// - Optional SMS auto-fill integration
/// - Rich animations and haptic feedback
/// - Full accessibility support
///
/// ```dart
/// OtpField(
///   length: 6,
///   onCompleted: (otp) => verifyOtp(otp),
///   style: OtpFieldStyle.rounded(),
/// )
/// ```
class OtpField extends StatefulWidget {
  /// Number of OTP digits.
  final int length;

  /// Styling configuration for the input fields.
  final OtpFieldStyle? style;

  /// Controller for managing OTP state.
  ///
  /// If not provided, a default controller will be created.
  final OtpController? controller;

  /// Called when all digits have been entered.
  final ValueChanged<String>? onCompleted;

  /// Called when the OTP value changes.
  final ValueChanged<String>? onChanged;

  /// Whether to automatically focus the first field.
  final bool autoFocus;

  /// Whether to obscure the OTP digits (like a password).
  final bool obscureText;

  /// Whether to enable haptic feedback on input.
  final bool hapticFeedback;

  /// Whether to automatically listen for SMS OTP.
  final bool autoListen;

  /// Whether the input is in an error state.
  final bool hasError;

  /// Error message to display.
  final String? errorMessage;

  /// Whether the input is enabled.
  final bool enabled;

  /// Whether to auto-submit when complete.
  final bool autoSubmit;

  /// Keyboard type for the input.
  final TextInputType keyboardType;

  /// Custom input formatters.
  final List<TextInputFormatter>? inputFormatters;

  /// Focus node for external focus management.
  final FocusNode? focusNode;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  /// Main axis alignment for the field row.
  final MainAxisAlignment mainAxisAlignment;

  const OtpField({
    super.key,
    this.length = 6,
    this.style,
    this.controller,
    this.onCompleted,
    this.onChanged,
    this.autoFocus = true,
    this.obscureText = false,
    this.hapticFeedback = true,
    this.autoListen = false,
    this.hasError = false,
    this.errorMessage,
    this.enabled = true,
    this.autoSubmit = true,
    this.keyboardType = TextInputType.number,
    this.inputFormatters,
    this.focusNode,
    this.semanticLabel,
    this.mainAxisAlignment = MainAxisAlignment.center,
  }) : assert(length >= 4 && length <= 8, 'OTP length must be between 4 and 8');

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> with TickerProviderStateMixin {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late List<AnimationController> _animationControllers;
  late OtpController _otpController;
  late OtpFieldStyle _style;

  bool _ownsController = false;
  StreamSubscription<dynamic>? _otpSubscription;

  @override
  void initState() {
    super.initState();

    // Initialize style
    _style = widget.style ?? OtpFieldStyle.rounded();

    // Initialize controllers for each field
    _controllers = List.generate(
      widget.length,
      (_) => TextEditingController(),
    );

    // Initialize focus nodes
    _focusNodes = List.generate(
      widget.length,
      (index) => FocusNode(
        debugLabel: 'OTP Field $index',
      ),
    );

    // Initialize animation controllers for each field
    _animationControllers = List.generate(
      widget.length,
      (_) => AnimationController(
        vsync: this,
        duration: _style.animationDuration,
      ),
    );

    // Initialize OTP controller
    if (widget.controller != null) {
      _otpController = widget.controller!;
    } else {
      _ownsController = true;
      _otpController = OtpController(
        config: SmsOtpConfig(
          otpLength: widget.length,
          autoSubmit: widget.autoSubmit,
        ),
      );
    }

    // Listen to focus changes
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() => _onFocusChange(i));
    }

    // Sync with controller
    _otpController.addListener(_syncFromController);

    // Auto-focus if enabled
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestFocus(0);
      });
    }

    // Start auto-listening if enabled
    if (widget.autoListen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startListening();
      });
    }
  }

  @override
  void didUpdateWidget(OtpField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.style != oldWidget.style && widget.style != null) {
      _style = widget.style!;
    }
  }

  void _syncFromController() {
    // Prevent updates after widget is disposed
    if (!mounted) return;

    final otp = _otpController.value.otp;
    for (int i = 0; i < widget.length; i++) {
      final digit = i < otp.length ? otp[i] : '';
      if (_controllers[i].text != digit) {
        _controllers[i].text = digit;
      }
    }

    // Trigger animations for filled fields
    for (int i = 0; i < otp.length; i++) {
      _animationControllers[i].forward();
    }
    for (int i = otp.length; i < widget.length; i++) {
      _animationControllers[i].reverse();
    }
  }

  void _onFocusChange(int index) {
    if (_focusNodes[index].hasFocus) {
      setState(() {});
    }
  }

  void _requestFocus(int index) {
    if (index >= 0 && index < widget.length) {
      _focusNodes[index].requestFocus();
    }
  }

  Future<void> _startListening() async {
    // Cancel existing subscription
    await _otpSubscription?.cancel();

    // Start listening
    await _otpController.startListening();
  }

  void _onDigitEntered(int index, String value) {
    if (!widget.enabled) return;

    // Prevent non-digit input
    final sanitized = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (sanitized.isEmpty) {
      // Only clear and animate if this field had content
      if (_controllers[index].text.isNotEmpty) {
        _controllers[index].clear();
        _animationControllers[index].reverse();
        _updateOtpValue();
      } else if (index > 0) {
        // Move to previous field if current is empty
        _requestFocus(index - 1);
      }
      return;
    }

    // Handle paste - if value is multiple digits
    if (sanitized.length > 1) {
      _handlePaste(sanitized);
      return;
    }

    // Single digit input
    _controllers[index].text = sanitized;

    // Haptic feedback
    if (widget.hapticFeedback) {
      HapticFeedback.lightImpact();
    }

    // Animate
    _animationControllers[index].forward();

    // Update controller
    _updateOtpValue();

    // Move to next field
    if (index < widget.length - 1) {
      _requestFocus(index + 1);
    } else {
      // Last field - unfocus or submit
      _focusNodes[index].unfocus();
      _checkCompletion();
    }
  }

  void _handlePaste(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final truncated = digits.length > widget.length
        ? digits.substring(0, widget.length)
        : digits;

    for (int i = 0; i < widget.length; i++) {
      _controllers[i].text = i < truncated.length ? truncated[i] : '';
      if (i < truncated.length) {
        _animationControllers[i].forward();
      }
    }

    // Haptic feedback
    if (widget.hapticFeedback) {
      HapticFeedback.mediumImpact();
    }

    _updateOtpValue();

    // Focus appropriate field
    if (truncated.length < widget.length) {
      _requestFocus(truncated.length);
    } else {
      _focusNodes[widget.length - 1].unfocus();
      _checkCompletion();
    }
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isNotEmpty) {
      // Clear current field
      _controllers[index].clear();
      _animationControllers[index].reverse();
      _updateOtpValue();

      // Move to previous field after clearing
      if (index > 0) {
        _requestFocus(index - 1);
      }
    } else if (index > 0) {
      // Field is empty, move to previous and clear it
      _requestFocus(index - 1);
      _controllers[index - 1].clear();
      _animationControllers[index - 1].reverse();
      _updateOtpValue();
    }

    if (widget.hapticFeedback) {
      HapticFeedback.selectionClick();
    }
  }

  void _updateOtpValue() {
    if (!mounted) return;
    final otp = _controllers.map((c) => c.text).join();
    _otpController.setOtp(otp);
    widget.onChanged?.call(otp);
  }

  void _checkCompletion() {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == widget.length) {
      if (widget.hapticFeedback) {
        HapticFeedback.heavyImpact();
      }
      widget.onCompleted?.call(otp);
    }
  }

  BoxDecoration _getDecoration(int index) {
    final isFilled = _controllers[index].text.isNotEmpty;
    final isFocused = _focusNodes[index].hasFocus;
    final hasError = widget.hasError;

    if (hasError) {
      return _style.errorDecoration;
    }
    if (isFocused) {
      return _style.activeDecoration;
    }
    if (isFilled) {
      return _style.filledDecoration;
    }
    return _style.inactiveDecoration;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel ?? 'OTP input with ${widget.length} digits',
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive field width based on available space
          final availableWidth = constraints.maxWidth;
          final totalGaps = _style.gap * (widget.length - 1);
          final maxFieldWidth = _style.fieldWidth;

          // Calculate field width that fits the available space
          double fieldWidth = (availableWidth - totalGaps) / widget.length;

          // Clamp field width to reasonable bounds
          fieldWidth = fieldWidth.clamp(36.0, maxFieldWidth);

          // Calculate gap that fits
          double gap = _style.gap;
          final totalWidth =
              fieldWidth * widget.length + gap * (widget.length - 1);
          if (totalWidth > availableWidth) {
            // Reduce gap first
            gap = (availableWidth - fieldWidth * widget.length) /
                (widget.length - 1);
            gap = gap.clamp(2.0, _style.gap);

            // If still too wide, reduce field width more
            final newTotalWidth =
                fieldWidth * widget.length + gap * (widget.length - 1);
            if (newTotalWidth > availableWidth) {
              fieldWidth =
                  (availableWidth - gap * (widget.length - 1)) / widget.length;
              fieldWidth = fieldWidth.clamp(32.0, maxFieldWidth);
            }
          }

          return AutofillGroup(
            child: Stack(
              children: [
                // Hidden TextField for iOS autofill
                // iOS needs a single field to receive the full OTP
                Positioned(
                  left: -1000,
                  child: SizedBox(
                    width: 1,
                    height: 1,
                    child: TextField(
                      autofillHints: const [AutofillHints.oneTimeCode],
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.length >= widget.length) {
                          _handlePaste(value);
                        }
                      },
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Use OverflowBox to prevent overflow errors
                    SizedBox(
                      width: availableWidth,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              widget.length,
                              (index) => _buildField(index, fieldWidth, gap),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(int index, double fieldWidth, double gap) {
    // Calculate field height proportionally to width
    final aspectRatio = _style.fieldHeight / _style.fieldWidth;
    final fieldHeight = fieldWidth * aspectRatio;

    return Container(
      margin: EdgeInsets.only(
        right: index < widget.length - 1 ? gap : 0,
      ),
      child: AnimatedBuilder(
        animation: _animationControllers[index],
        builder: (context, child) {
          final scale = 1.0 + (_animationControllers[index].value * 0.05);
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        // Use regular Container instead of AnimatedContainer to avoid
        // decoration interpolation issues with non-uniform borders
        child: Container(
          width: fieldWidth,
          height: fieldHeight,
          decoration: _getDecoration(index),
          child: Center(
            child: _buildTextField(index),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(int index) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          _onBackspace(index);
        }
      },
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        enabled: widget.enabled,
        keyboardType: widget.keyboardType,
        textAlign: TextAlign.center,
        // Don't use maxLength - it prevents iOS autofill from working
        // We handle length limiting via inputFormatters and onChanged
        obscureText: widget.obscureText,
        obscuringCharacter: _style.obscureCharacter,
        showCursor: _style.showCursor,
        cursorColor: _style.cursorColor,
        cursorWidth: 2.0,
        cursorHeight: _style.textStyle.fontSize != null
            ? _style.textStyle.fontSize! * 0.8
            : 20,
        style: widget.hasError
            ? (_style.errorTextStyle ?? _style.textStyle)
            : _style.textStyle,
        autofillHints: const [AutofillHints.oneTimeCode],
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        inputFormatters: widget.inputFormatters ??
            [
              FilteringTextInputFormatter.digitsOnly,
            ],
        onChanged: (value) => _onDigitEntered(index, value),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    _otpSubscription?.cancel();
    if (_ownsController) {
      _otpController.dispose();
    }
    super.dispose();
  }
}

/// Helper widget for building with animations - wraps Flutter's ListenableBuilder.
class AnimatedBuilder extends StatelessWidget {
  /// The animation to listen to.
  final Animation<double> animation;

  /// Builder function called on each animation tick.
  final Widget Function(BuildContext context, Widget? child) builder;

  /// Optional child widget to pass to builder.
  final Widget? child;

  /// Creates an AnimatedBuilder widget.
  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: animation,
      builder: (context, _) => builder(context, child),
      child: child,
    );
  }
}
