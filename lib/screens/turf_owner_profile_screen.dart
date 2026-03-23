import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/turf_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'package:playsync/auth/auth_wrapper.dart';
import 'turf_owner_turf_detail_screen.dart';

class TurfOwnerProfileScreen extends StatefulWidget {
  @override
  _TurfOwnerProfileScreenState createState() => _TurfOwnerProfileScreenState();
}

class _TurfOwnerProfileScreenState extends State<TurfOwnerProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _userData;
  List<TurfModel> _myTurfs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final data = await _authService.getUserData(user.uid);
        final turfs = await _firestoreService.getTurfsByOwner(user.uid);
        if (mounted) {
          setState(() {
            _userData = data;
            _myTurfs = turfs;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => AuthWrapper()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Owner Profile'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: primary,
                          child: Text(
                            (_userData?.name ?? 'O')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          _userData?.name ?? 'Turf Owner',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _userData?.email ?? '',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),

                  // Contact Info Section
                  _buildSectionTitle('Contact Information'),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.phone, color: primary),
                          title: Text('Phone Number'),
                          subtitle: Text(_userData?.phone ?? 'Not provided'),
                        ),
                        Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.business, color: primary),
                          title: Text('Turfs Owned'),
                          subtitle: Text('${_myTurfs.length} Turfs'),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // Turfs List Section
                  _buildSectionTitle('My Turfs'),
                  if (_myTurfs.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No turfs found.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _myTurfs.length,
                      itemBuilder: (context, index) {
                        final turf = _myTurfs[index];
                        return _buildTurfCard(turf);
                      },
                    ),

                  SizedBox(height: 40),

                  // Logout Button
                  ElevatedButton.icon(
                    onPressed: _showLogoutDialog,
                    icon: Icon(Icons.logout),
                    label: Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildTurfCard(TurfModel turf) {
    return Card(
      margin: EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.stadium, color: Colors.green[700], size: 30),
        ),
        title: Text(
          turf.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    turf.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              turf.gamesAvailable.join(', '),
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TurfOwnerTurfDetailScreen(turf: turf),
            ),
          );
        },
      ),
    );
  }
}
