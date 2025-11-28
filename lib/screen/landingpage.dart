import 'package:flutter/material.dart';
import '../backend/database_helper.dart';
import 'dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // EMAIL / PASSWORD LOGIN  (will switch to Firebase later)
  // ----------------------------------------------------------
  Future<void> _login() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _loading = false;
        _errorMessage = 'Please enter username and password.';
      });
      return;
    }

    try {
      final user = await DatabaseHelper.instance.getUser(username, password);
      if (user != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid username or password.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Database error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // ----------------------------------------------------------
  // GOOGLE LOGIN
  // ----------------------------------------------------------
Future<void> _googleLogin() async {
  setState(() {
    _loading = true;
    _errorMessage = null;
  });

  try {
    final GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: ['email'],
      serverClientId: "257276967770-kn631cuvo9skjdkonqospgc5ofrsdtgr.apps.googleusercontent.com",
    );

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      setState(() => _loading = false);
      return; // user cancelled
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  } catch (e) {
    setState(() {
      _errorMessage = "Google login failed: $e";
    });
  } finally {
    setState(() => _loading = false);
  }
}

  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Primal — Login'),
        backgroundColor: const Color(0xFF0A7A78),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Welcome',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // USERNAME
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // PASSWORD
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),

              // ERRORS
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              // LOGIN BUTTON
              _loading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A7A78),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _login,
                            child: const Text('Login'),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ------------------------------------
                        // GOOGLE LOGIN BUTTON
                        // ------------------------------------
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _googleLogin,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.black12),
                            ),
                            icon: Image.asset(
                              'assets/google.png',
                              height: 22,
                            ),
                            label: const Text(
                              "Continue with Google",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
