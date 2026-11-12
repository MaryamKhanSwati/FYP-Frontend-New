import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:house_of_tutor/AdminHome.dart';
import 'package:house_of_tutor/ParentDashboard.dart';
import 'package:house_of_tutor/RoleScreen.dart';
import 'package:house_of_tutor/StudentHome.dart';
import 'package:house_of_tutor/TutorHome.dart';
import 'package:house_of_tutor/services/api_client.dart';
import 'package:house_of_tutor/services/auth_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState(
    
  );
}

class _LoginScreenState extends State<LoginScreen> {

double? _toDoubleNullable(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  final text = value.toString().trim();
  if (text.isEmpty) {
    return null;
  }
  return double.tryParse(text);
}

bool _isValidLatitude(double value) {
  return !value.isNaN &&
      value >= -90 &&
      value <= 90;
}

bool _isValidLongitude(double value) {
  return !value.isNaN && //is NanN must be valid (not empty/invalid)
      value >= -180 &&
      value <= 180;
}
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController =TextEditingController();
  // STATE
  bool isLoading = false;
  bool _obscurePassword = true;
  // color these all color use in back ground hints login button text borders 
  static const Color primaryColor = Color(0xFF249688);
  static const Color headingColor = Color(0xFF07152E);
  static const Color textColor = Color(0xFF526174);
  static const Color hintColor = Color(0xFF9AA8BA);
  static const Color fieldBackground = Color(0xFFF8FAFC);
  static const Color borderColor = Color(0xFFDCE2E9);

  @override
  void dispose() { //dispose means destory the controller when the screen close and free memory
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();//finish the scrren clean up 
  }

  Future<void> _handleLogin() async {
  if (isLoading) return;
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();
//validation start 
  if (email.isEmpty) {
    _showMessage('Please enter your email address.');
    return;
  }
  if (password.isEmpty) {
    _showMessage('Please enter your password.');
    return;
  }
  setState(() {
    isLoading = true;
  });
  try {
    final res = await ApiClient.post(
      '/api/Auth/login',
      {
        'email': email,
        'password': password,
      },
      auth: false,
    );

    debugPrint('======================================');
    debugPrint('LOGIN STATUS : ${res.statusCode}');
    debugPrint('LOGIN BODY   : ${res.body}');
    debugPrint('======================================');

    if (!mounted) return;// screen open raha or aga code chala 

    // =======================================================
    // LOGIN SUCCESS
    // =======================================================

    if (res.statusCode == 200) {
      Map<String, dynamic> data;

      try {
        final decoded = jsonDecode(
          utf8.decode(res.bodyBytes),
        );

        if (decoded is! Map<String, dynamic>) {
          _showMessage(
            'Invalid response received from server.',
          );
          return;
        }

        data = decoded;
      } catch (e) {
        debugPrint('JSON DECODE ERROR: $e');

        _showMessage(
          'Invalid response from server.',
        );
        return;
      }

      // =====================================================
      // RESPONSE DATA
      // =====================================================

      final token = data['token']?.toString().trim();
      final dynamic rawUserId = data['userId'];
      final role = data['role']?.toString().trim();
      final fullName = data['fullName']?.toString().trim() ?? '';
      // IMPORTANT: LOCATION FROM LOGIN RESPONSE
       final double? latitude = _toDoubleNullable(data['latitude']);
      final double? longitude = _toDoubleNullable(data['longitude']);
      //debug location
    debugPrint('======================================');
      debugPrint('LOGIN LOCATION');
      debugPrint('Latitude  : $latitude');
      debugPrint('Longitude : $longitude');
      debugPrint('======================================');

      int? userId;//
      if (rawUserId is int) {
        userId = rawUserId;
      } else if (rawUserId != null) {
        userId = int.tryParse(
          rawUserId.toString(),
        );
      }
      // VALIDATE TOKEN
    
      if (token == null || token.isEmpty) {
        _showMessage(
          'Unexpected server response: token missing.',
        );
        return;
      }

      // VALIDATE USER ID
      if (userId == null) {
        _showMessage(
          'Unexpected server response: user ID missing.',
        );
        return;
      }
      // VALIDATE ROLE
      if (role == null || role.isEmpty) {
        _showMessage(
          'Unexpected server response: role missing.',
        );
        return;
      }
// SAVE LOGIN SESSION
          await AuthStore.instance.setSession(
        token: token,
        userId: userId,
        role: role,
        fullName: fullName,
      );
      // SAVE LOCATION
      // This is the important missing part.
      // AuthStore must expose saveLocation().
            if (latitude != null &&
          longitude != null &&
          _isValidLatitude(latitude) &&
          _isValidLongitude(longitude)) {
        await AuthStore.instance.saveLocation(
          latitude: latitude,
          longitude: longitude,
        );

        debugPrint(
          'LOGIN LOCATION SAVED TO AUTH STORE',
        );
      } else {
        debugPrint(
          'LOGIN LOCATION NOT AVAILABLE',
        );
      }

      // =====================================================
      // HYDRATE AGAIN
      // Make sure AuthStore memory contains latest values.
      // =====================================================

      await AuthStore.instance.hydrate();

      debugPrint('======================================');
      debugPrint('AUTH STORE AFTER LOGIN');
      debugPrint(
        'Latitude  : ${AuthStore.instance.lastLat}',
      );
      debugPrint(
        'Longitude : ${AuthStore.instance.lastLng}',
      );
      debugPrint('======================================');

      if (!mounted) return;
      final normalizedRole = role.toLowerCase().trim();
//Student
      if (normalizedRole == 'student') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const StudentHome(),
          ),
        );
      }
      // TUTOR
           else if (normalizedRole == 'tutor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TutorHome(),
          ),
        );
      }
      // PARENT
      else if (normalizedRole == 'parent') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ParentDashboard(),
          ),
        );
      }
      //admin
      else if (normalizedRole == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminHome(),
          ),
        );
      }
      else {
        _showMessage(
          'Unknown role: $role',
        );
      }
    }
// login failed
    else {
      final message =
          ApiClient.messageFromBody(
                res.body,
              ) ??
              'Login failed. Please check your email and password.';

      _showMessage(message);
    }
  }
//error
  catch (e, stackTrace) {
    debugPrint('======================================');
    debugPrint('LOGIN ERROR');
    debugPrint('ERROR: $e');
    debugPrint('STACK TRACE: $stackTrace');
    debugPrint('======================================');

    if (!mounted) return;

    final errorText =e.toString().toLowerCase();
    if (errorText.contains('connection refused') ||
        errorText.contains('socketexception')) {
      _showMessage(
        'Cannot connect to the server. '
        'Please make sure the API is running.',
      );
    } else if (errorText.contains('timeout')) {
      _showMessage(
        'Server connection timed out. '
        'Please try again.',
      );
    } else {
      _showMessage(
        'Network error: $e',
      );
    }
  }
//stop loading
  finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}
//message
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }
  // TEXT FIELD
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool password = false,
  }) {
    return TextField(
      controller: controller,
      obscureText:
          password ? _obscurePassword : false,
      keyboardType: password
          ? TextInputType.text
          : TextInputType.emailAddress,
      textInputAction: password
          ? TextInputAction.done
          : TextInputAction.next,
      autocorrect: false,
      enableSuggestions: !password,
      onSubmitted:
          password ? (_) => _handleLogin() : null,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF26364A),
        fontWeight: FontWeight.w500,
      ),

      decoration: InputDecoration(
        hintText: hintText,

        hintStyle: const TextStyle(
          fontSize: 14,
          color: hintColor,
        ),

        prefixIcon: const Icon(
          Icons.mail_outline,
          color: Color(0xFF8D9BAE),
          size: 20,
        ),

        suffixIcon: password
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword =
                        !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color:
                      const Color(0xFF68778A),
                  size: 20,
                ),
              )
            : null,

        filled: true,

        fillColor: fieldBackground,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(13),
          borderSide:
              const BorderSide(
            color: borderColor,
            width: 1.2,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(13),
          borderSide:
              const BorderSide(
            color: primaryColor,
            width: 1.7,
          ),
        ),

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(13),
          borderSide:
              const BorderSide(
            color: borderColor,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.of(context).size.width;

    final bool isVerySmall =
        screenWidth < 350;

    final bool isSmall =
        screenWidth < 400;

    final bool isTablet =
        screenWidth >= 600;

    // =======================================================
    // RESPONSIVE SIZES
    // =======================================================

    final double horizontalPadding =
        isTablet
            ? 50
            : isVerySmall
                ? 16
                : isSmall
                    ? 18
                    : 22;

    final double logoSize =
        isTablet
            ? 150
            : isVerySmall
                ? 100
                : isSmall
                    ? 110
                    : 125;

    final double headingSize =
        isTablet
            ? 34
            : isVerySmall
                ? 26
                : isSmall
                    ? 28
                    : 30;

    final double subtitleSize =
        isTablet
            ? 16
            : isVerySmall
                ? 12
                : 13;

    final double cardPadding =
        isTablet
            ? 32
            : isVerySmall
                ? 17
                : isSmall
                    ? 19
                    : 22;
//ui
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8FAFC),

      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .onDrag,

          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 550,
              ),

              child: Padding(
                padding:
                    EdgeInsets.symmetric(
                  horizontal:
                      horizontalPadding,
                ),

                child: Column(
                  children: [
                    // =================================================
                    // TOP SPACE
                    // =================================================

                    SizedBox(
                      height:
                          isVerySmall ? 18 : 22,
                    ),
// logo 
                    Container(
                      width: logoSize,
                      height: logoSize,

                      decoration:
                          BoxDecoration(
                        color: primaryColor,

                        borderRadius:
                            BorderRadius.circular(
                          isVerySmall
                              ? 25
                              : 30,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(0.10),
                            blurRadius: 8,
                            offset:
                                const Offset(
                              0,
                              3,
                            ),
                          ),
                        ],
                      ),

                      child: Center(
                        child: Container(
                          width:
                              logoSize * 0.72,

                          height:
                              logoSize * 0.50,

                          color: Colors.white,

                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder:
                                (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return const Icon(
                                Icons.school,
                                size: 45,
                                color:
                                    primaryColor,
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // =================================================
                    // LOGO → HEADING
                    // =================================================

                    SizedBox(
                      height:
                          isVerySmall ? 18 : 22,
                    ),

                    // =================================================
                    // WELCOME
                    // =================================================

                    Text(
                      'Welcome Back',
                      textAlign:
                          TextAlign.center,

                      style: TextStyle(
                        fontSize:
                            headingSize,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            headingColor,
                        letterSpacing:
                            -0.5,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    // =================================================
                    // SUBTITLE
                    // =================================================

                    Text(
                      'Sign in to manage your tutoring sessions &\nschedule',
                      textAlign:
                          TextAlign.center,

                      style: TextStyle(
                        fontSize:
                            subtitleSize,
                        height: 1.35,
                        color:
                            textColor,
                        fontWeight:
                            FontWeight.w400,
                      ),
                    ),

                    // =================================================
                    // SUBTITLE → CARD
                    // =================================================

                    SizedBox(
                      height:
                          isVerySmall
                              ? 22
                              : 28,
                    ),

                    // =================================================
                    // LOGIN CARD
                    // =================================================

                    Container(
                      width:
                          double.infinity,

                      padding:
                          EdgeInsets.all(
                        cardPadding,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,

                        borderRadius:
                            BorderRadius.circular(
                          isVerySmall
                              ? 18
                              : 20,
                        ),

                        border:
                            Border.all(
                          color:
                              const Color(
                            0xFFE4E8ED,
                          ),
                          width: 1,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(0.06),
                            blurRadius: 8,
                            offset:
                                const Offset(
                              0,
                              3,
                            ),
                          ),
                        ],
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          // =========================================
                          // EMAIL LABEL
                          // =========================================

                          const Text(
                            'Email Address',
                            style:
                                TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  Color(
                                0xFF26364A,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 7,
                          ),

                          // =========================================
                          // EMAIL
                          // =========================================

                          _buildTextField(
                            controller:
                                _emailController,
                            hintText:
                                'name@example.com',
                            icon:
                                Icons.mail_outline,
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          // =========================================
                          // PASSWORD LABEL
                          // =========================================

                          const Text(
                            'Password',
                            style:
                                TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  Color(
                                0xFF26364A,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 7,
                          ),

                          // =========================================
                          // PASSWORD
                          // =========================================

                          _buildTextField(
                            controller:
                                _passwordController,
                            hintText:
                                'Enter your password',
                            icon:
                                Icons.lock_outline,
                            password: true,
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          // =========================================
                          // SIGN IN BUTTON
                          // =========================================

                          SizedBox(
                            width:
                                double.infinity,

                            height:
                                isVerySmall
                                    ? 50
                                    : 52,

                            child:
                                ElevatedButton(
                              onPressed:
                                  isLoading
                                      ? null
                                      : _handleLogin,

                              style:
                                  ElevatedButton
                                      .styleFrom(
                                backgroundColor:
                                    primaryColor,

                                disabledBackgroundColor:
                                    primaryColor
                                        .withOpacity(
                                  0.65,
                                ),

                                disabledForegroundColor:
                                    Colors.white,

                                elevation: 0,

                                padding:
                                    EdgeInsets.zero,

                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    12,
                                  ),
                                ),
                              ),

                              child:
                                  isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth:
                                                2.2,
                                            valueColor:
                                                AlwaysStoppedAnimation<
                                                    Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'Sign In',
                                          style:
                                              TextStyle(
                                            fontSize:
                                                16,
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                            color:
                                                Colors.white,
                                          ),
                                        ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // =================================================
                    // CARD → CREATE ACCOUNT
                    // =================================================

                    SizedBox(
                      height:
                          isVerySmall
                              ? 24
                              : 28,
                    ),

                    const Text(
                      "Don't have an account yet?",
                      textAlign:
                          TextAlign.center,
                      style:
                          TextStyle(
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),
                    // CREATE ACCOUNT
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const RoleScreen(),
                                ),
                              );
                            },

                      style:
                          TextButton.styleFrom(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 5,
                          vertical: 3,
                        ),
                      ),

                      child: const Row(
                        mainAxisSize:
                            MainAxisSize.min,

                        children: [
                          Text(
                            'Create new account',
                            style:
                                TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w700,
                              color:
                                  primaryColor,
                            ),
                          ),

                          SizedBox(
                            width: 5,
                          ),

                          Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color:
                                primaryColor,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}