import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../main/presentation/view/main_view.dart';
import '../view_model/study_view_model.dart';

class TestResultView extends StatelessWidget {
  const TestResultView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StudyViewModel>(
      builder: (context, vm, _) {
        // Test sonucunu bir kere kaydet (mounted sonrası)
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (vm.correctCount + vm.incorrectCount > 0) {
            await vm.saveTestResult();
          }
        });

        final correct = vm.correctCount;
        final wrong = vm.incorrectCount;
        final total = correct + wrong;
        final successRate = total > 0 ? (correct / total) * 100 : 0.0;

        Color resultColor =
            successRate >= 50 ? context.ext.success : context.colors.error;

        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text('test_result_title'.tr())),
          body: Padding(
            padding: context.responsive.paddingPage,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  successRate >= 80
                      ? Icons.emoji_events
                      : (successRate >= 50 ? Icons.thumb_up : Icons.refresh),
                  size: 100,
                  color: resultColor,
                ),
                const SizedBox(height: 20),
                Text(
                  successRate >= 50
                      ? 'test_result_good'.tr()
                      : 'test_result_completed'.tr(),
                  style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: resultColor),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(context, 'correct'.tr(), "$correct",
                        context.ext.success),
                    _buildStat(context, 'incorrect'.tr(), "$wrong",
                        context.colors.error),
                    _buildStat(context, 'success_rate'.tr(),
                        "%${successRate.toInt()}", context.colors.primary),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const MainView()),
                          (route) => false);
                    },
                    child: Text('btn_home'.tr()),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(
      BuildContext context, String title, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(title, style: TextStyle(color: context.colors.onSurfaceVariant)),
      ],
    );
  }
}
