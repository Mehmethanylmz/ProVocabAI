import 'package:flutter/material.dart';
import '../../../../core/constants/navigation/navigation_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/init/navigation/navigation_service.dart';

class EmailVerificationView extends StatelessWidget {
  const EmailVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: context.responsive.paddingPage,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_read,
                size: 100, color: context.colors.primary),
            SizedBox(height: context.responsive.spacingL),
            Text("E-postanızı Kontrol Edin",
                style: context.textTheme.headlineSmall),
            SizedBox(height: context.responsive.spacingM),
            const Text(
              "Kayıt olduğunuz adrese doğrulama bağlantısı gönderdik. Lütfen onaylayıp giriş yapın.",
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.responsive.spacingXL),
            ElevatedButton(
              onPressed: () => NavigationService.instance
                  .navigateToPageClear(path: NavigationConstants.LOGIN),
              child: const Text("Giriş Ekranına Dön"),
            ),
          ],
        ),
      ),
    );
  }
}
