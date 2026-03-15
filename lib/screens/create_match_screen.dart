import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/matchmaking_service.dart';
import '../models/match_model.dart';
import '../models/player_profile_model.dart';
import '../models/turf_model.dart';
import '../models/booking_model.dart';
import '../theme/app_theme.dart';
import 'match_detail_screen.dart';

class CreateMatchScreen extends StatefulWidget {
  @override
  _CreateMatchScreenState createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final maxPlayersController = TextEditingController(text: '10');

  String selectedGame = 'Cricket';
  TurfModel? selectedTurf;
  List<TurfModel> availableTurfs = [];

  DateTime? scheduledTime;
  int maxPlayers = 10;

  final List<String> games = [
    'Cricket',
    'Badminton',
    'Pickleball',
    'Football',
    'Basketball',
    'Tennis',
  ];
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadTurfsForGame(selectedGame);
  }

  Future<void> _loadTurfsForGame(String gameType) async {
    setState(() => isLoading = true);
    try {
      final turfs = await _firestoreService.searchTurfs(gameType: gameType);
      setState(() {
        availableTurfs = turfs;
        selectedTurf = turfs.isNotEmpty ? turfs.first : null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load turfs: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _createMatch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedTurf == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a Turf location')));
      return;
    }

    setState(() => isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final matchId = Uuid().v4();
      final match = MatchModel(
        matchId: matchId,
        gameType: selectedGame,
        location: selectedTurf!.name, // Fallback location description
        turfId: selectedTurf!.turfId, // Native turf tracking
        createdBy: currentUser.uid,
        players: [currentUser.uid],
        matchStatus: 'pending',
        createdAt: DateTime.now(),
        scheduledTime: scheduledTime,
        maxPlayers: maxPlayers,
      );

      await _firestoreService.createMatch(match);

      // Create booking for the match
      final turf = await _firestoreService.getTurf(match.turfId);
      if (turf != null && match.scheduledTime != null) {
        final booking = BookingModel(
          bookingId: Uuid().v4(),
          turfId: match.turfId,
          turfOwnerId: turf.ownerId,
          playerId: currentUser.uid,
          matchId: match.matchId,
          gameType: selectedGame,
          bookingDate: DateTime(
            match.scheduledTime!.year,
            match.scheduledTime!.month,
            match.scheduledTime!.day,
          ),
          slotTime:
              '${match.scheduledTime!.hour}:${match.scheduledTime!.minute.toString().padLeft(2, '0')} - ${match.scheduledTime!.hour + 1}:${match.scheduledTime!.minute.toString().padLeft(2, '0')}',
          createdAt: DateTime.now(),
        );
        await _firestoreService.createBooking(booking);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MatchDetailScreen(matchId: matchId),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating match: $e')));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          scheduledTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    maxPlayersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Match'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create a New Match',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Set up a match and invite players',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 30),

              // Game Type
              Text(
                'Game Type *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedGame,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.sports_soccer),
                ),
                items: games.map((game) {
                  return DropdownMenuItem(value: game, child: Text(game));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedGame = value;
                      selectedTurf = null;
                    });
                    _loadTurfsForGame(value);
                  }
                },
              ),
              SizedBox(height: 20),

              // Location / Turf Selection
              Text(
                'Select Turf Location *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<TurfModel>(
                value: selectedTurf,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.location_on),
                  hintText: availableTurfs.isEmpty
                      ? 'No turfs available for this sport'
                      : 'Select a Turf',
                ),
                items: availableTurfs.map((turf) {
                  return DropdownMenuItem(
                    value: turf,
                    child: Text('${turf.name} - ${turf.location}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedTurf = value);
                },
                validator: (value) =>
                    value == null ? 'Please select a Turf location' : null,
              ),
              SizedBox(height: 20),

              // Max Players
              TextFormField(
                controller: maxPlayersController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Maximum Players *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.people),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Max players is required';
                  }
                  int? players = int.tryParse(value);
                  if (players == null || players < 2) {
                    return 'Enter at least 2 players';
                  }
                  maxPlayers = players;
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Scheduled Time
              Text(
                'Scheduled Time (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _selectDateTime,
                icon: Icon(Icons.calendar_today),
                label: Text(
                  scheduledTime == null
                      ? 'Select Date & Time'
                      : '${scheduledTime!.day}/${scheduledTime!.month}/${scheduledTime!.year} ${scheduledTime!.hour}:${scheduledTime!.minute.toString().padLeft(2, '0')}',
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 30),

              // Create Button
              ElevatedButton(
                onPressed: isLoading ? null : _createMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Create Match',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
