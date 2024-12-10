import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:telemoni/models/bank.dart';
import 'package:telemoni/models/product.dart';
import 'package:telemoni/models/transaction.dart';
import 'package:telemoni/utils/endpoints.dart';
import 'package:telemoni/utils/secure_storage_service.dart';

class ApiService {
  // Create a private static instance of the class
  static final ApiService _instance = ApiService._internal();

  // The HTTP client used throughout the app
  final http.Client _client = http.Client();

  // Private constructor to restrict external instantiation
  ApiService._internal();

  // Factory constructor that returns the singleton instance
  factory ApiService() {
    return _instance;
  }
  final SecureStorageService secureStorageService = SecureStorageService();
  static String? _token;

  // Method to get the token, either from memory or secure storage if not set
  Future<String?> getTokyo() async {
    _token = await secureStorageService.getToken();
    return _token;
  }

  Future<String?> generateOTP(String phoneNumber) async {
    print('otpgen');
    String? token = await getTokyo();
    print('token:$token');
    final response = await _client.post(
      Uri.parse(Endpoints.generateOTP), // Use baseUrl here

      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({'number': phoneNumber}),
    );
    print(json.encode({'number': phoneNumber}));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // return data['otp']; // Adjust according to your API response
    } else {
      print(response.body);
    }
  }

  Future<String?> verifyOTP(
      String idToken, String phone, String fcmtoken) async {
    final response = await _client.post(
      Uri.parse(Endpoints.verifyOtp),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({'idToken': idToken, 'phone': phone, 'fcm': fcmtoken}),
    );
    //print(json.encode({'number': phoneNumber, 'otp': otp}),);
    print(response.body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['token']; // Assuming the token is under 'token'

      // Store the token securely
      await secureStorageService.storeToken(token);

      return token;
    } else {
      throw Exception('Failed to verify OTP');
    }
  }

  Future<void> submitPanDetails(Map<String, dynamic> panData) async {
    String? token = await getTokyo(); // Get token from memory or secure storage
    if (token == null) {
      throw Exception('Token is null. Please login again.');
    }
    print(token);
    final response = await _client.post(
      Uri.parse(Endpoints.addPan),
      headers: {
        'authorization': token,
        'Content-Type': 'application/json',
      },
      body: json.encode(panData),
    );

    if (response.statusCode == 200) {
      print('Details submitted successfully');
    } else {
      print('Failed to submit details: ${response.reasonPhrase}');
    }
  }

  Future<void> submitBankDetails(Map<String, dynamic> bankData) async {
    String? token = await getTokyo(); // Get token from memory or secure storage
    if (token == null) {
      throw Exception('Token is null. Please login again.');
    }

    final response = await _client.post(
      Uri.parse(Endpoints.addProviderBank),
      headers: {
        'authorization': token,
        'Content-Type': 'application/json',
      },
      body: json.encode(bankData),
    );

    if (response.statusCode == 200) {
      print('Bank Details submitted successfully');
    } else {
      print('Failed to submit details: ${response.body}');
    }
  }

  Future<http.Response> createProduct(Map<String, dynamic> create) async {
    String? token = await getTokyo(); // Get token from memory or secure storage
    if (token == null) {
      throw Exception('Token is null. Please login again.');
    }

    final response = await _client.post(
      Uri.parse(Endpoints.createProduct),
      headers: {
        'authorization': token,
        'Content-Type': 'application/json',
      },
      body: json.encode(create),
    );

    print(json.encode(create));

    if (response.statusCode == 201) {
      print('Details submitted successfully');
    } else {
      print('Failed to submit details: ${response.body}');
    }

    return response; // Return the response
  }

  Future<List<BankDetails>> getBankAccounts() async {
    String? token = await getTokyo(); // Get token from memory or secure storage
    if (token == null) {
      throw Exception('Token is null. Please login again.');
    }

    final response = await _client.get(
      Uri.parse(Endpoints.getBankAccounts),
      headers: {
        'authorization': token,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // Parse the response into a list of bank details
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((data) => BankDetails.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load bank accounts: ${response.reasonPhrase}');
    }
  }

  Future<List<Product>> getProducts(int id) async {
    String? token = await getTokyo(); // Get token from memory or secure storage
    if (token == null) {
      throw Exception('Token is null. Please login again.');
    }
    final response = await _client.get(
      Uri.parse('${Endpoints.getProducts}$id'),
      headers: {
        'authorization': token,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // Parse the JSON data into a list of products
      List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load products: ${response.reasonPhrase}');
    }
  }

  Future<ResponseModel> deleteBankAccount(String textId) async {
    String? token = await getTokyo(); // Get token from memory or secure storage
    if (token == null) {
      throw Exception('Token is null. Please login again.');
    }
    final response = await http.delete(
      Uri.parse(Endpoints.deleteBankAccount), // Include textId in the URL
      headers: {
        'authorization': token,
        'Content-Type': 'application/json',
      },
      body: json.encode({'id': textId}),
    );

    if (response.statusCode == 200) {
      return ResponseModel.fromJson(json.decode(response.body));
    } else {
      throw Exception(response.body);
    }
  }

  Future<void> raiseWithdrawal(Map<String, dynamic> request) async {
    String? token = await getTokyo(); // Get token from memory or secure storage
    if (token == null) {
      throw Exception('Token is null. Please login again.');
    }
    try {
      final response = await http.post(
        Uri.parse(Endpoints.raiseWithdrawal),
        headers: {
          "Content-Type": "application/json",
          'authorization': token,
        },
        body: json.encode(request
            // "bank_id": bankId,
            // "amount": amount,
            ),
      );
      print(json.encode(request));
      if (response.statusCode == 201) {
        print('Details submitted successfully');
      } else {
        print('Failed to submit details: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Withdrawal history API
  Future<List<Transaction>> getWithdrawalHistory(int id) async {
    String? token = await getTokyo(); // Get token from memory or secure storage
    if (token == null) {
      throw Exception('Token is null. Please login again.');
    }
    try {
      final response = await http.get(
        Uri.parse('${Endpoints.withdrawalHistory}$id'),
        headers: {
          'authorization': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((item) => Transaction.fromJson(item)).toList();
      } else {
        throw Exception('Failed to fetch withdrawal history');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Balance> getBalance() async {
    String? token = await getTokyo();
    if (token == null) {
      throw Exception('Token is null. Please login again.');
    }
    try {
      final response = await http.get(
        Uri.parse(Endpoints.getWalletBalance),
        headers: {
          'authorization': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonData = jsonDecode(response.body);
        return Balance.fromJson(jsonData); // Parse to Balance model
      } else {
        throw Exception('Failed to fetch balance');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<EarningsTrans>> getEarningsTransactions(int id) async {
    String? token = await getTokyo(); // Get token from memory or secure storage
    if (token == null) {
      throw Exception('Token is null. Please login again.');
    }
    try {
      final response = await http.get(
        Uri.parse('${Endpoints.getEarningsTransactions}$id'),
        headers: {
          'authorization': token,
          'Content-Type': 'application/json',
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((item) => EarningsTrans.fromJson(item)).toList();
      } else {
        throw Exception('Failed to fetch withdrawal history');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Pan> getPanVerfication() async {
    String? token = await getTokyo(); // Get token from memory or secure storage
    if (token == null) {
      throw Exception('Token is null. Please login again.');
    }
    try {
      final response = await http.get(
        Uri.parse(Endpoints.panVericationStatus),
        headers: {
          'authorization': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonData = jsonDecode(response.body);
        return Pan.fromJson(jsonData); // Parse to Balance model
      } else {
        throw Exception('Failed to fetch Status');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
