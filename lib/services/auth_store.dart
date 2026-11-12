import 'package:shared_preferences/shared_preferences.dart';

class AuthStore {
  AuthStore._();

  static final AuthStore instance = AuthStore._();

  String? token;
  int? userId;
  String? role;
  String? fullName;

  double? lastLat;
  double? lastLng;

  // =========================================================
  // SET SESSION
  // =========================================================

  Future<void> setSession({
    required String token,
    required int userId,
    required String role,
    required String fullName,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', token);
    await prefs.setInt('userId', userId);
    await prefs.setString('role', role);
    await prefs.setString('fullName', fullName);

    this.token = token;
    this.userId = userId;
    this.role = role;
    this.fullName = fullName;
  }

  // =========================================================
  // SAVE LOCATION
  // =========================================================

  Future<void> saveLocation({
    required double latitude,
    required double longitude,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(
      'latitude',
      latitude,
    );

    await prefs.setDouble(
      'longitude',
      longitude,
    );

    lastLat = latitude;
    lastLng = longitude;

    print('====================================');
    print('AUTH STORE LOCATION SAVED');
    print('Latitude: $lastLat');
    print('Longitude: $lastLng');
    print('====================================');
  }

  // =========================================================
  // HYDRATE
  // =========================================================

  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();

    token = prefs.getString('token');

    userId = prefs.getInt('userId');

    role = prefs.getString('role');

    fullName = prefs.getString('fullName');

    lastLat = prefs.getDouble('latitude');

    lastLng = prefs.getDouble('longitude');

    print('====================================');
    print('AUTH STORE HYDRATED');
    print('Latitude: $lastLat');
    print('Longitude: $lastLng');
    print('====================================');
  }

  // =========================================================
  // CLEAR SESSION
  // =========================================================

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('role');
    await prefs.remove('fullName');

    await prefs.remove('latitude');
    await prefs.remove('longitude');

    token = null;
    userId = null;
    role = null;
    fullName = null;

    lastLat = null;
    lastLng = null;
  }
}















// import 'package:shared_preferences/shared_preferences.dart';

// class AuthStore {
//   AuthStore._();
//   static final AuthStore instance = AuthStore._();

//   static const _kToken = 'auth_token';
//   static const _kUserId = 'auth_user_id';
//   static const _kRole = 'auth_role';
//   static const _kFullName = 'auth_full_name';
//   static const _kLat = 'auth_last_lat';
//   static const _kLng = 'auth_last_lng';

//   String? _token;
//   int? userId;
//   String? role;
//   String? fullName;
//   double? lastLat;
//   double? lastLng;
//   bool _loaded = false;

//   String? get token => _token;

//   Future<void> hydrate() async {
//     if (_loaded) return;
//     final p = await SharedPreferences.getInstance();
//     _token = p.getString(_kToken);
//     userId = p.getInt(_kUserId);
//     role = p.getString(_kRole);
//     fullName = p.getString(_kFullName);
//     if (p.containsKey(_kLat)) lastLat = p.getDouble(_kLat);
//     if (p.containsKey(_kLng)) lastLng = p.getDouble(_kLng);
//     _loaded = true;
//   }

//   // =========================================================
//   // SET SESSION (now also accepts latitude/longitude,
//   // since the login API returns them together in one response)
//   // =========================================================

//   Future<void> setSession({
//     required String token,
//     required int userId,
//     required String role,
//     required String fullName,
//     double? latitude,
//     double? longitude,
//   }) async {
//     final p = await SharedPreferences.getInstance();
//     await p.setString(_kToken, token);
//     await p.setInt(_kUserId, userId);
//     await p.setString(_kRole, role);
//     await p.setString(_kFullName, fullName);

//     _token = token;
//     this.userId = userId;
//     this.role = role;
//     this.fullName = fullName;

//     // Only persist lat/lng if the login response actually
//     // included them (Parent/Admin logins send null for both).
//     if (latitude != null && longitude != null) {
//       await p.setDouble(_kLat, latitude);
//       await p.setDouble(_kLng, longitude);
//       lastLat = latitude;
//       lastLng = longitude;
//     }

//     _loaded = true;
//   }

//   // Kept for cases where you want to update location
//   // independently of a full login (e.g. a "update my location"
//   // screen later in the app).
//   Future<void> setLastLocation(double lat, double lng) async {
//     final p = await SharedPreferences.getInstance();
//     await p.setDouble(_kLat, lat);
//     await p.setDouble(_kLng, lng);
//     lastLat = lat;
//     lastLng = lng;
//     _loaded = true;
//   }

//   Future<void> clear() async {
//     final p = await SharedPreferences.getInstance();
//     await p.remove(_kToken);
//     await p.remove(_kUserId);
//     await p.remove(_kRole);
//     await p.remove(_kFullName);
//     await p.remove(_kLat);
//     await p.remove(_kLng);
//     _token = null;
//     userId = null;
//     role = null;
//     fullName = null;
//     lastLat = null;
//     lastLng = null;
//     _loaded = true;
//   }
// }