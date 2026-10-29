import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../app/theme/app_colors.dart';

class SyncBannerWidget extends StatelessWidget {
  const SyncBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivity = Get.find<ConnectivityService>();
    final syncService = Get.find<SyncService>();

    return Obx(() {
      final isOnline = connectivity.isOnline.value;
      final pendingCount = syncService.pendingCount.value;
      final isSyncing = syncService.isSyncing.value;

      if (isOnline && pendingCount == 0) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: !isOnline ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: !isOnline ? const Color(0xFFFCA5A5) : const Color(0xFFFDE68A),
          ),
        ),
        child: Row(
          children: [
            Icon(
              !isOnline ? Icons.cloud_off_rounded : Icons.sync_problem_rounded,
              color: !isOnline ? AppColors.errorRed : AppColors.checkOutAmber,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    !isOnline ? 'Offline Workspace Active' : '$pendingCount Pending Record(s) to Sync',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: !isOnline ? AppColors.errorRed : const Color(0xFF92400E),
                    ),
                  ),
                  Text(
                    !isOnline
                        ? 'Attendance actions will be saved locally and synced once online.'
                        : 'Local attendance saved. Tap Sync Now to commit to server.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            if (pendingCount > 0 && isOnline)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: isSyncing
                    ? null
                    : () async {
                        await syncService.syncPendingQueue();
                      },
                child: isSyncing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Sync Now', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      );
    });
  }
}
