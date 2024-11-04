class Transaction {
  final String status;
  final int amount;
  final String bankName;
  final String transactionId;
  final int id;
  final String formattedDate;

  Transaction({
    required this.status,
    required this.amount,
    required this.bankName,
    required this.transactionId,
    required this.id,
    required this.formattedDate,
  });

  // Custom method to parse and format the timestamp
static String formatDateTime(String timestamp) {
  try {
    DateTime parsedDate = DateTime.parse(timestamp).toUtc();
    
    // Convert to IST (UTC +5:30)
    DateTime istDate = parsedDate.add(Duration(hours: 5, minutes: 30));
    
    // Extract date components
    int day = istDate.day;
    String month = _getMonthAbbreviation(istDate.month);
    int year = istDate.year;
    
    // Extract time components
    int hour = istDate.hour;
    int minute = istDate.minute;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12 == 0 ? 12 : hour % 12; // Convert to 12-hour format

    return '$day-$month-$year ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  } catch (e) {
    // Fallback for any parsing issues
    return 'Unknown Date';
  }
}

  // Helper method to get month abbreviation
  static String _getMonthAbbreviation(int month) {
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      status: json['status'] ?? 'Unknown',
      amount: json['withdrawl_amount'] ?? 0,
      bankName: json['acno'] ?? 'Unknown Bank',
      transactionId: json['transactionid'] ?? 'N/A',
      id: json['id'] ?? 0,
      formattedDate: formatDateTime(json['tmstmp'] ?? ''),
    );
  }
}

class Balance {
  final double balance;
  final bool req;

  Balance({required this.balance, required this.req});

  factory Balance.fromJson(Map<String, dynamic> json) {
    return Balance(
      balance: json['balance'],
      req: json['req'],
    );
  }
}

class EarningsTrans {
  final int amount;
  final String buyerName;
  final String purchaseTime;

  EarningsTrans({
    required this.amount,
    required this.buyerName,
    required this.purchaseTime,
  });

  // Factory constructor to parse JSON
  factory EarningsTrans.fromJson(Map<String, dynamic> json) {
    return EarningsTrans(
      amount: json['amount'],
      buyerName: json['buyer_name'],
      purchaseTime: formatDateTime(json['purchase_time']),
    );
  }

  // Custom date formatting method
  static String formatDateTime(String timestamp) {
  try {
    DateTime parsedDate = DateTime.parse(timestamp).toUtc();
    
    // Convert to IST (UTC +5:30)
    DateTime istDate = parsedDate.add(Duration(hours: 5, minutes: 30));
    
    // Extract date components
    int day = istDate.day;
    String month = _getMonthAbbreviation(istDate.month);
    int year = istDate.year;
    
    // Extract time components
    int hour = istDate.hour;
    int minute = istDate.minute;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12 == 0 ? 12 : hour % 12; // Convert to 12-hour format

    return '$day-$month-$year ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  } catch (e) {
    // Fallback for any parsing issues
    return 'Unknown Date';
  }
}

  // Helper method to get month abbreviation
  static String _getMonthAbbreviation(int month) {
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

}

class Pan {
  final String status;
  final String? providerName;

  Pan({required this.providerName, required this.status});

  factory Pan.fromJson(Map<String, dynamic> json) {
    return Pan(
      status: json['status'],
      providerName: json['providerName'] ?? '',
    );
  }
}



