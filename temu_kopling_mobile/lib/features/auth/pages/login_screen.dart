import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temu_kopling_mobile/app/theme/app_theme.dart';
import 'package:temu_kopling_mobile/shared/widgets/custom_button.dart';
import 'package:temu_kopling_mobile/shared/widgets/custom_text_field.dart';
import 'package:temu_kopling_mobile/features/home/pages/main_screen.dart';
import 'package:temu_kopling_mobile/features/auth/pages/register_screen.dart';
import '../services/auth_service.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      await AuthService.login(email: email, password: password);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AuthHeader(
              title: 'Selamat Datang',
              subtitle: 'Masuk ke akun pelanggan Temu Kopling',
            ),
            SizedBox(height: AppSpacing.xxxxl),

            // Main Form Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard.withValues(alpha: 0.9),
                borderRadius: AppRadius.radiusAuthCard,
                border: Border.all(
                  color: AppColors.bgCard.withValues(alpha: 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email Field
                    CustomTextField(
                      controller: _emailController,
                      label: 'Alamat Email',
                      hint: 'email@contoh.com',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      borderRadius: AppRadius.radiusXxl,
                      borderColor: AppColors.textSecondary,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppSpacing.lg),

                    // Password Field
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Kata Sandi',
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: !_showPassword,
                      borderRadius: AppRadius.radiusXxl,
                      borderColor: AppColors.textSecondary,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      onTogglePassword: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password tidak boleh kosong';
                        }
                        if (value.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),

                    // Alerts: Error / Success
                    if (_errorMessage != null) ...[
                      SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          border: Border.all(color: Colors.red[100]!),
                          borderRadius: AppRadius.radiusXxl,
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[800],
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (_successMessage != null) ...[
                      SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          border: Border.all(color: Colors.green[100]!),
                          borderRadius: AppRadius.radiusXxl,
                        ),
                        child: Text(
                          _successMessage!,
                          style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: AppSpacing.xxl),

                    // Submit Button with Gradient
                    CustomButton(
                      text: 'Masuk',
                      onPressed: _handleSubmit,
                      isLoading: _isLoading,
                      gradient: const LinearGradient(
                        colors: [AppColors.accentBrown, AppColors.primaryBrown],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentBrown.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      borderRadius: AppRadius.radiusXxl,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textColor: AppColors.bgCard,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSpacing.xxl),

            // Toggle Login/Register
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Belum memiliki akun? ',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final registeredEmail = await Navigator.of(context)
                        .push<String>(
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                    if (registeredEmail != null && mounted) {
                      _emailController.text = registeredEmail;
                    }
                  },
                  child: const Text(
                    'Daftar sekarang',
                    style: TextStyle(
                      color: AppColors.accentBrown,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
