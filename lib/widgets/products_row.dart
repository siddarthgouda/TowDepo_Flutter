import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../Data Models/product_model.dart';
import '../pages/all_products_page.dart';
import '../pages/product_detail_page.dart';

class ProductsRow extends StatefulWidget {
  final void Function(Product product)? onProductTap;
  final String title;
  const ProductsRow({Key? key, this.onProductTap, this.title = 'All Products'}) : super(key: key);

  @override
  State<ProductsRow> createState() => _ProductsRowState();
}

class _ProductsRowState extends State<ProductsRow> {
  late Future<List<Product>> _future;
  String? _rawDebug; // store raw response snippet or error to show in UI

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _rawDebug = null;
    _future = ProductService.fetchAllProducts(limit: 200).then((list) {
      if (list.isEmpty) {
        _rawDebug = 'No products parsed. Check console for raw response (ApiService logs).';
      }
      return list;
    }).catchError((e) {
      _rawDebug = e.toString();
      throw e;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _load();
    });
    try {
      await _future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Row(children: [
                IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
                TextButton(
                  onPressed: () {
                    // Navigate to AllProductsPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AllProductsPage(title: widget.title)),
                    );
                  },
                  child: const Text('See all'),
                )
              ]),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Product>>(
            future: _future,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
              }
              if (snap.hasError) {
                final msg = _rawDebug ?? snap.error.toString();
                return _debugCard('Error', msg);
              }
              final products = snap.data ?? [];
              if (products.isEmpty) {
                final msg = _rawDebug ?? 'No products returned (parsed list is empty). Check console logs.';
                return _debugCard('No products', msg);
              }

              return SizedBox(
                height: 240,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final p = products[index];
                    final imageUrl = p.firstImageUrl;
                    return GestureDetector(
                      onTap: () {
                        // If parent provided onProductTap use it, otherwise navigate to detail page
                        if (widget.onProductTap != null) {
                          widget.onProductTap!.call(p);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProductDetailPage(product: p)),
                          );
                        }
                      },
                      child: SizedBox(
                        width: 160,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(p.category?.name ?? p.brand?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            const Spacer(),
                            Text(p.mrp != null ? '₹${p.mrp!.toStringAsFixed(2)}' : '—', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _debugCard(String title, String message) {
    final clipped = message.length > 600 ? message.substring(0, 600) + '... (truncated)' : message;
    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.yellow.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(child: SingleChildScrollView(child: Text(clipped, style: const TextStyle(fontSize: 12)))),
          const SizedBox(height: 8),
          Row(children: [
            ElevatedButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            const SizedBox(width: 8),
            TextButton(onPressed: () => _showFull(message), child: const Text('Show full')),
          ]),
        ],
      ),
    );
  }

  void _showFull(String full) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Server response'),
      content: SingleChildScrollView(child: Text(full)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
    ));
  }
}
