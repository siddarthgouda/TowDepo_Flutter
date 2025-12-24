import 'package:flutter/material.dart';
import '../Data Models/product_model.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../services/wishlist_service.dart';
import 'login_page.dart';
import 'cart_page.dart';
import 'wishlist_page.dart';
import '../widgets/product_details/product_detail_content.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _isWishlisted = false;
  bool _isLoadingWishlistState = true;
  bool _adding = false;

  // variant / quantity UI state
  int _selectedVariantIndex = 0;
  int _quantity = 1;
  bool _addingToCart = false;
  String? _selectedColor;

  List<CartItem> _cartItems = [];
  bool _loadingCart = false;

  @override
  void initState() {
    super.initState();
    _loadWishlistState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    if (!mounted) return;

    setState(() => _loadingCart = true);
    try {
      final loggedIn = await AuthService.isLoggedIn();
      if (loggedIn) {
        final items = await CartService.fetchCartItems();
        if (mounted) {
          setState(() => _cartItems = items);
        }
      }
    } catch (e) {
      // Silently fail - user might not be logged in or cart might be empty
      if (mounted) {
        setState(() => _cartItems = []);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingCart = false);
      }
    }
  }

  int get _cartItemCount {
    return _cartItems.fold(0, (sum, item) => sum + item.count);
  }

  Future<void> _loadWishlistState() async {
    setState(() => _isLoadingWishlistState = true);
    try {
      final loggedIn = await AuthService.isLoggedIn();
      if (!loggedIn) {
        setState(() {
          _isWishlisted = false;
          _isLoadingWishlistState = false;
        });
        return;
      }
      final inList = await WishlistService.isInWishlist(widget.product.id);
      if (!mounted) return;
      setState(() {
        _isWishlisted = inList;
        _isLoadingWishlistState = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isWishlisted = false;
        _isLoadingWishlistState = false;
      });
    }
  }

  Future<void> _toggleWishlist() async {
    final product = widget.product;
    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      if (result != true) return;
      await _loadWishlistState();
    }

    setState(() => _adding = true);
    try {
      if (_isWishlisted) {
        await WishlistService.removeByProductId(product.id);
        if (!mounted) return;
        setState(() => _isWishlisted = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from wishlist')),
        );
      } else {
        await WishlistService.addToWishlist(product);
        if (!mounted) return;
        setState(() => _isWishlisted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to wishlist')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wishlist failed: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _adding = false);
    }
  }

  void _onVariantSelected(int index, Variant variant) {
    setState(() {
      _selectedVariantIndex = index;
      // Reset quantity if variant stock is less than current quantity
      if (variant.quantity != null && _quantity > (variant.quantity ?? 0)) {
        _quantity = (variant.quantity ?? 1).clamp(1, variant.quantity ?? 1);
      }
    });
  }

  void _onQuantityChanged(int quantity) {
    setState(() {
      _quantity = quantity;
    });
  }

  void _onColorSelected(String? color) {
    setState(() {
      _selectedColor = color;
    });
  }

  // Add this method to your product detail page
  Future<void> _addToCart() async {
    try {
      setState(() {
        _addingToCart = true;
      });

      print('🎯 ADD TO CART BUTTON CLICKED');

      // Get the selected variant
      final selectedVariant = widget.product.variant != null &&
          widget.product.variant!.isNotEmpty &&
          _selectedVariantIndex < widget.product.variant!.length
          ? widget.product.variant![_selectedVariantIndex]
          : null;

      final variantId = selectedVariant?.id ?? 'default';

      print('📦 Product: ${widget.product.title}');
      print('🔧 Variant ID: $variantId');
      print('🔢 Quantity: $_quantity');

      // ACTUALLY CALL THE CART SERVICE API
      final cartItem = await CartService.addToCart(
        widget.product,
        variantId: variantId,
        quantity: _quantity,
      );

      print('✅ API CALL SUCCESS: ${cartItem.id}');

      // Refresh cart items to update the badge count
      await _loadCartItems();

      // Only show success if API call succeeds
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Item added to cart successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ ADD TO CART ERROR: $e');
      // Show error if API call fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to add to cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {_addingToCart = false;
        });
      }
    }
  }

  Widget _buildCartIcon() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () async {
            final loggedIn = await AuthService.isLoggedIn();
            if (!loggedIn) {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
              if (result != true) return;
            }

            // Navigate to cart page and refresh when returning
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartPage()),
            );

            // Refresh cart items when returning from cart page
            await _loadCartItems();
          },
        ),
        if (_cartItemCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _cartItemCount > 99 ? '99+' : _cartItemCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          product.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // Implement share functionality
            },
          ),
          _buildCartIcon(),
        ],
      ),
      body: SingleChildScrollView(
        child: ProductDetailContent(
          product: product,
          onVariantSelected: _onVariantSelected,
          onQuantityChanged: _onQuantityChanged,
          selectedVariantIndex: _selectedVariantIndex,
          quantity: _quantity,
          onWishlistTap: _toggleWishlist,
          isWishlisted: _isWishlisted,
          isLoadingWishlist: _adding,
          selectedColor: _selectedColor,
          onColorSelected: _onColorSelected,
          onAddToCart: _addToCart,
          addingToCart: _addingToCart,
        ),
      ),
    );
  }
}