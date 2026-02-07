import 'package:flutter/material.dart';
import '../core/exceptions/app_exceptions.dart';

class AppError {
  final String title;
  final String message;
  final ErrorType type;
  final VoidCallback? onRetry;

  AppError({
    required this.title,
    required this.message,
    this.type = ErrorType.general,
    this.onRetry,
  });

  factory AppError.networkError({VoidCallback? onRetry}) {
    return AppError(
      title: "No Internet Connection",
      message: "Please check your internet connection and try again.",
      type: ErrorType.network,
      onRetry: onRetry,
    );
  }

  factory AppError.serverError({VoidCallback? onRetry}) {
    return AppError(
      title: "Server Error",
      message: "Our servers are experiencing issues. Please try again later.",
      type: ErrorType.server,
      onRetry: onRetry,
    );
  }

  factory AppError.noDataError({VoidCallback? onRetry}) {
    return AppError(
      title: "No Products Available",
      message: "No products found at the moment. Please check back later.",
      type: ErrorType.noData,
      onRetry: onRetry,
    );
  }

  factory AppError.generalError(dynamic error, {VoidCallback? onRetry}) {
    return AppError(
      title: "Something went wrong",
      message: "An unexpected error occurred. Please try again.",
      type: ErrorType.general,
      onRetry: onRetry,
    );
  }
}

enum ErrorType {
  network,
  server,
  noData,
  general,
}

class ErrorHandler {
  static AppError handleError(dynamic error, {VoidCallback? onRetry}) {
    if (error is NetworkException ||
        error.toString().contains('SocketException') ||
        error.toString().contains('Connection') ||
        error.toString().contains('Network')) {
      return AppError.networkError(onRetry: onRetry);
    }

    if (error is ServerException ||
        error.toString().contains('500') ||
        error.toString().contains('Internal Server Error')) {
      return AppError.serverError(onRetry: onRetry);
    }

    if (error is ValidationException) {
      return AppError(
        title: "Validation Error",
        message: error.message,
        type: ErrorType.general,
        onRetry: onRetry,
      );
    }

    return AppError.generalError(error, onRetry: onRetry);
  }

  static void showErrorSnackBar(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(error.type),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    error.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    error.message,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _getErrorColor(error.type),
        duration: const Duration(seconds: 4),
        action: error.onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  error.onRetry?.call();
                },
              )
            : SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
      ),
    );
  }

  static Widget buildErrorWidget({
    required AppError error,
    double? maxWidth,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? 300),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getErrorIcon(error.type),
                size: 64,
                color: _getErrorColor(error.type),
              ),
              const SizedBox(height: 16),
              Text(
                error.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              if (error.onRetry != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: error.onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.server:
        return Colors.red;
      case ErrorType.noData:
        return Colors.blue;
      case ErrorType.general:
        return Colors.grey[700]!;
    }
  }

  static IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.server:
        return Icons.error_outline;
      case ErrorType.noData:
        return Icons.inbox_outlined;
      case ErrorType.general:
        return Icons.error_outline;
    }
  }
}
