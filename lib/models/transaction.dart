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
      DateTime parsedDate = DateTime.parse(timestamp);
      
      // Extract date components
      int day = parsedDate.day;
      String month = _getMonthAbbreviation(parsedDate.month);
      int year = parsedDate.year;
      
      // Extract time components
      int hour = parsedDate.hour;
      int minute = parsedDate.minute;
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
  final int balance;
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
  final DateTime purchaseTime;

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
      purchaseTime: DateTime.parse(json['purchase_time']),
    );
  }

  // Custom date formatting method
  String get formattedPurchaseTime {
    return _formatDate(purchaseTime);
  }

  // Method to format DateTime to 'yyyy-MM-dd – HH:mm'
  String _formatDate(DateTime dateTime) {
    String year = dateTime.year.toString();
    String month = dateTime.month.toString().padLeft(2, '0');  // Ensures two-digit month
    String day = dateTime.day.toString().padLeft(2, '0');      // Ensures two-digit day
    String hour = dateTime.hour.toString().padLeft(2, '0');    // Ensures two-digit hour
    String minute = dateTime.minute.toString().padLeft(2, '0'); // Ensures two-digit minute
    
    return "$year-$month-$day – $hour:$minute";
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



