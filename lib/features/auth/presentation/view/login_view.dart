import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/base/base_view.dart';
import '../../../../core/constants/navigation/navigation_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/init/di/injection_container.dart';
import '../../../../core/init/navigation/navigation_service.dart';
import '../../../../core/utils/validators.dart';
import '../view_model/auth_view_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<AuthViewModel>(
      viewModel: locator<AuthViewModel>(),
      onModelReady: (model) {},
      builder: (context, viewModel, child) {
        if (viewModel.errorMessage != null && !viewModel.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(viewModel.errorMessage!),
                backgroundColor: context.colors.error,
              ),
            );
            // Mesajı temizle ki sürekli çıkmasın (ViewModel'e cleanError metodu eklenebilir)
          });
        }

        return Scaffold(
          backgroundColor: context.colors.surface,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: context.responsive.paddingPage,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.lock_person_rounded,
                              size: 80, color: context.colors.primary)
                          .animate()
                          .scale(duration: 500.ms),
                      SizedBox(height: context.responsive.spacingL),
                      Text(
                        "Tekrar Hoşgeldin!",
                        textAlign: TextAlign.center,
                        style: context.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurface,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      SizedBox(height: context.responsive.spacingS),
                      Text(
                        "Devam etmek için giriş yapın",
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                      SizedBox(height: context.responsive.spacingXL),
                      TextFormField(
                        controller: _emailController,
                        validator: Validators.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "E-posta",
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ).animate().slideX(begin: -0.1, delay: 300.ms),
                      SizedBox(height: context.responsive.spacingM),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        validator: Validators.validatePassword,
                        decoration: InputDecoration(
                          labelText: "Şifre",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                      ).animate().slideX(begin: -0.1, delay: 400.ms),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => NavigationService.instance
                              .navigateToPage(
                                  path: NavigationConstants.FORGOT_PASSWORD),
                          child: Text("Şifremi Unuttum?",
                              style: TextStyle(color: context.colors.primary)),
                        ),
                      ),
                      SizedBox(height: context.responsive.spacingL),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: viewModel.isLoading
                              ? null
                              : () {
                                  context.closeKeyboard();
                                  if (_formKey.currentState!.validate()) {
                                    viewModel.login(
                                      _emailController.text.trim(),
                                      _passwordController.text.trim(),
                                    );
                                  }
                                },
                          child: viewModel.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text("Giriş Yap",
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ).animate().fadeIn(delay: 500.ms),
                      SizedBox(height: context.responsive.spacingXL),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Hesabın yok mu?",
                              style:
                                  TextStyle(color: context.colors.onSurface)),
                          TextButton(
                            onPressed: () => NavigationService.instance
                                .navigateToPage(
                                    path: NavigationConstants.REGISTER),
                            child: const Text("Kayıt Ol",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
