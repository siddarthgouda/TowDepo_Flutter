import 'dart:convert';
import 'package:flutter/material.dart';
import '../../Data Models/product_model.dart';
import '../../pages/login_page.dart';
import '../../services/auth_service.dart';
import 'image_carousel.dart';
import 'product_header.dart';
import 'product_description.dart';
import 'variant_selector.dart';


class ProductDetailContent extends StatelessWidget {
  final Product product;
  final Function(int, Variant) onVariantSelected;
  final Function(int) onQuantityChanged;
  final int selectedVariantIndex;
  final int quantity;
  final VoidCallback? onWishlistTap;
  final bool isWishlisted;
  final bool isLoadingWishlist;
  final String? selectedColor;
  final Function(String?) onColorSelected;
  final Future<void> Function() onAddToCart;
  final bool addingToCart;

  const ProductDetailContent({
    Key? key,
    required this.product,
    required this.onVariantSelected,
    required this.onQuantityChanged,
    required this.selectedVariantIndex,
    required this.quantity,
    this.onWishlistTap,
    this.isWishlisted = false,
    this.isLoadingWishlist = false,
    this.selectedColor,
    required this.onColorSelected,
    required this.onAddToCart,
    required this.addingToCart,
  }) : super(key: key);

  // Get the selected variant
  Variant? get _selectedVariant {
    if (product.variant == null || product.variant!.isEmpty) return null;
    if (selectedVariantIndex >= product.variant!.length) return null;
    return product.variant![selectedVariantIndex];
  }

  Widget _productInfoSection(BuildContext context) {
    if (product.productInfo == null || product.productInfo!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Product Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: product.productInfo!.map((info) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          info.title ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          info.description ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _specsSection(BuildContext context) {
    if (product.productSpec == null || product.productSpec!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Specifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: product.productSpec!.map((spec) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          spec.key ?? '',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          spec.value ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sellerSection(BuildContext context) {
    if (product.store == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Seller Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.store, color: Colors.blue),
            ),
            title: Text(
              product.store!.name ?? 'Unknown Store',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.store!.address != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.store!.address?.city ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (product.store!.address?.pincode != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Pincode: ${product.store!.address!.pincode}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
                if (product.store!.contact != null) ...[
                  const SizedBox(height: 4),
                  if (product.store!.contact?.phone != null)
                    Text(
                      '📞 ${product.store!.contact!.phone}',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _metaInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildMetaItem(
                'Created',
                product.createdAt.toLocal().toString().split('.').first,
              ),
              if (product.reviews != null)
                _buildMetaItem('Reviews', '${product.reviews}'),
              if (product.rating != null)
                _buildMetaItem('Rating', '${product.rating} ⭐'),
              _buildMetaItem('SKU', product.sku),
              if (product.category != null && product.category!.name != null)
                _buildMetaItem('Category', product.category!.name!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }

  Future<void> _showLoginRequiredDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Login required'),
          content: const Text(
            'You must be logged in to add items to the cart. Would you like to login now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();

                // ✅ Navigate directly to LoginPage
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LoginPage(), // ← NO redirectTo
                  ),
                );
              },
              child: const Text('Login'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Carousel with Wishlist button
        ProductImageCarousel(
          product: product,
          onWishlistTap: onWishlistTap,
          isWishlisted: isWishlisted,
          isLoadingWishlist: isLoadingWishlist,
          selectedColor: selectedColor,
        ),

        // Product content starts here
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pass selected variant to ProductHeader
              ProductHeader(
                product: product,
                selectedVariant: _selectedVariant,
              ),
              const SizedBox(height: 16),
              ProductDescription(product: product),

              // Variant Selector
              if (product.variant != null && product.variant!.isNotEmpty) ...[
                const SizedBox(height: 16),
                VariantSelector(
                  product: product,
                  onVariantSelected: onVariantSelected,
                  onQuantityChanged: onQuantityChanged,
                  selectedVariantIndex: selectedVariantIndex,
                  quantity: quantity,
                  onColorSelected: onColorSelected,
                ),
              ],

              _productInfoSection(context),
              _specsSection(context),
              _sellerSection(context),
              _metaInfoSection(context),

              // Add to Cart Button inside the scrollable content
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: addingToCart
                            ? null
                            : () async {
                          // 1) Check authentication first
                          final token = await AuthService.getAccessToken();
                          if (token == null || token.isEmpty) {
                            // Not logged in -> show dialog to login
                            await _showLoginRequiredDialog(context);
                            return;
                          }

                          // 2) Logged in -> call the provided onAddToCart callback
                          try {
                            print('🔄 ADD TO CART BUTTON PRESSED IN UI');
                            // show brief feedback
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Adding to cart...')),
                            );

                            await onAddToCart();

                            // success
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart')),
                            );
                          } catch (e) {
                            // show error message
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not add to cart: $e')),
                            );
                          }
                        },
                        icon: addingToCart
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Icon(Icons.shopping_cart_outlined, size: 20),
                        label: addingToCart
                            ? const Text('Adding...', style: TextStyle(fontSize: 14))
                            : const Text('Add to Cart', style: TextStyle(fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16), // Extra space at bottom
            ],
          ),
        ),
      ],
    );
  }
}
