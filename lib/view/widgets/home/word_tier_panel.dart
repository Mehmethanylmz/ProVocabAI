import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class WordTierPanel extends StatelessWidget {
  final Map<String, int> tierDistribution;
  final bool isSmallScreen;

  const WordTierPanel({
    super.key,
    required this.tierDistribution,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final colors = {
      'Unlearned': Colors.grey[700]!,
      'Struggling': Colors.red[600]!,
      'Novice': Colors.orange[600]!,
      'Apprentice': Colors.blue[700]!,
      'Expert': Colors.green[600]!,
    };
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: tierDistribution.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colors[entry.key],
                    radius: isSmallScreen ? 10 : 12,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 18 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    entry.value.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 18 : 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ).animate().slideX(begin: -0.1, duration: 400.ms);
          }).toList(),
        ),
      ),
    );
  }
}
