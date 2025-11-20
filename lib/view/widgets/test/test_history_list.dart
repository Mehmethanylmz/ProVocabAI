import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../data/models/test_result.dart';

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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Son 3 günde hiç test çözülmemiş!',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 16 : 20,
              color: Colors.grey[600],
            ),
          ).animate().fadeIn(),
        ),
      );
    }

    final fontSizeCaption = isSmallScreen ? 12.0 : 14.0;

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final result = history[index];
        final remainingTime = _getRemainingTime(result.date);

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey[50]!],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd.MM.yyyy - HH:mm').format(result.date),
                        style: GoogleFonts.poppins(
                          fontSize: fontSizeCaption,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${result.questions} Soru',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildResultChip(
                        Icons.check_circle,
                        '${result.correct}',
                        Colors.green,
                      ),
                      _buildResultChip(
                        Icons.cancel,
                        '${result.wrong}',
                        Colors.red,
                      ),
                      _buildResultChip(
                        Icons.percent,
                        result.successRate.toStringAsFixed(0),
                        Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        remainingTime,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate(delay: (index * 100).ms).fadeIn(duration: 400.ms).slideX();
      },
    );
  }

  Widget _buildResultChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
