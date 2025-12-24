import 'package:flutter/material.dart';
import '../../Data Models/address.dart';
import '../../config/app_config.dart';
import '../../services/cart_service.dart';

class PaymentDetailsSection extends StatelessWidget {
  final List<CartItem> cartItems;
  final double totalAmount;
  final Address selectedAddress;
  final bool isProcessing;
  final VoidCallback onPayNow;

  const PaymentDetailsSection({
    Key? key,
    required this.cartItems,
    required this.totalAmount,
    required this.selectedAddress,
    required this.isProcessing,
    required this.onPayNow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Order Summary
                _buildOrderSummary(context),

                const SizedBox(height: 16),

                // Shipping Address
                _buildAddressSection(context),

                const SizedBox(height: 16),

                // Payment Summary
                _buildPaymentSummary(context),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Pay Now Button (fixed at bottom)
        _buildPayButton(context),
      ],
    );
  }

  // Rest of your methods remain exactly the same...
  Widget _buildOrderSummary(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            ),
            const SizedBox(height: 16),
            ..._buildCartItems(context),
            const SizedBox(height: 16),
            _buildTotalSection(context),
          ],
        ),
      ),
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
    String? imageUrl;

    try {
      if (product?.images != null && product!.images!.isNotEmpty) {
        final firstImage = product.images!.first;
        if (firstImage is String && firstImage.isNotEmpty) {
          if (firstImage.startsWith('http')) {
            imageUrl = firstImage;
          } else {
            // Use your AppConfig image base URL
            imageUrl = '${AppConfig.imageBaseUrl}$firstImage';
          }
        }
      }

      // Alternative: Check if product has firstImageUrl directly
      if (imageUrl == null && product?.firstImageUrl != null) {
        final firstImageUrl = product!.firstImageUrl!;
        if (firstImageUrl.isNotEmpty) {
          if (firstImageUrl.startsWith('http')) {
            imageUrl = firstImageUrl;
          } else {
            imageUrl = '${AppConfig.imageBaseUrl}$firstImageUrl';
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting product image: $e');
    }

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
            return _buildPlaceholderIcon();
          },
        )
            : _buildPlaceholderIcon(),
      ),
    );
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
            '₹${totalAmount.toStringAsFixed(2)}',
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

  Widget _buildAddressSection(BuildContext context) {
    final address = selectedAddress;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Shipping Address',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.person, color: Colors.grey.shade600),
              title: Text(
                address.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('${address.addressLine1}${address.addressLine2 != null ? ', ${address.addressLine2}' : ''}'),
                  Text('${address.city}, ${address.state} ${address.postalCode}'),
                  Text(address.country),
                  Text(address.phoneNumber),
                  if (address.email != null && address.email!.isNotEmpty)
                    Text(address.email!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(context, 'Subtotal', '₹${totalAmount.toStringAsFixed(2)}'),
            _buildSummaryRow(context, 'Shipping', '₹0.00'),
            _buildSummaryRow(context, 'Tax', '₹0.00'),
            const Divider(),
            _buildSummaryRow(
              context,
              'Total Amount',
              '₹${totalAmount.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isProcessing ? null : onPayNow,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: isProcessing
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
                : const Text(
              'Pay Now',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}