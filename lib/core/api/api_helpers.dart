import 'package:dio/dio.dart';

class ApiError implements Exception {
  final int? status;
  final String message;
  final dynamic data;

  ApiError({this.status, required this.message, this.data});

  @override
  String toString() => 'ApiError(status: $status, message: $message)';
}

ApiError dioToApiError(DioException e) {
  if (e.response != null) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    // try extract message
    String msg = 'HTTP $status';
    if (data is Map) {
      if (data['message'] != null)
        msg = data['message'].toString();
      else if (data['error'] != null)
        msg = data['error'].toString();
      else if (data['detail'] != null) msg = data['detail'].toString();
    } else if (data is String && data.isNotEmpty) {
      msg = data;
    }

    return ApiError(status: status, message: msg, data: data);
  }

  // no response: timeout / refused / DNS
  return ApiError(
    status: null,
    message: '${e.type} • ${e.message ?? "Network error"}',
    data: null,
  );
}
