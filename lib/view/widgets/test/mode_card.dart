import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ModeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final bool enabled;
  final VoidCallback onTap;

  const ModeCard({
    super.key,
    required this.title,
    required this.icon,
    required this.gradient,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(enabled ? 0.15 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white70, size: 16),
            ],
          ),
        ),
      ).animate().scale(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack),
    );
  }
}
