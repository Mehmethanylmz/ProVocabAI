import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/extensions/context_extensions.dart';

class SocialView extends StatelessWidget {
  const SocialView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: Text('nav_hub'.tr()), // json'a ekleyeceğiz
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hub_rounded,
                size: 80, color: context.colors.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              "Yakında: AI Sohbet & Arkadaşların",
              style: context.textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
