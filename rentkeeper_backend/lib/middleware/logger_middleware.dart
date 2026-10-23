import 'dart:io';

class LoggerMiddleware {
  static void logRequest(HttpRequest request, int statusCode, int durationMs) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final method = request.method.padRight(6);
    final path = request.uri.path;
    final statusColor = statusCode >= 400 ? '!' : '*';

    print('[$timestamp] $statusColor $method $path -> $statusCode (${durationMs}ms)');
  }
}
