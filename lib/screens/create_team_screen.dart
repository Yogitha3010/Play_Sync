import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/team_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class CreateTeamScreen extends StatefulWidget {
  @override
  _CreateTeamScreenState createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  String _selectedSport = 'Football';
  String _teamVisibility = 'public';
  bool _isLoading = false;

  final List<String> _sportsList = [
    'Football',
    'Cricket',
    'Basketball',
    'Badminton',
    'Tennis',
    'Volleyball'
  ];

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final user = authService.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You must be logged in to create a team')),
        );
        return;
      }

      final teamId = Uuid().v4();
      final team = TeamModel(
        teamId: teamId,
        teamName: _teamNameController.text.trim(),
        createdBy: user.uid,
        players: [user.uid], // Creator is automatically part of the team
        visibility: _teamVisibility,
        gameType: _selectedSport,
        createdAt: DateTime.now(),
      );

      final firestoreService = FirestoreService();
      await firestoreService.createTeam(team);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Team created successfully!')),
      );

      Navigator.pop(context); // Return to teams screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating team: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Team'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Assemble Your Squad',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.theme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              TextFormField(
                controller: _teamNameController,
                decoration: InputDecoration(
                  labelText: 'Team Name',
                  prefixIcon: Icon(Icons.group),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a team name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedSport,
                decoration: InputDecoration(
                  labelText: 'Game Type',
                  prefixIcon: Icon(Icons.sports),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _sportsList.map((sport) {
                  return DropdownMenuItem(
                    value: sport,
                    child: Text(sport),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedSport = value;
                    });
                  }
                },
              ),
              SizedBox(height: 20),
              Text(
                'Team Access',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: 'public',
                      groupValue: _teamVisibility,
                      title: Text('Public'),
                      subtitle: Text('Anyone can join this team instantly.'),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _teamVisibility = value;
                          });
                        }
                      },
                    ),
                    Divider(height: 1),
                    RadioListTile<String>(
                      value: 'private',
                      groupValue: _teamVisibility,
                      title: Text('Private'),
                      subtitle: Text('Players must send a request and wait for admin approval.'),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _teamVisibility = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _createTeam,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Create Team',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
