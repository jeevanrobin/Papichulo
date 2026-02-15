import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String phone;

  const OtpVerifyScreen({super.key, required this.phone});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  static const Color goldYellow = Color(0xFFFFD700);
  final List<TextEditingController> _controllers =
      List<TextEditingController>.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List<FocusNode>.generate(6, (_) => FocusNode());
  String? _errorText;
  bool _verifying = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((controller) => controller.text).join();

  Future<void> _verify() async {
    if (_verifying) return;
    if (_otp.length != 6) {
      setState(() => _errorText = 'Enter complete 6-digit OTP');
      return;
    }

    setState(() {
      _verifying = true;
      _errorText = null;
    });

    try {
      await context.read<AuthService>().verifyOtp(phone: widget.phone, otp: _otp);
      if (!mounted) return;
      final isAdmin = context.read<AuthService>().isAdmin;
      context.go(isAdmin ? '/admin/dashboard' : '/');
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorText = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  Future<void> _resend() async {
    try {
      await context.read<AuthService>().sendOtp(phone: widget.phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP resent'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: goldYellow,
        title: const Text('Verify OTP'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: goldYellow.withValues(alpha: 0.25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter OTP',
                  style: TextStyle(
                    color: goldYellow,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'OTP sent to +91 ${widget.phone}',
                  style: TextStyle(color: Colors.grey[300]),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List<Widget>.generate(6, (index) {
                    return SizedBox(
                      width: 48,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFF131313),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: goldYellow.withValues(alpha: 0.25),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: goldYellow),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (value) => _onDigitChanged(index, value),
                      ),
                    );
                  }),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 10),
                  Text(_errorText!, style: const TextStyle(color: Colors.redAccent)),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _verifying ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldYellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _verifying
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Verify OTP',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resend,
                    child: const Text(
                      'Resend OTP',
                      style: TextStyle(color: goldYellow),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
