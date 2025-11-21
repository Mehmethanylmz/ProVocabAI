import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/test_result.dart';

class HistoryCardWidget extends StatelessWidget {
  final TestResult result;

  const HistoryCardWidget({super.key, required this.result});

  // KISALTILMIŞ FORMAT (2g 16s gibi)
  String _getCompactTime(DateTime testDate) {
    final expiryDate = testDate.add(const Duration(days: 3));
    final remaining = expiryDate.difference(DateTime.now());

    if (remaining.isNegative) return "Arşiv...";

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;

    if (days > 0) return "${days}g ${hours}s";
    if (hours > 0) return "${hours}s";
    return "<1s";
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final rateColor = result.successRate >= 80
        ? Colors.green
        : result.successRate >= 60
            ? Colors.orange
            : Colors.red;

    final compactTime = _getCompactTime(result.date);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(size.width * 0.04), // Padding'i biraz kıstım
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          // Sol: Puan
          CircleAvatar(
            radius: 24, // Biraz küçülttüm
            backgroundColor: rateColor.withOpacity(0.15),
            child: Text('${result.successRate.toInt()}%',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rateColor,
                    fontSize: 14)),
          ),
          const SizedBox(width: 12),

          // Orta: Bilgiler
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Üst Satır: Tarih ve Silinme Sayacı
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM - HH:mm').format(result.date),
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF475569)),
                    ),

                    // YENİ KISA SAYAÇ VE İKON
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 14, color: Colors.red[300]),
                          const SizedBox(width: 4),
                          Text(
                            compactTime,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[300],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Alt Satır: Doğru/Yanlış/Soru
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text('${result.correct}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 12),
                    const Icon(Icons.cancel, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('${result.wrong}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const Spacer(),
                    Text(
                      '${result.questions} Soru',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
