import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'turf_home_screen.dart';
import 'turf_profile_setup_screen.dart';
import 'turf_register_screen.dart';

class TurfLoginScreen extends StatefulWidget {
  @override
  _TurfLoginScreenState createState() => _TurfLoginScreenState();
}

class _TurfLoginScreenState extends State<TurfLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  void showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : AppTheme.secondary,
      ),
    );
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final userCredential = await _authService.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (userCredential != null) {
        // Check if email is verified
        if (!userCredential.user!.emailVerified) {
          showMessage(
            'Please verify your email before logging in. Check your inbox for the verification link.',
          );
          await _authService.logout(); // Sign out unverified user
          return;
        }

        final userData = await _authService.getUserData(userCredential.user!.uid);
        final ownerTurfs = await _firestoreService.getTurfsByOwner(
          userCredential.user!.uid,
        );

        final nextScreen =
            (userData == null || !userData.profileCompleted || ownerTurfs.isEmpty)
            ? TurfProfileSetupScreen(ownerId: userCredential.user!.uid)
            : TurfHomeScreen();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      }
    } catch (e) {
      showMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => isLoading = true);

    try {
      final userCredential = await _authService.signInWithGoogleAsTurfOwner();
      if (userCredential == null) {
        return;
      }

      final userData = await _authService.getUserData(userCredential.user!.uid);
      final ownerTurfs = await _firestoreService.getTurfsByOwner(
        userCredential.user!.uid,
      );

      if (!mounted) return;
      final nextScreen =
          (userData == null || !userData.profileCompleted || ownerTurfs.isEmpty)
          ? TurfProfileSetupScreen(ownerId: userCredential.user!.uid)
          : TurfHomeScreen();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    } catch (e) {
      if (mounted) {
        showMessage(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      showMessage('Please enter your email address first');
      return;
    }
    if (!email.contains('@')) {
      showMessage('Please enter a valid email address');
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(email);
      showMessage(
        'Password reset email sent. Check your inbox.',
        isError: false,
      );
    } catch (e) {
      showMessage(
        'Failed to send reset email: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Turf Owner Login"),
      ),
      body: Container(
        decoration: AppTheme.pageDecoration(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: AppTheme.surfaceCardDecoration(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: AppTheme.heroGradient,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome Back",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Login to manage your turf operations.",
                              style: TextStyle(
                                color: Colors.white,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Email is required";
                          }
                          if (!value.contains("@")) {
                            return "Enter a valid email";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Password is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),
                      ElevatedButton(
                        onPressed: isLoading ? null : login,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text("Login"),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: isLoading ? null : _handleGoogleSignIn,
                        icon: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(
                                Icons.g_mobiledata,
                                size: 32,
                                color: Colors.red,
                              ),
                        label: const Text('Continue with Google'),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "New owner? ",
                            style: TextStyle(color: AppTheme.mutedText),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TurfRegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Register",
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
