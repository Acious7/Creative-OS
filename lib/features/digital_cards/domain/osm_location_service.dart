import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class OsmPlaceDetail {
  final String name;
  final String address;
  final String category;
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final double? distanceMeters;

  const OsmPlaceDetail({
    required this.name,
    required this.address,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    this.distanceMeters,
  });

  String get shortSummary => address.isNotEmpty ? '$name • $address' : name;

  String get mapUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  String get formattedDistance {
    if (distanceMeters == null) return '';
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()}m away';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)}km away';
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'category': category,
    'latitude': latitude,
    'longitude': longitude,
    'city': city,
    'country': country,
    if (distanceMeters != null) 'distanceMeters': distanceMeters,
  };

  factory OsmPlaceDetail.fromJson(Map<String, dynamic> json) => OsmPlaceDetail(
    name: json['name'] as String? ?? 'Venue',
    address: json['address'] as String? ?? '',
    category: json['category'] as String? ?? 'place',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    city: json['city'] as String? ?? '',
    country: json['country'] as String? ?? '',
    distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
  );
}

class OsmLocationService {
  static const MethodChannel _locationChannel = MethodChannel(
    'com.brianetole.etole/location',
  );

  static const String userAgent =
      'EtoleStudio/2.1 (contact: hello@brianetole.com)';

  // OpenStreetMap rate limiting: max 1 request per second
  static DateTime _lastOsmRequestTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Cache for reverse geocoding and searches
  static final Map<String, OsmPlaceDetail> _reverseCache = {};
  static final Map<String, List<OsmPlaceDetail>> _searchCache = {};
  static final Map<String, List<OsmPlaceDetail>> _nearbyCache = {};

  static Future<void> _enforceRateLimit() async {
    final now = DateTime.now();
    final elapsed = now.difference(_lastOsmRequestTime).inMilliseconds;
    if (elapsed < 1050) {
      final waitMs = 1050 - elapsed;
      await Future.delayed(Duration(milliseconds: waitMs));
    }
    _lastOsmRequestTime = DateTime.now();
  }

  /// Check whether GPS location permission is granted
  static Future<bool> checkPermission() async {
    try {
      final res = await _locationChannel.invokeMethod<bool>('checkPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Request runtime location permission from the user
  static Future<bool> requestPermission() async {
    try {
      final res = await _locationChannel.invokeMethod<bool>(
        'requestPermission',
      );
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Retrieve current GPS coordinates using native Android LocationManager
  /// with IP geolocation as fallback
  static Future<Map<String, double>?> getCurrentCoordinates() async {
    try {
      final hasPerm = await checkPermission();
      if (!hasPerm) {
        final granted = await requestPermission();
        if (!granted) {
          return await _detectFallbackIpLocation();
        }
      }

      final res = await _locationChannel
          .invokeMapMethod<String, dynamic>('getCurrentLocation')
          .timeout(const Duration(seconds: 8));

      if (res != null) {
        final lat = (res['latitude'] as num?)?.toDouble();
        final lng = (res['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          return {'latitude': lat, 'longitude': lng};
        }
      }
    } catch (_) {
      // Fallback on IP geolocation if device GPS times out or throws
    }

    return await _detectFallbackIpLocation();
  }

  /// IP-based approximate location fallback (offline safe)
  static Future<Map<String, double>?> _detectFallbackIpLocation() async {
    try {
      final ipUrl = Uri.parse('https://ipapi.co/json/');
      final resp = await http.get(ipUrl).timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          return {'latitude': lat, 'longitude': lng};
        }
      }
    } catch (_) {}
    return null;
  }

  /// Reverse geocode coordinates to find venue name and formatted address
  static Future<OsmPlaceDetail?> reverseGeocode(double lat, double lon) async {
    final cacheKey = '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';
    if (_reverseCache.containsKey(cacheKey)) {
      return _reverseCache[cacheKey];
    }

    // 1. Try Photon reverse first for named POIs/venues
    try {
      final photonUrl = Uri.parse(
        'https://photon.komoot.io/reverse?lat=$lat&lon=$lon',
      );
      final pResp = await http
          .get(photonUrl, headers: {'User-Agent': userAgent})
          .timeout(const Duration(seconds: 5));

      if (pResp.statusCode == 200) {
        final data = json.decode(pResp.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];
        if (features.isNotEmpty) {
          final props =
              features.first['properties'] as Map<String, dynamic>? ?? {};
          final name = props['name']?.toString();
          final street = props['street']?.toString() ?? '';
          final city =
              props['city']?.toString() ??
              props['state']?.toString() ??
              props['district']?.toString() ??
              '';
          final country = props['country']?.toString() ?? '';
          final category =
              props['osm_value']?.toString() ??
              props['osm_key']?.toString() ??
              'place';

          if (name != null && name.isNotEmpty) {
            final addressParts = [
              if (street.isNotEmpty && street != name) street,
              if (city.isNotEmpty) city,
              if (country.isNotEmpty) country,
            ];

            final place = OsmPlaceDetail(
              name: name,
              address: addressParts.join(', '),
              category: category,
              latitude: lat,
              longitude: lon,
              city: city,
              country: country,
            );
            _reverseCache[cacheKey] = place;
            return place;
          }
        }
      }
    } catch (_) {}

    // 2. Fall back to OSM Nominatim reverse
    await _enforceRateLimit();
    try {
      final nomUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=jsonv2&addressdetails=1&zoom=18',
      );
      final nResp = await http
          .get(nomUrl, headers: {'User-Agent': userAgent})
          .timeout(const Duration(seconds: 6));

      if (nResp.statusCode == 200) {
        final data = json.decode(nResp.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};

        final venue =
            addr['amenity'] ??
            addr['shop'] ??
            addr['office'] ??
            addr['building'] ??
            addr['tourism'] ??
            addr['leisure'] ??
            data['name'];

        final road = addr['road']?.toString() ?? '';
        final suburb =
            addr['suburb']?.toString() ??
            addr['neighbourhood']?.toString() ??
            addr['city_district']?.toString() ??
            '';
        final city =
            addr['city']?.toString() ??
            addr['town']?.toString() ??
            addr['state']?.toString() ??
            '';
        final country = addr['country']?.toString() ?? '';

        final name = (venue != null && venue.toString().isNotEmpty)
            ? venue.toString()
            : (road.isNotEmpty
                  ? road
                  : (suburb.isNotEmpty
                        ? suburb
                        : 'Location (${lat.toStringAsFixed(3)}, ${lon.toStringAsFixed(3)})'));

        final addressParts = [
          if (road.isNotEmpty && road != name) road,
          if (suburb.isNotEmpty && suburb != name) suburb,
          if (city.isNotEmpty) city,
          if (country.isNotEmpty) country,
        ];

        final place = OsmPlaceDetail(
          name: name,
          address: addressParts.join(', '),
          category: data['category']?.toString() ?? 'place',
          latitude: lat,
          longitude: lon,
          city: city,
          country: country,
        );
        _reverseCache[cacheKey] = place;
        return place;
      }
    } catch (_) {}

    // 3. Fallback when completely offline
    return OsmPlaceDetail(
      name: 'Location (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})',
      address: 'Lat: $lat, Lon: $lon',
      category: 'coordinates',
      latitude: lat,
      longitude: lon,
      city: '',
      country: '',
    );
  }

  /// Find up to 5 nearest venues around a given coordinate
  static Future<List<OsmPlaceDetail>> getNearbyVenues(
    double lat,
    double lon, {
    int limit = 5,
  }) async {
    final cacheKey = '${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}';
    if (_nearbyCache.containsKey(cacheKey)) {
      return _nearbyCache[cacheKey]!;
    }

    final venues = <OsmPlaceDetail>[];
    final seenNames = <String>{};

    // Include the primary reverse-geocoded place if named
    final primary = await reverseGeocode(lat, lon);
    if (primary != null &&
        primary.name.isNotEmpty &&
        !primary.name.startsWith('Location (')) {
      venues.add(
        OsmPlaceDetail(
          name: primary.name,
          address: primary.address,
          category: primary.category,
          latitude: primary.latitude,
          longitude: primary.longitude,
          city: primary.city,
          country: primary.country,
          distanceMeters: 0,
        ),
      );
      seenNames.add(primary.name.toLowerCase());
    }

    // Query Photon for common meetup categories (cafe, restaurant, hotel, office)
    final categories = ['cafe', 'hotel', 'restaurant', 'office'];
    for (final cat in categories) {
      if (venues.length >= limit + 2) break;
      try {
        final url = Uri.parse(
          'https://photon.komoot.io/api/?q=$cat&lat=$lat&lon=$lon&limit=3',
        );
        final resp = await http
            .get(url, headers: {'User-Agent': userAgent})
            .timeout(const Duration(seconds: 4));

        if (resp.statusCode == 200) {
          final data = json.decode(resp.body) as Map<String, dynamic>;
          final features = data['features'] as List<dynamic>? ?? [];

          for (final f in features) {
            final props = f['properties'] as Map<String, dynamic>? ?? {};
            final geom = f['geometry'] as Map<String, dynamic>? ?? {};
            final coords = geom['coordinates'] as List<dynamic>? ?? [];
            if (coords.length < 2) continue;

            final vLon = (coords[0] as num).toDouble();
            final vLat = (coords[1] as num).toDouble();
            final name = props['name']?.toString() ?? '';
            if (name.isEmpty) continue;

            final lowerName = name.toLowerCase();
            if (seenNames.contains(lowerName)) continue;
            seenNames.add(lowerName);

            final street = props['street']?.toString() ?? '';
            final city =
                props['city']?.toString() ?? props['state']?.toString() ?? '';
            final country = props['country']?.toString() ?? '';
            final dist = _haversineMeters(lat, lon, vLat, vLon);

            // Filter out venues farther than 10km
            if (dist > 10000) continue;

            final addressParts = [
              if (street.isNotEmpty && street != name) street,
              if (city.isNotEmpty) city,
              if (country.isNotEmpty) country,
            ];

            venues.add(
              OsmPlaceDetail(
                name: name,
                address: addressParts.join(', '),
                category: props['osm_value']?.toString() ?? cat,
                latitude: vLat,
                longitude: vLon,
                city: city,
                country: country,
                distanceMeters: dist,
              ),
            );
          }
        }
      } catch (_) {}
    }

    // Sort by proximity
    venues.sort(
      (a, b) =>
          (a.distanceMeters ?? 999999).compareTo(b.distanceMeters ?? 999999),
    );

    final result = venues.take(limit).toList();
    _nearbyCache[cacheKey] = result;
    return result;
  }

  /// Search places by text query with caching and rate limiting (no search-as-you-type)
  static Future<List<OsmPlaceDetail>> searchPlaces(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final cacheKey = cleanQuery.toLowerCase();
    if (_searchCache.containsKey(cacheKey)) {
      return _searchCache[cacheKey]!;
    }

    // 1. Photon search (fast worldwide coverage)
    try {
      final url = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(cleanQuery)}&limit=8',
      );
      final resp = await http
          .get(url, headers: {'User-Agent': userAgent})
          .timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];

        final results = <OsmPlaceDetail>[];
        for (final f in features) {
          final props = f['properties'] as Map<String, dynamic>? ?? {};
          final geom = f['geometry'] as Map<String, dynamic>? ?? {};
          final coords = geom['coordinates'] as List<dynamic>? ?? [];
          if (coords.length < 2) continue;

          final name = (props['name'] ?? props['street'] ?? props['city'])
              ?.toString();
          if (name == null || name.isEmpty) continue;

          final street = props['street']?.toString() ?? '';
          final city =
              props['city']?.toString() ?? props['state']?.toString() ?? '';
          final country = props['country']?.toString() ?? '';

          final addressParts = [
            if (street.isNotEmpty && street != name) street,
            if (city.isNotEmpty) city,
            if (country.isNotEmpty) country,
          ];

          results.add(
            OsmPlaceDetail(
              name: name,
              address: addressParts.join(', '),
              category: props['osm_value']?.toString() ?? 'place',
              latitude: (coords[1] as num).toDouble(),
              longitude: (coords[0] as num).toDouble(),
              city: city,
              country: country,
            ),
          );
        }

        if (results.isNotEmpty) {
          _searchCache[cacheKey] = results;
          return results;
        }
      }
    } catch (_) {}

    // 2. Nominatim search fallback
    await _enforceRateLimit();
    try {
      final nomUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(cleanQuery)}&format=jsonv2&limit=6&addressdetails=1',
      );
      final nResp = await http
          .get(nomUrl, headers: {'User-Agent': userAgent})
          .timeout(const Duration(seconds: 6));

      if (nResp.statusCode == 200) {
        final list = json.decode(nResp.body) as List<dynamic>? ?? [];
        final results = <OsmPlaceDetail>[];

        for (final item in list) {
          final map = item as Map<String, dynamic>;
          final name = map['name']?.toString() ?? 'Venue';
          final lat = double.tryParse(map['lat']?.toString() ?? '') ?? 0.0;
          final lon = double.tryParse(map['lon']?.toString() ?? '') ?? 0.0;
          final addr = map['address'] as Map<String, dynamic>? ?? {};

          final road = addr['road']?.toString() ?? '';
          final city =
              addr['city']?.toString() ??
              addr['town']?.toString() ??
              addr['state']?.toString() ??
              '';
          final country = addr['country']?.toString() ?? '';

          final addressParts = [
            if (road.isNotEmpty && road != name) road,
            if (city.isNotEmpty) city,
            if (country.isNotEmpty) country,
          ];

          results.add(
            OsmPlaceDetail(
              name: name,
              address: addressParts.isNotEmpty
                  ? addressParts.join(', ')
                  : (map['display_name']?.toString() ?? ''),
              category: map['category']?.toString() ?? 'place',
              latitude: lat,
              longitude: lon,
              city: city,
              country: country,
            ),
          );
        }

        if (results.isNotEmpty) {
          _searchCache[cacheKey] = results;
          return results;
        }
      }
    } catch (_) {}

    return [];
  }

  /// Great circle distance in meters
  static double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0; // Earth radius in meters
    final phi1 = lat1 * pi / 180.0;
    final phi2 = lat2 * pi / 180.0;
    final deltaPhi = (lat2 - lat1) * pi / 180.0;
    final deltaLambda = (lon2 - lon1) * pi / 180.0;

    final a =
        sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }
}
