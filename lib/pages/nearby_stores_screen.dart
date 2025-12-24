import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../Data Models/product_model.dart' hide Location;

class AllStoresScreen extends StatefulWidget {
  final Position? userPosition;
  final String? initialPincode;

  const AllStoresScreen({
    Key? key,
    this.userPosition,
    this.initialPincode,
  }) : super(key: key);

  @override
  State<AllStoresScreen> createState() => _AllStoresScreenState();
}

class _AllStoresScreenState extends State<AllStoresScreen> {
  bool _loading = true;
  String? _error;
  LatLng? _center;
  final Set<Marker> _markers = {};
  List<Store> _stores = [];
  List<Store> _filteredStores = [];
  List<String> _states = [];
  String _selectedState = 'All States';
  final Completer<GoogleMapController> _mapController = Completer();

  // the actively-held controller reference (nullable)
  GoogleMapController? _googleMapController;
  bool _mapDisposed = false;

  BitmapDescriptor? _storeIcon; // custom marker image
  String? _selectedStoreId;

  static final String _localPreviewPath = '${AppConfig.imageBaseUrl}logos/store_marker.png';

  static const CameraPosition _fallbackCamera = CameraPosition(
    target: LatLng(20.5937, 78.9629),
    zoom: 4,
  );

  @override
  void initState() {
    super.initState();
    _loadCustomMarker(); // now loads from local file
    _initialize();
  }

  @override
  void dispose() {
    _mapDisposed = true;
    // dispose GoogleMapController if supported
    try {
      _googleMapController?.dispose();
    } catch (_) {}
    _googleMapController = null;
    super.dispose();
  }

  /// Safely obtain the GoogleMapController.
  /// Returns null if the map hasn't been created, the widget is unmounted,
  /// or the map controller was disposed.
  Future<GoogleMapController?> _safeGetMapController() async {
    if (!mounted) return null;
    if (_mapDisposed) return null;
    if (!_mapController.isCompleted) return null;
    try {
      final controller = await _mapController.future;
      if (!mounted || _mapDisposed) return null;
      return controller;
    } catch (e) {
      debugPrint('Map controller unavailable: $e');
      return null;
    }
  }

  /// Load custom marker from the provided local image file (resized to 96x96)
  Future<void> _loadCustomMarker() async {
    const int targetSize = 96;

    try {
      // Build full URL
      final String url = "${AppConfig.imageBaseUrl}logos/store_marker.png";

      // Fetch the image from your server
      final http.Response response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception("Failed to load marker from server: ${response.statusCode}");
      }

      final Uint8List bytes = response.bodyBytes;

      // Resize for Google Map Marker
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetSize,
        targetHeight: targetSize,
      );

      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      final ByteData? pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);

      if (pngBytes == null) {
        throw Exception("Failed to convert marker to PNG");
      }

      final Uint8List resizedBytes = pngBytes.buffer.asUint8List();

      // Convert to BitmapDescriptor
      _storeIcon = BitmapDescriptor.fromBytes(resizedBytes);

      debugPrint("Loaded custom marker from network: $url");

      if (mounted) setState(() {});
    } catch (e, st) {
      debugPrint("Marker load error: $e\n$st");
      _storeIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      if (mounted) setState(() {});
    }
  }

  Future<void> _initialize() async {
    try {
      LatLng center;
      if (widget.userPosition != null) {
        center = LatLng(widget.userPosition!.latitude, widget.userPosition!.longitude);
      } else if (widget.initialPincode != null && widget.initialPincode!.isNotEmpty) {
        try {
          final locs = await geocoding.locationFromAddress(widget.initialPincode!);
          if (locs.isNotEmpty) {
            center = LatLng(locs.first.latitude, locs.first.longitude);
          } else {
            final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
            center = LatLng(pos.latitude, pos.longitude);
          }
        } catch (_) {
          final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
          center = LatLng(pos.latitude, pos.longitude);
        }
      } else {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
        center = LatLng(pos.latitude, pos.longitude);
      }

      if (!mounted) return;
      setState(() => _center = center);
      await _fetchAllStores();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _fetchAllStores() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/store');
    debugPrint('AllStores: fetching $uri');

    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 12));
      debugPrint('AllStores: status ${resp.statusCode}');
      debugPrint('AllStores: body ${resp.body}');

      if (resp.statusCode != 200) {
        String serverMsg = resp.body;
        try {
          final parsed = json.decode(resp.body);
          if (parsed is Map && parsed['message'] != null) serverMsg = parsed['message'].toString();
        } catch (_) {}
        throw Exception('Server returned ${resp.statusCode}: $serverMsg');
      }

      final dynamic decoded = jsonDecode(resp.body);
      List<dynamic> rawList;
      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map && decoded['results'] is List) {
        rawList = decoded['results'] as List;
      } else if (decoded is Map && decoded['data'] is List) {
        rawList = decoded['data'] as List;
      } else if (decoded is Map && decoded['docs'] is List) {
        rawList = decoded['docs'] as List;
      } else {
        throw Exception('Unexpected response shape from /store');
      }

      final List<Store> stores = rawList.map<Store>((e) {
        final map = (e is Map<String, dynamic>) ? e : Map<String, dynamic>.from(e);
        return Store.fromJson(map);
      }).toList();

      // build state list
      final statesSet = <String>{};
      for (var s in stores) {
        final st = s.address?.state;
        if (st != null && st.trim().isNotEmpty) statesSet.add(st.trim());
      }
      final stateList = statesSet.toList()..sort();

      // set markers using optional custom icon
      _rebuildMarkers(stores, selectedId: _selectedStoreId);

      if (!mounted) return;
      setState(() {
        _stores = stores;
        _states = ['All States', ...stateList];
        _selectedState = 'All States';
        _filteredStores = List.from(_stores);
        _loading = false;
        _error = null;
      });

      // animate map to center or first store (safely)
      final controller = await _safeGetMapController();
      if (controller != null) {
        if (_stores.isNotEmpty) {
          final first = _latLngFromStore(_stores.first);
          try {
            await controller.animateCamera(CameraUpdate.newLatLngZoom(first, 12));
          } catch (e) {
            debugPrint('animateCamera skipped: $e');
          }
        } else if (_center != null) {
          try {
            await controller.animateCamera(CameraUpdate.newLatLngZoom(_center!, 12));
          } catch (e) {
            debugPrint('animateCamera skipped: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('AllStores error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  LatLng _latLngFromStore(Store s) {
    try {
      final loc = s.location;
      if (loc != null && loc.coordinates.length >= 2) {
        final lng = loc.coordinates[0];
        final lat = loc.coordinates[1];
        return LatLng(lat, lng);
      }
    } catch (_) {}
    return const LatLng(0.0, 0.0);
  }

  String? _addressTextFromStore(Store s) {
    try {
      final a = s.address;
      if (a == null) return null;
      final parts = <String>[];
      if ((a.street ?? '').isNotEmpty) parts.add(a.street!);
      if ((a.city ?? '').isNotEmpty) parts.add(a.city!);
      if ((a.state ?? '').isNotEmpty) parts.add(a.state!);
      if ((a.pincode ?? '').isNotEmpty) parts.add(a.pincode!);
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  void _rebuildMarkers(List<Store> stores, {String? selectedId}) {
    final markerIcon = _storeIcon;
    final newMarkers = <Marker>{};

    for (final store in stores) {
      final pos = _latLngFromStore(store);
      if (pos.latitude == 0.0 && pos.longitude == 0.0) continue;

      final isSelected = selectedId != null && selectedId == store.id;

      final BitmapDescriptor iconToUse;
      if (isSelected) {
        iconToUse = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      } else if (markerIcon != null) {
        iconToUse = markerIcon;
      } else {
        iconToUse = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      }

      final marker = Marker(
        markerId: MarkerId(store.id),
        position: pos,
        icon: iconToUse,
        infoWindow: InfoWindow(
          title: store.name ?? 'Store',
          snippet: _addressTextFromStore(store),
          onTap: () => _showStoreDetails(store),
        ),
        onTap: () {
          if (!mounted) return;
          setState(() => _selectedStoreId = store.id);
          _rebuildMarkers(stores, selectedId: _selectedStoreId);
          _showStoreDetails(store);
        },
      );

      newMarkers.add(marker);
    }

    _markers
      ..clear()
      ..addAll(newMarkers);

    if (mounted) setState(() {});
  }

  Future<void> _selectAndZoom(Store store) async {
    final controller = await _safeGetMapController();
    final pos = _latLngFromStore(store);
    if (controller != null && (pos.latitude != 0.0 || pos.longitude != 0.0)) {
      try {
        await controller.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
      } catch (e) {
        debugPrint('animateCamera failed in _selectAndZoom: $e');
      }
      if (!mounted) return;
      setState(() {
        _selectedStoreId = store.id;
        _rebuildMarkers(_stores, selectedId: _selectedStoreId);
      });
    } else {
      // If controller not available, still update selection visually
      if (!mounted) return;
      setState(() {
        _selectedStoreId = store.id;
        _rebuildMarkers(_stores, selectedId: _selectedStoreId);
      });
    }
  }

  void _showStoreDetails(Store s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.35,
          minChildSize: 0.2,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name ?? 'Store', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_addressTextFromStore(s) ?? 'No address'),
                    const SizedBox(height: 8),
                    if (s.contact?.phone != null) Text('Phone: ${s.contact!.phone}'),
                    if (s.contact?.email != null) Text('Email: ${s.contact!.email}'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _selectAndZoom(s);
                        },
                        child: const Text('View Store'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImageWidget(String src, {double? width, double? height}) {
    // If src is a local absolute path and exists, show it
    if (src.startsWith('/') && File(src).existsSync()) {
      return Image.file(
        File(src),
        width: width,
        height: height,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _fallbackImageBox(width, height),
      );
    }

    // file:// handling
    if (src.startsWith('file://')) {
      final path = src.replaceFirst('file://', '');
      if (File(path).existsSync()) {
        return Image.file(
          File(path),
          width: width,
          height: height,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => _fallbackImageBox(width, height),
        );
      }
    }

    // http(s) or resolved relative path using AppConfig
    final resolved = (src.startsWith('http://') || src.startsWith('https://')) ? src : '${AppConfig.imageBaseUrl}$src';
    return Image.network(
      resolved,
      width: width,
      height: height,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (_, __, ___) => _fallbackImageBox(width, height),
    );
  }

  Widget _fallbackImageBox(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: const Icon(Icons.storefront, size: 28, color: Colors.black26),
    );
  }

  void _onStateChanged(String? newState) async {
    if (newState == null) return;
    if (!mounted) return;
    setState(() {
      _selectedState = newState;
      if (newState == 'All States') {
        _filteredStores = List.from(_stores);
      } else {
        _filteredStores = _stores.where((s) => (s.address?.state ?? '').trim() == newState.trim()).toList();
      }
    });

    if (_filteredStores.isNotEmpty) {
      final controller = await _safeGetMapController();
      final pos = _latLngFromStore(_filteredStores.first);
      if (controller != null && (pos.latitude != 0.0 || pos.longitude != 0.0)) {
        try {
          await controller.animateCamera(CameraUpdate.newLatLngZoom(pos, 13));
        } catch (e) {
          debugPrint('animateCamera skipped in _onStateChanged: $e');
        }
      }
    }
  }

  Future<void> _refresh() async {
    await _fetchAllStores();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFFF8C00);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('All Stores'),
        backgroundColor: primaryOrange,
        elevation: 0,
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _initialize, child: const Text('Retry')),
          ]),
        ),
      )
          : Column(
        children: [
          // Map area (unchanged aside from safe controller handling & small color updates)
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.44,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: _center != null ? CameraPosition(target: _center!, zoom: 12) : _fallbackCamera,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: _markers,
                    onMapCreated: (controller) {
                      // store a reference safely
                      if (!_mapController.isCompleted) _mapController.complete(controller);
                      _googleMapController = controller;
                      _mapDisposed = false;
                    },
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.place, size: 18, color: Color(0xFFFF8C00)),
                            const SizedBox(width: 8),
                            Text(
                              _center == null ? 'Current' : 'Map center',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          backgroundColor: Colors.white,
                          heroTag: 'btn_bounds',
                          onPressed: () async {
                            if (_filteredStores.isEmpty) return;
                            final controller = await _safeGetMapController();
                            if (controller == null) return;
                            final lats = _filteredStores.map((s) => _latLngFromStore(s).latitude).where((v) => v != 0.0);
                            final lngs = _filteredStores.map((s) => _latLngFromStore(s).longitude).where((v) => v != 0.0);
                            if (lats.isEmpty || lngs.isEmpty) return;
                            final south = lats.reduce((a, b) => a < b ? a : b);
                            final north = lats.reduce((a, b) => a > b ? a : b);
                            final west = lngs.reduce((a, b) => a < b ? a : b);
                            final east = lngs.reduce((a, b) => a > b ? a : b);
                            final bounds = LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east));
                            try {
                              await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
                            } catch (e) {
                              debugPrint('animateCamera bounds failed: $e');
                            }
                          },
                          child: const Icon(Icons.center_focus_strong, color: Color(0xFFFF8C00)),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'btn_mypos',
                          backgroundColor: Colors.white,
                          onPressed: () async {
                            try {
                              final pos = await Geolocator.getCurrentPosition();
                              final controller = await _safeGetMapController();
                              if (controller == null) return;
                              await controller.animateCamera(CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 14));
                            } catch (e) {
                              debugPrint('mypos / animate failure: $e');
                            }
                          },
                          child: const Icon(Icons.my_location, color: Color(0xFFFF8C00)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filters (removed search button as requested)
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Text('State: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedState,
                    items: _states.map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
                    onChanged: _onStateChanged,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Search button removed per user request
              ],
            ),
          ),

          // Store list (preview image used for thumbnails)
          Expanded(
            child: _filteredStores.isEmpty
                ? Center(
              child: Text(_selectedState == 'All States' ? 'No stores available' : 'No stores in $_selectedState'),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _filteredStores.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final s = _filteredStores[index];
                final pos = _latLngFromStore(s);
                final isSelected = _selectedStoreId == s.id;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await _selectAndZoom(s);
                      _showStoreDetails(s);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: _buildImageWidget(_localPreviewPath, width: 72, height: 72),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(s.name ?? 'Store', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                                    const SizedBox(width: 6),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(8)),
                                        child: const Text('Selected', style: TextStyle(color: Colors.white, fontSize: 12)),
                                      )
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(_addressTextFromStore(s) ?? 'No address', maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (s.contact?.phone != null) Text(s.contact!.phone!, style: const TextStyle(fontSize: 13)),
                                    Text('Lat: ${pos.latitude.toStringAsFixed(4)}  Lng: ${pos.longitude.toStringAsFixed(4)}', style: const TextStyle(fontSize: 11)),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
