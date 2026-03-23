import 'package:flutter/material.dart';

import '../models/booking_model.dart';
import '../models/match_model.dart';
import '../models/turf_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'my_turfs_screen.dart';
import 'role_selection_screen.dart';
import 'turf_profile_setup_screen.dart';

class TurfProfileScreen extends StatefulWidget {
  const TurfProfileScreen({Key? key}) : super(key: key);

  @override
  State<TurfProfileScreen> createState() => _TurfProfileScreenState();
}

class _TurfProfileScreenState extends State<TurfProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  UserModel? _owner;
  List<TurfModel> _turfs = [];
  List<BookingModel> _bookings = [];
  List<MatchModel> _matches = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final owner = await _authService.getUserData(currentUser.uid);
      final turfs = await _firestoreService.getTurfsByOwner(currentUser.uid);
      final bookings = await _firestoreService.getOwnerBookings(currentUser.uid);
      final matches = await _firestoreService.getMatchesForTurfs(
        turfs.map((turf) => turf.turfId).toList(),
      );

      if (!mounted) return;
      setState(() {
        _owner = owner;
        _turfs = turfs;
        _bookings = bookings;
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading turf profile: $e')),
      );
    }
  }

  Future<void> _openEditProfile() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TurfProfileSetupScreen(
          ownerId: currentUser.uid,
          existingTurf: _turfs.isNotEmpty ? _turfs.first : null,
          navigateToHomeOnSave: false,
        ),
      ),
    );

    if (mounted) {
      _loadProfile();
    }
  }

  Future<void> _openManageTurfs() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MyTurfsScreen()),
    );

    if (mounted) {
      _loadProfile();
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownerName = (_owner?.name ?? '').trim();
    final displayName = ownerName.isNotEmpty ? ownerName : 'Turf Owner';
    final totalTurfs = _turfs.length;
    final totalBookings = _bookings.length;
    final completedMatches = _matches
        .where((match) => match.matchStatus == 'completed')
        .length;
    final activeMatches = _matches
        .where((match) => match.matchStatus == 'active')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Turf Profile'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
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
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.theme.colorScheme.primary.withOpacity(0.12),
                          child: Text(
                            displayName.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _owner?.email ?? '',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (_owner?.phone ?? '').trim().isNotEmpty
                              ? _owner!.phone!.trim()
                              : 'Phone not added',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Total Turfs',
                          value: totalTurfs.toString(),
                          icon: Icons.stadium,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Bookings',
                          value: totalBookings.toString(),
                          icon: Icons.calendar_today,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Matches Played',
                          value: completedMatches.toString(),
                          icon: Icons.emoji_events_outlined,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Active Matches',
                          value: activeMatches.toString(),
                          icon: Icons.sports_score,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openEditProfile,
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openManageTurfs,
                          icon: const Icon(Icons.view_list),
                          label: const Text('Manage Turfs'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Your Turfs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_turfs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'No turf details added yet.',
                      ),
                    ),
                  ..._turfs.map((turf) {
                    final turfBookings = _bookings
                        .where((booking) => booking.turfId == turf.turfId)
                        .length;
                    final turfCompletedMatches = _matches
                        .where(
                          (match) =>
                              match.turfId == turf.turfId &&
                              match.matchStatus == 'completed',
                        )
                        .length;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            turf.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            turf.location,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: turf.gamesAvailable
                                .map(
                                  (game) => Chip(
                                    label: Text(game),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Bookings: $turfBookings',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Completed matches: $turfCompletedMatches',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
