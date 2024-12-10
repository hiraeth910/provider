import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:telemoni/models/product.dart';
import 'package:telemoni/models/transaction.dart';
import 'package:telemoni/utils/api_service.dart';

class EarningsTransactions extends StatefulWidget {
  final Product product;

  EarningsTransactions({required this.product});

  @override
  _EarningsTransactionsState createState() => _EarningsTransactionsState();
}

class _EarningsTransactionsState extends State<EarningsTransactions> {
  List<EarningsTrans> transactions = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final fetchedTransactions =
          await ApiService().getEarningsTransactions(widget.product.productId);
      setState(() {
        transactions = fetchedTransactions;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.product.name} Transactions'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Failed to load transactions.'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _fetchTransactions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : transactions.isEmpty
                  ? const Center(child: Text('No transactions found.'))
                  : ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        // final purchaseTime = DateFormat('yyyy-MM-dd – kk:mm').format(
                        //   DateTime.parse(transaction.purchaseTime as String),
                        // );

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Buyer: ${transaction.buyerName}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                    'Amount: \$${(transaction.amount * 0.91).round()}'),
                                Text(
                                    'Purchased on: ${transaction.purchaseTime}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
