import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizStartButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isSmallScreen;

  const QuizStartButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: isSmallScreen ? 10 : 16,
        ),
        leading: CircleAvatar(
          backgroundColor: color,
          radius: isSmallScreen ? 24 : 30,
          child: const Icon(Icons.quiz, color: Colors.white, size: 28),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 14 : 16,
            color: Colors.grey[700],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward,
          color: color,
          size: isSmallScreen ? 24 : 32,
        ),
        onTap: onTap,
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }
}
