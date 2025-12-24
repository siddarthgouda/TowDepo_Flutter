import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/cart_service.dart';

class OrderSummarySection extends StatelessWidget {
  final List<CartItem> cartItems;
  final double total;

  const OrderSummarySection({
    Key? key,
    required this.cartItems,
    required this.total,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            ..._buildCartItems(context),
            const SizedBox(height: 16),
            _buildTotalSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.shopping_bag_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Order Summary',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCartItems(BuildContext context) {
    return cartItems.asMap().entries.map((entry) {
      final index = entry.key;
      final cartItem = entry.value;
      final product = cartItem.product;

      return Container(
        margin: EdgeInsets.only(bottom: index == cartItems.length - 1 ? 0 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(product),
            const SizedBox(width: 12),
            _buildProductDetails(cartItem, product),
            _buildProductPrice(context, cartItem, product),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildProductImage(dynamic product) {
    // Get the first image URL from the product
    final imageUrl = _getProductImageUrl(product);

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade100,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageUrl != null
            ? Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderIcon();
          },
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
        )
            : _buildPlaceholderIcon(),
      ),
    );
  }

  String? _getProductImageUrl(dynamic product) {
    if (product == null) return null;

    try {
      // Try different possible image field names
      if (product.images != null && product.images!.isNotEmpty) {
        final firstImage = product.images!.first;
        if (firstImage is String && firstImage.isNotEmpty) {
          return '${AppConfig.imageBaseUrl}$firstImage';
        }
      }

      // Try firstImageUrl if it exists
      if (product.firstImageUrl != null && product.firstImageUrl!.isNotEmpty) {
        return product.firstImageUrl;
      }

      // Try image field directly
      if (product.image != null && product.image!.isNotEmpty) {
        final image = product.image!;
        if (image.startsWith('http')) {
          return image;
        } else {
          return '${AppConfig.imageBaseUrl}$image';
        }
      }
    } catch (e) {
      debugPrint('Error getting product image URL: $e');
    }

    return null;
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        color: Colors.grey.shade400,
        size: 24,
      ),
    );
  }

  Widget _buildProductDetails(CartItem cartItem, dynamic product) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product?.title ?? 'Unknown Product',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Qty: ${cartItem.count}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          if (product?.description != null && product!.description!.isNotEmpty)
            Text(
              product.description!,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildProductPrice(BuildContext context, CartItem cartItem, dynamic product) {
    final price = product?.mrp ?? 0;
    final totalPrice = price * cartItem.count;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '₹${price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        Text(
          '₹${totalPrice.toStringAsFixed(2)}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            '₹${total.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}