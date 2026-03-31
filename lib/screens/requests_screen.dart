import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/booking_model.dart';
import '../models/play_request_model.dart';
import '../models/player_profile_model.dart';
import '../models/turf_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({Key? key}) : super(key: key);

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  bool isLoading = true;
  List<PlayRequestModel> incomingRequests = [];
  List<PlayRequestModel> outgoingRequests = [];
  final Map<String, PlayerProfileModel?> _profiles = {};
  final Map<String, TurfModel?> _turfs = {};

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  String _displayName(PlayerProfileModel? profile) {
    final name = (profile?.name ?? '').trim();
    if (name.isNotEmpty) {
      return name;
    }

    final username = (profile?.username ?? '').trim();
    if (username.isNotEmpty) {
      return username;
    }

    return 'Player';
  }

  String _avatarInitial(PlayerProfileModel? profile) {
    final label = _displayName(profile).trim();
    return label.isNotEmpty ? label.substring(0, 1).toUpperCase() : 'P';
  }

  Future<void> _loadRequests() async {
    setState(() => isLoading = true);
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final incoming = await _firestoreService.getIncomingPlayRequests(
        currentUser.uid,
      );
      final outgoing = await _firestoreService.getOutgoingPlayRequests(
        currentUser.uid,
      );

      final userIds = <String>{
        ...incoming.map((item) => item.fromUserId),
        ...outgoing.map((item) => item.toUserId),
      };
      final turfIds = <String>{
        ...incoming.map((item) => item.turfId),
        ...outgoing.map((item) => item.turfId),
      };

      _profiles.clear();
      _turfs.clear();

      for (final userId in userIds) {
        try {
          _profiles[userId] = await _firestoreService.getPlayerProfile(userId);
        } catch (_) {
          _profiles[userId] = null;
        }
      }
      for (final turfId in turfIds) {
        try {
          _turfs[turfId] = await _firestoreService.getTurf(turfId);
        } catch (_) {
          _turfs[turfId] = null;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        incomingRequests = incoming;
        outgoingRequests = outgoing;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading requests: $e')),
      );
    }
  }

  Future<void> _handleRequestAction(
    PlayRequestModel request,
    String status,
  ) async {
    try {
      if (status == 'accepted') {
        final turf = _turfs[request.turfId] ??
            await _firestoreService.getTurf(request.turfId);
        if (turf == null) {
          throw Exception('Selected turf is no longer available.');
        }

        final booking = BookingModel(
          bookingId: Uuid().v4(),
          turfId: turf.turfId,
          turfOwnerId: turf.ownerId,
          playerId: request.fromUserId,
          gameType: request.gameType,
          bookingDate: DateTime(
            request.date.year,
            request.date.month,
            request.date.day,
          ),
          slotTime: request.slotTime,
          createdAt: DateTime.now(),
        );

        await _firestoreService.createBooking(
          booking,
          maxBookingsPerSlot: turf.courts[request.gameType] ?? 1,
        );
      }

      await _firestoreService.updatePlayRequestStatus(request.requestId, status);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted'
                ? 'Request accepted and converted to booking.'
                : 'Request rejected.',
          ),
        ),
      );
      await _loadRequests();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request update failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Requests'),
          backgroundColor: AppTheme.theme.primaryColor,
          foregroundColor: Colors.white,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Incoming'),
              Tab(text: 'Outgoing'),
            ],
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildRequestList(
                    requests: incomingRequests,
                    incoming: true,
                  ),
                  _buildRequestList(
                    requests: outgoingRequests,
                    incoming: false,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRequestList({
    required List<PlayRequestModel> requests,
    required bool incoming,
  }) {
    if (requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRequests,
        child: ListView(
          children: [
            SizedBox(height: 180),
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Center(
              child: Text(
                incoming ? 'No incoming requests yet.' : 'No outgoing requests yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          final profile = _profiles[incoming ? request.fromUserId : request.toUserId];
          final turf = _turfs[request.turfId];

          return Card(
            margin: EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        child: Text(_avatarInitial(profile)),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayName(profile),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (((profile?.name) ?? '').trim().isEmpty &&
                                ((profile?.username) ?? '').trim().isNotEmpty)
                              Text(
                                profile!.username!,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                          ],
                        ),
                      ),
                      _StatusChip(status: request.status),
                    ],
                  ),
                  SizedBox(height: 14),
                  _DetailRow('Game', request.gameType),
                  _DetailRow('Turf', turf?.name ?? 'Selected turf'),
                  _DetailRow(
                    'Date',
                    '${request.date.day}/${request.date.month}/${request.date.year}',
                  ),
                  _DetailRow('Slot', request.slotTime),
                  if (incoming && request.status == 'pending') ...[
                    SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleRequestAction(
                              request,
                              'rejected',
                            ),
                            child: Text('Reject'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleRequestAction(
                              request,
                              'accepted',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.theme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Accept'),
                          ),
                        ),
                      ],
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'accepted'
        ? Colors.green
        : status == 'rejected'
            ? Colors.red
            : Colors.orange;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}


