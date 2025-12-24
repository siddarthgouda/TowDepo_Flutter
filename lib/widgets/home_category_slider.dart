import 'package:flutter/material.dart';

import '../config/app_config.dart';

class HomeCategorySlider extends StatelessWidget {
  const HomeCategorySlider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child:Image.network(
            '${AppConfig.imageBaseUrl}images/banner0.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
