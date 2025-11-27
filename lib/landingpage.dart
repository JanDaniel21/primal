import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'dashboard.dart';

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
        // Login success -> navigate to Dashboard
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

  /// For testing: create a user with the entered username/password.
  Future<void> _registerTestUser() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Enter username/password to register.';
      });
      return;
    }

    try {
      final id = await DatabaseHelper.instance.createUser(username, password);
      setState(() {
        _errorMessage = 'Registered user (id: $id). Now press Login.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Register error: $e';
      });
    }
  }

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

              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

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

                        const SizedBox(height: 8),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _registerTestUser,
                            child: const Text('Register (for testing)'),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextButton(
                          onPressed: () {
                            // Temporary: quick login as admin (username: admin, password: 1234)
                            _usernameController.text = 'admin';
                            _passwordController.text = '1234';
                          },
                          child: const Text('Fill test admin credentials'),
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
