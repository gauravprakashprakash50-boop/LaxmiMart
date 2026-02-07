class AppException implements Exception {
  final String message;
  final String prefix;
  final int? statusCode;

  AppException(this.message, this.prefix, [this.statusCode]);

  @override
  String toString() {
    return '$prefix: $message';
  }
}

class NetworkException extends AppException {
  NetworkException(String message) : super(message, 'Network Error');
}

class ServerException extends AppException {
  ServerException(String message, [int? statusCode])
      : super(message, 'Server Error', statusCode);
}

class ValidationException extends AppException {
  ValidationException(String message) : super(message, 'Validation Error');
}

class CacheException extends AppException {
  CacheException(String message) : super(message, 'Cache Error');
}

class TimeoutException extends AppException {
  TimeoutException(String message) : super(message, 'Timeout Error');
}

class UnknownException extends AppException {
  UnknownException(String message) : super(message, 'Unknown Error');
}
