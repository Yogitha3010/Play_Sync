import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'my_matches_by_game_screen.dart';

class MyMatchesGameSelectionScreen extends StatefulWidget {
  const MyMatchesGameSelectionScreen({Key? key}) : super(key: key);

  @override
  State<MyMatchesGameSelectionScreen> createState() =>
      _MyMatchesGameSelectionScreenState();
}

class _MyMatchesGameSelectionScreenState
    extends State<MyMatchesGameSelectionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool isLoading = true;
  List<String> games = [];

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    try {
      final availableGames = await _firestoreService.getAvailableGameTypes();
      if (!mounted) {
        return;
      }
      setState(() {
        games = availableGames;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading games: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Matches'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          AppTheme.theme.primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.sports,
                        color: AppTheme.theme.primaryColor,
                      ),
                    ),
                    title: Text(
                      game,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyMatchesByGameScreen(selectedGame: game),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
