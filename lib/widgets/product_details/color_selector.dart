import 'package:flutter/material.dart';
import '../../Data Models/product_model.dart';

class ColorSelector extends StatelessWidget {
  final Product product;
  const ColorSelector({Key? key, required this.product}) : super(key: key);

  Color? _parseColor(String colorString) {
    try {
      final c = colorString.trim();
      if (c.startsWith('#')) {
        final hex = c.replaceFirst('#', '');
        if (hex.length == 6) {
          return Color(int.parse('0xFF$hex'));
        } else if (hex.length == 8) {
          return Color(int.parse('0x$hex'));
        }
      } else if (c.startsWith('0x')) {
        return Color(int.parse(c));
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (product.color == null || product.color!.isEmpty) {
      return const SizedBox.shrink();
    }

    final parsedColor = _parseColor(product.color!);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            const Text(
              'Color:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            if (parsedColor != null) ...[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: parsedColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(product.color ?? ''),
          ],
        ),
      ),
    );
  }
}