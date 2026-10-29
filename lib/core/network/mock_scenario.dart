enum MockScenario {
  success,
  slowResponse,
  timeout,
  serverError,
  duplicateConflict,
  leaveRejected,
}

extension MockScenarioExtension on MockScenario {
  String get displayName {
    switch (this) {
      case MockScenario.success:
        return 'Normal (200 OK)';
      case MockScenario.slowResponse:
        return 'Slow Network (3.5s delay)';
      case MockScenario.timeout:
        return 'Timeout Error (Simulated)';
      case MockScenario.serverError:
        return 'Server Error (500)';
      case MockScenario.duplicateConflict:
        return 'Duplicate Attendance (409)';
      case MockScenario.leaveRejected:
        return 'Leave Validation Rejection (422)';
    }
  }

  String get description {
    switch (this) {
      case MockScenario.success:
        return 'API calls complete normally with valid responses.';
      case MockScenario.slowResponse:
        return 'Simulates slow 3G/edge network with high latency.';
      case MockScenario.timeout:
        return 'Simulates connection timeout to test retry & offline handling.';
      case MockScenario.serverError:
        return 'Simulates 500 internal server crash.';
      case MockScenario.duplicateConflict:
        return 'Simulates 409 Conflict when event is already recorded.';
      case MockScenario.leaveRejected:
        return 'Simulates server policy rejection on leave submission.';
    }
  }
}
