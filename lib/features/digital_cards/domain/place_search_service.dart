import 'dart:convert';

import 'package:http/http.dart' as http;

class PlaceSearchResult {
  final String name;
  final String address;
  final String category;
  final double latitude;
  final double longitude;
  final String city;
  final String country;

  PlaceSearchResult({
    required this.name,
    required this.address,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
  });

  String get shortSummary => address.isNotEmpty ? '$name • $address' : name;

  String get mapUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
}

class PlaceSearchService {
  /// Search venues, landmarks, cafes, and addresses worldwide using OpenStreetMap Photon API
  static Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final url = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(cleanQuery)}&limit=10',
      );
      final response = await http
          .get(url, headers: {'User-Agent': 'EtoleApp/2.0'})
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return [];
      final data = json.decode(response.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>? ?? [];

      final results = <PlaceSearchResult>[];
      for (final f in features) {
        final props = f['properties'] as Map<String, dynamic>? ?? {};
        final geom = f['geometry'] as Map<String, dynamic>? ?? {};
        final coords = geom['coordinates'] as List<dynamic>? ?? [0.0, 0.0];

        final name =
            (props['name'] ?? props['street'] ?? props['city'] ?? 'Known Venue')
                .toString();
        final street = props['street']?.toString() ?? '';
        final locality =
            props['locality']?.toString() ??
            props['district']?.toString() ??
            '';
        final city =
            props['city']?.toString() ?? props['state']?.toString() ?? '';
        final country = props['country']?.toString() ?? '';
        final osmValue =
            props['osm_value']?.toString() ??
            props['osm_key']?.toString() ??
            'place';

        final addressParts = [
          if (street.isNotEmpty && street != name) street,
          if (locality.isNotEmpty) locality,
          if (city.isNotEmpty) city,
          if (country.isNotEmpty) country,
        ];

        results.add(
          PlaceSearchResult(
            name: name,
            address: addressParts.join(', '),
            category: osmValue,
            latitude: (coords.length > 1 ? coords[1] as num : 0.0).toDouble(),
            longitude: (coords.isNotEmpty ? coords[0] as num : 0.0).toDouble(),
            city: city,
            country: country,
          ),
        );
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// Detect user location via IP or reverse geocoding
  static Future<PlaceSearchResult?> detectCurrentLocation() async {
    try {
      final ipUrl = Uri.parse('https://ipapi.co/json/');
      final ipResp = await http.get(ipUrl).timeout(const Duration(seconds: 5));
      if (ipResp.statusCode == 200) {
        final data = json.decode(ipResp.body) as Map<String, dynamic>;
        final city = data['city']?.toString() ?? 'Nairobi';
        final region = data['region']?.toString() ?? '';
        final country = data['country_name']?.toString() ?? 'Kenya';
        final lat = (data['latitude'] as num?)?.toDouble() ?? -1.28333;
        final lon = (data['longitude'] as num?)?.toDouble() ?? 36.81667;

        return PlaceSearchResult(
          name: 'Current Area ($city)',
          address: [city, if (region.isNotEmpty) region, country].join(', '),
          category: 'current_location',
          latitude: lat,
          longitude: lon,
          city: city,
          country: country,
        );
      }
    } catch (_) {}
    return null;
  }
}
