import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class LocationService {
  // Google Maps API key for web geocoding
  static const String _googleApiKey = 'AIzaSyB60AuVVaU0Y2PEj1EVbWSo2fkFhqrXaSA';

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Failed to get current location: $e');
      return null;
    }
  }

  /// Get address from coordinates
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      if (kIsWeb) {
        // Use Google Geocoding API for web
        return await _getAddressFromCoordinatesWeb(latitude, longitude);
      } else {
        // Use native geocoding for mobile
        List<Placemark> placemarks = await placemarkFromCoordinates(
          latitude,
          longitude,
        );

        if (placemarks.isNotEmpty) {
          final Placemark place = placemarks.first;
          return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}';
        }
        return null;
      }
    } catch (e) {
      print('Failed to get address: $e');
      return null;
    }
  }

  /// Web-specific geocoding using Google API
  Future<String?> _getAddressFromCoordinatesWeb(
    double latitude,
    double longitude,
  ) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$_googleApiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        return data['results'][0]['formatted_address'];
      }
    }
    return null;
  }

  /// Get city from coordinates
  Future<String?> getCityFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      if (kIsWeb) {
        // Use Google Geocoding API for web
        return await _getCityFromCoordinatesWeb(latitude, longitude);
      } else {
        // Use native geocoding for mobile
        List<Placemark> placemarks = await placemarkFromCoordinates(
          latitude,
          longitude,
        );

        if (placemarks.isNotEmpty) {
          return placemarks.first.locality;
        }
        return null;
      }
    } catch (e) {
      print('Failed to get city: $e');
      return null;
    }
  }

  /// Web-specific city lookup using Google API
  Future<String?> _getCityFromCoordinatesWeb(
    double latitude,
    double longitude,
  ) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$_googleApiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final components = data['results'][0]['address_components'] as List;
        for (var component in components) {
          final types = component['types'] as List;
          if (types.contains('locality')) {
            return component['long_name'];
          }
        }
      }
    }
    return null;
  }

  /// Get coordinates from address
  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      if (kIsWeb) {
        // Use Google Geocoding API for web
        return await _getCoordinatesFromAddressWeb(address);
      } else {
        // Use native geocoding for mobile
        List<Location> locations = await locationFromAddress(address);

        if (locations.isNotEmpty) {
          return {
            'latitude': locations.first.latitude,
            'longitude': locations.first.longitude,
          };
        }
        return null;
      }
    } catch (e) {
      print('Failed to get coordinates: $e');
      return null;
    }
  }

  /// Web-specific address to coordinates using Google API
  Future<Map<String, double>?> _getCoordinatesFromAddressWeb(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$_googleApiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final location = data['results'][0]['geometry']['location'];
        return {
          'latitude': location['lat'],
          'longitude': location['lng'],
        };
      }
    }
    return null;
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
        ) /
        1000; // Convert to kilometers
  }

  /// Format distance for display
  String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()} m';
    } else {
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
