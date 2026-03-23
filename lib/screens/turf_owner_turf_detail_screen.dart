import 'package:flutter/material.dart';
import '../models/turf_model.dart';
import '../theme/app_theme.dart';
import 'turf_bookings_list_screen.dart';

class TurfOwnerTurfDetailScreen extends StatelessWidget {
  final TurfModel turf;

  const TurfOwnerTurfDetailScreen({Key? key, required this.turf})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(turf.name),
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
                child: Icon(
                  Icons.sports_soccer,
                  size: 80,
                  color: Colors.grey[500],
                ),
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
                          turf.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '₹${turf.pricePerHour.toInt()}/hr',
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
                          turf.location,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (turf.contact != null && turf.contact!.isNotEmpty) ...[
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          color: AppTheme.theme.primaryColor,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          turf.contact!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
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
                    children: turf.gamesAvailable.map((game) {
                      int count = turf.courts[game] ?? 1;
                      return Chip(
                        avatar: Icon(
                          Icons.sports,
                          size: 16,
                          color: Colors.white,
                        ),
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
                  if (turf.facilities.isEmpty)
                    Text(
                      'No specific facilities listed.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: turf.facilities.map((facility) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green,
                              ),
                              SizedBox(width: 6),
                              Text(facility),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  SizedBox(height: 40),
                  
                  // View Bookings Button (UX enhancement)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TurfBookingsListScreen(turf: turf),
                          ),
                        );
                      },
                      icon: Icon(Icons.calendar_today, color: Colors.white),
                      label: Text(
                        'View Bookings',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
