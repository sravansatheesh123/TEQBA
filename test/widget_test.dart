import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:machine_task/core/network/api_client.dart';
import 'package:machine_task/core/network/mock_api_interceptor.dart';
import 'package:machine_task/core/services/connectivity_service.dart';
import 'package:machine_task/core/services/sync_service.dart';
import 'package:machine_task/data/datasources/local/app_local_datasource.dart';
import 'package:machine_task/data/datasources/remote/app_remote_datasource.dart';
import 'package:machine_task/data/models/attendance_event_model.dart';
import 'package:machine_task/modules/dashboard/widgets/sync_banner_widget.dart';

// Fake Local DataSource for testing widget states without disk I/O
class FakeLocalDataSource implements AppLocalDataSource {
  int _pendingCount = 1;
  final List<AttendanceEventModel> _queue = [];

  void setPending(int count) {
    _pendingCount = count;
  }

  @override
  int get pendingEventsCount => _pendingCount;

  @override
  List<AttendanceEventModel> getQueuedEvents() => _queue;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('5. Widget test covering Pending Sync and Offline Banner state', (WidgetTester tester) async {
    Get.reset();

    final connectivityService = ConnectivityService();
    connectivityService.isOnline.value = true;
    Get.put<ConnectivityService>(connectivityService);

    final fakeLocal = FakeLocalDataSource();
    fakeLocal.setPending(3);

    final mockInterceptor = MockApiInterceptor();
    final apiClient = ApiClient(interceptor: mockInterceptor);
    final remoteDataSource = AppRemoteDataSource(apiClient);

    final syncService = SyncService(fakeLocal, remoteDataSource, connectivityService);
    syncService.pendingCount.value = 3;
    Get.put<SyncService>(syncService);

    // Build the SyncBannerWidget
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: SyncBannerWidget(),
        ),
      ),
    );

    // Verify Pending Sync state:
    // Should display text about 3 Pending Record(s) to Sync
    expect(find.text('3 Pending Record(s) to Sync'), findsOneWidget);
    // Should display the "Sync Now" button
    expect(find.text('Sync Now'), findsOneWidget);

    // Now test Offline state
    connectivityService.isOnline.value = false;
    await tester.pumpAndSettle();

    // Verify Offline state:
    expect(find.text('Offline Workspace Active'), findsOneWidget);
  });
}
