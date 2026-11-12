import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:house_of_tutor/AdminApprovedTutor.dart';
import 'package:house_of_tutor/AdminDrawer.dart';
import 'package:house_of_tutor/AdminHome.dart';
import 'package:house_of_tutor/AdminSubject.dart';
import 'package:house_of_tutor/services/api_client.dart';

class AdminStudent extends StatefulWidget {
  const AdminStudent({super.key});

  @override
  State<AdminStudent> createState() => _AdminStudentState();
}

class _AdminStudentState extends State<AdminStudent> {
  List<dynamic> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getAllStudents();
  }

  // =========================================================
  // GET ALL STUDENTS
  // =========================================================

  Future<void> getAllStudents() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiClient.get("/api/Admin/all-students");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          students = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load students")),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // =========================================================
  // REJECT STUDENT
  // =========================================================

  Future<void> rejectStudent(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reject Student"),
          content:
              const Text("Are you sure you want to reject this student?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Reject"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final response =
          await ApiClient.put("/api/Admin/reject-student/$id", {});

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student rejected successfully")),
        );
        getAllStudents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to reject student")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // =========================================================
  // BLOCK STUDENT
  // =========================================================

  Future<void> blockStudent(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Block Student"),
          content:
              const Text("Are you sure you want to block this student?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Block"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final response =
          await ApiClient.put("/api/Admin/block-student/$id", {});

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student blocked successfully")),
        );
        getAllStudents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to block student")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // =========================================================
  // INFO ROW (email/phone/cnic/location)
  // =========================================================

  Widget infoItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xff68768A)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xff17233B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STUDENT AVATAR
  // =========================================================
  // Shows the student's profile picture when the API returns
  // one (checks a few common field names). Falls back to a
  // circle with the student's initials — same visual style
  // used on the Approved Tutors screen — if there's no image
  // or the image fails to load.
  //
  // NOTE: adjust the field name below ("profilePicture") to
  // whatever key your /api/Admin/all-students response
  // actually uses for the picture URL.

  Widget studentAvatar(dynamic student, String fullName) {
    final String? pictureUrl = (student["profilePicture"] ??
            student["profileImage"] ??
            student["picture"] ??
            student["image"])
        ?.toString();

    final String initials = fullName.trim().isEmpty
        ? "?"
        : fullName
            .trim()
            .split(" ")
            .where((e) => e.isNotEmpty)
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase();

    final bool hasPicture =
        pictureUrl != null && pictureUrl.trim().isNotEmpty;

    return CircleAvatar(
      radius: 27.5,
      backgroundColor: const Color(0xffF0F1FF),
      backgroundImage: hasPicture ? NetworkImage(pictureUrl) : null,
      onBackgroundImageError: hasPicture ? (_, __) {} : null,
      child: hasPicture
          ? null
          : Text(
              initials,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff5146D8),
              ),
            ),
    );
  }

  // =========================================================
  // SINGLE-LINE ACTION BUTTON HELPER
  // =========================================================
  // FittedBox shrinks the icon+label pair so Reject/Block
  // always stay on one line instead of wrapping on narrow
  // screens.

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color? bgColor,
    Color? fgColor,
    Color? borderColor,
    bool outlined = false,
  }) {
    final child = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );

    if (outlined) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: fgColor,
          side: BorderSide(color: borderColor ?? Colors.transparent),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          minimumSize: const Size(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        minimumSize: const Size(0, 42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: child,
    );
  }

  // =========================================================
  // STUDENT CARD
  // =========================================================

  Widget studentCard(dynamic student) {
    final String fullName = student["fullName"] ?? "";
    final String email = student["email"] ?? "Not Available";
    final String phone = student["phone"] ?? "Not Available";
    final String cnic = student["cnic"] ?? "Not Available";
    final String location = (student["location"] == null ||
            student["location"].toString().trim().isEmpty)
        ? "Not Available"
        : student["location"].toString();
    final int id = student["id"];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE7E9ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NAME ROW
          Row(
            children: [
              studentAvatar(student, fullName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff101C33),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffEFFFF7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.circle,
                              size: 8, color: Color(0xff20B486)),
                          SizedBox(width: 5),
                          Text(
                            "ACTIVE",
                            style: TextStyle(
                              color: Color(0xff20B486),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xffE7E9ED)),
          const SizedBox(height: 8),

          // EMAIL + PHONE
          Row(
            children: [
              infoItem(Icons.email_outlined, email),
              infoItem(Icons.phone_outlined, phone),
            ],
          ),

          const SizedBox(height: 10),

          // CNIC + LOCATION
          Row(
            children: [
              infoItem(Icons.badge_outlined, "CNIC: $cnic"),
              infoItem(Icons.location_on_outlined, location),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(color: Color(0xffE7E9ED)),
          const SizedBox(height: 10),

          // ACTION BUTTONS — always fit on one line now
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: "Reject",
                  icon: Icons.cancel_outlined,
                  onTap: () => rejectStudent(id),
                  outlined: true,
                  fgColor: const Color(0xffC77400),
                  borderColor: const Color(0xffF5D67B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  label: "Block Account",
                  icon: Icons.block,
                  onTap: () => blockStudent(id),
                  bgColor: const Color(0xffFDECEC),
                  fgColor: const Color(0xffE74C4C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      drawer: const AdminDrawer(),

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        centerTitle: true,
        leading: Builder(
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.only(left: 18, top: 13, bottom: 13),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffF8F9FC),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.menu,
                    size: 29,
                    color: Color(0xff17233B),
                  ),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
            );
          },
        ),
        title: Image.asset(
          "assets/images/logo.png",
          height: 50,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              "House of Tutor",
              style: TextStyle(
                color: Color(0xff17233B),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18, top: 12, bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xffF8F9FC),
                borderRadius: BorderRadius.circular(15),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.refresh,
                  size: 26,
                  color: Color(0xff20B486),
                ),
                onPressed: getAllStudents,
              ),
            ),
          ),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: getAllStudents,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 25, 18, 25),
                  children: [
                    // HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "All Students",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff101C33),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffEDEFF3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${students.length} Total",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff17233B),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // LIST
                    if (students.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Center(child: Text("No students found")),
                      )
                    else
                      ...students.map((s) => studentCard(s)),
                  ],
                ),
        ),
      ),

      // =====================================================
      // BOTTOM NAVIGATION
      // =====================================================

      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: 2,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 8,
          selectedItemColor: const Color(0xff258F81),
          unselectedItemColor: const Color(0xff68768A),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          iconSize: 24,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
          unselectedLabelStyle: const TextStyle(height: 1.0),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: "Tutors"),
            BottomNavigationBarItem(
                icon: Icon(Icons.school), label: "Students"),
            BottomNavigationBarItem(
                icon: Icon(Icons.menu_book), label: "Subjects"),
          ],
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminHome()),
              );
            }
            if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminApprovedTutor()),
              );
            }
            if (index == 3) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminSubject()),
              );
            }
          },
        ),
      ),
    );
  }
}




















// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:house_of_tutor/AdminApprovedTutor.dart';
// import 'package:house_of_tutor/AdminDrawer.dart';
// import 'package:house_of_tutor/AdminHome.dart';
// import 'package:house_of_tutor/AdminSubject.dart';
// import 'package:house_of_tutor/services/api_client.dart';

// class AdminStudent extends StatefulWidget {
//   const AdminStudent({super.key});

//   @override
//   State<AdminStudent> createState() => _AdminStudentState();
// }

// class _AdminStudentState extends State<AdminStudent> {
//   List<dynamic> students = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     getAllStudents();
//   }

//   // =========================================================
//   // GET ALL STUDENTS
//   // =========================================================

//   Future<void> getAllStudents() async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final response = await ApiClient.get("/api/Admin/all-students");

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         setState(() {
//           students = data;
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           isLoading = false;
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Failed to load students")),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isLoading = false;
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e")),
//       );
//     }
//   }

//   // =========================================================
//   // REJECT STUDENT
//   // =========================================================

//   Future<void> rejectStudent(int id) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text("Reject Student"),
//           content:
//               const Text("Are you sure you want to reject this student?"),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text("Cancel"),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: const Text("Reject"),
//             ),
//           ],
//         );
//       },
//     );

//     if (confirm != true) return;

//     try {
//       final response =
//           await ApiClient.put("/api/Admin/reject-student/$id", {});

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Student rejected successfully")),
//         );
//         getAllStudents();
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Failed to reject student")),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e")),
//       );
//     }
//   }

//   // =========================================================
//   // BLOCK STUDENT
//   // =========================================================

//   Future<void> blockStudent(int id) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text("Block Student"),
//           content:
//               const Text("Are you sure you want to block this student?"),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text("Cancel"),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: const Text("Block"),
//             ),
//           ],
//         );
//       },
//     );

//     if (confirm != true) return;

//     try {
//       final response =
//           await ApiClient.put("/api/Admin/block-student/$id", {});

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Student blocked successfully")),
//         );
//         getAllStudents();
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Failed to block student")),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e")),
//       );
//     }
//   }

//   // =========================================================
//   // INFO ROW (email/phone/cnic/location)
//   // =========================================================

//   Widget infoItem(IconData icon, String text) {
//     return Expanded(
//       child: Row(
//         children: [
//           Icon(icon, size: 18, color: const Color(0xff68768A)),
//           const SizedBox(width: 6),
//           Expanded(
//             child: Text(
//               text,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 fontSize: 14,
//                 color: Color(0xff17233B),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // =========================================================
//   // STUDENT CARD
//   // =========================================================

//   Widget studentCard(dynamic student) {
//     final String fullName = student["fullName"] ?? "";
//     final String email = student["email"] ?? "Not Available";
//     final String phone = student["phone"] ?? "Not Available";
//     final String cnic = student["cnic"] ?? "Not Available";
//     final String location = (student["location"] == null ||
//             student["location"].toString().trim().isEmpty)
//         ? "Not Available"
//         : student["location"].toString();
//     final int id = student["id"];

//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: const Color(0xffE7E9ED)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.06),
//             blurRadius: 5,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // NAME ROW
//           Row(
//             children: [
//               Container(
//                 width: 55,
//                 height: 55,
//                 decoration: const BoxDecoration(
//                   color: Color(0xffF0F1FF),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.school,
//                   size: 28,
//                   color: Color(0xff5146D8),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       fullName,
//                       style: const TextStyle(
//                         fontSize: 17,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xff101C33),
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 3,
//                       ),
//                       decoration: BoxDecoration(
//                         color: const Color(0xffEFFFF7),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: const [
//                           Icon(Icons.circle,
//                               size: 8, color: Color(0xff20B486)),
//                           SizedBox(width: 5),
//                           Text(
//                             "ACTIVE",
//                             style: TextStyle(
//                               color: Color(0xff20B486),
//                               fontWeight: FontWeight.w600,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 14),
//           const Divider(color: Color(0xffE7E9ED)),
//           const SizedBox(height: 8),

//           // EMAIL + PHONE
//           Row(
//             children: [
//               infoItem(Icons.email_outlined, email),
//               infoItem(Icons.phone_outlined, phone),
//             ],
//           ),

//           const SizedBox(height: 10),

//           // CNIC + LOCATION
//           Row(
//             children: [
//               infoItem(Icons.badge_outlined, "CNIC: $cnic"),
//               infoItem(Icons.location_on_outlined, location),
//             ],
//           ),

//           const SizedBox(height: 8),
//           const Divider(color: Color(0xffE7E9ED)),
//           const SizedBox(height: 10),

//           // ACTION BUTTONS
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton.icon(
//                   onPressed: () => rejectStudent(id),
//                   icon: const Icon(Icons.cancel_outlined,
//                       size: 18, color: Color(0xffC77400)),
//                   label: const Text("Reject"),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: const Color(0xffC77400),
//                     side: const BorderSide(color: Color(0xffF5D67B)),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 flex: 2,
//                 child: ElevatedButton.icon(
//                   onPressed: () => blockStudent(id),
//                   icon: const Icon(Icons.block, size: 18),
//                   label: const Text("Block Account"),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xffFDECEC),
//                     foregroundColor: const Color(0xffE74C4C),
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // =========================================================
//   // BUILD
//   // =========================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xffF8F9FB),
//       drawer: const AdminDrawer(),

//       // =====================================================
//       // APP BAR
//       // =====================================================

//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         toolbarHeight: 80,
//         centerTitle: true,
//         leading: Builder(
//           builder: (context) {
//             return Padding(
//               padding: const EdgeInsets.only(left: 18, top: 13, bottom: 13),
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: const Color(0xffF8F9FC),
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 child: IconButton(
//                   padding: EdgeInsets.zero,
//                   icon: const Icon(
//                     Icons.menu,
//                     size: 29,
//                     color: Color(0xff17233B),
//                   ),
//                   onPressed: () {
//                     Scaffold.of(context).openDrawer();
//                   },
//                 ),
//               ),
//             );
//           },
//         ),
//         title: Image.asset(
//           "assets/images/logo.png",
//           height: 50,
//           fit: BoxFit.contain,
//           errorBuilder: (context, error, stackTrace) {
//             return const Text(
//               "House of Tutor",
//               style: TextStyle(
//                 color: Color(0xff17233B),
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             );
//           },
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 18, top: 12, bottom: 12),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: const Color(0xffF8F9FC),
//                 borderRadius: BorderRadius.circular(15),
//               ),
//               child: IconButton(
//                 icon: const Icon(
//                   Icons.refresh,
//                   size: 26,
//                   color: Color(0xff20B486),
//                 ),
//                 onPressed: getAllStudents,
//               ),
//             ),
//           ),
//         ],
//       ),

//       // =====================================================
//       // BODY
//       // =====================================================

//       body: SafeArea(
//         bottom: false,
//         child: RefreshIndicator(
//           onRefresh: getAllStudents,
//           child: isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : ListView(
//                   physics: const AlwaysScrollableScrollPhysics(),
//                   padding: const EdgeInsets.fromLTRB(18, 25, 18, 25),
//                   children: [
//                     // HEADER
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text(
//                           "All Students",
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xff101C33),
//                           ),
//                         ),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 14,
//                             vertical: 6,
//                           ),
//                           decoration: BoxDecoration(
//                             color: const Color(0xffEDEFF3),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Text(
//                             "${students.length} Total",
//                             style: const TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               color: Color(0xff17233B),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 20),

//                     // LIST
//                     if (students.isEmpty)
//                       const Padding(
//                         padding: EdgeInsets.only(top: 100),
//                         child: Center(child: Text("No students found")),
//                       )
//                     else
//                       ...students.map((s) => studentCard(s)),
//                   ],
//                 ),
//         ),
//       ),

//       // =====================================================
//       // BOTTOM NAVIGATION
//       // =====================================================

//       bottomNavigationBar: SafeArea(
//         top: false,
//         child: BottomNavigationBar(
//           currentIndex: 2,
//           type: BottomNavigationBarType.fixed,
//           backgroundColor: Colors.white,
//           elevation: 8,
//           selectedItemColor: const Color(0xff258F81),
//           unselectedItemColor: const Color(0xff68768A),
//           selectedFontSize: 11,
//           unselectedFontSize: 11,
//           iconSize: 24,
//           selectedLabelStyle: const TextStyle(
//             fontWeight: FontWeight.bold,
//             height: 1.0,
//           ),
//           unselectedLabelStyle: const TextStyle(height: 1.0),
//           items: const [
//             BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
//             BottomNavigationBarItem(icon: Icon(Icons.groups), label: "Tutors"),
//             BottomNavigationBarItem(
//                 icon: Icon(Icons.school), label: "Students"),
//             BottomNavigationBarItem(
//                 icon: Icon(Icons.menu_book), label: "Subjects"),
//           ],
//           onTap: (index) {
//             if (index == 0) {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => const AdminHome()),
//               );
//             }
//             if (index == 1) {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => const AdminApprovedTutor()),
//               );
//             }
//             if (index == 3) {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => const AdminSubject()),
//               );
//             }
//           },
//         ),
//       ),
//     );z
//   }
// }