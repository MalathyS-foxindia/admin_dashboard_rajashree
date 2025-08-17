// models/product_model.dart

class Variant {
  final String? id;
  String name;
  String sku;
  double salePrice;
  double regularPrice;
  double weight;
  String color;
  String? imageUrl;

  Variant({
    this.id,
    required this.name,
    required this.sku,
    required this.salePrice,
    required this.regularPrice,
    required this.weight,
    required this.color,
    this.imageUrl,
  });

  factory Variant.fromJson(Map<String, dynamic> json) => Variant(
        id: json['variant_id']?.toString(),
        name: json['variant_name'],
        sku: json['sku'],
        salePrice: (json['saleprice'] ?? 0).toDouble(),
        regularPrice: (json['regularprice'] ?? 0).toDouble(),
        weight: (json['weight'] ?? 0).toDouble(),
        color: json['color'] ?? '',
        imageUrl: json['image_url'],
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'variant_id': id,
        'variant_name': name,
        'sku': sku,
        'saleprice': salePrice,
        'regularprice': regularPrice,
        'weight': weight,
        'color': color,
        if (imageUrl != null) 'image_url': imageUrl,
      };
}

class Product {
  final String? id;
  String name;
  String description;
  String sku;
  String category;
  bool hasVariant;
  double? salePrice;
  double? regularPrice;
  double? weight;
  String? imageUrl;
  List<Variant>? variants;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.sku,
    required this.category,
    required this.hasVariant,
    required this.salePrice,
    required this.regularPrice,
    this.weight,
    this.imageUrl,
    this.variants,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
     final variantsJson = json['variants'] as List<dynamic>? ?? [];
  final List<Variant> variantsList = variantsJson
      .map((v) => Variant.fromJson(v as Map<String, dynamic>))
      .toList();

    // If product itself has no price, take from first variant
    double salePrice = (json['saleprice'] ?? 0).toDouble();
    double regularPrice = (json['regularprice'] ?? 0).toDouble();
    double weight = (json['weight'] ?? 0).toDouble();

    if ((salePrice == 0 || regularPrice == 0|| weight ==0) && variantsList.isNotEmpty) {
      salePrice = variantsList.first.salePrice;
      regularPrice = variantsList.first.regularPrice;
      weight = variantsList.first.weight;
    }

    return Product(
      id: json['product_id']?.toString(),
      name: json['name'],
      description: json['description'],
      sku: json['sku'],
      category: json['category'],
      hasVariant: json['has_variant'] ?? false,
      salePrice: salePrice,
      regularPrice: regularPrice,
      weight: weight,
      imageUrl: json['image_url'],
      variants: variantsList,
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      if (id != null) 'product_id': id,
      'name': name,
      'description': description,
      'sku': sku,
      'category': category,
      'has_variant': hasVariant,
      'saleprice': salePrice,
      'regularprice': regularPrice,
      if (weight != null) 'weight': weight,
      if (imageUrl != null) 'image_url': imageUrl,
    };

    if (hasVariant) {
      data['variants'] = variants?.map((v) => v.toJson()).toList() ?? [];
    }

    return data;
  }
}
