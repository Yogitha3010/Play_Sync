import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/turf_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'turf_detail_screen.dart';

class TurfsScreen extends StatefulWidget {
  @override
  _TurfsScreenState createState() => _TurfsScreenState();
}

class _TurfsScreenState extends State<TurfsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<TurfModel> _allTurfs = [];
  List<Map<String, dynamic>> _nearbyTurfs = []; // Store turf and its distance
  
  bool _isLoading = true;
  String _errorMessage = '';
  Position? _currentPosition;
  double _radiusKm = 10.0; // Configurable radius

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _getCurrentLocation();
      await _fetchAndFilterTurfs();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable them.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    _currentPosition = await Geolocator.getCurrentPosition();
  }

  Future<void> _fetchAndFilterTurfs() async {
    if (_currentPosition == null) return;

    final turfs = await _firestoreService.searchTurfs();
    
    List<Map<String, dynamic>> filteredList = [];
    
    for (var turf in turfs) {
      if (turf.coordinates.containsKey('latitude') && turf.coordinates.containsKey('longitude')) {
        double turfLat = turf.coordinates['latitude']!;
        double turfLng = turf.coordinates['longitude']!;
        
        double distanceInMeters = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          turfLat,
          turfLng,
        );
        
        double distanceInKm = distanceInMeters / 1000;
        
        if (distanceInKm <= _radiusKm) {
          filteredList.add({
            'turf': turf,
            'distance': distanceInKm,
          });
        }
      }
    }
    
    // Sort by nearest distance
    filteredList.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    
    if (mounted) {
      setState(() {
        _allTurfs = turfs;
        _nearbyTurfs = filteredList;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Turfs'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _initializeApp,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Locating nearby turfs...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initializeApp,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_nearbyTurfs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No turfs found within ${_radiusKm.toInt()} km.\nTry increasing the radius or check back later.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Radius: ${_radiusKm.toInt()} km',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                value: _radiusKm,
                min: 5.0,
                max: 50.0,
                divisions: 9,
                label: '${_radiusKm.toInt()} km',
                onChanged: (value) {
                  setState(() {
                    _radiusKm = value;
                  });
                },
                onChangeEnd: (value) {
                  setState(() {
                    _isLoading = true;
                  });
                  _fetchAndFilterTurfs();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _nearbyTurfs.length,
            itemBuilder: (context, index) {
              final item = _nearbyTurfs[index];
              final TurfModel turf = item['turf'];
              final double distance = item['distance'];
              
              return _buildTurfCard(context, turf, distance);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTurfCard(BuildContext context, TurfModel turf, double distance) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TurfDetailScreen(turf: turf, distance: distance),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      turf.name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, size: 14, color: AppTheme.theme.primaryColor),
                        SizedBox(width: 4),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: TextStyle(
                            color: AppTheme.theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.map, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      turf.location,
                      style: TextStyle(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: turf.gamesAvailable.take(3).map((game) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      game,
                      style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${turf.pricePerHour.toInt()}/hr',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green[700],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
