import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telemoni/screens/home.dart';
import 'package:telemoni/utils/api_service.dart';
import 'package:telemoni/utils/localstorage.dart';
import 'package:telemoni/utils/secure_storage_service.dart';
import 'package:telemoni/utils/themeprovider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  bool token = false;
  if (LocalStorage.getLogin() == 'y') {
    token = true;
  }

  print(token);

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(
          initialRoute: token == false
              ? '/login'
              : '/home'), // Direct to appropriate screen
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Telemoni',
      theme: themeProvider.themeData,
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const MainPageContent(),
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String? generatedOTP;
  bool otpVisible = false;
  final ApiService apiService = ApiService();
  final SecureStorageService secureStorageService = SecureStorageService();
  var verify = '';

  // Function to generate a random OTP

  void _handleLogin() async {
    String phoneNumber = '+91' + _phoneController.text;

    if (phoneNumber.isNotEmpty) {
      try {
        // Call the API and get the generated OTP
        generatedOTP = await apiService.generateOTP(_phoneController.text);
        FirebaseAuth.instance.verifyPhoneNumber(
            verificationCompleted: (PhoneAuthCredential) {
              print(PhoneAuthCredential);
            },
            verificationFailed: (Error) {
              print(Error);
            },
            codeSent: (verificationId, forceResendingToken) {
              verify = verificationId;
            },
            codeAutoRetrievalTimeout: (verificationId) {
              print('autoretrievaltimeout');
            },
            phoneNumber: phoneNumber);

        setState(() {
          otpVisible = true; // Show OTP input field
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent to your phone')),
        );
      } catch (e) {
        // Handle errors (e.g., show a SnackBar)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
    }
  }

  // Function to handle OTP verification and saving the token (phone number)
  Future<void> _verifyOTP() async {
    String enteredOTP = _otpController.text;
    String phoneNumber = _phoneController.text;

    if (enteredOTP.isNotEmpty && phoneNumber.isNotEmpty) {
      try {
        // Attempt to create credential with verificationId and OTP code
        final cred = PhoneAuthProvider.credential(
            verificationId: verify, smsCode: enteredOTP);

        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(cred);

        // Adding a small delay to ensure the ID token is ready
        await Future.delayed(Duration(seconds: 1));

        // Get the ID token explicitly
        String? idToken = await userCredential.user?.getIdToken();
        print("Generated ID Token: $idToken");

        if (idToken != null) {
          // Call the API to verify the OTP, pass the idToken and phone number
          String? token = await apiService.verifyOTP(idToken, phoneNumber);

          if (token != null) {
            // Store the custom token
            await secureStorageService.storeToken(token);
            LocalStorage.setLogin('y');
            print("Custom Token: $token");

            // Navigate to the home page on successful verification
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            // Show an error if token generation failed
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to verify OTP')),
            );
          }
        } else {
          // If ID token is null, handle the failure
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to generate ID token')),
          );
        }
      } catch (e) {
        // Log the error for debugging
        print("Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } else {
      // Handle empty OTP input
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Enter phone number',
                prefixText: '+91 ',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleLogin,
              child: const Text('Generate OTP'),
            ),
            if (otpVisible) ...[
              const SizedBox(height: 20),
              Text(
                'OTP: $generatedOTP', // Display the received OTP
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Enter OTP'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _verifyOTP, // You will define _verifyOTP later
                child: const Text('Verify OTP and Login'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
