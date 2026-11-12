import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:house_of_tutor/services/api_client.dart';
import 'package:house_of_tutor/ParentChildClasses.dart';

class ParentChildCourses extends StatefulWidget {
  final int studentId;

  ParentChildCourses({
    Key? key,
    required dynamic studentId,
  }) : studentId = studentId is int 
          ? studentId 
          : int.tryParse(studentId?.toString() ?? '') ?? 0,
       super(key: key);

  @override
  _ParentChildCoursesState createState() => _ParentChildCoursesState();
}

class _ParentChildCoursesState extends State<ParentChildCourses> {
  List<dynamic> coursesList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChildCourses();
  }

  Future<void> fetchChildCourses() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiClient.get('/api/Parent/child-courses/${widget.studentId}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          coursesList = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        final data = json.decode(response.body);
        _showSnackBar(data['message'] ?? "Failed to load courses.");
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
              "Enrolled Courses",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Select a course subject to view detailed class schedules",
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
                : coursesList.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Text(
                            "No enrolled courses found.",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: coursesList.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final course = coursesList[index];
                          final courseTitle = course['courseTitle'] ?? 'Unnamed Course';
                          final courseNumber = index + 1;
                          
                          // Safely parse courseId to prevent type casting or null errors
                          final rawCourseId = course['courseId'] ?? course['id'];
                          final courseId = rawCourseId is int 
                              ? rawCourseId 
                              : int.tryParse(rawCourseId?.toString() ?? '') ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
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
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ParentChildClasses(
                                      studentId: widget.studentId,
                                      courseId: courseId,
                                      courseTitle: courseTitle,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(Icons.menu_book, color: Colors.teal.shade700, size: 24),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "COURSE #$courseNumber",
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                courseTitle,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.chevron_right, color: Colors.grey.shade600, size: 20),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: const [
                                        Text(
                                          "View Enrolled Classes",
                                          style: TextStyle(
                                            color: Colors.teal,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Icon(Icons.arrow_forward, color: Colors.teal, size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
// import 'package:house_of_tutor/ParentChildDetail.dart';
// import 'package:house_of_tutor/ParentChildProfile.dart';
// import 'package:house_of_tutor/services/api_client.dart';

// class ParentChildCourses extends StatefulWidget {
//   final int studentId;

//   const ParentChildCourses({
//     Key? key,
//     required this.studentId,
//   }) : super(key: key);

//   @override
//   State<ParentChildCourses> createState() => _ParentChildCoursesState();
// }

// class _ParentChildCoursesState extends State<ParentChildCourses> {
//   bool isLoading = true;
//   List<dynamic> courses = [];

//   @override
//   void initState() {
//     super.initState();
//     getCourses();
//   }

//   Future<void> getCourses() async {
//     setState(() => isLoading = true);

//     try {
//       final response = await ApiClient.get(
//         "/api/Parent/child-courses/${widget.studentId}",
//       );

//       debugPrint("CHILD COURSES STATUS : ${response.statusCode}");
//       debugPrint("CHILD COURSES BODY : ${response.body}");

//       if (response.statusCode == 200) {
//         setState(() {
//           courses = jsonDecode(utf8.decode(response.bodyBytes));
//           isLoading = false;
//         });
//       } else {
//         setState(() => isLoading = false);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 ApiClient.messageFromBody(response.body) ??
//                     "Unable to fetch courses",
//               ),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint("CHILD COURSES ERROR : $e");
//       setState(() => isLoading = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.toString())),
//         );
//       }
//     }
//   }

//   Future<void> refreshData() async {
//     await getCourses();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,

//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 1,
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
//         centerTitle: true,
//         title: Image.asset("assets/images/logo.png", height: 45),
//       ),

//       body: RefreshIndicator(
//         onRefresh: refreshData,
//         child: isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : courses.isEmpty
//                 ? const Center(
//                     child: Text(
//                       "No Courses Found",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   )
//                 : Column(
//                     children: [
//                       const SizedBox(height: 20),

//                       const Text(
//                         "Child Courses",
//                         style: TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.teal,
//                         ),
//                       ),

//                       const SizedBox(height: 20),

//                       Expanded(
//                         child: ListView.builder(
//                           itemCount: courses.length,
//                           itemBuilder: (context, index) {
//                             final course = courses[index];

//                             return InkWell(
//                               onTap: () {
//                                 // ✅ Course pe click karne pe classes open hongi
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (_) => ParentChildClasses(
//                                       studentId: widget.studentId,
//                                       courseId: course["courseId"],
//                                       courseName: course["courseTitle"],
//                                     ),
//                                   ),
//                                 );
//                               },
//                               child: Container(
//                                 margin: const EdgeInsets.symmetric(
//                                   horizontal: 15,
//                                   vertical: 8,
//                                 ),
//                                 padding: const EdgeInsets.all(15),
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(15),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.grey.shade300,
//                                       blurRadius: 6,
//                                       offset: const Offset(0, 3),
//                                     ),
//                                   ],
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     Container(
//                                       width: 60,
//                                       height: 60,
//                                       decoration: BoxDecoration(
//                                         color: Colors.teal.shade50,
//                                         shape: BoxShape.circle,
//                                       ),
//                                       child: const Icon(
//                                         Icons.menu_book_outlined,
//                                         color: Colors.teal,
//                                         size: 32,
//                                       ),
//                                     ),

//                                     const SizedBox(width: 18),

//                                     Expanded(
//                                       child: Text(
//                                         course["courseTitle"] ?? "",
//                                         style: const TextStyle(
//                                           fontSize: 20,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),

//                                     Container(
//                                       width: 38,
//                                       height: 38,
//                                       alignment: Alignment.center,
//                                       decoration: const BoxDecoration(
//                                         color: Colors.teal,
//                                         shape: BoxShape.circle,
//                                       ),
//                                       child: Text(
//                                         "${index + 1}",
//                                         style: const TextStyle(
//                                           color: Colors.white,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//       ),

//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: 1,
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
//               // Current screen
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
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("Coming soon")),
//               );
//               break;

//             case 4:
//               // ✅ Classes screen - bina courseId ke sabhi classes
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
//           // ✅ Classes item add kiya
//           BottomNavigationBarItem(
//             icon: Icon(Icons.class_),
//             label: "Fees",
//           ),
//         ],
//       ),
//     );
//   }
// }














































































// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:house_of_tutor/ParentChildClasses.dart';
// // import 'package:house_of_tutor/ParentChildDetail.dart';
// // import 'package:house_of_tutor/ParentChildProfile.dart';
// // import 'package:house_of_tutor/services/api_client.dart';


// // class ParentChildCourses extends StatefulWidget {
// //   final int studentId;

// //   const ParentChildCourses({
// //     Key? key,
// //     required this.studentId,
// //   }) : super(key: key);

// //   @override
// //   State<ParentChildCourses> createState() =>
// //       _ParentChildCoursesState();
// // }

// // class _ParentChildCoursesState
// //     extends State<ParentChildCourses> {

// //   bool isLoading = true;

// //   List<dynamic> courses = [];

// //   @override
// //   void initState() {
// //     super.initState();
// //     getCourses();
// //   }

// //   Future<void> getCourses() async {

// //     try {

// //       final response = await ApiClient.get(
// //         "/api/Parent/child-courses/${widget.studentId}",
// //       );

// //       if (response.statusCode == 200) {

// //         setState(() {

// //           courses = jsonDecode(
// //             utf8.decode(response.bodyBytes),
// //           );

// //           isLoading = false;

// //         });

// //       } else {

// //         setState(() {
// //           isLoading = false;
// //         });

// //         ScaffoldMessenger.of(context).showSnackBar(

// //           SnackBar(

// //             content: Text(

// //               ApiClient.messageFromBody(response.body) ??
// //                   "Unable to fetch courses",

// //             ),

// //           ),

// //         );

// //       }

// //     } catch (e) {

// //       setState(() {
// //         isLoading = false;
// //       });

// //       ScaffoldMessenger.of(context).showSnackBar(

// //         SnackBar(
// //           content: Text(e.toString()),
// //         ),

// //       );

// //     }

// //   }

// //   Future<void> refreshData() async {

// //     await getCourses();

// //   }

// //   @override
// //   Widget build(BuildContext context) {

// //     return Scaffold(
// //   backgroundColor: Colors.grey.shade100,

// //   appBar: AppBar(
// //     backgroundColor: Colors.white,
// //     elevation: 1,
// //     leading: IconButton(
// //       icon: const Icon(
// //         Icons.arrow_back,
// //         color: Colors.teal,
// //       ),
// //       onPressed: () {
// //         Navigator.pop(context);
// //       },
// //     ),
// //     centerTitle: true,
// //     title: Image.asset(
// //       "assets/images/logo.png",
// //       height: 45,
// //     ),
// //   ),

// //   body: RefreshIndicator(
// //     onRefresh: refreshData,
// //     child: isLoading
// //         ? const Center(
// //             child: CircularProgressIndicator(),
// //           )
// //         : courses.isEmpty
// //             ? const Center(
// //                 child: Text(
// //                   "No Courses Found",
// //                   style: TextStyle(
// //                     fontSize: 18,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //               )
// //             : Column(
// //                 children: [
// //                   const SizedBox(height: 20),

// //                   const Text(
// //                     "Child Courses",
// //                     style: TextStyle(
// //                       fontSize: 28,
// //                       fontWeight: FontWeight.bold,
// //                       color: Colors.teal,
// //                     ),
// //                   ),

// //                   const SizedBox(height: 20),

// //                   Expanded(
// //                     child: ListView.builder(
// //                       itemCount: courses.length,
// //                       itemBuilder: (context, index) {
// //                         final course = courses[index];

// //                         return InkWell(
// //                           onTap: () {
// //                             Navigator.push(
// //                               context,
// //                               MaterialPageRoute(
// //                                 builder: (_) => ParentChildClasses(
// //                                   studentId: widget.studentId,
// //                                   courseId: course["courseId"],
// //                                   courseName: course["courseTitle"],
// //                                 ),
// //                               ),
// //                             );
// //                           },
// //                           child: Container(
// //                             margin: const EdgeInsets.symmetric(
// //                               horizontal: 15,
// //                               vertical: 8,
// //                             ),
// //                             padding: const EdgeInsets.all(15),
// //                             decoration: BoxDecoration(
// //                               color: Colors.white,
// //                               borderRadius: BorderRadius.circular(15),
// //                               boxShadow: [
// //                                 BoxShadow(
// //                                   color: Colors.grey.shade300,
// //                                   blurRadius: 6,
// //                                   offset: const Offset(0, 3),
// //                                 ),
// //                               ],
// //                             ),
// //                             child: Row(
// //                               children: [
// //                                 Container(
// //                                   width: 60,
// //                                   height: 60,
// //                                   decoration: BoxDecoration(
// //                                     color: Colors.teal.shade50,
// //                                     shape: BoxShape.circle,
// //                                   ),
// //                                   child: const Icon(
// //                                     Icons.menu_book_outlined,
// //                                     color: Colors.teal,
// //                                     size: 32,
// //                                   ),
// //                                 ),

// //                                 const SizedBox(width: 18),

// //                                 Expanded(
// //                                   child: Text(
// //                                     course["courseTitle"] ?? "",
// //                                     style: const TextStyle(
// //                                       fontSize: 20,
// //                                       fontWeight: FontWeight.bold,
// //                                     ),
// //                                   ),
// //                                 ),

// //                                 Container(
// //                                   width: 38,
// //                                   height: 38,
// //                                   alignment: Alignment.center,
// //                                   decoration: const BoxDecoration(
// //                                     color: Colors.teal,
// //                                     shape: BoxShape.circle,
// //                                   ),
// //                                   child: Text(
// //                                     "${index + 1}",
// //                                     style: const TextStyle(
// //                                       color: Colors.white,
// //                                       fontWeight: FontWeight.bold,
// //                                     ),
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                           ),
// //                         );
// //                       },
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //   ),

// //   bottomNavigationBar: BottomNavigationBar(
// //     currentIndex: 1,
// //     type: BottomNavigationBarType.fixed,
// //     selectedItemColor: Colors.teal,
// //     unselectedItemColor: Colors.grey,

// //     onTap: (index) {
// //       switch (index) {
// //         case 0:
// //           Navigator.pushReplacement(
// //             context,
// //             MaterialPageRoute(
// //               builder: (_) => ParentChildProfile(
// //                 studentId: widget.studentId,
// //               ),
// //             ),
// //           );
// //           break;

// //         case 1:
// //           break;

// //         case 2:
// //           Navigator.pushReplacement(
// //             context,
// //             MaterialPageRoute(
// //               builder: (_) => ParentChildDetail(
// //                 studentId: widget.studentId,
// //                 childName: "",
// //                 email: "",
// //                 phone: "",
// //               ),
// //             ),
// //           );
// //           break;

// //         // case 3:
// //         //   Navigator.pushReplacement(
// //         //     context,
// //         //     MaterialPageRoute(
// //         //       builder: (_) => ParentChildTutor(
// //         //         studentId: widget.studentId,
// //         //       ),
// //         //     ),
// //         //   );
// //         //   break;

// //         case 4:
        

// //           ScaffoldMessenger.of(context).showSnackBar(
// //             const SnackBar(
// //               content: Text(
// //                 "Please select a course first.",
// //               ),
// //             ),
// //           );

// //           break;
// //       }
// //     },

// //     items: const [
// //       BottomNavigationBarItem(
// //         icon: Icon(Icons.person),
// //         label: "Profile",
// //       ),
// //       BottomNavigationBarItem(
// //         icon: Icon(Icons.book),
// //         label: "Courses",
// //       ),
// //       BottomNavigationBarItem(
// //         icon: Icon(Icons.schedule),
// //         label: "Schedule",
// //       ),
// //       BottomNavigationBarItem(
// //         icon: Icon(Icons.school),
// //         label: "Tutors",
// //       ),
// //       BottomNavigationBarItem(
// //         icon: Icon(Icons.class_),
// //         label: "Classes",
// //       ),
// //     ],
// //   ),
// // );
// //   }}