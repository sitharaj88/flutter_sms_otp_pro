# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-16

### Added

- **OtpField Widget** - Customizable OTP input with 6 preset themes
  - `rounded` - Modern rounded boxes with shadows
  - `underlined` - Minimalist underline style
  - `boxed` - Corporate/enterprise look
  - `circular` - Playful circular fields
  - `glassmorphism` - Frosted glass effect
  - `dark` - Dark theme

- **PhoneField Widget** - International phone number input
  - Country code picker with flags
  - Real-time validation
  - E.164 format support

- **CountdownTimer Widget** - Animated resend countdown
  - Pulse animation
  - Customizable appearance
  - Callbacks for tick and complete

- **OtpController** - State management
  - SMS listening lifecycle
  - Retry logic with cooldown
  - Validation utilities

- **Android SMS Retriever API** - Auto-read OTP without permissions
  - App signature generation
  - OTP extraction from SMS
  - Event streaming

- **iOS Native Autofill** - Keyboard code suggestions
  - AutofillHints support
  - No permissions required

- **PhoneValidator** - International phone validation
  - 20+ country formats
  - E.164 conversion

- **OtpParser** - Intelligent OTP extraction
  - Multiple pattern matching
  - Message format detection

### Security

- No SMS permissions required on Android (SMS Retriever API)
- No special entitlements needed on iOS
