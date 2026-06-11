import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/auth_model.dart';
import '../navigation/app_routes.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String _passwordStrength = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    if (mounted) {
      setState(() {
        if (password.isEmpty) {
          _passwordStrength = '';
        } else if (password.length < 8) {
          _passwordStrength = 'Weak';
        } else if (password.length >= 8 && password.length < 10) {
          _passwordStrength = 'Medium';
        } else if (password.length >= 10 &&
            RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password)) {
          _passwordStrength = 'Strong';
        } else {
          _passwordStrength = 'Good';
        }
      });
    }
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authModel = Provider.of<AuthModel>(context, listen: false);

      try {
        final success = await authModel.signUp(
          _emailController.text,
          _passwordController.text,
          _nameController.text,
        );

        if (!success) {
          if (mounted) {
            _showErrorDialog(authModel.errorMessage ?? 'Failed to create account. Please try again.');
          }
        } else {
          if (mounted) {
            final isAuthenticated =
                Provider.of<AuthModel>(context, listen: false).isAuthenticated;
            if (isAuthenticated) {
              context.go(const HomeRoute().location);
            } else {
              context.go(const LoginRoute().location);
            }
          }
        }
      } catch (e) {
        if (mounted) {
          if (kDebugMode) debugPrint('SignUp error: $e');
          _showErrorDialog(
              'An unexpected error occurred. Please try again.');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.red.shade50,
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600, size: 28),
              const SizedBox(width: 12),
              Text(
                'Sign Up Failed',
                style: GoogleFonts.inter(
                  color: Colors.red.shade800,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.inter(
              color: Colors.red.shade700,
              fontSize: 14,
            ),
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
          ],
        );
      },
    );
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
                  'Start small',
                  style: GoogleFonts.inter(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create an account in a minute',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Name ─────────────────────────────────────────
                _buildInputField(
                  controller: _nameController,
                  hint: 'Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    if (value.length > 50) {
                      return 'Name is too long';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

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
                  onChanged: _checkPasswordStrength,
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

                if (_passwordStrength.isNotEmpty) ...[  
                  const SizedBox(height: 8),
                  _buildPasswordStrengthRow(),
                ],

                const SizedBox(height: 18),

                // ── Terms checkbox ────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _agreedToTerms,
                        onChanged: (v) =>
                            setState(() => _agreedToTerms = v ?? false),
                        activeColor: const Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: const BorderSide(
                          color: Color(0xFFD1D5DB),
                          width: 1.5,
                        ),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: 'I agree to the ',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF111827),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFF111827),
                              ),
                            ),
                            TextSpan(
                              text: ' and ',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            TextSpan(
                              text: 'Privacy Policy.',
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
                  ],
                ),

                const SizedBox(height: 28),

                // ── Create account button ─────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_isLoading || !_agreedToTerms)
                        ? null
                        : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      disabledBackgroundColor:
                          const Color(0xFF111827).withValues(alpha: 0.35),
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                        : Text(
                            'Create account',
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
                        child: Container(
                            height: 1, color: const Color(0xFFE5E7EB))),
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
                        child: Container(
                            height: 1, color: const Color(0xFFE5E7EB))),
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

                // ── Log in link ───────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: 'Log in',
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
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword && !_isPasswordVisible,
      onChanged: onChanged,
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

  // ── Password strength row ────────────────────────────────────────
  Widget _buildPasswordStrengthRow() {
    Color color;
    switch (_passwordStrength) {
      case 'Weak':
        color = const Color(0xFFEF4444);
        break;
      case 'Medium':
        color = const Color(0xFFF59E0B);
        break;
      case 'Good':
        color = const Color(0xFF3B82F6);
        break;
      case 'Strong':
        color = const Color(0xFF10B981);
        break;
      default:
        color = const Color(0xFF9CA3AF);
    }
    return Row(
      children: [
        Text(
          'Password strength: ',
          style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF6B7280)),
        ),
        Text(
          _passwordStrength,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
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