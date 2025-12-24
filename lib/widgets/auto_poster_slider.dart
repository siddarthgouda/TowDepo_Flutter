import 'dart:async';
import 'package:flutter/material.dart';

import '../config/app_config.dart';

class AutoPosterSlider extends StatefulWidget {
  final void Function(int index)? onTap;

  const AutoPosterSlider({Key? key, this.onTap}) : super(key: key);

  @override
  State<AutoPosterSlider> createState() => _AutoPosterSliderState();
}

class _AutoPosterSliderState extends State<AutoPosterSlider> {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  // Use your AppConfig base URL (server) for real images.
  // Example server URLs:
  final List<String> _posters = [
    '${AppConfig.imageBaseUrl}images/banner1.png',
    '${AppConfig.imageBaseUrl}images/banner2.png',

  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_pageController.hasClients && _posters.isNotEmpty) {
        _currentPage = (_currentPage + 1) % _posters.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_posters.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: SizedBox(
        height: 260,
        child: PageView.builder(
          controller: _pageController,
          itemCount: _posters.length,
          itemBuilder: (context, index) {
            final poster = _posters[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: () => widget.onTap?.call(index),
                child: _buildPosterWidget(poster),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPosterWidget(String url) {
    // If the url starts with "file://", Image.network will still work for some platforms
    // but it's often better to use Image.file for local files. The following handles both.
    if (url.startsWith('file://')) {
      return Image.network(
        url,
        fit: BoxFit.fitWidth,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          // fallback to a placeholder if loading fails
          return Container(
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image, size: 48),
          );
        },
      );
    }

    // Normal network image (recommended)
    return Image.network(
      url,
      fit: BoxFit.fitWidth,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, size: 48),
        );
      },
    );
  }
}
