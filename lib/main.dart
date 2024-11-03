import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telemoni/screens/home.dart';
import 'package:telemoni/utils/api_service.dart';
import 'package:telemoni/utils/localstorage.dart';
import 'package:telemoni/utils/notifications.dart';
import 'package:telemoni/utils/secure_storage_service.dart';
import 'package:telemoni/utils/themeprovider.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Set up the background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize NotificationService
  NotificationService notificationService = NotificationService();
  await notificationService.initialize();

  // Check for an existing JWT token to determine the initial route
  String? jwtToken = await SecureStorageService().getToken();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(
        initialRoute: jwtToken == null ? '/login' : '/home',
      ),
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

// Handle notification clicks
void _handleNotificationClick(RemoteMessage message) {
  // Extract data from the notification payload
  if (message.data.isNotEmpty) {
    // Perform any specific actions based on the notification data
    print("Notification clicked with data: ${message.data}");
    // Example: navigate to a specific screen or perform an action
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
        generatedOTP = await apiService.generateOTP(_phoneController.text);
        FirebaseAuth.instance.verifyPhoneNumber(
          verificationCompleted: (PhoneAuthCredential credential) {
            print("Verification completed: $credential");
          },
          verificationFailed: (FirebaseAuthException error) {
            print("Verification failed: $error");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${error.message}')),
            );
          },
          codeSent: (verificationId, forceResendingToken) {
            verify = verificationId;
          },
          codeAutoRetrievalTimeout: (verificationId) {
            print('Auto-retrieval timeout');
          },
          phoneNumber: phoneNumber,
        );

        setState(() {
          otpVisible = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent to your phone')),
        );
      } catch (e) {
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

  // Function to handle OTP verification and generate FCM token after authentication
  Future<void> _verifyOTP() async {
    String enteredOTP = _otpController.text;
    String phoneNumber = _phoneController.text;
    print(enteredOTP);

    if (enteredOTP.isNotEmpty && phoneNumber.isNotEmpty) {
      try {
        // Verify OTP and get UserCredential
        final cred = PhoneAuthProvider.credential(
            verificationId: verify, smsCode: enteredOTP);
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(cred);

        // Generate FCM Token
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          print("Generated FCM Token: $fcmToken");

          // Send FCM token and other user info to your server
          String? idToken = await userCredential.user?.getIdToken();
          if (idToken != null) {
            String? serverToken =
                await apiService.verifyOTP(idToken, phoneNumber, fcmToken);

            if (serverToken != null) {
              await secureStorageService.storeToken(serverToken);
              final jwt = JWT.decode(serverToken);
              await setUserRole(serverToken);
              Navigator.pushReplacementNamed(context, '/home');
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to verify OTP')),
            );
          }
        } else {
          print('Failed to generate FCM Token');
        }
      } catch (e) {
        print("Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } else {
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
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Enter OTP'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _verifyOTP,
                child: const Text('Verify OTP and Login'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
