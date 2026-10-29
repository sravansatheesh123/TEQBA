import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

enum LocationSimulationMode {
  realGps,
  atOffice, // 0m
  nearOffice, // 120m
  outsideOffice, // 350m
  homeLocation, // 12km
}

extension LocationSimulationModeExtension on LocationSimulationMode {
  String get title {
    switch (this) {
      case LocationSimulationMode.realGps:
        return 'Current Location (Device GPS)';
      case LocationSimulationMode.atOffice:
        return 'Office Desk (0m away - Valid)';
      case LocationSimulationMode.nearOffice:
        return 'Office Gate (120m away - Valid)';
      case LocationSimulationMode.outsideOffice:
        return 'Coffee Shop (350m away - Outside)';
      case LocationSimulationMode.homeLocation:
        return 'Home (12.5km away - Outside)';
    }
  }

  String get subtitle {
    switch (this) {
      case LocationSimulationMode.realGps:
        return 'Uses real hardware/emulator GPS coordinates';
      case LocationSimulationMode.atOffice:
        return 'At configured company office (< 200m)';
      case LocationSimulationMode.nearOffice:
        return 'Within office entrance (~120m)';
      case LocationSimulationMode.outsideOffice:
        return 'Simulated outside boundary (~350m)';
      case LocationSimulationMode.homeLocation:
        return 'Simulated far away (~12.5km)';
    }
  }
}

class LocationResult {
  final bool isSuccess;
  final double? latitude;
  final double? longitude;
  final double? distanceMeters;
  final bool isWithinGeofence;
  final String? errorMessage;
  final bool isPermissionDeniedForever;

  LocationResult({
    required this.isSuccess,
    this.latitude,
    this.longitude,
    this.distanceMeters,
    this.isWithinGeofence = false,
    this.errorMessage,
    this.isPermissionDeniedForever = false,
  });
}

class LocationService extends GetxService {
  final Rx<LocationSimulationMode> simulationMode = LocationSimulationMode.realGps.obs;

  // Active Company Office coordinates (observable so UI & controllers react immediately)
  final RxDouble currentOfficeLatitude = AppConstants.defaultOfficeLatitude.obs;
  final RxDouble currentOfficeLongitude = AppConstants.defaultOfficeLongitude.obs;
  final RxString currentOfficeName = AppConstants.defaultOfficeName.obs;
  final RxBool isCustomOfficeSaved = false.obs;

  // Default Office fallback constants
  static const double officeLat = AppConstants.defaultOfficeLatitude;
  static const double officeLng = AppConstants.defaultOfficeLongitude;

  @override
  void onInit() {
    super.onInit();
    loadSavedCompanyLocation();
  }

  void loadSavedCompanyLocation() {
    // Company office is strictly fixed in Bengaluru HQ
    currentOfficeLatitude.value = AppConstants.defaultOfficeLatitude;
    currentOfficeLongitude.value = AppConstants.defaultOfficeLongitude;
    currentOfficeName.value = AppConstants.defaultOfficeName;
    isCustomOfficeSaved.value = false;

    try {
      if (Get.isRegistered<StorageService>()) {
        final storage = Get.find<StorageService>();
        storage.saveSetting(AppConstants.keyCustomOfficeLat, null);
        storage.saveSetting(AppConstants.keyCustomOfficeLng, null);
        storage.saveSetting(AppConstants.keyCustomOfficeName, null);
      }
    } catch (_) {}
  }

  void setSimulationMode(LocationSimulationMode mode) {
    simulationMode.value = mode;
  }

  /// Office location is strictly fixed at Bengaluru HQ.
  Future<LocationResult> saveCurrentGpsAsCompanyLocation() async {
    // Company office is strictly fixed in Bengaluru HQ and cannot be altered
    currentOfficeLatitude.value = AppConstants.defaultOfficeLatitude;
    currentOfficeLongitude.value = AppConstants.defaultOfficeLongitude;
    currentOfficeName.value = AppConstants.defaultOfficeName;
    isCustomOfficeSaved.value = false;

    if (Get.isRegistered<StorageService>()) {
      final storage = Get.find<StorageService>();
      await storage.saveSetting(AppConstants.keyCustomOfficeLat, null);
      await storage.saveSetting(AppConstants.keyCustomOfficeLng, null);
      await storage.saveSetting(AppConstants.keyCustomOfficeName, null);
    }

    return LocationResult(
      isSuccess: true,
      latitude: AppConstants.defaultOfficeLatitude,
      longitude: AppConstants.defaultOfficeLongitude,
      distanceMeters: 0.0,
      isWithinGeofence: true,
    );
  }

  /// Restores Company Location back to the default Bengaluru HQ coordinates.
  Future<void> resetCompanyLocationToDefault() async {
    currentOfficeLatitude.value = AppConstants.defaultOfficeLatitude;
    currentOfficeLongitude.value = AppConstants.defaultOfficeLongitude;
    currentOfficeName.value = AppConstants.defaultOfficeName;
    isCustomOfficeSaved.value = false;

    if (Get.isRegistered<StorageService>()) {
      final storage = Get.find<StorageService>();
      await storage.saveSetting(AppConstants.keyCustomOfficeLat, null);
      await storage.saveSetting(AppConstants.keyCustomOfficeLng, null);
      await storage.saveSetting(AppConstants.keyCustomOfficeName, null);
    }
  }

  /// Retrieves the raw hardware or simulated position for Pickup Location.
  Future<LocationResult> getPickupLocation() async {
    if (simulationMode.value != LocationSimulationMode.realGps) {
      // In simulation mode, pickup location is simulated
      return getCurrentLocation();
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          isSuccess: false,
          errorMessage: 'Location services are disabled.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
            isSuccess: false,
            errorMessage: 'Location permission denied.',
          );
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final distance = calculateDistance(
        position.latitude,
        position.longitude,
        currentOfficeLatitude.value,
        currentOfficeLongitude.value,
      );

      return LocationResult(
        isSuccess: true,
        latitude: position.latitude,
        longitude: position.longitude,
        distanceMeters: distance,
        isWithinGeofence: distance <= AppConstants.maxAllowedDistanceMeters,
      );
    } catch (e) {
      return LocationResult(
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

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
    );
  }

  Future<LocationResult> getCurrentLocation({
    double? targetOfficeLat,
    double? targetOfficeLng,
    double maxRadius = AppConstants.maxAllowedDistanceMeters,
  }) async {
    final effectiveTargetLat = targetOfficeLat ?? currentOfficeLatitude.value;
    final effectiveTargetLng = targetOfficeLng ?? currentOfficeLongitude.value;

    // 1. If in simulation mode (recommended for testing & reviewers)
    if (simulationMode.value != LocationSimulationMode.realGps) {
      double lat = effectiveTargetLat;
      double lng = effectiveTargetLng;

      switch (simulationMode.value) {
        case LocationSimulationMode.atOffice:
          lat = effectiveTargetLat;
          lng = effectiveTargetLng;
          break;
        case LocationSimulationMode.nearOffice:
          // ~120m north-east
          lat = effectiveTargetLat + 0.0008;
          lng = effectiveTargetLng + 0.0007;
          break;
        case LocationSimulationMode.outsideOffice:
          // ~350m
          lat = effectiveTargetLat + 0.0025;
          lng = effectiveTargetLng + 0.0020;
          break;
        case LocationSimulationMode.homeLocation:
          // ~12km
          lat = effectiveTargetLat - 0.0800;
          lng = effectiveTargetLng - 0.0700;
          break;
        default:
          break;
      }

      final distance = calculateDistance(lat, lng, effectiveTargetLat, effectiveTargetLng);
      final isInside = distance <= maxRadius;

      return LocationResult(
        isSuccess: true,
        latitude: lat,
        longitude: lng,
        distanceMeters: distance,
        isWithinGeofence: isInside,
        errorMessage: isInside
            ? null
            : 'You are ${distance.round()}m away from the office. Check-in is permitted only within ${maxRadius.round()}m.',
      );
    }

    // 2. Real GPS Hardware retrieval
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          isSuccess: false,
          errorMessage: 'Location services are disabled. Please enable GPS in device settings.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
            isSuccess: false,
            errorMessage: 'Location permissions are denied. Please grant location access to mark attendance.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          isSuccess: false,
          isPermissionDeniedForever: true,
          errorMessage: 'Location permissions are permanently denied. Please enable them in app settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final distance = calculateDistance(
        position.latitude,
        position.longitude,
        effectiveTargetLat,
        effectiveTargetLng,
      );

      final isInside = distance <= maxRadius;

      return LocationResult(
        isSuccess: true,
        latitude: position.latitude,
        longitude: position.longitude,
        distanceMeters: distance,
        isWithinGeofence: isInside,
        errorMessage: isInside
            ? null
            : 'You are ${distance.round()}m away from the office. Check-in is permitted only within ${maxRadius.round()}m.',
      );
    } catch (e) {
      return LocationResult(
        isSuccess: false,
        errorMessage: 'Failed to retrieve GPS location: ${e.toString()}',
      );
    }
  }
}
