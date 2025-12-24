import 'package:flutter/material.dart';
import '../../Data Models/product_model.dart';

class ProductHeader extends StatelessWidget {
  final Product product;
  final Variant? selectedVariant;

  const ProductHeader({
    Key? key,
    required this.product,
    this.selectedVariant,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use variant price if available, otherwise use product price
    final price = selectedVariant?.price ?? product.mrp ?? 0.0;
    final inStock = selectedVariant?.quantity != null
        ? (selectedVariant!.quantity! > 0)
        : product.inStock;

    final stockBg = inStock ? Colors.green.shade50 : Colors.red.shade50;
    final stockFg = inStock ? Colors.green.shade800 : Colors.red.shade800;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Price and Rating Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '₹${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                if (product.discount != null && product.discount!.isNotEmpty)
                  Text(
                    '${product.discount}% OFF',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const Spacer(),
                if (product.rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${product.rating}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (product.reviews != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${product.reviews})',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Stock status based on selected variant
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: stockBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    inStock ? 'In Stock' : 'Out of Stock',
                    style: TextStyle(
                      color: stockFg,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (selectedVariant?.quantity != null && selectedVariant!.quantity! > 0)
                  Text(
                    '${selectedVariant!.quantity} available',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Product Tags
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (product.category != null && product.category!.name != null)
                  Chip(
                    label: Text(product.category!.name!),
                    backgroundColor: Colors.blue.shade50,
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
                if (product.brand != null && product.brand!.name != null)
                  Chip(
                    label: Text(product.brand!.name!),
                    backgroundColor: Colors.purple.shade50,
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
                if (product.sku.isNotEmpty)
                  Chip(
                    label: Text('SKU: ${product.sku}'),
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}