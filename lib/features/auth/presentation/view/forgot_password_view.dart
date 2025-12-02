import 'package:flutter/material.dart';
import '../../../../core/base/base_view.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/init/di/injection_container.dart';
import '../../../../core/utils/validators.dart';
import '../view_model/auth_view_model.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return BaseView<AuthViewModel>(
      viewModel: locator<AuthViewModel>(),
      onModelReady: (_) {},
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(title: const Text("Şifremi Sıfırla")),
          body: Padding(
            padding: context.responsive.paddingPage,
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  const Text(
                      "E-posta adresinizi girin, size sıfırlama bağlantısı gönderelim."),
                  SizedBox(height: context.responsive.spacingL),
                  TextFormField(
                    controller: emailController,
                    validator: Validators.validateEmail,
                    decoration: const InputDecoration(
                        labelText: "E-posta", prefixIcon: Icon(Icons.email)),
                  ),
                  SizedBox(height: context.responsive.spacingXL),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          viewModel.forgotPassword(emailController.text.trim());
                        }
                      },
                      child: const Text("Gönder"),
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
