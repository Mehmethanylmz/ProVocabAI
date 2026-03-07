// lib/features/profile/presentation/widgets/share_card_widget.dart
//
// FAZ 13 — F13-05: Zengin paylaşım kartı
//   - RepaintBoundary ile screenshot alınır
//   - share_plus ile paylaşılır

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app/color_palette.dart';
import '../../../auth/presentation/state/auth_bloc.dart';
import '../../../dashboard/domain/entities/dashboard_stats_entity.dart';

class ShareCardWidget extends StatelessWidget {
  final AuthAuthenticated? authData;
  final DashboardStatsEntity stats;

  const ShareCardWidget({
    super.key,
    required this.authData,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = authData?.displayName ?? 'Kullanıcı';
    final totalXp = authData?.totalXp ?? 0;
    final streak = authData?.streakDays ?? 0;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            ColorPalette.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'ProVocabAI',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ShareStat(
                icon: Icons.star_rounded,
                value: _formatNumber(totalXp),
                label: 'Toplam XP',
              ),
              const SizedBox(width: 16),
              _ShareStat(
                icon: Icons.local_fire_department_rounded,
                value: '$streak',
                label: 'Gün Serisi',
              ),
              const SizedBox(width: 16),
              _ShareStat(
                icon: Icons.school_rounded,
                value: '${stats.masteredWords}',
                label: 'Kelime',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Bu hafta ${stats.weekQuestions} soru çözdüm! 🎯',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _ShareStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _ShareStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 3),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

/// Screenshot alıp Share.shareXFiles ile paylaşır.
Future<void> shareProfileCard(GlobalKey repaintKey) async {
  try {
    final boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final Uint8List pngBytes = byteData.buffer.asUint8List();
    final xFile = XFile.fromData(
      pngBytes,
      mimeType: 'image/png',
      name: 'provocabai_profile.png',
    );
    await Share.shareXFiles(
      [xFile],
      text: 'ProVocabAI\'de ilerliyorum! 🚀',
    );
  } catch (_) {
    // Sessizce başarısız ol
  }
}
