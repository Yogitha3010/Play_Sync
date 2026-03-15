import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/turf_model.dart';
import '../models/booking_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'create_match_screen.dart';

class TurfDetailScreen extends StatefulWidget {
  final TurfModel turf;
  final double distance;

  const TurfDetailScreen({
    Key? key,
    required this.turf,
    required this.distance,
  }) : super(key: key);

  @override
  _TurfDetailScreenState createState() => _TurfDetailScreenState();
}

class _TurfDetailScreenState extends State<TurfDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  Future<void> _showBookingSheet(BuildContext context) async {
    DateTime? selectedDate = DateTime.now();
    String? selectedSlot;
    String? selectedGame;

    if (widget.turf.gamesAvailable.isNotEmpty) {
      selectedGame = widget.turf.gamesAvailable.first;
    }

    final List<String> slots = [
      '06:00 - 07:00', '07:00 - 08:00', '08:00 - 09:00',
      '16:00 - 17:00', '17:00 - 18:00', '18:00 - 19:00',
      '19:00 - 20:00', '20:00 - 21:00', '21:00 - 22:00',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Book Turf', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  
                  // Game Selection
                  DropdownButtonFormField<String>(
                    value: selectedGame,
                    decoration: InputDecoration(
                      labelText: 'Select Game Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: widget.turf.gamesAvailable.map((game) {
                      return DropdownMenuItem(value: game, child: Text(game));
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedGame = val),
                  ),
                  SizedBox(height: 15),

                  // Date Selection
                  ListTile(
                    title: Text(selectedDate != null 
                        ? 'Date: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}' 
                        : 'Select Date'),
                    trailing: Icon(Icons.calendar_today),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey[300]!)
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 30)),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                  ),
                  SizedBox(height: 15),

                  // Slot Selection
                  DropdownButtonFormField<String>(
                    value: selectedSlot,
                    decoration: InputDecoration(
                      labelText: 'Select Time Slot',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: slots.map((slot) {
                      return DropdownMenuItem(value: slot, child: Text(slot));
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedSlot = val),
                  ),
                  SizedBox(height: 25),

                  ElevatedButton(
                    onPressed: () async {
                      if (selectedGame == null || selectedDate == null || selectedSlot == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please select game, date, and slot')),
                        );
                        return;
                      }

                      final user = _authService.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('You must be logged in to book.')),
                        );
                        return;
                      }

                      try {
                        final booking = BookingModel(
                          bookingId: Uuid().v4(),
                          turfId: widget.turf.turfId,
                          playerId: user.uid,
                          gameType: selectedGame!,
                          bookingDate: selectedDate!,
                          slotTime: selectedSlot!,
                          createdAt: DateTime.now(),
                        );

                        await _firestoreService.createBooking(booking);
                        Navigator.pop(context); // Close sheet
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Booking confirmed!')),
                        );
                      } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to book: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: AppTheme.theme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Confirm Booking', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.turf.name),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header image placeholder
            Container(
              height: 200,
              color: Colors.grey[300],
              child: Center(
                child: Icon(Icons.sports_soccer, size: 80, color: Colors.grey[500]),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.turf.name,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '₹${widget.turf.pricePerHour.toInt()}/hr',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red[400], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.turf.location} (${widget.distance.toStringAsFixed(1)} km away)',
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                  if (widget.turf.contact != null && widget.turf.contact!.isNotEmpty) ...[
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.phone, color: AppTheme.theme.primaryColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          widget.turf.contact!,
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                  
                  SizedBox(height: 24),
                  Divider(),
                  SizedBox(height: 16),
                  
                  Text(
                    'Available Games',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: widget.turf.gamesAvailable.map((game) {
                      int count = widget.turf.courts[game] ?? 1;
                      return Chip(
                        avatar: Icon(Icons.sports, size: 16, color: Colors.white),
                        label: Text('$game ($count courts)'),
                        backgroundColor: AppTheme.theme.primaryColor,
                        labelStyle: TextStyle(color: Colors.white),
                      );
                    }).toList(),
                  ),
                  
                  SizedBox(height: 24),
                  Text(
                    'Facilities',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  if (widget.turf.facilities.isEmpty)
                    Text('No specific facilities listed.', style: TextStyle(color: Colors.grey))
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: widget.turf.facilities.map((facility) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 16, color: Colors.green),
                              SizedBox(width: 6),
                              Text(facility),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  
                  SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _showBookingSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.theme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Book Turf Time',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
