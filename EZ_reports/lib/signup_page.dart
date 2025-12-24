import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'services/auth_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        phone: '', // Empty phone number since we removed the field
      );

      if (response.user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please check your email to verify your account.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to login page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF1f2b5b), // Solid blue background
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: width * 0.06),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  minWidth: 0,
                ),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.06, vertical: height * 0.04),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white, // Solid white for contrast
                            ),
                            padding: EdgeInsets.all(width * 0.04),
                            child: Icon(Icons.person_add, size: width * 0.15, color: const Color(0xFF1565C0)),
                          ),
                          SizedBox(height: height * 0.03),
                          Text(
                            'Sign up',
                            style: TextStyle(fontSize: width * 0.07, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          SizedBox(height: height * 0.04),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              labelStyle: const TextStyle(color: Color(0xFF1565C0)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              contentPadding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.02),
                            ),
                            style: const TextStyle(color: Colors.black),
                            cursorColor: const Color(0xFF1565C0),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              if (RegExp(r'^[0-9]+ ').hasMatch(value)) {
                                return 'Enter a valid name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: height * 0.025),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: const TextStyle(color: Color(0xFF1565C0)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              contentPadding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.02),
                            ),
                            style: const TextStyle(color: Colors.black),
                            cursorColor: const Color(0xFF1565C0),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter Email';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                return 'Enter a valid Email id';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: height * 0.025),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: Color(0xFF1565C0)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              contentPadding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.02),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  color: const Color(0xFF1565C0),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                            cursorColor: const Color(0xFF1565C0),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: height * 0.025),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              labelStyle: const TextStyle(color: Color(0xFF1565C0)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              contentPadding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.02),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                  color: const Color(0xFF1565C0),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                            cursorColor: const Color(0xFF1565C0),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: height * 0.03),
                          SizedBox(
                            width: double.infinity,
                            height: height * 0.07,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                foregroundColor: Colors.white,
                                elevation: 6,
                                shadowColor: const Color(0xFF1565C0).withOpacity(0.18),
                                textStyle: TextStyle(fontSize: width * 0.05, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: EdgeInsets.symmetric(vertical: height * 0.018),
                              ),
                              child: AnimatedScale(
                                scale: _isLoading ? 0.98 : 1.0,
                                duration: const Duration(milliseconds: 100),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      )
                                    : Text('Sign Up', style: TextStyle(fontSize: width * 0.05)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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