import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../core/providers/auth_provider.dart';

/// Registration screen with name, email, password, confirm password,
/// fitness goal chips, and a "Create Account" CTA.
///
/// Follows the FitPro design: white bg, uppercase labels, rounded inputs,
/// volt-green accent for primary actions and selected chips.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedGoal;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const _goals = [
    'Lose Weight',
    'Build Muscle',
    'Stay Fit',
    'Gain Strength',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // Optionally update fitness goal in profile
      if (_selectedGoal != null) {
        final updatedUser =
            authProvider.user.copyWith(fitnessGoal: _selectedGoal);
        await authProvider.updateProfile(updatedUser);
      }

      if (!mounted) return;
      // Change to OTP Verification Screen
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.otpVerification,
        arguments: {'email': _emailController.text.trim()},
      );
    } else {
      final errorMessage = authProvider.errorMessage.toLowerCase();
      final isAlreadyRegistered = errorMessage.contains('already registered') || 
                                  errorMessage.contains('already exists');
                                  
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAlreadyRegistered 
              ? 'Email is already registered. Please sign in instead.' 
              : authProvider.errorMessage
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
          action: isAlreadyRegistered 
              ? SnackBarAction(
                  label: 'SIGN IN',
                  textColor: Colors.white,
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const voltColor = Color(0xFFDAF900);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Navigation ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF1F2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF2C2F30),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            // ── Scrollable Content ──────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // ── Title ────────────────────────────────────────
                      Text(
                        'Create Account',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2C2F30),
                          letterSpacing: -1,
                        ),
                      ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: 8),

                      Text(
                        'Start your fitness journey today',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF595C5D),
                        ),
                      ).animate(delay: 150.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: 32),

                      // ── Full Name ────────────────────────────────────
                      _buildLabel('Full Name'),
                      const SizedBox(height: 8),
                      _buildInputField(
                        controller: _nameController,
                        hint: 'Enter your name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: 16),

                      // ── Email ────────────────────────────────────────
                      _buildLabel('Email'),
                      const SizedBox(height: 8),
                      _buildInputField(
                        controller: _emailController,
                        hint: 'fit@pro.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Invalid email address';
                          }
                          return null;
                        },
                      ).animate(delay: 250.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: 16),

                      // ── Password ───────────────────────────────────────
                      _buildLabel('Password'),
                      const SizedBox(height: 8),
                      _buildInputField(
                        controller: _passwordController,
                        hint: '••••••••',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: const Color(0xFF757778),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (value.length < 6) {
                            return 'Min 6 chars';
                          }
                          if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$').hasMatch(value)) {
                            return 'Require Upper, Lower & Num';
                          }
                          return null;
                        },
                      ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: 16),

                      // ── Confirm Password ───────────────────────────────
                      _buildLabel('Confirm'),
                      const SizedBox(height: 8),
                      _buildInputField(
                        controller: _confirmPasswordController,
                        hint: '••••••••',
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: const Color(0xFF757778),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Not match';
                          }
                          return null;
                        },
                      ).animate(delay: 320.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: 28),

                      // ── Fitness Goal Chips ───────────────────────────
                      _buildLabel('What is your primary goal?'),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _goals.map((goal) {
                          final isSelected = _selectedGoal == goal;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedGoal =
                                    _selectedGoal == goal ? null : goal;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? voltColor
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isSelected
                                      ? voltColor
                                      : const Color(0xFFABADAE)
                                          .withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                goal,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? const Color(0xFF505D00)
                                      : const Color(0xFF2C2F30),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ).animate(delay: 350.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: 40),

                      // ── Create Account Button ────────────────────────
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed:
                                  auth.isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: voltColor,
                                foregroundColor: const Color(0xFF505D00),
                                elevation: 0,
                                shadowColor: voltColor.withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Color(0xFF505D00),
                                      ),
                                    )
                                  : Text(
                                      'CREATE ACCOUNT',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          );
                        },
                      )
                          .animate(delay: 400.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 32),

                      // ── Footer Links ─────────────────────────────────
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF595C5D),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Text(
                                'Sign In',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: 450.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: 40),

                      // ── FitPro Kinetic Footer ────────────────────────
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 1,
                              color: const Color(0xFF757778)
                                  .withValues(alpha: 0.3),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'FITPRO KINETIC',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.5,
                                color: const Color(0xFF757778)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 32,
                              height: 1,
                              color: const Color(0xFF757778)
                                  .withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ).animate(delay: 500.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an uppercase label matching the reference design.
  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: const Color(0xFF595C5D),
      ),
    );
  }

  /// Builds a styled input field matching the FitPro register design.
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF2C2F30),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF757778),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFEFF1F2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFDAF900),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}
