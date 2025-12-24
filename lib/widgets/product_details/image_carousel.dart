import 'package:flutter/material.dart';
import '../../Data Models/product_model.dart';
import '../../config/app_config.dart';
import '../../pages/login_page.dart';
import '../../services/auth_service.dart';


class ProductImageCarousel extends StatelessWidget {
  final Product product;
  final VoidCallback? onWishlistTap;
  final bool isWishlisted;
  final bool isLoadingWishlist;
  final String? selectedColor;

  const ProductImageCarousel({
    Key? key,
    required this.product,
    this.onWishlistTap,
    this.isWishlisted = false,
    this.isLoadingWishlist = false,
    this.selectedColor,
  }) : super(key: key);

  List<String> _getFilteredImageUrls() {
    final List<String> images = [];

    // If a color is selected, show only images for that color
    if (selectedColor != null && selectedColor!.isNotEmpty) {
      // 1. Check variant images for the selected color
      if (product.variant != null && product.variant!.isNotEmpty) {
        for (final variant in product.variant!) {
          final variantColor = _getVariantColor(variant);
          if (variantColor?.toLowerCase() == selectedColor!.toLowerCase()) {
            if (variant.images != null && variant.images!.isNotEmpty) {
              for (final variantImage in variant.images!) {
                if (variantImage.isNotEmpty) {
                  final imageUrl = _buildImageUrl(variantImage);
                  if (!images.contains(imageUrl)) {
                    images.add(imageUrl);
                  }
                }
              }
            }
          }
        }
      }

      // 2. Check product images for the selected color
      if (product.images != null && product.images!.isNotEmpty) {
        for (final ImageModel img in product.images!) {
          if (img.src != null &&
              img.src!.isNotEmpty &&
              img.src!.toLowerCase().contains(selectedColor!.toLowerCase())) {
            final imageUrl = _buildImageUrl(img.src!);
            if (!images.contains(imageUrl)) {
              images.add(imageUrl);
            }
          }
        }
      }
    }

    // If no color selected or no color-specific images found, show all images
    if (images.isEmpty) {
      // Add main product images
      if (product.images != null && product.images!.isNotEmpty) {
        for (final ImageModel img in product.images!) {
          if (img.src != null && img.src!.isNotEmpty) {
            final imageUrl = _buildImageUrl(img.src!);
            if (!images.contains(imageUrl)) {
              images.add(imageUrl);
            }
          }
        }
      }

      // Add variant images if no main images
      if (images.isEmpty && product.variant != null && product.variant!.isNotEmpty) {
        for (final variant in product.variant!) {
          if (variant.images != null && variant.images!.isNotEmpty) {
            for (final variantImage in variant.images!) {
              if (variantImage.isNotEmpty) {
                final imageUrl = _buildImageUrl(variantImage);
                if (!images.contains(imageUrl)) {
                  images.add(imageUrl);
                }
              }
            }
          }
        }
      }
    }

    // Fallback to firstImageUrl from product model
    if (images.isEmpty) {
      images.add(product.firstImageUrl);
    }

    return images;
  }

  // Helper method to extract color from variant
  String? _getVariantColor(Variant variant) {
    if (variant.attributes == null || variant.attributes!.isEmpty) {
      return null;
    }

    for (final attr in variant.attributes!) {
      if (attr.name?.toLowerCase() == 'color' && attr.value != null && attr.value!.isNotEmpty) {
        return attr.value;
      }
    }

    return null;
  }

  String _buildImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // Handle different image path formats
    if (imagePath.contains('/')) {
      return '${AppConfig.imageBaseUrl}$imagePath';
    } else {
      return '${AppConfig.imageBaseUrl}$imagePath';
    }
  }

  // Handle wishlist tap with login check
  Future<void> _handleWishlistTap(BuildContext context) async {
    final loggedIn = await AuthService.isLoggedIn();

    if (!loggedIn) {
      // Show login dialog
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('Please login to add items to your wishlist.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Login'),
            ),
          ],
        ),
      );

      // If user wants to login, navigate to login page
      if (result == true) {
        final loginResult = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );

        // If login successful, trigger the actual wishlist action
        if (loginResult == true && onWishlistTap != null) {
          onWishlistTap!();
        }
      }
    } else {
      // Already logged in, trigger the wishlist action directly
      if (onWishlistTap != null) {
        onWishlistTap!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = _getFilteredImageUrls();

    return Stack(
      children: [
        // Image Carousel
        Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.4,
          child: imageUrls.length > 1
              ? PageView.builder(
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return _buildImageItem(imageUrls[index]);
            },
          )
              : _buildImageItem(imageUrls.first),
        ),

        // Wishlist Button at top right
        if (onWishlistTap != null)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: isLoadingWishlist ? null : () => _handleWishlistTap(context),
                icon: isLoadingWishlist
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  color: isWishlisted ? Colors.red : Colors.black87,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                splashRadius: 20,
              ),
            ),
          ),

        // Image Counter at bottom center (only show if multiple images)
        if (imageUrls.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${imageUrls.length} images',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImageItem(String imageUrl) {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade100,
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  'Image not available',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade200,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}