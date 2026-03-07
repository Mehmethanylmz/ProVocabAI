// FAZ 8C: Font migration GoogleFonts.poppins → GoogleFonts.inter
// lib/features/leaderboard/presentation/views/leaderboard_screen.dart
//
// FAZ 4 FIX:
//   - LeaderboardService DI → getIt (doğrudan new yerine)
//   - RefreshIndicator.onRefresh bağlandı
//   - Podium top 3 tasarımı
//   - Deprecated API: withOpacity → withValues
//   - FirebaseAuth.instance.currentUser direkt erişim (screen seviyesinde kabul edilebilir)
//   - getWeeklyLeaderboard() artık users collection'dan sorgu yapar

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/init/theme/app_theme_extension.dart';
import '../../../../core/utils/week_id_helper.dart';
import '../../../../firebase/firestore/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final LeaderboardService _service;
  late final String _weekId;

  List<LeaderboardEntry> _weeklyEntries = [];
  LeaderboardEntry? _myEntry;
  bool _loading = true;
  String? _error;

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _service = getIt<LeaderboardService>();
    _weekId = WeekIdHelper.currentWeekId();
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getWeeklyLeaderboard(_weekId),
        _service.getUserRank(_currentUid, _weekId),
      ]);
      if (mounted) {
        setState(() {
          _weeklyEntries = results[0] as List<LeaderboardEntry>;
          _myEntry = results[1] as LeaderboardEntry?;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Liderlik Tablosu',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Bu Hafta'),
            Tab(text: 'Tüm Zamanlar'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _WeeklyTab(
                      entries: _weeklyEntries,
                      myEntry: _myEntry,
                      currentUid: _currentUid,
                      onRefresh: _load,
                      weekId: _weekId,
                    ),
                    const _ComingSoonTab(),
                  ],
                ),
    );
  }
}

// ── Weekly Tab ────────────────────────────────────────────────────────────────

class _WeeklyTab extends StatelessWidget {
  const _WeeklyTab({
    required this.entries,
    required this.myEntry,
    required this.currentUid,
    required this.onRefresh,
    required this.weekId,
  });

  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? myEntry;
  final String currentUid;
  final Future<void> Function() onRefresh;
  final String weekId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 64, color: ext.tertiary.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              'Bu hafta henüz kimse XP kazanmadı.\nİlk sen ol!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // Top 3 podium + geri kalan liste
    final podiumEntries = entries.take(3).toList();
    final listEntries =
        entries.length > 3 ? entries.sublist(3) : <LeaderboardEntry>[];

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: CustomScrollView(
              slivers: [
                // Hafta bilgisi
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '📅 $weekId',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Podium (top 3)
                SliverToBoxAdapter(
                  child: _PodiumSection(
                    entries: podiumEntries,
                    currentUid: currentUid,
                  ),
                ),

                // Geri kalan liste (4+)
                if (listEntries.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final entry = listEntries[i];
                        final isMe = entry.uid == currentUid;
                        return _LeaderboardTile(
                          entry: entry,
                          isCurrentUser: isMe,
                        );
                      },
                      childCount: listEntries.length,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Sticky bottom: kullanıcının kendi sırası
        if (myEntry != null &&
            !entries.any((e) => e.uid == myEntry!.uid && e.rank <= 3)) ...[
          const Divider(height: 1),
          _StickyMyRankRow(entry: myEntry!),
        ],
      ],
    );
  }
}

// ── Podium Section (Top 3) ────────────────────────────────────────────────────

class _PodiumSection extends StatelessWidget {
  const _PodiumSection({
    required this.entries,
    required this.currentUid,
  });

  final List<LeaderboardEntry> entries;
  final String currentUid;

  @override
  Widget build(BuildContext context) {
    // Podium sırası: 2nd | 1st | 3rd (ortada 1.)
    final first = entries.isNotEmpty ? entries[0] : null;
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          if (second != null)
            Expanded(
              child: _PodiumItem(
                entry: second,
                medal: '🥈',
                height: 90,
                isCurrentUser: second.uid == currentUid,
              ),
            )
          else
            const Expanded(child: SizedBox()),
          const SizedBox(width: 8),

          // 1st place (tallest)
          if (first != null)
            Expanded(
              child: _PodiumItem(
                entry: first,
                medal: '🥇',
                height: 120,
                isCurrentUser: first.uid == currentUid,
              ),
            )
          else
            const Expanded(child: SizedBox()),
          const SizedBox(width: 8),

          // 3rd place
          if (third != null)
            Expanded(
              child: _PodiumItem(
                entry: third,
                medal: '🥉',
                height: 70,
                isCurrentUser: third.uid == currentUid,
              ),
            )
          else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  const _PodiumItem({
    required this.entry,
    required this.medal,
    required this.height,
    required this.isCurrentUser,
  });

  final LeaderboardEntry entry;
  final String medal;
  final double height;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Medal
        Text(medal, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),

        // Avatar
        CircleAvatar(
          radius: 22,
          backgroundColor:
              isCurrentUser ? scheme.primary : scheme.surfaceContainerHighest,
          child: Text(
            entry.displayName.isNotEmpty
                ? entry.displayName[0].toUpperCase()
                : '?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isCurrentUser ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Name
        Text(
          entry.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
            color: isCurrentUser ? scheme.primary : null,
          ),
        ),

        // Podium bar
        Container(
          height: height,
          width: double.infinity,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCurrentUser
                  ? [
                      scheme.primary.withValues(alpha: 0.3),
                      scheme.primary.withValues(alpha: 0.1)
                    ]
                  : [
                      scheme.surfaceContainerHighest,
                      scheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: isCurrentUser
                ? Border.all(color: scheme.primary.withValues(alpha: 0.3))
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded,
                    color: Theme.of(context).extension<AppThemeExtension>()!.tertiary,
                    size: 18),
                const SizedBox(height: 2),
                Text(
                  '${entry.weeklyXp}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'XP',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Leaderboard Tile (4th+) ──────────────────────────────────────────────────

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.entry,
    required this.isCurrentUser,
  });

  final LeaderboardEntry entry;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? scheme.primaryContainer.withValues(alpha: 0.3)
            : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: SizedBox(
          width: 32,
          child: Text(
            '${entry.rank}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        title: Text(
          entry.displayName,
          style: GoogleFonts.inter(
            fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
            color: isCurrentUser ? scheme.primary : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded,
                color: Theme.of(context).extension<AppThemeExtension>()!.tertiary,
                size: 16),
            const SizedBox(width: 4),
            Text(
              '${entry.weeklyXp} XP',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sticky My Rank Row ────────────────────────────────────────────────────────

class _StickyMyRankRow extends StatelessWidget {
  const _StickyMyRankRow({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.primaryContainer.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.person_pin_rounded, size: 20),
          const SizedBox(width: 8),
          Text(
            'Sıran: #${entry.rank}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Icon(Icons.star_rounded,
              color: Theme.of(context).extension<AppThemeExtension>()!.tertiary,
              size: 18),
          const SizedBox(width: 4),
          Text(
            '${entry.weeklyXp} XP',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Coming Soon ───────────────────────────────────────────────────────────────

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('Yakında',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text('Yüklenemedi',
              style:
                  GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}
