import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertfirst/pages/wishlist_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../states/app_state.dart';
import '../widgets/HomeHighlightsSection.dart';
import '../widgets/app_footer.dart';
import '../widgets/auto_poster_slider.dart';
import '../widgets/home_category_slider.dart';
import '../widgets/home_info_section.dart';
import '../widgets/products_row.dart';
import 'cart_page.dart';
import 'login_page.dart';
import 'nearby_products_screen.dart';
import 'nearby_stores_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedMode = 'Current Location';
  final TextEditingController _pincodeController = TextEditingController();
  String _currentAddress = 'Fetching location...';
  bool _isLoadingLocation = false;
  bool _showSearchButton = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentAddress == 'Fetching location...') {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLocation = true;
      _currentAddress = 'Fetching location...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _currentAddress = 'Location services disabled. Tap to enable.';
          _isLoadingLocation = false;
        });
        if (!kIsWeb) {
          await Geolocator.openLocationSettings();
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _currentAddress = 'Location permission denied. Tap to grant.';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _currentAddress = 'Location permission permanently denied. Open settings.';
          _isLoadingLocation = false;
        });
        return;
      }

      try {
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null && mounted) {
          _currentPosition = lastPosition;
          // update shared AppState
          Provider.of<AppState>(context, listen: false).setPosition(lastPosition);
          await _getAddressFromPosition(lastPosition);
          return;
        }
      } catch (e) {
        debugPrint('Last known position error: $e');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        forceAndroidLocationManager: false,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Location request timed out. Please check emulator location settings.');
        },
      );

      if (!mounted) return;
      _currentPosition = position;

      // update shared AppState
      Provider.of<AppState>(context, listen: false).setPosition(position);

      await _getAddressFromPosition(position);

    } catch (e) {
      if (!mounted) return;
      debugPrint('Location error: $e');

      String errorMessage = 'Unable to get location';
      if (e.toString().contains('timed out')) {
        errorMessage = 'Location timeout. Check emulator settings.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Location permission required. Tap to grant.';
      } else if (e.toString().contains('disabled')) {
        errorMessage = 'Location services disabled. Tap to enable.';
      }

      setState(() {
        _currentAddress = '$errorMessage Tap to retry';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _getAddressFromPosition(Position position) async {
    if (!mounted) return;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        List<String> addressParts = [];
        if (place.subLocality?.isNotEmpty ?? false) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality?.isNotEmpty ?? false) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea?.isNotEmpty ?? false) {
          addressParts.add(place.administrativeArea!);
        }

        setState(() {
          _currentAddress = addressParts.isNotEmpty
              ? addressParts.join(', ')
              : '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _currentAddress = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Geocoding error: $e');
      setState(() {
        _currentAddress = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _isLoadingLocation = false;
      });
    }
  }

  void _handleLocationTap() {
    if (_currentAddress.contains('Tap to retry') ||
        _currentAddress.contains('Tap to enable') ||
        _currentAddress.contains('Tap to grant') ||
        _currentAddress.contains('Open settings')) {
      if (_currentAddress.contains('Open settings')) {
        Geolocator.openAppSettings();
      } else if (_currentAddress.contains('enable location')) {
        Geolocator.openLocationSettings();
      } else {
        _getCurrentLocation();
      }
    } else {
      _showLocationDialog();
    }
  }

  void _openNearbyProductsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NearbyProductsScreen(
          searchMode: _selectedMode,
          pincode: _pincodeController.text.isNotEmpty ? _pincodeController.text : null,
        ),
      ),
    );
  }

  void _showLocationDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.my_location, color: Colors.blue),
              title: const Text('Use Current Location'),
              subtitle: const Text('Auto-detect your location'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedMode = 'Current Location';
                  _showSearchButton = false;
                });
                _getCurrentLocation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.blue),
              title: const Text('Search by Pincode'),
              subtitle: const Text('Enter pincode manually'),
              onTap: () {
                Navigator.pop(context);
                _showPincodeDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPincodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Pincode'),
        content: TextField(
          controller: _pincodeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Pincode',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
            hintText: 'Enter 6-digit pincode',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_pincodeController.text.isNotEmpty &&
                  _pincodeController.text.length == 6) {
                setState(() {
                  _selectedMode = 'Pincode';
                  _showSearchButton = true;
                });

                // update shared AppState with pincode
                Provider.of<AppState>(context, listen: false).setPincode(_pincodeController.text);

                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid 6-digit pincode'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Search Location'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Fixed height app bar - REDUCED HEIGHT
          Container(
            height: MediaQuery.of(context).padding.top + 120, // Further reduced height
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
              gradient: LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced padding
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo and Icons Row - COMPACT
                    SizedBox(
                      height: 40, // Reduced height
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Logo - More compact
                          Container(
                            height: 35, // Reduced height
                            child: Image.network(
                              '${AppConfig.imageBaseUrl}logos/TowDepo.png',
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Row(
                                  children: [
                                    Text(
                                      'TOW',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22, // Smaller font
                                      ),
                                    ),
                                    Text(
                                      'DEPO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22, // Smaller font
                                      ),
                                    ),
                                  ],
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Logo loading error: $error');
                                return const Row(
                                  children: [
                                    Text(
                                      'TOW',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22, // Smaller font
                                      ),
                                    ),
                                    Text(
                                      'DEPO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22, // Smaller font
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          Row(
                            children: [
                              // inside HomeScreen build, where wishlist icon is defined:
                              IconButton(
                                icon: const Icon(Icons.favorite_border, color: Colors.black, size: 20),
                                onPressed: () async {
                                  final loggedIn = await AuthService.isLoggedIn();

                                  if (!loggedIn) {
                                    // Show login dialog first
                                    final result = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Login Required'),
                                        content: const Text('Please login to access your wishlist.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(true),
                                            child: const Text('Login'),
                                          ),
                                        ],
                                      ),
                                    );

                                    // If user wants to login, navigate to login page
                                    if (result == true) {
                                      final loginResult = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(builder: (_) => const LoginPage()),
                                      );

                                      // If login successful, open wishlist page
                                      if (loginResult == true && mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const WishlistPage()),
                                        );
                                      }
                                    }
                                  } else {
                                    // Already logged in, directly open wishlist page
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const WishlistPage()),
                                    );
                                  }
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),

                              const SizedBox(width: 4), // Reduced spacing
                              IconButton(
                                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black, size: 20),
                                onPressed: () async {
                                  final loggedIn = await AuthService.isLoggedIn();

                                  if (!loggedIn) {
                                    // Show login dialog first
                                    final result = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Login Required'),
                                        content: const Text('Please login to access your cart.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(true),
                                            child: const Text('Login'),
                                          ),
                                        ],
                                      ),
                                    );

                                    // If user wants to login, navigate to login page
                                    if (result == true) {
                                      final loginResult = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(builder: (_) => const LoginPage()),
                                      );

                                      // If login successful, open cart page
                                      if (loginResult == true && mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const CartPage()),
                                        );
                                      }
                                    }
                                  } else {
                                    // Already logged in, directly open cart page
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const CartPage()),
                                    );
                                  }
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12), // Reduced spacing

                    // Location Bar - COMPACT
                    SizedBox(
                      height: 50, // Reduced height
                      child: InkWell(
                        onTap: _handleLocationTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Reduced padding
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isLoadingLocation ? Icons.location_searching : Icons.location_on,
                                color: Colors.orange,
                                size: 18, // Smaller icon
                              ),
                              const SizedBox(width: 6), // Reduced spacing
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedMode == 'Current Location'
                                          ? 'Current Location'
                                          : 'Pincode: ${_pincodeController.text}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12, // Smaller font
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 1), // Minimal spacing
                                    _isLoadingLocation
                                        ? const Row(
                                      children: [
                                        SizedBox(
                                          height: 10,
                                          width: 10,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Getting location...',
                                          style: TextStyle(
                                            fontSize: 10, // Smaller font
                                            color: Colors.black12,
                                          ),
                                        ),
                                      ],
                                    )
                                        : Text(
                                      _selectedMode == 'Current Location'
                                          ? _currentAddress
                                          : 'Tap to change location',
                                      style: const TextStyle(
                                        fontSize: 10, // Smaller font
                                        color: Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 2), // Minimal spacing
                              Icon(
                                _currentAddress.contains('Tap to') || _currentAddress.contains('Open settings')
                                    ? Icons.refresh
                                    : Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 18, // Smaller icon
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search Button only for Pincode mode
          if (_showSearchButton && _selectedMode == 'Pincode')
            Padding(
              padding: const EdgeInsets.all(12.0), // Reduced padding
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openNearbyProductsScreen,
                  icon: const Icon(Icons.search, size: 18), // Smaller icon
                  label: const Text('Find Nearby Products', style: TextStyle(fontSize: 14)), // Smaller text
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0082C3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12), // Reduced padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),

          // Body
          const Expanded(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Important
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HomeCategorySlider(),
                        AutoPosterSlider(),
                        SizedBox(height: 20),
                        ProductsRow(),
                        SizedBox(height: 20),
                        HomeHighlightsSection(),
                        SizedBox(height: 20),
                        HomeInfoSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Floating Action Button to navigate to Nearby Products
      floatingActionButton: FloatingActionButton(
        onPressed: _openNearbyProductsScreen,
        backgroundColor: const Color(0xFFF66622),
        foregroundColor: Colors.white,
        child: const Icon(Icons.shopping_basket, size: 24),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // NOTE: bottomNavigationBar removed; MainShell provides the shared bar
    );
  }

  @override
  void dispose() {
    _pincodeController.dispose();
    super.dispose();
  }
}
