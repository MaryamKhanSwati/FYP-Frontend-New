import 'package:flutter/material.dart';
import 'package:house_of_tutor/StudentHome.dart';
import 'package:house_of_tutor/StudentAddCourses.dart';
import 'package:house_of_tutor/StudentAllClasses.dart';
import 'package:house_of_tutor/StudentDrawer.dart';
import 'package:house_of_tutor/StudentFindTutor.dart';
import 'package:house_of_tutor/StudentFindNonVisitingTutor.dart';
import 'package:house_of_tutor/services/api_client.dart';
import 'package:house_of_tutor/services/auth_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentCourses extends StatefulWidget {
  const StudentCourses({super.key});

  @override
  State<StudentCourses> createState() => _StudentCoursesState();
}

class _StudentCoursesState extends State<StudentCourses> {
  // ============================================================
  // VARIABLES
  // ============================================================

  bool isLoading = true;

  List<dynamic> coursesList = [];

  String errorMessage = '';

  // Main color of this screen
  final Color primaryColor = const Color(0xff009688);

  // Drawer control
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Bottom navigation: this screen is "Request" (index 2)
  int selectedIndex = 2;

  // Logo path (change if your asset path is different)
  static const String logoPath = 'assets/images/logo.png';

  // Student location
  double? userLat;
  double? userLng;

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    initializePage();
  }

  // ============================================================
  // INITIALIZE PAGE
  // ============================================================
  //
  // Location and courses load at the same time,
  // so the screen opens faster.
  // ============================================================

  Future<void> initializePage() async {
    await Future.wait([
      loadStudentLocation(),
      fetchStudentCourses(),
    ]);
  }

  // ============================================================
  // BOTTOM NAVIGATION TAP
  // ============================================================

  void onTapBottom(int index) {
    // Already on this screen
    if (index == selectedIndex) return;

    Widget? screen;

    switch (index) {
      case 0:
        // Home / Schedule
        screen = const StudentHome();
        break;

      case 1:
        // Add Courses
        screen = const StudentAddCourses();
        break;

      case 3:
        // Classes
        screen = const StudentAllClasses();
        break;
    }

    if (screen == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen!),
    );
  }

  // ============================================================
  // LOAD STUDENT LOCATION
  // ============================================================

  Future<void> loadStudentLocation() async {
    try {
      // LOAD LOCATION FROM AUTH STORE
      await AuthStore.instance.hydrate();

      userLat = AuthStore.instance.lastLat;
      userLng = AuthStore.instance.lastLng;

      debugPrint('====================================');
      debugPrint('StudentCourses LOCATION FROM AUTH STORE');
      debugPrint('Latitude: $userLat');
      debugPrint('Longitude: $userLng');
      debugPrint('====================================');

      // FALLBACK TO SHARED PREFERENCES
      if (!isValidLocation()) {
        final prefs = await SharedPreferences.getInstance();

        userLat = prefs.getDouble('latitude');
        userLng = prefs.getDouble('longitude');

        debugPrint('====================================');
        debugPrint('StudentCourses LOCATION FROM PREFS');
        debugPrint('Latitude: $userLat');
        debugPrint('Longitude: $userLng');
        debugPrint('====================================');
      }

      debugPrint('FINAL STUDENT LOCATION: $userLat, $userLng '
          '(valid: ${isValidLocation()})');
    } catch (e) {
      debugPrint('StudentCourses Location Error: $e');

      userLat = null;
      userLng = null;
    }
  }

  // ============================================================
  // VALIDATE LOCATION
  // ============================================================

  bool isValidLocation() {
    if (userLat == null || userLng == null) return false;

    if (userLat!.isNaN || userLng!.isNaN) return false;

    if (userLat! < -90 || userLat! > 90) return false;

    if (userLng! < -180 || userLng! > 180) return false;

    return true;
  }

  // ============================================================
  // GET STUDENT COURSES
  // ============================================================

  Future<void> fetchStudentCourses() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }

    try {
      final response = await ApiClient.get('/api/Student/my-courses');

      if (!mounted) return;

      debugPrint('Student Courses Status: ${response.statusCode}');
      debugPrint('Student Courses Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = await ApiClient.decodeJson(response);

        if (!mounted) return;

        List courses = [];

        // API can return a direct list: [...]
        if (data is List) {
          courses = data;
        }
        // Or: { "data": [...] }
        else if (data is Map && data['data'] is List) {
          courses = data['data'];
        }

        setState(() {
          coursesList = courses;
          isLoading = false;
          errorMessage = '';
        });
      } else {
        final errorMsg = ApiClient.messageFromBody(response.body) ??
            'Failed to load courses.';

        setState(() {
          errorMessage = errorMsg;
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('Student Courses Error: $e');

      setState(() {
        errorMessage = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  // ============================================================
  // FIND VISITING TUTOR
  // ============================================================
  //
  // Tutor comes to student's location,
  // so student location is required.
  // ============================================================

  Future<void> navigateToFindTutor(
    int courseId,
    String courseName,
  ) async {
    // Always load the latest location
    await loadStudentLocation();

    if (!mounted) return;

    if (!isValidLocation()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Student location not found. Please login again to update your location.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );

      return;
    }

    debugPrint('====================================');
    debugPrint('NAVIGATING TO VISITING TUTOR');
    debugPrint('Course ID: $courseId');
    debugPrint('Course Name: $courseName');
    debugPrint('Student Latitude: $userLat');
    debugPrint('Student Longitude: $userLng');
    debugPrint('====================================');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentFindTutor(
          courseId: courseId,
          courseName: courseName,
          userLat: userLat!,
          userLng: userLng!,
        ),
      ),
    );
  }

  // ============================================================
  // FIND NON-VISITING TUTOR
  // ============================================================
  //
  // Student goes to tutor's place,
  // so student location is NOT required.
  // ============================================================

  void navigateToFindNonVisitingTutor(
    int courseId,
    String courseName,
  ) {
    debugPrint('====================================');
    debugPrint('NAVIGATING TO NON-VISITING TUTOR');
    debugPrint('Course ID: $courseId');
    debugPrint('Course Name: $courseName');
    debugPrint('====================================');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentFindTutorNonVisiting(
          courseId: courseId,
          courseName: courseName,
        ),
      ),
    );
  }

  // ============================================================
  // LOGO WIDGET
  // ============================================================

  Widget buildLogo() {
    return Image.asset(
      logoPath,
      height: 32,
      width: 32,
      fit: BoxFit.contain,
      // If the logo file is missing, show the old school icon
      errorBuilder: (context, error, stackTrace) {
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.school,
            color: primaryColor,
            size: 20,
          ),
        );
      },
    );
  }

  // ============================================================
  // COURSE CARD
  // ============================================================

  Widget buildCourseCard(dynamic course) {
    final int courseId = _toInt(course['course_id']);

    final String courseName = course['course_name']?.toString() ??
        course['course_title']?.toString() ??
        'Course';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COURSE INFORMATION
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu_book,
                  color: primaryColor,
                  size: 22,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Active Course',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // FIND VISITING TUTOR BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              onPressed: courseId <= 0
                  ? null
                  : () => navigateToFindTutor(courseId, courseName),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, size: 17),
                  SizedBox(width: 7),
                  Text(
                    'Find Visiting Tutor',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.search, size: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // FIND NON-VISITING TUTOR BUTTON
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor, width: 1.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: courseId <= 0
                  ? null
                  : () => navigateToFindNonVisitingTutor(
                        courseId,
                        courseName,
                      ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_work_outlined, size: 18),
                  SizedBox(width: 7),
                  Text(
                    'Find Non-Visiting Tutor',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.search, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BODY CONTENT (loading / error / empty / list)
  // ============================================================

  Widget buildBody() {
    // Loading
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    // Error: scrollable so pull-to-refresh still works
    if (errorMessage.isNotEmpty && coursesList.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                errorMessage,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    // Empty
    if (coursesList.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'No enrolled courses found.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
          ),
        ],
      );
    }

    // Course list
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: coursesList.length,
      itemBuilder: (context, index) {
        return buildCourseCard(coursesList[index]);
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade50,

      // DRAWER
      drawer: const StudentDrawer(),

      // APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.menu,
            color: Colors.black87,
          ),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildLogo(),
            const SizedBox(width: 8),
            const Text(
              'House of Tutor',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Plus button opens the Add Courses screen
          IconButton(
            tooltip: 'Add Courses',
            icon: const Icon(
              Icons.add,
              color: Colors.black87,
            ),
            onPressed: () => onTapBottom(1),
          ),
        ],
      ),

      // BODY
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Enrolled Courses',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${coursesList.length}',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Text(
              'Select a subject to find a tutor',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 16),

            // COURSES (with pull-to-refresh)
            Expanded(
              child: RefreshIndicator(
                color: primaryColor,
                onRefresh: fetchStudentCourses,
                child: buildBody(),
              ),
            ),
          ],
        ),
      ),

      // ==========================================================
      // BOTTOM NAVIGATION
      // ==========================================================

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: onTapBottom,
        items: const [
          // Home / Schedule
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Schedule",
          ),

          // Add Courses
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: "Add Courses",
          ),

          // Request
          BottomNavigationBarItem(
            icon: Icon(Icons.request_page),
            label: "Request",
          ),

          // Classes
          BottomNavigationBarItem(
            icon: Icon(Icons.class_),
            label: "Classes",
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAFE INT CONVERSION
  // ============================================================

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is num) return value.toInt();

    return int.tryParse(value.toString().trim()) ?? 0;
  }
}






// import 'package:flutter/material.dart';
// import 'package:house_of_tutor/StudentFindTutor.dart';
// import 'package:house_of_tutor/StudentFindNonVisitingTutor.dart';
// import 'package:house_of_tutor/services/api_client.dart';
// import 'package:house_of_tutor/services/auth_store.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class StudentCourses extends StatefulWidget {
//   const StudentCourses({super.key});

//   @override
//   State<StudentCourses> createState() => _StudentCoursesState();
// }

// class _StudentCoursesState extends State<StudentCourses> {
//   bool isLoading = true;

//   List<dynamic> coursesList = [];

//   String errorMessage = '';

//   // ============================================================
//   // STUDENT LOCATION
//   // ============================================================

//   double? userLat;
//   double? userLng;

//   // ============================================================
//   // INIT STATE
//   // ============================================================

//   @override
//   void initState() {
//     super.initState();

//     initializePage();
//   }

//   // ============================================================
//   // INITIALIZE PAGE
//   // ============================================================

//   Future<void> initializePage() async {
//     await loadStudentLocation();

//     await fetchStudentCourses();
//   }

//   // ============================================================
//   // LOAD STUDENT LOCATION
//   // ============================================================

//   Future<void> loadStudentLocation() async {
//     try {
//       // ==========================================================
//       // LOAD LOCATION FROM AUTH STORE
//       // ==========================================================

//       await AuthStore.instance.hydrate();

//       userLat = AuthStore.instance.lastLat;
//       userLng = AuthStore.instance.lastLng;

//       debugPrint('====================================');
//       debugPrint('StudentCourses LOCATION FROM AUTH STORE');
//       debugPrint('Latitude: $userLat');
//       debugPrint('Longitude: $userLng');
//       debugPrint('====================================');

//       // ==========================================================
//       // FALLBACK TO SHARED PREFERENCES
//       // ==========================================================

//       if (!isValidLocation()) {
//         final prefs = await SharedPreferences.getInstance();

//         userLat = prefs.getDouble('latitude');
//         userLng = prefs.getDouble('longitude');

//         debugPrint('====================================');
//         debugPrint('StudentCourses LOCATION FROM PREFS');
//         debugPrint('Latitude: $userLat');
//         debugPrint('Longitude: $userLng');
//         debugPrint('====================================');
//       }

//       // ==========================================================
//       // FINAL LOCATION
//       // ==========================================================

//       debugPrint('====================================');
//       debugPrint('FINAL STUDENT LOCATION');
//       debugPrint('Latitude: $userLat');
//       debugPrint('Longitude: $userLng');
//       debugPrint('Valid: ${isValidLocation()}');
//       debugPrint('====================================');
//     } catch (e) {
//       debugPrint(
//         'StudentCourses Location Error: $e',
//       );

//       userLat = null;
//       userLng = null;
//     }
//   }

//   // ============================================================
//   // VALIDATE LOCATION
//   // ============================================================

//   bool isValidLocation() {
//     if (userLat == null || userLng == null) {
//       return false;
//     }

//     if (userLat!.isNaN || userLng!.isNaN) {
//       return false;
//     }

//     if (userLat! < -90 || userLat! > 90) {
//       return false;
//     }

//     if (userLng! < -180 || userLng! > 180) {
//       return false;
//     }

//     return true;
//   }

//   // ============================================================
//   // GET STUDENT COURSES
//   // ============================================================

//   Future<void> fetchStudentCourses() async {
//     try {
//       final response = await ApiClient.get(
//         '/api/Student/my-courses',
//       );

//       if (!mounted) return;

//       debugPrint(
//         'Student Courses Status: ${response.statusCode}',
//       );

//       debugPrint(
//         'Student Courses Response: ${response.body}',
//       );

//       if (response.statusCode == 200) {
//         final data = await ApiClient.decodeJson(response);

//         setState(() {
//           coursesList = data is List ? data : [];

//           isLoading = false;

//           errorMessage = '';
//         });
//       } else {
//         final errorMsg =
//             ApiClient.messageFromBody(response.body) ??
//                 'Failed to load courses.';

//         setState(() {
//           errorMessage = errorMsg;

//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (!mounted) return;

//       debugPrint(
//         'Student Courses Error: $e',
//       );

//       setState(() {
//         errorMessage = 'An error occurred: $e';

//         isLoading = false;
//       });
//     }
//   }

//   // ============================================================
//   // FIND VISITING TUTOR
//   // ============================================================
//   //
//   // Visiting Tutor:
//   // Student location is required.
//   //
//   // Tutor comes to student's location.
//   //
//   // ============================================================

//   Future<void> navigateToFindTutor(
//     BuildContext context,
//     int courseId,
//     String courseName,
//   ) async {
//     // ==========================================================
//     // ALWAYS LOAD LATEST LOCATION
//     // ==========================================================

//     await loadStudentLocation();

//     // ==========================================================
//     // CHECK LOCATION
//     // ==========================================================

//     if (!isValidLocation()) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Student location not found. Please login again to update your location.',
//           ),
//           backgroundColor: Colors.red,
//           duration: Duration(seconds: 4),
//         ),
//       );

//       return;
//     }

//     // ==========================================================
//     // DEBUG
//     // ==========================================================

//     debugPrint('====================================');
//     debugPrint('NAVIGATING TO VISITING TUTOR');
//     debugPrint('Course ID: $courseId');
//     debugPrint('Course Name: $courseName');
//     debugPrint('Student Latitude: $userLat');
//     debugPrint('Student Longitude: $userLng');
//     debugPrint('====================================');

//     // ==========================================================
//     // NAVIGATE
//     // ==========================================================

//     if (!mounted) return;

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => StudentFindTutor(
//           courseId: courseId,
//           courseName: courseName,
//           userLat: userLat!,
//           userLng: userLng!,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // FIND NON-VISITING TUTOR
//   // ============================================================
//   //
//   // Non-Visiting Tutor:
//   // Student goes to tutor's place.
//   //
//   // Student location is NOT required.
//   //
//   // ============================================================

//   void navigateToFindNonVisitingTutor(
//     BuildContext context,
//     int courseId,
//     String courseName,
//   ) {
//     // ==========================================================
//     // DEBUG
//     // ==========================================================

//     debugPrint('====================================');
//     debugPrint('NAVIGATING TO NON-VISITING TUTOR');
//     debugPrint('Course ID: $courseId');
//     debugPrint('Course Name: $courseName');
//     debugPrint('====================================');

//     // ==========================================================
//     // NAVIGATE
//     // ==========================================================

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => StudentFindTutorNonVisiting(
//           courseId: courseId,
//           courseName: courseName,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // BUILD
//   // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,

//       // ==========================================================
//       // APP BAR
//       // ==========================================================

//       appBar: AppBar(
//         backgroundColor: Colors.white,

//         elevation: 0,

//         leading: IconButton(
//           icon: const Icon(
//             Icons.menu,
//             color: Colors.black87,
//           ),
//           onPressed: () {},
//         ),

//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(6),

//               decoration: BoxDecoration(
//                 color: Colors.teal.shade50,

//                 borderRadius: BorderRadius.circular(8),
//               ),

//               child: const Icon(
//                 Icons.school,

//                 color: Color(0xff009688),

//                 size: 20,
//               ),
//             ),

//             const SizedBox(width: 8),

//             const Text(
//               'House of Tutor',

//               style: TextStyle(
//                 color: Colors.black87,

//                 fontWeight: FontWeight.bold,

//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),

//         centerTitle: true,

//         actions: [
//           IconButton(
//             icon: const Icon(
//               Icons.add,

//               color: Colors.black87,
//             ),

//             onPressed: () {},
//           ),
//         ],
//       ),

//       // ==========================================================
//       // BODY
//       // ==========================================================

//       body: Padding(
//         padding: const EdgeInsets.symmetric(
//           horizontal: 20,
//           vertical: 10,
//         ),

//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,

//           children: [
//             // =====================================================
//             // HEADER
//             // =====================================================

//             Row(
//               mainAxisAlignment:
//                   MainAxisAlignment.spaceBetween,

//               children: [
//                 const Text(
//                   'My Enrolled Courses',

//                   style: TextStyle(
//                     fontSize: 22,

//                     fontWeight: FontWeight.bold,

//                     color: Colors.black87,
//                   ),
//                 ),

//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 10,
//                     vertical: 4,
//                   ),

//                   decoration: BoxDecoration(
//                     color: Colors.teal.shade50,

//                     borderRadius:
//                         BorderRadius.circular(12),
//                   ),

//                   child: Text(
//                     '${coursesList.length}',

//                     style: const TextStyle(
//                       color: Color(0xff009688),

//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 4),

//             Text(
//               'Select a subject to find a tutor',

//               style: TextStyle(
//                 fontSize: 13,

//                 color: Colors.grey.shade600,
//               ),
//             ),

//             const SizedBox(height: 16),

//             // =====================================================
//             // COURSES
//             // =====================================================

//             Expanded(
//               child: isLoading
//                   ? const Center(
//                       child:
//                           CircularProgressIndicator(
//                         color: Color(0xff009688),
//                       ),
//                     )
//                   : errorMessage.isNotEmpty &&
//                           coursesList.isEmpty
//                       ? Center(
//                           child: Text(
//                             errorMessage,

//                             style: const TextStyle(
//                               color: Colors.grey,

//                               fontSize: 15,
//                             ),

//                             textAlign: TextAlign.center,
//                           ),
//                         )
//                       : coursesList.isEmpty
//                           ? const Center(
//                               child: Text(
//                                 'No enrolled courses found.',

//                                 style: TextStyle(
//                                   color: Colors.grey,

//                                   fontSize: 15,
//                                 ),
//                               ),
//                             )
//                           : ListView.builder(
//                               itemCount:
//                                   coursesList.length,

//                               itemBuilder:
//                                   (context, index) {
//                                 final course =
//                                     coursesList[index];

//                                 // =================================================
//                                 // COURSE ID
//                                 // =================================================

//                                 final int courseId =
//                                     _toInt(
//                                   course['course_id'],
//                                 );

//                                 // =================================================
//                                 // COURSE NAME
//                                 // =================================================

//                                 final String courseName =
//                                     course['course_name']
//                                             ?.toString() ??
//                                         'Course';

//                                 return Container(
//                                   margin:
//                                       const EdgeInsets.only(
//                                     bottom: 16,
//                                   ),

//                                   padding:
//                                       const EdgeInsets.all(
//                                     16,
//                                   ),

//                                   decoration:
//                                       BoxDecoration(
//                                     color: Colors.white,

//                                     borderRadius:
//                                         BorderRadius.circular(
//                                       16,
//                                     ),

//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: Colors.black
//                                             .withOpacity(
//                                           0.04,
//                                         ),

//                                         blurRadius: 8,

//                                         offset:
//                                             const Offset(
//                                           0,
//                                           2,
//                                         ),
//                                       ),
//                                     ],
//                                   ),

//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment
//                                             .start,

//                                     children: [
//                                       // ==========================================
//                                       // COURSE INFORMATION
//                                       // ==========================================

//                                       Row(
//                                         children: [
//                                           Container(
//                                             width: 45,

//                                             height: 45,

//                                             decoration:
//                                                 BoxDecoration(
//                                               color: Colors
//                                                   .teal
//                                                   .shade50,

//                                               borderRadius:
//                                                   BorderRadius
//                                                       .circular(
//                                                 12,
//                                               ),
//                                             ),

//                                             child:
//                                                 const Icon(
//                                               Icons.menu_book,

//                                               color:
//                                                   Color(
//                                                 0xff009688,
//                                               ),

//                                               size: 22,
//                                             ),
//                                           ),

//                                           const SizedBox(
//                                             width: 14,
//                                           ),

//                                           Expanded(
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment
//                                                       .start,

//                                               children: [
//                                                 Text(
//                                                   courseName,

//                                                   style:
//                                                       const TextStyle(
//                                                     fontSize:
//                                                         16,

//                                                     fontWeight:
//                                                         FontWeight
//                                                             .bold,

//                                                     color: Colors
//                                                         .black87,
//                                                   ),
//                                                 ),

//                                                 const SizedBox(
//                                                   height: 2,
//                                                 ),

//                                                 Text(
//                                                   'Active Course',

//                                                   style:
//                                                       TextStyle(
//                                                     fontSize:
//                                                         12,

//                                                     color: Colors
//                                                         .grey
//                                                         .shade500,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                         ],
//                                       ),

//                                       const SizedBox(
//                                         height: 16,
//                                       ),

//                                       // ==========================================
//                                       // FIND VISITING TUTOR BUTTON
//                                       // ==========================================

//                                       SizedBox(
//                                         width:
//                                             double.infinity,

//                                         child:
//                                             ElevatedButton(
//                                           style:
//                                               ElevatedButton
//                                                   .styleFrom(
//                                             backgroundColor:
//                                                 const Color(
//                                               0xff009688,
//                                             ),

//                                             foregroundColor:
//                                                 Colors.white,

//                                             shape:
//                                                 RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius
//                                                       .circular(
//                                                 12,
//                                               ),
//                                             ),

//                                             padding:
//                                                 const EdgeInsets
//                                                     .symmetric(
//                                               vertical: 12,
//                                             ),

//                                             elevation: 0,
//                                           ),

//                                           // =================================================
//                                           // CALL VISITING TUTOR FUNCTION HERE
//                                           // =================================================

//                                           onPressed:
//                                               courseId <=
//                                                       0
//                                                   ? null
//                                                   : () {
//                                                       navigateToFindTutor(
//                                                         context,
//                                                         courseId,
//                                                         courseName,
//                                                       );
//                                                     },

//                                           child: Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment
//                                                     .center,

//                                             children: const [
//                                               Icon(
//                                                 Icons
//                                                     .location_on,
//                                                 size: 17,
//                                               ),

//                                               SizedBox(
//                                                 width: 7,
//                                               ),

//                                               Text(
//                                                 'Find Visiting Tutor',

//                                                 style:
//                                                     TextStyle(
//                                                   fontWeight:
//                                                       FontWeight
//                                                           .bold,
//                                                 ),
//                                               ),

//                                               SizedBox(
//                                                 width: 6,
//                                               ),

//                                               Icon(
//                                                 Icons.search,
//                                                 size: 16,
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ),

//                                       const SizedBox(
//                                         height: 10,
//                                       ),

//                                       // ==========================================
//                                       // FIND NON-VISITING TUTOR BUTTON
//                                       // ==========================================

//                                       SizedBox(
//                                         width:
//                                             double.infinity,

//                                         child:
//                                             OutlinedButton(
//                                           style:
//                                               OutlinedButton
//                                                   .styleFrom(
//                                             foregroundColor:
//                                                 const Color(
//                                               0xff009688,
//                                             ),

//                                             side:
//                                                 const BorderSide(
//                                               color: Color(
//                                                 0xff009688,
//                                               ),
//                                               width: 1.3,
//                                             ),

//                                             shape:
//                                                 RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius
//                                                       .circular(
//                                                 12,
//                                               ),
//                                             ),

//                                             padding:
//                                                 const EdgeInsets
//                                                     .symmetric(
//                                               vertical: 12,
//                                             ),
//                                           ),

//                                           // =================================================
//                                           // CALL NON-VISITING TUTOR FUNCTION HERE
//                                           // =================================================

//                                           onPressed:
//                                               courseId <=
//                                                       0
//                                                   ? null
//                                                   : () {
//                                                       navigateToFindNonVisitingTutor(
//                                                         context,
//                                                         courseId,
//                                                         courseName,
//                                                       );
//                                                     },

//                                           child: Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment
//                                                     .center,

//                                             children: const [
//                                               Icon(
//                                                 Icons
//                                                     .home_work_outlined,
//                                                 size: 18,
//                                               ),

//                                               SizedBox(
//                                                 width: 7,
//                                               ),

//                                               Text(
//                                                 'Find Non-Visiting Tutor',

//                                                 style:
//                                                     TextStyle(
//                                                   fontWeight:
//                                                       FontWeight
//                                                           .bold,
//                                                 ),
//                                               ),

//                                               SizedBox(
//                                                 width: 6,
//                                               ),

//                                               Icon(
//                                                 Icons.search,
//                                                 size: 16,
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 );
//                               },
//                             ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // SAFE INT CONVERSION
//   // ============================================================

//   int _toInt(dynamic value) {
//     if (value == null) {
//       return 0;
//     }

//     if (value is int) {
//       return value;
//     }

//     if (value is num) {
//       return value.toInt();
//     }

//     return int.tryParse(
//           value.toString().trim(),
//         ) ??
//         0;
//   }
// }
