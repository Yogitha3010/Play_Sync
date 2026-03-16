import 'package:flutter/material.dart';
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
  List<String> _locations = [];
  String? _selectedLocation;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTurfs();
  }

  Future<void> _loadTurfs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final turfs = await _firestoreService.searchTurfs();
      final locations = turfs
          .map((turf) => turf.location.trim())
          .where((location) => location.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      if (!mounted) return;

      setState(() {
        _allTurfs = turfs;
        _locations = locations;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load turfs: $e';
        _isLoading = false;
      });
    }
  }

  List<TurfModel> get _filteredTurfs {
    if (_selectedLocation == null || _selectedLocation!.isEmpty) {
      return [];
    }

    return _allTurfs
        .where((turf) => turf.location.trim() == _selectedLocation)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
        titleSpacing: 12,
        title: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLocation,
                    hint: Text(
                      'Select Location',
                      style: TextStyle(color: Colors.white),
                    ),
                    isExpanded: true,
                    dropdownColor: AppTheme.theme.primaryColor,
                    iconEnabledColor: Colors.white,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    items: _locations.map((location) {
                      return DropdownMenuItem<String>(
                        value: location,
                        child: Text(
                          location,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLocation = value;
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: Icon(Icons.clear),
              tooltip: 'Clear location',
              onPressed: () {
                setState(() {
                  _selectedLocation = null;
                });
              },
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTurfs,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 56, color: Colors.red),
              SizedBox(height: 12),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTurfs,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_allTurfs.isEmpty) {
      return Center(
        child: Text(
          'No turfs available right now.',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTurfs,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            'Available Turfs',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            _selectedLocation == null
                ? 'Browse all turfs in the app. Select a location to filter them.'
                : 'Showing turfs for $_selectedLocation',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _allTurfs.length,
              separatorBuilder: (_, __) => SizedBox(width: 12),
              itemBuilder: (context, index) {
                final turf = _allTurfs[index];
                return _buildHorizontalTurfCard(turf);
              },
            ),
          ),
          SizedBox(height: 28),
          Text(
            _selectedLocation == null
                ? 'Choose a location'
                : 'Turfs in $_selectedLocation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          if (_selectedLocation == null)
            Container(
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.place, color: AppTheme.theme.colorScheme.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select a location from the top-left dropdown to view turfs for that area.',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            )
          else if (_filteredTurfs.isEmpty)
            Container(
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'No turfs found for $_selectedLocation.',
                style: TextStyle(color: Colors.grey[700]),
              ),
            )
          else
            ..._filteredTurfs.map(_buildVerticalTurfCard),
        ],
      ),
    );
  }

  Widget _buildHorizontalTurfCard(TurfModel turf) {
    return InkWell(
      onTap: () => _openTurfDetail(turf),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 260,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              turf.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Text(
              turf.location,
              style: TextStyle(color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 14),
            Text(
              'Rs ${turf.pricePerHour.toInt()}/hr',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.green[700],
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: turf.gamesAvailable.take(3).map((game) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        game,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'View details',
                style: TextStyle(
                  color: AppTheme.theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalTurfCard(TurfModel turf) {
    return Card(
      margin: EdgeInsets.only(bottom: 14),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(
          turf.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(turf.location),
              SizedBox(height: 6),
              Text(
                'Rs ${turf.pricePerHour.toInt()}/hr',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: turf.gamesAvailable.map((game) {
                  return Chip(
                    label: Text(game, style: TextStyle(fontSize: 12)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _openTurfDetail(turf),
      ),
    );
  }

  void _openTurfDetail(TurfModel turf) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TurfDetailScreen(
          turf: turf,
          distance: 0.0,
        ),
      ),
    );
  }
}
