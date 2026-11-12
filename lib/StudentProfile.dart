import 'package:flutter/material.dart';
import 'package:house_of_tutor/services/api_client.dart';

class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  bool isLoading = true;
  Map<String, dynamic> profileData = {};
  String errorMessage = '';

  // 🎨 MAIN THEME COLOR
  final Color mainColor = const Color(0xff009688);

  @override
  void initState() {
    super.initState();
    fetchStudentProfile();
  }

  Future<void> fetchStudentProfile() async {
    try {
      final response = await ApiClient.get('/api/Student/my-profile');

      if (response.statusCode == 200) {
        final data = await ApiClient.decodeJson(response);
        setState(() {
          profileData = data is Map<String, dynamic> ? data : {};
          isLoading = false;
        });
      } else {
        final serverMessage = ApiClient.messageFromBody(response.body);
        setState(() {
          errorMessage = serverMessage ?? 'Failed to load profile data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  // =========================================================
  // INITIALS FROM FULL NAME
  // =========================================================

  String get initials {
    final String name = (profileData['full_name'] ?? '').toString().trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((e) => e.isNotEmpty).toList();
    return parts.map((e) => e[0]).take(2).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: mainColor, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Student Profile",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: mainColor),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =========================================
                      // AVATAR CARD
                      // =========================================

                      card(
                        child: Column(
                          children: [
                            // AVATAR + VERIFIED BADGE
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: mainColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 40,
                                    backgroundColor: mainColor.withOpacity(.12),
                                    child: Text(
                                      initials,
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: mainColor,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.verified,
                                      color: mainColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // NAME
                            Text(
                              profileData['full_name'] ?? 'User Name',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // STUDENT BADGE
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: mainColor.withOpacity(.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "STUDENT",
                                style: TextStyle(
                                  color: mainColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: .6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // =========================================
                      // CONTACT INFORMATION
                      // =========================================

                      sectionTitle("CONTACT INFORMATION"),
                      const SizedBox(height: 10),

                      card(
                        child: Column(
                          children: [
                            infoRow(
                              icon: Icons.email_outlined,
                              iconBg: const Color(0xffE3F6EA),
                              iconColor: const Color(0xff2E9E5B),
                              title: "Email Address",
                              value: profileData['email'] ?? 'Not provided',
                            ),
                            const Divider(height: 26),
                            infoRow(
                              icon: Icons.phone_outlined,
                              iconBg: const Color(0xffE3F0F6),
                              iconColor: const Color(0xff1E88A8),
                              title: "Phone Number",
                              value: profileData['phone'] ?? 'Not provided',
                            ),
                            const Divider(height: 26),
                            infoRow(
                              icon: Icons.badge_outlined,
                              iconBg: const Color(0xffFBEBE0),
                              iconColor: const Color(0xffC1601A),
                              title: "CNIC / National ID",
                              value: profileData['cnic'] ?? 'Not provided',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // =========================================
                      // LOCATION DETAILS
                      // =========================================

                      sectionTitle("LOCATION DETAILS"),
                      const SizedBox(height: 10),

                      card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            infoRow(
                              icon: Icons.location_on_outlined,
                              iconBg: const Color(0xffE9E6FB),
                              iconColor: const Color(0xff5146D8),
                              title: "City / Location",
                              value: (profileData['location'] == null ||
                                      profileData['location']
                                          .toString()
                                          .trim()
                                          .isEmpty)
                                  ? "N/A"
                                  : profileData['location'].toString(),
                            ),

                            const SizedBox(height: 16),

                            // LAT / LONG
                            Row(
                              children: [
                                Expanded(
                                  child: coordinateBox(
                                    icon: Icons.explore_outlined,
                                    iconColor: const Color(0xff2E9E5B),
                                    label: "Latitude",
                                    value: profileData['latitude']
                                            ?.toString() ??
                                        "N/A",
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: coordinateBox(
                                    icon: Icons.explore_outlined,
                                    iconColor: const Color(0xff1E88A8),
                                    label: "Longitude",
                                    value: profileData['longitude']
                                            ?.toString() ??
                                        "N/A",
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // =========================================================
  // WHITE ROUNDED CARD WRAPPER
  // =========================================================

  Widget card({required Widget child}) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }

  // =========================================================
  // SECTION TITLE (grey uppercase label)
  // =========================================================

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // =========================================================
  // INFO ROW (icon + label + value)
  // =========================================================

  Widget infoRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // LATITUDE / LONGITUDE BOX
  // =========================================================

  Widget coordinateBox({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}











































// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:house_of_tutor/services/api_client.dart';

// class StudentProfile extends StatefulWidget {
//   const StudentProfile({super.key});

//   @override
//   State<StudentProfile> createState() => _StudentProfileState();
// }

// class _StudentProfileState extends State<StudentProfile> {
//   bool isLoading = true;
//   Map<String, dynamic> profileData = {};
//   String errorMessage = '';

//   @override
//   void initState() {
//     super.initState();
//     fetchStudentProfile();
//   }

//   Future<void> fetchStudentProfile() async {
//     try {
//       final response = await ApiClient.get('/api/Student/my-profile');

//       if (response.statusCode == 200) {
//         final data = await ApiClient.decodeJson(response);
//         setState(() {
//           profileData = data is Map<String, dynamic> ? data : {};
//           isLoading = false;
//         });
//       } else {
//         final serverMessage = ApiClient.messageFromBody(response.body);
//         setState(() {
//           errorMessage = serverMessage ?? 'Failed to load profile data';
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         errorMessage = 'An error occurred: $e';
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Image.asset(
//           'assets/images/logo.png',
//           height: 30,
//           errorBuilder: (context, error, stackTrace) => const Text(
//             "House of Tutor",
//             style: TextStyle(color: Color(0xff009688), fontWeight: FontWeight.bold),
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: isLoading
//           ? const Center(
//               child: CircularProgressIndicator(color: Color(0xff009688)),
//             )
//           : errorMessage.isNotEmpty
//               ? Center(
//                   child: Padding(
//                     padding: const EdgeInsets.all(20.0),
//                     child: Text(
//                       errorMessage,
//                       style: const TextStyle(color: Colors.red, fontSize: 16),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                 )
//               : SingleChildScrollView(
//                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                   child: Column(
//                     children: [
//                       const SizedBox(height: 10),
//                       // Avatar Icon container
//                       Container(
//                         padding: const EdgeInsets.all(4),
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           border: Border.all(color: const Color(0xff009688), width: 2),
//                         ),
//                         child: const CircleAvatar(
//                           radius: 45,
//                           backgroundColor: Color(0xff009688),
//                           child: Icon(
//                             Icons.person,
//                             size: 55,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       Text(
//                         profileData['full_name'] ?? 'User Name',
//                         style: const TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: Colors.teal.shade50,
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(color: Colors.teal.shade100),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: const [
//                             Icon(Icons.verified, color: Color(0xff009688), size: 16),
//                             SizedBox(width: 6),
//                             Text(
//                               "Student Account",
//                               style: TextStyle(
//                                 color: Color(0xff00796B),
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: 13,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 25),
//                       // Personal Information Card
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(20),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(16),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.05),
//                               blurRadius: 10,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               "PERSONAL INFORMATION",
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.grey.shade500,
//                                 letterSpacing: 1.2,
//                               ),
//                             ),
//                             const SizedBox(height: 15),
//                             buildInfoRow(
//                               icon: Icons.person_outline,
//                               title: "Full Name",
//                               value: profileData['full_name'] ?? 'Not provided',
//                             ),
//                             const Divider(height: 24),
//                             buildInfoRow(
//                               icon: Icons.email_outlined,
//                               title: "Email Address",
//                               value: profileData['email'] ?? 'Not provided',
//                             ),
//                             const Divider(height: 24),
//                             buildInfoRow(
//                               icon: Icons.badge_outlined,
//                               title: "CNIC Number",
//                               value: profileData['cnic'] ?? 'Not provided',
//                             ),
//                             const Divider(height: 24),
//                             buildInfoRow(
//                               icon: Icons.phone_outlined,
//                               title: "Contact Number",
//                               value: profileData['phone'] ?? 'Not provided',
//                             ),
//                             const Divider(height: 24),
//                             buildInfoRow(
//                               icon: Icons.location_on_outlined,
//                               title: "Primary Location",
//                               value: profileData['location'] ?? 'Not provided',
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//     );
//   }

//   Widget buildInfoRow({
//     required IconData icon,
//     required String title,
//     required String value,
//   }) {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: Colors.teal.shade50,
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Icon(icon, color: const Color(0xff009688), size: 22),
//         ),
//         const SizedBox(width: 15),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey.shade500,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const SizedBox(height: 3),
//               Text(
//                 value,
//                 style: const TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }