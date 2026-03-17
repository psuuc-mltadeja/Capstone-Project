import 'package:cityinsight_mobile/auth/phone.dart';
import 'package:cityinsight_mobile/auth/register.dart';
import 'package:cityinsight_mobile/auth/reset.dart';
import 'package:cityinsight_mobile/auth/verifye_email.dart';
import 'package:cityinsight_mobile/screens/mainscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool showPassword = true;
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();

  void toggleShowPassword() {
    setState(() {
      showPassword = !showPassword;
    });
  }

  void login() async {
    if (formKey.currentState!.validate()) {
      EasyLoading.show(status: 'Processing...');

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
                email: email.text, password: password.text);

        User user = userCredential.user!;

        var userDoc = await FirebaseFirestore.instance
            .collection('users') // Ensure this matches your Firestore structure
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          // Retrieve the 'status' field if it exists
          String? status = userDoc.data()?['status'];

          if (status == 'banned') {
            EasyLoading.dismiss();
            EasyLoading.showError('Your account is banned.');
            FirebaseAuth.instance.signOut();
            return; // Stop further login attempt if the account is banned
          } else if (status == null || status == 'active') {
            // Continue login if status is 'active' or not set
            if (!user.emailVerified) {
              EasyLoading.dismiss();
              // Navigate to VerifyEmailScreen if not verified
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute(builder: (_) => const VerifyEmailScreen()),
              );
            } else {
              EasyLoading.dismiss();
              String userId = user.uid;
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute(builder: (_) => MainScreen(userId: userId)),
              );
            }
          }
        } else {
          // Handle case where user document does not exist
          EasyLoading.dismiss();
          EasyLoading.showError('User does not exist in the database.');
        }
      } catch (error) {
        print('ERROR: $error');
        EasyLoading.dismiss();
        EasyLoading.showError('Incorrect Username and/or Password');
      }
    }
  }

  _signInWithGoogle() async {
    final GoogleSignIn _googleSignIn = GoogleSignIn();
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken,
        );

        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        String userId = userCredential.user!.uid;

        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: (context) => MainScreen(userId: userId),
          ),
        );
      }
    } catch (err) {
      print('Error: $err');
      EasyLoading.showError('Some error occurred: $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Welcome to City Insight',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(30),
                  TextFormField(
                    controller: email,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required. Please enter an email address';
                      }
                      if (!EmailValidator.validate(value)) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[200],
                      prefixIcon: const Icon(Icons.email),
                    ),
                  ),
                  const Gap(12),
                  TextFormField(
                    controller: password,
                    obscureText: showPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required. Please enter your password';
                      }
                      if (value.length <= 5) {
                        return 'Password should be more than 6 characters';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[200],
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        onPressed: toggleShowPassword,
                        icon: Icon(showPassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                      ),
                    ),
                  ),
                  const Gap(16),
                  ForgotPassword(),
                  const Gap(16),
                  ElevatedButton(
                    onPressed: login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const Gap(20),
                  // Row for Google and Phone Sign-In Buttons
                  ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Red color for Google
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(FontAwesomeIcons.google,
                        color: Colors.white),
                    label: const Text(
                      'Google',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Gap(20),
                  // Phone Sign-In Button
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PhoneAuth()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue), // Blue border
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.phone, color: Colors.blue),
                    label: const Text(
                      'Phone',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Gap(20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Doesn't have an account? ",
                        style: TextStyle(fontSize: 16),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Register',
                          style: TextStyle(fontSize: 16, color: Colors.blue),
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
    );
  }
}
