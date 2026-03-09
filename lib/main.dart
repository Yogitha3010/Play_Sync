import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import 'screens/role_selection_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Run the app immediately, initialize Firebase in the background
  runApp(PlaySyncApp());
  
  // Initialize Firebase asynchronously
  _initializeFirebase();
}

Future<void> _initializeFirebase() async {
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      final options = DefaultFirebaseOptions.currentPlatform;
      await Firebase.initializeApp(options: options);
      print('Firebase initialized successfully for ${kIsWeb ? "web" : "mobile"}');
    } else {
      print('Firebase already initialized');
    }
    
    // Verify Firebase is initialized
    final app = Firebase.app();
    print('Firebase app name: ${app.name}');
  } catch (e, stackTrace) {
    print('Firebase initialization error: $e');
    print('Stack trace: $stackTrace');
    
    // For web, try initializing without options as fallback
    if (kIsWeb) {
      try {
        print('Attempting Firebase initialization without options (web fallback)...');
        await Firebase.initializeApp();
        print('Firebase initialized with default options (web fallback)');
      } catch (e2) {
        print('Firebase initialization failed completely: $e2');
        print('App will continue but Firebase features may not work');
      }
    }
  }
}

class PlaySyncApp extends StatelessWidget {
  const PlaySyncApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PlaySync',
      theme: AppTheme.theme,
      home: RoleSelectionScreen(),
    );
  }
}
