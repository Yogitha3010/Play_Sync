import 'package:flutter/material.dart';
import '../models/turf_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'available_matches_screen.dart';
import 'create_match_screen.dart';
import 'find_players_screen.dart';
import 'my_matches_screen.dart';
import 'player_profile_screen.dart';
import 'requests_screen.dart';
import 'teams_screen.dart';
import 'turf_detail_screen.dart';
import 'turfs_screen.dart';

class PlayerHomeScreen extends StatefulWidget {
  @override
  _PlayerHomeScreenState createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends State<PlayerHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    PlayerHomeTab(),
    const FindPlayersScreen(),
    const AvailableMatchesScreen(),
    MyMatchesScreen(),
    const RequestsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.theme.colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Find Players',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available),
            label: 'Matches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'My Matches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mail_outline),
            label: 'Requests',
          ),
        ],
      ),
    );
  }
}

class PlayerHomeTab extends StatefulWidget {
  @override
  State<PlayerHomeTab> createState() => _PlayerHomeTabState();
}

class _PlayerHomeTabState extends State<PlayerHomeTab> {
  final FirestoreService _firestoreService = FirestoreService();

  List<TurfModel> _allTurfs = [];
  List<String> _locations = [];
  String? _selectedLocation;
  bool _isLoadingTurfs = true;
  String _turfErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTurfs();
  }

  Future<void> _loadTurfs() async {
    setState(() {
      _isLoadingTurfs = true;
      _turfErrorMessage = '';
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
        _isLoadingTurfs = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _turfErrorMessage = 'Failed to load turfs: $e';
        _isLoadingTurfs = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PlaySync'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayerProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTurfs,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.theme.colorScheme.primary,
                      AppTheme.theme.colorScheme.primary.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Find players, create matches, and sync your game!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Text(
                'Find Turfs by Location',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Choose a location to see available turfs. Other options are below.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLocation,
                    isExpanded: true,
                    hint: Text('Select Location'),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.theme.colorScheme.primary,
                    ),
                    items: _locations.map((location) {
                      return DropdownMenuItem<String>(
                        value: location,
                        child: Text(
                          location,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _locations.isEmpty
                        ? null
                        : (value) {
                            setState(() {
                              _selectedLocation = value;
                            });
                          },
                  ),
                ),
              ),
              if (_selectedLocation != null) ...[
                SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedLocation = null;
                    });
                  },
                  icon: Icon(Icons.clear),
                  label: Text('Clear location'),
                ),
              ],
              SizedBox(height: 16),
              _buildTurfSection(),
              SizedBox(height: 30),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.search,
                      title: 'Find Players',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => FindPlayersScreen()),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.map,
                      title: 'Find Turfs',
                      color: Colors.indigo,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TurfsScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.add_circle,
                      title: 'Create Match',
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CreateMatchScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.groups,
                      title: 'Teams',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TeamsScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTurfSection() {
    if (_isLoadingTurfs) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_turfErrorMessage.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _turfErrorMessage,
              style: TextStyle(color: Colors.red[700]),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: _loadTurfs,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_allTurfs.isEmpty) {
      return _buildTurfMessageCard('No turfs available right now.');
    }

    if (_selectedLocation == null) {
      return _buildTurfMessageCard(
        'Select a location to view available turfs in that area.',
      );
    }

    if (_filteredTurfs.isEmpty) {
      return _buildTurfMessageCard('No turfs found for $_selectedLocation.');
    }

    return Column(
      children: _filteredTurfs.map(_buildHomeTurfCard).toList(),
    );
  }

  Widget _buildTurfMessageCard(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on, color: AppTheme.theme.colorScheme.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTurfCard(TurfModel turf) {
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
              Row(
                children: [
                  Icon(Icons.place_outlined, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 6),
                  Expanded(child: Text(turf.location)),
                ],
              ),
              SizedBox(height: 8),
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
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
