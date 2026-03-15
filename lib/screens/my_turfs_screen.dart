import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/turf_model.dart';
import '../theme/app_theme.dart';
import 'turf_profile_setup_screen.dart';

class MyTurfsScreen extends StatefulWidget {
  @override
  _MyTurfsScreenState createState() => _MyTurfsScreenState();
}

class _MyTurfsScreenState extends State<MyTurfsScreen> {
  bool isLoading = true;
  List<TurfModel> turfs = [];

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadTurfs();
  }

  Future<void> _loadTurfs() async {
    setState(() => isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final turfsData = await _firestoreService.getTurfsByOwner(currentUser.uid);
      setState(() {
        turfs = turfsData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading turfs: $e')),
      );
    }
  }

  Future<void> _openTurfForm({TurfModel? turf}) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TurfProfileSetupScreen(
          ownerId: currentUser.uid,
          existingTurf: turf,
          navigateToHomeOnSave: false,
        ),
      ),
    );

    if (mounted) {
      _loadTurfs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Turfs'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTurfForm(),
        backgroundColor: AppTheme.theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text('Add Turf'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : turfs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stadium, size: 64, color: Colors.grey),
                      SizedBox(height: 20),
                      Text(
                        'No turfs registered',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _openTurfForm(),
                        icon: Icon(Icons.add_business),
                        label: Text('Add Turf Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(20),
                  itemCount: turfs.length,
                  itemBuilder: (context, index) {
                    final turf = turfs[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 15),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    turf.name,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: turf.isActive
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    turf.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: turf.isActive ? Colors.green : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _openTurfForm(turf: turf),
                                  icon: Icon(Icons.edit, color: AppTheme.theme.colorScheme.primary),
                                  tooltip: 'Edit turf',
                                ),
                              ],
                            ),
                            SizedBox(height: 15),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.grey),
                                SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    turf.location,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.currency_rupee, size: 16, color: Colors.grey),
                                SizedBox(width: 5),
                                Text(
                                  '${turf.pricePerHour.toStringAsFixed(0)}/hour',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            SizedBox(height: 15),
                            Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              children: turf.gamesAvailable.map((game) {
                                return Chip(
                                  label: Text(
                                    game,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  padding: EdgeInsets.all(0),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                );
                              }).toList(),
                            ),
                            if (turf.facilities.isNotEmpty) ...[
                              SizedBox(height: 10),
                              Wrap(
                                spacing: 5,
                                runSpacing: 5,
                                children: turf.facilities.map((facility) {
                                  return Chip(
                                    label: Text(
                                      facility,
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    padding: EdgeInsets.all(0),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: Colors.blue.withOpacity(0.2),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
