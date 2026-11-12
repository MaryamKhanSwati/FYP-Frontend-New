import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:house_of_tutor/LoginScreen.dart';
import 'package:house_of_tutor/MapLocationScreen.dart';
import 'package:house_of_tutor/services/api_client.dart';
import 'package:latlong2/latlong.dart';

class StudentSignupScreen extends StatefulWidget {
  const StudentSignupScreen({super.key});

  @override
  State<StudentSignupScreen> createState() => _StudentSignupScreenState();
}

class _StudentSignupScreenState extends State<StudentSignupScreen> {
  final _nameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _fatherCnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // ⭐ NEW:
  // Student fee responsibility.
  // Backend accepts only: ByMe OR ByParent
  String? _feeResponsibility;

  @override
  void dispose() {
    _nameController.dispose();
    _fatherCnicController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    final phone = _phoneController.text.trim();
    final cnic = _cnicController.text.trim();
    final fatherCnic = _fatherCnicController.text.trim();

    // =====================================================
    // VALIDATION
    // =====================================================

    if (name.isEmpty ||
        email.isEmpty ||
        pass.isEmpty ||
        cnic.isEmpty ||
        fatherCnic.isEmpty) {
      _showMessage(
        'Please fill name, email, password, CNIC, and Father CNIC',
      );
      return;
    }

    if (pass != confirm) {
      _showMessage('Passwords do not match');
      return;
    }

    // ⭐ NEW:
    // Backend requires feeResponsibility for Student.
    if (_feeResponsibility == null) {
      _showMessage('Please select who will discuss the fee');
      return;
    }

    setState(() => isLoading = true);

    // =====================================================
    // SELECT LOCATION
    // =====================================================

    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => const MapLocationScreen(),
      ),
    );

    if (!mounted) return;

    if (result == null) {
      setState(() => isLoading = false);
      _showMessage('Please select location');
      return;
    }

    try {
      // =====================================================
      // 1. REGISTER STUDENT
      // =====================================================

      final reg = await ApiClient.post(
        '/api/Auth/register',
        {
          'fullName': name,
          'email': email,
          'phone': phone.isEmpty ? '—' : phone,
          'cnic': cnic,
          'fatherCNIC': fatherCnic,
          'password': pass,
          'role': 'Student',

          // ⭐ NEW:
          // VERY IMPORTANT.
          // Backend checks this value:
          //
          // "ByMe"
          // OR
          // "ByParent"
          //
          'feeResponsibility': _feeResponsibility,
        },
        auth: false,
      );

      // =====================================================
      // CHECK REGISTRATION RESPONSE
      // =====================================================

      if (reg.statusCode != 200) {
        final msg =
            ApiClient.messageFromBody(reg.body) ??
            'Registration failed';

        if (mounted) {
          _showMessage(msg);
          setState(() => isLoading = false);
        }

        return;
      }

      // =====================================================
      // 2. READ USER ID
      // =====================================================

      final regData =
          jsonDecode(
            utf8.decode(reg.bodyBytes),
          ) as Map<String, dynamic>;

      final userId = regData['userId'];

      if (userId == null) {
        if (mounted) {
          _showMessage(
            'Unexpected server response: userId missing',
          );
          setState(() => isLoading = false);
        }

        return;
      }

      final uid = userId is int
          ? userId
          : int.tryParse(userId.toString());

      if (uid == null) {
        if (mounted) {
          _showMessage(
            'Invalid user ID returned by server',
          );
          setState(() => isLoading = false);
        }

        return;
      }

      // =====================================================
      // 3. SAVE LOCATION
      // =====================================================

      final loc = await ApiClient.post(
        '/api/Auth/update-location',
        {
          'userId': uid,
          'latitude': result.latitude,
          'longitude': result.longitude,
        },
        auth: false,
      );

      if (loc.statusCode != 200) {
        final msg =
            ApiClient.messageFromBody(loc.body) ??
            'Could not save location';

        if (mounted) {
          _showMessage(msg);
          setState(() => isLoading = false);
        }

        return;
      }

      // =====================================================
      // LOCATION SAVED
      // =====================================================
      //
      // We DO NOT save location in AuthStore here.
      //
      // Student is not logged in yet.
      //
      // Login API should return latitude/longitude,
      // then LoginScreen can save it into AuthStore.
      // =====================================================

      if (!mounted) return;

      _showMessage(
        'Account created. Please log in.',
      );

      // =====================================================
      // 4. GO TO LOGIN
      // =====================================================

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Network error: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF139675);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // =====================================================
              // HEADER
              // =====================================================

              Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 70,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Create Your Account',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Fill in your details to get started as a student',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // =====================================================
              // FORM CONTAINER
              // =====================================================

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =====================================================
                    // PERSONAL DETAILS
                    // =====================================================

                    const Text(
                      'PERSONAL DETAILS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF139675),
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _buildField(
                      controller: _nameController,
                      label: 'Enter Your Full Name',
                      hint: 'Enter Your Full Name',
                      icon: Icons.person_outline,
                      primaryColor: primaryColor,
                    ),

                    _buildField(
                      controller: _cnicController,
                      label: 'Enter Your CNIC',
                      hint: 'Enter Your CNIC',
                      icon: Icons.badge_outlined,
                      primaryColor: primaryColor,
                    ),

                    _buildField(
                      controller: _fatherCnicController,
                      label: "Enter Father's CNIC",
                      hint: "Enter Father's CNIC",
                      icon: Icons.people_outline,
                      primaryColor: primaryColor,
                    ),

                    _buildField(
                      controller: _phoneController,
                      label: 'Enter Phone Number',
                      hint: 'Enter Phone Number',
                      icon: Icons.phone_outlined,
                      primaryColor: primaryColor,
                      keyboardType: TextInputType.phone,
                    ),

                    _buildField(
                      controller: _emailController,
                      label: 'Enter Email',
                      hint: 'Enter Email',
                      icon: Icons.email_outlined,
                      primaryColor: primaryColor,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 8.0,
                      ),
                      child: Divider(
                        color: Color(0xFFEEEEEE),
                      ),
                    ),

                    // =====================================================
                    // ⭐ NEW: FEE RESPONSIBILITY
                    // =====================================================

                    const SizedBox(height: 4),

                    const Text(
                      'FEE DISCUSS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF139675),
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Who will discuss the fee?',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ⭐ NEW:
                    // By Me / By Parent selection
                    Row(
                      children: [
                        Expanded(
                          child: _buildFeeOption(
                            title: 'By Me',
                            value: 'ByMe',
                            primaryColor: primaryColor,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: _buildFeeOption(
                            title: 'By Parent',
                            value: 'ByParent',
                            primaryColor: primaryColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 8.0,
                      ),
                      child: Divider(
                        color: Color(0xFFEEEEEE),
                      ),
                    ),

                    // =====================================================
                    // SECURITY
                    // =====================================================

                    const SizedBox(height: 4),

                    const Text(
                      'SECURITY',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF139675),
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _buildField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscurePassword =
                              !_obscurePassword;
                        });
                      },
                      primaryColor: primaryColor,
                    ),

                    _buildField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      hint: 'Confirm Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: _obscureConfirmPassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                        });
                      },
                      primaryColor: primaryColor,
                    ),

                    const SizedBox(height: 10),

                    // =====================================================
                    // REGISTER BUTTON
                    // =====================================================

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: isLoading
                          ? Center(
                              child:
                                  CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                  primaryColor,
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _handleSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    primaryColor,
                                foregroundColor:
                                    Colors.white,
                                elevation: 0,
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    10,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Register',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 12),

                    // =====================================================
                    // LOGIN
                    // =====================================================

                    Center(
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const LoginScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Log in',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight:
                                    FontWeight.bold,
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

  // =====================================================
  // ⭐ NEW: FEE OPTION WIDGET
  // =====================================================

  Widget _buildFeeOption({
    required String title,
    required String value,
    required Color primaryColor,
  }) {
    final bool selected =
        _feeResponsibility == value;

    return InkWell(
      onTap: () {
        setState(() {
          _feeResponsibility = value;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor.withOpacity(0.08)
              : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? primaryColor
                : const Color(0xFFE0E0E0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _feeResponsibility,
              activeColor: primaryColor,
              onChanged: (newValue) {
                setState(() {
                  _feeResponsibility = newValue;
                });
              },
            ),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // TEXT FIELD
  // =====================================================

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
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          TextField(
            controller: controller,
            obscureText:
                isPassword ? obscureText : false,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
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
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey,
                      ),
                      onPressed:
                          onToggleVisibility,
                    )
                  : null,
              filled: true,
              fillColor:
                  const Color(0xFFFAFAFA),
              contentPadding:
                  const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 12,
              ),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(10),
                borderSide:
                    const BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(10),
                borderSide: BorderSide(
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

// class StudentSignupScreen extends StatefulWidget {
//   const StudentSignupScreen({super.key});

//   @override
//   State<StudentSignupScreen> createState() => _StudentSignupScreenState();
// }

// class _StudentSignupScreenState extends State<StudentSignupScreen> {
//   final _nameController = TextEditingController();
//   final _cnicController = TextEditingController();
//   final _fatherCnicController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();

//   bool isLoading = false;
//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _fatherCnicController.dispose();
//     _cnicController.dispose();
//     _phoneController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   Future<void> _handleSignup() async {
//   final name = _nameController.text.trim();
//   final email = _emailController.text.trim();
//   final pass = _passwordController.text.trim();
//   final confirm = _confirmPasswordController.text.trim();
//   final phone = _phoneController.text.trim();
//   final cnic = _cnicController.text.trim();
//   final fatherCnic = _fatherCnicController.text.trim();

//   if (name.isEmpty ||
//       email.isEmpty ||
//       pass.isEmpty ||
//       cnic.isEmpty ||
//       fatherCnic.isEmpty) {
//     _showMessage(
//       'Please fill name, email, password, CNIC, and Father CNIC',
//     );
//     return;
//   }

//   if (pass != confirm) {
//     _showMessage('Passwords do not match');
//     return;
//   }

//   setState(() => isLoading = true);

//   // Select student location first
//   final result = await Navigator.push<LatLng>(
//     context,
//     MaterialPageRoute(
//       builder: (_) => const MapLocationScreen(),
//     ),
//   );

//   if (!mounted) return;

//   if (result == null) {
//     setState(() => isLoading = false);
//     _showMessage('Please select location');
//     return;
//   }

//   try {
//     // -----------------------------
//     // 1. REGISTER STUDENT
//     // -----------------------------
//     final reg = await ApiClient.post(
//       '/api/Auth/register',
//       {
//         'fullName': name,
//         'email': email,
//         'phone': phone.isEmpty ? '—' : phone,
//         'cnic': cnic,
//         'fatherCNIC': fatherCnic,
//         'password': pass,
//         'role': 'Student',
//       },
//       auth: false,
//     );

//     if (reg.statusCode != 200) {
//       final msg =
//           ApiClient.messageFromBody(reg.body) ??
//           'Registration failed';

//       if (mounted) {
//         _showMessage(msg);
//         setState(() => isLoading = false);
//       }
//       return;
//     }

//     // -----------------------------
//     // 2. READ USER ID
//     // -----------------------------
//     final regData =
//         jsonDecode(utf8.decode(reg.bodyBytes)) as Map<String, dynamic>;

//     final userId = regData['userId'];

//     if (userId == null) {
//       if (mounted) {
//         _showMessage('Unexpected server response: userId missing');
//         setState(() => isLoading = false);
//       }
//       return;
//     }

//     final uid = userId is int
//         ? userId
//         : int.tryParse(userId.toString());

//     if (uid == null) {
//       if (mounted) {
//         _showMessage('Invalid user ID returned by server');
//         setState(() => isLoading = false);
//       }
//       return;
//     }

//     // -----------------------------
//     // 3. SAVE LOCATION
//     // -----------------------------
//     final loc = await ApiClient.post(
//       '/api/Auth/update-location',
//       {
//         'userId': uid,
//         'latitude': result.latitude,
//         'longitude': result.longitude,
//       },
//       auth: false,
//     );

//     if (loc.statusCode != 200) {
//       final msg =
//           ApiClient.messageFromBody(loc.body) ??
//           'Could not save location';

//       if (mounted) {
//         _showMessage(msg);
//         setState(() => isLoading = false);
//       }
//       return;
//     }

//     // IMPORTANT:
//     // Do NOT call AuthStore.setLastLocation() here.
//     //
//     // The user is not logged in yet.
//     // Location is already saved in the database.
//     //
//     // LoginScreen will receive the location from the login API
//     // and save it into AuthStore.

//     if (!mounted) return;

//     _showMessage('Account created. Please log in.');

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (_) => const LoginScreen(),
//       ),
//     );
//   } catch (e) {
//     if (mounted) {
//       _showMessage('Network error: $e');
//     }
//   } finally {
//     if (mounted) {
//       setState(() => isLoading = false);
//     }
//   }
// }

//   void _showMessage(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg)),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final primaryColor = const Color(0xFF139675);

//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F7),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//           child: Column(
//             children: [
//               const SizedBox(height: 10),
//               Column(
//                 children: [
//                   Image.asset(
//                     'assets/images/logo.png',
//                     height: 70,
//                   ),
//                   const SizedBox(height: 12),
//                   const Text(
//                     'Create Your Account',
//                     style: TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   const Text(
//                     'Fill in your details to get started as a student',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
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
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'PERSONAL DETAILS',
//                       style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF139675),
//                         letterSpacing: 0.5,
//                       ),
//                     ),
//                     const SizedBox(height: 14),
//                     _buildField(
//                       controller: _nameController,
//                       label: 'Enter Your Full Name',
//                       hint: 'Enter Your Full Name',
//                       icon: Icons.person_outline,
//                       primaryColor: primaryColor,
//                     ),
//                     _buildField(
//                       controller: _cnicController,
//                       label: 'Enter Your CNIC',
//                       hint: 'Enter Your CNIC',
//                       icon: Icons.badge_outlined,
//                       primaryColor: primaryColor,
//                     ),
//                     _buildField(
//                       controller: _fatherCnicController,
//                       label: "Enter Father's CNIC",
//                       hint: "Enter Father's CNIC",
//                       icon: Icons.people_outline,
//                       primaryColor: primaryColor,
//                     ),
//                     _buildField(
//                       controller: _phoneController,
//                       label: 'Enter Phone Number',
//                       hint: 'Enter Phone Number',
//                       icon: Icons.phone_outlined,
//                       primaryColor: primaryColor,
//                       keyboardType: TextInputType.phone,
//                     ),
//                     _buildField(
//                       controller: _emailController,
//                       label: 'Enter Email',
//                       hint: 'Enter Email',
//                       icon: Icons.email_outlined,
//                       primaryColor: primaryColor,
//                       keyboardType: TextInputType.emailAddress,
//                     ),
//                     const Padding(
//                       padding: EdgeInsets.symmetric(vertical: 8.0),
//                       child: Divider(color: Color(0xFFEEEEEE)),
//                     ),
//                     const SizedBox(height: 4),
//                     const Text(
//                       'SECURITY',
//                       style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF139675),
//                         letterSpacing: 0.5,
//                       ),
//                     ),
//                     const SizedBox(height: 14),
//                     _buildField(
//                       controller: _passwordController,
//                       label: 'Password',
//                       hint: 'Password',
//                       icon: Icons.lock_outline,
//                       isPassword: true,
//                       obscureText: _obscurePassword,
//                       onToggleVisibility: () {
//                         setState(() {
//                           _obscurePassword = !_obscurePassword;
//                         });
//                       },
//                       primaryColor: primaryColor,
//                     ),
//                     _buildField(
//                       controller: _confirmPasswordController,
//                       label: 'Confirm Password',
//                       hint: 'Confirm Password',
//                       icon: Icons.lock_outline,
//                       isPassword: true,
//                       obscureText: _obscureConfirmPassword,
//                       onToggleVisibility: () {
//                         setState(() {
//                           _obscureConfirmPassword = !_obscureConfirmPassword;
//                         });
//                       },
//                       primaryColor: primaryColor,
//                     ),
//                     const SizedBox(height: 10),
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: isLoading
//                           ? Center(
//                               child: CircularProgressIndicator(
//                                 valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
//                               ),
//                             )
//                           : ElevatedButton(
//                               onPressed: _handleSignup,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: primaryColor,
//                                 foregroundColor: Colors.white,
//                                 elevation: 0,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                               ),
//                               child: const Text(
//                                 'Register',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                     ),
//                     const SizedBox(height: 12),
//                     Center(
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Text(
//                             'Already have an account? ',
//                             style: TextStyle(color: Colors.black54, fontSize: 14),
//                           ),
//                           GestureDetector(
//                             onTap: () {
//                               Navigator.pushReplacement(
//                                 context,
//                                 MaterialPageRoute(builder: (_) => const LoginScreen()),
//                               );
//                             },
//                             child: Text(
//                               'Log in',
//                               style: TextStyle(
//                                 color: primaryColor,
//                                 fontWeight: FontWeight.bold,
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
//         crossAxisAlignment: CrossAxisAlignment.start,
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
//             obscureText: isPassword ? obscureText : false,
//             keyboardType: keyboardType,
//             decoration: InputDecoration(
//               hintText: hint,
//               hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
//               prefixIcon: Icon(icon, color: Colors.grey),
//               suffixIcon: isPassword
//                   ? IconButton(
//                       icon: Icon(
//                         obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
//                         color: Colors.grey,
//                       ),
//                       onPressed: onToggleVisibility,
//                     )
//                   : null,
//               filled: true,
//               fillColor: const Color(0xFFFAFAFA),
//               contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: BorderSide(color: primaryColor, width: 1.5),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
