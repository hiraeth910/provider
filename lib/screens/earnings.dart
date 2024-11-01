import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telemoni/models/product.dart';
import 'package:telemoni/screens/earningstransactions.dart';
import 'package:telemoni/utils/api_service.dart';
import 'package:telemoni/utils/themeprovider.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  _EarningsPageState createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  List<Product> products = [];
  bool isLoading = true;
  int currentPage = 1;
  bool hasMoreProducts = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchProducts() async {
    if (!hasMoreProducts) return;

    setState(() {
      isLoading = true;
    });

    try {
      final fetchedProducts = await ApiService().getProducts(currentPage);
      setState(() {
        // Filter to show only active products
        products.addAll(fetchedProducts.where((product) => product.status == 'active'));
        isLoading = false;
        currentPage++;
        hasMoreProducts = fetchedProducts.isNotEmpty;
      });
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        products.length >= 5) {
      _fetchProducts();
    }
  }

  void onCardTap(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EarningsTransactions(product: product),
      ),
    );
  }

  Color getRandomColor(CustomColorScheme colors) {
    final List<Color> possibleColors = [
      colors.customRed,
      colors.customGreen,
      colors.customGrey,
    ];
    return possibleColors[Random().nextInt(possibleColors.length)];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).customColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Earnings'),
      ),
      body: products.isEmpty && isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              controller: _scrollController,
              itemCount: products.length + (hasMoreProducts && products.length >= 6 ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == products.length) {
                  return const Center(child: CircularProgressIndicator());
                }

                final product = products[index];
                final backgroundColor = getRandomColor(colors);
                return GestureDetector(
                  onTap: () => onCardTap(product),
                  child: _buildProductCard(product, backgroundColor, colors),
                );
              },
            ),
    );
  }

  Widget _buildProductCard(Product product, Color backgroundColor, CustomColorScheme colors) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      child: SizedBox(
        height: screenHeight * 0.146,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.03),
              child: CircleAvatar(
                radius: screenHeight * 0.04,
                backgroundColor: backgroundColor,
                child: Text(
                  product.name[0].toUpperCase(),
                  style: TextStyle(
                    color: colors.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.05,
                  ),
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Text(
                product.name,
                style: TextStyle(
                  color: colors.textColor,
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Display earnings instead of status
            Container(
              margin: EdgeInsets.only(right: screenWidth * 0.05),
              child: Text(
                '\$${product.earning.toStringAsFixed(2)}',
                style: TextStyle(
                  color: colors.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.045,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
