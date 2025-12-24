// lib/widgets/home_info_section.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

class HomeInfoSection extends StatelessWidget {
  const HomeInfoSection({Key? key}) : super(key: key);

  static const String instagramUrl = "https://instagram.com/tow_depo";

  Future<void> _launchInstagram() async {
    final uri = Uri.parse(instagramUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw "Could not launch $instagramUrl";
    }
  }

  Widget _infoItem(String iconPath, String title, String desc) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F2EA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Image.network(
                  iconPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.image_not_supported,
                        size: 28, color: Colors.grey.shade700);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 18),
        const Text(
          "Follow us",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            try {
              await _launchInstagram();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not open Instagram: $e')),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Image.network(
                    '${AppConfig.imageBaseUrl}logos/instagram.png',
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "@tow_depo",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Fixed layout using ConstrainedBox
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600, // Adjust based on your needs
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoItem(
                "${AppConfig.imageBaseUrl}logos/pay.png",
                "Payment Method",
                "We offer flexible payment options to make shopping easier.",
              ),
              _infoItem(
                "${AppConfig.imageBaseUrl}logos/return.png",
                "Return Policy",
                "You can return a product within 30 days.",
              ),
              _infoItem(
                "${AppConfig.imageBaseUrl}logos/support.png",
                "Customer Support",
                "Our support team is here 24/7.",
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
