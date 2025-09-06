// models/product_model.dart
class Variant {
  final String? id;
  final String name;
  final String sku;
  final double salePrice;
  final double regularPrice;
  final double weight;
  final String color;
  final double stock;
  final double? length;
  final double? size;
  final String? imageUrl;
  final bool? isActive;

  Variant({
    this.id,
    required this.name,
    required this.sku,
    required this.salePrice,
    required this.regularPrice,
    required this.weight,
    required this.color,
    this.imageUrl,
    this.length,
    this.size,
    this.stock = 0,
    this.isActive,
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
        length: json['length'] != null ? (json['length'] as num).toDouble() : null,
        size: json['size'] != null ? (json['size'] as num).toDouble() : null,
        stock: (json['stock'] ?? 0).toDouble(),
        isActive: json['is_Active'],
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'variant_id': id,
        'variant_name': name,
        'sku': sku,
        'saleprice': salePrice,
        'regularprice': regularPrice,
        'weight': weight,
        'color': color,
        if (stock != null) 'stock': stock,
        if (length != null) 'length': length,
        if (size != null) 'size': size,
        if (imageUrl != null) 'image_url': imageUrl,
        if (isActive != null) 'is_Active': isActive,
      };

  /// ✅ copyWith method for immutability
  Variant copyWith({
    String? id,
    String? name,
    String? sku,
    double? salePrice,
    double? regularPrice,
    double? weight,
    String? color,
    double? stock,
    double? length,
    double? size,
    String? imageUrl,
    bool? isActive,
  }) {
    return Variant(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      salePrice: salePrice ?? this.salePrice,
      regularPrice: regularPrice ?? this.regularPrice,
      weight: weight ?? this.weight,
      color: color ?? this.color,
      stock: stock ?? this.stock,
      length: length ?? this.length,
      size: size ?? this.size,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
    );
  }
}


class Product {
  final String? id;
  String name;
  String description;
  String sku;
  String category;
  bool hasVariant;
  bool? isActive;  

  String? imageUrl;
  List<Variant>? variants;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.sku,
   required this.category,
    required this.hasVariant,
    
    this.imageUrl,
    this.variants,
    this.isActive,
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
      imageUrl: json['image_url'],
      variants: variantsList,
      isActive: json['is_Active'],
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
      if (imageUrl != null) 'image_url': imageUrl,
      if (isActive != null) 'is_Active': isActive,
    };

      data['variants'] = variants?.map((v) => v.toJson()).toList() ?? [];
  

    return data;
  }
}
