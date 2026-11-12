
import 'dart:io';

// Backend HTTP port
const int kApiHttpPort = 5137;

// Your PC's IP address on Wi-Fi
const String? kAndroidLanOverride = 'http://10.106.94.90:5137';

// Backend base URL
String get apiBaseUrl {
  const fromEnv = String.fromEnvironment('API_BASE_URL');

  if (fromEnv.isNotEmpty) {
    return fromEnv.replaceAll(RegExp(r'/+$'), '');
  }

  final lan = kAndroidLanOverride?.trim();

  if (lan != null && lan.isNotEmpty) {
    return lan.replaceAll(RegExp(r'/+$'), '');
  }

  if (Platform.isAndroid) {
    return 'http://127.0.0.1:$kApiHttpPort';
  }

  return 'http://localhost:$kApiHttpPort';
}

// Build complete API URL.
// Example:
// Student/upload-course-content
// becomes:
// http://10.106.94.90:5254/api/Student/upload-course-content
String buildApiUrl(String endpoint) {
  String baseUrl = apiBaseUrl.trim();

  baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');

  String path = endpoint.trim();

  path = path.replaceAll(RegExp(r'^/+'), '');

  if (!baseUrl.toLowerCase().endsWith('/api')) {
    baseUrl = '$baseUrl/api';
  }

  return '$baseUrl/$path';
}



















// import 'dart:io';

// /// HTTP port your API listens on (`launchSettings.json` → `http` profile).
// const int kApiHttpPort = 5254;

// /// Physical phone on **Wi‑Fi** — your PC's local IP from `ipconfig`.
// /// Leave as `null` and use `adb reverse` instead if you prefer USB-only setup.
// //const String? kAndroidLanOverride = 'http://192.168.137.1:5254';
// const String? kAndroidLanOverride = 'http://10.106.94.90:5254';//mymobile 
// /// Backend base URL (no trailing slash).
// ///
// /// **Wi‑Fi setup (current):**
// /// Phone and PC must be on the same Wi‑Fi network. [kAndroidLanOverride] points
// /// directly at the PC's IP, so no `adb reverse` or cable is needed.
// ///
// /// **Override:** `flutter run --dart-define=API_BASE_URL=http://...`
// String get apiBaseUrl {
//   const fromEnv = String.fromEnvironment('API_BASE_URL');
//   if (fromEnv.isNotEmpty) {
//     return fromEnv.replaceAll(RegExp(r'/$'), '');
//   }

//   final lan = kAndroidLanOverride?.trim();
//   if (lan != null && lan.isNotEmpty) {
//     return lan.replaceAll(RegExp(r'/$'), '');
//   }

//   if (Platform.isAndroid) {
//     return 'http://127.0.0.1:$kApiHttpPort';
//   }
//   return 'http://localhost:$kApiHttpPort';
// }