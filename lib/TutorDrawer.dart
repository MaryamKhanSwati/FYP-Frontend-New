import 'package:flutter/material.dart';
import 'package:house_of_tutor/LoginScreen.dart';
import 'package:house_of_tutor/TutorAllClasses.dart';
import 'package:house_of_tutor/TutorCancelledClasses.dart';
import 'package:house_of_tutor/TutorCourseMarkAsDone.dart';
import 'package:house_of_tutor/TutorDashboard.dart';
import 'package:house_of_tutor/TutorHistory.dart';
import 'package:house_of_tutor/TutorMyStudents.dart';
import 'package:house_of_tutor/TutorPaymentScreen.dart';
import 'package:house_of_tutor/TutorProfile.dart';
import 'package:house_of_tutor/services/api_client.dart';
import 'package:house_of_tutor/services/auth_store.dart';

class TutorDrawer extends StatelessWidget {
  const TutorDrawer({
    super.key,
  });

  // =====================================================
  // NAVIGATION
  // =====================================================

  void navigateToPage(
    BuildContext context,
    Widget page,
  ) {
    Navigator.pop(context); // Close the drawer

    // Using Navigator.push keeps the history stack so the back button 
    // successfully navigates to the previous page instead of closing the app.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> logout(
    BuildContext context,
  ) async {
    try {
      Navigator.pop(context);

      // =========================================
      // CLEAR STORAGE
      // =========================================

      await AuthStore.instance.clear();

      // =========================================
      // GO LOGIN
      // =========================================

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Logout Error : $e",
          ),
        ),
      );
    }
  }

  // =====================================================
  // DRAWER ITEM
  // =====================================================

  Widget drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.teal,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF5F7FA),
      child: Column(
        children: [
          // =================================================
          // HEADER
          // =================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 25,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF00796B),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Image.asset(
                      "assets/images/logo.png",
                      height: 50,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.school,
                        size: 40,
                        color: Color(0xFF00796B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Tutor Panel",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "House of Tutor",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // =================================================
          // MENU ITEMS
          // =================================================

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Dashboard
                drawerItem(
                  icon: Icons.dashboard_rounded,
                  title: "Dashboard",
                  color: const Color(0xFF00796B),
                  onTap: () {
                    navigateToPage(
                      context,
                      const TutorDashboard(),
                    );
                  },
                ),

                // Profile
                drawerItem(
                  icon: Icons.person_rounded,
                  title: "Profile",
                  color: Colors.indigo,
                  onTap: () {
                    navigateToPage(
                      context,
                      const TutorProfile(),
                    );
                  },
                ),

                // All Classes
                drawerItem(
                  icon: Icons.menu_book_rounded,
                  title: "All Classes",
                  color: Colors.teal,
                  onTap: () {
                    navigateToPage(
                      context,
                      const TutorAllClasses(),
                    );
                  },
                ),

                // Cancelled Classes
                drawerItem(
                  icon: Icons.cancel_schedule_send_rounded,
                  title: "Cancelled Classes",
                  color: Colors.redAccent,
                  onTap: () {
                    navigateToPage(
                      context,
                      const TutorCancelledClasses(),
                    );
                  },
                ),

                // My Students
                drawerItem(
                  icon: Icons.groups_rounded,
                  title: "My Students",
                  color: Colors.blueAccent,
                  onTap: () {
                    navigateToPage(
                      context,
                      const TutorMyStudent(),
                    );
                  },
                ),

                // Payment Screen
                drawerItem(
                  icon: Icons.payment_rounded,
                  title: "Payment Screen",
                  color: Colors.green,
                  onTap: () {
                    navigateToPage(
                      context,
                      const TutorPaymentScreen(),
                    );
                  },
                ),

                // History
                drawerItem(
                  icon: Icons.history_rounded,
                  title: "History",
                  color: Colors.deepOrange,
                  onTap: () {
                    navigateToPage(
                      context,
                      const TutorHistory(),
                    );
                  },
                ),

                // Mark As Done
                drawerItem(
                  icon: Icons.task_alt_rounded,
                  title: "Mark As Done",
                  color: Colors.purple,
                  onTap: () {
                    navigateToPage(
                      context,
                      const TutorCourseMarkAsDone(),
                    );
                  },
                ),
              ],
            ),
          ),

          // =================================================
          // LOGOUT BUTTON
          // =================================================

          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                ),
                onPressed: () async {
                  await logout(
                    context,
                  );
                },
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                  size: 20,
                ),
                label: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}


















// import 'package:flutter/material.dart';
// import 'package:house_of_tutor/TutorCancelledClasses.dart';
// import 'package:house_of_tutor/LoginScreen.dart';
// import 'package:house_of_tutor/TutorAllClasses.dart';
// import 'package:house_of_tutor/TutorMyStudents.dart';
// //import 'package:house_of_tutor/TutorPaymentScreen.dart';
// import 'package:house_of_tutor/TutorProfile.dart';
// import 'package:house_of_tutor/TutorHistory.dart';
// import 'package:house_of_tutor/TutorDashboard.dart';
// import 'package:house_of_tutor/TutorCourseMarkAsDone.dart';

// import 'package:house_of_tutor/services/auth_store.dart';
// import 'package:house_of_tutor/services/api_client.dart';

// class TutorDrawer extends StatelessWidget {
//   const TutorDrawer({
//     super.key,
//   });

//   // =====================================================
//   // NAVIGATION
//   // =====================================================

//   void navigateToPage(
//     BuildContext context,
//     Widget page,
//   ) {
//     Navigator.pop(context);

//     Future.delayed(
//       const Duration(
//         milliseconds: 250,
//       ),
//       () {
//         if (!context.mounted) return;
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => page,
//           ),
//         );
//       },
//     );
//   }

//   // =====================================================
//   // LOGOUT
//   // =====================================================

//   Future<void> logout(
//     BuildContext context,
//   ) async {
//     try {
//       Navigator.pop(context);

//       // =========================================
//       // BACKEND LOGOUT
//       // =========================================

//       try {
//         await ApiClient.post(
//           '/api/Auth/logout',
//           {},
//         );
//       } catch (e) {
//         debugPrint(
//           "LOGOUT API ERROR : $e",
//         );
//       }

//       // =========================================
//       // CLEAR STORAGE
//       // =========================================

//       await AuthStore.instance.clear();

//       // =========================================
//       // GO LOGIN
//       // =========================================

//       if (!context.mounted) return;

//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(
//           builder: (_) => const LoginScreen(),
//         ),
//         (route) => false,
//       );
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             "Logout Error : $e",
//           ),
//         ),
//       );
//     }
//   }

//   // =====================================================
//   // DRAWER ITEM
//   // =====================================================

//   Widget drawerItem({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//     Color color = Colors.teal,
//   }) {
//     return Container(
//       margin: const EdgeInsets.symmetric(
//         horizontal: 12,
//         vertical: 5,
//       ),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.05),
//             blurRadius: 5,
//           ),
//         ],
//       ),
//       child: ListTile(
//         leading: Icon(
//           icon,
//           color: color,
//         ),
//         title: Text(
//           title,
//           style: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         trailing: const Icon(
//           Icons.arrow_forward_ios,
//           size: 16,
//           color: Colors.grey,
//         ),
//         onTap: onTap,
//       ),
//     );
//   }

//   // =====================================================
//   // UI
//   // =====================================================

//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       backgroundColor: const Color(0xffF5F5F5),
//       child: Column(
//         children: [
//           // =================================================
//           // HEADER
//           // =================================================

//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.only(
//               top: 60,
//               bottom: 30,
//             ),
//             decoration: const BoxDecoration(
//               color: Colors.teal,
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(25),
//                 bottomRight: Radius.circular(25),
//               ),
//             ),
//             child: Column(
//               children: [
//                 CircleAvatar(
//                   radius: 45,
//                   backgroundColor: Colors.white,
//                   child: Image.asset(
//                     "assets/images/logo.png",
//                     height: 60,
//                   ),
//                 ),
//                 const SizedBox(
//                   height: 15,
//                 ),
//                 const Text(
//                   "Tutor Panel",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(
//                   height: 5,
//                 ),
//                 const Text(
//                   "House of Tutor",
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 15,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 20),

//           // =================================================
//           // MENU ITEMS
//           // =================================================

//           Expanded(
//             child: ListView(
//               padding: EdgeInsets.zero,
//               children: [
//                 // Profile
//                 drawerItem(
//                   icon: Icons.person,
//                   title: "Profile",
//                   onTap: () {
//                     navigateToPage(
//                       context,
//                       const TutorProfile(),
//                     );
//                   },
//                 ),

//                 // History
//                 drawerItem(
//                   icon: Icons.history,
//                   title: "History",
//                   onTap: () {
//                     navigateToPage(
//                       context,
//                       const TutorHistory(),
//                     );
//                   },
//                 ),

//                 // drawerItem(
//                 //   icon: Icons.payment,
//                 //   title: "Payment",
//                 //   onTap: () {
//                 //     navigateToPage(
//                 //       context,
//                 //       const TutorPayment(),
//                 //     );
//                 //   },
//                 // ),

//                 // Dashboard
//                 drawerItem(
//                   icon: Icons.dashboard,
//                   title: "Dashboard",
//                   onTap: () {
//                     navigateToPage(
//                       context,
//                       const TutorDashboard(),
//                     );
//                   },
//                 ),

//                 // Cancelled Classes
//                 drawerItem(
//                   icon: Icons.cancel_schedule_send,
//                   title: "Cancelled Classes",
//                   onTap: () {
//                     navigateToPage(
//                       context,
//                       const TutorCancelledClasses(),
//                     );
//                   },
//                 ),

//                 // All Classes
//                 drawerItem(
//                   icon: Icons.menu_book,
//                   title: "All Classes",
//                   onTap: () {
//                     navigateToPage(
//                       context,
//                       const TutorAllClasses(),
//                     );
//                   },
//                 ),

//                 // My Students
//                 drawerItem(
//                   icon: Icons.groups,
//                   title: "My Students",
//                   onTap: () {
//                     navigateToPage(
//                       context,
//                       const TutorMyStudent(),
//                     );
//                   },
//                 ),

//                 // Mark As Done
//                 drawerItem(
//                   icon: Icons.feedback,
//                   title: "Mark As Done",
//                   onTap: () {
//                     navigateToPage(
//                       context,
//                       const TutorCourseMarkAsDone(),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),

//           // =================================================
//           // LOGOUT BUTTON
//           // =================================================

//           Padding(
//             padding: const EdgeInsets.all(15),
//             child: SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton.icon(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                 ),
//                 onPressed: () async {
//                   await logout(
//                     context,
//                   );
//                 },
//                 icon: const Icon(
//                   Icons.logout,
//                   color: Colors.white,
//                 ),
//                 label: const Text(
//                   "Logout",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           const SizedBox(height: 10),
//         ],
//       ),
//     );
//   }
// }