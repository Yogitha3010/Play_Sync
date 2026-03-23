import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../constants/game_constants.dart';
import '../models/booking_model.dart';
import '../models/feedback_model.dart';
import '../models/play_request_model.dart';
import '../models/player_profile_model.dart';
import '../models/turf_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/slot_service.dart';
import '../theme/app_theme.dart';
import '../widgets/player_profile_content.dart';

class PlayerDetailScreen extends StatefulWidget {
  final String playerId;

  const PlayerDetailScreen({Key? key, required this.playerId}) : super(key: key);

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  bool isLoading = true;
  bool isSubmittingRequest = false;
  PlayerProfileModel? profile;
  List<FeedbackModel> feedbackList = [];
  Map<String, int> gameCounts = {};
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);

    try {
      final profileData = await _firestoreService.getPlayerProfile(widget.playerId);
      final feedbackData = await _firestoreService.getFeedbackForPlayer(
        widget.playerId,
      );
      final matches = await _firestoreService.getPlayerMatches(widget.playerId);
      final counts = <String, int>{};
      for (final match in matches) {
        counts.update(match.gameType, (value) => value + 1, ifAbsent: () => 1);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        profile = profileData;
        feedbackList = feedbackData;
        gameCounts = Map.fromEntries(
          counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
        );
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  Future<void> _showRequestToPlaySheet() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null || profile == null) {
      return;
    }

    final turfs = await _firestoreService.searchTurfs();
    if (!mounted) {
      return;
    }

    String? selectedGame = profile!.preferredSports.isNotEmpty
        ? profile!.preferredSports.first
        : GameConstants.supportedGames.first;
    TurfModel? selectedTurf = turfs.isNotEmpty ? turfs.first : null;
    DateTime selectedDate = DateTime.now().add(Duration(days: 1));
    String? selectedSlot;
    List<BookingModel> turfBookings = selectedTurf == null
        ? []
        : await _firestoreService.getTurfBookings(selectedTurf.turfId);

    List<String> availableSlots() {
      if (selectedTurf == null || selectedGame == null) {
        return [];
      }

      final slots = SlotService.generateSlots(
        selectedTurf!.openingTime,
        selectedTurf!.closingTime,
      );

      final now = DateTime.now();
      final isToday = selectedDate.year == now.year &&
          selectedDate.month == now.month &&
          selectedDate.day == now.day;

      return slots.where((slot) {
        // For today, filter out slots whose start time has already passed
        if (isToday) {
          final parts = slot.split(' - ');
          if (parts.isNotEmpty) {
            final timeParts = parts[0].trim().split(':');
            if (timeParts.length == 2) {
              final slotHour = int.tryParse(timeParts[0]) ?? 0;
              final slotMinute = int.tryParse(timeParts[1]) ?? 0;
              final slotStartMinutes = slotHour * 60 + slotMinute;
              final nowMinutes = now.hour * 60 + now.minute;
              if (slotStartMinutes <= nowMinutes) {
                return false;
              }
            }
          }
        }

        // Filter out fully booked slots
        final bookedCount = turfBookings.where((booking) {
          return booking.status != 'cancelled' &&
              booking.gameType == selectedGame &&
              _isSameDay(booking.bookingDate, selectedDate) &&
              booking.slotTime == slot;
        }).length;
        return bookedCount < (selectedTurf!.courts[selectedGame!] ?? 1);
      }).toList();
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final slots = availableSlots();
            if (selectedSlot != null && !slots.contains(selectedSlot)) {
              selectedSlot = null;
            }

            Future<void> refreshTurfBookings() async {
              if (selectedTurf == null) {
                return;
              }
              turfBookings = await _firestoreService.getTurfBookings(
                selectedTurf!.turfId,
              );
              setModalState(() {});
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Request to Play',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedGame,
                      decoration: InputDecoration(
                        labelText: 'Game',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: GameConstants.supportedGames.map((game) {
                        return DropdownMenuItem(value: game, child: Text(game));
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() => selectedGame = value);
                      },
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<TurfModel>(
                      value: selectedTurf,
                      decoration: InputDecoration(
                        labelText: 'Turf',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: turfs.map((turf) {
                        return DropdownMenuItem(
                          value: turf,
                          child: Text('${turf.name} - ${turf.location}'),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        selectedTurf = value;
                        selectedSlot = null;
                        await refreshTurfBookings();
                      },
                    ),
                    SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      title: Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 60)),
                        );
                        if (picked != null) {
                          selectedDate = picked;
                          selectedSlot = null;
                          await refreshTurfBookings();
                        }
                      },
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedSlot,
                      decoration: InputDecoration(
                        labelText: 'Time Slot',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: slots.map((slot) {
                        return DropdownMenuItem(value: slot, child: Text(slot));
                      }).toList(),
                      onChanged: slots.isEmpty
                          ? null
                          : (value) {
                              setModalState(() => selectedSlot = value);
                            },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isSubmittingRequest
                          ? null
                          : () async {
                              if (selectedGame == null ||
                                  selectedTurf == null ||
                                  selectedSlot == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Please choose a game, turf, and slot.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              Navigator.pop(context);
                              await _submitPlayRequest(
                                currentUser.uid,
                                selectedGame!,
                                selectedTurf!,
                                selectedDate,
                                selectedSlot!,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('Send Request'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitPlayRequest(
    String fromUserId,
    String gameType,
    TurfModel turf,
    DateTime date,
    String slotTime,
  ) async {
    setState(() => isSubmittingRequest = true);
    try {
      final request = PlayRequestModel(
        requestId: Uuid().v4(),
        fromUserId: fromUserId,
        toUserId: widget.playerId,
        gameType: gameType,
        turfId: turf.turfId,
        date: DateTime(date.year, date.month, date.day),
        slotTime: slotTime,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createPlayRequest(request);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Play request sent successfully.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmittingRequest = false);
      }
    }
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Player Profile'),
          backgroundColor: AppTheme.theme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Player Profile'),
          backgroundColor: AppTheme.theme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text('Player not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Player Profile'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: PlayerProfileContent(
        profile: profile!,
        feedbackList: feedbackList,
        gameCounts: gameCounts,
        footer: _authService.currentUser?.uid == widget.playerId
            ? null
            : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmittingRequest ? null : _showRequestToPlaySheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isSubmittingRequest ? 'Sending...' : 'Request to Play',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
      ),
    );
  }
}
