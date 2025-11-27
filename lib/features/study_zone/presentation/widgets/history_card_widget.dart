import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/test_result_entity.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';

class HistoryCard extends StatelessWidget {
  final TestResultEntity result;

  const HistoryCard({super.key, required this.result});

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

  Color _getSuccessColor(BuildContext context, double rate) {
    if (rate >= 80) return context.ext.success;
    if (rate >= 50) return context.ext.warning;
    return context.colors.error;
  }

  @override
  Widget build(BuildContext context) {
    final rateColor = _getSuccessColor(context, result.successRate);
    final compactTime = _getCompactTime(result.date);

    return Container(
      margin: EdgeInsets.symmetric(vertical: context.responsive.spacingXS),
      padding: context.responsive.paddingCard,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(context.responsive.borderRadiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius:
                context.responsive.value(mobile: 22, tablet: 24, desktop: 26),
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
                        color: context.colors.onSurface,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive.spacingS,
                        vertical: context.responsive.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                            context.responsive.borderRadiusS),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: context.responsive.fontSizeSmall,
                              color: context.colors.error),
                          SizedBox(width: context.responsive.spacingXS),
                          Text(
                            compactTime,
                            style: GoogleFonts.poppins(
                              fontSize: context.responsive.fontSizeSmall,
                              fontWeight: FontWeight.w600,
                              color: context.colors.error,
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
                    Icon(Icons.check_circle,
                        size: context.responsive.iconSizeS,
                        color: context.ext.success),
                    SizedBox(width: context.responsive.spacingXS),
                    Text(
                      '${result.correct}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: context.responsive.fontSizeCaption,
                        color: context.colors.onSurface,
                      ),
                    ),
                    SizedBox(width: context.responsive.spacingM),
                    Icon(Icons.cancel,
                        size: context.responsive.iconSizeS,
                        color: context.colors.error),
                    SizedBox(width: context.responsive.spacingXS),
                    Text(
                      '${result.wrong}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: context.responsive.fontSizeCaption,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${result.questions} ${'questions'.tr()}',
                      style: TextStyle(
                        color: context.colors.onSurfaceVariant,
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
