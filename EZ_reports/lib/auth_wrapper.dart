import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';
import 'landing.dart';
import 'bottomnav.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    
    // Listen to authentication state changes
    AuthService.listenToAuthChanges((AuthState data) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is authenticated
    if (AuthService.isAuthenticated) {
      return const Bottomnav();
    } else {
      return const LandingPage();
    }
  }
}
