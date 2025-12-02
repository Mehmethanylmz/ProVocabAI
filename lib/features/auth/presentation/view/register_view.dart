import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/base/base_view.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/init/di/injection_container.dart';
import '../../../../core/utils/validators.dart';
import '../view_model/auth_view_model.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<AuthViewModel>(
      viewModel: locator<AuthViewModel>(),
      onModelReady: (_) {},
      builder: (context, viewModel, child) {
        if (viewModel.errorMessage != null && !viewModel.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(viewModel.errorMessage!),
                  backgroundColor: context.colors.error),
            );
          });
        }

        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: AppBar(title: const Text("Kayıt Ol")),
          body: SingleChildScrollView(
            padding: context.responsive.paddingPage,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: context.responsive.spacingL),
                  Text(
                    "Aramıza Katıl",
                    style: context.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ).animate().fadeIn(),
                  SizedBox(height: context.responsive.spacingL),
                  TextFormField(
                    controller: _nameController,
                    validator: (v) => v!.isEmpty ? "İsim gerekli" : null,
                    decoration: const InputDecoration(
                      labelText: "Ad Soyad",
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  SizedBox(height: context.responsive.spacingM),
                  TextFormField(
                    controller: _emailController,
                    validator: Validators.validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "E-posta",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  SizedBox(height: context.responsive.spacingM),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    validator: Validators.validatePassword,
                    decoration: const InputDecoration(
                      labelText: "Şifre",
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  SizedBox(height: context.responsive.spacingXL),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () {
                              context.closeKeyboard();
                              if (_formKey.currentState!.validate()) {
                                viewModel.register(
                                  _nameController.text.trim(),
                                  _emailController.text.trim(),
                                  _passwordController.text.trim(),
                                );
                              }
                            },
                      child: viewModel.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text("Kayıt Ol",
                              style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
