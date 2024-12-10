import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:telemoni/main.dart';
import 'package:telemoni/screens/home.dart';
import 'package:telemoni/utils/api_service.dart';
import 'package:telemoni/utils/localstorage.dart';
import 'package:telemoni/utils/secure_storage_service.dart';
import 'package:telemoni/utils/themeprovider.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _panController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final _focusNode = FocusNode();
  File? _selectedImage;
  String? _base64Image;
  bool _isFormVisible = false;
  bool _isPanValid = true;
  String _verificationStatus = ''; // Starts empty
  bool _isImageRequired = false;
  String? _imageError;
  bool buttonLoad = false;

  final ApiService apiService = ApiService();
  final SecureStorageService secureStorageService = SecureStorageService();
  final _panFormat = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
  Timer? _userCheckTimer;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  @override
  void dispose() {
    _panController.dispose();
    _nameController.dispose();
    _focusNode.dispose();
    _userCheckTimer?.cancel();
    super.dispose();
  }

  void _checkVerificationStatus() async {
    // Initial check for user status and verification
    await _verifyUserStatus();

    // If the user is 'provider_user', start a periodic timer to check status every 5 seconds
    _userCheckTimer = Timer.periodic(const Duration(seconds: 100), (timer) async {
      final user = await LocalStorage.getUser();
      if (user == 'wallet_user') {
        // If user has changed to 'wallet_user', cancel the timer and update verification status
        timer.cancel();
        setState(() {
          _verificationStatus = 'verified';
        });
      } else {
        // If still 'provider_user', continue checking verification status from API
        await _verifyUserStatus();
      }
    });
  }

  Future<void> _verifyUserStatus() async {
    final user = await LocalStorage.getUser();
    final name = await LocalStorage.getProviderName();

    if (user == 'wallet_user' && name != null && name.isNotEmpty) {
      // Verified locally as 'wallet_user'
      setState(() {
        _verificationStatus = 'verified';
      });
      return;
    }

    // If not locally verified, check verification status via API
    try {
      final panStatus = await apiService.getPanVerfication();

      if (panStatus.status == 'pending' || panStatus.status == 'verified') {
        if (panStatus.providerName != null) {
          await LocalStorage.setProviderName(panStatus.providerName!);
        }
        // Print token for debugging
      }

      setState(() {
        _verificationStatus = panStatus.status;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching verification status: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
     
        final bytes = await file.readAsBytes(); // Read file as bytes
        final base64Image = base64Encode(bytes); // Convert to Base64

        setState(() {
          _selectedImage =
              file; // Set the selected image (if needed for preview)
          _base64Image = base64Image; // Store the Base64 string
        });
     
    }
  }

  void _validateAndSubmit() async {
    String enteredPan = _panController.text.toUpperCase();
    bool isPanValid = _panFormat.hasMatch(enteredPan);

    setState(() {
      _isPanValid = isPanValid;
    });

    if (isPanValid && _base64Image != null) {
      final panData = {
        'name': _nameController.text,
        'pan': enteredPan,
        'image': _base64Image, // Use the Base64 image string
      };

      print(
          'Name: ${_nameController.text}, PAN: ${_panController.text}, Image (Base64): ${_base64Image}');

      try {
        await apiService
            .submitPanDetails(panData); // Use the ApiService to submit details
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Form Submitted Successfully!')),
        );
        Navigator.pushAndRemoveUntil(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const MainPageContent()),
          (Route<dynamic> route) =>
              route.isFirst, // Ensures back navigation goes to main.dart
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting details: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please enter a valid PAN and upload an image.')),
      );
    }
  }

  int _previousLength = 0; // Track the previous input length

  void _onPanChanged(String value) {
    String newValue = value.toUpperCase();

    // Limit the length of the input to 10 characters
    if (newValue.length > 10) {
      newValue = newValue.substring(0, 10);
    }

    // Determine the new input length
    int newLength = newValue.length;

    // Check for keyboard type changes based on length
    if (_previousLength == 4 && newLength == 5) {
      // From 4 to 5, switch to number keyboard
      _focusNode.unfocus();
      Future.delayed(Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(_focusNode);
        SystemChannels.textInput
            .invokeMethod('TextInput.setClient', [null, TextInputType.number]);
      });
    } else if (_previousLength == 5 && newLength == 4) {
      // From 5 to 4, switch to text keyboard
      _focusNode.unfocus();
      Future.delayed(Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(_focusNode);
        SystemChannels.textInput
            .invokeMethod('TextInput.setClient', [null, TextInputType.text]);
      });
    } else if (_previousLength == 8 && newLength == 9) {
      // From 8 to 9, switch to text keyboard
      _focusNode.unfocus();
      Future.delayed(Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(_focusNode);
        SystemChannels.textInput
            .invokeMethod('TextInput.setClient', [null, TextInputType.text]);
      });
    } else if (_previousLength == 9 && newLength == 8) {
      // From 9 to 10, switch to number keyboard
      _focusNode.unfocus();
      Future.delayed(Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(_focusNode);
        SystemChannels.textInput
            .invokeMethod('TextInput.setClient', [null, TextInputType.number]);
      });
    }

    // Update the text field with the uppercase value
    _panController.value = TextEditingValue(
      text: newValue,
      selection: TextSelection.fromPosition(
        TextPosition(offset: newValue.length),
      ),
    );

    // Update the previous length
    _previousLength = newLength;

    setState(() {
      _isPanValid = true; // Reset validation state when input changes
    });
  }

  Future<void> _logout() async {
    LocalStorage.removeLogin();
    secureStorageService.deleteToken();
    LocalStorage.removeUser();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final customColors = themeProvider.customColors;
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: themeProvider.themeData.colorScheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_verificationStatus.isEmpty)
                CircularProgressIndicator(color: customColors.customGrey)
              else if (_verificationStatus == 'verified')
                Text(
                  'You are verified',
                  style: TextStyle(
                    color: customColors.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (_verificationStatus == 'pending')
                Column(
                  children: [
                    Image.asset(
                      'assets/clock.png',
                      height: 100,
                      width: 100,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please wait while we verify your details',
                      style: TextStyle(
                        color: customColors.textColor,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Button to print token
                    ElevatedButton(
                      onPressed: () async {
                        bool? confirmLogout = await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirm Logout'),
                              content: const Text(
                                  'Are you sure you want to logout?'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('No'),
                                  onPressed: () {
                                    Navigator.of(context).pop(
                                        false); // Close dialog and return false
                                  },
                                ),
                                TextButton(
                                  child: const Text('Yes'),
                                  onPressed: () {
                                    Navigator.of(context).pop(
                                        true); // Close dialog and return true
                                  },
                                ),
                              ],
                            );
                          },
                        );

                        if (confirmLogout == true) {
                          await _logout(); // Call the logout function if user confirms
                        }
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Text(
                      !_isFormVisible
                          ? 'You are not verified'
                          : 'Complete the form to get verified',
                      style: TextStyle(
                        color: customColors.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!_isFormVisible)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: Image.asset(
                          'assets/404.jpg',
                          width: MediaQuery.of(context).size.width * .9,
                        ),
                      ),
                    const SizedBox(height: 30),
                    if (_isFormVisible)
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Name input field
                              TextField(
                                controller:
                                    _nameController, // Add a controller for the name input
                                decoration: InputDecoration(
                                  labelText: 'Enter Name as per PAN',
                                  labelStyle:
                                      TextStyle(color: customColors.textColor),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: customColors.textColor),
                                  ),
                                ),
                                style: TextStyle(color: customColors.textColor),
                              ),
                              const SizedBox(height: 16),

                              // PAN input field
                              TextField(
                                controller: _panController,
                                focusNode: _focusNode,
                                onChanged: _onPanChanged,
                                keyboardType: _panController.text.length >= 5 &&
                                        _panController.text.length < 9
                                    ? TextInputType.number
                                    : TextInputType.text,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z0-9]'),
                                  ),
                                ],
                                maxLength: 10,
                                decoration: InputDecoration(
                                  labelText: 'Enter your PAN',
                                  errorText: _isPanValid ? null : 'Invalid PAN',
                                  labelStyle:
                                      TextStyle(color: customColors.textColor),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: customColors.textColor),
                                  ),
                                ),
                                style: TextStyle(color: customColors.textColor),
                              ),
                              const SizedBox(height: 16),
                              Column(
                                children: [
                                  if (_selectedImage != null)
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Image.file(
                                        _selectedImage!,
                                        height: 100,
                                        width: 100,
                                      ),
                                    ),
                                  ElevatedButton(
                                    onPressed: _pickImage,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: customColors.customBlue,
                                    ),
                                    child: Text(
                                      'Pan Image',
                                      style: TextStyle(
                                          color: customColors.textColor),
                                    ),
                                  ),
                                  if (_isImageRequired &&
                                      _selectedImage == null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        _imageError ??
                                            'We need your PAN to verify your details', // Show the error if present
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_isFormVisible) {
                          _validateAndSubmit();
                          setState(() {
                            buttonLoad = true;
                            _isImageRequired = _selectedImage ==
                                null; // Show error if image is not selected
                          });
                        } else {
                          setState(() {
                            _isFormVisible = true;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormVisible
                            ? themeProvider.isDarkMode
                                ? Colors.green[900]
                                : Colors.greenAccent
                            : themeProvider.isDarkMode
                                ? Colors.red[900]
                                : Colors.redAccent,
                        padding: EdgeInsets.symmetric(
                          horizontal: mediaQuery.size.width * 0.2,
                          vertical: mediaQuery.size.height * 0.016,
                        ),
                      ),
                      child: _isFormVisible
                          ? (buttonLoad
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('Submit'))
                          : const Text('Get Verified'),

                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
