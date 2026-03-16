import 'package:flutter/material.dart';
import '../models/team_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'create_team_screen.dart';
import 'team_detail_screen.dart';

class TeamsScreen extends StatefulWidget {
  @override
  _TeamsScreenState createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teams'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<TeamModel>>(
        stream: _firestoreService.getTeamsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading teams.\nPlease try again later.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final teams = snapshot.data ?? [];

          if (teams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No teams found.\nBe the first to create one!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return _buildTeamCard(context, team);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateTeamScreen()),
          );
        },
        icon: Icon(Icons.add),
        label: Text('Create Team'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildTeamCard(BuildContext context, TeamModel team) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.theme.primaryColor.withOpacity(0.1),
          child: Icon(Icons.sports, color: AppTheme.theme.primaryColor),
          radius: 28,
        ),
        title: Text(
          team.teamName,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sports_soccer, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(team.gameType),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    team.visibility == 'private' ? Icons.lock : Icons.public,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4),
                  Text(team.visibility == 'private' ? 'Private Team' : 'Public Team'),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text('${team.players.length} Players'),
                ],
              ),
            ],
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TeamDetailScreen(team: team)),
          );
        },
      ),
    );
  }
}
