import 'package:flutter/material.dart';

import '../models/booking_model.dart';
import '../models/match_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'match_detail_screen.dart';
import 'match_score_calculator_screen.dart';

class MyMatchesByGameScreen extends StatefulWidget {
  final String selectedGame;

  const MyMatchesByGameScreen({
    Key? key,
    required this.selectedGame,
  }) : super(key: key);

  @override
  State<MyMatchesByGameScreen> createState() => _MyMatchesByGameScreenState();
}

class _MyMatchesByGameScreenState extends State<MyMatchesByGameScreen> {
  bool isLoading = true;
  List<MatchModel> matches = [];
  Map<String, BookingModel?> bookingsByMatchId = {};
  String selectedFilter = 'all';

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        if (!mounted) return;
        setState(() => isLoading = false);
        return;
      }

      final allMatches = await _firestoreService.getPlayerMatches(currentUser.uid);
      final filteredByGame = allMatches
          .where((match) => match.gameType == widget.selectedGame)
          .toList();

      final matchBookings = await Future.wait(
        filteredByGame.map(
          (match) async => MapEntry(
            match.matchId,
            await _firestoreService.getMatchBooking(match.matchId),
          ),
        ),
      );

      if (!mounted) return;
      setState(() {
        matches = filteredByGame;
        bookingsByMatchId = {
          for (final entry in matchBookings) entry.key: entry.value,
        };
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading matches: $e')),
      );
    }
  }

  String _getEffectiveStatus(MatchModel match) {
    if (match.matchStatus == 'active' || match.matchStatus == 'completed') {
      return match.matchStatus;
    }

    if (match.players.length >= match.maxPlayers) {
      return 'active';
    }

    if (match.scheduledTime != null &&
        !match.scheduledTime!.isAfter(DateTime.now())) {
      return 'completed';
    }

    return 'pending';
  }

  List<MatchModel> get filteredMatches {
    if (selectedFilter == 'all') return matches;
    return matches.where((m) => _getEffectiveStatus(m) == selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.selectedGame} Matches'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: selectedFilter == 'all',
                  onTap: () => setState(() => selectedFilter = 'all'),
                ),
                _FilterChip(
                  label: 'Pending',
                  isSelected: selectedFilter == 'pending',
                  onTap: () => setState(() => selectedFilter = 'pending'),
                ),
                _FilterChip(
                  label: 'Active',
                  isSelected: selectedFilter == 'active',
                  onTap: () => setState(() => selectedFilter = 'active'),
                ),
                _FilterChip(
                  label: 'Completed',
                  isSelected: selectedFilter == 'completed',
                  onTap: () => setState(() => selectedFilter = 'completed'),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredMatches.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
                            SizedBox(height: 20),
                            Text(
                              'No ${widget.selectedGame} matches found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMatches,
                        child: ListView.builder(
                          padding: EdgeInsets.all(15),
                          itemCount: filteredMatches.length,
                          itemBuilder: (context, index) {
                            final match = filteredMatches[index];
                            return _MatchCard(
                              match: match,
                              booking: bookingsByMatchId[match.matchId],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        MatchDetailScreen(matchId: match.matchId),
                                  ),
                                );
                              },
                              onOpenCalculator: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        MatchScoreCalculatorScreen(match: match),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.theme.colorScheme.primary
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchModel match;
  final BookingModel? booking;
  final VoidCallback onTap;
  final VoidCallback onOpenCalculator;

  const _MatchCard({
    required this.match,
    required this.booking,
    required this.onTap,
    required this.onOpenCalculator,
  });

  String _getEffectiveStatus(MatchModel match) {
    if (match.matchStatus == 'active' || match.matchStatus == 'completed') {
      return match.matchStatus;
    }

    if (match.players.length >= match.maxPlayers) {
      return 'active';
    }

    if (match.scheduledTime != null &&
        !match.scheduledTime!.isAfter(DateTime.now())) {
      return 'completed';
    }

    return 'pending';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFE79A2D);
      case 'active':
        return AppTheme.secondary;
      case 'completed':
        return AppTheme.accent;
      default:
        return AppTheme.mutedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStatus = _getEffectiveStatus(match);

    return Card(
      margin: EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      match.gameType,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getStatusColor(effectiveStatus).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      effectiveStatus.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(effectiveStatus),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      match.location,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey),
                  SizedBox(width: 5),
                  Text('${match.players.length}/${match.maxPlayers} players'),
                  SizedBox(width: 20),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  SizedBox(width: 5),
                  Text(
                    match.scheduledTime != null
                        ? '${match.scheduledTime!.day}/${match.scheduledTime!.month}/${match.scheduledTime!.year}'
                        : 'No date set',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              if (booking != null) ...[
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey),
                    SizedBox(width: 5),
                    Text(
                      'Booked slot: ${booking!.slotTime}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
              if (effectiveStatus == 'active') ...[
                SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onOpenCalculator,
                        icon: Icon(Icons.calculate_outlined),
                        label: Text('Open Calculator'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: BorderSide(color: AppTheme.border),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
