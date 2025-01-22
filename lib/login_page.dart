import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_sign_in/google_sign_in.dart'; // Removed
import 'register_page.dart';
import 'forgotpassword_page.dart';
import 'main_page_client.dart';
import 'main_page_trainer.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // final GoogleSignIn _googleSignIn = GoogleSignIn(); // Removed

  // Funkce pro přihlášení uživatele
  Future<void> _loginUser() async {
    try {
      // Přihlášení uživatele
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Načtení role uživatele
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      
      if (userDoc.exists && mounted) {
        String role = userDoc['role'];

        // Přesměrování na odpovídající stránku podle role
        if (role == 'client') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainPageClient()),
          );
        } else if (role == 'trainer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainPageTrainer()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Neznámá role, nelze pokračovat.')),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Úspěšné přihlášení!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba při přihlášení: ${e.message}')),
        );
      }
    }
  }

  // Removed Google Sign-In method
  // Future<void> _signInWithGoogle() async {
  //   // Google Sign-In code
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Přihlášení',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal.shade700, // Changed to a more prominent color
        elevation: 4, // Added elevation for better visibility
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color.fromARGB(255, 0, 0, 0), Colors.grey.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Vítejte zpět!',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 20),

                // Textové pole pro email
                _buildTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  icon: Icons.email,
                  onChanged: (value) {
                    if (!value.contains('@')) {
                      _emailController.value = TextEditingValue(
                        text: '$value@',
                        selection: TextSelection.fromPosition(
                          TextPosition(offset: value.length + 1),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 15),

                // Textové pole pro heslo
                _buildTextField(
                  controller: _passwordController,
                  labelText: 'Heslo',
                  icon: Icons.lock,
                  obscureText: true,
                ),
                const SizedBox(height: 20),

                // Tlačítko pro přihlášení
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade600,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _loginUser,
                    child: const Text(
                      'Přihlásit se',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Removed Google sign-in button
                // Center(
                //   child: ElevatedButton(
                //     onPressed: _signInWithGoogle,
                //     child: const Text('Sign in with Google'),
                //   ),
                // ),
                const SizedBox(height: 10),

                // Odkaz na registraci
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    child: const Text(
                      'Nemáte účet? Zaregistrujte se',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                // Odkaz na zapomenuté heslo
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage()),
                      );
                    },
                    child: const Text(
                      'Zapomněli jste heslo?',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Funkce pro zobrazení textového pole
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white),
        prefixIcon: Icon(icon, color: Colors.white),
        filled: true,
        fillColor: Colors.black87,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
    );
  }
}
