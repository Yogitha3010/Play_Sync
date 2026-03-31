import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;

  // Collection references
  static CollectionReference get usersCollection => firestore.collection('users');
  static CollectionReference get playerProfilesCollection =>
      firestore.collection('playerProfiles');
  static CollectionReference get turfsCollection => firestore.collection('turfs');
  static CollectionReference get matchesCollection =>
      firestore.collection('matches');
  static CollectionReference get feedbackCollection =>
      firestore.collection('feedback');
  static CollectionReference get chatsCollection => firestore.collection('chats');
  static CollectionReference get teamsCollection => firestore.collection('teams');
  static CollectionReference get bookingsCollection => firestore.collection('bookings');
  static CollectionReference get bookingSlotsCollection =>
      firestore.collection('bookingSlots');
  static CollectionReference get playRequestsCollection =>
      firestore.collection('playRequests');
  static CollectionReference get notificationsCollection =>
      firestore.collection('notifications');
}
