import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:house_of_tutor/LoginScreen.dart';
import 'package:house_of_tutor/MapLocationScreen.dart';
import 'package:house_of_tutor/services/api_client.dart';
import 'package:latlong2/latlong.dart';

class TutorSignupScreen extends StatefulWidget {
  const TutorSignupScreen({super.key});

  @override
  State<TutorSignupScreen> createState() => _TutorSignupScreenState();
}

class _TutorSignupScreenState extends State<TutorSignupScreen> {

  final _nameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _radiusController = TextEditingController();
  final _experienceController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // VARIABLES
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _teachingMode;

  // DISPOSE
  @override
  void dispose() {
    _nameController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _qualificationController.dispose();
    _radiusController.dispose();
    _experienceController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // =============================================================
  // HANDLE SIGNUP
  // =============================================================

  Future<void> _handleSignup() async {
    if (isLoading) return;

    // ===========================================================
    // GET VALUES
    // ===========================================================

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword =
        _confirmPasswordController.text.trim();

    final phone = _phoneController.text.trim();
    final cnic = _cnicController.text.trim();

    final qualification =
        _qualificationController.text.trim();

    final radiusRaw =
        _radiusController.text.trim();

    final experienceRaw =
        _experienceController.text.trim();

    // ===========================================================
    // BASIC VALIDATION
    // ===========================================================

    if (name.isEmpty) {
      _showMessage('Please enter your full name');
      return;
    }

    if (cnic.isEmpty) {
      _showMessage('Please enter your CNIC');
      return;
    }

    if (email.isEmpty) {
      _showMessage('Please enter your email');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Please enter your password');
      return;
    }

    if (qualification.isEmpty) {
      _showMessage('Please enter qualification');
      return;
    }

    // ===========================================================
    // TEACHING MODE VALIDATION
    // ===========================================================

    if (_teachingMode == null) {
      _showMessage('Please select Teaching Mode');
      return;
    }

    // ===========================================================
    // PASSWORD VALIDATION
    // ===========================================================

    if (password != confirmPassword) {
      _showMessage('Passwords do not match');
      return;
    }

    // ===========================================================
    // EXPERIENCE VALIDATION
    // ===========================================================

    final experience =
        int.tryParse(experienceRaw);

    if (experience == null || experience < 0) {
      _showMessage(
        'Please enter valid years of experience',
      );
      return;
    }

    // ===========================================================
    // RADIUS VALIDATION
    //
    // ONLY Visiting tutor needs radius.
    //
    // Non-Visiting:
    // Radius is not required.
    // Radius is not sent.
    // ===========================================================

    int? radius;

    if (_teachingMode == 'Visiting') {
      radius = int.tryParse(radiusRaw);

      if (radius == null || radius <= 0) {
        _showMessage(
          'Please enter a valid radius (km, whole number)',
        );
        return;
      }
    }

    // ===========================================================
    // START LOADING
    // ===========================================================

    setState(() {
      isLoading = true;
    });

    // ===========================================================
    // LOCATION VARIABLE
    //
    // Only Visiting tutor will use this.
    // ===========================================================

    LatLng? selectedLocation;

    // ===========================================================
    // VISITING TUTOR
    //
    // Open Map Screen.
    //
    // User selects latitude and longitude.
    // ===========================================================

    if (_teachingMode == 'Visiting') {
      try {
        selectedLocation =
            await Navigator.push<LatLng>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const MapLocationScreen(),
          ),
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });

          _showMessage(
            'Could not open location map: $e',
          );
        }

        return;
      }

      // =========================================================
      // CHECK MAP RESULT
      // =========================================================

      if (!mounted) return;

      if (selectedLocation == null) {
        setState(() {
          isLoading = false;
        });

        _showMessage(
          'Please select your location',
        );

        return;
      }
    }

    // ===========================================================
    // REGISTER USER
    // ===========================================================

    try {
      // =========================================================
      // CREATE REGISTRATION BODY
      // =========================================================

      final Map<String, dynamic> registrationBody = {
        'fullName': name,
        'email': email,
        'phone': phone.isEmpty ? '—' : phone,
        'cnic': cnic,
        'password': password,
        'role': 'Tutor',

        'qualification': qualification,
        'experience': experience,

        // Backend requires:
        // Visiting / Non-Visiting
        'teachingMode': _teachingMode,
      };

      // =========================================================
      // IMPORTANT:
      //
      // Only send radius for Visiting tutor.
      //
      // Non-Visiting does NOT send radius.
      // =========================================================

      if (_teachingMode == 'Visiting') {
        registrationBody['radius'] = radius;
      }

      // =========================================================
      // CALL REGISTER API
      // =========================================================

      final reg = await ApiClient.post(
        '/api/Auth/register',
        registrationBody,
        auth: false,
      );

      if (!mounted) return;

      // =========================================================
      // CHECK REGISTER RESPONSE
      // =========================================================

      if (reg.statusCode < 200 ||
          reg.statusCode >= 300) {
        final msg =
            ApiClient.messageFromBody(reg.body) ??
                'Registration failed';

        _showMessage(msg);

        setState(() {
          isLoading = false;
        });

        return;
      }

      // =========================================================
      // PARSE RESPONSE
      // =========================================================

      Map<String, dynamic> regData;

      try {
        regData = jsonDecode(
          utf8.decode(reg.bodyBytes),
        ) as Map<String, dynamic>;
      } catch (e) {
        _showMessage(
          'Invalid registration response from server',
        );

        setState(() {
          isLoading = false;
        });

        return;
      }

      // =========================================================
      // GET USER ID
      // =========================================================

      final userIdValue = regData['userId'];

      if (userIdValue == null) {
        _showMessage(
          'Registration successful, but user ID was not returned.',
        );

        setState(() {
          isLoading = false;
        });

        return;
      }

      final int? userId =
          int.tryParse(
        userIdValue.toString(),
      );

      if (userId == null || userId <= 0) {
        _showMessage(
          'Invalid user ID returned by server.',
        );

        setState(() {
          isLoading = false;
        });

        return;
      }

      // ===========================================================
      // SAVE LOCATION
      //
      // ONLY FOR VISITING TUTOR
      //
      // Non-Visiting tutor:
      // No location API call.
      // Latitude remains NULL.
      // Longitude remains NULL.
      // Location remains NULL.
      // ===========================================================

      if (_teachingMode == 'Visiting' &&
          selectedLocation != null) {
        final locationResponse =
            await ApiClient.post(
          '/api/Auth/update-location',
          {
            'userId': userId,
            'latitude':
                selectedLocation.latitude,
            'longitude':
                selectedLocation.longitude,
          },
          auth: false,
        );

        if (!mounted) return;

        // =========================================================
        // CHECK LOCATION RESPONSE
        // =========================================================

        if (locationResponse.statusCode < 200 ||
            locationResponse.statusCode >= 300) {
          final msg =
              ApiClient.messageFromBody(
                    locationResponse.body,
                  ) ??
                  'Could not save tutor location';

          _showMessage(msg);

          setState(() {
            isLoading = false;
          });

          return;
        }
      }

      // ===========================================================
      // SUCCESS
      // ===========================================================

      _showMessage(
        'Account created successfully. Please log in.',
      );

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) return;

      // ===========================================================
      // GO TO LOGIN
      // ===========================================================

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Network error: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =============================================================
  // SHOW MESSAGE
  // =============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    const primaryColor =
        Color(0xFF139675);

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F7),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),

          child: Column(
            children: [
              const SizedBox(height: 10),

              // =================================================
              // HEADER
              // =================================================

              Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 70,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Create Tutor Account',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Set up your profile to start teaching on the platform',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // =================================================
              // MAIN CARD
              // =================================================

              Container(
                padding:
                    const EdgeInsets.all(20),

                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(16),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.05),
                      blurRadius: 10,
                      offset:
                          const Offset(0, 4),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    // =================================================
                    // PERSONAL DETAILS
                    // =================================================

                    const Text(
                      'PERSONAL DETAILS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _buildField(
                      controller:
                          _nameController,
                      label: 'Full Name',
                      hint: 'Full Name',
                      icon:
                          Icons.person_outline,
                      primaryColor:
                          primaryColor,
                    ),

                    _buildField(
                      controller:
                          _cnicController,
                      label: 'CNIC',
                      hint: 'CNIC',
                      icon:
                          Icons.badge_outlined,
                      primaryColor:
                          primaryColor,
                    ),

                    _buildField(
                      controller:
                          _phoneController,
                      label: 'Phone',
                      hint: 'Phone',
                      icon:
                          Icons.phone_outlined,
                      primaryColor:
                          primaryColor,
                      keyboardType:
                          TextInputType.phone,
                    ),

                    _buildField(
                      controller:
                          _emailController,
                      label: 'Email',
                      hint: 'Email',
                      icon:
                          Icons.email_outlined,
                      primaryColor:
                          primaryColor,
                      keyboardType:
                          TextInputType
                              .emailAddress,
                    ),

                    const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        vertical: 8,
                      ),
                      child: Divider(
                        color:
                            Color(0xFFEEEEEE),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // =================================================
                    // TEACHING DETAILS
                    // =================================================

                    const Text(
                      'TEACHING DETAILS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _buildField(
                      controller:
                          _qualificationController,
                      label: 'Qualification',
                      hint: 'Qualification',
                      icon:
                          Icons.school_outlined,
                      primaryColor:
                          primaryColor,
                    ),

                    // =================================================
                    // EXPERIENCE
                    //
                    // Experience is ALWAYS shown.
                    // =================================================

                    _buildField(
                      controller:
                          _experienceController,
                      label:
                          'Experience (years)',
                      hint: 'Experience',
                      icon:
                          Icons.work_outline,
                      primaryColor:
                          primaryColor,
                      keyboardType:
                          TextInputType.number,
                    ),

                    // =================================================
                    // TEACHING MODE
                    // =================================================

                    const Text(
                      'Teaching Mode',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFFAFAFA,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(10),
                        border: Border.all(
                          color:
                              const Color(
                            0xFFE0E0E0,
                          ),
                        ),
                      ),

                      child: Column(
                        children: [
                          // =============================================
                          // VISITING
                          // =============================================

                          RadioListTile<String>(
                            value: 'Visiting',
                            groupValue:
                                _teachingMode,
                            activeColor:
                                primaryColor,

                            title:
                                const Text(
                              'Visiting',
                              style:
                                  TextStyle(
                                fontSize: 14,
                              ),
                            ),

                            subtitle:
                                const Text(
                              'Tutor can visit the student',
                              style:
                                  TextStyle(
                                fontSize: 12,
                                color:
                                    Colors.grey,
                              ),
                            ),

                            onChanged:
                                isLoading
                                    ? null
                                    : (value) {
                                        setState(
                                          () {
                                            _teachingMode =
                                                value;
                                          },
                                        );
                                      },
                          ),

                          const Divider(
                            height: 1,
                            color:
                                Color(0xFFEAEAEA),
                          ),

                          // =============================================
                          // NON-VISITING
                          // =============================================

                          RadioListTile<String>(
                            value:
                                'Non-Visiting',
                            groupValue:
                                _teachingMode,
                            activeColor:
                                primaryColor,

                            title:
                                const Text(
                              'Non-Visiting',
                              style:
                                  TextStyle(
                                fontSize: 14,
                              ),
                            ),

                            subtitle:
                                const Text(
                              'Student goes to tutor / online',
                              style:
                                  TextStyle(
                                fontSize: 12,
                                color:
                                    Colors.grey,
                              ),
                            ),

                            onChanged:
                                isLoading
                                    ? null
                                    : (value) {
                                        setState(
                                          () {
                                            _teachingMode =
                                                value;

                                            // =================================================
                                            // IMPORTANT:
                                            // Clear radius when changing to Non-Visiting.
                                            //
                                            // This prevents old radius value from
                                            // accidentally being used later.
                                            // =================================================

                                            if (value ==
                                                'Non-Visiting') {
                                              _radiusController
                                                  .clear();
                                            }
                                          },
                                        );
                                      },
                          ),
                        ],
                      ),
                    ),

                    // =================================================
                    // RADIUS
                    //
                    // ONLY SHOW FOR VISITING
                    // =================================================

                    if (_teachingMode ==
                        'Visiting') ...[
                      const SizedBox(height: 16),

                      _buildField(
                        controller:
                            _radiusController,
                        label:
                            'Radius (km)',
                        hint: 'Radius',
                        icon: Icons
                            .location_on_outlined,
                        primaryColor:
                            primaryColor,
                        keyboardType:
                            TextInputType.number,
                      ),

                      // ===============================================
                      // LOCATION INFORMATION
                      // ===============================================

                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .all(12),
                        margin:
                            const EdgeInsets
                                .only(
                          bottom: 4,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFEFFAF6,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                          border:
                              Border.all(
                            color:
                                const Color(
                              0xFFD5F0E7,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Icon(
                              Icons
                                  .location_on_outlined,
                              size: 20,
                              color:
                                  primaryColor,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Text(
                                'After registration, you will select your teaching location on the map.',
                                style:
                                    TextStyle(
                                  fontSize: 12,
                                  color:
                                      Colors.grey[
                                          700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // =================================================
                    // SECURITY DIVIDER
                    // =================================================

                    const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        vertical: 8,
                      ),
                      child: Divider(
                        color:
                            Color(0xFFEEEEEE),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // =================================================
                    // SECURITY
                    // =================================================

                    const Text(
                      'SECURITY',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // =================================================
                    // PASSWORD
                    // =================================================

                    _buildField(
                      controller:
                          _passwordController,
                      label: 'Password',
                      hint: 'Password',
                      icon:
                          Icons.lock_outline,
                      isPassword: true,
                      obscureText:
                          _obscurePassword,

                      onToggleVisibility:
                          () {
                        setState(() {
                          _obscurePassword =
                              !_obscurePassword;
                        });
                      },

                      primaryColor:
                          primaryColor,
                    ),

                    // =================================================
                    // CONFIRM PASSWORD
                    // =================================================

                    _buildField(
                      controller:
                          _confirmPasswordController,
                      label:
                          'Confirm Password',
                      hint:
                          'Confirm Password',
                      icon:
                          Icons.lock_outline,
                      isPassword: true,
                      obscureText:
                          _obscureConfirmPassword,

                      onToggleVisibility:
                          () {
                        setState(() {
                          _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                        });
                      },

                      primaryColor:
                          primaryColor,
                    ),

                    const SizedBox(height: 10),

                    // =================================================
                    // REGISTER BUTTON
                    // =================================================

                    SizedBox(
                      width:
                          double.infinity,
                      height: 50,

                      child: isLoading
                          ? const Center(
                              child:
                                  CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<
                                        Color>(
                                  primaryColor,
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed:
                                  _handleSignup,

                              style:
                                  ElevatedButton
                                      .styleFrom(
                                backgroundColor:
                                    primaryColor,
                                foregroundColor:
                                    Colors.white,
                                elevation: 0,

                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    10,
                                  ),
                                ),
                              ),

                              child:
                                  const Text(
                                'Register',
                                style:
                                    TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 12),

                    // =================================================
                    // LOGIN
                    // =================================================

                    Center(
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color:
                                  Colors.black54,
                              fontSize: 14,
                            ),
                          ),

                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () {
                                    Navigator
                                        .pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) =>
                                                const LoginScreen(),
                                      ),
                                    );
                                  },

                            child:
                                const Text(
                              'Log in',
                              style:
                                  TextStyle(
                                color:
                                    primaryColor,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // TEXT FIELD
  // =============================================================

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,

    bool isPassword = false,
    bool obscureText = false,

    VoidCallback? onToggleVisibility,

    TextInputType? keyboardType,

    required Color primaryColor,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 16),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight:
                  FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          TextField(
            controller: controller,

            obscureText: isPassword
                ? obscureText
                : false,

            keyboardType: keyboardType,

            decoration:
                InputDecoration(
              hintText: hint,

              hintStyle:
                  const TextStyle(
                color: Colors.black38,
                fontSize: 14,
              ),

              prefixIcon: Icon(
                icon,
                color: Colors.grey,
              ),

              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons
                                .visibility_outlined
                            : Icons
                                .visibility_off_outlined,
                        color:
                            Colors.grey,
                      ),
                      onPressed:
                          onToggleVisibility,
                    )
                  : null,

              filled: true,

              fillColor:
                  const Color(0xFFFAFAFA),

              contentPadding:
                  const EdgeInsets
                      .symmetric(
                vertical: 14,
                horizontal: 12,
              ),

              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius
                        .circular(10),

                borderSide:
                    const BorderSide(
                  color:
                      Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),

              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius
                        .circular(10),

                borderSide:
                    BorderSide(
                  color: primaryColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



























// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:house_of_tutor/LoginScreen.dart';
// import 'package:house_of_tutor/MapLocationScreen.dart';
// import 'package:house_of_tutor/services/api_client.dart';
// import 'package:latlong2/latlong.dart';

// class TutorSignupScreen extends StatefulWidget {
//   const TutorSignupScreen({super.key});

//   @override
//   State<TutorSignupScreen> createState() => _TutorSignupScreenState();
// }

// class _TutorSignupScreenState extends State<TutorSignupScreen> {
//   final _nameController = TextEditingController();
//   final _cnicController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _qualificationController = TextEditingController();
//   final _radiusController = TextEditingController();
//   final _experienceController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();

//   bool isLoading = false;

//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;

//   // =========================================================
//   // NEW: TUTOR TEACHING MODE
//   // Backend requires:
//   // "Visiting" OR "Non-Visiting"
//   // =========================================================
//   String? _teachingMode;

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _cnicController.dispose();
//     _phoneController.dispose();
//     _emailController.dispose();
//     _qualificationController.dispose();
//     _radiusController.dispose();
//     _experienceController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();

//     super.dispose();
//   }

//   Future<void> _handleSignup() async {
//     if (isLoading) return;

//     final name = _nameController.text.trim();
//     final email = _emailController.text.trim();
//     final pass = _passwordController.text.trim();
//     final confirm = _confirmPasswordController.text.trim();
//     final phone = _phoneController.text.trim();
//     final cnic = _cnicController.text.trim();
//     final qualification = _qualificationController.text.trim();
//     final radiusRaw = _radiusController.text.trim();
//     final expRaw = _experienceController.text.trim();

//     // =========================================================
//     // VALIDATION
//     // =========================================================

//     if (name.isEmpty ||
//         email.isEmpty ||
//         pass.isEmpty ||
//         cnic.isEmpty) {
//       _showMessage(
//         'Please fill name, email, password, and CNIC',
//       );
//       return;
//     }

//     if (qualification.isEmpty) {
//       _showMessage('Please enter qualification');
//       return;
//     }

//     if (pass != confirm) {
//       _showMessage('Passwords do not match');
//       return;
//     }

//     // =========================================================
//     // NEW: VALIDATE TEACHING MODE
//     // Backend requires Visiting or Non-Visiting
//     // =========================================================

//     if (_teachingMode == null) {
//       _showMessage(
//         'Please select Teaching Mode',
//       );
//       return;
//     }

//     final radius = int.tryParse(radiusRaw);
//     final experience = int.tryParse(expRaw);

//     if (radius == null || radius <= 0) {
//       _showMessage(
//         'Please enter a valid radius (km, whole number)',
//       );
//       return;
//     }

//     if (experience == null || experience < 0) {
//       _showMessage(
//         'Please enter valid years of experience',
//       );
//       return;
//     }

//     // =========================================================
//     // SELECT LOCATION
//     // =========================================================

//     setState(() {
//       isLoading = true;
//     });

//     LatLng? result;

//     try {
//       result = await Navigator.push<LatLng>(
//         context,
//         MaterialPageRoute(
//           builder: (_) => const MapLocationScreen(),
//         ),
//       );
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });

//         _showMessage(
//           'Could not open location map: $e',
//         );
//       }

//       return;
//     }

//     if (!mounted) return;

//     if (result == null) {
//       setState(() {
//         isLoading = false;
//       });

//       _showMessage(
//         'Please select location',
//       );

//       return;
//     }

//     // =========================================================
//     // REGISTER TUTOR
//     // =========================================================

//     try {
//       final reg = await ApiClient.post(
//         '/api/Auth/register',

//         // =====================================================
//         // REGISTRATION BODY
//         // =====================================================

//         {
//           'fullName': name,
//           'email': email,
//           'phone': phone.isEmpty ? '—' : phone,
//           'cnic': cnic,
//           'password': pass,
//           'role': 'Tutor',

//           'qualification': qualification,
//           'experience': experience,
//           'radius': radius,

//           // =================================================
//           // NEW:
//           // SEND TEACHING MODE TO BACKEND
//           //
//           // Value will be:
//           // "Visiting"
//           // OR
//           // "Non-Visiting"
//           // =================================================
//           'teachingMode': _teachingMode,
//         },

//         auth: false,
//       );

//       if (!mounted) return;

//       // =====================================================
//       // CHECK REGISTRATION RESPONSE
//       // =====================================================

//       if (reg.statusCode < 200 || reg.statusCode >= 300) {
//         final msg =
//             ApiClient.messageFromBody(reg.body) ??
//                 'Registration failed';

//         _showMessage(msg);

//         setState(() {
//           isLoading = false;
//         });

//         return;
//       }

//       // =====================================================
//       // PARSE REGISTER RESPONSE
//       // =====================================================

//       Map<String, dynamic> regData;

//       try {
//         regData = jsonDecode(
//           utf8.decode(reg.bodyBytes),
//         ) as Map<String, dynamic>;
//       } catch (e) {
//         _showMessage(
//           'Invalid registration response from server',
//         );

//         setState(() {
//           isLoading = false;
//         });

//         return;
//       }

//       // =====================================================
//       // GET USER ID
//       // =====================================================

//       final userIdValue = regData['userId'];

//       if (userIdValue == null) {
//         _showMessage(
//           'Registration successful, but user ID was not returned.',
//         );

//         setState(() {
//           isLoading = false;
//         });

//         return;
//       }

//       final int? uid = int.tryParse(
//         userIdValue.toString(),
//       );

//       if (uid == null || uid <= 0) {
//         _showMessage(
//           'Invalid user ID returned by server.',
//         );

//         setState(() {
//           isLoading = false;
//         });

//         return;
//       }

//       // =====================================================
//       // SAVE TUTOR LOCATION
//       // =====================================================

//       final loc = await ApiClient.post(
//         '/api/Auth/update-location',
//         {
//           'userId': uid,
//           'latitude': result.latitude,
//           'longitude': result.longitude,
//         },
//         auth: false,
//       );

//       if (!mounted) return;

//       if (loc.statusCode < 200 || loc.statusCode >= 300) {
//         final msg =
//             ApiClient.messageFromBody(loc.body) ??
//                 'Could not save location';

//         _showMessage(msg);

//         setState(() {
//           isLoading = false;
//         });

//         return;
//       }

//       // =====================================================
//       // IMPORTANT:
//       // Tutor is NOT logged in yet.
//       //
//       // Registration + location are already saved.
//       // Do not use AuthStore here.
//       // =====================================================

//       _showMessage(
//         'Account created successfully. Please log in.',
//       );

//       await Future.delayed(
//         const Duration(milliseconds: 700),
//       );

//       if (!mounted) return;

//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(
//           builder: (_) => const LoginScreen(),
//         ),
//         (route) => false,
//       );
//     } catch (e) {
//       if (!mounted) return;

//       _showMessage(
//         'Network error: $e',
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }

//   void _showMessage(String msg) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(
//         SnackBar(
//           content: Text(msg),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//   }

//   @override
//   Widget build(BuildContext context) {
//     const primaryColor = Color(0xFF139675);

//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F7),

//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(
//             horizontal: 20,
//             vertical: 12,
//           ),

//           child: Column(
//             children: [
//               const SizedBox(height: 10),

//               // =================================================
//               // HEADER
//               // =================================================

//               Column(
//                 children: [
//                   Image.asset(
//                     'assets/images/logo.png',
//                     height: 70,
//                   ),

//                   const SizedBox(height: 12),

//                   const Text(
//                     'Create Tutor Account',
//                     style: TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),

//                   const SizedBox(height: 6),

//                   const Text(
//                     'Set up your profile to start teaching on the platform',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               // =================================================
//               // MAIN CARD
//               // =================================================

//               Container(
//                 padding: const EdgeInsets.all(20),

//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),

//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.05),
//                       blurRadius: 10,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),

//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,

//                   children: [
//                     // =================================================
//                     // PERSONAL DETAILS
//                     // =================================================

//                     const Text(
//                       'PERSONAL DETAILS',
//                       style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.bold,
//                         color: primaryColor,
//                         letterSpacing: 0.5,
//                       ),
//                     ),

//                     const SizedBox(height: 14),

//                     _buildField(
//                       controller: _nameController,
//                       label: 'Full Name',
//                       hint: 'Full Name',
//                       icon: Icons.person_outline,
//                       primaryColor: primaryColor,
//                     ),

//                     _buildField(
//                       controller: _cnicController,
//                       label: 'CNIC',
//                       hint: 'CNIC',
//                       icon: Icons.badge_outlined,
//                       primaryColor: primaryColor,
//                     ),

//                     _buildField(
//                       controller: _phoneController,
//                       label: 'Phone',
//                       hint: 'Phone',
//                       icon: Icons.phone_outlined,
//                       primaryColor: primaryColor,
//                       keyboardType: TextInputType.phone,
//                     ),

//                     _buildField(
//                       controller: _emailController,
//                       label: 'Email',
//                       hint: 'Email',
//                       icon: Icons.email_outlined,
//                       primaryColor: primaryColor,
//                       keyboardType:
//                           TextInputType.emailAddress,
//                     ),

//                     const Padding(
//                       padding: EdgeInsets.symmetric(
//                         vertical: 8,
//                       ),

//                       child: Divider(
//                         color: Color(0xFFEEEEEE),
//                       ),
//                     ),

//                     const SizedBox(height: 4),

//                     // =================================================
//                     // TEACHING DETAILS
//                     // =================================================

//                     const Text(
//                       'TEACHING DETAILS',
//                       style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.bold,
//                         color: primaryColor,
//                         letterSpacing: 0.5,
//                       ),
//                     ),

//                     const SizedBox(height: 14),

//                     _buildField(
//                       controller: _qualificationController,
//                       label: 'Qualification',
//                       hint: 'Qualification',
//                       icon: Icons.school_outlined,
//                       primaryColor: primaryColor,
//                     ),

//                     Row(
//                       crossAxisAlignment:
//                           CrossAxisAlignment.start,

//                       children: [
//                         Expanded(
//                           child: _buildField(
//                             controller:
//                                 _radiusController,
//                             label: 'Radius (km)',
//                             hint: 'Radius',
//                             icon:
//                                 Icons.location_on_outlined,
//                             primaryColor:
//                                 primaryColor,
//                             keyboardType:
//                                 TextInputType.number,
//                           ),
//                         ),

//                         const SizedBox(width: 12),

//                         Expanded(
//                           child: _buildField(
//                             controller:
//                                 _experienceController,
//                             label:
//                                 'Experience (years)',
//                             hint: 'Experience',
//                             icon: Icons.work_outline,
//                             primaryColor:
//                                 primaryColor,
//                             keyboardType:
//                                 TextInputType.number,
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 2),

//                     // =================================================
//                     // NEW TEACHING MODE UI
//                     //
//                     // User selects:
//                     // Visiting
//                     // OR
//                     // Non-Visiting
//                     // =================================================

//                     const Text(
//                       'Teaching Mode',
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: Colors.black87,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),

//                     const SizedBox(height: 8),

//                     Container(
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFFAFAFA),
//                         borderRadius:
//                             BorderRadius.circular(10),
//                         border: Border.all(
//                           color: const Color(0xFFE0E0E0),
//                         ),
//                       ),

//                       child: Column(
//                         children: [
//                           // -----------------------------------------
//                           // VISITING
//                           // -----------------------------------------

//                           RadioListTile<String>(
//                             value: 'Visiting',
//                             groupValue: _teachingMode,

//                             activeColor:
//                                 primaryColor,

//                             title: const Text(
//                               'Visiting',
//                               style: TextStyle(
//                                 fontSize: 14,
//                               ),
//                             ),

//                             subtitle: const Text(
//                               'Tutor can visit the student',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey,
//                               ),
//                             ),

//                             onChanged: (value) {
//                               setState(() {
//                                 _teachingMode = value;
//                               });
//                             },
//                           ),

//                           const Divider(
//                             height: 1,
//                             color: Color(0xFFEAEAEA),
//                           ),

//                           // -----------------------------------------
//                           // NON-VISITING
//                           // -----------------------------------------

//                           RadioListTile<String>(
//                             value: 'Non-Visiting',
//                             groupValue: _teachingMode,

//                             activeColor:
//                                 primaryColor,

//                             title: const Text(
//                               'Non-Visiting',
//                               style: TextStyle(
//                                 fontSize: 14,
//                               ),
//                             ),

//                             subtitle: const Text(
//                               'Student goes to tutor / online',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey,
//                               ),
//                             ),

//                             onChanged: (value) {
//                               setState(() {
//                                 _teachingMode = value;
//                               });
//                             },
//                           ),
//                         ],
//                       ),
//                     ),

//                     const Padding(
//                       padding: EdgeInsets.symmetric(
//                         vertical: 8,
//                       ),

//                       child: Divider(
//                         color: Color(0xFFEEEEEE),
//                       ),
//                     ),

//                     const SizedBox(height: 4),

//                     // =================================================
//                     // SECURITY
//                     // =================================================

//                     const Text(
//                       'SECURITY',
//                       style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.bold,
//                         color: primaryColor,
//                         letterSpacing: 0.5,
//                       ),
//                     ),

//                     const SizedBox(height: 14),

//                     _buildField(
//                       controller:
//                           _passwordController,
//                       label: 'Password',
//                       hint: 'Password',
//                       icon: Icons.lock_outline,
//                       isPassword: true,
//                       obscureText:
//                           _obscurePassword,

//                       onToggleVisibility: () {
//                         setState(() {
//                           _obscurePassword =
//                               !_obscurePassword;
//                         });
//                       },

//                       primaryColor: primaryColor,
//                     ),

//                     _buildField(
//                       controller:
//                           _confirmPasswordController,
//                       label: 'Confirm Password',
//                       hint: 'Confirm Password',
//                       icon: Icons.lock_outline,
//                       isPassword: true,
//                       obscureText:
//                           _obscureConfirmPassword,

//                       onToggleVisibility: () {
//                         setState(() {
//                           _obscureConfirmPassword =
//                               !_obscureConfirmPassword;
//                         });
//                       },

//                       primaryColor: primaryColor,
//                     ),

//                     const SizedBox(height: 10),

//                     // =================================================
//                     // REGISTER BUTTON
//                     // =================================================

//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,

//                       child: isLoading
//                           ? const Center(
//                               child:
//                                   CircularProgressIndicator(
//                                 valueColor:
//                                     AlwaysStoppedAnimation<
//                                         Color>(
//                                   primaryColor,
//                                 ),
//                               ),
//                             )

//                           : ElevatedButton(
//                               onPressed:
//                                   _handleSignup,

//                               style:
//                                   ElevatedButton.styleFrom(
//                                 backgroundColor:
//                                     primaryColor,
//                                 foregroundColor:
//                                     Colors.white,
//                                 elevation: 0,

//                                 shape:
//                                     RoundedRectangleBorder(
//                                   borderRadius:
//                                       BorderRadius.circular(
//                                     10,
//                                   ),
//                                 ),
//                               ),

//                               child: const Text(
//                                 'Register',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight:
//                                       FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                     ),

//                     const SizedBox(height: 12),

//                     // =================================================
//                     // LOGIN
//                     // =================================================

//                     Center(
//                       child: Row(
//                         mainAxisAlignment:
//                             MainAxisAlignment.center,

//                         children: [
//                           const Text(
//                             'Already have an account? ',
//                             style: TextStyle(
//                               color: Colors.black54,
//                               fontSize: 14,
//                             ),
//                           ),

//                           GestureDetector(
//                             onTap: () {
//                               Navigator.pushReplacement(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) =>
//                                       const LoginScreen(),
//                                 ),
//                               );
//                             },

//                             child: const Text(
//                               'Log in',
//                               style: TextStyle(
//                                 color: primaryColor,
//                                 fontWeight:
//                                     FontWeight.bold,
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // =============================================================
//   // TEXT FIELD
//   // =============================================================

//   Widget _buildField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required IconData icon,

//     bool isPassword = false,
//     bool obscureText = false,

//     VoidCallback? onToggleVisibility,

//     TextInputType? keyboardType,

//     required Color primaryColor,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),

//       child: Column(
//         crossAxisAlignment:
//             CrossAxisAlignment.start,

//         children: [
//           Text(
//             label,

//             style: const TextStyle(
//               fontSize: 13,
//               color: Colors.black87,
//               fontWeight: FontWeight.w500,
//             ),
//           ),

//           const SizedBox(height: 6),

//           TextField(
//             controller: controller,

//             obscureText:
//                 isPassword
//                     ? obscureText
//                     : false,

//             keyboardType: keyboardType,

//             decoration: InputDecoration(
//               hintText: hint,

//               hintStyle: const TextStyle(
//                 color: Colors.black38,
//                 fontSize: 14,
//               ),

//               prefixIcon: Icon(
//                 icon,
//                 color: Colors.grey,
//               ),

//               suffixIcon: isPassword
//                   ? IconButton(
//                       icon: Icon(
//                         obscureText
//                             ? Icons.visibility_outlined
//                             : Icons.visibility_off_outlined,
//                         color: Colors.grey,
//                       ),

//                       onPressed:
//                           onToggleVisibility,
//                     )
//                   : null,

//               filled: true,

//               fillColor:
//                   const Color(0xFFFAFAFA),

//               contentPadding:
//                   const EdgeInsets.symmetric(
//                 vertical: 14,
//                 horizontal: 12,
//               ),

//               enabledBorder:
//                   OutlineInputBorder(
//                 borderRadius:
//                     BorderRadius.circular(10),

//                 borderSide:
//                     const BorderSide(
//                   color: Color(0xFFE0E0E0),
//                   width: 1,
//                 ),
//               ),

//               focusedBorder:
//                   OutlineInputBorder(
//                 borderRadius:
//                     BorderRadius.circular(10),

//                 borderSide:
//                     BorderSide(
//                   color: primaryColor,
//                   width: 1.5,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


































// // import 'dart:convert';

// // import 'package:flutter/material.dart';
// // import 'package:house_of_tutor/LoginScreen.dart';
// // import 'package:house_of_tutor/MapLocationScreen.dart';
// // import 'package:house_of_tutor/services/api_client.dart';
// // import 'package:latlong2/latlong.dart';

// // class TutorSignupScreen extends StatefulWidget {
// //   const TutorSignupScreen({super.key});

// //   @override
// //   State<TutorSignupScreen> createState() => _TutorSignupScreenState();
// // }

// // class _TutorSignupScreenState extends State<TutorSignupScreen> {
// //   final _nameController = TextEditingController();
// //   final _cnicController = TextEditingController();
// //   final _phoneController = TextEditingController();
// //   final _emailController = TextEditingController();
// //   final _qualificationController = TextEditingController();
// //   final _radiusController = TextEditingController();
// //   final _experienceController = TextEditingController();
// //   final _passwordController = TextEditingController();
// //   final _confirmPasswordController = TextEditingController();

// //   bool isLoading = false;
// //   bool _obscurePassword = true;
// //   bool _obscureConfirmPassword = true;

// //   @override
// //   void dispose() {
// //     _nameController.dispose();
// //     _cnicController.dispose();
// //     _phoneController.dispose();
// //     _emailController.dispose();
// //     _qualificationController.dispose();
// //     _radiusController.dispose();
// //     _experienceController.dispose();
// //     _passwordController.dispose();
// //     _confirmPasswordController.dispose();
// //     super.dispose();
// //   }

// //   Future<void> _handleSignup() async {
// //     if (isLoading) return;

// //     final name = _nameController.text.trim();
// //     final email = _emailController.text.trim();
// //     final pass = _passwordController.text.trim();
// //     final confirm = _confirmPasswordController.text.trim();
// //     final phone = _phoneController.text.trim();
// //     final cnic = _cnicController.text.trim();
// //     final qualification = _qualificationController.text.trim();
// //     final radiusRaw = _radiusController.text.trim();
// //     final expRaw = _experienceController.text.trim();

// //     // -----------------------------
// //     // VALIDATION
// //     // -----------------------------

// //     if (name.isEmpty ||
// //         email.isEmpty ||
// //         pass.isEmpty ||
// //         cnic.isEmpty) {
// //       _showMessage(
// //         'Please fill name, email, password, and CNIC',
// //       );
// //       return;
// //     }

// //     if (qualification.isEmpty) {
// //       _showMessage('Please enter qualification');
// //       return;
// //     }

// //     if (pass != confirm) {
// //       _showMessage('Passwords do not match');
// //       return;
// //     }

// //     final radius = int.tryParse(radiusRaw);
// //     final experience = int.tryParse(expRaw);

// //     if (radius == null || radius <= 0) {
// //       _showMessage(
// //         'Please enter a valid radius (km, whole number)',
// //       );
// //       return;
// //     }

// //     if (experience == null || experience < 0) {
// //       _showMessage(
// //         'Please enter valid years of experience',
// //       );
// //       return;
// //     }

// //     // -----------------------------
// //     // SELECT LOCATION
// //     // -----------------------------

// //     setState(() {
// //       isLoading = true;
// //     });

// //     LatLng? result;

// //     try {
// //       result = await Navigator.push<LatLng>(
// //         context,
// //         MaterialPageRoute(
// //           builder: (_) => const MapLocationScreen(),
// //         ),
// //       );
// //     } catch (e) {
// //       if (mounted) {
// //         setState(() {
// //           isLoading = false;
// //         });

// //         _showMessage(
// //           'Could not open location map: $e',
// //         );
// //       }
// //       return;
// //     }

// //     if (!mounted) return;

// //     if (result == null) {
// //       setState(() {
// //         isLoading = false;
// //       });

// //       _showMessage('Please select location');
// //       return;
// //     }

// //     // -----------------------------
// //     // REGISTER TUTOR
// //     // -----------------------------

// //     try {
// //       final reg = await ApiClient.post(
// //         '/api/Auth/register',
// //         {
// //           'fullName': name,
// //           'email': email,
// //           'phone': phone.isEmpty ? '—' : phone,
// //           'cnic': cnic,
// //           'password': pass,
// //           'role': 'Tutor',
// //           'qualification': qualification,
// //           'experience': experience,
// //           'radius': radius,
// //         },
// //         auth: false,
// //       );

// //       if (!mounted) return;

// //       if (reg.statusCode < 200 || reg.statusCode >= 300) {
// //         final msg =
// //             ApiClient.messageFromBody(reg.body) ??
// //                 'Registration failed';

// //         _showMessage(msg);

// //         setState(() {
// //           isLoading = false;
// //         });

// //         return;
// //       }

// //       // -----------------------------
// //       // PARSE REGISTER RESPONSE
// //       // -----------------------------

// //       Map<String, dynamic> regData;

// //       try {
// //         regData = jsonDecode(
// //           utf8.decode(reg.bodyBytes),
// //         ) as Map<String, dynamic>;
// //       } catch (e) {
// //         _showMessage(
// //           'Invalid registration response from server',
// //         );

// //         setState(() {
// //           isLoading = false;
// //         });

// //         return;
// //       }

// //       final userIdValue = regData['userId'];

// //       if (userIdValue == null) {
// //         _showMessage(
// //           'Registration successful, but user ID was not returned.',
// //         );

// //         setState(() {
// //           isLoading = false;
// //         });

// //         return;
// //       }

// //       final int? uid = int.tryParse(
// //         userIdValue.toString(),
// //       );

// //       if (uid == null || uid <= 0) {
// //         _showMessage(
// //           'Invalid user ID returned by server.',
// //         );

// //         setState(() {
// //           isLoading = false;
// //         });

// //         return;
// //       }

// //       // -----------------------------
// //       // SAVE TUTOR LOCATION
// //       // -----------------------------

// //       final loc = await ApiClient.post(
// //         '/api/Auth/update-location',
// //         {
// //           'userId': uid,
// //           'latitude': result.latitude,
// //           'longitude': result.longitude,
// //         },
// //         auth: false,
// //       );

// //       if (!mounted) return;

// //       if (loc.statusCode < 200 || loc.statusCode >= 300) {
// //         final msg =
// //             ApiClient.messageFromBody(loc.body) ??
// //                 'Could not save location';

// //         _showMessage(msg);

// //         setState(() {
// //           isLoading = false;
// //         });

// //         return;
// //       }

// //       // ------------------------------------------------
// //       // IMPORTANT:
// //       // DO NOT USE AuthStore HERE.
// //       //
// //       // Tutor is not logged in yet.
// //       // Location has already been saved to the database
// //       // using /api/Auth/update-location.
// //       // ------------------------------------------------

// //       _showMessage(
// //         'Account created successfully. Please log in.',
// //       );

// //       await Future.delayed(
// //         const Duration(milliseconds: 700),
// //       );

// //       if (!mounted) return;

// //       Navigator.pushAndRemoveUntil(
// //         context,
// //         MaterialPageRoute(
// //           builder: (_) => const LoginScreen(),
// //         ),
// //         (route) => false,
// //       );
// //     } catch (e) {
// //       if (!mounted) return;

// //       _showMessage(
// //         'Network error: $e',
// //       );
// //     } finally {
// //       if (mounted) {
// //         setState(() {
// //           isLoading = false;
// //         });
// //       }
// //     }
// //   }

// //   void _showMessage(String msg) {
// //     if (!mounted) return;

// //     ScaffoldMessenger.of(context)
// //       ..hideCurrentSnackBar()
// //       ..showSnackBar(
// //         SnackBar(
// //           content: Text(msg),
// //           behavior: SnackBarBehavior.floating,
// //         ),
// //       );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     const primaryColor = Color(0xFF139675);

// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF7F7F7),
// //       body: SafeArea(
// //         child: SingleChildScrollView(
// //           padding: const EdgeInsets.symmetric(
// //             horizontal: 20,
// //             vertical: 12,
// //           ),
// //           child: Column(
// //             children: [
// //               const SizedBox(height: 10),

// //               // -----------------------------
// //               // HEADER
// //               // -----------------------------

// //               Column(
// //                 children: [
// //                   Image.asset(
// //                     'assets/images/logo.png',
// //                     height: 70,
// //                   ),
// //                   const SizedBox(height: 12),
// //                   const Text(
// //                     'Create Tutor Account',
// //                     style: TextStyle(
// //                       fontSize: 22,
// //                       fontWeight: FontWeight.bold,
// //                       color: Colors.black87,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 6),
// //                   const Text(
// //                     'Set up your profile to start teaching on the platform',
// //                     textAlign: TextAlign.center,
// //                     style: TextStyle(
// //                       fontSize: 14,
// //                       color: Colors.grey,
// //                     ),
// //                   ),
// //                 ],
// //               ),

// //               const SizedBox(height: 20),

// //               // -----------------------------
// //               // MAIN CARD
// //               // -----------------------------

// //               Container(
// //                 padding: const EdgeInsets.all(20),
// //                 decoration: BoxDecoration(
// //                   color: Colors.white,
// //                   borderRadius: BorderRadius.circular(16),
// //                   boxShadow: [
// //                     BoxShadow(
// //                       color: Colors.black.withOpacity(0.05),
// //                       blurRadius: 10,
// //                       offset: const Offset(0, 4),
// //                     ),
// //                   ],
// //                 ),
// //                 child: Column(
// //                   crossAxisAlignment:
// //                       CrossAxisAlignment.start,
// //                   children: [
// //                     // -----------------------------
// //                     // PERSONAL DETAILS
// //                     // -----------------------------

// //                     const Text(
// //                       'PERSONAL DETAILS',
// //                       style: TextStyle(
// //                         fontSize: 13,
// //                         fontWeight: FontWeight.bold,
// //                         color: primaryColor,
// //                         letterSpacing: 0.5,
// //                       ),
// //                     ),

// //                     const SizedBox(height: 14),

// //                     _buildField(
// //                       controller: _nameController,
// //                       label: 'Full Name',
// //                       hint: 'Full Name',
// //                       icon: Icons.person_outline,
// //                       primaryColor: primaryColor,
// //                     ),

// //                     _buildField(
// //                       controller: _cnicController,
// //                       label: 'CNIC',
// //                       hint: 'CNIC',
// //                       icon: Icons.badge_outlined,
// //                       primaryColor: primaryColor,
// //                     ),

// //                     _buildField(
// //                       controller: _phoneController,
// //                       label: 'Phone',
// //                       hint: 'Phone',
// //                       icon: Icons.phone_outlined,
// //                       primaryColor: primaryColor,
// //                       keyboardType:
// //                           TextInputType.phone,
// //                     ),

// //                     _buildField(
// //                       controller: _emailController,
// //                       label: 'Email',
// //                       hint: 'Email',
// //                       icon: Icons.email_outlined,
// //                       primaryColor: primaryColor,
// //                       keyboardType:
// //                           TextInputType.emailAddress,
// //                     ),

// //                     const Padding(
// //                       padding:
// //                           EdgeInsets.symmetric(vertical: 8),
// //                       child: Divider(
// //                         color: Color(0xFFEEEEEE),
// //                       ),
// //                     ),

// //                     const SizedBox(height: 4),

// //                     // -----------------------------
// //                     // TEACHING DETAILS
// //                     // -----------------------------

// //                     const Text(
// //                       'TEACHING DETAILS',
// //                       style: TextStyle(
// //                         fontSize: 13,
// //                         fontWeight: FontWeight.bold,
// //                         color: primaryColor,
// //                         letterSpacing: 0.5,
// //                       ),
// //                     ),

// //                     const SizedBox(height: 14),

// //                     _buildField(
// //                       controller:
// //                           _qualificationController,
// //                       label: 'Qualification',
// //                       hint: 'Qualification',
// //                       icon: Icons.school_outlined,
// //                       primaryColor: primaryColor,
// //                     ),

// //                     Row(
// //                       crossAxisAlignment:
// //                           CrossAxisAlignment.start,
// //                       children: [
// //                         Expanded(
// //                           child: _buildField(
// //                             controller:
// //                                 _radiusController,
// //                             label: 'Radius (km)',
// //                             hint: 'Radius',
// //                             icon: Icons.location_on_outlined,
// //                             primaryColor:
// //                                 primaryColor,
// //                             keyboardType:
// //                                 TextInputType.number,
// //                           ),
// //                         ),

// //                         const SizedBox(width: 12),

// //                         Expanded(
// //                           child: _buildField(
// //                             controller:
// //                                 _experienceController,
// //                             label:
// //                                 'Experience (years)',
// //                             hint: 'Experience',
// //                             icon: Icons.work_outline,
// //                             primaryColor:
// //                                 primaryColor,
// //                             keyboardType:
// //                                 TextInputType.number,
// //                           ),
// //                         ),
// //                       ],
// //                     ),

// //                     const Padding(
// //                       padding:
// //                           EdgeInsets.symmetric(vertical: 8),
// //                       child: Divider(
// //                         color: Color(0xFFEEEEEE),
// //                       ),
// //                     ),

// //                     const SizedBox(height: 4),

// //                     // -----------------------------
// //                     // SECURITY
// //                     // -----------------------------

// //                     const Text(
// //                       'SECURITY',
// //                       style: TextStyle(
// //                         fontSize: 13,
// //                         fontWeight: FontWeight.bold,
// //                         color: primaryColor,
// //                         letterSpacing: 0.5,
// //                       ),
// //                     ),

// //                     const SizedBox(height: 14),

// //                     _buildField(
// //                       controller:
// //                           _passwordController,
// //                       label: 'Password',
// //                       hint: 'Password',
// //                       icon: Icons.lock_outline,
// //                       isPassword: true,
// //                       obscureText:
// //                           _obscurePassword,
// //                       onToggleVisibility: () {
// //                         setState(() {
// //                           _obscurePassword =
// //                               !_obscurePassword;
// //                         });
// //                       },
// //                       primaryColor: primaryColor,
// //                     ),

// //                     _buildField(
// //                       controller:
// //                           _confirmPasswordController,
// //                       label: 'Confirm Password',
// //                       hint: 'Confirm Password',
// //                       icon: Icons.lock_outline,
// //                       isPassword: true,
// //                       obscureText:
// //                           _obscureConfirmPassword,
// //                       onToggleVisibility: () {
// //                         setState(() {
// //                           _obscureConfirmPassword =
// //                               !_obscureConfirmPassword;
// //                         });
// //                       },
// //                       primaryColor: primaryColor,
// //                     ),

// //                     const SizedBox(height: 10),

// //                     // -----------------------------
// //                     // REGISTER BUTTON
// //                     // -----------------------------

// //                     SizedBox(
// //                       width: double.infinity,
// //                       height: 50,
// //                       child: isLoading
// //                           ? const Center(
// //                               child:
// //                                   CircularProgressIndicator(
// //                                 valueColor:
// //                                     AlwaysStoppedAnimation<
// //                                         Color>(
// //                                   primaryColor,
// //                                 ),
// //                               ),
// //                             )
// //                           : ElevatedButton(
// //                               onPressed:
// //                                   _handleSignup,
// //                               style:
// //                                   ElevatedButton.styleFrom(
// //                                 backgroundColor:
// //                                     primaryColor,
// //                                 foregroundColor:
// //                                     Colors.white,
// //                                 elevation: 0,
// //                                 shape:
// //                                     RoundedRectangleBorder(
// //                                   borderRadius:
// //                                       BorderRadius
// //                                           .circular(10),
// //                                 ),
// //                               ),
// //                               child: const Text(
// //                                 'Register',
// //                                 style: TextStyle(
// //                                   fontSize: 16,
// //                                   fontWeight:
// //                                       FontWeight.bold,
// //                                 ),
// //                               ),
// //                             ),
// //                     ),

// //                     const SizedBox(height: 12),

// //                     // -----------------------------
// //                     // LOGIN
// //                     // -----------------------------

// //                     Center(
// //                       child: Row(
// //                         mainAxisAlignment:
// //                             MainAxisAlignment.center,
// //                         children: [
// //                           const Text(
// //                             'Already have an account? ',
// //                             style: TextStyle(
// //                               color: Colors.black54,
// //                               fontSize: 14,
// //                             ),
// //                           ),
// //                           GestureDetector(
// //                             onTap: () {
// //                               Navigator.pushReplacement(
// //                                 context,
// //                                 MaterialPageRoute(
// //                                   builder: (_) =>
// //                                       const LoginScreen(),
// //                                 ),
// //                               );
// //                             },
// //                             child: const Text(
// //                               'Log in',
// //                               style: TextStyle(
// //                                 color: primaryColor,
// //                                 fontWeight:
// //                                     FontWeight.bold,
// //                                 fontSize: 14,
// //                               ),
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),

// //               const SizedBox(height: 20),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildField({
// //     required TextEditingController controller,
// //     required String label,
// //     required String hint,
// //     required IconData icon,
// //     bool isPassword = false,
// //     bool obscureText = false,
// //     VoidCallback? onToggleVisibility,
// //     TextInputType? keyboardType,
// //     required Color primaryColor,
// //   }) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 16),
// //       child: Column(
// //         crossAxisAlignment:
// //             CrossAxisAlignment.start,
// //         children: [
// //           Text(
// //             label,
// //             style: const TextStyle(
// //               fontSize: 13,
// //               color: Colors.black87,
// //               fontWeight: FontWeight.w500,
// //             ),
// //           ),

// //           const SizedBox(height: 6),

// //           TextField(
// //             controller: controller,
// //             obscureText:
// //                 isPassword ? obscureText : false,
// //             keyboardType: keyboardType,
// //             decoration: InputDecoration(
// //               hintText: hint,
// //               hintStyle: const TextStyle(
// //                 color: Colors.black38,
// //                 fontSize: 14,
// //               ),
// //               prefixIcon: Icon(
// //                 icon,
// //                 color: Colors.grey,
// //               ),
// //               suffixIcon: isPassword
// //                   ? IconButton(
// //                       icon: Icon(
// //                         obscureText
// //                             ? Icons
// //                                 .visibility_outlined
// //                             : Icons
// //                                 .visibility_off_outlined,
// //                         color: Colors.grey,
// //                       ),
// //                       onPressed:
// //                           onToggleVisibility,
// //                     )
// //                   : null,
// //               filled: true,
// //               fillColor:
// //                   const Color(0xFFFAFAFA),
// //               contentPadding:
// //                   const EdgeInsets.symmetric(
// //                 vertical: 14,
// //                 horizontal: 12,
// //               ),
// //               enabledBorder:
// //                   OutlineInputBorder(
// //                 borderRadius:
// //                     BorderRadius.circular(10),
// //                 borderSide:
// //                     const BorderSide(
// //                   color: Color(0xFFE0E0E0),
// //                   width: 1,
// //                 ),
// //               ),
// //               focusedBorder:
// //                   OutlineInputBorder(
// //                 borderRadius:
// //                     BorderRadius.circular(10),
// //                 borderSide: BorderSide(
// //                   color: primaryColor,
// //                   width: 1.5,
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }