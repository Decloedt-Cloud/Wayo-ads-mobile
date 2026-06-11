import 'package:dio/dio.dart';

import 'maintenance_service.dart';

/// Flags global maintenance when Wayo API responses look like platform downtime.
class MaintenanceInterceptor extends Interceptor {
  MaintenanceInterceptor(this._service);

  final MaintenanceService _service;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (responseIndicatesMaintenance(response)) {
      _service.enterMaintenance();
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (dioExceptionIndicatesMaintenance(err)) {
      _service.enterMaintenance();
    }
    handler.next(err);
  }
}
