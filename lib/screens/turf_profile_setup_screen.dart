import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/turf_model.dart';
import '../theme/app_theme.dart';
import 'turf_home_screen.dart';

class TurfProfileSetupScreen extends StatefulWidget {
  final String ownerId;
  final TurfModel? existingTurf;
  final bool navigateToHomeOnSave;

  const TurfProfileSetupScreen({
    Key? key,
    required this.ownerId,
    this.existingTurf,
    this.navigateToHomeOnSave = true,
  }) : super(key: key);

  @override
  _TurfProfileSetupScreenState createState() => _TurfProfileSetupScreenState();
}

class _TurfProfileSetupScreenState extends State<TurfProfileSetupScreen> {
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final turfNameController = TextEditingController();
  final locationController = TextEditingController();
  final priceController = TextEditingController();
  final contactController = TextEditingController();

  Map<String, bool> games = {
    'Cricket': false,
    'Badminton': false,
    'Pickleball': false,
    'Football': false,
    'Basketball': false,
    'Tennis': false,
  };

  Map<String, TextEditingController> courtControllers = {};

  List<String> facilities = [];
  final List<String> availableFacilities = [
    'AC',
    'Changing Room',
    'Parking',
    'Cafeteria',
    'First Aid',
    'Water Facility',
  ];

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Initialize court controllers
    for (String game in games.keys) {
      courtControllers[game] = TextEditingController();
    }
    _populateExistingData();
  }

  void _populateExistingData() {
    final turf = widget.existingTurf;
    if (turf == null) return;

    turfNameController.text = turf.name;
    locationController.text = turf.location;
    priceController.text = turf.pricePerHour.toStringAsFixed(0);
    contactController.text = turf.contact ?? '';
    facilities = List<String>.from(turf.facilities);

    for (final game in turf.gamesAvailable) {
      if (games.containsKey(game)) {
        games[game] = true;
        courtControllers[game]?.text = (turf.courts[game] ?? 0).toString();
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if at least one game is selected
    bool hasGame = games.values.any((selected) => selected);
    if (!hasGame) {
      showMessage('Please select at least one game');
      return;
    }

    // Validate court numbers for selected games
    List<String> selectedGames = games.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    for (String game in selectedGames) {
      String courtCount = courtControllers[game]!.text;
      if (courtCount.isEmpty || int.tryParse(courtCount) == null) {
        showMessage('Please enter number of courts for $game');
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      Map<String, int> courts = {};
      for (String game in selectedGames) {
        courts[game] = int.parse(courtControllers[game]!.text);
      }

      final existingTurf = widget.existingTurf;

      if (existingTurf == null) {
        final turf = TurfModel(
          turfId: Uuid().v4(),
          ownerId: widget.ownerId,
          name: turfNameController.text.trim(),
          location: locationController.text.trim(),
          gamesAvailable: selectedGames,
          courts: courts,
          pricePerHour: double.tryParse(priceController.text) ?? 0.0,
          facilities: facilities,
          contact: contactController.text.trim(),
          createdAt: DateTime.now(),
        );

        await _firestoreService.createTurf(turf);
        await _authService.updateProfileCompletion(widget.ownerId, true);
      } else {
        await _firestoreService.updateTurf(existingTurf.turfId, {
          'name': turfNameController.text.trim(),
          'turfName': turfNameController.text.trim(),
          'location': locationController.text.trim(),
          'gamesAvailable': selectedGames,
          'gameTypes': selectedGames,
          'courts': courts,
          'pricePerHour': double.tryParse(priceController.text) ?? 0.0,
          'facilities': facilities,
          'contact': contactController.text.trim(),
          'isActive': existingTurf.isActive,
        });
      }

      if (mounted) {
        if (widget.navigateToHomeOnSave) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => TurfHomeScreen()),
          );
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      showMessage('Error saving profile: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    turfNameController.dispose();
    locationController.dispose();
    priceController.dispose();
    contactController.dispose();
    for (var controller in courtControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingTurf == null ? 'Complete Turf Profile' : 'Edit Turf Profile',
        ),
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
                widget.existingTurf == null ? 'Welcome!' : 'Edit Turf Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                widget.existingTurf == null
                    ? 'Complete your turf profile to get started'
                    : 'Update your turf information and keep it current',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 30),

              // Turf Name
              TextFormField(
                controller: turfNameController,
                decoration: InputDecoration(
                  labelText: 'Turf Name *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.stadium),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Turf name is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),

              // Location
              TextFormField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Location *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),

              // Price
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price Per Hour (₹) *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Price is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid price';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),

              // Contact
              TextFormField(
                controller: contactController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Contact Number *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Contact number is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 25),

              // Games Available
              Text(
                'Games Available *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ...games.keys.map((game) {
                return CheckboxListTile(
                  title: Text(game),
                  value: games[game],
                  onChanged: (value) {
                    setState(() {
                      games[game] = value!;
                    });
                  },
                );
              }).toList(),

              // Court Numbers
              ...games.keys.where((game) => games[game]!).map((game) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: courtControllers[game],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Number of $game Courts *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.sports),
                    ),
                    validator: (value) {
                      if (games[game]! && (value == null || value.isEmpty)) {
                        return 'Enter number of courts';
                      }
                      return null;
                    },
                  ),
                );
              }).toList(),

              SizedBox(height: 20),

              // Facilities
              Text(
                'Facilities',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: availableFacilities.map((facility) {
                  bool isSelected = facilities.contains(facility);
                  return FilterChip(
                    label: Text(facility),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          facilities.add(facility);
                        } else {
                          facilities.remove(facility);
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
                        widget.existingTurf == null
                            ? 'Complete Profile'
                            : 'Save Changes',
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
