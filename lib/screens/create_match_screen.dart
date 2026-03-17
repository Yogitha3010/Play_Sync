import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/match_model.dart';
import '../models/turf_model.dart';
import '../models/booking_model.dart';
import '../models/team_model.dart';
import '../theme/app_theme.dart';
import 'match_detail_screen.dart';

class CreateMatchScreen extends StatefulWidget {
  final TeamModel? team;

  const CreateMatchScreen({Key? key, this.team}) : super(key: key);

  @override
  _CreateMatchScreenState createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final maxPlayersController = TextEditingController(text: '10');
  final List<String> _allSlots = const [
    '06:00 - 07:00',
    '07:00 - 08:00',
    '08:00 - 09:00',
    '16:00 - 17:00',
    '17:00 - 18:00',
    '18:00 - 19:00',
    '19:00 - 20:00',
    '20:00 - 21:00',
    '21:00 - 22:00',
  ];

  String selectedGame = 'Cricket';
  TurfModel? selectedTurf;
  List<TurfModel> availableTurfs = [];
  List<BookingModel> turfBookings = [];

  DateTime? selectedDate;
  String? selectedSlot;
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
    if (widget.team != null) {
      selectedGame = widget.team!.gameType;
    }
    _loadTurfsForGame(selectedGame);
  }

  Future<void> _loadTurfsForGame(String gameType) async {
    setState(() => isLoading = true);
    try {
      final turfs = await _firestoreService.searchTurfs(gameType: gameType);
      final initialTurf = turfs.isNotEmpty ? turfs.first : null;
      final initialBookings = initialTurf != null
          ? await _firestoreService.getTurfBookings(initialTurf.turfId)
          : <BookingModel>[];
      setState(() {
        availableTurfs = turfs;
        selectedTurf = initialTurf;
        turfBookings = initialBookings;
        selectedDate = null;
        selectedSlot = null;
        scheduledTime = null;
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

    if (selectedDate == null || selectedSlot == null || scheduledTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a booking date and available slot')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await _refreshBookingsForCurrentTurf(keepSelection: true);
      final latestAvailableSlots = _getAvailableSlots();
      if (selectedSlot == null || !latestAvailableSlots.contains(selectedSlot)) {
        setState(() {
          selectedSlot = null;
          scheduledTime = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('That slot was just booked. Please choose another available slot.'),
          ),
        );
        return;
      }

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
        visibility: widget.team != null ? 'team' : 'public',
        teamId: widget.team?.teamId,
      );

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
            selectedDate!.year,
            selectedDate!.month,
            selectedDate!.day,
          ),
          slotTime: selectedSlot!,
          createdAt: DateTime.now(),
        );
        await _firestoreService.createBooking(
          booking,
          maxBookingsPerSlot: turf.courts[selectedGame] ?? 1,
        );
      }

      await _firestoreService.createMatch(match);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MatchDetailScreen(matchId: matchId),
          ),
        );
      }
    } on BookingConflictException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
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

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
        selectedSlot = null;
        scheduledTime = null;
      });
      await _refreshBookingsForCurrentTurf(keepSelection: true);
    }
  }

  Future<void> _loadBookingsForSelectedTurf(TurfModel? turf) async {
    if (turf == null) {
      setState(() {
        turfBookings = [];
        selectedDate = null;
        selectedSlot = null;
        scheduledTime = null;
      });
      return;
    }

    final bookings = await _firestoreService.getTurfBookings(turf.turfId);
    if (!mounted) return;
    setState(() {
      selectedTurf = turf;
      turfBookings = bookings;
      selectedDate = null;
      selectedSlot = null;
      scheduledTime = null;
    });
  }

  Future<void> _refreshBookingsForCurrentTurf({
    bool keepSelection = false,
  }) async {
    if (selectedTurf == null) return;

    final bookings = await _firestoreService.getTurfBookings(selectedTurf!.turfId);
    if (!mounted) return;

    setState(() {
      turfBookings = bookings;
      if (!keepSelection) {
        selectedDate = null;
        selectedSlot = null;
        scheduledTime = null;
      } else if (selectedSlot != null && _getRemainingCapacity(selectedSlot!) <= 0) {
        selectedSlot = null;
        scheduledTime = null;
      }
    });
  }

  List<String> _getAvailableSlots() {
    if (selectedDate == null || selectedTurf == null) {
      return [];
    }

    return _allSlots.where((slot) {
      return _isSlotInFuture(slot) && _getRemainingCapacity(slot) > 0;
    }).toList();
  }

  int _getRemainingCapacity(String slotTime) {
    if (selectedDate == null || selectedTurf == null) {
      return 0;
    }

    final normalizedSlot = _normalizeSlotTime(slotTime);
    final totalCourts = selectedTurf!.courts[selectedGame] ?? 1;
    final bookedCount = turfBookings.where((booking) {
      return booking.status != 'cancelled' &&
          booking.gameType == selectedGame &&
          _isSameDay(booking.bookingDate, selectedDate!) &&
          _normalizeSlotTime(booking.slotTime) == normalizedSlot;
    }).length;

    final remaining = totalCourts - bookedCount;
    return remaining > 0 ? remaining : 0;
  }

  void _updateScheduledTimeFromSelection() {
    if (selectedDate == null || selectedSlot == null) {
      scheduledTime = null;
      return;
    }

    final parts = _normalizeSlotTime(selectedSlot!).split(' - ');
    final timeParts = parts.first.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    scheduledTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      hour,
      minute,
    );
  }

  bool _isSlotInFuture(String slotTime) {
    if (selectedDate == null) {
      return false;
    }

    final parts = _normalizeSlotTime(slotTime).split(' - ');
    final start = parts.first.split(':');
    final slotStart = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      int.parse(start[0]),
      int.parse(start[1]),
    );

    return slotStart.isAfter(DateTime.now());
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

  @override
  void dispose() {
    maxPlayersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableSlots = _getAvailableSlots();
    if (selectedSlot != null && !availableSlots.contains(selectedSlot)) {
      selectedSlot = null;
      scheduledTime = null;
    }

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
              if (widget.team != null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.theme.colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.groups, color: AppTheme.theme.colorScheme.primary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This match will be visible only to members of ${widget.team!.teamName}.',
                          style: TextStyle(
                            color: AppTheme.theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                onChanged: widget.team != null
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            selectedGame = value;
                            selectedTurf = null;
                            turfBookings = [];
                            selectedDate = null;
                            selectedSlot = null;
                            scheduledTime = null;
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
                  _loadBookingsForSelectedTurf(value);
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

              // Booking Date
              Text(
                'Booking Date *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: selectedTurf == null ? null : _selectDate,
                icon: Icon(Icons.calendar_today),
                label: Text(
                  selectedDate == null
                      ? 'Select Booking Date'
                      : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 20),

              Text(
                'Available Time Slot *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              if (selectedDate == null)
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text('Select a booking date to see available slots'),
                )
              else if (availableSlots.isEmpty)
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    'No slots available for this Date .',
                    style: TextStyle(color: Colors.orange.shade900),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: selectedSlot,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  items: availableSlots.map((slot) {
                    final remainingCourts = _getRemainingCapacity(slot);
                    final label = remainingCourts > 1
                        ? '$slot ($remainingCourts courts left)'
                        : slot;
                    return DropdownMenuItem(
                      value: slot,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSlot = value;
                      _updateScheduledTimeFromSelection();
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select an available slot' : null,
                ),
              if (scheduledTime != null) ...[
                SizedBox(height: 10),
                Text(
                  'Match will be scheduled for ${scheduledTime!.day}/${scheduledTime!.month}/${scheduledTime!.year} ${selectedSlot!}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
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
