import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({Key? key}) : super(key: key);

  static const Map<String, String> supportLinks = {
    'Contact Us': 'https://yourdomain.com/contact',
    'Shipping': 'https://yourdomain.com/shipping',
    'Returns': 'https://yourdomain.com/returns',
    'Track Order': 'https://yourdomain.com/track-order',
  };

  static const Map<String, String> companyLinks = {
    'Customer Support': 'https://yourdomain.com/support',
    'Delivery Details': 'https://yourdomain.com/delivery',
    "Terms & Conditions": 'https://yourdomain.com/terms',
    'Privacy Policy': 'https://yourdomain.com/privacy',
  };

  static const Map<String, String> socialLinks = {
    'Facebook': 'https://facebook.com/yourpage',
    'Instagram': 'https://instagram.com/tow_depo',
    'YouTube': 'https://youtube.com/yourchannel',
  };

  Future<void> _openUrl(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  Widget _linkColumn(String title, Map<String, String> items, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...items.entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: InkWell(
            onTap: () => _openUrl(e.value, context),
            child: Text(
              e.key,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
        ))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;

          // If plenty of width, show three columns side-by-side with equal space.
          // On narrow screens, let them compress but remain visible.
          if (maxWidth >= 420) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "TOW ",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          TextSpan(
                            text: "DEPO",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 20),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'One Stop E Commerce site for truck tires and trendy t-shirts.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 25),

                // Row with three Expanded columns so all are visible
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _linkColumn('SUPPORT', supportLinks, context),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _linkColumn('COMPANY', companyLinks, context),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _linkColumn('SOCIAL', socialLinks, context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            );
          }

          // Fallback for very narrow screens: horizontal scroll but keep equal widths
          final columnWidth = maxWidth / 3;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "TOW ",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        TextSpan(
                          text: "DEPO",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'One Stop E Commerce site for truck tires and trendy t-shirts.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 18),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: columnWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _linkColumn('SUPPORT', supportLinks, context),
                      ),
                    ),
                    SizedBox(
                      width: columnWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _linkColumn('COMPANY', companyLinks, context),
                      ),
                    ),
                    SizedBox(
                      width: columnWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _linkColumn('SOCIAL', socialLinks, context),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}
