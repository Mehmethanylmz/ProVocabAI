// lib/features/study_zone/presentation/widgets/review_rating_sheet.dart
//
// FAZ 1 FIX:
//   F1-05: Countdown 3 saniye → 2 saniye (daha hızlı akış)
//   Deprecated API düzeltmeleri: withOpacity→withValues

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../srs/fsrs_state.dart';
import '../state/study_zone_bloc.dart';
import '../state/study_zone_event.dart';

// ── ReviewRatingSheet ─────────────────────────────────────────────────────────

class ReviewRatingSheet extends StatefulWidget {
  final int responseMs;

  const ReviewRatingSheet({super.key, required this.responseMs});

  static Future<void> show(
    BuildContext context, {
    required int responseMs,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<StudyZoneBloc>(),
        child: ReviewRatingSheet(responseMs: responseMs),
      ),
    );
  }

  @override
  State<ReviewRatingSheet> createState() => _ReviewRatingSheetState();
}

class _ReviewRatingSheetState extends State<ReviewRatingSheet>
    with SingleTickerProviderStateMixin {
  // F1-05: 3 → 2 saniye countdown
  static const _countdownSeconds = 2;

  late int _remaining;
  Timer? _timer;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _remaining = _countdownSeconds;

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _countdownSeconds),
    )..forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        _submitRating(ReviewRating.good); // GOOD default
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _submitRating(ReviewRating rating) {
    _timer?.cancel();
    if (!mounted) return;
    context.read<StudyZoneBloc>().add(
          AnswerSubmitted(rating: rating, responseMs: widget.responseMs),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Countdown bar
              _CountdownBar(
                controller: _progressController,
                remaining: _remaining,
                total: _countdownSeconds,
              ),
              const SizedBox(height: 16),

              // Başlık
              Text(
                'Bu kelimeyi ne kadar iyi hatırladın?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '$_remaining sn içinde seçilmezse "İyi" seçilir',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // 4 rating butonu — 2x2 grid
              Row(
                children: [
                  Expanded(
                    child: _RatingButton(
                      label: 'Çok Zor',
                      sublabel: 'Unutmuştum',
                      rating: ReviewRating.again,
                      color: const Color(0xFFE53935),
                      onTap: () => _submitRating(ReviewRating.again),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RatingButton(
                      label: 'Zor',
                      sublabel: 'Zorlandım',
                      rating: ReviewRating.hard,
                      color: const Color(0xFFFB8C00),
                      onTap: () => _submitRating(ReviewRating.hard),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _RatingButton(
                      label: 'İyi',
                      sublabel: 'Hatırladım',
                      rating: ReviewRating.good,
                      color: const Color(0xFF43A047),
                      isDefault: true,
                      onTap: () => _submitRating(ReviewRating.good),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RatingButton(
                      label: 'Kolay',
                      sublabel: 'Çok kolaydı',
                      rating: ReviewRating.easy,
                      color: const Color(0xFF1E88E5),
                      onTap: () => _submitRating(ReviewRating.easy),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _CountdownBar ─────────────────────────────────────────────────────────────

class _CountdownBar extends StatelessWidget {
  final AnimationController controller;
  final int remaining;
  final int total;

  const _CountdownBar({
    required this.controller,
    required this.remaining,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: 1 - controller.value,
          minHeight: 4,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            remaining <= 1
                ? const Color(0xFFE53935)
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

// ── _RatingButton ─────────────────────────────────────────────────────────────

class _RatingButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final ReviewRating rating;
  final Color color;
  final bool isDefault;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.sublabel,
    required this.rating,
    required this.color,
    required this.onTap,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: ValueKey('rating_${rating.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: isDefault ? Border.all(color: color, width: 2) : null,
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
