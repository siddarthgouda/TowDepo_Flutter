import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import 'product_detail_page.dart';
import 'checkout_page.dart';
import '../Data Models/address.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Future<List<CartItem>> _future;
  bool _loadingAction = false;

  @override
  void initState() {
    super.initState();
    _future = CartService.fetchCartItems();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = CartService.fetchCartItems();
    });
    try {
      await _future;
    } catch (_) {}
  }

  double _computeTotal(List<CartItem> items) {
    double total = 0;
    for (final c in items) {
      final price = c.product?.mrp ?? 0;
      total += (price * (c.count));
    }
    return total;
  }

  Widget _buildTile(CartItem item) {
    final prod = item.product;
    final img = prod?.firstImageUrl ?? 'https://via.placeholder.com/150';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: () {
          if (prod != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: prod)));
          }
        },
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(img, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
        ),
        title: Text(
          prod?.title ?? 'Unknown product',
          maxLines: 2, // Prevent long titles from causing overflow
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text('Price: ₹${prod?.mrp?.toStringAsFixed(2) ?? '--'}'),
            const SizedBox(height: 6),
            Wrap( // Changed from Row to Wrap to prevent overflow
              spacing: 4,
              runSpacing: 4,
              children: [
                IconButton(
                  onPressed: () async {
                    if (item.count <= 1) return;
                    setState(() => _loadingAction = true);
                    try {
                      await CartService.updateCartCount(item.id, item.count - 1);
                      await _refresh();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
                    } finally {
                      setState(() => _loadingAction = false);
                    }
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                  iconSize: 20, // Smaller icon size
                  padding: EdgeInsets.zero, // Reduce padding
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                Text('${item.count}', style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () async {
                    setState(() => _loadingAction = true);
                    try {
                      await CartService.updateCartCount(item.id, item.count + 1);
                      await _refresh();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
                    } finally {
                      setState(() => _loadingAction = false);
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 20, // Smaller icon size
                  padding: EdgeInsets.zero, // Reduce padding
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Remove item'),
                        content: const Text('Remove this item from cart?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
                        ],
                      ),
                    );
                    if (ok == true) {
                      setState(() => _loadingAction = true);
                      try {
                        await CartService.deleteCartItem(item.id);
                        await _refresh();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                      } finally {
                        setState(() => _loadingAction = false);
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Remove', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                )
              ],
            )
          ],
        ),
        trailing: SizedBox(
          width: 70, // Fixed width for trailing to prevent overflow
          child: Text(
            '₹${((prod?.mrp ?? 0) * item.count).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
        isThreeLine: true, // Allow more space for content
      ),
    );
  }
  Future<void> _onCheckoutPressed(List<CartItem> items) async {
    // Navigate to CheckoutPage with the list of CartItem
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CheckoutPage(cartItems: items)),
    );

    // result == true means payment completed (you can adapt)
    if (result == true) {
      // Optionally clear cart or refresh
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment completed (placeholder)')));
      await _refresh();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))],
      ),
      body: FutureBuilder<List<CartItem>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('Your cart is empty'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Browse products')),
            ]));
          }

          final total = _computeTotal(items);

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _buildTile(items[index]),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Total', style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(height: 6),
                      Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ])),
                    ElevatedButton(
                      onPressed: _loadingAction ? null : () => _onCheckoutPressed(items),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        child: Text('Checkout'),
                      ),
                    )
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
