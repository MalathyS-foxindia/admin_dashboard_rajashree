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
    this.imageUrl
  });

  factory Variant.fromJson(Map<String, dynamic> json) => Variant(
    id: json['variant_id']?.toString(),
    name: json['variant_name'],
    sku: json['sku'],
    salePrice: (json['saleprice'] ?? 0).toDouble(),
    regularPrice: (json['regularprice'] ?? 0).toDouble(),
    weight: (json['weight'] ?? 0).toDouble(),
    color: json['color'] ?? '',
    imageUrl: json['image_url'] ?? null,
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
  String? image_url; // Added for image URL
  List<Variant>? variants;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.sku,
    required this.category,
    required this.hasVariant,
    this.salePrice,
    this.regularPrice,
    this.weight,
    this.image_url,
    this.variants,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['product_id']?.toString(),
    name: json['name'],
    description: json['description'],
    sku: json['sku'],
    category: json['category'],
    hasVariant: json['has_variant'],
    salePrice: json['saleprice']?.toDouble(),
    regularPrice: json['regularprice']?.toDouble(),
    weight: json['weight']?.toDouble(),
    image_url: json['image_url'],
    variants: json['variants'] != null
        ? (json['variants'] as List)
            .map((v) => Variant.fromJson(v))
            .toList()
        : [],
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'product_id': id,
    'name': name,
    'description': description,
    'sku': sku,
    'category': category,
    'has_variant': hasVariant,
    if (!hasVariant) ...{
      'saleprice': salePrice,
      'regularprice': regularPrice,
      'weight': weight,
    },
    if (image_url != null) 'image_url': image_url,
    if (hasVariant) 'variants': variants?.map((v) => v.toJson()).toList(),
  };
}
