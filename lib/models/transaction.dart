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
