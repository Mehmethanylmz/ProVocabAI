// lib/features/leaderboard/presentation/views/leaderboard_screen.dart
//
// T-20: LeaderboardScreen
// Blueprint:
//   - Haftalık / Global tab (TabBar)
//   - Top 100 liste
//   - Kullanıcı kendi sırası → sticky bottom row
//   - leaderboard_enabled feature flag kontrolü

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../../firebase/firestore/leaderboard_service.dart';
import '../../../../../core/utils/week_id_helper.dart';

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
    _service = LeaderboardService();
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
      final entries = await _service.getWeeklyLeaderboard(_weekId);
      final myEntry = await _service.getUserRank(_currentUid, _weekId);
      if (mounted) {
        setState(() {
          _weeklyEntries = entries;
          _myEntry = myEntry;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liderlik Tablosu'),
        bottom: TabBar(
          controller: _tabController,
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
                    ),
                    // Global tab: Cloud Function'dan ayrı hesaplanır
                    // Sprint 4 sonunda açılır (leaderboard_enabled flag)
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
  });

  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? myEntry;
  final String currentUid;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.amber),
            SizedBox(height: 16),
            Text(
              'Bu hafta henüz kimse XP kazanmadı.\nİlk sen ol!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Scrollable top 100 liste
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {},
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (ctx, i) {
                final entry = entries[i];
                final isMe = entry.uid == currentUid;
                return _LeaderboardTile(
                  entry: entry,
                  isCurrentUser: isMe,
                );
              },
            ),
          ),
        ),

        // Sticky bottom: kullanıcının kendi sırası
        if (myEntry != null) ...[
          const Divider(height: 1),
          _StickyMyRankRow(entry: myEntry!),
        ],
      ],
    );
  }
}

// ── Leaderboard Tile ──────────────────────────────────────────────────────────

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.entry,
    required this.isCurrentUser,
  });

  final LeaderboardEntry entry;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget rankBadge;
    switch (entry.rank) {
      case 1:
        rankBadge = const Text('🥇', style: TextStyle(fontSize: 24));
      case 2:
        rankBadge = const Text('🥈', style: TextStyle(fontSize: 24));
      case 3:
        rankBadge = const Text('🥉', style: TextStyle(fontSize: 24));
      default:
        rankBadge = SizedBox(
          width: 36,
          child: Text(
            '${entry.rank}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        );
    }

    return ListTile(
      leading: rankBadge,
      title: Text(
        entry.displayName,
        style: TextStyle(
          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
          color: isCurrentUser ? theme.colorScheme.primary : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 18),
          const SizedBox(width: 4),
          Text(
            '${entry.weeklyXp} XP',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      tileColor: isCurrentUser
          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
          : null,
    );
  }
}

// ── Sticky My Rank Row ────────────────────────────────────────────────────────

class _StickyMyRankRow extends StatelessWidget {
  const _StickyMyRankRow({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.primaryContainer.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.person_pin, size: 20),
            const SizedBox(width: 8),
            Text(
              'Sıran: #${entry.rank}',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(Icons.star, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(
              '${entry.weeklyXp} XP',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coming Soon ───────────────────────────────────────────────────────────────

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Yakında', style: TextStyle(fontSize: 18, color: Colors.grey)),
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
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text('Yüklenemedi', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}
