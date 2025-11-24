import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/test_result.dart';
import '../../../core/extensions/responsive_extension.dart';
import '../../../core/constants/app_colors.dart';

class HistoryCardWidget extends StatelessWidget {
  final TestResult result;

  const HistoryCardWidget({super.key, required this.result});

  String _getCompactTime(DateTime testDate) {
    final expiryDate = testDate.add(const Duration(days: 3));
    final remaining = expiryDate.difference(DateTime.now());

    if (remaining.isNegative) return "archive".tr();

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;

    if (days > 0) return "${days}g ${hours}s";
    if (hours > 0) return "${hours}s";
    return "<1s";
  }

  @override
  Widget build(BuildContext context) {
    final rateColor = AppColors.getSuccessColor(result.successRate);
    final compactTime = _getCompactTime(result.date);

    return Container(
      margin: EdgeInsets.symmetric(vertical: context.responsive.spacingXS),
      padding: context.responsive.paddingCard,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: context.responsive.value(
              mobile: 22,
              tablet: 24,
              desktop: 26,
            ),
            backgroundColor: rateColor.withOpacity(0.15),
            child: Text(
              '${result.successRate.toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: rateColor,
                fontSize: context.responsive.fontSizeCaption,
              ),
            ),
          ),
          SizedBox(width: context.responsive.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM - HH:mm').format(result.date),
                      style: GoogleFonts.poppins(
                        fontSize: context.responsive.fontSizeBody,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive.spacingS,
                        vertical: context.responsive.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          context.responsive.borderRadiusS,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: context.responsive.fontSizeSmall,
                            color: AppColors.error,
                          ),
                          SizedBox(width: context.responsive.spacingXS),
                          Text(
                            compactTime,
                            style: GoogleFonts.poppins(
                              fontSize: context.responsive.fontSizeSmall,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.responsive.spacingS),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: context.responsive.iconSizeS,
                      color: AppColors.success,
                    ),
                    SizedBox(width: context.responsive.spacingXS),
                    Text(
                      '${result.correct}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: context.responsive.fontSizeCaption,
                      ),
                    ),
                    SizedBox(width: context.responsive.spacingM),
                    Icon(
                      Icons.cancel,
                      size: context.responsive.iconSizeS,
                      color: AppColors.error,
                    ),
                    SizedBox(width: context.responsive.spacingXS),
                    Text(
                      '${result.wrong}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: context.responsive.fontSizeCaption,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${result.questions} ${'questions'.tr()}',
                      style: TextStyle(
                        color: AppColors.textDisabled,
                        fontSize: context.responsive.fontSizeSmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 400))
        .slideY(begin: 0.2);
  }
}
