// lib/pages/wishlist_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/wishlist_service.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'product_detail_page.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({Key? key}) : super(key: key);

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  Future<List<WishlistItem>>? _future;

  // Local preview file you provided — used as a fallback image.
  static const String _localPreviewPath = '/mnt/data/e876ee23-50c5-45d1-ab2c-119a5db316e3.png';

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) {
      final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      if (result != true) {
        Navigator.pop(context);
        return;
      }
    }
    setState(() {
      _future = WishlistService.fetchWishlist(limit: 200);
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _future = WishlistService.fetchWishlist(limit: 200);
    });
  }

  Widget _buildLeadingImage(String? imageUrl) {
    const double size = 56.0;
    final borderRadius = BorderRadius.circular(8);

    // Widget shown when no network image and local fallback both fail
    Widget fallbackIcon() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: borderRadius,
        ),
        child: const Icon(Icons.storefront, size: 28, color: Colors.black26),
      );
    }

    // If there's no imageUrl just attempt to use local preview file or icon
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      if (File(_localPreviewPath).existsSync()) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: Image.file(
            File(_localPreviewPath),
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      } else {
        return fallbackIcon();
      }
    }

    // Try network first. On error, fall back to local file -> icon.
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          // show a subtle placeholder while loading
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: size,
              height: size,
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // Try local fallback file if present
            if (File(_localPreviewPath).existsSync()) {
              return Image.file(
                File(_localPreviewPath),
                width: size,
                height: size,
                fit: BoxFit.cover,
              );
            }
            return fallbackIcon();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If _future is not yet set, show a loading screen
    if (_future == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Wishlist')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist')),
      body: FutureBuilder<List<WishlistItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('No items in wishlist'));

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final it = items[i];

                return ListTile(
                  leading: it.image != null
                      ? _buildLeadingImage(it.image)
                      : _buildLeadingImage(null),
                  title: Text(it.title),
                  subtitle: Text('₹${it.mrp ?? '-'} • ${it.discount ?? ''}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      try {
                        await WishlistService.removeByProductId(it.productId);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed')));
                        _refresh();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Remove failed: $e')));
                      }
                    },
                  ),
                  onTap: () {
                    // navigate to product detail (you need to fetch or pass product object)
                    // If you have the full product object on WishlistItem, use it:
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: it.product)));
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
