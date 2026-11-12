import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:house_of_tutor/services/api_config.dart';
import 'package:house_of_tutor/services/auth_store.dart';

class ApiClient {
  ApiClient._();

  // =====================================================
  // URI
  // =====================================================

  static Uri _uri(String path) {
    final base = apiBaseUrl;

    final p = path.startsWith('/') ? path : '/$path';

    return Uri.parse('$base$p');
  }

  // =====================================================
  // HEADERS
  // =====================================================

  static Future<Map<String, String>> _headers({
    bool withAuth = true,
    Map<String, String>? extraHeaders,
  }) async {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth) {
      await AuthStore.instance.hydrate();

      final t = AuthStore.instance.token;

      if (t != null && t.isNotEmpty) {
        h['Authorization'] = 'Bearer $t';
      }
    }

    if (extraHeaders != null) {
      h.addAll(extraHeaders);
    }

    return h;
  }

  // =====================================================
  // GET
  // =====================================================

  static Future<http.Response> get(
    String path, {
    bool auth = true,
  }) async {
    try {
      final uri = _uri(path);

      final headers =
          await _headers(withAuth: auth);

      // Helpful for debugging
      print('GET Request: $uri');
      print('Headers: $headers');

      final res =
          await http.get(
        uri,
        headers: headers,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          return http.Response(
            '{"message": "Connection timed out. Please try again."}',
            408,
          );
        },
      );

      print(
        'Response Code: ${res.statusCode}',
      );

      print(
        'Response Body: ${res.body}',
      );

      return res;
    } catch (e) {
      print('GET Error: $e');

      return http.Response(
        '{"message": "Network error occurred: $e"}',
        500,
      );
    }
  }

  // =====================================================
  // POST
  // =====================================================

  static Future<http.Response> post(
    String path,
    Object? jsonBody, {
    bool auth = true,
    Map<String, String>? headers,
  }) async {
    try {
      final body =
          jsonBody == null
              ? null
              : jsonEncode(jsonBody);

      return await http.post(
        _uri(path),
        headers: await _headers(
          withAuth: auth,
          extraHeaders: headers,
        ),
        body: body,
      );
    } catch (e) {
      print('POST Error: $e');

      return http.Response(
        '{"message": "Network error occurred: $e"}',
        500,
      );
    }
  }

  // =====================================================
  // PUT
  // =====================================================

  static Future<http.Response> put(
    String path,
    Object? jsonBody, {
    bool auth = true,
    Map<String, String>? headers,
  }) async {
    try {
      final encodedBody =
          jsonBody == null
              ? null
              : jsonEncode(jsonBody);

      return await http.put(
        _uri(path),
        headers: await _headers(
          withAuth: auth,
          extraHeaders: headers,
        ),
        body: encodedBody,
      );
    } catch (e) {
      print('PUT Error: $e');

      return http.Response(
        '{"message": "Network error occurred: $e"}',
        500,
      );
    }
  }

  // =====================================================
  // DELETE
  // =====================================================

  static Future<http.Response> delete(
    String path, {
    bool auth = true,
    Map<String, String>? headers,
  }) async {
    try {
      return await http.delete(
        _uri(path),
        headers: await _headers(
          withAuth: auth,
          extraHeaders: headers,
        ),
      );
    } catch (e) {
      print('DELETE Error: $e');

      return http.Response(
        '{"message": "Network error occurred: $e"}',
        500,
      );
    }
  }

  // =====================================================
  // UPLOAD FILE
  //
  // IMPORTANT:
  // This method uses multipart/form-data.
  //
  // Use this for:
  // PDF
  // DOC
  // DOCX
  // JPG
  // JPEG
  // PNG
  //
  // Example backend:
  //
  // [HttpPost("upload-course-content")]
  // public async Task<IActionResult> UploadCourseContent(
  //     [FromForm] int course_id,
  //     [FromForm] string title,
  //     [FromForm] string description,
  //     [FromForm] IFormFile file)
  //
  // =====================================================

  static Future<http.Response> uploadFile(
    String path, {
    required File file,
    required Map<String, String> fields,
    String fileFieldName = 'file',
    bool auth = true,
  }) async {
    try {
      // ---------------------------------------------------
      // 1. CREATE MULTIPART REQUEST
      // ---------------------------------------------------

      final request =
          http.MultipartRequest(
        'POST',
        _uri(path),
      );

      // ---------------------------------------------------
      // 2. AUTHORIZATION TOKEN
      // ---------------------------------------------------

      if (auth) {
        await AuthStore.instance.hydrate();

        final token =
            AuthStore.instance.token;

        if (token != null &&
            token.isNotEmpty) {
          request.headers['Authorization'] =
              'Bearer $token';
        }
      }

      // ---------------------------------------------------
      // 3. ACCEPT JSON RESPONSE
      //
      // DO NOT manually add:
      //
      // Content-Type: multipart/form-data
      //
      // MultipartRequest automatically creates the
      // correct boundary.
      // ---------------------------------------------------

      request.headers['Accept'] =
          'application/json';

      // ---------------------------------------------------
      // 4. ADD FORM FIELDS
      // ---------------------------------------------------

      request.fields.addAll(fields);

      // ---------------------------------------------------
      // 5. ADD FILE
      // ---------------------------------------------------

      final multipartFile =
          await http.MultipartFile.fromPath(
        fileFieldName,
        file.path,
      );

      request.files.add(
        multipartFile,
      );

      // ---------------------------------------------------
      // DEBUG
      // ---------------------------------------------------

      print(
        '========================================',
      );

      print(
        'UPLOAD FILE REQUEST',
      );

      print(
        'URL: ${request.url}',
      );

      print(
        'Fields: ${request.fields}',
      );

      print(
        'File Field: $fileFieldName',
      );

      print(
        'File Path: ${file.path}',
      );

      print(
        '========================================',
      );

      // ---------------------------------------------------
      // 6. SEND REQUEST
      // ---------------------------------------------------

      final streamedResponse =
          await request.send().timeout(
        const Duration(seconds: 60),
      );

      // ---------------------------------------------------
      // 7. CONVERT STREAMED RESPONSE TO NORMAL RESPONSE
      // ---------------------------------------------------

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      // ---------------------------------------------------
      // DEBUG RESPONSE
      // ---------------------------------------------------

      print(
        'Upload Response Code: '
        '${response.statusCode}',
      );

      print(
        'Upload Response Body: '
        '${response.body}',
      );

      return response;
    } on SocketException catch (e) {
      print(
        'Upload Socket Error: $e',
      );

      return http.Response(
        jsonEncode({
          'message':
              'Network error. Please check your internet connection.',
        }),
        500,
      );
    } on http.ClientException catch (e) {
      print(
        'Upload Client Error: $e',
      );

      return http.Response(
        jsonEncode({
          'message':
              'Could not connect to the server.',
        }),
        500,
      );
    } catch (e) {
      print(
        'Upload File Error: $e',
      );

      return http.Response(
        jsonEncode({
          'message':
              'File upload failed: $e',
        }),
        500,
      );
    }
  }

  // =====================================================
  // DECODE JSON
  // =====================================================

  static Future<dynamic> decodeJson(
    http.Response r,
  ) async {
    if (r.body.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(
        utf8.decode(
          r.bodyBytes,
        ),
      );
    } catch (e) {
      print(
        'JSON Decode Error: $e',
      );

      return null;
    }
  }

  static String get baseUrlForFiles {
    return apiBaseUrl;
  }
  // =====================================================
  // MESSAGE
  // =====================================================

  static String? messageFromBody(
    String body,
  ) {
    try {
      final m = jsonDecode(body);

      if (m is! Map) {
        return null;
      }

      if (m['message'] != null) {
        return m['message'].toString();
      }

      if (m['title'] != null) {
        return m['title'].toString();
      }

      if (m['detail'] != null) {
        return m['detail'].toString();
      }
    } catch (_) {}

    return null;
  }

  // =====================================================
// GET TUTOR -> STUDENT COURSE CONTENT
// =====================================================

  Future<Map<String, dynamic>> getTutorCourseContent({
    required int studentId,
    required int courseId,
  }) async {
    final response = await get(
      '/Tutor/tutor-course-content/$studentId/$courseId',
    );

    return jsonDecode(response.body);
  }
}





























// import 'dart:convert';

// import 'package:http/http.dart' as http;

// import 'package:house_of_tutor/services/api_config.dart';
// import 'package:house_of_tutor/services/auth_store.dart';

// class ApiClient {
//   ApiClient._();

//   // =====================================================
//   // URI
//   // =====================================================

//   static Uri _uri(String path) {
//     final base = apiBaseUrl;

//     final p = path.startsWith('/') ? path : '/$path';

//     return Uri.parse('$base$p');
//   }

//   // =====================================================
//   // HEADERS
//   // =====================================================

//   static Future<Map<String, String>> _headers({
//     bool withAuth = true,
//     Map<String, String>? extraHeaders,
//   }) async {
//     final h = <String, String>{
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//     };

//     if (withAuth) {
//       await AuthStore.instance.hydrate();

//       final t = AuthStore.instance.token;

//       if (t != null && t.isNotEmpty) {
//         h['Authorization'] = 'Bearer $t';
//       }
//     }

//     if (extraHeaders != null) {
//       h.addAll(extraHeaders);
//     }

//     return h;
//   }

//   // =====================================================
//   // GET
//   // =====================================================
// static Future<http.Response> get(String path, {bool auth = true}) async {
//   try {
//     final uri = _uri(path);
//     final headers = await _headers(withAuth: auth);

//     // Helpful for debugging network calls and headers
//     print('GET Request: $uri');
//     print('Headers: $headers');

//     final res = await http.get(uri, headers: headers).timeout(
//       const Duration(seconds: 15),
//       onTimeout: () {
//         return http.Response('{"message": "Connection timed out. Please try again."}', 408);
//       },
//     );

//     print('Response Code: ${res.statusCode}');
//     print('Response Body: ${res.body}');

//     return res;
//   } catch (e) {
//     print('GET Error: $e');
//     // Return a structured error response instead of letting the app crash unhandled
//     return http.Response('{"message": "Network error occurred: $e"}', 500);
//   }
// }
//   // static Future<http.Response> get(String path, {bool auth = true}) async {
//   //   final res = await http.get(_uri(path), headers: await _headers(withAuth: auth));

//   //   return res;
//   // }

//   // =====================================================
//   // POST
//   // =====================================================

//   static Future<http.Response> post(
//     String path,
//     Object? jsonBody, {
//     bool auth = true,
//     Map<String, String>? headers,
//   }) async {
//     final body = jsonBody == null ? null : jsonEncode(jsonBody);

//     return await http.post(
//       _uri(path),
//       headers: await _headers(withAuth: auth, extraHeaders: headers),
//       body: body,
//     );
//   }

//   // =====================================================
//   // PUT
//   // =====================================================

//   static Future<http.Response> put(
//     String path,
//     Object? jsonBody, {
//     bool auth = true,
//     Map<String, String>? headers,
//   }) async {
//     final encodedBody = jsonBody == null ? null : jsonEncode(jsonBody);

//     return await http.put(
//       _uri(path),
//       headers: await _headers(withAuth: auth, extraHeaders: headers),
//       body: encodedBody,
//     );
//   }

//   // =====================================================
//   // DELETE
//   // =====================================================

//   static Future<http.Response> delete(
//     String path, {
//     bool auth = true,
//     Map<String, String>? headers,
//   }) async {
//     return await http.delete(
//       _uri(path),
//       headers: await _headers(withAuth: auth, extraHeaders: headers),
//     );
//   }

//   // =====================================================
//   // DECODE JSON
//   // =====================================================

//   static Future<dynamic> decodeJson(http.Response r) async {
//     if (r.body.isEmpty) {
//       return null;
//     }

//     return jsonDecode(utf8.decode(r.bodyBytes));
//   }

//   // =====================================================
//   // MESSAGE
//   // =====================================================

//   static String? messageFromBody(String body) {
//     try {
//       final m = jsonDecode(body);

//       if (m is! Map) {
//         return null;
//       }

//       if (m['message'] != null) {
//         return m['message'].toString();
//       }

//       if (m['title'] != null) {
//         return m['title'].toString();
//       }

//       if (m['detail'] != null) {
//         return m['detail'].toString();
//       }
//     } catch (_) {}

//     return null;
//   }
// }














// // import 'dart:convert';

// // import 'package:http/http.dart' as http;

// // import 'package:house_of_tutor/services/api_config.dart';
// // import 'package:house_of_tutor/services/auth_store.dart';

// // class ApiClient {
// //   ApiClient._();

// //   // =====================================================
// //   // URI
// //   // =====================================================

// //   static Uri _uri(String path) {
// //     final base = apiBaseUrl;

// //     final p = path.startsWith('/') ? path : '/$path';

// //     return Uri.parse('$base$p');
// //   }

// //   // =====================================================
// //   // HEADERS
// //   // =====================================================

// //   static Future<Map<String, String>> _headers({
// //     bool withAuth = true,
// //     Map<String, String>? extraHeaders,
// //   }) async {
// //     final h = <String, String>{
// //       'Content-Type': 'application/json',
// //       'Accept': 'application/json',
// //     };

// //     if (withAuth) {
// //       await AuthStore.instance.hydrate();

// //       final t = AuthStore.instance.token;

// //       if (t != null && t.isNotEmpty) {
// //         h['Authorization'] = 'Bearer $t';
// //       }
// //     }

// //     if (extraHeaders != null) {
// //       h.addAll(extraHeaders);
// //     }

// //     return h;
// //   }

// //   // =====================================================
// //   // GET
// //   // =====================================================

// //   static Future<http.Response> get(String path, {bool auth = true}) async {
// //     final res = await http.get(_uri(path), headers: await _headers(withAuth: auth));

// //     return res;
// //   }

// //   // =====================================================
// //   // POST
// //   // =====================================================

// //   static Future<http.Response> post(
// //     String path,
// //     Object? jsonBody, {
// //     bool auth = true,
// //     Map<String, String>? headers,
// //   }) async {
// //     final body = jsonBody == null ? null : jsonEncode(jsonBody);

// //     return await http.post(
// //       _uri(path),
// //       headers: await _headers(withAuth: auth, extraHeaders: headers),
// //       body: body,
// //     );
// //   }
// //   // =====================================================
// //   // PUT
// //   // =====================================================

// //   static Future<http.Response> put(
// //     String path,
// //     Object? jsonBody, {
// //     bool auth = true,
// //     Map<String, String>? headers,
// //   }) async {
// //     final encodedBody = jsonBody == null ? null : jsonEncode(jsonBody);

// //     return await http.put(
// //       _uri(path),
// //       headers: await _headers(withAuth: auth, extraHeaders: headers),
// //       body: encodedBody,
// //     );
// //   }
// //   // // =====================================================
// //   // // PUT
// //   // // =====================================================

// //   // static Future<http.Response> put(
// //   //   String path,
// //   //   Object? jsonBody, {
// //   //   bool auth = true,
// //   //   Map<String, String>? headers, required Map<dynamic, dynamic> body,
// //   // }) async {
// //   //   final body = jsonBody == null ? null : jsonEncode(jsonBody);

// //   //   return await http.put(
// //   //     _uri(path),
// //   //     headers: await _headers(withAuth: auth, extraHeaders: headers),
// //   //     body: body,
// //   //   );
// //   // }

// //   // =====================================================
// //   // DELETE
// //   // =====================================================

// //   static Future<http.Response> delete(
// //     String path, {
// //     bool auth = true,
// //     Map<String, String>? headers,
// //   }) async {
// //     return await http.delete(
// //       _uri(path),
// //       headers: await _headers(withAuth: auth, extraHeaders: headers),
// //     );
// //   }

// //   // =====================================================
// //   // DECODE JSON
// //   // =====================================================

// //   static Future<dynamic> decodeJson(http.Response r) async {
// //     if (r.body.isEmpty) {
// //       return null;
// //     }

// //     return jsonDecode(utf8.decode(r.bodyBytes));
// //   }

// //   // =====================================================
// //   // MESSAGE
// //   // =====================================================

// //   static String? messageFromBody(String body) {
// //     try {
// //       final m = jsonDecode(body);

// //       if (m is! Map) {
// //         return null;
// //       }

// //       if (m['message'] != null) {
// //         return m['message'].toString();
// //       }

// //       if (m['title'] != null) {
// //         return m['title'].toString();
// //       }

// //       if (m['detail'] != null) {
// //         return m['detail'].toString();
// //       }
// //     } catch (_) {}

// //     return null;
// //   }
// // }