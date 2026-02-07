import 'package:flutter/material.dart';
import '../services/error_handler.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;

  const LoadingWidget({super.key, this.message, this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? 40,
            height: size ?? 40,
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD32F2F)),
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorDisplayWidget extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final double? maxWidth;

  const ErrorDisplayWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorHandler.buildErrorWidget(
      error: error,
      maxWidth: maxWidth,
    );
  }
}
