import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../data/datasources/local/app_local_datasource.dart';
import '../../data/datasources/remote/app_remote_datasource.dart';
import '../../data/models/attendance_event_model.dart';
import 'connectivity_service.dart';

class SyncResult {
  final int totalProcessed;
  final int syncedCount;
  final int failedCount;
  final String message;

  SyncResult({
    required this.totalProcessed,
    required this.syncedCount,
    required this.failedCount,
    required this.message,
  });
}

class SyncService extends GetxService {
  final AppLocalDataSource _localDataSource;
  final AppRemoteDataSource _remoteDataSource;
  final ConnectivityService _connectivityService;

  final RxBool isSyncing = false.obs;
  final RxInt pendingCount = 0.obs;
  final RxString lastSyncMessage = ''.obs;
  final Rx<DateTime?> lastSyncTime = Rx<DateTime?>(null);

  // Observable callback for UI to refresh after sync
  final RxInt syncVersion = 0.obs;

  SyncService(
    this._localDataSource,
    this._remoteDataSource,
    this._connectivityService,
  );

  @override
  void onInit() {
    super.onInit();
    _updatePendingCount();

    // Hook auto-sync when network returns
    _connectivityService.onConnectionRestored = () {
      if (pendingCount.value > 0) {
        syncPendingQueue();
      }
    };
  }

  void _updatePendingCount() {
    pendingCount.value = _localDataSource.pendingEventsCount;
  }

  /// Synchronizes all pending events sequentially (FIFO order)
  Future<SyncResult> syncPendingQueue() async {
    if (isSyncing.value) {
      return SyncResult(
        totalProcessed: 0,
        syncedCount: 0,
        failedCount: 0,
        message: 'Sync already in progress.',
      );
    }

    _updatePendingCount();
    if (pendingCount.value == 0) {
      return SyncResult(
        totalProcessed: 0,
        syncedCount: 0,
        failedCount: 0,
        message: 'All records are up to date.',
      );
    }

    if (!_connectivityService.isOnline.value) {
      return SyncResult(
        totalProcessed: 0,
        syncedCount: 0,
        failedCount: pendingCount.value,
        message: 'Cannot sync: Device is offline.',
      );
    }

    isSyncing.value = true;
    lastSyncMessage.value = 'Synchronizing pending records...';

    int synced = 0;
    int failed = 0;

    // Get FIFO sorted queue (check-in comes before check-out)
    final queue = _localDataSource.getQueuedEvents();

    for (final event in queue) {
      final dateStr = DateFormat('yyyy-MM-dd').format(event.timestamp);

      try {
        // Send event to server with its unique eventId (Idempotent endpoint)
        await _remoteDataSource.postAttendanceEvent(event);

        // Success (200 / 201)
        await _localDataSource.removeQueuedEvent(event.eventId);
        synced++;

        // Update local daily record status
        final existingRecord = _localDataSource.getAttendanceRecordForDate(dateStr);
        if (existingRecord != null) {
          final updated = existingRecord.copyWith(
            syncStatus: SyncStatus.synced,
            rejectionReason: null,
          );
          await _localDataSource.saveOrUpdateAttendanceRecord(updated);
        }
      } on DioException catch (dioErr) {
        final statusCode = dioErr.response?.statusCode;

        // Case 1: 409 Conflict (Attendance already exists on server)
        if (statusCode == 409) {
          // Reconcile: Server already has this attendance or marked today.
          // We remove from queue and mark local record as Synced (or reconciled)
          await _localDataSource.removeQueuedEvent(event.eventId);
          synced++;

          final existingRecord = _localDataSource.getAttendanceRecordForDate(dateStr);
          if (existingRecord != null) {
            final updated = existingRecord.copyWith(
              syncStatus: SyncStatus.synced,
            );
            await _localDataSource.saveOrUpdateAttendanceRecord(updated);
          }
        }
        // Case 2: Permanent client error (e.g. 400 Bad Request, check-out without check-in)
        else if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          final errorMsg = dioErr.response?.data?['message'] ?? 'Rejected by server policy';
          await _localDataSource.removeQueuedEvent(event.eventId);
          failed++;

          final existingRecord = _localDataSource.getAttendanceRecordForDate(dateStr);
          if (existingRecord != null) {
            final updated = existingRecord.copyWith(
              syncStatus: SyncStatus.rejected,
              rejectionReason: errorMsg.toString(),
            );
            await _localDataSource.saveOrUpdateAttendanceRecord(updated);
          }
        }
        // Case 3: Transient error (Timeout / 500 Server Error / Network Disconnect)
        else {
          failed++;
          final updatedEvent = event.copyWith(
            retryCount: event.retryCount + 1,
            rejectionReason: 'Network error or timeout: Retrying later',
          );
          await _localDataSource.updateQueuedEvent(updatedEvent);

          // Stop processing remainder to preserve FIFO ordering!
          break;
        }
      } catch (e) {
        failed++;
        break;
      }
    }

    _updatePendingCount();
    isSyncing.value = false;
    lastSyncTime.value = DateTime.now();
    syncVersion.value++;

    final resultMessage = synced > 0
        ? 'Successfully synchronized $synced event(s).'
        : (failed > 0 ? 'Sync incomplete. Retrying on next connection.' : 'Synced.');

    lastSyncMessage.value = resultMessage;

    return SyncResult(
      totalProcessed: synced + failed,
      syncedCount: synced,
      failedCount: failed,
      message: resultMessage,
    );
  }
}
