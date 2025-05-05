import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isSignUp = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "",
        ),
        backgroundColor: Colors.teal.shade800, // Set the background color here
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(),
              SizedBox(height: 24),
              _isSignUp ? _buildSignUpForm() : _buildSignInForm(),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildLogo() {
  return FractionallySizedBox(
    widthFactor: 0.8, // Use 80% of the screen width
    child: AspectRatio(
      aspectRatio: 16 / 9, 
      child: Image.asset(
        'assets/TheSpindexFullLogo.png',
        fit: BoxFit.contain,
      ),
    ),
  );
}

  // Widget for the sign-in form
  Widget _buildSignInForm() {
    return Column(
      children: [
        _buildTextField(_emailController, "Email"),
        _buildTextField(_passwordController, "Password", obscureText: true),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _handleSignIn,
          child: Text("Sign In"),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isSignUp = true;
            });
          },
          child: Text("Don't have an account? Sign Up"),
        ),
        TextButton(
          onPressed: _handleForgotPassword,
          child: Text("Forgot Password?"),
        ),
      ],
    );
  }

  // Widget for the sign-up form
  Widget _buildSignUpForm() {
    return Column(
      children: [
        _buildTextField(_emailController, "Email"),
        _buildTextField(_passwordController, "Password", obscureText: true),
        _buildTextField(_confirmPasswordController, "Confirm Password", obscureText: true),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _handleSignUp,
          child: Text("Sign Up"),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isSignUp = false;
            });
          },
          child: Text("Already have an account? Sign In"),
        ),
      ],
    );
  }

  // Helper method to build text fields
  Widget _buildTextField(TextEditingController controller, String labelText, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: labelText),
      obscureText: obscureText,
    );
  }

  // Method to handle sign-in
  Future<void> _handleSignIn() async {
    if (!_isValidEmail(_emailController.text)) {
      _showToast("Invalid email format");
      return;
    }
    try {
      final user = await _authService.signIn(
        _emailController.text,
        _passwordController.text,
      );
      if (user != null) {
        _showToast("Signed in: ${user.uid}");

        // Check if the user's profile exists
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          // Initialize the user's profile if it doesn't exist
          await userDoc.set({
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
          });

          await userDoc.collection('lists').add({
            'name': 'My Collection',
            'createdAt': FieldValue.serverTimestamp(),
            'albums': [],
          });

          _showToast("Profile initialized for user: ${user.uid}");
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainPage(),
          ),
        );
      }
    } catch (e) {
      _showToast("Error signing in: ${e.toString()}");
    }
  }

  // Method to handle sign-up
  Future<void> _handleSignUp() async {
    if (!_isValidEmail(_emailController.text)) {
      _showToast("Invalid email format");
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showToast("Passwords do not match");
      return;
    }
    try {
      final user = await _authService.signUp(
        _emailController.text,
        _passwordController.text,
      );
      if (user != null) {
        _showToast("Signed up: ${user.uid}");
        await _createDefaultList(user); // Ensure the default list is created
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainPage(), // Navigate only after list creation
          ),
        );
      }
    } catch (e) {
      _showToast("Error signing up: ${e.toString()}");
    }
  }

  // Method to handle "Forgot Password"
  Future<void> _handleForgotPassword() async {
    if (!_isValidEmail(_emailController.text)) {
      _showToast("Please enter a valid email address.");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text);
      _showToast("Password reset email sent. Check your inbox.");
    } catch (e) {
      _showToast("Error sending password reset email: ${e.toString()}");
    }
  }

  // Method to create a default list for a new user
  Future<void> _createDefaultList(User user) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

    await userDoc.set({
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await userDoc.collection('lists').add({
      'name': 'My Collection',
      'createdAt': FieldValue.serverTimestamp(),
      'albums': [],
    });
  }

  // Utility method to validate email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  // Utility method to show a toast message
  void _showToast(String message) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
