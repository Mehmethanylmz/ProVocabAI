import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

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
    final size = MediaQuery.of(context).size;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
            child: Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569))),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final item = items[i];
                final isSelected = selected.contains(item);
                return GestureDetector(
                  onTap: () => onTap(item),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color:
                              isSelected ? accentColor : Colors.grey.shade300,
                          width: 1.5),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: accentColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4))
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        item == 'all' ? 'filter_all'.tr() : item.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isSelected ? Colors.white : Colors.grey[700],
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
          SizedBox(height: size.height * 0.02),
        ],
      ),
    );
  }
}
