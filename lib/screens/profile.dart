import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telemoni/main.dart';
import 'package:telemoni/screens/banking.dart';
import 'package:telemoni/screens/earnings.dart';
import 'package:telemoni/screens/wallet.dart';
import 'package:telemoni/utils/api_service.dart';
import 'package:telemoni/utils/localstorage.dart';
import 'package:telemoni/utils/secure_storage_service.dart';
import 'package:telemoni/utils/themeprovider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = 'user'; // Default name

  @override
  void initState() {
    super.initState();
    _loadProviderName();
  }

  Future<void> _loadProviderName() async {
    String? savedName = await LocalStorage.getProviderName();
    setState(() {
      name = savedName ?? 'user'; // Fallback to 'user' if no name is saved
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    SecureStorageService secureStorageService = SecureStorageService();
    // Access custom colors from ThemeProvider
    final customColors = Provider.of<ThemeProvider>(context).customColors;

    // Scaling factors
    double paddingScale = screenWidth * 0.04;
    double avatarRadius = screenWidth * 0.08;
    double fontSize = screenWidth * 0.045;
    double cardElevation = screenWidth * 0.01;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(paddingScale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First card with profile picture and greeting
            Card(
              elevation: cardElevation,
              shadowColor: customColors.shadowColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: EdgeInsets.all(paddingScale),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: avatarRadius,
                      backgroundImage: const AssetImage('assets/profile.png'),
                    ),
                    SizedBox(width: paddingScale),
                    Text(
                      'Hello, $name',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: customColors.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: paddingScale),

            // Second card with Wallet and Earnings
            Card(
              elevation: cardElevation,
              shadowColor: customColors.shadowColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: paddingScale,
                  horizontal: paddingScale / 2,
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.account_balance_wallet,
                        color: customColors.iconColor,
                        size: screenWidth * 0.07,
                      ),
                      title: Text(
                        'Wallet',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: customColors.textColor,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WithdrawalPage(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.attach_money,
                        color: customColors.iconColor,
                        size: screenWidth * 0.07,
                      ),
                      title: Text(
                        'Earnings',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: customColors.textColor,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EarningsPage(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.account_balance, // Bank icon
                        color: customColors.iconColor,
                        size: screenWidth * 0.07,
                      ),
                      title: Text(
                        'Bank Accounts',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: customColors.textColor,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Banking(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: paddingScale),

            // Third card with Dashboard, Settings, and Logout
            Card(
              elevation: cardElevation,
              shadowColor: customColors.shadowColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: paddingScale,
                  horizontal: paddingScale / 2,
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.dashboard,
                        color: customColors.iconColor,
                        size: screenWidth * 0.07,
                      ),
                      title: Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: customColors.textColor,
                        ),
                      ),
                      onTap: () {
                        // Navigate to Dashboard
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.settings,
                        color: customColors.iconColor,
                        size: screenWidth * 0.07,
                      ),
                      title: Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: customColors.textColor,
                        ),
                      ),
                      onTap: () {
                        // Navigate to Settings
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.logout,
                        color: customColors.iconColor,
                        size: screenWidth * 0.07,
                      ),
                      title: Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: customColors.textColor,
                        ),
                      ),
                      onTap: () async {
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
                          // Perform logout actions if user confirms
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
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
