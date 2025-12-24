// lib/pages/nearby_products_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../Data Models/product_model.dart' hide Location; // Import your Product model
import 'product_detail_page.dart';

class NearbyProductsScreen extends StatefulWidget {
  final String searchMode;
  final String? pincode;

  const NearbyProductsScreen({
    Key? key,
    this.searchMode = 'Current Location',
    this.pincode,
  }) : super(key: key);

  @override
  State<NearbyProductsScreen> createState() => _NearbyProductsScreenState();
}

class _NearbyProductsScreenState extends State<NearbyProductsScreen> {
  final TextEditingController _pincodeController = TextEditingController();
  String _selectedMode = 'Current Location';
  List<Product> _nearbyProducts = []; // Product model
  bool _isLoading = false;
  bool _hasSearched = false;
  String _sortBy = 'distance';

  // Theme / accent color
  static const Color primaryOrange = Color(0xFFFF8C00);

  // Local preview fallback image (uploaded file)
  static const String _localPreviewPath = '/mnt/data/e876ee23-50c5-45d1-ab2c-119a5db316e3.png';

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.searchMode;
    if (widget.pincode != null) {
      _pincodeController.text = widget.pincode!;
    }
    _getNearbyProducts();
  }

  Future<void> _fetchNearbyProducts({
    required double lat,
    required double lng,
    double radius = 10,
  }) async {
    setState(() => _isLoading = true);

    final url = Uri.parse('${AppConfig.apiBaseUrl}/product/nearby?lat=$lat&lng=$lng&radius=$radius');
    debugPrint("🌍 Fetching from: $url");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint("✅ API Response: $data");

        // Convert to Product objects
        List<Product> products = [];
        for (var item in data) {
          try {
            products.add(Product.fromJson(item));
          } catch (e) {
            debugPrint('Error parsing product: $e');
          }
        }

        setState(() {
          _nearbyProducts = products;
          _hasSearched = true;
        });
      } else {
        throw Exception('Failed to fetch nearby products');
      }
    } catch (e) {
      debugPrint('❌ Error fetching products: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching products: $e')),
      );
      setState(() {
        _hasSearched = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _searchByPincode(String pincode) async {
    try {
      List<Location> locations = await locationFromAddress(pincode);
      if (locations.isNotEmpty) {
        final lat = locations.first.latitude;
        final lng = locations.first.longitude;
        await _fetchNearbyProducts(lat: lat, lng: lng);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No location found for this pincode')),
        );
        setState(() {
          _hasSearched = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching location from pincode: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid or unreachable pincode')),
      );
      setState(() {
        _hasSearched = true;
      });
    }
  }

  Future<void> _getNearbyProducts() async {
    if (_selectedMode == 'Current Location') {
      try {
        final pos = await _getCurrentLocation();
        await _fetchNearbyProducts(lat: pos.latitude, lng: pos.longitude);
      } catch (e) {
        debugPrint('❌ Error getting location: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location Error: $e')),
        );
        setState(() {
          _hasSearched = true;
        });
      }
    } else {
      final pin = _pincodeController.text.trim();
      if (pin.isNotEmpty) {
        await _searchByPincode(pin);
      } else if (widget.pincode != null && widget.pincode!.isNotEmpty) {
        await _searchByPincode(widget.pincode!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a pincode')),
        );
      }
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort By',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSortOption('Distance (Nearest First)', 'distance'),
            _buildSortOption('Price (Low to High)', 'price_low'),
            _buildSortOption('Price (High to Low)', 'price_high'),
            _buildSortOption('Name (A to Z)', 'name'),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _sortBy,
      activeColor: primaryOrange,
      onChanged: (val) {
        setState(() {
          _sortBy = val!;
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nearby Products',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _selectedMode == 'Current Location' ? 'Current Location' : 'Pincode: ${_pincodeController.text}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: _showSortOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Refresh Button
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _getNearbyProducts,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text("Refresh Products"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          // Filter Chips (removed km chips)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', true),
                  _buildFilterChip('In Stock', false),
                  _buildFilterChip('Offers', false),
                ],
              ),
            ),
          ),

          // Results Count
          if (_nearbyProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '${_nearbyProducts.length} Products Found',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _showSortOptions,
                    child: Row(
                      children: [
                        const Icon(Icons.swap_vert, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'Sort',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Product List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _nearbyProducts.isEmpty && _hasSearched
                ? _buildEmptyState()
                : _nearbyProducts.isEmpty
                ? const SizedBox()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _nearbyProducts.length,
              itemBuilder: (context, index) {
                final product = _nearbyProducts[index];
                return _buildProductCard(product);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_mall_outlined,
              size: 100,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              "No Products Nearby",
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedMode == 'Current Location'
                  ? "We couldn't find any products in your current location. Please check back later."
                  : "No products found for pincode ${_pincodeController.text}.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _getNearbyProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool value) {},
        backgroundColor: Colors.grey.shade100,
        selectedColor: primaryOrange,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
        checkmarkColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    // Get image URL - SIMPLIFIED
    String imageUrl = product.firstImageUrl ?? '';

    // Debug
    debugPrint('Image URL for ${product.title}: $imageUrl');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to product detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageWithFallback(imageUrl),
                ),
              ),
              const SizedBox(width: 12),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Store Name
                    if (product.store != null)
                      Text(
                        'Store: ${product.store!.name ?? 'Unknown Store'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 8),

                    Text(
                      '₹${product.mrp ?? '--'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryOrange,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Discount
                    Text(
                      'Discount: ${product.discount ?? 'No discount'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: product.discount != null ? Colors.red : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Stock Status
                    Row(
                      children: [
                        Icon(
                          product.inStock ? Icons.check_circle : Icons.cancel,
                          size: 14,
                          color: product.inStock ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.inStock ? 'In Stock' : 'Out of Stock',
                          style: TextStyle(
                            fontSize: 12,
                            color: product.inStock ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Rating
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          'Rating: ${product.rating ?? 'No rating'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Spacer where wishlist button used to be (keeps layout)
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWithFallback(String url) {
    if (url.isEmpty) {
      if (File(_localPreviewPath).existsSync()) {
        return Image.file(File(_localPreviewPath), fit: BoxFit.cover);
      } else {
        return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
      }
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Image loading error: $error');
        if (File(_localPreviewPath).existsSync()) {
          return Image.file(File(_localPreviewPath), fit: BoxFit.cover);
        }
        return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
      },
    );
  }
}
