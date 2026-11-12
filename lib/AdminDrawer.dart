import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:house_of_tutor/AdminAllClasses.dart';
import 'package:house_of_tutor/AdminBlockList.dart';
import 'package:house_of_tutor/AdminFeedback.dart';
import 'package:house_of_tutor/AdminBlockedStudent.dart';
import 'package:house_of_tutor/LoginScreen.dart';

// ============================================================
// VENUE MANAGEMENT SCREEN
// ============================================================
import 'package:house_of_tutor/AdminVenueManagement.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  // ============================================================
  // NAVIGATE TO SCREEN
  // ============================================================

  void navigate(BuildContext context, Widget page) {
    // Close drawer first
    Navigator.pop(context);

    // Open selected screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  void logout(BuildContext context) {
    // Close drawer
    Navigator.pop(context);

    // Remove all previous screens
    // and go to LoginScreen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,

      child: ListView(
        padding: EdgeInsets.zero,

        children: [

          // ====================================================
          // HEADER
          // ====================================================

          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D9488),
                  Color(0xFF14B8A6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),

            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [

                // ==============================================
                // LOGO
                // ==============================================

                Container(
                  padding:
                      const EdgeInsets.all(8),

                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,

                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset:
                            const Offset(0, 2),
                      ),
                    ],
                  ),

                  child: Image.asset(
                    "assets/images/logo.png",
                    height: 50,
                  ),
                ),

                const SizedBox(height: 10),

                // ==============================================
                // TITLE
                // ==============================================

                const Text(
                  "Admin Panel",

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),

                // ==============================================
                // SUBTITLE
                // ==============================================

                const Text(
                  "House of Tutor Management",

                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ====================================================
          // MANAGEMENT SECTION
          // ====================================================

          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),

            child: Text(
              "MANAGEMENT",

              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight:
                    FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // ====================================================
          // ALL CLASSES
          // ====================================================

          _buildDrawerItem(
            context,

            icon: Icons.class_,

            title: "All Classes",

            page: const AdminAllClasses(),

            color: Colors.blue,
          ),

          // ====================================================
          // VENUE MANAGEMENT
          // ====================================================

          _buildDrawerItem(
            context,

            icon: Icons.meeting_room,

            title: "Venue Management",

            // Opens AdminVenueManagement screen
            page: const AdminVenueManagement(),

            color: Colors.teal,
          ),

          // ====================================================
          // BLOCKED TUTORS
          // ====================================================

          _buildDrawerItem(
            context,

            icon: Icons.block,

            title: "Blocked Tutors",

            page: const AdminBlockList(),

            color: Colors.red,
          ),

          // ====================================================
          // BLOCKED STUDENTS
          // ====================================================

          _buildDrawerItem(
            context,

            icon: Icons.person_off,

            title: "Blocked Students",

            page: const AdminBlockedStudent(),

            color: Colors.orange,
          ),

          const SizedBox(height: 10),

          // ====================================================
          // COMMUNICATION SECTION
          // ====================================================

          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),

            child: Text(
              "COMMUNICATION",

              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight:
                    FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // ====================================================
          // FEEDBACK
          // ====================================================

          _buildDrawerItem(
            context,

            icon: Icons.feedback_rounded,

            title: "Feedback",

            page: const AdminFeedback(),

            color: Colors.teal,
          ),

          // ====================================================
          // DIVIDER
          // ====================================================

          const Divider(
            indent: 16,
            endIndent: 16,
            height: 30,
          ),

          // ====================================================
          // LOGOUT
          // ====================================================

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),

            child: ListTile(
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(10),
              ),

              // ==============================================
              // LOGOUT ICON
              // ==============================================

              leading: Container(
                padding:
                    const EdgeInsets.all(8),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.red.shade50,
                  borderRadius:
                      BorderRadius.circular(8),
                ),

                child: const Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 20,
                ),
              ),

              // ==============================================
              // LOGOUT TEXT
              // ==============================================

              title: const Text(
                "Logout",

                style: TextStyle(
                  color: Colors.red,
                  fontWeight:
                      FontWeight.w600,
                  fontSize: 15,
                ),
              ),

              // ==============================================
              // ARROW
              // ==============================================

              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.red,
              ),

              // ==============================================
              // LOGOUT ACTION
              // ==============================================

              onTap: () {
                logout(context);
              },
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============================================================
  // DRAWER ITEM
  // ============================================================

  Widget _buildDrawerItem(
    BuildContext context, {

    required IconData icon,

    required String title,

    required Widget page,

    required Color color,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),

      child: ListTile(
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(10),
        ),

        // ======================================================
        // ICON
        // ======================================================

        leading: Container(
          padding:
              const EdgeInsets.all(8),

          decoration:
              BoxDecoration(
            color:
                color.withOpacity(0.1),

            borderRadius:
                BorderRadius.circular(8),
          ),

          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),

        // ======================================================
        // TITLE
        // ======================================================

        title: Text(
          title,

          style: const TextStyle(
            fontWeight:
                FontWeight.w500,
            fontSize: 15,
            color:
                Colors.black87,
          ),
        ),

        // ======================================================
        // ARROW
        // ======================================================

        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),

        // ======================================================
        // OPEN SCREEN
        // ======================================================

        onTap: () {
          navigate(context, page);
        },
      ),
    );
  }
}





































// import 'package:flutter/material.dart';
// import 'package:house_of_tutor/AdminAllClasses.dart';
// import 'package:house_of_tutor/AdminBlockList.dart';
// import 'package:house_of_tutor/AdminFeedback.dart';
// import 'package:house_of_tutor/AdminBlockedStudent.dart';
// import 'package:house_of_tutor/LoginScreen.dart';
// import 'package:house_of_tutor/AdminVenueManagement.dart';

// class AdminDrawer extends StatelessWidget {
//   const AdminDrawer({super.key});

//   void navigate(BuildContext context, Widget page) {
//     Navigator.pop(context); // Close drawer first

//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => page),
//     );
//   }

//   // ================= LOGOUT =================
//   void logout(BuildContext context) {
//     // Close drawer
//     Navigator.pop(context);

//     // Navigate to LoginScreen and remove all previous screens
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(
//         builder: (_) => const LoginScreen(),
//       ),
//       (route) => false,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       backgroundColor: Colors.white,
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           // ================= HEADER =================
//           DrawerHeader(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Color(0xFF0D9488),
//                   Color(0xFF14B8A6),
//                 ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Image.asset(
//                     "assets/images/logo.png",
//                     height: 50,
//                   ),
//                 ),

//                 const SizedBox(height: 10),

//                 const Text(
//                   "Admin Panel",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: 0.5,
//                   ),
//                 ),

//                 const Text(
//                   "House of Tutor Management",
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 10),

//           // ================= MANAGEMENT SECTION =================
//           const Padding(
//             padding: EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 8,
//             ),
//             child: Text(
//               "MANAGEMENT",
//               style: TextStyle(
//                 color: Colors.grey,
//                 fontSize: 11,
//                 fontWeight: FontWeight.bold,
//                 letterSpacing: 1.2,
//               ),
//             ),
//           ),

//           // ================= ALL CLASSES =================
//           _buildDrawerItem(
//             context,
//             icon: Icons.class_,
//             title: "All Classes",
//             page: const AdminAllClasses(),
//             color: Colors.blue,
//           ),

//           // ================= BLOCKED TUTORS =================
//           _buildDrawerItem(
//             context,
//             icon: Icons.block,
//             title: "Blocked Tutors",
//             page: const AdminBlockList(),
//             color: Colors.red,
//           ),

//           // ================= BLOCKED STUDENTS =================
//           _buildDrawerItem(
//             context,
//             icon: Icons.person_off,
//             title: "Blocked Students",
//             page: const AdminBlockedStudent(),
//             color: Colors.orange,
//           ),

//           const SizedBox(height: 10),

//           // ================= COMMUNICATION SECTION =================
//           const Padding(
//             padding: EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 8,
//             ),
//             child: Text(
//               "COMMUNICATION",
//               style: TextStyle(
//                 color: Colors.grey,
//                 fontSize: 11,
//                 fontWeight: FontWeight.bold,
//                 letterSpacing: 1.2,
//               ),
//             ),
//           ),

//           // ================= FEEDBACK =================
//           _buildDrawerItem(
//             context,
//             icon: Icons.feedback_rounded,
//             title: "Feedback",
//             page: const AdminFeedback(),
//             color: Colors.teal,
//           ),

//           const Divider(
//             indent: 16,
//             endIndent: 16,
//             height: 30,
//           ),

//           // ================= LOGOUT =================
//           Padding(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 12,
//               vertical: 4,
//             ),
//             child: ListTile(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),

//               leading: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.red.shade50,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Icon(
//                   Icons.logout,
//                   color: Colors.red,
//                   size: 20,
//                 ),
//               ),

//               title: const Text(
//                 "Logout",
//                 style: TextStyle(
//                   color: Colors.red,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 15,
//                 ),
//               ),

//               trailing: const Icon(
//                 Icons.arrow_forward_ios,
//                 size: 14,
//                 color: Colors.red,
//               ),

//               // ================= LOGOUT ACTION =================
//               onTap: () {
//                 logout(context);
//               },
//             ),
//           ),

//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   // ================= DRAWER ITEM =================
//   Widget _buildDrawerItem(
//     BuildContext context, {
//     required IconData icon,
//     required String title,
//     required Widget page,
//     required Color color,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 12,
//         vertical: 4,
//       ),
//       child: ListTile(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),

//         leading: Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(
//             icon,
//             color: color,
//             size: 20,
//           ),
//         ),

//         title: Text(
//           title,
//           style: const TextStyle(
//             fontWeight: FontWeight.w500,
//             fontSize: 15,
//             color: Colors.black87,
//           ),
//         ),

//         trailing: const Icon(
//           Icons.arrow_forward_ios,
//           size: 14,
//           color: Colors.grey,
//         ),

//         onTap: () => navigate(context, page),
//       ),
//     );
//   }
// }




























// // import 'package:flutter/material.dart';
// // import 'package:house_of_tutor/AdminAllClasses.dart';
// // import 'package:house_of_tutor/AdminBlockList.dart';
// // import 'package:house_of_tutor/AdminFeedback.dart';

// // class AdminDrawer extends StatelessWidget {
// //   const AdminDrawer({super.key});

// //   void navigate(BuildContext context, Widget page) {
// //     Navigator.pop(context); // close drawer first
// //     Navigator.push(
// //       context,
// //       MaterialPageRoute(builder: (_) => page),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Drawer(
// //       child: ListView(
// //         padding: EdgeInsets.zero,
// //         children: [

// //           // ================= HEADER =================
// //           DrawerHeader(
// //             decoration: const BoxDecoration(color: Colors.teal),
// //             child: Column(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: [
// //                 Image.asset("assets/images/logo.png", height: 80),
// //                 const SizedBox(height: 10),
// //                 const Text(
// //                   "Admin Panel",
// //                   style: TextStyle(
// //                     color: Colors.white,
// //                     fontSize: 22,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),

// //           // ================= FEEDBACK =================
// //           ListTile(
// //             leading: const Icon(Icons.feedback),
// //             title: const Text("Feedback"),
// //             onTap: () {
// //               navigate(context, const AdminFeedback());
// //             },
// //           ),

// //           // ================= BLOCK LIST =================
// //           ListTile(
// //             leading: const Icon(Icons.block),
// //             title: const Text("Block List"),
// //             onTap: () {
// //               navigate(context, const AdminBlockList());
// //             },
// //           ),

// //           // ================= ALL CLASSES =================
// //           ListTile(
// //             leading: const Icon(Icons.class_),
// //             title: const Text("All Classes"),
// //             onTap: () {
// //               navigate(context, const AdminAllClasses());
// //             },
// //           ),

// //           const Divider(),

// //           // ================= LOGOUT =================
// //           ListTile(
// //             leading: const Icon(Icons.logout, color: Colors.red),
// //             title: const Text("Logout"),
// //             onTap: () {
// //               Navigator.pop(context);

// //               ScaffoldMessenger.of(context).showSnackBar(
// //                 const SnackBar(content: Text("Logout Successfully")),
// //               );
// //             },
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }