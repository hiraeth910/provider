import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telemoni/models/product.dart';
import 'package:telemoni/screens/aboutproduct.dart';
import 'package:telemoni/utils/api_service.dart';
import 'package:telemoni/utils/themeprovider.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
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
        products.addAll(fetchedProducts);
        isLoading = false;
        currentPage++;

        // Check if fetchedProducts is empty to determine end of list
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
    // Trigger loading more only if we have enough products to enable scrolling
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        products.length >= 5) {
      _fetchProducts();
    }
  }

  // Method to get the correct image asset based on the product type
  String getImageAsset(String type) {
    switch (type) {
      case 'telegram':
        return 'assets/telegram.png';
      case 'zoom':
        return 'assets/zoom.png';
      case 'message':
        return 'assets/lock.png';
      default:
        return 'assets/profile.png';
    }
  }

  // Method to get a random color for the avatar background
  Color getRandomColor(CustomColorScheme colors) {
    final List<Color> possibleColors = [
      colors.customRed,
      colors.customGreen,
      colors.customGrey,
    ];
    return possibleColors[Random().nextInt(possibleColors.length)];
  }

  // Method to handle card tap
  void onCardTap(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AboutProductWidget(product: product),
      ),
    );
  }

 @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).customColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Page'),
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
            // Avatar and image
            Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.03),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: screenWidth * 0.03),
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
                  Positioned(
                    bottom: screenHeight * 0.0015,
                    child: Image.asset(
                      getImageAsset(product.type),
                      height: screenHeight * 0.035,
                      width: screenHeight * 0.035,
                    ),
                  ),
                ],
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
            // Product status
            Container(
              margin: EdgeInsets.only(right: screenWidth * 0.05),
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.005,
                horizontal: screenWidth * 0.02,
              ),
              decoration: BoxDecoration(
                color: getStatusBackgroundColor(product.status, colors),
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                border: Border.all(
                  color: getStatusBorderColor(product.status, colors),
                ),
              ),
              child: Text(
                product.status,
                style: TextStyle(
                  color: getStatusTextColor(product.status, colors),
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.035,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color getStatusBackgroundColor(String status, CustomColorScheme colors) {
    switch (status) {
      case 'pending':
        return Provider.of<ThemeProvider>(context, listen: false).isDarkMode
            ? colors.customYellow.withOpacity(0.1)
            : colors.customBlue.withOpacity(0.1);
      case 'active':
        return colors.customGreen.withOpacity(0.1);
      case 'inactive':
        return colors.customRed.withOpacity(0.1);
      default:
        return colors.customGrey;
    }
  }

  Color getStatusTextColor(String status, CustomColorScheme colors) {
    switch (status) {
      case 'pending':
        return Provider.of<ThemeProvider>(context, listen: false).isDarkMode
            ? colors.customYellow
            : colors.customBlue;
      case 'active':
        return Provider.of<ThemeProvider>(context, listen: false).isDarkMode?Colors.green[900]!: Colors.greenAccent;
      case 'inactive':
        return colors.customRed;
      default:
        return colors.textColor;
    }
  }

  Color getStatusBorderColor(String status, CustomColorScheme colors) {
    switch (status) {
      case 'pending':
        return Provider.of<ThemeProvider>(context, listen: false).isDarkMode
            ? colors.customYellow
            : colors.customBlue;
      case 'active':
        return Provider.of<ThemeProvider>(context, listen: false).isDarkMode
            ? Colors.green[900]!
            : Colors.greenAccent;
      case 'inactive':
        return colors.customRed;
      default:
        return colors.customGrey;
    }
  }
}
