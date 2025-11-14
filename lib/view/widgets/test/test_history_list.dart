import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/test_result.dart';

class TestHistoryList extends StatelessWidget {
  final List<TestResult> history;
  final bool isSmallScreen;

  const TestHistoryList({
    super.key,
    required this.history,
    required this.isSmallScreen,
  });

  String _getRemainingTime(DateTime testDate) {
    final expiryDate = testDate.add(const Duration(days: 3));
    final remaining = expiryDate.difference(DateTime.now());

    if (remaining.isNegative) return "Arşivleniyor...";

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;

    if (days > 0) return "Silinmesine: $days gün $hours saat kaldı";
    if (hours > 0) return "Silinmesine: $hours saat kaldı";
    return "Silinmesine: 1 saatten az kaldı";
  }

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Text(
          'Son 3 günde hiç test çözülmemiş!',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 16 : 20,
            color: Colors.grey[600],
          ),
        ).animate().fadeIn(),
      );
    }

    final fontSizeCaption = isSmallScreen ? 12.0 : 14.0;
    final fontSizeValue = isSmallScreen ? 16.0 : 18.0;

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final result = history[index];
        final remainingTime = _getRemainingTime(result.date);

        return Card(
          elevation: 6,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd.MM.yyyy - HH:mm').format(result.date),
                    style: GoogleFonts.poppins(
                      fontSize: fontSizeCaption,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${result.questions} Soru',
                        style: GoogleFonts.poppins(
                          fontSize: fontSizeValue,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${result.successRate.toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                          fontSize: fontSizeValue + 2,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Doğru: ${result.correct}',
                        style: GoogleFonts.poppins(
                          fontSize: fontSizeCaption,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        'Yanlış: ${result.wrong}',
                        style: GoogleFonts.poppins(
                          fontSize: fontSizeCaption,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Süre: ${result.duration.inMinutes}d ${result.duration.inSeconds % 60}s',
                    style: GoogleFonts.poppins(
                      fontSize: fontSizeCaption,
                      color: Colors.blue[700],
                    ),
                  ),
                  Divider(height: 20),
                  Row(
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 8),
                      Text(
                        remainingTime,
                        style: GoogleFonts.poppins(
                          fontSize: fontSizeCaption,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate(delay: (index * 150).ms).fadeIn(duration: 600.ms);
      },
    );
  }
}
