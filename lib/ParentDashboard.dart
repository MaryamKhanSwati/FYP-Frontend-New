import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:house_of_tutor/services/api_client.dart';
import 'package:house_of_tutor/LoginScreen.dart';
import 'ParentChildDetail.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({Key? key}) : super(key: key);

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  // =========================================================
  // CHILDREN LIST
  // =========================================================

  List<dynamic> childrenList = [];

  // Loading indicator
  bool isLoading = true;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    // API call when screen opens
    fetchMyChildren();
  }

  // =========================================================
  // GET MY CHILDREN
  // API:
  // GET /api/Parent/my-children
  // =========================================================

  Future<void> fetchMyChildren() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      // -----------------------------------------------------
      // CALL API
      // -----------------------------------------------------

      final response = await ApiClient.get(
        '/api/Parent/my-children',
      );

      print('========================================');
      print('PARENT - MY CHILDREN API');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('========================================');

      // -----------------------------------------------------
      // SUCCESS
      // -----------------------------------------------------

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          if (!mounted) return;

          setState(() {
            childrenList = [];
            isLoading = false;
          });

          return;
        }

        final decodedData = jsonDecode(response.body);

        if (decodedData is List) {
          if (!mounted) return;

          setState(() {
            childrenList = decodedData;
            isLoading = false;
          });
        } else {
          if (!mounted) return;

          setState(() {
            childrenList = [];
            isLoading = false;
          });

          _showSnackBar(
            'Invalid children data received from server.',
          );
        }
      }

      // -----------------------------------------------------
      // ERROR
      // -----------------------------------------------------

      else {
        if (!mounted) return;

        setState(() {
          childrenList = [];
          isLoading = false;
        });

        String errorMessage =
            'Failed to load children profiles.';

        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);

            if (errorData is Map &&
                errorData['message'] != null) {
              errorMessage =
                  errorData['message'].toString();
            }
          } catch (e) {
            errorMessage = response.body;
          }
        }

        _showSnackBar(errorMessage);
      }
    } catch (e) {
      print('MY CHILDREN ERROR: $e');

      if (!mounted) return;

      setState(() {
        childrenList = [];
        isLoading = false;
      });

      _showSnackBar(
        'Unable to connect to the server.',
      );
    }
  }

  // =========================================================
  // SHOW MESSAGE
  // =========================================================

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }

  // =========================================================
  // GET CHILD INITIALS
  // =========================================================

  String _getInitials(String name) {
    name = name.trim();

    if (name.isEmpty) {
      return 'C';
    }

    final parts = name.split(RegExp(r'\s+'));

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return parts[0][0].toUpperCase();
  }

  // =========================================================
  // NAVIGATE TO CHILD DETAIL
  // =========================================================

  void _navigateToDetail(dynamic child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParentChildDetail(
          child: child,
        ),
      ),
    );
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        automaticallyImplyLeading: false,

        title: Row(
          children: [
            // =================================================
            // ASSET LOGO
            // =================================================
            //
            // MAKE SURE YOUR IMAGE EXISTS HERE:
            //
            // assets/logo.png
            //
            // Also add it in pubspec.yaml:
            //
            // flutter:
            //   assets:
            //     - assets/logo.png
            //
            // =================================================

            Image.asset(
              'assets/images/logo.png',
              height: 32,
              width: 32,
              fit: BoxFit.contain,

              // If image is not found,
              // this icon will be displayed.
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return const Icon(
                  Icons.school,
                  color: Colors.teal,
                  size: 32,
                );
              },
            ),

            const SizedBox(width: 8),

            // =================================================
            // APP NAME
            // =================================================

            const Text(
              'House of Tutor',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        // ===================================================
        // LOGOUT BUTTON
        // ===================================================

        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),

            child: OutlinedButton.icon(
              // Logout button
              onPressed: _logout,

              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade400,

                side: BorderSide(
                  color: Colors.red.shade100,
                ),

                backgroundColor: Colors.red.shade50,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              icon: const Icon(
                Icons.logout,
                size: 16,
              ),

              label: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: RefreshIndicator(
        onRefresh: fetchMyChildren,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // =================================================
            // PAGE HEADER
            // =================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                8,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  const Text(
                    'My Children',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Select a child profile to view academic details and fees.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // =================================================
            // CHILDREN
            // =================================================

            Expanded(
              child: isLoading

                  // ------------------------------------------------
                  // LOADING
                  // ------------------------------------------------

                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.teal,
                      ),
                    )

                  // ------------------------------------------------
                  // NO CHILDREN
                  // ------------------------------------------------

                  : childrenList.isEmpty
                      ? _buildEmptyState()

                      // ------------------------------------------------
                      // CHILDREN LIST
                      // ------------------------------------------------

                      : ListView.builder(
                          physics:
                              const AlwaysScrollableScrollPhysics(),

                          padding: const EdgeInsets.only(
                            bottom: 20,
                          ),

                          itemCount: childrenList.length,

                          itemBuilder:
                              (context, index) {
                            final child =
                                childrenList[index];

                            return _buildChildCard(
                              child,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),

      children: [
        SizedBox(
          height:
              MediaQuery.of(context).size.height * 0.25,
        ),

        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),

                child: Icon(
                  Icons.people_outline,
                  size: 45,
                  color: Colors.teal.shade400,
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                'No Children Found',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 6),

              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 35,
                ),

                child: Text(
                  'No child profile with ByParent fee responsibility is linked to your account.',
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // =================================================
              // REFRESH BUTTON
              // =================================================

              OutlinedButton.icon(
                onPressed: fetchMyChildren,

                icon: const Icon(
                  Icons.refresh,
                  size: 18,
                ),

                label: const Text(
                  'Refresh',
                ),

                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal,

                  side: const BorderSide(
                    color: Colors.teal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // CHILD CARD
  // =========================================================

  Widget _buildChildCard(dynamic child) {
    // -------------------------------------------------------
    // GET DATA SAFELY
    // -------------------------------------------------------

    final String fullName =
        child['fullName']?.toString().trim().isNotEmpty ==
                true
            ? child['fullName'].toString()
            : 'Unknown Child';

    final String cnic =
        child['cnic']?.toString().trim().isNotEmpty ==
                true
            ? child['cnic'].toString()
            : 'N/A';

    final String email =
        child['email']?.toString().trim().isNotEmpty ==
                true
            ? child['email'].toString()
            : 'Not Available';

    final String phone =
        child['phone']?.toString().trim().isNotEmpty ==
                true
            ? child['phone'].toString()
            : 'Not Available';

    final String location =
        child['location']?.toString().trim().isNotEmpty ==
                true
            ? child['location'].toString()
            : 'Location not available';

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: Colors.grey.shade200,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,

        borderRadius: BorderRadius.circular(16),

        child: InkWell(
          borderRadius: BorderRadius.circular(16),

          onTap: () {
            _navigateToDetail(child);
          },

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // =================================================
                // CHILD HEADER
                // =================================================

                Row(
                  children: [
                    // =================================================
                    // CHILD INITIALS
                    // =================================================

                    Container(
                      width: 58,
                      height: 58,

                      alignment: Alignment.center,

                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,

                        borderRadius:
                            BorderRadius.circular(14),
                      ),

                      child: Text(
                        _getInitials(fullName),

                        style: TextStyle(
                          color: Colors.teal.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // =================================================
                    // NAME + CNIC
                    // =================================================

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Text(
                            fullName,

                            maxLines: 1,

                            overflow:
                                TextOverflow.ellipsis,

                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),

                            decoration: BoxDecoration(
                              color:
                                  Colors.grey.shade100,

                              borderRadius:
                                  BorderRadius.circular(6),

                              border: Border.all(
                                color:
                                    Colors.grey.shade300,
                              ),
                            ),

                            child: Text(
                              'CNIC/ID: $cnic',

                              maxLines: 1,

                              overflow:
                                  TextOverflow.ellipsis,

                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // =================================================
                    // ARROW
                    // =================================================

                    IconButton(
                      onPressed: () {
                        _navigateToDetail(child);
                      },

                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                // =================================================
                // DIVIDER
                // =================================================

                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 12,
                  ),

                  child: Divider(
                    height: 1,
                    color: Color(0xFFF0F0F0),
                  ),
                ),

                // =================================================
                // EMAIL
                // =================================================

                _buildInfoRow(
                  icon: Icons.email_outlined,
                  text: email,
                ),

                const SizedBox(height: 8),

                // =================================================
                // PHONE
                // =================================================

                _buildInfoRow(
                  icon: Icons.phone_outlined,
                  text: phone,
                ),

                const SizedBox(height: 8),

                // =================================================
                // LOCATION
                // =================================================

                _buildInfoRow(
                  icon: Icons.location_on_outlined,
                  text: location,
                ),

                const SizedBox(height: 12),

                // =================================================
                // VIEW DETAILS BUTTON
                // =================================================

                SizedBox(
                  width: double.infinity,

                  child: OutlinedButton.icon(
                    onPressed: () {
                      _navigateToDetail(child);
                    },

                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 17,
                    ),

                    label: const Text(
                      'View Child Details',
                    ),

                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          Colors.teal.shade700,

                      side: BorderSide(
                        color: Colors.teal.shade200,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // INFO ROW
  // =========================================================

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            text,

            maxLines: 2,

            overflow: TextOverflow.ellipsis,

            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }
}