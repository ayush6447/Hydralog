import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = await AuthService.signInWithGoogle();
      if (user == null && mounted) {
        setState(() { _error = 'Sign-in cancelled.'; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // App icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF64D2FF).withOpacity(0.15),
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/new-logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'FlowTrack',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your personal health dashboard,\nsynced across all your devices.',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white.withOpacity(0.5),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 48),

              // Feature rows
              _featureRow(
                Icons.water_drop_rounded,
                'Water intake',
                'Log and sync in real time',
                const Color(0xFF64D2FF),
              ),
              _featureRow(
                Icons.directions_walk_rounded,
                'Steps',
                'From iPhone and Samsung',
                const Color(0xFFFF9F0A),
              ),
              _featureRow(
                Icons.local_fire_department_rounded,
                'Calories & sleep',
                'From Apple Health or Health Connect',
                const Color(0xFFFF375F),
              ),
              _featureRow(
                Icons.phone_android_rounded,
                'Screen time',
                'Samsung only',
                const Color(0xFF5E5CE6),
              ),

              const Spacer(),

              // Sign in button
              if (_loading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFF64D2FF)),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _signIn,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('Continue with Google',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(_error!,
                      style: const TextStyle(
                          color: Color(0xFFFF375F), fontSize: 13)),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow(
      IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
              Text(subtitle,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
