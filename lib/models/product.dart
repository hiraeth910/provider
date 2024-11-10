// Product model class
class Product {
  final int productId;
  final String about;
  final double earning;
  final int subs;
  final String status;
  final String type;
  final bool? channel;
  final String name;
  final String? link;
  final int price;
  final String? joininglink;
  Product(
      {required this.productId,
      required this.about,
      required this.earning,
      required this.subs,
      required this.status,
      required this.type,
      required this.price,
      this.channel,
      this.link,
      this.joininglink,
      required this.name});

  // Factory method to create a Product object from JSON data
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
        productId: json['product_id'],
        about: json['about'],
        earning: json['earning'].toDouble(),
        subs: json['subs'],
        status: json['status'],
        type: json['type'],
        channel: json['channel'],
        link: json['link'],
        price: json['price'],
        joininglink: json['joininglink'],
        name: json['name']);
  }

  // Method to convert a Product object to JSON data
  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'about': about,
      'earning': earning,
      'subs': subs,
      'status': status,
      'type': type,
      'channel': channel,
      'name': name
    };
  }
}

// Function to parse a list of products from JSON data
List<Product> parseProductsList(List<dynamic> jsonList) {
  return jsonList.map((json) => Product.fromJson(json)).toList();
}

class ResponseModel {
  final bool success;
  final String message;

  ResponseModel({required this.success, required this.message});

  factory ResponseModel.fromJson(Map<String, dynamic> json) {
    return ResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}
