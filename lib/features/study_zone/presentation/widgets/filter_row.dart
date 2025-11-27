import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';

class FilterRow extends StatelessWidget {
  final String title;
  final List<String> items;
  final List<String> selected;
  final Function(String) onTap;
  final Color accentColor;

  const FilterRow({
    super.key,
    required this.title,
    required this.items,
    required this.selected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal:
                  context.responsive.value(mobile: 16, tablet: 24, desktop: 32),
            ),
            child: Text(
              title,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(height: context.responsive.spacingS),
          SizedBox(
            height:
                context.responsive.value(mobile: 45, tablet: 50, desktop: 55),
            child: ListView.separated(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive
                    .value(mobile: 16, tablet: 24, desktop: 32),
              ),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  SizedBox(width: context.responsive.spacingS),
              itemBuilder: (context, i) {
                final item = items[i];
                final isSelected = selected.contains(item);
                return GestureDetector(
                  onTap: () => onTap(item),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive.spacingL,
                      vertical: context.responsive.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor : context.colors.surface,
                      borderRadius: BorderRadius.circular(
                          context.responsive.borderRadiusXL),
                      border: Border.all(
                        color: isSelected
                            ? accentColor
                            : context.colors.outlineVariant,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accentColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        item == 'all' ? 'filter_all'.tr() : item.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: context.responsive.fontSizeCaption,
                          color: isSelected
                              ? Colors.white
                              : context.colors.onSurfaceVariant,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: context.responsive.spacingM),
        ],
      ),
    );
  }
}
