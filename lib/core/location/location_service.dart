import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double? lat;
  final double? lng;
  final String? errorMessage;
  final bool permissionDenied;
  final bool gpsDisabled;
  final bool fromFallback;

  const LocationResult({
    this.lat,
    this.lng,
    this.errorMessage,
    this.permissionDenied = false,
    this.gpsDisabled = false,
    this.fromFallback = false,
  });

  bool get hasLocation => lat != null && lng != null;
}

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  static const double _fallbackLat = -12.0464;
  static const double _fallbackLng = -77.0428;

  static const Duration _timeout = Duration(seconds: 15);

  Future<bool> ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    return permission != LocationPermission.deniedForever;
  }

  Future<LocationResult> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          gpsDisabled: true,
          errorMessage: 'GPS desactivado. Active la ubicación del dispositivo.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const LocationResult(
          permissionDenied: true,
          errorMessage: 'Permiso de ubicación denegado.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          permissionDenied: true,
          errorMessage:
              'Permiso de ubicación denegado permanentemente. '
              'Actívelo desde Configuración > Permisos.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: _timeout,
      );

      return LocationResult(
        lat: position.latitude,
        lng: position.longitude,
      );
    } on TimeoutException {
      return const LocationResult(
        errorMessage: 'No se pudo obtener ubicación (timeout).',
      );
    } catch (e) {
      return LocationResult(
        errorMessage: 'Error al obtener ubicación: ${e.toString()}',
      );
    }
  }

  Future<LocationResult> getCurrentPositionWithFallback() async {
    final result = await getCurrentPosition();
    if (result.hasLocation) return result;

    return LocationResult(
      lat: _fallbackLat,
      lng: _fallbackLng,
      errorMessage: result.errorMessage,
      permissionDenied: result.permissionDenied,
      gpsDisabled: result.gpsDisabled,
      fromFallback: true,
    );
  }

  Future<LocationResult> getLastKnownPosition() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        return LocationResult(
          lat: position.latitude,
          lng: position.longitude,
        );
      }
      return const LocationResult(
        errorMessage: 'Sin ubicación conocida reciente.',
      );
    } catch (e) {
      return LocationResult(
        errorMessage: 'Error: ${e.toString()}',
      );
    }
  }
}
