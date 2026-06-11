// lib/screens/login_screen.dart
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/auth_model.dart';
import '../navigation/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authModel = Provider.of<AuthModel>(context, listen: false);
        if (kDebugMode) debugPrint('Attempting login for: ${_emailController.text}');
        final result = await authModel.login(
            _emailController.text, _passwordController.text);

        if (mounted) setState(() => _isLoading = false);

        if (result == true) {
          _navigateHome();
        } else if (result == null) {
          _showErrorDialog('OTP sent to your email. Please verify.');
        } else {
          _showErrorDialog('Invalid email or password');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          if (kDebugMode) debugPrint('Login error: $e');
          _showErrorDialog('An unexpected error occurred. Please try again.');
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.red.shade50,
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600, size: 28),
              const SizedBox(width: 12),
              Text(
                'Login Failed',
                style: GoogleFonts.inter(
                  color: Colors.red.shade800,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.red.shade700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: Colors.blue.shade600, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Tips:',
                          style: GoogleFonts.inter(
                            color: Colors.blue.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Check if your email is correct\n• Make sure your password is right\n• Try resetting your password if needed',
                      style: GoogleFonts.inter(
                        color: Colors.blue.shade700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Try Again',
                style: GoogleFonts.inter(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showForgotPasswordDialog();
              },
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.inter(
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.blue.shade50,
          title: Row(
            children: [
              Icon(Icons.lock_reset, color: Colors.blue.shade600, size: 28),
              const SizedBox(width: 12),
              Text(
                'Reset Password',
                style: GoogleFonts.inter(
                  color: Colors.blue.shade800,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: GoogleFonts.inter(
                  color: Colors.blue.shade700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (emailController.text.isNotEmpty) {
                  final authModel =
                  Provider.of<AuthModel>(context, listen: false);
                  await authModel
                      .sendPasswordResetEmail(emailController.text);

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Password reset email sent to ${emailController.text}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text(
                'Send Reset Link',
                style: GoogleFonts.inter(
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateHome() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              'Welcome back!',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),

                // ── Logo ─────────────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded,
                        color: Color(0xFF7C3AED), size: 22),
                    const SizedBox(width: 7),
                    Text(
                      'UpHeal',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // ── Heading ───────────────────────────────────────
                Text(
                  'Welcome back',
                  style: GoogleFonts.inter(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Let's continue from where you left off",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Email ─────────────────────────────────────────
                _buildInputField(
                  controller: _emailController,
                  hint: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // ── Password ──────────────────────────────────────
                _buildInputField(
                  controller: _passwordController,
                  hint: 'Password',
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    if (value.length > 50) {
                      return 'Password is too long';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // ── Forgot password ───────────────────────────────
                GestureDetector(
                  onTap: _showForgotPasswordDialog,
                  child: RichText(
                    text: TextSpan(
                      text: 'Forgot your password? ',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                      children: [
                        TextSpan(
                          text: 'Recover it',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF111827),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Log In button ─────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      disabledBackgroundColor:
                          const Color(0xFF111827).withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Log In',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Divider ───────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                        child: Container(height: 1,
                            color: const Color(0xFFE5E7EB))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                        child: Container(height: 1,
                            color: const Color(0xFFE5E7EB))),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Continue with Apple ───────────────────────────
                _buildSocialButton(
                  icon: LucideIcons.apple,
                  label: 'Continue with Apple',
                ),

                const SizedBox(height: 12),

                // ── Continue with Google ──────────────────────────
                _buildGoogleButton(),

                const SizedBox(height: 28),

                // ── Sign Up link ──────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => const SignUpRoute().push<void>(context),
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have account? ",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF111827),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                              decorationColor: const Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Input field ─────────────────────────────────────────────────
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword && !_isPasswordVisible,
      style: GoogleFonts.inter(
        fontSize: 15,
        color: const Color(0xFF111827),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF9CA3AF),
          fontSize: 15,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: const Color(0xFF9CA3AF),
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
      validator: validator,
    );
  }

  // ── Social login button ─────────────────────────────────────────
  Widget _buildSocialButton({
    required IconData icon,
    required String label,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF111827), size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Google button ───────────────────────────────────────────────
  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'G',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF4285F4),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }
}