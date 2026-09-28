import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import 'providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = ref.read(authProvider.notifier);
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (mounted) setState(() => _isLoading = false);

    if (!success && mounted) {
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Login failed. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() => _isLoading = true);
    final auth = ref.read(authProvider.notifier);
    await auth.loginGuest();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first.'),
        ),
      );
      return;
    }
    final auth = ref.read(authProvider.notifier);
    final sent = await auth.forgotPassword(email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sent
              ? 'Password reset email sent to $email'
              : 'Could not send reset email. Please try again.'),
          backgroundColor: sent ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero header with Orange Gradient
              Container(
                height: 250.h,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 76.w,
                      height: 76.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 16.r,
                            offset: Offset(0, 6.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.home_work_rounded,
                        size: 42.sp,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'Crabigo Host',
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 26.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Sign in to manage your properties',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 13.sp,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 8.h),
                      Text(
                        'Welcome back! 👋',
                        style: AppTextStyles.headlineMedium.copyWith(fontSize: 20.sp),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Sign in to your host account',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 13.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 28.h),

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(fontSize: 14.sp),
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: TextStyle(fontSize: 13.sp),
                          prefixIcon: Icon(Icons.email_outlined,
                              color: AppColors.textHint, size: 20.sp),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!v.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        style: TextStyle(fontSize: 14.sp),
                        onFieldSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(fontSize: 13.sp),
                          prefixIcon: Icon(Icons.lock_outline,
                              color: AppColors.textHint, size: 20.sp),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textHint,
                              size: 20.sp,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          if (v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 8.h),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _handleForgotPassword,
                          child: Text('Forgot Password?', style: TextStyle(fontSize: 13.sp)),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Login button
                      PrimaryGradientButton(
                        text: 'Sign In',
                        onPressed: _isLoading ? null : _handleLogin,
                        isLoading: _isLoading,
                      ),
                      SizedBox(height: 12.h),

                      // Guest Mode / Demo bypass button
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleGuestLogin,
                        icon: Icon(Icons.person_pin_rounded, size: 18.sp, color: AppColors.primary),
                        label: Text(
                          'Explore in Guest Mode (Demo)',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      SizedBox(height: 32.h),

                      // Footer
                      Center(
                        child: Text(
                          'Powered by Crabigo Platform',
                          style: AppTextStyles.caption.copyWith(fontSize: 11.sp),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
