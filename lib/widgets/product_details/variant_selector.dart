import 'package:flutter/material.dart';
import '../../Data Models/product_model.dart';
import '../../config/app_config.dart';

class VariantSelector extends StatefulWidget {
  final Product product;
  final Function(int, Variant) onVariantSelected;
  final Function(int) onQuantityChanged;
  final int selectedVariantIndex;
  final int quantity;
  final Function(String?) onColorSelected;

  const VariantSelector({
    Key? key,
    required this.product,
    required this.onVariantSelected,
    required this.onQuantityChanged,
    required this.selectedVariantIndex,
    required this.quantity,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  State<VariantSelector> createState() => _VariantSelectorState();
}

class _VariantSelectorState extends State<VariantSelector> {
  late int _selectedVariantIndex;
  late int _quantity;
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedVariantIndex = widget.selectedVariantIndex;
    _quantity = widget.quantity;
    _selectedColor = _getVariantColor(widget.product.variant?[_selectedVariantIndex]);
  }

  @override
  void didUpdateWidget(covariant VariantSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedVariantIndex != widget.selectedVariantIndex) {
      _selectedVariantIndex = widget.selectedVariantIndex;
      _selectedColor = _getVariantColor(widget.product.variant?[_selectedVariantIndex]);
    }
    if (oldWidget.quantity != widget.quantity) {
      _quantity = widget.quantity;
    }
  }

  // Filter only available variants (quantity > 0)
  List<Variant> get _availableVariants {
    if (widget.product.variant == null) return [];
    return widget.product.variant!.where((variant) =>
    (variant.quantity ?? 0) > 0).toList();
  }

  Variant get _selectedVariant => _availableVariants[_selectedVariantIndex];

  // Extract color from variant attributes
  String? _getVariantColor(Variant? variant) {
    if (variant == null || variant.attributes == null || variant.attributes!.isEmpty) {
      return null;
    }

    // Look for color in attributes
    for (final attr in variant.attributes!) {
      if (attr.name?.toLowerCase() == 'color' && attr.value != null && attr.value!.isNotEmpty) {
        return attr.value;
      }
    }

    return null;
  }

  // Extract size from variant attributes
  String? _getVariantSize(Variant variant) {
    if (variant.attributes == null || variant.attributes!.isEmpty) {
      return variant.sku;
    }

    // Look for size in attributes
    for (final attr in variant.attributes!) {
      if (attr.name?.toLowerCase() == 'size' && attr.value != null && attr.value!.isNotEmpty) {
        return attr.value;
      }
    }

    return variant.sku;
  }

  // Get the specific image for this color variant
  String _getVariantImage(Variant variant) {
    // First priority: Use variant's own images
    if (variant.images != null && variant.images!.isNotEmpty) {
      for (final image in variant.images!) {
        if (image.isNotEmpty) {
          return image.startsWith('http')
              ? image
              : '${AppConfig.imageBaseUrl}$image';
        }
      }
    }

    // Second priority: Try to find image by color name in product images
    final variantColor = _getVariantColor(variant);
    if (variantColor != null && widget.product.images != null) {
      for (final productImage in widget.product.images!) {
        if (productImage.src != null &&
            productImage.src!.isNotEmpty &&
            productImage.src!.toLowerCase().contains(variantColor.toLowerCase())) {
          return productImage.src!.startsWith('http')
              ? productImage.src!
              : '${AppConfig.imageBaseUrl}${productImage.src!}';
        }
      }
    }

    // Third priority: Try to find image by color name in variant images
    if (variantColor != null && widget.product.variant != null) {
      for (final otherVariant in widget.product.variant!) {
        if (otherVariant.images != null && otherVariant.images!.isNotEmpty) {
          for (final image in otherVariant.images!) {
            if (image.toLowerCase().contains(variantColor.toLowerCase())) {
              return image.startsWith('http')
                  ? image
                  : '${AppConfig.imageBaseUrl}$image';
            }
          }
        }
      }
    }

    // Fallback: Use first available image from this variant
    if (variant.images != null && variant.images!.isNotEmpty) {
      final firstImage = variant.images!.first;
      if (firstImage.isNotEmpty) {
        return firstImage.startsWith('http')
            ? firstImage
            : '${AppConfig.imageBaseUrl}$firstImage';
      }
    }

    // Final fallback: Use product's first image
    return widget.product.firstImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final availableVariants = _availableVariants;

    if (availableVariants.isEmpty) {
      return const Card(
        elevation: 1,
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No variants available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Size Selection Section
        _buildSizeSection(),

        const SizedBox(height: 20),

        // Color Selection Section
        _buildColorSection(),

        const SizedBox(height: 20),

        // Quantity Controls
        _buildQuantityControls(),
      ],
    );
  }

  Widget _buildSizeSection() {
    // Group variants by size
    final sizeGroups = <String, List<Variant>>{};
    for (final variant in _availableVariants) {
      final size = _getVariantSize(variant);
      if (size != null) {
        sizeGroups.putIfAbsent(size, () => []);
        sizeGroups[size]!.add(variant);
      }
    }

    final sizes = sizeGroups.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Size',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: sizes.map((size) {
            final variantsWithThisSize = sizeGroups[size]!;
            final isSelected = variantsWithThisSize.any((v) =>
            _availableVariants.indexOf(v) == _selectedVariantIndex);

            return GestureDetector(
              onTap: () {
                // Select the first variant with this size
                final firstVariantIndex = _availableVariants.indexOf(variantsWithThisSize.first);
                if (firstVariantIndex != -1) {
                  setState(() {
                    _selectedVariantIndex = firstVariantIndex;
                    _selectedColor = _getVariantColor(variantsWithThisSize.first);
                  });
                  widget.onVariantSelected(firstVariantIndex, variantsWithThisSize.first);
                  widget.onColorSelected(_selectedColor);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.orange : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  size,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.orange : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorSection() {
    // Group variants by color
    final colorGroups = <String, List<Variant>>{};
    for (final variant in _availableVariants) {
      final color = _getVariantColor(variant);
      if (color != null) {
        colorGroups.putIfAbsent(color, () => []);
        colorGroups[color]!.add(variant);
      }
    }

    final colors = colorGroups.keys.toList();

    if (colors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Color',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: colors.length,
          itemBuilder: (context, index) {
            final color = colors[index];
            final variantsWithThisColor = colorGroups[color]!;
            final isSelected = _selectedColor == color;
            final variantImage = _getVariantImage(variantsWithThisColor.first);

            return GestureDetector(
              onTap: () {
                // Select the first variant with this color
                final firstVariantIndex = _availableVariants.indexOf(variantsWithThisColor.first);
                if (firstVariantIndex != -1) {
                  setState(() {
                    _selectedVariantIndex = firstVariantIndex;
                    _selectedColor = color;
                  });
                  widget.onVariantSelected(firstVariantIndex, variantsWithThisColor.first);
                  widget.onColorSelected(color);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.orange : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Product image for this color - properly fitted
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(variantImage),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        _truncateColorName(color),
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.orange : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuantityControls() {
    final selectedColor = _getVariantColor(_selectedVariant);
    final selectedSize = _getVariantSize(_selectedVariant);

    return Card(
      elevation: 1,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected variant info
            if (selectedColor != null || selectedSize != null) ...[
              Row(
                children: [
                  if (selectedSize != null) ...[
                    Text(
                      'Size: $selectedSize',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (selectedColor != null && selectedSize != null)
                    const SizedBox(width: 16),
                  if (selectedColor != null)
                    Text(
                      'Color: $selectedColor',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            const Text(
              'Quantity & Price',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: _quantity > 1
                                ? () {
                              setState(() => _quantity--);
                              widget.onQuantityChanged(_quantity);
                            }
                                : null,
                            splashRadius: 18,
                            padding: const EdgeInsets.all(8),
                            color: _quantity > 1 ? Colors.black : Colors.grey,
                          ),
                          Container(
                            width: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$_quantity',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () {
                              final maxQty = _selectedVariant.quantity ?? 9999;
                              if (_quantity < maxQty) {
                                setState(() => _quantity++);
                                widget.onQuantityChanged(_quantity);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Maximum stock reached for this variant'),
                                  ),
                                );
                              }
                            },
                            splashRadius: 18,
                            padding: const EdgeInsets.all(8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Total Price - Uses selected variant price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total Price',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedVariant.price != null)
                      Text(
                        '₹${(_selectedVariant.price! * _quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    if (_selectedVariant.price != null)
                      Text(
                        '₹${_selectedVariant.price!.toStringAsFixed(2)} each',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _truncateColorName(String color) {
    if (color.length <= 8) return color;
    return '${color.substring(0, 8)}...';
  }
}