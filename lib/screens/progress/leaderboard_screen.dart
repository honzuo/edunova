import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _topUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    final data = await DatabaseService().getLeaderboard();
    if (mounted) {
      setState(() {
        _topUsers = data;
        _isLoading = false;
      });
    }
  }

  // 帮前三名加上金银铜牌
  Widget _buildRankIcon(int index) {
    if (index == 0) return const Text('🥇', style: TextStyle(fontSize: 28));
    if (index == 1) return const Text('🥈', style: TextStyle(fontSize: 28));
    if (index == 2) return const Text('🥉', style: TextStyle(fontSize: 28));
    return CircleAvatar(
      backgroundColor: Colors.grey[200],
      radius: 16,
      child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Leaderboard 🏆', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchLeaderboard();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _topUsers.isEmpty
          ? const Center(child: Text('No study records yet. Be the first!'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _topUsers.length,
        itemBuilder: (context, index) {
          final user = _topUsers[index];
          final isTop3 = index < 3;

          return Card(
            elevation: isTop3 ? 4 : 1,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isTop3 ? BorderSide(color: const Color(0xFFFFD700).withAlpha(100), width: 2) : BorderSide.none,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: _buildRankIcon(index),
              title: Text(
                user['user_name'],
                style: TextStyle(
                  fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTop3 ? 18 : 16,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${user['total_minutes']} mins',
                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}