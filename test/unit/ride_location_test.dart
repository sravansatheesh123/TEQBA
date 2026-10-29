import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:machine_task/core/constants/app_constants.dart';
import 'package:machine_task/core/services/location_service.dart';
import 'package:machine_task/core/services/storage_service.dart';

void main() {
  late Directory tempDir;
  late StorageService storageService;
  late LocationService locationService;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Get.reset();

    tempDir = Directory.systemTemp.createTempSync('company_location_test_');
    storageService = StorageService();
    await storageService.init(customPath: tempDir.path);
    Get.put<StorageService>(storageService);

    locationService = LocationService();
    Get.put<LocationService>(locationService);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
    Get.reset();
  });

  group('Company Location Customization & Persistence Tests', () {
    test('Default office location matches Bengaluru HQ', () {
      expect(locationService.currentOfficeLatitude.value, AppConstants.defaultOfficeLatitude);
      expect(locationService.currentOfficeLongitude.value, AppConstants.defaultOfficeLongitude);
      expect(locationService.isCustomOfficeSaved.value, false);
    });

    test('Company office location is strictly fixed in Bengaluru HQ and cannot be altered', () async {
      // User requested: office location must NOT change and stays permanently fixed in Bengaluru HQ
      locationService.loadSavedCompanyLocation();

      expect(locationService.currentOfficeLatitude.value, AppConstants.defaultOfficeLatitude);
      expect(locationService.currentOfficeLongitude.value, AppConstants.defaultOfficeLongitude);
      expect(locationService.currentOfficeName.value, AppConstants.defaultOfficeName);
      expect(locationService.isCustomOfficeSaved.value, false);

      // Verify that resetting also maintains default Bengaluru HQ
      await locationService.resetCompanyLocationToDefault();
      expect(locationService.currentOfficeLatitude.value, AppConstants.defaultOfficeLatitude);
      expect(locationService.currentOfficeLongitude.value, AppConstants.defaultOfficeLongitude);
      expect(locationService.isCustomOfficeSaved.value, false);
      expect(storageService.getSetting(AppConstants.keyCustomOfficeLat), isNull);
    });

    test('Simulation modes evaluate geofence against the active company location', () async {
      locationService.setSimulationMode(LocationSimulationMode.atOffice);
      final atOfficeResult = await locationService.getCurrentLocation();
      expect(atOfficeResult.isWithinGeofence, true);
      expect(atOfficeResult.distanceMeters, 0.0);

      locationService.setSimulationMode(LocationSimulationMode.outsideOffice);
      final outsideResult = await locationService.getCurrentLocation();
      expect(outsideResult.isWithinGeofence, false);
      expect(outsideResult.distanceMeters! > 200, true);
    });

    test('Pickup location acquires valid device coordinates for location card', () async {
      locationService.setSimulationMode(LocationSimulationMode.nearOffice);
      final pickupResult = await locationService.getPickupLocation();
      expect(pickupResult.isSuccess, true);
      expect(pickupResult.latitude, isNotNull);
      expect(pickupResult.longitude, isNotNull);
      expect(pickupResult.isWithinGeofence, true);
    });
  });
}
