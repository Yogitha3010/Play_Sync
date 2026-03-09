import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/player_profile_model.dart';
import '../theme/app_theme.dart';

class EditPlayerProfileScreen extends StatefulWidget {
  final PlayerProfileModel profile;

  const EditPlayerProfileScreen({Key? key, required this.profile}) : super(key: key);

  @override
  _EditPlayerProfileScreenState createState() => _EditPlayerProfileScreenState();
}

class _EditPlayerProfileScreenState extends State<EditPlayerProfileScreen> {
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final skillLevelController = TextEditingController();

  List<String> selectedSports = [];
  double skillLevel = 5.0;

  final List<String> availableSports = [
    'Cricket',
    'Badminton',
    'Pickleball',
    'Football',
    'Basketball',
    'Tennis',
    'Volleyball',
  ];

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    selectedSports = List.from(widget.profile.preferredSports);
    skillLevel = widget.profile.skillLevel;
    skillLevelController.text = skillLevel.toStringAsFixed(1);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

    try {
      await _firestoreService.updatePlayerProfile(widget.profile.userId, {
        'preferredSports': selectedSports,
        'skillLevel': skillLevel,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    skillLevelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Update Your Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 30),

              // Skill Level
              TextFormField(
                controller: skillLevelController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Skill Level (1.0 - 10.0)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.star),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your skill level';
                  }
                  double? level = double.tryParse(value);
                  if (level == null || level < 1.0 || level > 10.0) {
                    return 'Skill level must be between 1.0 and 10.0';
                  }
                  skillLevel = level;
                  return null;
                },
              ),
              SizedBox(height: 25),

              // Preferred Sports
              Text(
                'Preferred Sports',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: availableSports.map((sport) {
                  bool isSelected = selectedSports.contains(sport);
                  return FilterChip(
                    label: Text(sport),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedSports.add(sport);
                        } else {
                          selectedSports.remove(sport);
                        }
                      });
                    },
                    selectedColor: AppTheme.theme.colorScheme.primary.withOpacity(0.3),
                    checkmarkColor: AppTheme.theme.colorScheme.primary,
                  );
                }).toList(),
              ),
              SizedBox(height: 30),

              // Save Button
              ElevatedButton(
                onPressed: isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
