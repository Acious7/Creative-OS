import 'osm_location_service.dart';

class PlaceSearchResult {
  final String name;
  final String address;
  final String category;
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final double? distanceMeters;

  PlaceSearchResult({
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

  factory PlaceSearchResult.fromOsm(OsmPlaceDetail p) => PlaceSearchResult(
    name: p.name,
    address: p.address,
    category: p.category,
    latitude: p.latitude,
    longitude: p.longitude,
    city: p.city,
    country: p.country,
    distanceMeters: p.distanceMeters,
  );
}

class PlaceSearchService {
  /// Search venues, landmarks, cafes, and addresses worldwide using OpenStreetMap services
  static Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    final osmResults = await OsmLocationService.searchPlaces(query);
    return osmResults.map(PlaceSearchResult.fromOsm).toList();
  }

  /// Detect user location via GPS or IP reverse geocoding
  static Future<PlaceSearchResult?> detectCurrentLocation() async {
    final coords = await OsmLocationService.getCurrentCoordinates();
    if (coords == null) return null;

    final place = await OsmLocationService.reverseGeocode(
      coords['latitude']!,
      coords['longitude']!,
    );
    if (place != null) {
      return PlaceSearchResult.fromOsm(place);
    }
    return null;
  }
}
