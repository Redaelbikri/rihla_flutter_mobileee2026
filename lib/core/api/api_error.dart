class ApiError implements Exception {
  final String message;
  final int? status;

  ApiError(this.message, {this.status});

  @override
  String toString() => 'ApiError(status: $status, message: $message)';
}
