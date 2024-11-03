import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telemoni/screens/addproduct.dart';
import 'package:telemoni/screens/getverified.dart';
import 'package:telemoni/screens/products.dart';
import 'package:telemoni/screens/profile.dart';
import 'package:telemoni/utils/themeprovider.dart';
import 'package:telemoni/utils/localstorage.dart'; // Import LocalStorage for user status check

class MainPageContent extends StatefulWidget {
  const MainPageContent({super.key});

  @override
  State<MainPageContent> createState() => _MainPageContentState();
}

class _MainPageContentState extends State<MainPageContent> {
  int _selectedIndex = 0;
  bool _isVerifiedUser = false; // Variable to store verification status

  final List<Widget> _pages = [
    const VerificationScreen(),
    const AddProductPage(),
    const ProductsPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkUserStatus(); // Check the user status on page load
  }

  // Function to check user status
  Future<void> _checkUserStatus() async {
    final userStatus = await LocalStorage.getUser();
    setState(() {
      _isVerifiedUser = userStatus == 'wallet_user'; // Set verification status
    });
  }

  // Function to handle bottom navigation bar tap with verification check
  void _onItemTapped(int index) {
    if (!_isVerifiedUser && index != 0) {
      // Show message if the user is not verified and attempts to navigate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete verification to access this page.')),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDarkMode ? Colors.white : Colors.black;
    final labelColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Telemoni'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: iconColor),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add, color: iconColor),
            label: 'Add Product',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory, color: iconColor),
            label: 'My Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: iconColor),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 111, 63, 193),
        onTap: _onItemTapped,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        unselectedItemColor: iconColor,
        selectedLabelStyle: TextStyle(color: labelColor),
        unselectedLabelStyle: TextStyle(color: labelColor),
      ),
    );
  }
}
