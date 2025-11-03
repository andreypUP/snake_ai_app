import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:venom_shield_ph/routes.dart';
import 'package:venom_shield_ph/domain/services/auth_service.dart';
import 'package:venom_shield_ph/core/di/injection_container.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  final AuthService _authService = getIt<AuthService>();
  int _selectedIndex = 0;
  bool _isLoading = false;
  User? _currentUser;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _checkLoginState();
    _authService.authStateChanges.listen((User? user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  Future<void> _checkLoginState() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user was previously logged in
      final isLoggedIn = await _authService.isUserLoggedIn();

      if (isLoggedIn) {
        // Firebase Auth automatically restores the session
        _currentUser = _authService.currentUser;

        // If Firebase session expired but SharedPreferences says logged in, clear it
        if (_currentUser == null) {
          await _authService.signOut();
        }
      }
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential != null && mounted) {
        // User successfully signed in - auth state listener will update UI automatically
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${userCredential.user?.displayName ?? 'User'}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleContinueAsGuest() {
    setState(() {
      _isGuest = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Continuing as guest - AI Cam only'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _handleSignOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signOut();
      setState(() {
        _isGuest = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    // Guest can only access AI Cam (index 0)
    if (_isGuest && index != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to access this feature'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentUser == null && !_isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first')),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    // Navigate to the corresponding page
    switch (index) {
      case 0:
        AICamPageRoute().push(context);
        break;
      case 1:
        ReportPageRoute().push(context);
        break;
      case 2:
        MapPageRoute().push(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (_currentUser != null || _isGuest)
          ? AppBar(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              title: Text(_isGuest ? 'Guest Mode' : 'Venom Shield PH'),
              actions: [
                if (_currentUser != null && _currentUser!.photoURL != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(_currentUser!.photoURL!),
                    ),
                  ),
                if (_isGuest)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'signout') {
                      _handleSignOut();
                    }
                  },
                  itemBuilder: (context) => [
                    if (_isGuest)
                      PopupMenuItem(
                        value: 'signout',
                        child: Row(
                          children: const [
                            Icon(Icons.exit_to_app, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Exit Guest Mode'),
                          ],
                        ),
                      )
                    else
                      PopupMenuItem(
                        value: 'signout',
                        child: Row(
                          children: const [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Sign Out'),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            )
          : null,
      body: _isLoading
          ? Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.green,
                ),
              ),
            )
          : (_currentUser == null && !_isGuest)
              ? _buildSignInUI()
              : _buildHomeUI(),
      bottomNavigationBar: (_currentUser != null || _isGuest)
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: Colors.green,
              unselectedItemColor: Colors.grey,
              selectedFontSize: 14,
              unselectedFontSize: 12,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.camera_alt_outlined),
                  activeIcon: Icon(Icons.camera_alt),
                  label: 'AI Cam',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.report_outlined),
                  activeIcon: Icon(Icons.report),
                  label: 'Report',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined),
                  activeIcon: Icon(Icons.map),
                  label: 'Map',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildSignInUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield,
              size: 120,
              color: Colors.green.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'Venom Shield PH',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your snake safety companion',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleGoogleSignIn,
              icon: Image.asset(
                'assets/google_logo.png',
                height: 24,
                width: 24,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.login, color: Colors.white);
                },
              ),
              label: const Text(
                'Sign in with Google',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _handleContinueAsGuest,
              icon: const Icon(Icons.person_outline),
              label: const Text(
                'Continue as Guest',
                style: TextStyle(fontSize: 18),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange, width: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Guest mode: Offline AI Cam only',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isGuest ? Icons.person : Icons.shield,
            size: 120,
            color: _isGuest ? Colors.orange.shade300 : Colors.green.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            _isGuest ? 'Guest Mode' : 'Welcome!',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: _isGuest ? Colors.orange : Colors.green,
            ),
          ),
          if (!_isGuest) ...[
            const SizedBox(height: 8),
            Text(
              _currentUser?.displayName ?? 'User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            _isGuest
                ? 'You can only access AI Cam in guest mode'
                : 'Select an option from the menu below',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (_isGuest) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isGuest = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Sign In for Full Access'),
            ),
          ],
        ],
      ),
    );
  }
}