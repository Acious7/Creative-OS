import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../domain/place_search_service.dart';

class RealLocationPickerSheet extends StatefulWidget {
  final String? initialQuery;

  const RealLocationPickerSheet({super.key, this.initialQuery});

  @override
  State<RealLocationPickerSheet> createState() =>
      _RealLocationPickerSheetState();
}

class _RealLocationPickerSheetState extends State<RealLocationPickerSheet> {
  late final TextEditingController _searchController;
  Timer? _debounce;
  bool _isLoading = false;
  List<PlaceSearchResult> _results = [];
  PlaceSearchResult? _selectedPlace;
  String _activeCategory = 'All';

  final List<Map<String, String>> _categories = const [
    {'label': 'All', 'icon': '📍'},
    {'label': 'Café', 'query': 'cafe', 'icon': '☕'},
    {'label': 'Restaurant', 'query': 'restaurant', 'icon': '🍽️'},
    {'label': 'Hotel', 'query': 'hotel', 'icon': '🏨'},
    {'label': 'Co-working', 'query': 'coworking office', 'icon': '🏢'},
    {'label': 'Studio', 'query': 'studio film', 'icon': '🎬'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    if ((widget.initialQuery ?? '').isNotEmpty) {
      _performSearch(widget.initialQuery!);
    } else {
      _performSearch('Java House Nairobi');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final list = await PlaceSearchService.searchPlaces(query);
    if (mounted) {
      setState(() {
        _results = list;
        _isLoading = false;
        if (list.isNotEmpty && _selectedPlace == null) {
          _selectedPlace = list.first;
        }
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoading = true);
    final loc = await PlaceSearchService.detectCurrentLocation();
    if (mounted) {
      setState(() => _isLoading = false);
      if (loc != null) {
        setState(() {
          _selectedPlace = loc;
          _results = [loc, ..._results];
        });
        _searchController.text = loc.city;
        _performSearch(loc.city);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not detect location. Please search manually.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  IconData _getCategoryIcon(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('cafe') || lower.contains('coffee')) {
      return Icons.local_cafe_rounded;
    }
    if (lower.contains('restaurant') || lower.contains('food')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('hotel') || lower.contains('lodging')) {
      return Icons.hotel_rounded;
    }
    if (lower.contains('office') || lower.contains('work')) {
      return Icons.business_rounded;
    }
    if (lower.contains('studio') || lower.contains('film')) {
      return Icons.movie_rounded;
    }
    return Icons.place_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0F141C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

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
                    Icons.location_searching_rounded,
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
                        'Select Real Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Search venues, cafés, hotels, or use GPS',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
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
          const SizedBox(height: 14),

          // Search Field + Current Location Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF161D26),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search place, café, street...',
                        hintStyle: const TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  color: Colors.white38,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _useCurrentLocation,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: Color(0xFFF59E0B),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Category Quick Chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _activeCategory == cat['label'];
                return FilterChip(
                  label: Text('${cat['icon']} ${cat['label']}'),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() => _activeCategory = cat['label']!);
                    final term = cat['query'] ?? '';
                    final currentText = _searchController.text;
                    _performSearch(
                      term.isEmpty ? currentText : '$currentText $term',
                    );
                  },
                  backgroundColor: const Color(0xFF161D26),
                  selectedColor: const Color(0xFFF59E0B)
                      .withValues(alpha: 0.25),
                  checkmarkColor: const Color(0xFFF59E0B),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? const Color(0xFFF59E0B)
                        : Colors.white70,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFFF59E0B)
                        : Colors.white12,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Results List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
                  )
                : _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_off_rounded,
                          size: 40,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No matching places found',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final place = _results[index];
                      final isSelected = _selectedPlace == place;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: isSelected
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                              : const Color(0xFF161D26),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => setState(() => _selectedPlace = place),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFF59E0B)
                                      : Colors.white.withValues(alpha: 0.05),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFF59E0B)
                                          : Colors.white10,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(place.category),
                                      color: isSelected
                                          ? Colors.black
                                          : const Color(0xFFF59E0B),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          place.name,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                          ),
                                        ),
                                        if (place.address.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Text(
                                              place.address,
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFFF59E0B),
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Confirm Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF0A0E14),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                if (_selectedPlace != null) ...[
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.map_rounded,
                      color: Color(0xFFF59E0B),
                    ),
                    onPressed: () {
                      final url = Uri.parse(_selectedPlace!.mapUrl);
                      launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedPlace != null
                        ? () => Navigator.pop(context, _selectedPlace)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white12,
                      disabledForegroundColor: Colors.white30,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Use This Location',
                      style: TextStyle(
                        fontSize: 15,
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
