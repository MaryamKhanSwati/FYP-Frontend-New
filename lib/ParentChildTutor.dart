import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:house_of_tutor/services/api_client.dart';

class ParentChildTutor extends StatefulWidget {
  final Map<String, dynamic> child;

  const ParentChildTutor({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _ParentChildTutorState createState() => _ParentChildTutorState();
}

class _ParentChildTutorState extends State<ParentChildTutor> {
  List<dynamic> tutorsList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChildTutors();
  }

  Future<void> fetchChildTutors() async {
    setState(() {
      isLoading = true;
    });

    try {
      final studentId = widget.child['studentId'];
      final response = await ApiClient.get('/api/Parent/child-tutors/$studentId');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          tutorsList = data is List ? data : [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        String errorMessage = "Failed to load tutors.";
        if (response.body.isNotEmpty) {
          try {
            final data = json.decode(response.body);
            errorMessage = data['message'] ?? errorMessage;
          } catch (_) {
            errorMessage = response.body;
          }
        }
        _showSnackBar(errorMessage);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar("An error occurred: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "T";
    List<String> parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.teal),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 24,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, color: Colors.teal, size: 24),
            ),
            const SizedBox(width: 8),
            const Text(
              "House of Tutor",
              style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header Section
            const Text(
              "Assigned Tutors",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Manage and view academic instructors for your child",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            // Main Content Area
            isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: Colors.teal),
                    ),
                  )
                : tutorsList.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Text(
                            "No assigned tutors found.",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: tutorsList.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final tutor = tutorsList[index];
                          final fullName = tutor['fullName'] ?? 'Unknown Tutor';
                          final email = tutor['email'] ?? 'Not Available';
                          final phone = tutor['phone'] ?? 'Not Available';
                          final qualification = tutor['qualification'] ?? 'N/A';
                          final experience = tutor['experience']?.toString() ?? '0';
                          final radius = tutor['radius']?.toString() ?? '0';
                          List<dynamic> coursesTeaching = tutor['coursesTeaching'] ?? [];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tutor Header Info
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        _getInitials(fullName),
                                        style: TextStyle(
                                          color: Colors.teal.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fullName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.teal.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.school_outlined, size: 12, color: Colors.teal.shade700),
                                                const SizedBox(width: 4),
                                                Text(
                                                  qualification,
                                                  style: TextStyle(color: Colors.teal.shade700, fontSize: 11, fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Experience and Coverage Info Box
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Icon(Icons.work_outline, size: 18, color: Colors.grey.shade600),
                                            const SizedBox(height: 4),
                                            const Text(
                                              "Experience",
                                              style: TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "$experience Years",
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(height: 30, width: 1, color: Colors.grey.shade300),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade600),
                                            const SizedBox(height: 4),
                                            const Text(
                                              "Coverage",
                                              style: TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "$radius KM Radius",
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Contact Info Rows
                                Row(
                                  children: [
                                    Icon(Icons.email_outlined, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 8),
                                    Text(
                                      email,
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 8),
                                    Text(
                                      phone,
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0),
                                  child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                                ),

                                // Assigned Courses Section
                                const Row(
                                  children: [
                                    Icon(Icons.menu_book_outlined, size: 16, color: Colors.teal),
                                    SizedBox(width: 6),
                                    Text(
                                      "Assigned Courses",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 6.0,
                                  children: coursesTeaching.map<Widget>((course) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade50.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.teal.shade200),
                                      ),
                                      child: Text(
                                        course.toString(),
                                        style: TextStyle(
                                          color: Colors.teal.shade800,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}

























// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:house_of_tutor/ParentChildClasses.dart';
// import 'package:house_of_tutor/ParentChildCourses.dart';
// import 'package:house_of_tutor/ParentChildDetail.dart';
// import 'package:house_of_tutor/ParentChildProfile.dart';
// import 'package:house_of_tutor/services/api_client.dart';

// class ParentChildTutor extends StatefulWidget {
//   final int studentId;

//   const ParentChildTutor({
//     super.key,
//     required this.studentId,
//   });

//   @override
//   State<ParentChildTutor> createState() => _ParentChildTutorState();
// }

// class _ParentChildTutorState extends State<ParentChildTutor> {
//   bool isLoading = true;

//   List<Map<String, dynamic>> tutors = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchTutors();
//   }

//   // =====================================================
//   // FETCH TUTORS
//   // =====================================================

//   Future<void> fetchTutors() async {
//     setState(() => isLoading = true);

//     try {
//       final response = await ApiClient.get(
//         "/api/Parent/child-tutors/${widget.studentId}",
//       );

//       debugPrint("CHILD TUTORS STATUS : ${response.statusCode}");
//       debugPrint("CHILD TUTORS BODY : ${response.body}");

//       if (response.statusCode == 200) {
//         final List<dynamic> data =
//             jsonDecode(utf8.decode(response.bodyBytes));

//         // =============================================
//         // GROUP BY TUTOR
//         // =============================================
//         final Map<int, Map<String, dynamic>> grouped = {};

//         for (final item in data) {
//           final int tutorId = item["tutorId"] ?? 0;

//           if (!grouped.containsKey(tutorId)) {
//             grouped[tutorId] = {
//               "tutorId": tutorId,
//               "fullName": item["fullName"] ?? "",
//               "email": item["email"] ?? "",
//               "phone": item["phone"] ?? "",
//               "qualification": item["qualification"] ?? "",
//               "experience": item["experience"],
//               "radius": item["radius"],
//               "courses": <String>[],
//             };
//           }

//           final courseId = item["courseId"];
//           if (courseId != null) {
//             final courses =
//                 grouped[tutorId]!["courses"] as List<String>;
//             final courseName =
//                 item["courseName"]?.toString() ??
//                     "Course #$courseId";
//             if (!courses.contains(courseName)) {
//               courses.add(courseName);
//             }
//           }
//         }

//         setState(() {
//           tutors = grouped.values.toList();
//           isLoading = false;
//         });
//       } else {
//         setState(() => isLoading = false);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 ApiClient.messageFromBody(response.body) ??
//                     "Unable to fetch tutors",
//               ),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint("CHILD TUTORS ERROR : $e");
//       setState(() => isLoading = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.toString())),
//         );
//       }
//     }
//   }

//   // =====================================================
//   // UI
//   // =====================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,

//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 1,
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.teal),
//           onPressed: () {
//             if (Navigator.canPop(context)) {
//               Navigator.pop(context);
//             } else {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => ParentChildProfile(
//                     studentId: widget.studentId,
//                   ),
//                 ),
//               );
//             }
//           },
//         ),
//         title: Image.asset("assets/images/logo.png", height: 45),
//       ),

//       body: RefreshIndicator(
//         onRefresh: fetchTutors,
//         child: isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : tutors.isEmpty
//                 ? const Center(
//                     child: Text(
//                       "No Tutors Found",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   )
//                 : ListView(
//                     padding: const EdgeInsets.all(16),
//                     children: [
//                       const Center(
//                         child: Text(
//                           "Child Tutors",
//                           style: TextStyle(
//                             fontSize: 26,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.teal,
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 20),

//                       ...tutors.map((tutor) => tutorCard(tutor)),
//                     ],
//                   ),
//       ),

//       // =====================================================
//       // BOTTOM NAV — same as ParentChildCourses
//       // =====================================================
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: 3,
//         type: BottomNavigationBarType.fixed,
//         selectedItemColor: Colors.teal,
//         unselectedItemColor: Colors.grey,
//         onTap: (index) {
//           switch (index) {
//             case 0:
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => ParentChildProfile(
//                     studentId: widget.studentId,
//                   ),
//                 ),
//               );
//               break;

//             case 1:
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => ParentChildCourses(
//                     studentId: widget.studentId,
//                   ),
//                 ),
//               );
//               break;

//             case 2:
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => ParentChildDetail(
//                     studentId: widget.studentId,
//                     childName: "",
//                     email: "",
//                     phone: "",
//                   ),
//                 ),
//               );
//               break;

//             case 3:
//               // Current screen
//               break;

//             case 4:
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => ParentChildClasses(
//                     studentId: widget.studentId,
//                   ),
//                 ),
//               );
//               break;
//           }
//         },
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: "Profile",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.book),
//             label: "Courses",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.schedule),
//             label: "Schedule",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.school),
//             label: "Tutors",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.class_),
//             label: "Fees",
//           ),
//         ],
//       ),
//     );
//   }

//   // =====================================================
//   // TUTOR CARD
//   // =====================================================

//   Widget tutorCard(Map<String, dynamic> tutor) {
//     final String name = tutor["fullName"] ?? "";
//     final String email = tutor["email"] ?? "";
//     final String phone = tutor["phone"] ?? "";
//     final String qualification = tutor["qualification"] ?? "";
//     final dynamic experience = tutor["experience"];
//     final dynamic radius = tutor["radius"];
//     final List<String> courses =
//         List<String>.from(tutor["courses"] ?? []);

//     return Container(
//       margin: const EdgeInsets.only(bottom: 18),
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.shade300,
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ================================
//           // AVATAR
//           // ================================
//           CircleAvatar(
//             radius: 30,
//             backgroundColor: Colors.teal.shade50,
//             child: const Icon(
//               Icons.school,
//               color: Colors.teal,
//               size: 32,
//             ),
//           ),

//           const SizedBox(width: 15),

//           // ================================
//           // INFO
//           // ================================
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   name,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),

//                 const SizedBox(height: 10),

//                 _infoRow(Icons.email_outlined, email),
//                 _infoRow(Icons.phone_outlined, phone),

//                 if (qualification.isNotEmpty)
//                   _infoRow(
//                     Icons.workspace_premium_outlined,
//                     "Qualification: $qualification",
//                   ),

//                 if (experience != null)
//                   _infoRow(
//                     Icons.history_edu_outlined,
//                     "Experience: $experience Years",
//                   ),

//                 if (radius != null)
//                   _infoRow(
//                     Icons.location_on_outlined,
//                     "Radius: $radius KM",
//                   ),

//                 // ================================
//                 // COURSES
//                 // ================================
//                 if (courses.isNotEmpty) ...[
//                   const SizedBox(height: 10),
//                   const Text(
//                     "Courses Teaching",
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.teal,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   ...courses.map(
//                     (course) => Padding(
//                       padding: const EdgeInsets.only(
//                         left: 4,
//                         bottom: 4,
//                       ),
//                       child: Row(
//                         children: [
//                           const Icon(
//                             Icons.circle,
//                             size: 7,
//                             color: Colors.teal,
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               course,
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // =====================================================
//   // INFO ROW HELPER
//   // =====================================================

//   Widget _infoRow(IconData icon, String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6),
//       child: Row(
//         children: [
//           Icon(icon, size: 16, color: Colors.teal),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 14),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }