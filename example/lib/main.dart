import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sms_otp_pro/flutter_sms_otp_pro.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS OTP Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const OtpDemoPage(),
    );
  }
}

class OtpDemoPage extends StatefulWidget {
  const OtpDemoPage({super.key});

  @override
  State<OtpDemoPage> createState() => _OtpDemoPageState();
}

class _OtpDemoPageState extends State<OtpDemoPage> {
  late OtpController _otpController;
  String? _appSignature;
  String _selectedStyle = 'rounded';
  bool _isVerifying = false;
  String? _verificationResult;

  final _styles = {
    'rounded': OtpFieldStyle.rounded(),
    'underlined': OtpFieldStyle.underlined(),
    'boxed': OtpFieldStyle.boxed(),
    'circular': OtpFieldStyle.circular(),
    'glassmorphism': OtpFieldStyle.glassmorphism(),
    'dark': OtpFieldStyle.dark(),
  };

  @override
  void initState() {
    super.initState();
    _otpController = OtpController(
      config: const SmsOtpConfig(
        otpLength: 6,
        timeout: Duration(minutes: 5),
        maxRetries: 3,
        retryCooldown: Duration(seconds: 30),
      ),
    );
    _loadAppSignature();
    _startSmsListener();

    // Listen for OTP auto-fill from SMS
    _otpController.addListener(_onOtpStateChanged);
  }

  void _onOtpStateChanged() {
    // When OTP is auto-filled from SMS, call onCompleted
    if (_otpController.value.isComplete &&
        _otpController.value.otp.isNotEmpty) {
      _onOtpCompleted(_otpController.value.otp);
    }
  }

  Future<void> _startSmsListener() async {
    // Start listening for SMS (for Android auto-read)
    if (_otpController.supportsAutoRead) {
      await _otpController.startListening();
    }
  }

  Future<void> _loadAppSignature() async {
    final signature = await _otpController.getAppSignature();
    if (mounted) {
      setState(() {
        _appSignature = signature;
      });
    }
  }

  void _onOtpCompleted(String otp) {
    setState(() {
      _isVerifying = true;
      _verificationResult = null;
    });

    // Simulate verification delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          // Simulate success if OTP is "123456"
          _verificationResult =
              otp == '123456' ? '✅ Verified successfully!' : '❌ Invalid OTP';
        });
      }
    });
  }

  void _resetOtp() {
    _otpController.reset();
    setState(() {
      _verificationResult = null;
      _isVerifying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS OTP Demo'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Style Selector
            _buildSectionTitle('Style'),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _styles.length,
                itemBuilder: (context, index) {
                  final styleName = _styles.keys.elementAt(index);
                  final isSelected = styleName == _selectedStyle;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(styleName),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _selectedStyle = styleName);
                        _resetOtp();
                        _startSmsListener(); // Restart SMS listener
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // OTP Input Section
            _buildSectionTitle('Enter OTP'),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to your phone',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),

            // OTP Field with dynamic background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                gradient: _selectedStyle == 'glassmorphism'
                    ? LinearGradient(
                        colors: [
                          Colors.indigo.shade400,
                          Colors.purple.shade400,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: _selectedStyle == 'dark'
                    ? const Color(0xFF111827)
                    : (_selectedStyle != 'glassmorphism'
                        ? (isDark ? Colors.grey[900] : Colors.grey[50])
                        : null),
                borderRadius: BorderRadius.circular(16),
              ),
              child: OtpField(
                key: ValueKey(_selectedStyle), // Force rebuild on style change
                length: 6,
                controller: _otpController,
                style: _styles[_selectedStyle],
                autoFocus: true,
                hapticFeedback: true,
                onCompleted: _onOtpCompleted,
                onChanged: (value) {
                  if (_verificationResult != null) {
                    setState(() => _verificationResult = null);
                  }
                },
              ),
            ),

            const SizedBox(height: 24),

            // Verification Status
            if (_isVerifying)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Verifying...'),
                  ],
                ),
              )
            else if (_verificationResult != null)
              Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _verificationResult!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _verificationResult!.contains('✅')
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Countdown Timer
            Center(
              child: CountdownTimer(
                duration: const Duration(seconds: 30),
                onResend: () {
                  _resetOtp();
                  _startSmsListener(); // Restart SMS listener
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('OTP resent! SMS listener started.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Phone Input Section
            _buildSectionTitle('Phone Number'),
            const SizedBox(height: 16),
            PhoneField(
              initialCountryCode: '+1',
              labelText: 'Mobile Number',
              hintText: 'Enter phone number',
              showValidation: true,
              onValidated: (result) {
                if (result.isValid) {
                  debugPrint('Valid: ${result.e164Format}');
                }
              },
            ),

            const SizedBox(height: 32),

            // App Signature Section (Android only)
            if (_appSignature != null) ...[
              _buildSectionTitle('Android App Signature'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Include this in your SMS for auto-read:',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              _appSignature!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            tooltip: 'Copy signature',
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: _appSignature!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Signature copied!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SMS Format:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              final smsFormat =
                                  '<#> Your code is 123456\n$_appSignature';
                              Clipboard.setData(ClipboardData(text: smsFormat));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('SMS format copied!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          '<#> Your code is 123456\n$_appSignature',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Reset Button
            Center(
              child: OutlinedButton.icon(
                onPressed: _resetOtp,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  @override
  void dispose() {
    _otpController.removeListener(_onOtpStateChanged);
    _otpController.dispose();
    super.dispose();
  }
}
