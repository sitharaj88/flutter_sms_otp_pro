import 'dart:async';

import 'package:flutter/material.dart';

/// A countdown timer widget for OTP resend functionality.
///
/// Displays a countdown and button to request a new OTP code.
///
/// ```dart
/// CountdownTimer(
///   duration: Duration(seconds: 30),
///   onResend: () => requestNewOtp(),
/// )
/// ```
class CountdownTimer extends StatefulWidget {
  /// The countdown duration.
  final Duration duration;

  /// Called when the resend button is pressed.
  final VoidCallback? onResend;

  /// Called every second with remaining time.
  final ValueChanged<Duration>? onTick;

  /// Called when the countdown completes.
  final VoidCallback? onComplete;

  /// Whether to auto-start the countdown.
  final bool autoStart;

  /// Style for the timer text.
  final TextStyle? timerStyle;

  /// Style for the resend button text.
  final TextStyle? buttonStyle;

  /// Text to show before the timer value.
  final String timerPrefix;

  /// Text for the resend button.
  final String resendText;

  /// Text shown while countdown is active.
  final String countdownText;

  /// Custom builder for the timer display.
  final Widget Function(Duration remaining, bool canResend)? builder;

  /// Background decoration for the button.
  final BoxDecoration? buttonDecoration;

  /// Padding for the button.
  final EdgeInsets buttonPadding;

  const CountdownTimer({
    super.key,
    this.duration = const Duration(seconds: 30),
    this.onResend,
    this.onTick,
    this.onComplete,
    this.autoStart = true,
    this.timerStyle,
    this.buttonStyle,
    this.timerPrefix = 'Resend in ',
    this.resendText = 'Resend OTP',
    this.countdownText = 'Didn\'t receive the code?',
    this.builder,
    this.buttonDecoration,
    this.buttonPadding = const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 12,
    ),
  });

  @override
  State<CountdownTimer> createState() => CountdownTimerState();
}

class CountdownTimerState extends State<CountdownTimer>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late Duration _remaining;
  late AnimationController _pulseController;

  bool get canResend => _remaining.inSeconds <= 0;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.autoStart) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _remaining = widget.duration;
    }
  }

  /// Starts the countdown timer.
  void start() {
    _remaining = widget.duration;
    _startTimer();
  }

  /// Resets and restarts the countdown.
  void reset() {
    _timer?.cancel();
    setState(() {
      _remaining = widget.duration;
    });
    _startTimer();
  }

  /// Stops the countdown timer.
  void stop() {
    _timer?.cancel();
    _pulseController.stop();
  }

  void _startTimer() {
    _timer?.cancel();
    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds > 0) {
        setState(() {
          _remaining -= const Duration(seconds: 1);
        });
        widget.onTick?.call(_remaining);
      } else {
        _timer?.cancel();
        _pulseController.stop();
        _pulseController.value = 1.0;
        widget.onComplete?.call();
      }
    });
  }

  void _handleResend() {
    if (canResend) {
      widget.onResend?.call();
      reset();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (minutes > 0) {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.builder != null) {
      return widget.builder!(_remaining, canResend);
    }

    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.countdownText,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: canResend
              ? _buildResendButton(primaryColor)
              : _buildCountdown(primaryColor),
        ),
      ],
    );
  }

  Widget _buildCountdown(Color primaryColor) {
    return ListenableBuilder(
      listenable: _pulseController,
      builder: (context, child) {
        final opacity = 0.5 + (_pulseController.value * 0.5);
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 18,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              '${widget.timerPrefix}${_formatDuration(_remaining)}',
              style: widget.timerStyle ??
                  TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResendButton(Color primaryColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleResend,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: widget.buttonPadding,
          decoration: widget.buttonDecoration ??
              BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                widget.resendText,
                style: widget.buttonStyle ??
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
}
