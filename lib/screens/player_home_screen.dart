import 'package:flutter/material.dart';
import '../models/turf_model.dart';
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search_rounded),
              label: 'Find Players',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_available_outlined),
              activeIcon: Icon(Icons.event_available),
              label: 'Matches',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer_outlined),
              activeIcon: Icon(Icons.sports_soccer),
              label: 'My Matches',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mail_outline),
              activeIcon: Icon(Icons.mail),
              label: 'Requests',
            ),
          ],
        ),
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
        title: const Text('PlaySync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayerProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.pageDecoration(),
        child: RefreshIndicator(
          onRefresh: _loadTurfs,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.16),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Find players, create matches, and sync your game!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flash_on_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Discover games faster',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Find Turfs by Location',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a location to see available turfs. Other options are below.',
                  style: TextStyle(color: AppTheme.mutedText),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: AppTheme.surfaceCardDecoration(),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLocation,
                      isExpanded: true,
                      hint: const Text('Select Location'),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.primary,
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
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedLocation = null;
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear location'),
                  ),
                ],
                const SizedBox(height: 16),
                _buildTurfSection(),
                const SizedBox(height: 30),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 15),
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
                    const SizedBox(width: 15),
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
                const SizedBox(height: 15),
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
                            MaterialPageRoute(
                              builder: (_) => CreateMatchScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
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
      ),
    );
  }

  Widget _buildTurfSection() {
    if (_isLoadingTurfs) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.surfaceCardDecoration(),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_turfErrorMessage.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.surfaceCardDecoration(elevated: false),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.mutedText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTurfCard(TurfModel turf) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        title: Text(
          turf.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.place_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(child: Text(turf.location)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Rs ${turf.pricePerHour.toInt()}/hr',
                style: TextStyle(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
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
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.tintedCardDecoration(color),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
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
