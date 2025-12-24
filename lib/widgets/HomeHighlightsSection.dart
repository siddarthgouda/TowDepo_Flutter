import 'dart:io';
import 'package:flutter/material.dart';

import '../config/app_config.dart';

class HomeHighlightsSection extends StatelessWidget {
  const HomeHighlightsSection({Key? key}) : super(key: key);

  Widget _highlightBox({
    required bool imageOnRight,
    required String title,
    required String desc,
    required String image,
  }) {
    final textBlock = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 14.5,
              color: Colors.black54,
              height: 1.35,
            ),
          ),
        ],
      ),
    );

    // use responsive size so images don't get upscaled too much
    const double baseSize = 130;

    final imageBlock = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: baseSize,
        height: baseSize,
        child: _buildImageWidget(image, width: baseSize, height: baseSize),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: imageOnRight
            ? [
          textBlock,
          const SizedBox(width: 18),
          imageBlock,
        ]
            : [
          imageBlock,
          const SizedBox(width: 18),
          textBlock,
        ],
      ),
    );
  }

  // Helper: handles network, file (local preview), or asset images.
  // If you always use network images, you can simplify to Image.network with caching.
  Widget _buildImageWidget(String src, {double? width, double? height}) {
    // Local file path uploaded by you for desktop preview:
    // file:///mnt/data/e876ee23-50c5-45d1-ab2c-119a5db316e3.png
    if (src.startsWith('file://')) {
      final filePath = src.replaceFirst('file://', '');
      final file = File(filePath);
      return Image.file(
        file,
        width: width,
        height: height,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _imageFallback(),
      );
    }

    // If it already looks like a full http(s) URL, use network directly
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(
        src,
        width: width,
        height: height,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
                strokeWidth: 2.0,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _imageFallback(),
      );
    }

    // If you pass only a filename, prepend AppConfig base url (convenience)
    final resolved = src.startsWith('/')
        ? src // absolute-like: leave it
        : '${AppConfig.imageBaseUrl}$src';

    // fall back to network using resolved url
    return Image.network(
      resolved,
      width: width,
      height: height,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
              strokeWidth: 2.0,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => _imageFallback(),
    );
  }

  // simple placeholder
  Widget _imageFallback() {
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, size: 36, color: Colors.black26),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _highlightBox(
          imageOnRight: true,
          title: "Safety Shirts & Jackets",
          desc:
          "Express your style with premium-quality safety shirts and jackets crafted for comfort and protection.",
          image: "${AppConfig.imageBaseUrl}images/cat3.png",

        ),

        _highlightBox(
          imageOnRight: false,
          title: "Truck Tyres",
          desc:
          "High-quality tyres built for durability and performance. Get reliable and long-lasting products for your vehicle.",
          image: "${AppConfig.imageBaseUrl}images/cat2.png",
        ),
      ],
    );
  }
}
