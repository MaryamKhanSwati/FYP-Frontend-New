import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:house_of_tutor/services/api_client.dart';

class ParentChildProfile extends StatefulWidget {
  final Map<String, dynamic> child;

  const ParentChildProfile({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<ParentChildProfile> createState() => _ParentChildProfileState();
}

class _ParentChildProfileState extends State<ParentChildProfile> {
  // ============================================================
  // VARIABLES
  // ============================================================

  Map<String, dynamic> studentProfile = {};

  bool isLoading = true;

  // ============================================================
  // COLORS
  // Change colors here if you want
  // ============================================================

  static const Color primaryColor = Color(0xFF00897B);
  static const Color darkPrimaryColor = Color(0xFF00695C);
  static const Color backgroundColor = Color(0xFFF5F7F8);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    // Load child profile when screen opens
    fetchChildProfile();
  }

  // ============================================================
  // GET CHILD PROFILE API
  // ============================================================

  Future<void> fetchChildProfile() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      // --------------------------------------------------------
      // Get Student ID from previous screen
      // --------------------------------------------------------

      final studentId = widget.child['studentId'];

      if (studentId == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }

        _showSnackBar("Student ID is not available.");
        return;
      }

      debugPrint("========================================");
      debugPrint("GET CHILD PROFILE");
      debugPrint("Student ID: $studentId");
      debugPrint("========================================");

      // --------------------------------------------------------
      // API CALL
      // --------------------------------------------------------

      final response = await ApiClient.get(
        '/api/Parent/child-profile/$studentId',
      );

      debugPrint("PROFILE STATUS: ${response.statusCode}");
      debugPrint("PROFILE BODY: ${response.body}");

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      if (response.statusCode == 200) {
        final data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        if (mounted) {
          setState(() {
            studentProfile =
                data is Map<String, dynamic> ? data : {};

            isLoading = false;
          });
        }

        return;
      }

      // --------------------------------------------------------
      // ERROR RESPONSE
      // --------------------------------------------------------

      String errorMessage = "Failed to load child profile.";

      if (response.body.isNotEmpty) {
        try {
          final data = jsonDecode(response.body);

          if (data is Map<String, dynamic>) {
            errorMessage =
                data['message'] ??
                data['error'] ??
                errorMessage;
          }
        } catch (_) {
          errorMessage = response.body;
        }
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      _showSnackBar(errorMessage);
    } catch (e) {
      debugPrint("CHILD PROFILE ERROR: $e");

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      _showSnackBar(
        "Unable to load child profile.",
      );
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ----------------------------------------------------------
    // Get profile values
    // API value is preferred.
    // If API value does not exist, previous child value is used.
    // ----------------------------------------------------------

    final String fullName =
        _getValue(
          studentProfile['fullName'],
          widget.child['fullName'],
          "Student",
        );

    final String email =
        _getValue(
          studentProfile['email'],
          widget.child['email'],
          "Not Available",
        );

    final String phone =
        _getValue(
          studentProfile['phone'],
          widget.child['phone'],
          "Not Available",
        );

    final String cnic =
        _getValue(
          studentProfile['cnic'],
          null,
          "Not Available",
        );

    final String location =
        _getValue(
          studentProfile['location'],
          null,
          "Location not available",
        );

    final String latitude =
        _getValue(
          studentProfile['latitude'],
          null,
          "N/A",
        );

    final String longitude =
        _getValue(
          studentProfile['longitude'],
          null,
          "N/A",
        );

    return Scaffold(
      backgroundColor: backgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        // ------------------------------------------------------
        // BACK BUTTON
        // ------------------------------------------------------

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: darkPrimaryColor,
            size: 20,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),

        centerTitle: true,

        // ------------------------------------------------------
        // AESTHETIC HOUSE OF TUTOR LOGO
        // ------------------------------------------------------

        title: _buildLogo(),

        // Small shadow/bottom line
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: isLoading
          ? _buildLoading()
          : RefreshIndicator(
              color: primaryColor,
              onRefresh: fetchChildProfile,

              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  30,
                ),

                child: Column(
                  children: [

                    // ==================================================
                    // PROFILE HEADER
                    // ==================================================

                    _buildProfileHeader(
                      fullName: fullName,
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // CONTACT DETAILS
                    // ==================================================

                    _buildSectionCard(
                      title: "CONTACT DETAILS",
                      icon: Icons.contact_page_outlined,

                      children: [

                        _buildInfoTile(
                          icon: Icons.email_outlined,
                          title: "Email Address",
                          value: email,
                        ),

                        _buildDivider(),

                        _buildInfoTile(
                          icon: Icons.phone_outlined,
                          title: "Phone Number",
                          value: phone,
                        ),

                        _buildDivider(),

                        _buildInfoTile(
                          icon: Icons.badge_outlined,
                          title: "CNIC / National ID",
                          value: cnic,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // LOCATION DETAILS
                    // ==================================================

                    _buildSectionCard(
                      title: "LOCATION & COORDINATES",
                      icon: Icons.location_on_outlined,

                      children: [

                        _buildInfoTile(
                          icon: Icons.location_on_outlined,
                          title: "Primary Address",
                          value: location,
                        ),

                        _buildDivider(),

                        _buildInfoTile(
                          icon: Icons.navigation_outlined,
                          title: "Latitude",
                          value: latitude,
                        ),

                        _buildDivider(),

                        _buildInfoTile(
                          icon: Icons.explore_outlined,
                          title: "Longitude",
                          value: longitude,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // FOOTER
                    // ==================================================

                    Text(
                      "House of Tutor",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "Student Profile",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================
  // GET VALUE SAFELY
  // ============================================================

  String _getValue(
    dynamic apiValue,
    dynamic oldValue,
    String defaultValue,
  ) {
    if (apiValue != null &&
        apiValue.toString().trim().isNotEmpty) {
      return apiValue.toString();
    }

    if (oldValue != null &&
        oldValue.toString().trim().isNotEmpty) {
      return oldValue.toString();
    }

    return defaultValue;
  }

  // ============================================================
  // AESTHETIC LOGO
  //
  // Change logo path here if your image is somewhere else.
  //
  // Current:
  // assets/images/logo.png
  // ============================================================

  Widget _buildLogo() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(
          color: Colors.teal.shade50,
          width: 1,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ------------------------------------------------------
          // LOGO IMAGE
          // ------------------------------------------------------

          Container(
            width: 32,
            height: 32,

            padding: const EdgeInsets.all(4),

            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(9),
            ),

            child: Image.asset(
              'assets/images/logo.png',

              fit: BoxFit.contain,

              // ------------------------------------------------
              // If logo does not load, show school icon
              // ------------------------------------------------

              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return Icon(
                  Icons.school_rounded,
                  color: darkPrimaryColor,
                  size: 22,
                );
              },
            ),
          ),

          const SizedBox(width: 9),

          // ------------------------------------------------------
          // APP NAME
          // ------------------------------------------------------

          const Text(
            "House of Tutor",
            style: TextStyle(
              color: Color(0xFF263238),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING UI
  // ============================================================

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // Loading circle
          Container(
            width: 65,
            height: 65,

            padding: const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 15,
                ),
              ],
            ),

            child: const CircularProgressIndicator(
              strokeWidth: 3,
              color: primaryColor,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            "Loading Profile...",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER CARD
  // ============================================================

  Widget _buildProfileHeader({
    required String fullName,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: Colors.grey.shade200,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        children: [

          // ------------------------------------------------------
          // PROFILE ICON
          // ------------------------------------------------------

          Container(
            width: 92,
            height: 92,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              gradient: LinearGradient(
                colors: [
                  Colors.teal.shade50,
                  Colors.teal.shade100,
                ],

                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),

              border: Border.all(
                color: Colors.teal.shade100,
                width: 2,
              ),
            ),

            child: Icon(
              Icons.person_rounded,
              size: 52,
              color: darkPrimaryColor,
            ),
          ),

          const SizedBox(height: 16),

          // ------------------------------------------------------
          // STUDENT NAME
          // ------------------------------------------------------

          Text(
            fullName,

            textAlign: TextAlign.center,

            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),

          const SizedBox(height: 9),

          // ------------------------------------------------------
          // STUDENT BADGE
          // ------------------------------------------------------

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 6,
            ),

            decoration: BoxDecoration(
              color: Colors.teal.shade50,

              borderRadius: BorderRadius.circular(20),

              border: Border.all(
                color: Colors.teal.shade100,
              ),
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [

                Icon(
                  Icons.school_outlined,
                  size: 14,
                  color: darkPrimaryColor,
                ),

                const SizedBox(width: 5),

                const Text(
                  "STUDENT",
                  style: TextStyle(
                    color: darkPrimaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: Colors.grey.shade200,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ------------------------------------------------------
          // SECTION HEADER
          // ------------------------------------------------------

          Row(
            children: [

              Container(
                width: 34,
                height: 34,

                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),

                child: Icon(
                  icon,
                  size: 19,
                  color: darkPrimaryColor,
                ),
              ),

              const SizedBox(width: 10),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF455A64),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // ------------------------------------------------------
          // INFORMATION
          // ------------------------------------------------------

          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // INFORMATION TILE
  // ============================================================

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 3,
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // ------------------------------------------------------
          // ICON
          // ------------------------------------------------------

          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(11),
            ),

            child: Icon(
              icon,
              size: 20,
              color: darkPrimaryColor,
            ),
          ),

          const SizedBox(width: 12),

          // ------------------------------------------------------
          // TEXT
          // ------------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,

                  maxLines: 3,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF263238),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIVIDER
  // ============================================================

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),

      child: Divider(
        height: 1,
        thickness: 0.7,
        color: Colors.grey.shade200,
      ),
    );
  }
}