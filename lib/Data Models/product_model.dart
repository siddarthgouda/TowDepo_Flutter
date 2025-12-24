import '../config/app_config.dart';

String extractMongoId(dynamic raw) {
  if (raw == null) return '';

  if (raw is String && raw.isNotEmpty) return raw;

  if (raw is Map) {
    // common mongo export { "$oid": "..." }
    if (raw.containsKey('\$oid')) {
      final oid = raw['\$oid'];
      if (oid is String && oid.isNotEmpty) return oid;
    }
    // sometimes object contains 'id'
    if (raw.containsKey('id')) {
      final idv = raw['id'];
      if (idv is String && idv.isNotEmpty) return idv;
    }
  }

  return '';
}

/// Search for product id in several likely places inside a product JSON
String findProductId(Map<String, dynamic> json) {
  // 1) explicit id
  if (json['id'] is String && (json['id'] as String).isNotEmpty) {
    return json['id'] as String;
  }

  // 2) _id or _id.$oid
  final fromUnderscore = extractMongoId(json['_id']);
  if (fromUnderscore.isNotEmpty) return fromUnderscore;

  // 3) some APIs put productId inside variant attributes
  try {
    if (json['variant'] is List) {
      for (final v in json['variant']) {
        if (v is Map) {
          // 3a) variant itself may have id
          final vid = extractMongoId(v['_id'] ?? v['id']);
          if (vid.isNotEmpty) return vid;

          // 3b) attributes array with name: productId or key productId
          if (v['attributes'] is List) {
            for (final attr in v['attributes']) {
              if (attr is Map) {
                // attribute could be { "name": "productId", "value": "68f..." }
                if ((attr['name'] == 'productId' || attr['key'] == 'productId') && attr['value'] is String && (attr['value'] as String).isNotEmpty) {
                  return attr['value'] as String;
                }
                // or attributes might include nested _id/$oid
                final maybe = extractMongoId(attr['_id'] ?? attr['id'] ?? attr['value']);
                if (maybe.isNotEmpty) return maybe;
              }
            }
          }
        }
      }
    }
  } catch (_) {}

  // 4) fallback: try productInfo, product._id etc
  if (json['product'] is Map) {
    final pid = extractMongoId(json['product']['_id'] ?? json['product']['id']);
    if (pid.isNotEmpty) return pid;
  }

  return '';
}

// Image Model
class ImageModel {
  final String id;
  final String? src;
  final String? alt;
  final int? order;

  ImageModel({
    required this.id,
    this.src,
    this.alt,
    this.order,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: extractMongoId(json['_id'] ?? json['id']),
      src: json['src'] as String?,
      alt: json['alt'] as String?,
      order: json['order'] is int ? json['order'] as int : (json['order'] is String ? int.tryParse(json['order']) : null),
    );
  }
}

// Attribute Model
class Attribute {
  final String id;
  final String? name;
  final String? value;

  Attribute({
    required this.id,
    this.name,
    this.value,
  });

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      id: extractMongoId(json['_id'] ?? json['id'] ?? json['value']),
      name: json['name'] as String?,
      value: json['value'] is String ? json['value'] as String : (json['value']?.toString()),
    );
  }
}

// Variant Model
class Variant {
  final String id;
  final String? sku;
  final int? quantity;
  final double? price;
  final List<String>? images;
  final List<Attribute>? attributes;

  Variant({
    required this.id,
    this.sku,
    this.quantity,
    this.price,
    this.images,
    this.attributes,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: extractMongoId(json['_id'] ?? json['id']),
      sku: json['sku'] as String?,
      quantity: json['quantity'] is int ? json['quantity'] as int : (json['quantity'] is String ? int.tryParse(json['quantity']) : null),
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      images: (json['images'] is List) ? List<String>.from(json['images'].map((e) => e?.toString() ?? '')) : [],
      attributes: (json['attributes'] is List) ? (json['attributes'] as List).map<Attribute>((a) => Attribute.fromJson(Map<String, dynamic>.from(a))).toList() : [],
    );
  }
}

// Category Model
class Category {
  final String id;
  final String? name;

  Category({
    required this.id,
    this.name,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: extractMongoId(json['_id'] ?? json['id']),
      name: json['name'] as String?,
    );
  }
}

// Brand Model
class Brand {
  final String id;
  final String? name;

  Brand({
    required this.id,
    this.name,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: extractMongoId(json['_id'] ?? json['id']),
      name: json['name'] as String?,
    );
  }
}

// IdealFor Model
class IdealFor {
  final String id;
  final String? name;

  IdealFor({
    required this.id,
    this.name,
  });

  factory IdealFor.fromJson(Map<String, dynamic> json) {
    return IdealFor(
      id: extractMongoId(json['_id'] ?? json['id']),
      name: json['name'] as String?,
    );
  }
}

// ProductInfo Model
class ProductInfo {
  final String id;
  final String? title;
  final String? description;

  ProductInfo({
    required this.id,
    this.title,
    this.description,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: extractMongoId(json['_id'] ?? json['id']),
      title: json['title'] as String?,
      description: json['description'] as String?,
    );
  }
}

// ProductSpec Model
class ProductSpec {
  final String id;
  final String? key;
  final String? value;

  ProductSpec({
    required this.id,
    this.key,
    this.value,
  });

  factory ProductSpec.fromJson(Map<String, dynamic> json) {
    return ProductSpec(
      id: extractMongoId(json['_id'] ?? json['id']),
      key: json['key'] as String?,
      value: json['value'] as String?,
    );
  }
}

// Address Model
class Address {
  final String? street;
  final String? city;
  final String? state;
  final String? pincode;

  Address({
    this.street,
    this.city,
    this.state,
    this.pincode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
    );
  }
}

// Location Model
class Location {
  final String type;
  final List<double> coordinates;

  Location({
    required this.type,
    required this.coordinates,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    final coords = <double>[];
    try {
      if (json['coordinates'] is List) {
        for (final c in json['coordinates']) {
          coords.add((c is num) ? c.toDouble() : double.tryParse(c.toString()) ?? 0.0);
        }
      }
    } catch (_) {}
    return Location(
      type: json['type'] as String? ?? 'Point',
      coordinates: coords.isNotEmpty ? coords : [0.0, 0.0],
    );
  }
}

// Contact Model
class Contact {
  final String? phone;
  final String? email;
  final String? website;

  Contact({this.phone, this.email, this.website});

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
    );
  }
}

// Store Model
class Store {
  final String id;
  final String? name;
  final Address? address;
  final Location? location;
  final Contact? contact;

  Store({
    required this.id,
    this.name,
    this.address,
    this.location,
    this.contact,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: extractMongoId(json['_id'] ?? json['id']),
      name: json['name'] as String?,
      address: json['address'] is Map ? Address.fromJson(Map<String, dynamic>.from(json['address'])) : null,
      location: json['location'] is Map ? Location.fromJson(Map<String, dynamic>.from(json['location'])) : null,
      contact: json['contact'] is Map ? Contact.fromJson(Map<String, dynamic>.from(json['contact'])) : null,
    );
  }
}

// Main Product Model
class Product {
  final String id;
  final DateTime createdAt;
  final bool inStock;
  final Category? category;
  final String title;
  final String? description;
  final double? mrp;
  final Brand? brand;
  final IdealFor? ideaFor;
  final String? discount;
  final double? rating;
  final int? reviews;
  final String? color;
  final List<ImageModel>? images;
  final List<Variant>? variant;
  final String sku;
  final List<ProductInfo>? productInfo;
  final List<ProductSpec>? productSpec;
  final DateTime createdOn;
  final Store? store;

  Product({
    required this.id,
    required this.createdAt,
    required this.inStock,
    this.category,
    required this.title,
    this.description,
    this.mrp,
    this.brand,
    this.ideaFor,
    this.discount,
    this.rating,
    this.reviews,
    this.color,
    this.images,
    this.variant,
    required this.sku,
    this.productInfo,
    this.productSpec,
    required this.createdOn,
    this.store,
  });
  /// Create minimal Product when only id exists
  factory Product.withId(String id) {
    return Product(
      id: id,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      inStock: false,
      title: '',
      sku: '',
      createdOn: DateTime.fromMillisecondsSinceEpoch(0),
      category: null,
      description: null,
      mrp: null,
      brand: null,
      ideaFor: null,
      discount: null,
      rating: null,
      reviews: null,
      color: null,
      images: const [],
      variant: const [],
      productInfo: const [],
      productSpec: const [],
      store: null,
    );
  }


  factory Product.fromJson(Map<String, dynamic> json) {
    // compute id robustly
    final pid = findProductId(json);

    // parse lists safely
    List<ImageModel> imgs = [];
    try {
      if (json['images'] is List) {
        imgs = (json['images'] as List).map<ImageModel>((i) => ImageModel.fromJson(Map<String, dynamic>.from(i))).toList();
      }
    } catch (_) { imgs = []; }

    List<Variant> vars = [];
    try {
      if (json['variant'] is List) {
        vars = (json['variant'] as List).map<Variant>((v) => Variant.fromJson(Map<String, dynamic>.from(v))).toList();
      }
    } catch (_) { vars = []; }

    List<ProductInfo> pinfo = [];
    try {
      if (json['productInfo'] is List) {
        pinfo = (json['productInfo'] as List).map<ProductInfo>((i) => ProductInfo.fromJson(Map<String, dynamic>.from(i))).toList();
      }
    } catch (_) { pinfo = []; }

    List<ProductSpec> pspec = [];
    try {
      if (json['productSpec'] is List) {
        pspec = (json['productSpec'] as List).map<ProductSpec>((s) => ProductSpec.fromJson(Map<String, dynamic>.from(s))).toList();
      }
    } catch (_) { pspec = []; }

    return Product(
      id: pid,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
      inStock: json['inStock'] is bool ? json['inStock'] as bool : (json['inStock'] != null ? json['inStock'].toString() == 'true' : false),
      category: json['category'] is Map ? Category.fromJson(Map<String, dynamic>.from(json['category'])) : null,
      title: json['title']?.toString() ?? '',
      description: json['description'] as String?,
      mrp: json['mrp'] != null ? double.tryParse(json['mrp'].toString()) : null,
      brand: json['brand'] is Map ? Brand.fromJson(Map<String, dynamic>.from(json['brand'])) : null,
      ideaFor: json['ideaFor'] is Map ? IdealFor.fromJson(Map<String, dynamic>.from(json['ideaFor'])) : null,
      discount: json['discount'] as String?,
      rating: json['rating'] != null ? double.tryParse(json['rating'].toString()) : null,
      reviews: json['reviews'] is int ? json['reviews'] as int : (json['reviews'] is String ? int.tryParse(json['reviews']) : null),
      color: json['color'] as String?,
      images: imgs,
      variant: vars,
      sku: json['SKU']?.toString() ?? '',
      productInfo: pinfo,
      productSpec: pspec,
      createdOn: json['created_on'] != null ? DateTime.tryParse(json['created_on'].toString()) ?? DateTime.now() : DateTime.now(),
      store: json['store'] is Map ? Store.fromJson(Map<String, dynamic>.from(json['store'])) : null,
    );

  }



  String get firstImageUrl {
    // First try product images (if they exist as objects)
    if (images != null && images!.isNotEmpty && images!.first.src != null && images!.first.src!.isNotEmpty) {
      final cleaned = images!.first.src!;
      return cleaned.startsWith('http') ? cleaned : "${AppConfig.imageBaseUrl}${cleaned}";
    }

    // Then try variant images (which are strings in your API)
    if (variant != null && variant!.isNotEmpty) {
      final firstVariant = variant!.first;
      if (firstVariant.images != null && firstVariant.images!.isNotEmpty && firstVariant.images!.first.isNotEmpty) {
        final cleaned = firstVariant.images!.first;
        return cleaned.startsWith('http') ? cleaned : "${AppConfig.imageBaseUrl}${cleaned}";
      }
    }
    // Fallback placeholder image
    return "https://via.placeholder.com/150";
  }
}
