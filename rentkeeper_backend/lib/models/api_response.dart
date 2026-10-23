import 'dart:convert';

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? message;
  final dynamic error;
  final String timestamp;
  final Map<String, dynamic>? meta;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.meta,
    String? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toUtc().toIso8601String();

  factory ApiResponse.success(dynamic data, {String? message, Map<String, dynamic>? meta}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      meta: meta,
    );
  }

  factory ApiResponse.error(dynamic error, {String? message, int? statusCode}) {
    return ApiResponse(
      success: false,
      error: error,
      message: message ?? 'An error occurred',
      meta: statusCode != null ? {'statusCode': statusCode} : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      if (data != null) 'data': data,
      if (message != null) 'message': message,
      if (error != null) 'error': error,
      'timestamp': timestamp,
      if (meta != null) 'meta': meta,
    };
  }

  String toJson() => jsonEncode(toMap());
}
