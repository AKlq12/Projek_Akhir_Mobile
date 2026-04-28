import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/providers/sensor_provider.dart';
import '../../core/providers/tools_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  String _email = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retrieve the email passed from the RegisterScreen
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('email')) {
      _email = args['email'];
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final code = _otpController.text.trim();
    if (code.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid 8-digit code.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtp(email: _email, token: code);

    if (!mounted) return;

    if (success) {
      // Load per-user data
      context.read<ToolsProvider>().loadUserData(authProvider.user.id);
      context.read<SensorProvider>().loadUserData(authProvider.user.id);
      context.read<ChatProvider>().loadUserData(authProvider.user.id);
      Navigator.of(context).pushReplacementNamed(AppRoutes.main);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const voltColor = Color(0xFFDAF900);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2C2F30)),
          onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // ── Title ────────────────────────────────────────
              Text(
                'Verify Email',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2C2F30),
                  letterSpacing: -1,
                ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 8),

              Text(
                'We sent an 8-digit code to\n$_email',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF595C5D),
                  height: 1.4,
                ),
              ).animate(delay: 150.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 48),

              // ── OTP Input ────────────────────────────────────
              Center(
                child: SizedBox(
                  width: 300,
                  child: TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                      color: const Color(0xFF2C2F30),
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '00000000',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 8,
                        color: const Color(0xFFABADAE),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFEFF1F2), width: 3),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: voltColor, width: 3),
                      ),
                    ),
                  ),
                ),
              ).animate(delay: 250.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 48),

              // ── Verify Button ──────────────────────────────
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: voltColor,
                        foregroundColor: const Color(0xFF505D00),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF505D00)),
                            )
                          : Text(
                              'VERIFY CODE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  );
                },
              ).animate(delay: 350.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
