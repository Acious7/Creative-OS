import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../domain/osm_location_service.dart';
import '../../domain/place_search_service.dart';
import 'osm_map_view.dart';

class RealLocationPickerSheet extends StatefulWidget {
  final String? initialQuery;
  final double? initialLatitude;
  final double? initialLongitude;

  const RealLocationPickerSheet({
    super.key,
    this.initialQuery,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<RealLocationPickerSheet> createState() =>
      _RealLocationPickerSheetState();
}

class _RealLocationPickerSheetState extends State<RealLocationPickerSheet> {
  late final TextEditingController _searchController;
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;

  double _currentLat = -1.28333; // Default Nairobi center
  double _currentLon = 36.81667;
  String _currentCategory = 'place';
  String _currentCity = '';
  String _currentCountry = '';

  bool _isLoading = false;
  String? _statusMessage;
  List<OsmPlaceDetail> _nearbyVenues = [];
  List<OsmPlaceDetail> _searchResults = [];
  Timer? _reverseGeocodeDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _nameController = TextEditingController();
    _addressController = TextEditingController();

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _currentLat = widget.initialLatitude!;
      _currentLon = widget.initialLongitude!;
      _reverseGeocodeCoordinate(_currentLat, _currentLon);
    } else if ((widget.initialQuery ?? '').isNotEmpty) {
      _nameController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    } else {
      // Auto-detect location on first open
      _useCurrentLocation();
    }
  }

  @override
  void dispose() {
    _reverseGeocodeDebounce?.cancel();
    _searchController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Use device GPS to detect position, find nearest venues, and pre-fill fields
  Future<void> _useCurrentLocation() async {
    EtoleHaptics.selection();
    setState(() {
      _isLoading = true;
      _statusMessage = 'Acquiring GPS location...';
    });

    final coords = await OsmLocationService.getCurrentCoordinates();

    if (coords != null && mounted) {
      final lat = coords['latitude']!;
      final lon = coords['longitude']!;

      setState(() {
        _currentLat = lat;
        _currentLon = lon;
        _statusMessage = 'Finding nearest venues & address...';
      });

      // 1. Reverse geocode primary location
      final place = await OsmLocationService.reverseGeocode(lat, lon);
      // 2. Query 5 nearest venues
      final nearby = await OsmLocationService.getNearbyVenues(
        lat,
        lon,
        limit: 5,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = null;
          _nearbyVenues = nearby;

          if (place != null) {
            _nameController.text = place.name;
            _addressController.text = place.address;
            _currentCategory = place.category;
            _currentCity = place.city;
            _currentCountry = place.country;
          } else if (nearby.isNotEmpty) {
            _nameController.text = nearby.first.name;
            _addressController.text = nearby.first.address;
            _currentCategory = nearby.first.category;
          }
        });
      }
    } else if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'GPS unavailable. You can drag the map pin or type a location manually.',
          ),
          backgroundColor: Color(0xFFE57B22),
        ),
      );
    }
  }

  /// Debounced reverse geocode when user finishes dragging pin on map
  void _onCoordinatesMoved(OsmCoordinates coords) {
    setState(() {
      _currentLat = coords.latitude;
      _currentLon = coords.longitude;
    });

    _reverseGeocodeDebounce?.cancel();
    _reverseGeocodeDebounce = Timer(const Duration(milliseconds: 650), () {
      _reverseGeocodeCoordinate(coords.latitude, coords.longitude);
    });
  }

  Future<void> _reverseGeocodeCoordinate(double lat, double lon) async {
    setState(() => _statusMessage = 'Looking up address...');
    final place = await OsmLocationService.reverseGeocode(lat, lon);
    final nearby = await OsmLocationService.getNearbyVenues(lat, lon, limit: 5);

    if (mounted) {
      setState(() {
        _statusMessage = null;
        _nearbyVenues = nearby;
        if (place != null) {
          _nameController.text = place.name;
          _addressController.text = place.address;
          _currentCategory = place.category;
          _currentCity = place.city;
          _currentCountry = place.country;
        }
      });
    }
  }

  /// Search places by name (on submit / explicit button press, no search-as-you-type)
  Future<void> _performSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _statusMessage = 'Searching places...';
      _searchResults = [];
    });

    final results = await OsmLocationService.searchPlaces(clean);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = null;
        _searchResults = results;
        if (results.isNotEmpty) {
          final first = results.first;
          _selectPlace(first);
        }
      });
    }
  }

  void _selectPlace(OsmPlaceDetail place) {
    EtoleHaptics.selection();
    setState(() {
      _currentLat = place.latitude;
      _currentLon = place.longitude;
      _nameController.text = place.name;
      _addressController.text = place.address;
      _currentCategory = place.category;
      _currentCity = place.city;
      _currentCountry = place.country;
      _searchResults = [];
    });
  }

  void _confirmSelection() {
    EtoleHaptics.success();
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    final result = PlaceSearchResult(
      name: name.isNotEmpty ? name : 'Meeting Venue',
      address: address,
      category: _currentCategory,
      latitude: _currentLat,
      longitude: _currentLon,
      city: _currentCity,
      country: _currentCountry,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFF0C1015),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location & Venue Picker',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'OpenStreetMap • Drag pin, search, or tap GPS',
                        style: TextStyle(color: Colors.white54, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white60),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Search Field + "Use My Location" GPS Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF151B22),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _performSearch,
                      decoration: InputDecoration(
                        hintText: 'Search venue by name...',
                        hintStyle: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFFF59E0B),
                          size: 19,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFFF59E0B),
                            size: 18,
                          ),
                          onPressed: () =>
                              _performSearch(_searchController.text),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // "Use My Location" Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _useCurrentLocation,
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.my_location_rounded,
                            color: Color(0xFFF59E0B),
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Use GPS',
                            style: TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Main Scrollable Area
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 10 + bottomInset),
              children: [
                // Loading or status indicator
                if (_statusMessage != null || _isLoading)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _statusMessage ?? 'Processing...',
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Search Results Dropdown List (if active)
                if (_searchResults.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151B22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                          child: Text(
                            'SEARCH RESULTS (TAP TO SELECT)',
                            style: TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ..._searchResults
                            .take(4)
                            .map(
                              (p) => ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                leading: const Icon(
                                  Icons.place_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 18,
                                ),
                                title: Text(
                                  p.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  p.address,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _selectPlace(p),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],

                // OpenStreetMap View with draggable center pin
                OsmMapView(
                  initialLatitude: _currentLat,
                  initialLongitude: _currentLon,
                  height: 220,
                  onCoordinatesChanged: _onCoordinatesMoved,
                  onUseMyLocation: _useCurrentLocation,
                ),
                const SizedBox(height: 12),

                // 5 Nearest Venues Strip (Rule: "If several venues are close, show the 5 nearest to tap")
                if (_nearbyVenues.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        size: 14,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '5 NEAREST VENUES (TAP TO SELECT)',
                        style: EtoleTypography.labelCaps(
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 58,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _nearbyVenues.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final v = _nearbyVenues[index];
                        final isSelected =
                            _nameController.text.trim().toLowerCase() ==
                            v.name.toLowerCase();

                        return Material(
                          color: isSelected
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                              : const Color(0xFF151B22),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () => _selectPlace(v),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFF59E0B)
                                      : Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    v.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFFF59E0B)
                                          : Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    v.formattedDistance.isNotEmpty
                                        ? '${v.formattedDistance} • ${v.address}'
                                        : v.address,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Pre-filled Venue Name Field (editable, manual entry works offline)
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  decoration: InputDecoration(
                    labelText: 'Venue / Meeting Place Name',
                    hintText: 'e.g. Java House Kilimani, Film Studio Karura',
                    labelStyle: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 12,
                    ),
                    hintStyle: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF15191E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Pre-filled Address Field (editable)
                TextField(
                  controller: _addressController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Address / Street / Area',
                    hintText: 'e.g. Lenana Road, Nairobi',
                    labelStyle: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 12,
                    ),
                    hintStyle: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF15191E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.place_outlined,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),

          // Bottom Action Bar: Google Maps Preview & Confirm Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF090D12),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  tooltip: 'Preview in Google Maps',
                  icon: const Icon(Icons.map_rounded, color: Color(0xFFF59E0B)),
                  onPressed: () {
                    final url = Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=$_currentLat,$_currentLon',
                    );
                    launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Confirm & Use This Location',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
