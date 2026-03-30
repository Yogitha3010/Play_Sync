import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'my_turfs_screen.dart';
import 'turf_owner_bookings_screen.dart';
import 'turf_profile_screen.dart';
import 'turf_profile_setup_screen.dart';

class TurfHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turf Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TurfProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.pageDecoration(),
        child: SingleChildScrollView(
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
                      'Welcome, Turf Owner!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Manage your turfs and bookings',
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
                            Icons.auto_graph_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Professional owner workspace',
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: AppTheme.surfaceCardDecoration(elevated: false),
                child: const Row(
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      color: AppTheme.secondary,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your owner tools now follow the same PlaySync theme used on login and player screens.',
                        style: TextStyle(color: AppTheme.mutedText),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 15),
              _OwnerActionCard(
                icon: Icons.stadium,
                title: 'My Turfs',
                subtitle: 'View and manage your turfs',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MyTurfsScreen()),
                  );
                },
              ),
              const SizedBox(height: 15),
              _OwnerActionCard(
                icon: Icons.add_business,
                title: 'Add Turf Details',
                subtitle: 'Register a new turf or complete missing details',
                onTap: () {
                  final currentUser = AuthService().currentUser;
                  if (currentUser == null) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TurfProfileSetupScreen(
                        ownerId: currentUser.uid,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _OwnerActionCard(
                icon: Icons.calendar_today,
                title: 'Bookings',
                subtitle: 'View match bookings for your turfs',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TurfOwnerBookingsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OwnerActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.tintedCardDecoration(AppTheme.secondary),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 28, color: AppTheme.primary),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppTheme.mutedText),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
