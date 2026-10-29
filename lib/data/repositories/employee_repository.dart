import '../datasources/local/app_local_datasource.dart';
import '../datasources/remote/app_remote_datasource.dart';
import '../models/employee_model.dart';

class EmployeeRepository {
  final AppLocalDataSource _localDataSource;
  final AppRemoteDataSource _remoteDataSource;

  EmployeeRepository(this._localDataSource, this._remoteDataSource);

  Future<EmployeeModel> getEmployeeProfile({bool forceRefresh = false}) async {
    // 1. Check local cache first if not forced
    final cached = _localDataSource.getCachedEmployee();
    if (cached != null && !forceRefresh) {
      // Background refresh can happen asynchronously
      _refreshInBackground();
      return cached;
    }

    try {
      final remote = await _remoteDataSource.getEmployee();
      await _localDataSource.cacheEmployee(remote);
      return remote;
    } catch (_) {
      if (cached != null) return cached;
      final fallback = EmployeeModel.defaultEmployee();
      await _localDataSource.cacheEmployee(fallback);
      return fallback;
    }
  }

  void _refreshInBackground() async {
    try {
      final remote = await _remoteDataSource.getEmployee();
      await _localDataSource.cacheEmployee(remote);
    } catch (_) {}
  }
}
