import 'package:flutter/material.dart';

import '../models/turf_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'available_matches_screen.dart';
import 'chennai_location_picker_screen.dart';
import 'create_match_screen.dart';
import 'find_players_screen.dart';
import 'my_matches_screen.dart';
import 'player_profile_screen.dart';
import 'requests_screen.dart';
import 'teams_screen.dart';
import 'turf_detail_screen.dart';
import 'turfs_screen.dart';

class PlayerHomeScreen extends StatefulWidget {
  final int initialIndex;

  const PlayerHomeScreen({super.key, this.initialIndex = 0});

  @override
  State<PlayerHomeScreen> createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends State<PlayerHomeScreen> {
  late int _currentIndex;

  final List<Widget> _screens = [
    const PlayerHomeTab(),
    const FindPlayersScreen(),
    const AvailableMatchesScreen(),
    MyMatchesScreen(),
    const RequestsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

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
  const PlayerHomeTab({super.key});

  @override
  State<PlayerHomeTab> createState() => _PlayerHomeTabState();
}

class _PlayerHomeTabState extends State<PlayerHomeTab> {
  static const Set<String> _genericLocationWords = {
    'chennai',
    'tamil',
    'nadu',
    'india',
    'district',
    'city',
  };

  final FirestoreService _firestoreService = FirestoreService();

  List<TurfModel> _allTurfs = [];
  List<String> _knownLocations = [];
  String? _selectedLocationLabel;
  String? _selectedLocationQuery;
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
      final knownLocations = turfs
          .map((turf) => turf.location.trim())
          .where((location) => location.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      if (!mounted) {
        return;
      }

      setState(() {
        _allTurfs = turfs;
        _knownLocations = knownLocations;
        _isLoadingTurfs = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _turfErrorMessage = 'Failed to load turfs: $e';
        _isLoadingTurfs = false;
      });
    }
  }

  List<TurfModel> get _filteredTurfs {
    final query = _selectedLocationQuery;
    if (query == null || query.trim().isEmpty) {
      return [];
    }

    return _allTurfs
        .where((turf) => _matchesLocation(turf.location, query))
        .toList();
  }

  Future<void> _pickLocationOnMap() async {
    final result = await Navigator.push<ChennaiLocationSelection>(
      context,
      MaterialPageRoute(
        builder: (_) => ChennaiLocationPickerScreen(
          initialLabel: _selectedLocationLabel,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final matchedLocation = _findBestLocationMatch(result.label);
    setState(() {
      _selectedLocationLabel = result.label;
      _selectedLocationQuery = matchedLocation ?? result.label;
    });
  }

  void _clearLocation() {
    setState(() {
      _selectedLocationLabel = null;
      _selectedLocationQuery = null;
    });
  }

  String? _findBestLocationMatch(String label) {
    final normalizedLabel = _normalizeLocation(label);
    final labelTokens = _extractLocationTokens(label);

    for (final location in _knownLocations) {
      final normalizedLocation = _normalizeLocation(location);
      if (normalizedLocation == normalizedLabel ||
          normalizedLocation.contains(normalizedLabel) ||
          normalizedLabel.contains(normalizedLocation)) {
        return location;
      }
    }

    for (final location in _knownLocations) {
      final tokens = _extractLocationTokens(location);
      if (labelTokens.isNotEmpty && tokens.any(labelTokens.contains)) {
        return location;
      }
    }

    return null;
  }

  bool _matchesLocation(String turfLocation, String query) {
    final normalizedTurfLocation = _normalizeLocation(turfLocation);
    final normalizedQuery = _normalizeLocation(query);

    if (normalizedTurfLocation == normalizedQuery ||
        normalizedTurfLocation.contains(normalizedQuery) ||
        normalizedQuery.contains(normalizedTurfLocation)) {
      return true;
    }

    final turfTokens = _extractLocationTokens(turfLocation);
    final queryTokens = _extractLocationTokens(query);
    if (queryTokens.isEmpty) {
      return false;
    }

    return queryTokens.any(turfTokens.contains);
  }

  String _normalizeLocation(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  Set<String> _extractLocationTokens(String value) {
    return _normalizeLocation(value)
        .split(' ')
        .where(
          (token) =>
              token.length > 2 && !_genericLocationWords.contains(token),
        )
        .toSet();
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
            icon: const Icon(Icons.location_on_outlined),
            tooltip: 'Pick Chennai location',
            onPressed: _pickLocationOnMap,
          ),
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
                        'Pick a Chennai location and explore nearby turfs, matches, and players.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: _pickLocationOnMap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.place_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _selectedLocationLabel ??
                                      'Tap to search or select a Chennai location',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedLocationLabel != null) ...[
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: _clearLocation,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear selected location'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Nearby Turfs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedLocationLabel == null
                      ? 'Use the location pin to search or select an area in Chennai.'
                      : 'Showing turfs that match ${_selectedLocationLabel!}.',
                  style: const TextStyle(color: AppTheme.mutedText),
                ),
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FindPlayersScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.map,
                        title: 'Find Turfs',
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
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadTurfs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_allTurfs.isEmpty) {
      return _buildTurfMessageCard('No turfs available right now.');
    }

    if (_selectedLocationQuery == null || _selectedLocationQuery!.isEmpty) {
      return _buildTurfMessageCard(
        'Search or select a Chennai location from the map to see nearby turfs.',
      );
    }

    if (_filteredTurfs.isEmpty) {
      return _buildTurfMessageCard(
        'No turfs found for ${_selectedLocationLabel ?? _selectedLocationQuery}.',
      );
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
                style: const TextStyle(
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
                    label: Text(game, style: const TextStyle(fontSize: 12)),
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
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.tintedCardDecoration(AppTheme.secondary),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 30, color: AppTheme.primary),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppTheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
