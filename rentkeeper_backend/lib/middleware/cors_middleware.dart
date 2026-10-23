import 'dart:io';

class CorsMiddleware {
  static void apply(HttpRequest request) {
    final res = request.response;
    res.headers.set('Access-Control-Allow-Origin', '*');
    res.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.headers.set('Access-Control-Allow-Headers', 'Origin, Content-Type, Authorization, Accept, X-Requested-With, X-Client-Version');
    res.headers.set('Access-Control-Max-Age', '86400');
  }

  static bool handlePreflight(HttpRequest request) {
    if (request.method == 'OPTIONS') {
      apply(request);
      request.response.statusCode = HttpStatus.noContent;
      request.response.close();
      return true;
    }
    return false;
  }
}
