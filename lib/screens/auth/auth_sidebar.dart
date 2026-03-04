import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';

/// A Swiggy-style sliding right-aligned sidebar that handles both
/// phone-number entry and OTP verification using **Firebase Phone Auth**.
class AuthSidebar extends StatefulWidget {
  const AuthSidebar({super.key});

  @override
  State<AuthSidebar> createState() => _AuthSidebarState();
}

class _AuthSidebarState extends State<AuthSidebar>
    with SingleTickerProviderStateMixin {
  static const Color _gold = Color(0xFFFFD700);
  static const Color _bg = Color(0xFF1A1A1A);
  static const Color _surface = Color(0xFF232323);
  static const Color _inputBg = Color(0xFF131313);

  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;

  // Step: 0 = phone input, 1 = OTP verify
  int _step = 0;

  // Phone step
  final TextEditingController _phoneCtrl = TextEditingController();
  bool _sendingOtp = false;
  String? _phoneError;

  // Firebase
  fb.ConfirmationResult? _confirmationResult;

  // OTP step
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _verifying = false;
  String? _otpError;
  Timer? _resendTimer;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _phoneCtrl.dispose();
    _resendTimer?.cancel();
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final n in _otpFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _close() async {
    await _slideCtrl.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  // ─── Phone Step ────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    if (_sendingOtp) return;
    final digits = _phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 10) {
      setState(() => _phoneError = 'Enter a valid 10-digit mobile number');
      return;
    }
    setState(() {
      _sendingOtp = true;
      _phoneError = null;
    });
    try {
      final result = await fb.FirebaseAuth.instance.signInWithPhoneNumber(
        '+91$digits',
      );
      if (!mounted) return;
      _confirmationResult = result;
      setState(() => _step = 1);
      _startResendTimer();
    } catch (e) {
      if (!mounted) return;
      setState(
          () => _phoneError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  // ─── OTP Step ──────────────────────────────────────────────────
  String get _otp => _otpCtrls.map((c) => c.text).join();

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendCooldown = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        t.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0) return;
    final digits = _phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    try {
      final result = await fb.FirebaseAuth.instance.signInWithPhoneNumber(
        '+91$digits',
      );
      if (!mounted) return;
      _confirmationResult = result;
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP resent'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _onOtpDigitChanged(int idx, String value) {
    if (value.length > 1) {
      // Paste support
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      final usable = digits.length > 6 ? digits.substring(0, 6) : digits;
      for (var i = 0; i < _otpCtrls.length; i++) {
        _otpCtrls[i].text = i < usable.length ? usable[i] : '';
      }
      if (usable.length == 6) {
        _otpFocusNodes.last.unfocus();
        Future.microtask(_verifyOtp);
      }
      return;
    }
    if (value.isNotEmpty && idx < 5) {
      _otpFocusNodes[idx + 1].requestFocus();
    } else if (value.isEmpty && idx > 0) {
      _otpFocusNodes[idx - 1].requestFocus();
    }
    if (value.isNotEmpty && idx == 5 && _otp.length == 6) {
      Future.microtask(_verifyOtp);
    }
  }

  Future<void> _verifyOtp() async {
    if (_verifying || _confirmationResult == null) return;
    if (_otp.length != 6) {
      setState(() => _otpError = 'Enter complete 6-digit OTP');
      return;
    }
    setState(() {
      _verifying = true;
      _otpError = null;
    });
    try {
      // Firebase confirms the OTP
      final userCredential = await _confirmationResult!.confirm(_otp);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) throw Exception('Firebase auth failed');

      // Get the Firebase ID token
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) throw Exception('Cannot get Firebase token');

      // Send to our backend to create/find user and get JWT
      final digits = _phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
      if (!mounted) return;
      await context.read<AuthService>().firebaseLogin(
            phone: digits,
            firebaseIdToken: idToken,
          );
      if (!mounted) return;
      await _close();
    } catch (e) {
      if (!mounted) return;
      setState(
          () => _otpError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          // Dismiss on tap outside
          GestureDetector(onTap: _close),
          // Sidebar panel
          Align(
            alignment: Alignment.centerRight,
            child: SlideTransition(
              position: _slideAnim,
              child: Container(
                width: 520,
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.92,
                ),
                height: double.infinity,
                decoration: const BoxDecoration(
                  color: _bg,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 24,
                      offset: Offset(-4, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 36, vertical: 20),
                          child:
                              _step == 0 ? _buildPhoneStep() : _buildOtpStep(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(
          bottom: BorderSide(color: _gold.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.restaurant_menu, color: _gold, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _step == 0 ? 'Login' : 'Verify OTP',
              style: const TextStyle(
                color: _gold,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: _close,
          ),
        ],
      ),
    );
  }

  // ─── Phone Input Step ──────────────────────────────────────────
  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        // Illustration area
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _gold.withValues(alpha: 0.25),
                  _gold.withValues(alpha: 0.08),
                ],
              ),
            ),
            child: const Icon(Icons.phone_android, color: _gold, size: 56),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Enter your\nmobile number',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ll send a 6-digit OTP via Firebase for secure login.',
          style: TextStyle(color: Colors.grey[400], fontSize: 15),
        ),
        const SizedBox(height: 28),
        // Phone field
        Container(
          decoration: BoxDecoration(
            color: _inputBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _gold.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: _gold.withValues(alpha: 0.15)),
                  ),
                ),
                child: const Text(
                  '+91',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  autofocus: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: 'Mobile number',
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 16),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendOtp(),
                ),
              ),
            ],
          ),
        ),
        if (_phoneError != null) ...[
          const SizedBox(height: 10),
          Text(_phoneError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
        ],
        const SizedBox(height: 24),
        // CTA button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _sendingOtp ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _sendingOtp
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.black),
                  )
                : const Text(
                    'CONTINUE',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        // Terms
        Center(
          child: Text(
            'By continuing, you agree to our Terms & Privacy Policy',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),
      ],
    );
  }

  // ─── OTP Verification Step ─────────────────────────────────────
  Widget _buildOtpStep() {
    final phone = _phoneCtrl.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        // Back to phone step
        GestureDetector(
          onTap: () => setState(() => _step = 0),
          child: Row(
            children: [
              Icon(Icons.arrow_back_ios, size: 14, color: _gold),
              const SizedBox(width: 4),
              Text(
                'Change number',
                style: TextStyle(color: _gold, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Enter OTP',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.grey[400], fontSize: 15),
            children: [
              const TextSpan(text: 'OTP sent to '),
              TextSpan(
                text: '+91 $phone',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        // OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 52,
              child: TextField(
                controller: _otpCtrls[i],
                focusNode: _otpFocusNodes[i],
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
                  fillColor: _inputBg,
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: _gold.withValues(alpha: 0.25)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: _gold, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (v) => _onOtpDigitChanged(i, v),
                onSubmitted: (_) => _verifyOtp(),
              ),
            );
          }),
        ),
        if (_otpError != null) ...[
          const SizedBox(height: 10),
          Text(_otpError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
        ],
        const SizedBox(height: 24),
        // Verify button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _verifying ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _verifying
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.black),
                  )
                : const Text(
                    'VERIFY OTP',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        // Resend
        Align(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: _resendCooldown > 0 ? null : _resendOtp,
            child: Text(
              _resendCooldown > 0
                  ? 'Resend OTP (${_resendCooldown}s)'
                  : 'Resend OTP',
              style: TextStyle(
                color: _resendCooldown > 0 ? Colors.grey[600] : _gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
