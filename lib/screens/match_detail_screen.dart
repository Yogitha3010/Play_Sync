import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/matchmaking_service.dart';
import '../models/match_model.dart';
import '../models/player_profile_model.dart';
import '../models/booking_model.dart';
import '../models/turf_model.dart';
import '../services/slot_service.dart';
import '../theme/app_theme.dart';
import 'feedback_screen.dart';
import 'chat_screen.dart';
import '../models/team_model.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  _MatchDetailScreenState createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  bool isLoading = true;
  MatchModel? match;
  List<PlayerProfileModel> playerProfiles = [];
  Map<String, List<String>> teams = {'teamA': [], 'teamB': []};
  Map<String, dynamic>? prediction;
  TeamModel? linkedTeam;
  BookingModel? matchBooking;
  bool _feedbackPromptShown = false;

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final MatchmakingService _matchmakingService = MatchmakingService();

  @override
  void initState() {
    super.initState();
    _loadMatch();
  }

  Future<void> _loadMatch() async {
    setState(() => isLoading = true);

    try {
      final matchData = await _firestoreService.getMatch(widget.matchId);
      if (matchData == null) {
        setState(() => isLoading = false);
        return;
      }

      setState(() {
        match = matchData;
        teams = {
          'teamA': List.from(matchData.teamA),
          'teamB': List.from(matchData.teamB),
        };
      });

      if (matchData.teamId != null && matchData.teamId!.isNotEmpty) {
        linkedTeam = await _firestoreService.getTeam(matchData.teamId!);
      } else {
        linkedTeam = null;
      }

      matchBooking = await _firestoreService.getMatchBooking(widget.matchId);

      // Load player profiles
      await _loadPlayerProfiles();

      // Calculate prediction if teams are formed
      if (matchData.teamA.isNotEmpty && matchData.teamB.isNotEmpty) {
        _calculatePrediction();
      }

      await _checkAutoFeedbackNavigation(matchData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading match: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadPlayerProfiles() async {
    if (match == null) return;

    List<PlayerProfileModel> profiles = [];
    for (String playerId in match!.players) {
      final profile = await _firestoreService.getPlayerProfile(playerId);
      if (profile != null) {
        profiles.add(profile);
      }
    }
    setState(() => playerProfiles = profiles);
  }

  void _calculatePrediction() {
    if (match == null) return;

    List<PlayerProfileModel> teamAProfiles = playerProfiles
        .where((p) => match!.teamA.contains(p.userId))
        .toList();
    List<PlayerProfileModel> teamBProfiles = playerProfiles
        .where((p) => match!.teamB.contains(p.userId))
        .toList();

    if (teamAProfiles.isNotEmpty && teamBProfiles.isNotEmpty) {
      setState(() {
        prediction = _matchmakingService.predictMatchOutcome(
          teamAProfiles,
          teamBProfiles,
        );
      });
    }
  }

  Future<void> _joinMatch() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null || match == null) return;

      if (match!.players.contains(currentUser.uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are already in this match')),
        );
        return;
      }

      if (match!.players.length >= match!.maxPlayers) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Match is full')),
        );
        return;
      }

      if (match!.visibility == 'team') {
        final userTeams = await _firestoreService.getTeamsForPlayer(currentUser.uid);
        final isAllowed = match!.teamId != null &&
            userTeams.any((team) => team.teamId == match!.teamId);

        if (!isAllowed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Only team members can join this match')),
          );
          return;
        }
      }

      List<String> updatedPlayers = List.from(match!.players);
      updatedPlayers.add(currentUser.uid);

      await _firestoreService.updateMatch(widget.matchId, {
        'players': updatedPlayers,
      });

      _loadMatch();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining match: $e')),
      );
    }
  }

  Future<void> _leaveMatch() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null || match == null) return;

      if (!match!.players.contains(currentUser.uid)) {
        return;
      }

      List<String> updatedPlayers = List.from(match!.players);
      updatedPlayers.remove(currentUser.uid);

      await _firestoreService.updateMatch(widget.matchId, {
        'players': updatedPlayers,
      });

      _loadMatch();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving match: $e')),
      );
    }
  }

  Future<void> _formTeams() async {
    if (match == null || playerProfiles.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Need at least 2 players to form teams')),
      );
      return;
    }

    try {
      final balancedTeams = _matchmakingService.formBalancedTeams(playerProfiles);

      await _firestoreService.updateMatch(widget.matchId, {
        'teamA': balancedTeams['teamA'],
        'teamB': balancedTeams['teamB'],
      });

      _loadMatch();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error forming teams: $e')),
      );
    }
  }

  Future<void> _performToss() async {
    if (match == null) return;

    final random = DateTime.now().millisecondsSinceEpoch % 2;
    final winner = random == 0 ? 'teamA' : 'teamB';
    final tossChoices = _getTossChoices(match!.gameType);
    final choice =
        tossChoices[DateTime.now().millisecondsSinceEpoch % tossChoices.length];

    try {
      await _firestoreService.updateMatch(widget.matchId, {
        'tossResult': {
          'winner': winner,
          'choice': choice,
        },
        'matchStatus': 'active',
      });

      _loadMatch();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error performing toss: $e')),
      );
    }
  }

  Future<void> _showCompleteMatchDialog() async {
    final teamAScoreCtrl = TextEditingController();
    final teamBScoreCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('End Match - Enter Score'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: teamAScoreCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Team A Score'),
            ),
            TextField(
              controller: teamBScoreCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Team B Score'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _completeMatch(
                int.tryParse(teamAScoreCtrl.text) ?? 0,
                int.tryParse(teamBScoreCtrl.text) ?? 0,
              );
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeMatch(int scoreA, int scoreB) async {
    if (match == null) return;
    setState(() => isLoading = true);

    try {
      // Update the match in Firestore
      await _firestoreService.updateMatch(widget.matchId, {
        'matchStatus': 'completed',
        'score': {
          'teamA': scoreA,
          'teamB': scoreB,
        }
      });

      // Update player win/loss statistics
      String winner = '';
      if (scoreA > scoreB) winner = 'teamA';
      else if (scoreB > scoreA) winner = 'teamB';
      else winner = 'tie';

      for (String playerId in match!.teamA) {
        await _firestoreService.recordMatchResultForPlayer(
          playerId: playerId,
          gameType: match!.gameType,
          won: winner == 'teamA',
          tied: winner == 'tie',
        );
      }

      for (String playerId in match!.teamB) {
        await _firestoreService.recordMatchResultForPlayer(
          playerId: playerId,
          gameType: match!.gameType,
          won: winner == 'teamB',
          tied: winner == 'tie',
        );
      }

      final updatedMatch = await _firestoreService.getMatch(widget.matchId);
      if (updatedMatch != null) {
        await _checkAutoFeedbackNavigation(updatedMatch);
      }
      _loadMatch();
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ending match: $e')),
        );
      }
    }
  }

  Future<void> _checkAutoFeedbackNavigation(MatchModel matchData) async {
    final currentUser = _authService.currentUser;
    if (_feedbackPromptShown ||
        currentUser == null ||
        !matchData.players.contains(currentUser.uid) ||
        matchData.matchStatus != 'completed') {
      return;
    }

    final hasSubmitted = await _firestoreService.hasSubmittedFeedback(
      matchId: matchData.matchId,
      fromUserId: currentUser.uid,
    );

    if (hasSubmitted || matchData.players.length <= 1 || !mounted) {
      return;
    }

    _feedbackPromptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FeedbackScreen(matchId: matchData.matchId),
        ),
      ).then((_) => _loadMatch());
    });
  }

  void _openChatScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatRoomId: match!.matchId,
          chatTitle: 'Match Chat',
        ),
      ),
    );
  }

  void _openFeedbackScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackScreen(matchId: match!.matchId),
      ),
    ).then((_) => _loadMatch());
  }

  String _getEffectiveStatus() {
    if (match == null) return 'pending';
    if (match!.matchStatus == 'active' || match!.matchStatus == 'completed') {
      return match!.matchStatus;
    }
    if (match!.players.length >= match!.maxPlayers) {
      return 'active';
    }
    if (match!.scheduledTime != null &&
        !match!.scheduledTime!.isAfter(DateTime.now())) {
      return 'completed';
    }
    return 'pending';
  }

  Future<void> _deleteCurrentMatch() async {
    if (match == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Match'),
        content: Text('Do you want to delete this match?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isLoading = true);
    try {
      if (matchBooking != null) {
        await _firestoreService.deleteBooking(matchBooking!.bookingId);
      }
      await _firestoreService.deleteMatch(match!.matchId);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting match: $e')));
    }
  }

  Future<void> _showEditMatchDialog() async {
    if (match == null || matchBooking == null) return;

    final turf = await _firestoreService.getTurf(match!.turfId);
    if (turf == null || !mounted) return;

    List<BookingModel> turfBookings = await _firestoreService.getTurfBookings(
      match!.turfId,
    );
    DateTime selectedDate = matchBooking!.bookingDate;
    String selectedSlot = _normalizeSlotTime(matchBooking!.slotTime);
    final generatedSlots = SlotService.generateSlots(
      turf.openingTime,
      turf.closingTime,
    );

    List<String> getAvailableSlots() {
      final totalCourts = turf.courts[match!.gameType] ?? 1;
      final currentBookedSlot = _normalizeSlotTime(matchBooking!.slotTime);
      final slotOptions = List<String>.from(generatedSlots);
      if (!slotOptions.contains(currentBookedSlot)) {
        slotOptions.add(currentBookedSlot);
      }

      return slotOptions.where((slot) {
        final normalizedSlot = _normalizeSlotTime(slot);
        if (normalizedSlot == currentBookedSlot &&
            _isSameDay(selectedDate, matchBooking!.bookingDate)) {
          return true;
        }

        final bookedCount = turfBookings.where((item) {
          if (item.bookingId == matchBooking!.bookingId ||
              item.status == 'cancelled') {
            return false;
          }

          return item.gameType == match!.gameType &&
              _isSameDay(item.bookingDate, selectedDate) &&
              _normalizeSlotTime(item.slotTime) == normalizedSlot;
        }).length;

        return bookedCount < totalCourts;
      }).toList();
    }

    Future<void> refreshBookings(StateSetter setModalState) async {
      turfBookings = await _firestoreService.getTurfBookings(match!.turfId);
      if (!mounted) return;
      setModalState(() {
        final latestSlots = getAvailableSlots();
        if (!latestSlots.contains(selectedSlot)) {
          selectedSlot = latestSlots.isNotEmpty
              ? latestSlots.first
              : _normalizeSlotTime(matchBooking!.slotTime);
        }
      });
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableSlots = getAvailableSlots();

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Edit Match',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${match!.gameType} at ${match!.location}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 15),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current booking',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '${matchBooking!.bookingDate.day}/${matchBooking!.bookingDate.month}/${matchBooking!.bookingDate.year}  |  ${matchBooking!.slotTime}',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    ),
                    trailing: Icon(Icons.calendar_today),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );

                      if (picked != null) {
                        setModalState(() {
                          selectedDate = picked;
                          selectedSlot = _normalizeSlotTime(matchBooking!.slotTime);
                        });
                        await refreshBookings(setModalState);
                      }
                    },
                  ),
                  SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedSlot,
                    decoration: InputDecoration(
                      labelText: 'Available Slot',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    items: availableSlots.map((slot) {
                      final label = slot == _normalizeSlotTime(matchBooking!.slotTime) &&
                              _isSameDay(selectedDate, matchBooking!.bookingDate)
                          ? '$slot (Your booked slot)'
                          : slot;
                      return DropdownMenuItem(value: slot, child: Text(label));
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() => selectedSlot = value);
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await refreshBookings(setModalState);

                        if (!getAvailableSlots().contains(selectedSlot)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'That slot is no longer available. Please choose another one.',
                              ),
                            ),
                          );
                          return;
                        }

                        await _firestoreService.rescheduleBooking(
                          matchBooking!,
                          newBookingDate: selectedDate,
                          newSlotTime: selectedSlot,
                          maxBookingsPerSlot: turf.courts[match!.gameType] ?? 1,
                        );

                        final parts = selectedSlot.split(' - ').first.split(':');
                        final scheduledTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          int.parse(parts[0]),
                          int.parse(parts[1]),
                        );

                        await _firestoreService.updateMatch(match!.matchId, {
                          'scheduledTime': scheduledTime.toIso8601String(),
                        });

                        if (!mounted) return;
                        Navigator.pop(context);
                        await _loadMatch();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating match: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text('Save Changes'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || match == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Match Details'),
          backgroundColor: AppTheme.theme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentUser = _authService.currentUser;
    final isPlayer = currentUser != null && match!.players.contains(currentUser.uid);
    final isCreator = currentUser != null && match!.createdBy == currentUser.uid;
    final isBookingOwner =
        currentUser != null &&
        matchBooking != null &&
        matchBooking!.playerId == currentUser.uid;
    final effectiveStatus = _getEffectiveStatus();
    final canManageMatch =
        effectiveStatus != 'completed' && (isCreator || isBookingOwner);

    return Scaffold(
      appBar: AppBar(
        title: Text('Match Details'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (isPlayer || isCreator)
            TextButton(
              onPressed: _openChatScreen,
              child: Text(
                'Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (effectiveStatus == 'completed' && isPlayer)
            TextButton(
              onPressed: _openFeedbackScreen,
              child: Text(
                'Feedback',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match Info Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          match!.gameType,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(effectiveStatus).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            effectiveStatus.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(effectiveStatus),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    _InfoRow(Icons.location_on, match!.location),
                    if (match!.scheduledTime != null)
                      _InfoRow(
                        Icons.calendar_today,
                        '${match!.scheduledTime!.day}/${match!.scheduledTime!.month}/${match!.scheduledTime!.year} ${match!.scheduledTime!.hour}:${match!.scheduledTime!.minute.toString().padLeft(2, '0')}',
                      ),
                    if (isBookingOwner)
                      _InfoRow(Icons.access_time, 'Booked Slot: ${matchBooking!.slotTime}'),
                    if (match!.visibility == 'team')
                      _InfoRow(
                        Icons.groups,
                        linkedTeam != null
                            ? 'Visible only to ${linkedTeam!.teamName} members'
                            : 'Visible only to team members',
                      ),
                    _InfoRow(Icons.people, '${match!.players.length}/${match!.maxPlayers} players'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    AppTheme.theme.colorScheme.primary.withOpacity(0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.theme.colorScheme.primary.withOpacity(0.14),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (isPlayer || isCreator) ? _openChatScreen : null,
                      icon: Icon(Icons.chat_bubble_outline),
                      label: Text('Chat'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: effectiveStatus == 'completed' && isPlayer
                          ? _openFeedbackScreen
                          : null,
                      icon: Icon(Icons.rate_review_outlined),
                      label: Text(
                        effectiveStatus == 'completed'
                            ? 'Feedback'
                            : 'After Match',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade700,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (canManageMatch) ...[
              SizedBox(height: 18),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.theme.colorScheme.primary.withOpacity(0.10),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.theme.colorScheme.primary.withOpacity(0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Match',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'You can update only the date and slot, or delete this match.',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: matchBooking == null ? null : _showEditMatchDialog,
                            icon: Icon(Icons.edit_calendar),
                            label: Text('Edit Match'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _deleteCurrentMatch,
                            icon: Icon(Icons.delete_outline),
                            label: Text('Delete Match'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 20),

            // Join/Form Teams Buttons
            if (!isPlayer && match!.players.length < match!.maxPlayers)
              ElevatedButton(
                onPressed: _joinMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add),
                    SizedBox(width: 10),
                    Text('Join Match', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),

            if (isPlayer && !isCreator && effectiveStatus == 'pending')
              ElevatedButton(
                onPressed: _leaveMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.exit_to_app),
                    SizedBox(width: 10),
                    Text('Leave Match', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),

            if (isCreator && match!.teamA.isEmpty && match!.players.length >= 2)
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: ElevatedButton(
                  onPressed: _formTeams,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group),
                      SizedBox(width: 10),
                      Text('Form Balanced Teams', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),

            // Teams Section
            if (match!.teamA.isNotEmpty || match!.teamB.isNotEmpty) ...[
              SizedBox(height: 20),
              Text(
                'Teams',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _TeamCard(
                      title: 'Team A',
                      playerIds: match!.teamA,
                      profiles: playerProfiles,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: _TeamCard(
                      title: 'Team B',
                      playerIds: match!.teamB,
                      profiles: playerProfiles,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),

              // Toss Section
              if (match!.tossResult == null && isCreator && effectiveStatus == 'pending')
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: ElevatedButton(
                    onPressed: _performToss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.casino),
                        SizedBox(width: 10),
                        Text('Perform Toss', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),

              // Complete Match Button
              if (isCreator && effectiveStatus == 'active')
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: ElevatedButton(
                    onPressed: _showCompleteMatchDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stop_circle),
                        SizedBox(width: 10),
                        Text('End Match & Log Score', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),

              if (match!.tossResult != null) ...[
                SizedBox(height: 20),
                Card(
                  color: Colors.amber.withOpacity(0.2),
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      children: [
                        Text(
                          '${match!.gameType} Toss Result',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          _buildTossResultText(),
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Score Section
              if (match!.score != null) ...[
                SizedBox(height: 20),
                Card(
                  color: Colors.green.withOpacity(0.2),
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      children: [
                        Text(
                          'Final Score',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              'Team A: ${match!.score!['teamA']}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                            ),
                            Text('-', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                              'Team B: ${match!.score!['teamB']}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[800]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Prediction
              if (prediction != null) ...[
                SizedBox(height: 20),
                Card(
                  color: Colors.purple.withOpacity(0.1),
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Match Prediction',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Team A Win Probability: ${(prediction!['teamAWinProbability'] * 100).toStringAsFixed(1)}%',
                        ),
                        Text(
                          'Team B Win Probability: ${(prediction!['teamBWinProbability'] * 100).toStringAsFixed(1)}%',
                        ),
                        SizedBox(height: 5),
                        LinearProgressIndicator(
                          value: prediction!['teamAWinProbability'],
                          backgroundColor: Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],

            // Players List
            SizedBox(height: 20),
            Text(
              'Players (${match!.players.length})',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            ...playerProfiles.map((profile) {
              return ListTile(
                leading: CircleAvatar(
                  child: Text(profile.name?.substring(0, 1).toUpperCase() ?? 'P'),
                ),
                title: Text(profile.name ?? 'Unknown'),
                subtitle: Text('Rating: ${profile.rating.toStringAsFixed(1)}'),
                trailing: Icon(Icons.star, color: Colors.amber),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  List<String> _getTossChoices(String gameType) {
    switch (gameType.toLowerCase()) {
      case 'cricket':
        return ['bat', 'bowl'];
      case 'badminton':
      case 'tennis':
      case 'pickleball':
        return ['serve', 'receive'];
      case 'football':
        return ['kick-off', 'choose side'];
      case 'basketball':
        return ['first possession', 'choose side'];
      case 'volleyball':
        return ['serve', 'choose side'];
      default:
        return ['start first', 'choose side'];
    }
  }

  String _buildTossResultText() {
    if (match == null || match!.tossResult == null) {
      return '';
    }

    final winningTeam =
        match!.tossResult!['winner'] == 'teamA' ? 'Team A' : 'Team B';
    final choice = match!.tossResult!['choice']?.toString() ?? '';

    switch (match!.gameType.toLowerCase()) {
      case 'cricket':
        return '$winningTeam won the toss and chose to $choice.';
      case 'badminton':
      case 'tennis':
      case 'pickleball':
      case 'volleyball':
        return '$winningTeam won the toss and chose to $choice first.';
      case 'football':
        return choice == 'kick-off'
            ? '$winningTeam won the toss and chose the kick-off.'
            : '$winningTeam won the toss and chose a side.';
      case 'basketball':
        return choice == 'first possession'
            ? '$winningTeam won the toss and chose first possession.'
            : '$winningTeam won the toss and chose a side.';
      default:
        return '$winningTeam won the toss and chose to $choice.';
    }
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _normalizeSlotTime(String slotTime) {
    final parts = slotTime.split('-');
    if (parts.length != 2) {
      return slotTime.trim();
    }

    final start = _normalizeTimeLabel(parts[0]);
    final end = _normalizeTimeLabel(parts[1]);
    return '$start - $end';
  }

  String _normalizeTimeLabel(String value) {
    final match = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*$').firstMatch(value);
    if (match == null) {
      return value.trim();
    }

    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null) {
      return value.trim();
    }

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final String title;
  final List<String> playerIds;
  final List<PlayerProfileModel> profiles;
  final Color color;

  const _TeamCard({
    required this.title,
    required this.playerIds,
    required this.profiles,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final teamProfiles = profiles.where((p) => playerIds.contains(p.userId)).toList();

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 10),
            ...teamProfiles.map((profile) {
              return Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  '• ${profile.name ?? 'Unknown'}',
                  style: TextStyle(fontSize: 14),
                ),
              );
            }),
            if (teamProfiles.isEmpty)
              Text(
                'No players yet',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
