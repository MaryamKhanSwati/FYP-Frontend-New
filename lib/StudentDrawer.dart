import 'package:flutter/material.dart';

import 'package:house_of_tutor/LoginScreen.dart';
import 'package:house_of_tutor/StudentGroup.dart';
import 'package:house_of_tutor/StudentProfile.dart';
import 'package:house_of_tutor/StudentTodayClasses.dart';
import 'package:house_of_tutor/StudentMyTutor.dart';
import 'package:house_of_tutor/StudentHistory.dart';
import 'package:house_of_tutor/StudentFriendList.dart';
import 'package:house_of_tutor/StudentMyFee.dart';

class StudentDrawer extends StatelessWidget {
const StudentDrawer({super.key});

@override
Widget build(BuildContext context) {
return Drawer(
backgroundColor: const Color(0xFFF8FAFC),

  child: SafeArea(
    child: Column(
      children: [
        // =========================================================
        // HEADER SECTION
        // =========================================================
        Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            24,
            20,
            20,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF249688),
                Color(0xFF00796B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),

          child: Row(
            children: [
              // ===================================================
              // LOGO
              // ===================================================
              Container(
                width: 54,
                height: 54,

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(14),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),

                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(14),

                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,

                    errorBuilder:
                        (context, error, stackTrace) {
                      return const Icon(
                        Icons.school,
                        size: 28,
                        color: Color(0xFF249688),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // ===================================================
              // TITLE
              // ===================================================
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      "House of Tutor",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      "Student Portal",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // ===================================================
              // CLOSE BUTTON
              // ===================================================
              InkWell(
                onTap: () => Navigator.pop(context),

                borderRadius:
                    BorderRadius.circular(12),

                child: Container(
                  width: 38,
                  height: 38,

                  decoration: BoxDecoration(
                    color:
                        Colors.white.withOpacity(0.15),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),

                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),

        // =========================================================
        // NAVIGATION MENU LIST
        // =========================================================
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),

            children: [
              // ===================================================
              // MAIN MENU TITLE
              // ===================================================
              const Padding(
                padding: EdgeInsets.only(
                  left: 8,
                  bottom: 12,
                ),

                child: Text(
                  "MAIN MENU",
                  style: TextStyle(
                    color: Color(0xFF8D9BAE),
                    letterSpacing: 1.2,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // ===================================================
              // MY PROFILE
              // ===================================================
              _buildDrawerTile(
                context,
                icon: Icons.person_outline_rounded,
                title: "My Profile",
                subtitle:
                    "View and edit your details",

                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const StudentProfile(),
                    ),
                  );
                },
              ),

              // ===================================================
              // MY TUTOR
              // ===================================================
              _buildDrawerTile(
                context,
                icon: Icons.school_outlined,
                title: "My Tutor",
                subtitle:
                    "View your assigned tutor",

                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const StudentMyTutor(),
                    ),
                  );
                },
              ),

              // ===================================================
              // TODAY CLASSES
              // ===================================================
              _buildDrawerTile(
                context,
                icon: Icons.calendar_today_outlined,
                title: "Today Classes",
                subtitle:
                    "Manage your active schedule",

                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const StudentTodayClasses(),
                    ),
                  );
                },
              ),
              // student group
              _buildDrawerTile(
                context,
                icon: Icons.group,
                title: "Student Group",
                subtitle:
                    "Student group",

                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const StudentGroup(),
                    ),
                  );
                },
              ),
              // ===================================================
              // SESSION HISTORY
              // ===================================================
              _buildDrawerTile(
                context,
                icon: Icons.history_rounded,
                title: "Session History",
                subtitle:
                    "Past sessions and records",

                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const StudentHistory(),
                    ),
                  );
                },
              ),

              // ===================================================
              // FRIEND LIST
              // ===================================================
              // When student clicks this item:
              // 1. Drawer closes
              // 2. StudentFriendList screen opens
               _buildDrawerTile(
               context,
                icon: Icons.people_alt_outlined,
                title: "Friend List",
                subtitle:
                   "View and manage your friends",

                onTap: () {
                  // Close the drawer
                  Navigator.pop(context);

                  // Open Friend List screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const StudentFriendList(),
                    ),
                  );
                },
              ),

              // ===================================================
              // MY FEE
              // ===================================================
              _buildDrawerTile(
                context,
                icon: Icons.payments_outlined,
                title: "My Fee",
                subtitle:
                    "View and manage your fee",

                onTap: () {
                  // Close drawer
                  Navigator.pop(context);

                  // Open My Fee screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const StudentMyFee(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // =========================================================
        // LOGOUT BUTTON SECTION
        // =========================================================
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            24,
          ),

          child: SizedBox(
            width: double.infinity,
            height: 50,

            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor:
                    const Color(0xFFE53935),

                side: const BorderSide(
                  color: Color(0xFFFEE2E2),
                  width: 1.5,
                ),

                elevation: 0,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),

              icon: const Icon(
                Icons.logout_rounded,
                size: 20,
              ),

              label: const Text(
                "Log Out",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // =================================================
              // LOGOUT
              // =================================================
              onPressed: () {
                showDialog(
                  context: context,

                  builder: (dialogContext) {
                    return AlertDialog(
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(20),
                      ),

                      title: const Text(
                        "Log Out",
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),

                      content: const Text(
                        "Are you sure you want to log out from your account?",
                        style: TextStyle(
                          color:
                              Color(0xFF526174),
                          fontSize: 14,
                        ),
                      ),

                      actionsPadding:
                          const EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        20,
                      ),

                      actions: [
                        // ========================================
                        // CANCEL BUTTON
                        // ========================================
                        TextButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                            );
                          },

                          style:
                              TextButton.styleFrom(
                            foregroundColor:
                                const Color(
                                    0xFF526174),
                          ),

                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),

                        // ========================================
                        // LOGOUT CONFIRM BUTTON
                        // ========================================
                        ElevatedButton(
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(
                                    0xFFE53935),

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

                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),

                          onPressed: () {
                            // Close dialog
                            Navigator.pop(
                              dialogContext,
                            );

                            // Go to Login Screen
                            // Remove all previous screens
                            Navigator
                                .pushAndRemoveUntil(
                              context,

                              MaterialPageRoute(
                                builder: (_) =>
                                    const LoginScreen(),
                              ),

                              (route) => false,
                            );
                          },

                          child: const Text(
                            "Log Out",
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    ),
  ),
);

}

// =========================================================
// REUSABLE DRAWER TILE
// =========================================================

Widget _buildDrawerTile(
BuildContext context, {
required IconData icon,
required String title,
required String subtitle,
required VoidCallback onTap,
}) {
return Padding(
padding: const EdgeInsets.only(
bottom: 10,
),


  child: Material(
    color: Colors.white,
    elevation: 0,

    borderRadius:
        BorderRadius.circular(14),

    child: InkWell(
      borderRadius:
          BorderRadius.circular(14),

      onTap: onTap,

      child: Container(
        padding:
            const EdgeInsets.all(12),

        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(14),

          border: Border.all(
            color:
                const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),

        child: Row(
          children: [
            // =================================================
            // MENU ICON
            // =================================================
            Container(
              width: 44,
              height: 44,

              decoration: BoxDecoration(
                color: const Color(
                  0xFF249688,
                ).withOpacity(0.1),

                borderRadius:
                    BorderRadius.circular(12),
              ),

              child: Icon(
                icon,
                color:
                    const Color(0xFF249688),
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            // =================================================
            // TITLE + SUBTITLE
            // =================================================
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    style:
                        const TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          Color(0xFF07152E),
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    subtitle,

                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          Color(0xFF68778A),
                      fontWeight:
                          FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // =================================================
            // ARROW
            // =================================================
            const Icon(
              Icons.chevron_right_rounded,
              color:
                  Color(0xFF9AA8BA),
              size: 20,
            ),
          ],
        ),
      ),
    ),
  ),
);


}
}

















































// import 'package:flutter/material.dart';

// import 'package:house_of_tutor/LoginScreen.dart';
// import 'package:house_of_tutor/StudentProfile.dart';
// import 'package:house_of_tutor/StudentTodayClasses.dart';
// import 'package:house_of_tutor/StudentMyTutor.dart';
// import 'package:house_of_tutor/StudentHistory.dart';
// import 'package:house_of_tutor/StudentFriendList.dart';
// import 'package:house_of_tutor/StudentMyFee.dart'; // ✅ NEW: Student My Fee

// class StudentDrawer extends StatelessWidget {
//   const StudentDrawer({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       backgroundColor: const Color(0xFFF8FAFC),
//       child: SafeArea(
//         child: Column(
//           children: [
//             // =========================================================
//             // HEADER SECTION
//             // =========================================================
//             Container(
//               padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     Color(0xFF249688),
//                     Color(0xFF00796B),
//                   ],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 54,
//                     height: 54,
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(14),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.08),
//                           blurRadius: 8,
//                           offset: const Offset(0, 3),
//                         ),
//                       ],
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(14),
//                       child: Image.asset(
//                         'assets/images/logo.png',
//                         fit: BoxFit.contain,
//                         errorBuilder: (context, error, stackTrace) {
//                           return const Icon(
//                             Icons.school,
//                             size: 28,
//                             color: Color(0xFF249688),
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 14),
//                   const Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "House of Tutor",
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.w800,
//                             fontSize: 18,
//                             letterSpacing: -0.3,
//                           ),
//                         ),
//                         SizedBox(height: 3),
//                         Text(
//                           "Student Portal",
//                           style: TextStyle(
//                             color: Colors.white70,
//                             fontSize: 13,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   InkWell(
//                     onTap: () => Navigator.pop(context),
//                     borderRadius: BorderRadius.circular(12),
//                     child: Container(
//                       width: 38,
//                       height: 38,
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.15),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: const Icon(
//                         Icons.close,
//                         color: Colors.white,
//                         size: 20,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // =========================================================
//             // NAVIGATION MENU LIST
//             // =========================================================
//             Expanded(
//               child: ListView(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 20,
//                 ),
//                 children: [
//                   const Padding(
//                     padding: EdgeInsets.only(left: 8, bottom: 12),
//                     child: Text(
//                       "MAIN MENU",
//                       style: TextStyle(
//                         color: Color(0xFF8D9BAE),
//                         letterSpacing: 1.2,
//                         fontSize: 11,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ),

//                   // =====================================================
//                   // MY PROFILE
//                   // =====================================================
//                   _buildDrawerTile(
//                     context,
//                     icon: Icons.person_outline_rounded,
//                     title: "My Profile",
//                     subtitle: "View and edit your details",
//                     onTap: () {
//                       Navigator.pop(context);

//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => const StudentProfile(),
//                         ),
//                       );
//                     },
//                   ),

//                   // =====================================================
//                   // MY TUTOR
//                   // =====================================================
//                   _buildDrawerTile(
//                     context,
//                     icon: Icons.school_outlined,
//                     title: "My Tutor",
//                     subtitle: "View your assigned tutor",
//                     onTap: () {
//                       Navigator.pop(context);

//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => const StudentMyTutor(),
//                         ),
//                       );
//                     },
//                   ),

//                   // =====================================================
//                   // TODAY CLASSES
//                   // =====================================================
//                   _buildDrawerTile(
//                     context,
//                     icon: Icons.calendar_today_outlined,
//                     title: "Today Classes",
//                     subtitle: "Manage your active schedule",
//                     onTap: () {
//                       Navigator.pop(context);

//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => const StudentTodayClasses(),
//                         ),
//                       );
//                     },
//                   ),

//                   // =====================================================
//                   // SESSION HISTORY
//                   // =====================================================
//                   _buildDrawerTile(
//                     context,
//                     icon: Icons.history_rounded,
//                     title: "Session History",
//                     subtitle: "Past sessions and records",
//                     onTap: () {
//                       Navigator.pop(context);

//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => const StudentHistory(),
//                         ),
//                       );
//                     },
//                   ),

//                   // =====================================================
//                   // MY FEE
//                   // =====================================================
//                   // ✅ NEW MENU ITEM
//                   // When student clicks this, StudentMyFee screen opens.
//                   _buildDrawerTile(
//                     context,
//                     icon: Icons.payments_outlined,
//                     title: "My Fee",
//                     subtitle: "View and manage your fee",
//                     onTap: () {
//                       // Close drawer first
//                       Navigator.pop(context);

//                       // Open Student My Fee screen
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => const StudentMyFee(),
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),

//             // =========================================================
//             // LOGOUT BUTTON SECTION
//             // =========================================================
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
//               child: SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: OutlinedButton.icon(
//                   style: OutlinedButton.styleFrom(
//                     backgroundColor: Colors.white,
//                     foregroundColor: const Color(0xFFE53935),
//                     side: const BorderSide(
//                       color: Color(0xFFFEE2E2),
//                       width: 1.5,
//                     ),
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                   ),
//                   icon: const Icon(
//                     Icons.logout_rounded,
//                     size: 20,
//                   ),
//                   label: const Text(
//                     "Log Out",
//                     style: TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   onPressed: () {
//                     showDialog(
//                       context: context,
//                       builder: (dialogContext) {
//                         return AlertDialog(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           title: const Text(
//                             "Log Out",
//                             style: TextStyle(
//                               fontWeight: FontWeight.w700,
//                               fontSize: 18,
//                             ),
//                           ),
//                           content: const Text(
//                             "Are you sure you want to log out from your account?",
//                             style: TextStyle(
//                               color: Color(0xFF526174),
//                               fontSize: 14,
//                             ),
//                           ),
//                           actionsPadding: const EdgeInsets.fromLTRB(
//                             20,
//                             0,
//                             20,
//                             20,
//                           ),
//                           actions: [
//                             // =================================================
//                             // CANCEL BUTTON
//                             // =================================================
//                             TextButton(
//                               onPressed: () {
//                                 Navigator.pop(dialogContext);
//                               },
//                               style: TextButton.styleFrom(
//                                 foregroundColor: const Color(0xFF526174),
//                               ),
//                               child: const Text(
//                                 "Cancel",
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),

//                             // =================================================
//                             // LOGOUT CONFIRM BUTTON
//                             // =================================================
//                             ElevatedButton(
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: const Color(0xFFE53935),
//                                 foregroundColor: Colors.white,
//                                 elevation: 0,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 16,
//                                   vertical: 10,
//                                 ),
//                               ),
//                               onPressed: () {
//                                 // Close confirmation dialog
//                                 Navigator.pop(dialogContext);

//                                 // Go to Login Screen
//                                 // Remove all previous screens.
//                                 Navigator.pushAndRemoveUntil(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (_) => const LoginScreen(),
//                                   ),
//                                   (route) => false,
//                                 );
//                               },
//                               child: const Text(
//                                 "Log Out",
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // =========================================================
//   // REUSABLE PROFESSIONAL TILE WIDGET
//   // =========================================================
//   Widget _buildDrawerTile(
//     BuildContext context, {
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required VoidCallback onTap,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: Material(
//         color: Colors.white,
//         elevation: 0,
//         borderRadius: BorderRadius.circular(14),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(14),
//           onTap: onTap,
//           child: Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(14),
//               border: Border.all(
//                 color: const Color(0xFFE2E8F0),
//                 width: 1,
//               ),
//             ),
//             child: Row(
//               children: [
//                 // =========================================================
//                 // MENU ICON
//                 // =========================================================
//                 Container(
//                   width: 44,
//                   height: 44,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF249688).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(
//                     icon,
//                     color: const Color(0xFF249688),
//                     size: 22,
//                   ),
//                 ),

//                 const SizedBox(width: 14),

//                 // =========================================================
//                 // TITLE + SUBTITLE
//                 // =========================================================
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         title,
//                         style: const TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFF07152E),
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         subtitle,
//                         style: const TextStyle(
//                           fontSize: 12,
//                           color: Color(0xFF68778A),
//                           fontWeight: FontWeight.w400,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // =========================================================
//                 // ARROW
//                 // =========================================================
//                 const Icon(
//                   Icons.chevron_right_rounded,
//                   color: Color(0xFF9AA8BA),
//                   size: 20,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
















































// // import 'package:flutter/material.dart';

// // import 'package:house_of_tutor/LoginScreen.dart';
// // import 'package:house_of_tutor/StudentProfile.dart';
// // import 'package:house_of_tutor/StudentTodayClasses.dart';
// // import 'package:house_of_tutor/StudentMyTutor.dart';
// // import 'package:house_of_tutor/StudentHistory.dart';

// // class StudentDrawer extends StatelessWidget {
// //   const StudentDrawer({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Drawer(
// //       backgroundColor: const Color(0xFFF8FAFC),
// //       child: SafeArea(
// //         child: Column(
// //           children: [
// //             // =========================================================
// //             // HEADER SECTION
// //             // =========================================================
// //             Container(
// //               padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
// //               decoration: const BoxDecoration(
// //                 gradient: LinearGradient(
// //                   colors: [
// //                     Color(0xFF249688),
// //                     Color(0xFF00796B),
// //                   ],
// //                   begin: Alignment.topLeft,
// //                   end: Alignment.bottomRight,
// //                 ),
// //               ),
// //               child: Row(
// //                 children: [
// //                   Container(
// //                     width: 54,
// //                     height: 54,
// //                     decoration: BoxDecoration(
// //                       color: Colors.white,
// //                       borderRadius: BorderRadius.circular(14),
// //                       boxShadow: [
// //                         BoxShadow(
// //                           color: Colors.black.withOpacity(0.08),
// //                           blurRadius: 8,
// //                           offset: const Offset(0, 3),
// //                         ),
// //                       ],
// //                     ),
// //                     child: ClipRRect(
// //                       borderRadius: BorderRadius.circular(14),
// //                       child: Image.asset(
// //                         'assets/images/logo.png',
// //                         fit: BoxFit.contain,
// //                         errorBuilder: (context, error, stackTrace) {
// //                           return const Icon(
// //                             Icons.school,
// //                             size: 28,
// //                             color: Color(0xFF249688),
// //                           );
// //                         },
// //                       ),
// //                     ),
// //                   ),
// //                   const SizedBox(width: 14),
// //                   const Expanded(
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         Text(
// //                           "House of Tutor",
// //                           style: TextStyle(
// //                             color: Colors.white,
// //                             fontWeight: FontWeight.w800,
// //                             fontSize: 18,
// //                             letterSpacing: -0.3,
// //                           ),
// //                         ),
// //                         SizedBox(height: 3),
// //                         Text(
// //                           "Student Portal",
// //                           style: TextStyle(
// //                             color: Colors.white70,
// //                             fontSize: 13,
// //                             fontWeight: FontWeight.w500,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                   InkWell(
// //                     onTap: () => Navigator.pop(context),
// //                     borderRadius: BorderRadius.circular(12),
// //                     child: Container(
// //                       width: 38,
// //                       height: 38,
// //                       decoration: BoxDecoration(
// //                         color: Colors.white.withOpacity(0.15),
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                       child: const Icon(
// //                         Icons.close,
// //                         color: Colors.white,
// //                         size: 20,
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),

// //             // =========================================================
// //             // NAVIGATION MENU LIST
// //             // =========================================================
// //             Expanded(
// //               child: ListView(
// //                 padding: const EdgeInsets.symmetric(
// //                   horizontal: 16,
// //                   vertical: 20,
// //                 ),
// //                 children: [
// //                   const Padding(
// //                     padding: EdgeInsets.only(left: 8, bottom: 12),
// //                     child: Text(
// //                       "MAIN MENU",
// //                       style: TextStyle(
// //                         color: Color(0xFF8D9BAE),
// //                         letterSpacing: 1.2,
// //                         fontSize: 11,
// //                         fontWeight: FontWeight.w700,
// //                       ),
// //                     ),
// //                   ),
// //                   _buildDrawerTile(
// //                     context,
// //                     icon: Icons.person_outline_rounded,
// //                     title: "My Profile",
// //                     subtitle: "View and edit your details",
// //                     onTap: () {
// //                       Navigator.pop(context);
// //                       Navigator.push(
// //                         context,
// //                         MaterialPageRoute(
// //                           builder: (_) => const StudentProfile(),
// //                         ),
// //                       );
// //                     },
// //                   ),
// //                   _buildDrawerTile(
// //                     context,
// //                     icon: Icons.school_outlined,
// //                     title: "My Tutor",
// //                     subtitle: "View your assigned tutor",
// //                     onTap: () {
// //                       Navigator.pop(context);
// //                       Navigator.push(
// //                         context,
// //                         MaterialPageRoute(
// //                           builder: (_) => const StudentMyTutor(),
// //                         ),
// //                       );
// //                     },
// //                   ),
// //                   _buildDrawerTile(
// //                     context,
// //                     icon: Icons.calendar_today_outlined,
// //                     title: "Today Classes",
// //                     subtitle: "Manage your active schedule",
// //                     onTap: () {
// //                       Navigator.pop(context);
// //                       Navigator.push(
// //                         context,
// //                         MaterialPageRoute(
// //                           builder: (_) => const StudentTodayClasses(),
// //                         ),
// //                       );
// //                     },
// //                   ),
// //                   _buildDrawerTile(
// //                     context,
// //                     icon: Icons.history_rounded,
// //                     title: "Session History",
// //                     subtitle: "Past sessions and records",
// //                     onTap: () {
// //                       Navigator.pop(context);
// //                       Navigator.push(
// //                         context,
// //                         MaterialPageRoute(
// //                           builder: (_) => const StudentHistory(),
// //                         ),
// //                       );
// //                     },
// //                   ),
// //                 ],
// //               ),
// //             ),

// //             // =========================================================
// //             // LOGOUT BUTTON SECTION
// //             // =========================================================
// //             Padding(
// //               padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
// //               child: SizedBox(
// //                 width: double.infinity,
// //                 height: 50,
// //                 child: OutlinedButton.icon(
// //                   style: OutlinedButton.styleFrom(
// //                     backgroundColor: Colors.white,
// //                     foregroundColor: const Color(0xFFE53935),
// //                     side: const BorderSide(
// //                       color: Color(0xFFFEE2E2),
// //                       width: 1.5,
// //                     ),
// //                     elevation: 0,
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(14),
// //                     ),
// //                   ),
// //                   icon: const Icon(Icons.logout_rounded, size: 20),
// //                   label: const Text(
// //                     "Log Out",
// //                     style: TextStyle(
// //                       fontSize: 15,
// //                       fontWeight: FontWeight.w600,
// //                     ),
// //                   ),
// //                   onPressed: () {
// //                     showDialog(
// //                       context: context,
// //                       builder: (dialogContext) {
// //                         return AlertDialog(
// //                           shape: RoundedRectangleBorder(
// //                             borderRadius: BorderRadius.circular(20),
// //                           ),
// //                           title: const Text(
// //                             "Log Out",
// //                             style: TextStyle(
// //                               fontWeight: FontWeight.w700,
// //                               fontSize: 18,
// //                             ),
// //                           ),
// //                           content: const Text(
// //                             "Are you sure you want to log out from your account?",
// //                             style: TextStyle(
// //                               color: Color(0xFF526174),
// //                               fontSize: 14,
// //                             ),
// //                           ),
// //                           actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
// //                           actions: [
// //                             TextButton(
// //                               onPressed: () {
// //                                 Navigator.pop(dialogContext);
// //                               },
// //                               style: TextButton.styleFrom(
// //                                 foregroundColor: const Color(0xFF526174),
// //                               ),
// //                               child: const Text(
// //                                 "Cancel",
// //                                 style: TextStyle(fontWeight: FontWeight.w600),
// //                               ),
// //                             ),
// //                             ElevatedButton(
// //                               style: ElevatedButton.styleFrom(
// //                                 backgroundColor: const Color(0xFFE53935),
// //                                 foregroundColor: Colors.white,
// //                                 elevation: 0,
// //                                 shape: RoundedRectangleBorder(
// //                                   borderRadius: BorderRadius.circular(10),
// //                                 ),
// //                                 padding: const EdgeInsets.symmetric(
// //                                   horizontal: 16,
// //                                   vertical: 10,
// //                                 ),
// //                               ),
// //                               onPressed: () {
// //                                 Navigator.pop(dialogContext);

// //                                 Navigator.pushAndRemoveUntil(
// //                                   context,
// //                                   MaterialPageRoute(
// //                                     builder: (_) => const LoginScreen(),
// //                                   ),
// //                                   (route) => false,
// //                                 );
// //                               },
// //                               child: const Text(
// //                                 "Log Out",
// //                                 style: TextStyle(
// //                                   fontWeight: FontWeight.w600,
// //                                 ),
// //                               ),
// //                             ),
// //                           ],
// //                         );
// //                       },
// //                     );
// //                   },
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   // =========================================================
// //   // REUSABLE PROFESSIONAL TILE WIDGET
// //   // =========================================================
// //   Widget _buildDrawerTile(
// //     BuildContext context, {
// //     required IconData icon,
// //     required String title,
// //     required String subtitle,
// //     required VoidCallback onTap,
// //   }) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 10),
// //       child: Material(
// //         color: Colors.white,
// //         elevation: 0,
// //         borderRadius: BorderRadius.circular(14),
// //         child: InkWell(
// //           borderRadius: BorderRadius.circular(14),
// //           onTap: onTap,
// //           child: Container(
// //             padding: const EdgeInsets.all(12),
// //             decoration: BoxDecoration(
// //               borderRadius: BorderRadius.circular(14),
// //               border: Border.all(
// //                 color: const Color(0xFFE2E8F0),
// //                 width: 1,
// //               ),
// //             ),
// //             child: Row(
// //               children: [
// //                 Container(
// //                   width: 44,
// //                   height: 44,
// //                   decoration: BoxDecoration(
// //                     color: const Color(0xFF249688).withOpacity(0.1),
// //                     borderRadius: BorderRadius.circular(12),
// //                   ),
// //                   child: Icon(
// //                     icon,
// //                     color: const Color(0xFF249688),
// //                     size: 22,
// //                   ),
// //                 ),
// //                 const SizedBox(width: 14),
// //                 Expanded(
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text(
// //                         title,
// //                         style: const TextStyle(
// //                           fontSize: 15,
// //                           fontWeight: FontWeight.w700,
// //                           color: Color(0xFF07152E),
// //                         ),
// //                       ),
// //                       const SizedBox(height: 2),
// //                       Text(
// //                         subtitle,
// //                         style: const TextStyle(
// //                           fontSize: 12,
// //                           color: Color(0xFF68778A),
// //                           fontWeight: FontWeight.w400,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //                 const Icon(
// //                   Icons.chevron_right_rounded,
// //                   color: Color(0xFF9AA8BA),
// //                   size: 20,
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }







































































































