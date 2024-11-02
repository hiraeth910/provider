import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telemoni/screens/home.dart';
import 'package:telemoni/screens/wallet.dart';
import 'package:telemoni/utils/api_service.dart';
import 'package:telemoni/utils/secure_storage_service.dart';
import 'package:telemoni/utils/themeprovider.dart';
final GlobalKey<NavigatorState> notificationNavigatorKey =
    GlobalKey<NavigatorState>();
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This handler is called when the app is in the background or terminated.
  await Firebase.initializeApp();
  _handleNotification(message);
}

void _handleNotification(RemoteMessage message) async {
  SecureStorageService secureStorageService = SecureStorageService();

  // Check if the notification is for updating the JWT token
  if (message.data.containsKey('new_jwt_token')) {
    String newJwtToken = message.data['new_jwt_token'];
    // Update the JWT token in secure storage
    await secureStorageService.storeToken(newJwtToken);
    print("JWT token updated from notification!");
  }

  // Check if the notification is a transactional message (e.g., withdrawal)
  if (message.data.containsKey('transaction_type') &&
      message.data['transaction_type'] == 'withdrawal') {
    // Navigate to WithdrawalPage
    // This requires a Navigator context. Use a global key for the navigator if needed.
    notificationNavigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => WithdrawalPage()),
    );
    print("Navigated to WithdrawalPage from notification!");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission to show notifications (iOS specific)
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission for notifications');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission for notifications');
  } else {
    print('User declined or has not accepted permission for notifications');
  }

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Set up notification tap functionality for when the app is opened from a notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotification(message);
  });

  // Check for existing JWT token to determine the initial route
  String? jwtToken = await SecureStorageService().getToken();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(initialRoute: jwtToken == null ? '/login' : '/home'),
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
        //generatedOTP = await apiService.generateOTP(_phoneController.text);
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
          if(idToken!=null){

          String? serverToken =
              await apiService.verifyOTP(idToken, phoneNumber,fcmToken);

          if (serverToken != null) {
            // Store server token in secure storage and proceed
            await secureStorageService.storeToken(serverToken);
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
              Text(
                'OTP: $generatedOTP',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
