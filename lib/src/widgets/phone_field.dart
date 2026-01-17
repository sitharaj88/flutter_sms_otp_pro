import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/phone_validator.dart';

/// A customizable phone number input field with country code support.
///
/// Features:
/// - Country code picker
/// - Real-time validation
/// - Formatted display
/// - International number support
///
/// ```dart
/// PhoneField(
///   onValidated: (result) {
///     if (result.isValid) {
///       sendOtp(result.e164Format!);
///     }
///   },
/// )
/// ```
class PhoneField extends StatefulWidget {
  /// Called when the phone number changes.
  final ValueChanged<String>? onChanged;

  /// Called when a valid phone number is entered.
  final ValueChanged<PhoneValidationResult>? onValidated;

  /// Called when form submission is triggered.
  final ValueChanged<String>? onSubmitted;

  /// Initial country code (e.g., '+1', '+91').
  final String? initialCountryCode;

  /// Initial phone number value.
  final String? initialValue;

  /// Hint text for the input field.
  final String hintText;

  /// Label text for the input field.
  final String? labelText;

  /// Whether to show validation errors.
  final bool showValidation;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether to auto focus the field.
  final bool autoFocus;

  /// Custom decoration for the input.
  final InputDecoration? decoration;

  /// Style for the input text.
  final TextStyle? textStyle;

  /// Country code button style.
  final CountryCodeStyle? countryCodeStyle;

  /// Focus node for external focus management.
  final FocusNode? focusNode;

  const PhoneField({
    super.key,
    this.onChanged,
    this.onValidated,
    this.onSubmitted,
    this.initialCountryCode,
    this.initialValue,
    this.hintText = 'Phone number',
    this.labelText,
    this.showValidation = true,
    this.enabled = true,
    this.autoFocus = false,
    this.decoration,
    this.textStyle,
    this.countryCodeStyle,
    this.focusNode,
  });

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late String _selectedCountryCode;
  PhoneValidationResult? _validationResult;
  bool _ownsController = false;
  bool _ownsFocusNode = false;

  // Common country codes with flags
  static const List<CountryCodeData> _countryCodes = [
    CountryCodeData(code: '+1', flag: '🇺🇸', name: 'United States'),
    CountryCodeData(code: '+1', flag: '🇨🇦', name: 'Canada'),
    CountryCodeData(code: '+44', flag: '🇬🇧', name: 'United Kingdom'),
    CountryCodeData(code: '+91', flag: '🇮🇳', name: 'India'),
    CountryCodeData(code: '+86', flag: '🇨🇳', name: 'China'),
    CountryCodeData(code: '+81', flag: '🇯🇵', name: 'Japan'),
    CountryCodeData(code: '+49', flag: '🇩🇪', name: 'Germany'),
    CountryCodeData(code: '+33', flag: '🇫🇷', name: 'France'),
    CountryCodeData(code: '+61', flag: '🇦🇺', name: 'Australia'),
    CountryCodeData(code: '+55', flag: '🇧🇷', name: 'Brazil'),
    CountryCodeData(code: '+7', flag: '🇷🇺', name: 'Russia'),
    CountryCodeData(code: '+82', flag: '🇰🇷', name: 'South Korea'),
    CountryCodeData(code: '+39', flag: '🇮🇹', name: 'Italy'),
    CountryCodeData(code: '+34', flag: '🇪🇸', name: 'Spain'),
    CountryCodeData(code: '+31', flag: '🇳🇱', name: 'Netherlands'),
    CountryCodeData(code: '+65', flag: '🇸🇬', name: 'Singapore'),
    CountryCodeData(code: '+971', flag: '🇦🇪', name: 'UAE'),
    CountryCodeData(code: '+966', flag: '🇸🇦', name: 'Saudi Arabia'),
  ];

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialValue);
    _ownsController = true;

    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }

    _selectedCountryCode = widget.initialCountryCode ?? '+1';
  }

  void _validatePhoneNumber(String value) {
    final fullNumber = '$_selectedCountryCode$value';
    final result = PhoneValidator.validate(fullNumber);

    setState(() {
      _validationResult = result;
    });

    widget.onValidated?.call(result);
    widget.onChanged?.call(fullNumber);
  }

  void _showCountryCodePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CountryCodePicker(
        countryCodes: _countryCodes,
        selectedCode: _selectedCountryCode,
        onSelected: (code) {
          setState(() {
            _selectedCountryCode = code;
          });
          _validatePhoneNumber(_controller.text);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = widget.showValidation &&
        _validationResult != null &&
        !_validationResult!.isValid &&
        _controller.text.isNotEmpty;

    final codeStyle = widget.countryCodeStyle ?? CountryCodeStyle.standard();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? Colors.red.shade400
                  : _focusNode.hasFocus
                      ? theme.primaryColor
                      : Colors.grey.shade300,
              width: _focusNode.hasFocus ? 2 : 1,
            ),
            color: widget.enabled ? Colors.white : Colors.grey.shade100,
          ),
          child: Row(
            children: [
              // Country code button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.enabled ? _showCountryCodePicker : null,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(11),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: codeStyle.backgroundColor,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(11),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getFlag(_selectedCountryCode),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedCountryCode,
                          style: codeStyle.textStyle ??
                              TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.grey.shade800,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Divider
              Container(
                width: 1,
                height: 30,
                color: Colors.grey.shade300,
              ),

              // Phone number input
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  autofocus: widget.autoFocus,
                  keyboardType: TextInputType.phone,
                  style: widget.textStyle ??
                      const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                  decoration: widget.decoration ??
                      InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.normal,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        suffixIcon: _validationResult?.isValid == true
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green.shade500,
                              )
                            : null,
                      ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  onChanged: _validatePhoneNumber,
                  onSubmitted: widget.onSubmitted,
                ),
              ),
            ],
          ),
        ),

        // Validation error message
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: Colors.red.shade500,
              ),
              const SizedBox(width: 6),
              Text(
                _validationResult!.message ?? 'Invalid phone number',
                style: TextStyle(
                  color: Colors.red.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _getFlag(String code) {
    final country = _countryCodes.firstWhere(
      (c) => c.code == code,
      orElse: () =>
          const CountryCodeData(code: '', flag: '🌍', name: 'Unknown'),
    );
    return country.flag;
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }
}

/// Country code data model.
class CountryCodeData {
  final String code;
  final String flag;
  final String name;

  const CountryCodeData({
    required this.code,
    required this.flag,
    required this.name,
  });
}

/// Styling for the country code button.
class CountryCodeStyle {
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final BorderRadius? borderRadius;

  const CountryCodeStyle({
    this.backgroundColor,
    this.textStyle,
    this.borderRadius,
  });

  factory CountryCodeStyle.standard() {
    return CountryCodeStyle(
      backgroundColor: Colors.grey.shade50,
    );
  }
}

/// Country code picker bottom sheet.
class _CountryCodePicker extends StatefulWidget {
  final List<CountryCodeData> countryCodes;
  final String selectedCode;
  final ValueChanged<String> onSelected;

  const _CountryCodePicker({
    required this.countryCodes,
    required this.selectedCode,
    required this.onSelected,
  });

  @override
  State<_CountryCodePicker> createState() => _CountryCodePickerState();
}

class _CountryCodePickerState extends State<_CountryCodePicker> {
  late List<CountryCodeData> _filteredCodes;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCodes = widget.countryCodes;
  }

  void _filterCodes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCodes = widget.countryCodes;
      } else {
        _filteredCodes = widget.countryCodes.where((c) {
          return c.name.toLowerCase().contains(query.toLowerCase()) ||
              c.code.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'Select Country',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search country...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterCodes,
            ),
          ),
          const SizedBox(height: 16),

          // Country list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredCodes.length,
              itemBuilder: (context, index) {
                final country = _filteredCodes[index];
                final isSelected = country.code == widget.selectedCode;

                return ListTile(
                  leading: Text(
                    country.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    country.name,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: Text(
                    country.code,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  onTap: () => widget.onSelected(country.code),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
