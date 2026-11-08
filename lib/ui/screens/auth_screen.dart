import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/auth_service.dart';

enum AuthScreenMode {
  signIn,
  signUpForm,
  signUpInterests,
  signUpVerifyOtp,
  forgotPasswordEmail,
  forgotPasswordResetOtp,
}

class AuthScreen extends StatefulWidget {
  final AuthService authService;

  const AuthScreen({super.key, required this.authService});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthScreenMode _mode = AuthScreenMode.signIn;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureNewPassword = true;
  String? _errorMessage;
  String? _successMessage;

  // Multi-genre interest options
  static const List<Map<String, String>> _availableInterests = [
    {'name': 'Pop', 'icon': '🎤'},
    {'name': 'Phonk', 'icon': '🏎️'},
    {'name': 'Brazilian Funk', 'icon': '🇧🇷'},
    {'name': 'Bollywood', 'icon': '🎬'},
    {'name': 'Hollywood / English', 'icon': '🌟'},
    {'name': 'Hip-Hop / Rap', 'icon': '🎧'},
    {'name': 'Punjabi', 'icon': '🪕'},
    {'name': 'EDM / Dance', 'icon': '⚡'},
    {'name': 'Lo-Fi Chill', 'icon': '☕'},
    {'name': 'R&B / Soul', 'icon': '🎷'},
    {'name': 'Rock / Metal', 'icon': '🎸'},
    {'name': 'South Indian', 'icon': '🌴'},
    {'name': 'K-Pop', 'icon': '💜'},
    {'name': 'Latin / Reggaeton', 'icon': '🔥'},
    {'name': 'Acoustic / Indie', 'icon': '🏕️'},
  ];

  final Set<String> _selectedInterests = {};

  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  // --- Actions ---

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await widget.authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;
    if (res['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _errorMessage = res['error'] as String? ?? 'Sign in failed');
    }
  }

  void _handleContinueToInterests() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _errorMessage = null;
      _mode = AuthScreenMode.signUpInterests;
    });
  }

  Future<void> _handleSendRegistrationOtp() async {
    if (_selectedInterests.length < 3) {
      setState(() => _errorMessage = 'Please choose at least 3 genres to continue');
      return;
    }

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await widget.authService.register(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Viper User',
      interests: _selectedInterests.toList(),
    );

    if (!mounted) return;
    if (res['success'] == true) {
      if (res['verificationRequired'] == false) {
        // Daily quota limit fallback: direct sign up without requiring OTP!
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Welcome to MUSIC.'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _mode = AuthScreenMode.signUpVerifyOtp;
        _successMessage = 'A 6-digit verification code was sent to ${_emailController.text.trim()}';
      });
      _startResendTimer();
    } else {
      setState(() => _errorMessage = res['error'] as String? ?? 'Registration failed');
    }
  }

  Future<void> _handleVerifyRegistrationOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit verification code');
      return;
    }

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await widget.authService.verifyEmail(
      email: _emailController.text.trim(),
      code: code,
    );

    if (!mounted) return;
    if (res['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _errorMessage = res['error'] as String? ?? 'Verification failed');
    }
  }

  Future<void> _handleSendForgotPasswordOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await widget.authService.forgotPassword(email: email);

    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _mode = AuthScreenMode.forgotPasswordResetOtp;
        _successMessage = 'A 6-digit password reset code was sent to $email';
      });
      _startResendTimer();
    } else {
      final err = res['error'] as String? ?? '';
      if (err.toLowerCase().contains('quota') ||
          err.toLowerCase().contains('daily limit') ||
          err.contains('429')) {
        setState(() => _errorMessage = 'Email service daily limit reached. Please try again later or contact support.');
      } else {
        setState(() => _errorMessage = err.isNotEmpty ? err : 'Failed to send reset code');
      }
    }
  }

  Future<void> _handleResetPassword() async {
    final code = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit reset code');
      return;
    }
    if (newPassword.length < 6) {
      setState(() => _errorMessage = 'New password must be at least 6 characters');
      return;
    }

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await widget.authService.resetPassword(
      email: _emailController.text.trim(),
      code: code,
      newPassword: newPassword,
    );

    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _mode = AuthScreenMode.signIn;
        _passwordController.text = newPassword;
        _otpController.clear();
        _newPasswordController.clear();
        _successMessage = 'Password reset successfully! You can now sign in.';
      });
    } else {
      setState(() => _errorMessage = res['error'] as String? ?? 'Reset failed');
    }
  }

  Future<void> _handleResend(String type) async {
    if (_resendCooldown > 0) return;
    final email = _emailController.text.trim();
    final res = await widget.authService.resendCode(email: email, type: type);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() => _successMessage = 'A fresh 6-digit code was sent to $email');
      _startResendTimer();
    } else {
      setState(() => _errorMessage = res['error'] as String? ?? 'Failed to resend code');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.authService.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_mode == AuthScreenMode.signUpInterests) {
              setState(() => _mode = AuthScreenMode.signUpForm);
            } else if (_mode == AuthScreenMode.signUpVerifyOtp) {
              setState(() => _mode = AuthScreenMode.signUpInterests);
            } else if (_mode == AuthScreenMode.forgotPasswordEmail ||
                _mode == AuthScreenMode.forgotPasswordResetOtp) {
              setState(() => _mode = AuthScreenMode.signIn);
            } else {
              Navigator.of(context).pop(false);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo (No circle around it)
                  Center(
                    child: Image.asset(
                      'assets/images/header_logo.png',
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Text(
                        'MUSIC',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notifications & Error Messages
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryRed, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.primaryRed, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.greenAccent, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Conditional Views
                  if (_mode == AuthScreenMode.signIn) _buildSignInView(isLoading),
                  if (_mode == AuthScreenMode.signUpForm) _buildSignUpFormView(isLoading),
                  if (_mode == AuthScreenMode.signUpInterests) _buildInterestsPickerView(isLoading),
                  if (_mode == AuthScreenMode.signUpVerifyOtp) _buildVerifyOtpView(isLoading),
                  if (_mode == AuthScreenMode.forgotPasswordEmail) _buildForgotPasswordEmailView(isLoading),
                  if (_mode == AuthScreenMode.forgotPasswordResetOtp) _buildForgotPasswordResetOtpView(isLoading),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 1. Sign In View
  Widget _buildSignInView(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Sign in to your account',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Listen to unlimited music and access your saved playlists.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
        ),
        const SizedBox(height: 24),

        _buildTabSwitcher(isSignUp: false),
        const SizedBox(height: 20),

        // Email Field
        _buildEmailField(),
        const SizedBox(height: 14),

        // Password Field
        _buildPasswordField(
          controller: _passwordController,
          label: 'Password',
          obscureText: _obscurePassword,
          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
        ),

        // Forgot Password Button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => setState(() {
              _mode = AuthScreenMode.forgotPasswordEmail;
              _errorMessage = null;
              _successMessage = null;
            }),
            child: const Text(
              'Forgot Password?',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Submit
        _buildPrimaryButton(
          title: 'Sign In',
          isLoading: isLoading,
          onPressed: _handleSignIn,
        ),
      ],
    );
  }

  // 2. Sign Up Form View
  Widget _buildSignUpFormView(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Create your account',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Join MUSIC for free and get personal recommendations.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
        ),
        const SizedBox(height: 24),

        _buildTabSwitcher(isSignUp: true),
        const SizedBox(height: 20),

        // Name
        TextFormField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _inputDecoration(hint: 'Full Name', icon: Icons.person_outline),
        ),
        const SizedBox(height: 14),

        // Email
        _buildEmailField(),
        const SizedBox(height: 14),

        // Password
        _buildPasswordField(
          controller: _passwordController,
          label: 'Password (min. 6 characters)',
          obscureText: _obscurePassword,
          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 24),

        _buildPrimaryButton(
          title: 'Continue: Choose Musical Taste →',
          isLoading: false,
          onPressed: _handleContinueToInterests,
        ),
      ],
    );
  }

  // 3. Musical Interests Grid View
  Widget _buildInterestsPickerView(bool isLoading) {
    final count = _selectedInterests.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'What do you love listening to?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Select at least 3 genres to calibrate your personal recommendation feed.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
        ),
        const SizedBox(height: 16),

        // Selection Counter Badge
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: count >= 3 ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: count >= 3 ? Colors.greenAccent : Colors.white24,
                width: 0.8,
              ),
            ),
            child: Text(
              '$count selected ${count >= 3 ? "✓ Ready" : "(min. 3 required)"}',
              style: TextStyle(
                color: count >= 3 ? Colors.greenAccent : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Genres Grid
        Wrap(
          spacing: 8,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _availableInterests.map((g) {
            final name = g['name']!;
            final icon = g['icon']!;
            final isSelected = _selectedInterests.contains(name);

            return FilterChip(
              avatar: Text(icon, style: const TextStyle(fontSize: 14)),
              label: Text(name),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedInterests.add(name);
                  } else {
                    _selectedInterests.remove(name);
                  }
                });
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primaryRed,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.85),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryRed : AppColors.border,
                  width: 0.8,
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),

        _buildPrimaryButton(
          title: 'Send 6-Digit Email Code →',
          isLoading: isLoading,
          onPressed: _handleSendRegistrationOtp,
        ),
      ],
    );
  }

  // 4. Verify OTP View (Sign Up)
  Widget _buildVerifyOtpView(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined, color: AppColors.primaryRed, size: 54),
        const SizedBox(height: 14),
        const Text(
          'Check your inbox',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'We sent a 6-digit confirmation code to\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 24),

        // OTP Field
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            letterSpacing: 10,
            fontWeight: FontWeight.w900,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppColors.surface,
            hintText: '000000',
            hintStyle: TextStyle(color: Colors.white24, fontSize: 28, letterSpacing: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5)),
          ),
        ),
        const SizedBox(height: 24),

        _buildPrimaryButton(
          title: 'Verify & Start Listening',
          isLoading: isLoading,
          onPressed: _handleVerifyRegistrationOtp,
        ),
        const SizedBox(height: 14),

        // Resend
        Center(
          child: TextButton(
            onPressed: _resendCooldown > 0 ? null : () => _handleResend('signup'),
            child: Text(
              _resendCooldown > 0 ? 'Resend code in ${_resendCooldown}s' : 'Didn\'t receive code? Resend',
              style: TextStyle(color: _resendCooldown > 0 ? Colors.white38 : Colors.white70, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  // 5. Forgot Password Email View
  Widget _buildForgotPasswordEmailView(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_reset_rounded, color: AppColors.primaryRed, size: 54),
        const SizedBox(height: 14),
        const Text(
          'Reset Your Password',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your registered email address to receive a 6-digit password reset code.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
        ),
        const SizedBox(height: 24),

        _buildEmailField(),
        const SizedBox(height: 24),

        _buildPrimaryButton(
          title: 'Send Reset Code',
          isLoading: isLoading,
          onPressed: _handleSendForgotPasswordOtp,
        ),
        const SizedBox(height: 12),

        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _mode = AuthScreenMode.signIn;
              _errorMessage = null;
              _successMessage = null;
            }),
            child: const Text('Back to Sign In', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  // 6. Forgot Password Reset & Enter New Password View
  Widget _buildForgotPasswordResetOtpView(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.security_rounded, color: AppColors.primaryRed, size: 54),
        const SizedBox(height: 14),
        const Text(
          'Enter Reset Code',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter the 6-digit code sent to ${_emailController.text.trim()} and choose a new password.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
        ),
        const SizedBox(height: 20),

        // Code
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            letterSpacing: 8,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppColors.surface,
            hintText: '000000',
            hintStyle: TextStyle(color: Colors.white24, fontSize: 26, letterSpacing: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.2)),
          ),
        ),
        const SizedBox(height: 14),

        // New Password
        _buildPasswordField(
          controller: _newPasswordController,
          label: 'New Password (min. 6 characters)',
          obscureText: _obscureNewPassword,
          onToggleVisibility: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
        ),
        const SizedBox(height: 24),

        _buildPrimaryButton(
          title: 'Update Password & Sign In',
          isLoading: isLoading,
          onPressed: _handleResetPassword,
        ),
        const SizedBox(height: 12),

        Center(
          child: TextButton(
            onPressed: _resendCooldown > 0 ? null : () => _handleResend('reset'),
            child: Text(
              _resendCooldown > 0 ? 'Resend code in ${_resendCooldown}s' : 'Resend Code',
              style: TextStyle(color: _resendCooldown > 0 ? Colors.white38 : Colors.white70, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  // --- Sub-Components ---

  Widget _buildTabSwitcher({required bool isSignUp}) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _mode = AuthScreenMode.signIn;
                _errorMessage = null;
                _successMessage = null;
              }),
              child: Container(
                decoration: BoxDecoration(
                  color: !isSignUp ? AppColors.primaryRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      color: !isSignUp ? Colors.white : Colors.white70,
                      fontWeight: !isSignUp ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _mode = AuthScreenMode.signUpForm;
                _errorMessage = null;
                _successMessage = null;
              }),
              child: Container(
                decoration: BoxDecoration(
                  color: isSignUp ? AppColors.primaryRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      color: isSignUp ? Colors.white : Colors.white70,
                      fontWeight: isSignUp ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: (v) {
        if (v == null || v.trim().isEmpty || !v.contains('@')) {
          return 'Enter a valid email address';
        }
        return null;
      },
      decoration: _inputDecoration(hint: 'Email address', icon: Icons.email_outlined),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: (v) {
        if (v == null || v.trim().length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        hintText: label,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white54, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.white54,
            size: 20,
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.2)),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.surface,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.white54, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.2)),
    );
  }

  Widget _buildPrimaryButton({
    required String title,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
