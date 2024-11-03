import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static SharedPreferences? _preferences;
  static const _providerNameKey = 'providerName';
  static const _userRole = 'userRole';

  // Initialize SharedPreferences
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // Save token (phone number) to shared preferences
  static Future<void> setLogin(String token) async {
    await _preferences?.setString('token', token);
  }

  // Get the stored token (returns null if not found)
  static String? getLogin() {
    return _preferences?.getString('token');
  }

  // Remove the token from shared preferences (for logout)
  static Future<void> removeLogin() async {
    await _preferences?.remove('token');
  }

  static Future<void> setUser(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRole, role);
  }
  static Future<void> removeUser() async {
    await _preferences?.remove('role');
  }
  static Future<String?> getUser() async{
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRole);
  }

  static Future<void> setProviderName(String providerName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerNameKey, providerName);
  }

  static Future<String?> getProviderName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_providerNameKey);
  }

  static Future<void> removeProviderName() async {
    await _preferences?.remove('name');
  }
 
}