import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/turf_model.dart';
import '../models/booking_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class TurfOwnerBookingsScreen extends StatefulWidget {
  @override
  _TurfOwnerBookingsScreenState createState() =>
      _TurfOwnerBookingsScreenState();
}

class _TurfOwnerBookingsScreenState extends State<TurfOwnerBookingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  List<TurfModel> _myTurfs = [];
  Map<String, List<BookingModel>> _turfBookings = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      // 1. Get all turfs for this owner
      final turfs = await _firestoreService.getTurfsByOwner(user.uid);
      _myTurfs = turfs;

      // 2. Get all bookings for the owner's turfs
      final bookingsByTurf = await Future.wait(
        turfs.map((turf) => _firestoreService.getTurfBookings(turf.turfId)),
      );
      final allBookings = bookingsByTurf.expand((bookings) => bookings).toList()
        ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

      // 3. Group bookings by turfId
      final Map<String, List<BookingModel>> bookingsMap = {};
      for (var booking in allBookings) {
        if (!bookingsMap.containsKey(booking.turfId)) {
          bookingsMap[booking.turfId] = [];
        }
        bookingsMap[booking.turfId]!.add(booking);
      }

      _turfBookings = bookingsMap;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading bookings: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildBookingCard(BookingModel booking, TurfModel turf) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(booking.bookingDate),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.blueGrey),
                SizedBox(width: 8),
                Text(booking.slotTime, style: TextStyle(fontSize: 15)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.sports, size: 18, color: Colors.blueGrey),
                SizedBox(width: 8),
                Text(booking.gameType, style: TextStyle(fontSize: 15)),
              ],
            ),
            if (booking.matchId != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.group, size: 18, color: Colors.blueGrey),
                  SizedBox(width: 8),
                  Text(
                    'Match ID: ${booking.matchId}',
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ],
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 8),
            Text(
              'Player ID: ${booking.playerId}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameSection(
    String gameType,
    List<BookingModel> bookings,
    TurfModel turf,
  ) {
    return Container(
      margin: EdgeInsets.only(left: 12, right: 12, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.only(bottom: 8),
        leading: Icon(Icons.sports_soccer, color: AppTheme.theme.primaryColor),
        title: Text(
          gameType,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text('${bookings.length} booking${bookings.length == 1 ? '' : 's'}'),
        children: bookings.map((booking) => _buildBookingCard(booking, turf)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Bookings'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _turfBookings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No bookings found for your turfs.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                itemCount: _myTurfs.length,
                itemBuilder: (context, index) {
                  final turf = _myTurfs[index];
                  final turfBookings = _turfBookings[turf.turfId] ?? [];
                  final Map<String, List<BookingModel>> bookingsByGame = {};

                  for (final booking in turfBookings) {
                    bookingsByGame.putIfAbsent(booking.gameType, () => []);
                    bookingsByGame[booking.gameType]!.add(booking);
                  }

                  final gameEntries = bookingsByGame.entries.toList()
                    ..sort((a, b) => a.key.compareTo(b.key));

                  if (turfBookings.isEmpty) return SizedBox.shrink();

                  return Container(
                    margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      childrenPadding: EdgeInsets.only(bottom: 10),
                      leading: Icon(
                        Icons.stadium,
                        color: AppTheme.theme.primaryColor,
                      ),
                      title: Text(
                        turf.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${turfBookings.length} booking${turfBookings.length == 1 ? '' : 's'} • Tap to view games',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      children: gameEntries
                          .map(
                            (entry) => _buildGameSection(
                              entry.key,
                              entry.value,
                              turf,
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
