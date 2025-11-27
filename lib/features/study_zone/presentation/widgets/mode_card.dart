import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/extensions/responsive_extension.dart';

class ModeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradient;
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
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive.spacingXL,
          vertical: context.responsive.spacingL,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(context.responsive.borderRadiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(enabled ? 0.15 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.responsive.spacingM),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: context.responsive.iconSizeM,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: context.responsive.spacingL),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: context.responsive.fontSizeH3,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: context.responsive.iconSizeS,
              ),
            ],
          ),
        ),
      ).animate().scale(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
          ),
    );
  }
}
