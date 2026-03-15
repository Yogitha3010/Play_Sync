import 'package:flutter/material.dart';
import '../models/team_model.dart';
import '../models/player_profile_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'player_detail_screen.dart';
import 'chat_screen.dart';

class TeamDetailScreen extends StatefulWidget {
  final TeamModel team;

  const TeamDetailScreen({Key? key, required this.team}) : super(key: key);

  @override
  _TeamDetailScreenState createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  List<PlayerProfileModel> _players = [];
  bool _isLoading = true;
  late TeamModel _currentTeam;

  @override
  void initState() {
    super.initState();
    _currentTeam = widget.team;
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
    });

    List<PlayerProfileModel> loadedPlayers = [];
    for (String playerId in _currentTeam.players) {
      final profile = await _firestoreService.getPlayerProfile(playerId);
      if (profile != null) {
        loadedPlayers.add(profile);
      }
    }

    if (mounted) {
      setState(() {
        _players = loadedPlayers;
        _isLoading = false;
      });
    }
  }

  Future<void> _joinTeam() async {
    final user = _authService.currentUser;
    if (user != null) {
      await _firestoreService.joinTeam(_currentTeam.teamId, user.uid);
      final updatedTeam = await _firestoreService.getTeam(_currentTeam.teamId);
      if (updatedTeam != null && mounted) {
        setState(() {
          _currentTeam = updatedTeam;
        });
        _loadPlayers();
      }
    }
  }

  Future<void> _leaveTeam() async {
    final user = _authService.currentUser;
    if (user != null) {
      await _firestoreService.leaveTeam(_currentTeam.teamId, user.uid);
      final updatedTeam = await _firestoreService.getTeam(_currentTeam.teamId);
      if (updatedTeam != null && mounted) {
        setState(() {
          _currentTeam = updatedTeam;
        });
        _loadPlayers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final isMember = user != null && _currentTeam.players.contains(user.uid);
    final isCreator = user != null && _currentTeam.createdBy == user.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTeam.teamName),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (isMember || isCreator)
            IconButton(
              icon: Icon(Icons.chat),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatRoomId: _currentTeam.teamId,
                      chatTitle: '${_currentTeam.teamName} Chat',
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.theme.primaryColor.withOpacity(0.1),
                      child: Icon(Icons.group, size: 50, color: AppTheme.theme.primaryColor),
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      _currentTeam.teamName,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _currentTeam.gameType,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  if (user != null)
                    Center(
                      child: ElevatedButton(
                        onPressed: isCreator ? null : (isMember ? _leaveTeam : _joinTeam),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCreator
                              ? Colors.grey
                              : (isMember ? Colors.red : AppTheme.theme.primaryColor),
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          isCreator
                              ? 'You Created This Team'
                              : (isMember ? 'Leave Team' : 'Join Team'),
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  SizedBox(height: 30),
                  Text(
                    'Team Members (${_players.length})',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _players.length,
                    itemBuilder: (context, index) {
                      final player = _players[index];
                      final isTeamCreator = player.userId == _currentTeam.createdBy;

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Text(
                              (player.name?.isNotEmpty ?? false) ? player.name![0].toUpperCase() : '?',
                              style: TextStyle(color: Colors.blue[900]),
                            ),
                          ),
                          title: Text(player.name ?? 'Unknown Player'),
                          subtitle: Text('Skill Level: ${player.skillLevel.toStringAsFixed(1)}'),
                          trailing: isTeamCreator
                              ? Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Admin',
                                    style: TextStyle(color: Colors.amber[900], fontSize: 12),
                                  ),
                                )
                              : null,
                          onTap: () {
                            if (player.userId != user?.uid) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlayerDetailScreen(playerId: player.userId),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
