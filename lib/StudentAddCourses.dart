
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:house_of_tutor/StudentHome.dart';
import 'package:house_of_tutor/StudentAllClasses.dart';
import 'package:house_of_tutor/StudentCourses.dart';
import 'package:house_of_tutor/StudentDrawer.dart';
import 'package:house_of_tutor/services/api_client.dart';
import 'package:house_of_tutor/services/api_config.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
// COLORS
// ============================================================

const Color primaryColor = Color(0xFF1E8E7E);
const Color pageColor = Color(0xFFF6F8FA);
const Color darkColor = Color(0xFF202C3B);
const Color secondaryTextColor = Color(0xFF718096);
const Color borderColor = Color(0xFFE3E9EE);

// ============================================================
// STUDENT ADD COURSES
// ============================================================

class StudentAddCourses extends StatefulWidget {
  const StudentAddCourses({super.key});

  @override
  State<StudentAddCourses> createState() => _StudentAddCoursesState();
}

class _StudentAddCoursesState extends State<StudentAddCourses> {
  final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  final TextEditingController searchController =
      TextEditingController();

  Timer? searchTimer;

  bool isLoading = true;
  bool isMyCoursesLoading = false;
  bool isMyCoursesView = false;

  String searchError = '';
  String myCoursesError = '';

  List<dynamic> catalogCourses = [];
  List<dynamic> myCourses = [];

  final Set<int> addingCourseIds = {};

  int selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  @override
  void dispose() {
    searchTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // COMMON HELPERS
  // ============================================================

  int courseIdOf(dynamic course) {
    if (course is! Map) return 0;

    return int.tryParse(
          (course['course_id'] ??
                  course['courseId'] ??
                  course['CourseId'] ??
                  0)
              .toString(),
        ) ??
        0;
  }

  String courseNameOf(dynamic course) {
    if (course is! Map) return 'Unknown Course';

    return (course['course_name'] ??
            course['course_title'] ??
            course['CourseTitle'] ??
            'Unknown Course')
        .toString();
  }

  List<dynamic> extractList(dynamic data) {
    if (data is List) return data;

    if (data is Map) {
      if (data['data'] is List) {
        return data['data'];
      }

      if (data['courses'] is List) {
        return data['courses'];
      }
    }

    return [];
  }

  String responseMessage(dynamic data, String fallback) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }

    return fallback;
  }

  void showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              error ? Colors.red.shade700 : primaryColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // ============================================================
  // INITIAL DATA
  // ============================================================

  Future<void> loadInitialData() async {
    await Future.wait([
      fetchCatalog(),
      fetchMyCourses(silent: true),
    ]);
  }

  // ============================================================
  // API 1: GET AVAILABLE COURSES
  //
  // GET /api/Student/all-courses?search=
  //
  // Supports searching by:
  // 1. Course name
  // 2. Course code
  // ============================================================

  Future<void> fetchCatalog({String search = ''}) async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      searchError = '';
    });

    try {
      String url = '/api/Student/all-courses';

      if (search.trim().isNotEmpty) {
        url += '?search=${Uri.encodeQueryComponent(search.trim())}';
      }

      final response = await ApiClient.get(url);
      final data = await ApiClient.decodeJson(response);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          catalogCourses = extractList(data);
          isLoading = false;
          searchError = '';
        });
      } else {
        setState(() {
          isLoading = false;
          searchError = responseMessage(
            data,
            'Unable to load course catalog.',
          );
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        searchError = 'Error loading courses: $e';
      });
    }
  }

  // ============================================================
  // SEARCH WITH DEBOUNCE
  // ============================================================

  void onSearchChanged(String value) {
    searchTimer?.cancel();

    searchTimer = Timer(
      const Duration(milliseconds: 450),
      () {
        if (!mounted) return;

        fetchCatalog(search: value);
      },
    );
  }

  void clearSearch() {
    searchTimer?.cancel();
    searchController.clear();
    fetchCatalog();
  }

  // ============================================================
  // API 2: GET MY ENROLLED COURSES
  //
  // GET /api/Student/my-courses-for-student-add-courses
  // ============================================================

  Future<void> fetchMyCourses({bool silent = false}) async {
    if (!mounted) return;

    if (!silent) {
      setState(() {
        isMyCoursesLoading = true;
        myCoursesError = '';
      });
    }

    try {
      final response = await ApiClient.get(
        '/api/Student/my-courses-for-student-add-courses',
      );

      final data = await ApiClient.decodeJson(response);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          myCourses = extractList(data);
          isMyCoursesLoading = false;
          myCoursesError = '';
        });
      } else {
        setState(() {
          isMyCoursesLoading = false;
          myCoursesError = responseMessage(
            data,
            'Unable to load your courses.',
          );
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isMyCoursesLoading = false;
        myCoursesError = 'Error loading your courses: $e';
      });
    }
  }

  // ============================================================
  // API 3: ADD COURSE
  //
  // POST /api/Student/add-courses
  //
  // BODY:
  // {
  //   "courseIds": [1]
  // }
  // ============================================================

  Future<String?> addStudentCourse(int courseId) async {
    if (courseId <= 0) {
      return 'Invalid course ID.';
    }

    if (addingCourseIds.contains(courseId)) {
      return 'Please wait.';
    }

    setState(() {
      addingCourseIds.add(courseId);
    });

    try {
      final response = await ApiClient.post(
        '/api/Student/add-courses',
        {
          'courseIds': [courseId],
        },
      );

      final data = await ApiClient.decodeJson(response);

      if (!mounted) return 'Screen is no longer available.';

      if (response.statusCode == 200) {
        setState(() {
          catalogCourses.removeWhere(
            (course) => courseIdOf(course) == courseId,
          );
        });

        await fetchMyCourses(silent: true);

        if (mounted) {
          showMessage(
            responseMessage(
              data,
              'Course added successfully.',
            ),
          );
        }

        return null;
      }

      return responseMessage(
        data,
        'Unable to add course.',
      );
    } catch (e) {
      return 'Error adding course: $e';
    } finally {
      if (mounted) {
        setState(() {
          addingCourseIds.remove(courseId);
        });
      }
    }
  }

  Future<void> handleAddCourse(int id) async {
    final error = await addStudentCourse(id);

    if (!mounted) return;

    if (error != null) {
      showMessage(error, error: true);
    }
  }

  // ============================================================
  // COURSE CODE HELPERS
  // ============================================================

  List<dynamic> courseCodesOf(dynamic course) {
    if (course is! Map) return [];

    final codes = course['course_codes'] ??
        course['courseCodes'] ??
        course['CourseCodes'];

    return codes is List ? codes : [];
  }

  String codeOf(dynamic code) {
    if (code is! Map) return '';

    return (code['course_code'] ??
            code['courseCode'] ??
            code['CourseCode1'] ??
            '')
        .toString();
  }

  String instituteOf(dynamic code) {
    if (code is! Map) return '';

    return (code['institute'] ?? '').toString();
  }

  String programOf(dynamic code) {
    if (code is! Map) return '';

    return (code['program'] ?? '').toString();
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void onTapBottom(int index) {
    if (index == selectedIndex) return;

    Widget? screen;

    switch (index) {
      case 0:
        screen = const StudentHome();
        break;
      case 2:
        screen = const StudentCourses();
        break;
      case 3:
        screen = const StudentAllClasses();
        break;
    }

    if (screen == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => screen!,
      ),
    );
  }

  // ============================================================
  // UPLOAD COURSE CONTENT
  //
  // POST /api/Student/upload-course-content
  //
  // MULTIPART:
  // course_id
  // title
  // description
  // file
  // ============================================================

  Future<void> uploadCourseContent(int courseId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'jpg',
        'jpeg',
        'png',
      ],
    );

    if (result == null) return;

    final selectedFile = result.files.single;

    if (selectedFile.path == null) {
      showMessage(
        'Unable to access selected file.',
        error: true,
      );
      return;
    }

    final file = File(selectedFile.path!);

    if (!await file.exists()) {
      showMessage('Selected file does not exist.', error: true);
      return;
    }

    final fileSize = await file.length();

    if (fileSize <= 0) {
      showMessage('Selected file is empty.', error: true);
      return;
    }

    if (fileSize > 100 * 1024 * 1024) {
      showMessage('Maximum file size is 100 MB.', error: true);
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final shouldUpload = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Upload Course Content',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insert_drive_file_outlined,
                        color: primaryColor,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selectedFile.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 17),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Content Title *',
                    hintText: 'Example: Week 1 Notes',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 13),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter content description',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  showMessage(
                    'Please enter content title.',
                    error: true,
                  );
                  return;
                }

                Navigator.pop(dialogContext, true);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (shouldUpload != true || !mounted) {
      titleController.dispose();
      descriptionController.dispose();
      return;
    }

    // Show upload progress.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: primaryColor),
                SizedBox(height: 15),
                Text('Uploading course content...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final response = await ApiClient.uploadFile(
        '/api/Student/upload-course-content',
        fields: {
          'course_id': courseId.toString(),
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
        },
        fileFieldName: 'file',
        file: file,
      );

      final data = await ApiClient.decodeJson(response);

      if (!mounted) return;

      // Close only the upload progress dialog.
      Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode == 200) {
        showMessage(
          responseMessage(
            data,
            'Course content uploaded successfully.',
          ),
        );
      } else {
        showMessage(
          responseMessage(
            data,
            'Course content upload failed.',
          ),
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      showMessage(
        'Upload failed: $e',
        error: true,
      );
    } finally {
      titleController.dispose();
      descriptionController.dispose();
    }
  }

  // ============================================================
  // OPEN COURSE CONTENT
  // ============================================================

  void openCourseDetails(Map<String, dynamic> course) {
    final id = courseIdOf(course);

    if (id <= 0) {
      showMessage('Invalid course ID.', error: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentCourseContentScreen(
          courseId: id,
          courseName: courseNameOf(course),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER LOGO
  // ============================================================

  Widget buildLogo() {
    return Image.asset(
      'assets/images/logo.png',
      width: 37,
      height: 37,
      errorBuilder: (_, __, ___) {
        return const Icon(
          Icons.school,
          color: primaryColor,
          size: 32,
        );
      },
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 75,
      leading: IconButton(
        onPressed: () {
          scaffoldKey.currentState?.openDrawer();
        },
        icon: Container(
          height: 43,
          width: 43,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7F8),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.menu,
            color: darkColor,
            size: 25,
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildLogo(),
          const SizedBox(width: 9),
          const Text(
            'House of Tutor',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget buildPageHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(21, 23, 21, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isMyCoursesView ? 'My Courses' : 'Course Catalog',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: darkColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (isMyCoursesView)
                _roundAction(
                  icon: Icons.refresh,
                  onTap: () => fetchMyCourses(),
                )
              else
                _roundAction(
                  icon: Icons.refresh,
                  onTap: () => fetchCatalog(
                    search: searchController.text,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            isMyCoursesView
                ? 'Manage your enrolled courses and learning materials.'
                : 'Search by course name or course code',
            style: const TextStyle(
              fontSize: 15,
              color: secondaryTextColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 19),

          // Catalog / My Courses switch.
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFECEFF1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _viewTab(
                    title: 'Course Catalog',
                    selected: !isMyCoursesView,
                    onTap: () {
                      setState(() {
                        isMyCoursesView = false;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _viewTab(
                    title: 'My Courses (${myCourses.length})',
                    selected: isMyCoursesView,
                    onTap: () {
                      setState(() {
                        isMyCoursesView = true;
                      });

                      fetchMyCourses(silent: true);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewTab({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? primaryColor : secondaryTextColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _roundAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFEAF5F3),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: SizedBox(
          height: 43,
          width: 43,
          child: Icon(
            icon,
            color: primaryColor,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 21),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.025),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                searchTimer?.cancel();
                fetchCatalog(search: value);
              },
              decoration: InputDecoration(
                hintText: 'Search course name or code (e.g. OOP, CS)',
                hintStyle: TextStyle(
                  color: Colors.blueGrey.shade300,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: secondaryTextColor,
                  size: 25,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: clearSearch,
                        icon: const Icon(
                          Icons.close,
                          color: secondaryTextColor,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Search supports partial course names and course codes.',
            style: TextStyle(
              fontSize: 12,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COURSE CATALOG CARD
  // ============================================================

  Widget buildCatalogCard(dynamic course) {
    final id = courseIdOf(course);
    final name = courseNameOf(course);
    final codes = courseCodesOf(course);
    final isAdding = addingCourseIds.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5FC),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF159AC8),
                  size: 32,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: darkColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Course Content required after adding',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 43,
                child: ElevatedButton(
                  onPressed: id <= 0 || isAdding
                      ? null
                      : () => handleAddCourse(id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    disabledBackgroundColor:
                        primaryColor.withOpacity(0.5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isAdding
                      ? const SizedBox(
                          height: 19,
                          width: 19,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 20),
                            SizedBox(width: 3),
                            Text(
                              'Add',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),
          const Divider(height: 1, color: Color(0xFFEDF0F2)),
          const SizedBox(height: 13),

          if (codes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No course code available',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 13,
                ),
              ),
            )
          else ...[
            ...List.generate(codes.length, (index) {
              final code = codes[index];

              final courseCode = codeOf(code);
              final institute = instituteOf(code);
              final program = programOf(code);

              return Container(
                width: double.infinity,
                margin: EdgeInsets.only(
                  bottom: index == codes.length - 1 ? 0 : 9,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FB),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: const Color(0xFFE5EAEE),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.confirmation_number,
                          size: 17,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            courseCode.isEmpty
                                ? 'Course code not available'
                                : courseCode,
                            style: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (institute.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _metadataRow(
                        'Institute',
                        institute,
                      ),
                    ],
                    if (program.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _metadataRow(
                        'Program',
                        program,
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _metadataRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12,
          color: secondaryTextColor,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: darkColor,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }

  // ============================================================
  // MY COURSE CARD
  // ============================================================

  Widget buildMyCourseCard(dynamic course) {
    final id = courseIdOf(course);
    final name = courseNameOf(course);

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () {
          if (course is Map) {
            openCourseDetails(
              Map<String, dynamic>.from(course),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5F3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: primaryColor,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'View course content',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Upload content',
                onPressed: id > 0
                    ? () => uploadCourseContent(id)
                    : null,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFEAF5F3),
                ),
                icon: const Icon(
                  Icons.cloud_upload_outlined,
                  color: primaryColor,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 85,
              width: 85,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF5F3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: darkColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: secondaryTextColor,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CATALOG BODY
  // ============================================================

  Widget buildCatalogBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    if (searchError.isNotEmpty && catalogCourses.isEmpty) {
      return buildEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Unable to load catalog',
        message: searchError,
        onRetry: () => fetchCatalog(
          search: searchController.text,
        ),
      );
    }

    if (catalogCourses.isEmpty) {
      return buildEmptyState(
        icon: Icons.search_off_rounded,
        title: searchController.text.trim().isEmpty
            ? 'No available courses'
            : 'No matching courses found',
        message: searchController.text.trim().isEmpty
            ? 'All available courses have already been added, or no courses are available.'
            : 'Try another course name or course code.',
        onRetry: clearSearch,
      );
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () => fetchCatalog(
        search: searchController.text,
      ),
      child: ListView.builder(
        keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(21, 18, 21, 25),
        itemCount: catalogCourses.length,
        itemBuilder: (context, index) {
          return buildCatalogCard(catalogCourses[index]);
        },
      ),
    );
  }

  // ============================================================
  // MY COURSES BODY
  // ============================================================

  Widget buildMyCoursesBody() {
    if (isMyCoursesLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    if (myCoursesError.isNotEmpty && myCourses.isEmpty) {
      return buildEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Unable to load courses',
        message: myCoursesError,
        onRetry: () => fetchMyCourses(),
      );
    }

    if (myCourses.isEmpty) {
      return buildEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No enrolled courses',
        message: 'Add a course from the Course Catalog to get started.',
        onRetry: () {
          setState(() {
            isMyCoursesView = false;
          });
        },
      );
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: fetchMyCourses,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(21, 18, 21, 25),
        itemCount: myCourses.length,
        itemBuilder: (context, index) {
          return buildMyCourseCard(myCourses[index]);
        },
      ),
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: pageColor,
      drawer: const StudentDrawer(),
      appBar: buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildPageHeader(),

                if (!isMyCoursesView) ...[
                  buildSearchBar(),
                  const SizedBox(height: 18),
                ] else
                  const SizedBox(height: 5),
              ],
            ),
          ),

          // COURSE COUNT
          Padding(
            padding: const EdgeInsets.fromLTRB(21, 17, 21, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isMyCoursesView
                      ? 'Your Enrollments'
                      : 'Available Courses',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: darkColor,
                    fontSize: 16,
                  ),
                ),
                Text(
                  isMyCoursesView
                      ? '${myCourses.length} courses'
                      : '${catalogCourses.length} found',
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: isMyCoursesView
                ? buildMyCoursesBody()
                : buildCatalogBody(),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
        selectedItemColor: primaryColor,
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        onTap: onTapBottom,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: 'Add Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Classes',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STUDENT COURSE CONTENT SCREEN
//
// GET /api/Student/my-course-content/{courseId}
// ============================================================

class StudentCourseContentScreen extends StatefulWidget {
  final int courseId;
  final String courseName;

  const StudentCourseContentScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<StudentCourseContentScreen> createState() =>
      _StudentCourseContentScreenState();
}

class _StudentCourseContentScreenState
    extends State<StudentCourseContentScreen> {
  bool isLoading = true;
  String errorMessage = '';

  List<dynamic> courseContents = [];

  @override
  void initState() {
    super.initState();
    fetchCourseContent();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ============================================================
  // GET COURSE CONTENT API
  // ============================================================

  Future<void> fetchCourseContent() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await ApiClient.get(
        '/api/Student/my-course-content/${widget.courseId}',
      );

      final data = await ApiClient.decodeJson(response);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          courseContents =
              data is Map && data['data'] is List
                  ? data['data']
                  : [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = data is Map
              ? (data['message']?.toString() ??
                  'Unable to load course content.')
              : 'Unable to load course content.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Error loading content: $e';
      });
    }
  }

  // ============================================================
  // FILE URL
  // ============================================================

  String getFileUrl(String path) {
    String cleanPath = path.trim();

    if (cleanPath.isEmpty) return '';

    if (cleanPath.startsWith('http://') ||
        cleanPath.startsWith('https://')) {
      return cleanPath;
    }

    String base = apiBaseUrl.trim();

    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }

    if (base.toLowerCase().endsWith('/api')) {
      base = base.substring(0, base.length - 4);
    }

    if (!cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }

    return '$base$cleanPath';
  }

  // ============================================================
  // FILE HELPERS
  // ============================================================

  bool isImageFile(String name) {
    final lower = name.toLowerCase();

    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
  }

  IconData fileIcon(String name) {
    final lower = name.toLowerCase();

    if (lower.endsWith('.pdf')) {
      return Icons.picture_as_pdf_rounded;
    }

    if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
      return Icons.description_rounded;
    }

    if (isImageFile(lower)) {
      return Icons.image_rounded;
    }

    return Icons.insert_drive_file_rounded;
  }

  String formatDate(dynamic value) {
    if (value == null) return '';

    try {
      final date = DateTime.parse(value.toString()).toLocal();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  void showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              error ? Colors.red.shade700 : primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // OPEN DOCUMENT
  // ============================================================

  Future<void> openFile(String url) async {
    if (url.isEmpty) {
      showMessage('File URL is not available.', error: true);
      return;
    }

    try {
      final uri = Uri.parse(url);

      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!success && mounted) {
        showMessage('Unable to open file.', error: true);
      }
    } catch (e) {
      if (mounted) {
        showMessage('Unable to open file: $e', error: true);
      }
    }
  }

  // ============================================================
  // IMAGE PREVIEW
  // ============================================================

  Widget buildImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 350,
          minHeight: 150,
        ),
        width: double.infinity,
        color: pageColor,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;

            return const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) {
            return const SizedBox(
              height: 180,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      size: 45,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text('Unable to load image'),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // DOCUMENT CARD
  // ============================================================

  Widget buildDocument(String name, String url) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: pageColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            height: 49,
            width: 49,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              fileIcon(name),
              color: primaryColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: darkColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => openFile(url),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENT CARD
  // ============================================================

  Widget buildContentCard(Map<String, dynamic> content) {
    final title =
        (content['title'] ?? 'Course Content').toString();

    final description =
        (content['description'] ?? '').toString();

    final fileName =
        (content['file_name'] ?? '').toString();

    final filePath =
        (content['file_path'] ?? '').toString();

    final uploadedDate = content['uploaded_date'];

    final fileUrl = getFileUrl(filePath);

    final displayName = fileName.trim().isNotEmpty
        ? fileName
        : (filePath.isNotEmpty
            ? filePath.split('/').last
            : 'Course Content');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: darkColor,
                      ),
                    ),
                    if (uploadedDate != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Uploaded: ${formatDate(uploadedDate)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (description.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: darkColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: secondaryTextColor,
              ),
            ),
          ],

          if (fileUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            if (isImageFile(displayName))
              buildImage(fileUrl)
            else
              buildDocument(displayName, fileUrl),
          ] else ...[
            const SizedBox(height: 12),
            const Text(
              'No file available.',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // COURSE CONTENT SCREEN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: darkColor),
        title: Text(
          widget.courseName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: darkColor,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: fetchCourseContent,
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh,
              color: primaryColor,
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Course Materials',
                  style: TextStyle(
                    color: darkColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'View your uploaded notes and learning materials.',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${courseContents.length} materials',
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: primaryColor,
              onRefresh: fetchCourseContent,
              child: isLoading
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(
                          height: 300,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    )
                  : errorMessage.isNotEmpty
                      ? ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: 350,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(25),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.cloud_off_outlined,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 15),
                                      Text(
                                        errorMessage,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      ElevatedButton(
                                        onPressed: fetchCourseContent,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Try Again'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : courseContents.isEmpty
                          ? ListView(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: 350,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          height: 85,
                                          width: 85,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFEAF5F3),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.folder_open_outlined,
                                            color: primaryColor,
                                            size: 42,
                                          ),
                                        ),
                                        const SizedBox(height: 17),
                                        const Text(
                                          'No Course Content',
                                          style: TextStyle(
                                            color: darkColor,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        const Text(
                                          'No content has been uploaded\nfor this course yet.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: secondaryTextColor,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(20),
                              itemCount: courseContents.length,
                              itemBuilder: (context, index) {
                                final item = courseContents[index];

                                if (item is! Map) {
                                  return const SizedBox.shrink();
                                }

                                return buildContentCard(
                                  Map<String, dynamic>.from(item),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}


























// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:house_of_tutor/StudentHome.dart';
// import 'package:house_of_tutor/StudentAllClasses.dart';
// import 'package:house_of_tutor/StudentCourses.dart';
// import 'package:house_of_tutor/StudentDrawer.dart';
// import 'package:house_of_tutor/services/api_client.dart';
// import 'package:house_of_tutor/services/api_config.dart';
// import 'package:url_launcher/url_launcher.dart';

// const Color primaryColor = Color(0xFF1E8E7E);
// const Color pageColor = Color(0xFFF4F7F8);
// const Color darkColor = Color(0xFF243238);


// class StudentAddCourses extends StatefulWidget {
//   const StudentAddCourses({super.key});

//   @override
//   State<StudentAddCourses> createState() => _StudentAddCoursesState();
// }

// class _StudentAddCoursesState extends State<StudentAddCourses> {
//   final GlobalKey<ScaffoldState> scaffoldKey =
//       GlobalKey<ScaffoldState>();

//   bool isLoading = true;
//   bool isCatalogLoading = false;

//   List<dynamic> myCourses = [];

//   String errorMessage = '';

//   int selectedIndex = 1;

//   static const String logoPath = 'assets/images/logo.png';

//   @override
//   void initState() {
//     super.initState();
//     fetchMyCourses();
//   }

//   // ============================================================
//   // HELPERS
//   // ============================================================

//   int courseIdOf(dynamic course) {
//     if (course is! Map) return 0;

//     return int.tryParse(
//           (course['course_id'] ??
//                   course['courseId'] ??
//                   course['CourseId'] ??
//                   '0')
//               .toString(),
//         ) ??
//         0;
//   }

//   String courseNameOf(dynamic course) {
//     if (course is! Map) return 'Course';

//     return (course['course_name'] ??
//             course['course_title'] ??
//             course['CourseTitle'] ??
//             'Course')
//         .toString();
//   }

//   List<dynamic> extractList(dynamic data) {
//     if (data is List) return data;

//     if (data is Map) {
//       if (data['data'] is List) {
//         return data['data'];
//       }

//       if (data['courses'] is List) {
//         return data['courses'];
//       }
//     }

//     return [];
//   }

//   String responseMessage(dynamic data, String fallback) {
//     if (data is Map && data['message'] != null) {
//       return data['message'].toString();
//     }

//     return fallback;
//   }

//   void showMessage(String message, {bool error = false}) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(
//         SnackBar(
//           content: Text(message),
//           backgroundColor: error ? Colors.red.shade700 : primaryColor,
//           behavior: SnackBarBehavior.floating,
//           duration: const Duration(seconds: 3),
//         ),
//       );
//   }

//   // ============================================================
//   // BOTTOM NAVIGATION
//   // ============================================================

//   void onTapBottom(int index) {
//     if (index == selectedIndex) return;

//     Widget? screen;

//     switch (index) {
//       case 0:
//         screen = const StudentHome();
//         break;
//       case 2:
//         screen = const StudentCourses();
//         break;
//       case 3:
//         screen = const StudentAllClasses();
//         break;
//     }

//     if (screen == null) return;

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => screen!),
//     );
//   }

//   // ============================================================
//   // 1. GET MY ENROLLED COURSES
//   // BACKEND:
//   // GET /api/Student/my-courses-for-student-add-courses
//   // ============================================================

//   Future<void> fetchMyCourses({bool silent = false}) async {
//     if (!mounted) return;

//     if (!silent) {
//       setState(() {
//         isLoading = true;
//         errorMessage = '';
//       });
//     }

//     try {
//       final response = await ApiClient.get(
//         '/api/Student/my-courses-for-student-add-courses',
//       );

//       final data = await ApiClient.decodeJson(response);

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         final courses = extractList(data);

//         setState(() {
//           myCourses = courses;
//           isLoading = false;
//           errorMessage = '';
//         });
//       } else {
//         setState(() {
//           isLoading = false;
//           errorMessage = responseMessage(
//             data,
//             'Unable to load your courses.',
//           );
//         });
//       }
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isLoading = false;
//         errorMessage = 'Unable to load courses: $e';
//       });
//     }
//   }

//   // ============================================================
//   // 2. GET ALL AVAILABLE COURSES
//   // BACKEND:
//   // GET /api/Student/all-courses?search=...
//   // ============================================================

//   Future<List<dynamic>> fetchAvailableCourses({
//     String search = '',
//   }) async {
//     String path = '/api/Student/all-courses';

//     if (search.trim().isNotEmpty) {
//       path += '?search=${Uri.encodeQueryComponent(search.trim())}';
//     }

//     final response = await ApiClient.get(path);

//     final data = await ApiClient.decodeJson(response);

//     if (response.statusCode == 200) {
//       return extractList(data);
//     }

//     throw Exception(
//       responseMessage(data, 'Unable to fetch available courses.'),
//     );
//   }

//   // ============================================================
//   // COURSE CODES
//   // ============================================================

//   List<dynamic> courseCodesOf(dynamic course) {
//     if (course is! Map) return [];

//     final codes = course['course_codes'] ??
//         course['courseCodes'] ??
//         course['CourseCodes'];

//     return codes is List ? codes : [];
//   }

//   String codeValue(dynamic code) {
//     if (code is! Map) return '';

//     return (code['course_code'] ??
//             code['courseCode'] ??
//             code['CourseCode1'] ??
//             '')
//         .toString();
//   }

//   // ============================================================
//   // 3. ADD STUDENT COURSES
//   // BACKEND:
//   // POST /api/Student/add-courses
//   // BODY: { "courseIds": [1,2,3] }
//   // ============================================================

//   Future<String?> addStudentCourses(
//     List<int> courseIds, {
//     bool showResult = true,
//   }) async {
//     if (courseIds.isEmpty) return 'Please select a course.';

//     try {
//       final response = await ApiClient.post(
//         '/api/Student/add-courses',
//         {
//           'courseIds': courseIds,
//         },
//       );

//       final data = await ApiClient.decodeJson(response);

//       if (response.statusCode == 200) {
//         await fetchMyCourses(silent: true);

//         if (mounted && showResult) {
//           showMessage(
//             responseMessage(data, 'Courses added successfully.'),
//           );
//         }

//         return null;
//       }

//       final message = responseMessage(
//         data,
//         'Unable to add courses.',
//       );

//       if (mounted && showResult) {
//         showMessage(message, error: true);
//       }

//       return message;
//     } catch (e) {
//       final message = 'Error adding courses: $e';

//       if (mounted && showResult) {
//         showMessage(message, error: true);
//       }

//       return message;
//     }
//   }

//   // ============================================================
//   // 4. COURSE CATALOG
//   // ============================================================

//   Future<void> showCourseCatalog() async {
//     if (isCatalogLoading) return;

//     setState(() {
//       isCatalogLoading = true;
//     });

//     try {
//       final courses = await fetchAvailableCourses();

//       if (!mounted) return;

//       setState(() {
//         isCatalogLoading = false;
//       });

//       showModalBottomSheet(
//         context: context,
//         isScrollControlled: true,
//         backgroundColor: Colors.transparent,
//         builder: (_) => CourseCatalogSheet(
//           initialCourses: courses,
//           fetchCourses: fetchAvailableCourses,
//           addCourses: addStudentCourses,
//           primaryColor: primaryColor,
//         ),
//       ).then((_) {
//         if (mounted) fetchMyCourses(silent: true);
//       });
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isCatalogLoading = false;
//       });

//       showMessage(e.toString(), error: true);
//     }
//   }

//   // ============================================================
//   // 5. UPLOAD COURSE CONTENT
//   // BACKEND:
//   // POST /api/Student/upload-course-content
//   //
//   // multipart:
//   // course_id
//   // title
//   // description
//   // file
//   // ============================================================

//   Future<void> uploadCourseContent(int courseId) async {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: [
//         'pdf',
//         'doc',
//         'docx',
//         'jpg',
//         'jpeg',
//         'png',
//       ],
//     );

//     if (result == null) return;

//     final selected = result.files.single;

//     if (selected.path == null) {
//       showMessage('Unable to access selected file.', error: true);
//       return;
//     }

//     final file = File(selected.path!);

//     if (!await file.exists()) {
//       showMessage('Selected file does not exist.', error: true);
//       return;
//     }

//     final fileSize = await file.length();

//     if (fileSize == 0) {
//       showMessage('Selected file is empty.', error: true);
//       return;
//     }

//     if (fileSize > 100 * 1024 * 1024) {
//       showMessage('Maximum file size is 100 MB.', error: true);
//       return;
//     }

//     final titleController = TextEditingController();
//     final descriptionController = TextEditingController();

//     bool uploading = false;

//     final shouldUpload = await showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(18),
//               ),
//               title: const Text(
//                 'Upload Course Content',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               content: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: pageColor,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Row(
//                         children: [
//                           const Icon(
//                             Icons.insert_drive_file,
//                             color: primaryColor,
//                             size: 28,
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: Text(
//                               selected.name,
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(fontSize: 13),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 18),
//                     TextField(
//                       controller: titleController,
//                       decoration: InputDecoration(
//                         labelText: 'Content Title *',
//                         hintText: 'Example: Week 1 Notes',
//                         prefixIcon: const Icon(Icons.title),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 14),
//                     TextField(
//                       controller: descriptionController,
//                       maxLines: 3,
//                       decoration: InputDecoration(
//                         labelText: 'Description',
//                         hintText: 'Enter content details',
//                         prefixIcon: const Icon(Icons.description_outlined),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: uploading
//                       ? null
//                       : () => Navigator.pop(dialogContext, false),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: primaryColor,
//                     foregroundColor: Colors.white,
//                   ),
//                   onPressed: uploading
//                       ? null
//                       : () {
//                           if (titleController.text.trim().isEmpty) {
//                             showMessage(
//                               'Please enter content title.',
//                               error: true,
//                             );
//                             return;
//                           }

//                           Navigator.pop(dialogContext, true);
//                         },
//                   child: const Text('Continue'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );

//     if (shouldUpload != true || !mounted) {
//       titleController.dispose();
//       descriptionController.dispose();
//       return;
//     }

//     // Upload progress dialog.
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => const Center(
//         child: Card(
//           child: Padding(
//             padding: EdgeInsets.all(25),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(color: primaryColor),
//                 SizedBox(height: 15),
//                 Text('Uploading course content...'),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );

//     try {
//       final response = await ApiClient.uploadFile(
//         '/api/Student/upload-course-content',
//         fields: {
//           'course_id': courseId.toString(),
//           'title': titleController.text.trim(),
//           'description': descriptionController.text.trim(),
//         },
//         fileFieldName: 'file',
//         file: file,
//       );

//       final data = await ApiClient.decodeJson(response);

//       if (!mounted) return;

//       Navigator.of(context, rootNavigator: true).pop();

//       if (response.statusCode == 200) {
//         showMessage(
//           responseMessage(
//             data,
//             'Course content uploaded successfully.',
//           ),
//         );
//       } else {
//         showMessage(
//           responseMessage(data, 'Course content upload failed.'),
//           error: true,
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;

//       Navigator.of(context, rootNavigator: true).pop();

//       showMessage('Upload failed: $e', error: true);
//     } finally {
//       titleController.dispose();
//       descriptionController.dispose();
//     }
//   }

//   // ============================================================
//   // 6. OPEN COURSE DETAILS
//   // ============================================================

//   void openCourseDetails(Map<String, dynamic> course) {
//     final id = courseIdOf(course);

//     if (id <= 0) {
//       showMessage('Invalid course ID.', error: true);
//       return;
//     }

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => StudentCourseContentScreen(
//           courseId: id,
//           courseName: courseNameOf(course),
//           primaryColor: primaryColor,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // LOGO
//   // ============================================================

//   Widget buildLogo() {
//     return Image.asset(
//       'assets/images/logo.png',
//       height: 34,
//       width: 34,
//       errorBuilder: (_, __, ___) => const Icon(
//         Icons.school,
//         color: primaryColor,
//         size: 30,
//       ),
//     );
//   }

//   // ============================================================
//   // COURSE CARD
//   // ============================================================

//   Widget buildCourseCard(Map<String, dynamic> course) {
//     final id = courseIdOf(course);
//     final name = courseNameOf(course);

//     return Container(
//       margin: const EdgeInsets.only(bottom: 14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(17),
//         border: Border.all(color: const Color(0xFFE8EEEE)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.035),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(17),
//         onTap: () => openCourseDetails(course),
//         child: Padding(
//           padding: const EdgeInsets.all(15),
//           child: Row(
//             children: [
//               Container(
//                 width: 53,
//                 height: 53,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFE7F4F1),
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 child: const Icon(
//                   Icons.menu_book_rounded,
//                   color: primaryColor,
//                   size: 27,
//                 ),
//               ),
//               const SizedBox(width: 13),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       name,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w700,
//                         color: darkColor,
//                       ),
//                     ),
//                     const SizedBox(height: 7),
//                     Row(
//                       children: [
//                         const Icon(
//                           Icons.check_circle,
//                           color: primaryColor,
//                           size: 15,
//                         ),
//                         const SizedBox(width: 5),
//                         Text(
//                           'Enrolled',
//                           style: TextStyle(
//                             color: Colors.grey.shade600,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               IconButton(
//                 tooltip: 'Upload Course Content',
//                 onPressed: id > 0 ? () => uploadCourseContent(id) : null,
//                 style: IconButton.styleFrom(
//                   backgroundColor: const Color(0xFFE7F4F1),
//                 ),
//                 icon: const Icon(
//                   Icons.cloud_upload_outlined,
//                   color: primaryColor,
//                 ),
//               ),
//               const Icon(
//                 Icons.chevron_right,
//                 color: Colors.grey,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // MAIN BUILD
//   // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: scaffoldKey,
//       backgroundColor: pageColor,
//       drawer: const StudentDrawer(),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         leading: IconButton(
//           onPressed: () => scaffoldKey.currentState?.openDrawer(),
//           icon: const Icon(Icons.menu, color: darkColor),
//         ),
//         title: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             buildLogo(),
//             const SizedBox(width: 9),
//             const Text(
//               'House of Tutor',
//               style: TextStyle(
//                 color: darkColor,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 17,
//               ),
//             ),
//           ],
//         ),
//         centerTitle: true,
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // HEADER
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.vertical(
//                 bottom: Radius.circular(23),
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'My Courses',
//                   style: TextStyle(
//                     fontSize: 25,
//                     fontWeight: FontWeight.bold,
//                     color: darkColor,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   'Manage your enrolled courses and learning materials.',
//                   style: TextStyle(
//                     color: Colors.grey.shade600,
//                     fontSize: 13,
//                   ),
//                 ),
//                 const SizedBox(height: 18),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: _statCard(
//                         Icons.school_outlined,
//                         '${myCourses.length}',
//                         'Enrolled Courses',
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: _statCard(
//                         Icons.cloud_upload_outlined,
//                         '100 MB',
//                         'Upload Limit',
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // SECTION HEADER
//           Padding(
//             padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Your Enrollments',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 17,
//                     color: darkColor,
//                   ),
//                 ),
//                 TextButton.icon(
//                   onPressed: fetchMyCourses,
//                   icon: const Icon(Icons.refresh, size: 17),
//                   label: const Text('Refresh'),
//                   style: TextButton.styleFrom(
//                     foregroundColor: primaryColor,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // COURSE LIST
//           Expanded(
//             child: isLoading
//                 ? const Center(
//                     child: CircularProgressIndicator(
//                       color: primaryColor,
//                     ),
//                   )
//                 : errorMessage.isNotEmpty && myCourses.isEmpty
//                     ? _emptyState(
//                         icon: Icons.cloud_off_outlined,
//                         title: 'Unable to load courses',
//                         message: errorMessage,
//                         buttonText: 'Try Again',
//                         onPressed: fetchMyCourses,
//                       )
//                     : myCourses.isEmpty
//                         ? _emptyState(
//                             icon: Icons.menu_book_outlined,
//                             title: 'No courses enrolled',
//                             message:
//                                 'Start building your study plan by adding your first course.',
//                             buttonText: 'Explore Courses',
//                             onPressed: showCourseCatalog,
//                           )
//                         : RefreshIndicator(
//                             color: primaryColor,
//                             onRefresh: fetchMyCourses,
//                             child: ListView.builder(
//                               padding: const EdgeInsets.fromLTRB(
//                                 20, 0, 20, 100,
//                               ),
//                               physics:
//                                   const AlwaysScrollableScrollPhysics(),
//                               itemCount: myCourses.length,
//                               itemBuilder: (context, index) {
//                                 final item = myCourses[index];

//                                 if (item is! Map) {
//                                   return const SizedBox.shrink();
//                                 }

//                                 return buildCourseCard(
//                                   Map<String, dynamic>.from(item),
//                                 );
//                               },
//                             ),
//                           ),
//           ),
//         ],
//       ),

//       // ADD COURSE BUTTON
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: isCatalogLoading ? null : showCourseCatalog,
//         backgroundColor: primaryColor,
//         foregroundColor: Colors.white,
//         elevation: 3,
//         icon: isCatalogLoading
//             ? const SizedBox(
//                 width: 19,
//                 height: 19,
//                 child: CircularProgressIndicator(
//                   color: Colors.white,
//                   strokeWidth: 2,
//                 ),
//               )
//             : const Icon(Icons.add),
//         label: const Text(
//           'Add Course',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//       ),

//       // BOTTOM NAVIGATION
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: selectedIndex,
//         type: BottomNavigationBarType.fixed,
//         selectedItemColor: primaryColor,
//         unselectedItemColor: Colors.grey,
//         backgroundColor: Colors.white,
//         elevation: 10,
//         onTap: onTapBottom,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.calendar_month_outlined),
//             label: 'Schedule',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.add_box_outlined),
//             label: 'Add Courses',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.request_page_outlined),
//             label: 'Request',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.class_outlined),
//             label: 'Classes',
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // STAT CARD
//   // ============================================================

//   Widget _statCard(IconData icon, String value, String label) {
//     return Container(
//       padding: const EdgeInsets.all(13),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF2F8F7),
//         borderRadius: BorderRadius.circular(13),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: primaryColor, size: 23),
//           const SizedBox(width: 9),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                     color: darkColor,
//                   ),
//                 ),
//                 Text(
//                   label,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     fontSize: 10,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // EMPTY STATE
//   // ============================================================

//   Widget _emptyState({
//     required IconData icon,
//     required String title,
//     required String message,
//     required String buttonText,
//     required VoidCallback onPressed,
//   }) {
//     return Center(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(28),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               height: 90,
//               width: 90,
//               decoration: const BoxDecoration(
//                 color: Color(0xFFE7F4F1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(icon, size: 43, color: primaryColor),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 19,
//                 fontWeight: FontWeight.bold,
//                 color: darkColor,
//               ),
//             ),
//             const SizedBox(height: 9),
//             Text(
//               message,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//                 height: 1.5,
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: onPressed,
//               icon: const Icon(Icons.refresh),
//               label: Text(buttonText),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: primaryColor,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 12,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ============================================================
// // COURSE CATALOG BOTTOM SHEET
// // ============================================================

// class CourseCatalogSheet extends StatefulWidget {
//   final List<dynamic> initialCourses;

//   final Future<List<dynamic>> Function({String search}) fetchCourses;

//   final Future<String?> Function(
//     List<int> ids, {
//     bool showResult,
//   }) addCourses;

//   final Color primaryColor;

//   const CourseCatalogSheet({
//     super.key,
//     required this.initialCourses,
//     required this.fetchCourses,
//     required this.addCourses,
//     required this.primaryColor,
//   });

//   @override
//   State<CourseCatalogSheet> createState() =>
//       _CourseCatalogSheetState();
// }

// class _CourseCatalogSheetState extends State<CourseCatalogSheet> {
//   final TextEditingController searchController =
//       TextEditingController();

//   List<dynamic> courses = [];

//   bool isLoading = false;

//   String errorMessage = '';

//   final Set<int> addingIds = {};

//   @override
//   void initState() {
//     super.initState();
//     courses = widget.initialCourses;
//   }

//   @override
//   void dispose() {
//     searchController.dispose();
//     super.dispose();
//   }

//   int courseId(dynamic course) {
//     if (course is! Map) return 0;

//     return int.tryParse(
//           (course['course_id'] ?? course['courseId'] ?? '0').toString(),
//         ) ??
//         0;
//   }

//   String courseName(dynamic course) {
//     if (course is! Map) return 'Course';

//     return (course['course_name'] ?? course['course_title'] ?? 'Course')
//         .toString();
//   }

//   List<dynamic> courseCodes(dynamic course) {
//     if (course is! Map) return [];

//     final value = course['course_codes'] ?? course['courseCodes'];

//     return value is List ? value : [];
//   }

//   String codeText(dynamic code) {
//     if (code is! Map) return '';

//     return (code['course_code'] ?? code['courseCode'] ?? '').toString();
//   }

//   String instituteText(dynamic code) {
//     if (code is! Map) return '';

//     return (code['institute'] ?? '').toString();
//   }

//   String programText(dynamic code) {
//     if (code is! Map) return '';

//     return (code['program'] ?? '').toString();
//   }

//   Future<void> searchCourses(String value) async {
//     setState(() {
//       isLoading = true;
//       errorMessage = '';
//     });

//     try {
//       final result = await widget.fetchCourses(search: value);

//       if (!mounted) return;

//       setState(() {
//         courses = result;
//         isLoading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isLoading = false;
//         errorMessage = e.toString();
//       });
//     }
//   }

//   Future<void> addCourse(int id) async {
//     if (id <= 0 || addingIds.contains(id)) return;

//     setState(() {
//       addingIds.add(id);
//       errorMessage = '';
//     });

//     final error = await widget.addCourses(
//       [id],
//       showResult: false,
//     );

//     if (!mounted) return;

//     setState(() {
//       addingIds.remove(id);

//       if (error != null) {
//         errorMessage = error;
//       }
//     });

//     if (error == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Course added successfully.'),
//           backgroundColor: primaryColor,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );

//       // Remove from catalog because backend excludes enrolled courses.
//       setState(() {
//         courses.removeWhere((c) => courseId(c) == id);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.88,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(
//           top: Radius.circular(25),
//         ),
//       ),
//       child: SafeArea(
//         top: false,
//         child: Column(
//           children: [
//             const SizedBox(height: 12),
//             Container(
//               height: 5,
//               width: 45,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(20, 18, 12, 15),
//               child: Row(
//                 children: [
//                   Container(
//                     height: 45,
//                     width: 45,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFE7F4F1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: const Icon(
//                       Icons.library_books_outlined,
//                       color: primaryColor,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   const Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Course Catalog',
//                           style: TextStyle(
//                             fontSize: 19,
//                             fontWeight: FontWeight.bold,
//                             color: darkColor,
//                           ),
//                         ),
//                         Text(
//                           'Find courses by name or course code',
//                           style: TextStyle(
//                             fontSize: 11,
//                             color: Colors.grey,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: () => Navigator.pop(context),
//                     icon: const Icon(Icons.close),
//                   ),
//                 ],
//               ),
//             ),

//             // SEARCH
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: TextField(
//                 controller: searchController,
//                 onChanged: searchCourses,
//                 decoration: InputDecoration(
//                   hintText: 'Search course name or code...',
//                   prefixIcon: const Icon(
//                     Icons.search,
//                     color: primaryColor,
//                   ),
//                   suffixIcon: IconButton(
//                     onPressed: () {
//                       searchController.clear();
//                       searchCourses('');
//                     },
//                     icon: const Icon(Icons.close),
//                   ),
//                   filled: true,
//                   fillColor: pageColor,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(14),
//                     borderSide: BorderSide.none,
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(
//                     vertical: 14,
//                   ),
//                 ),
//               ),
//             ),

//             if (errorMessage.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Text(
//                   errorMessage,
//                   style: const TextStyle(color: Colors.red),
//                 ),
//               ),

//             Padding(
//               padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Available Courses',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: darkColor,
//                     ),
//                   ),
//                   Text(
//                     '${courses.length} found',
//                     style: const TextStyle(
//                       color: primaryColor,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             Expanded(
//               child: isLoading
//                   ? const Center(
//                       child: CircularProgressIndicator(
//                         color: primaryColor,
//                       ),
//                     )
//                   : courses.isEmpty
//                       ? Center(
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(
//                                 Icons.search_off,
//                                 size: 55,
//                                 color: Colors.grey.shade300,
//                               ),
//                               const SizedBox(height: 10),
//                               const Text(
//                                 'No available courses found.',
//                                 style: TextStyle(color: Colors.grey),
//                               ),
//                             ],
//                           ),
//                         )
//                       : ListView.builder(
//                           padding: const EdgeInsets.fromLTRB(
//                             20, 0, 20, 25,
//                           ),
//                           itemCount: courses.length,
//                           itemBuilder: (context, index) {
//                             final course = courses[index];

//                             final id = courseId(course);
//                             final name = courseName(course);
//                             final codes = courseCodes(course);

//                             final isAdding = addingIds.contains(id);

//                             return Container(
//                               margin: const EdgeInsets.only(bottom: 13),
//                               padding: const EdgeInsets.all(14),
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(15),
//                                 border: Border.all(
//                                   color: const Color(0xFFE6EEEE),
//                                 ),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment:
//                                     CrossAxisAlignment.start,
//                                 children: [
//                                   Row(
//                                     children: [
//                                       Container(
//                                         width: 42,
//                                         height: 42,
//                                         decoration: BoxDecoration(
//                                           color: const Color(0xFFE7F4F1),
//                                           borderRadius:
//                                               BorderRadius.circular(11),
//                                         ),
//                                         child: const Icon(
//                                           Icons.menu_book,
//                                           color: primaryColor,
//                                         ),
//                                       ),
//                                       const SizedBox(width: 11),
//                                       Expanded(
//                                         child: Text(
//                                           name,
//                                           style: const TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 14,
//                                             color: darkColor,
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(width: 5),
//                                       isAdding
//                                           ? const SizedBox(
//                                               height: 24,
//                                               width: 24,
//                                               child:
//                                                   CircularProgressIndicator(
//                                                 strokeWidth: 2,
//                                                 color: primaryColor,
//                                               ),
//                                             )
//                                           : ElevatedButton(
//                                               onPressed: id > 0
//                                                   ? () => addCourse(id)
//                                                   : null,
//                                               style: ElevatedButton.styleFrom(
//                                                 backgroundColor: primaryColor,
//                                                 foregroundColor: Colors.white,
//                                                 elevation: 0,
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                   horizontal: 13,
//                                                   vertical: 9,
//                                                 ),
//                                               ),
//                                               child: const Text('+ Add'),
//                                             ),
//                                     ],
//                                   ),

//                                   if (codes.isNotEmpty) ...[
//                                     const SizedBox(height: 13),
//                                     const Text(
//                                       'Course Codes',
//                                       style: TextStyle(
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.bold,
//                                         color: darkColor,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 8),

//                                     ...codes.map((code) {
//                                       final codeName = codeText(code);
//                                       final institute =
//                                           instituteText(code);
//                                       final program = programText(code);

//                                       return Container(
//                                         width: double.infinity,
//                                         margin:
//                                             const EdgeInsets.only(bottom: 7),
//                                         padding: const EdgeInsets.all(10),
//                                         decoration: BoxDecoration(
//                                           color: pageColor,
//                                           borderRadius:
//                                               BorderRadius.circular(9),
//                                         ),
//                                         child: Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             Row(
//                                               children: [
//                                                 const Icon(
//                                                   Icons.tag,
//                                                   size: 15,
//                                                   color: primaryColor,
//                                                 ),
//                                                 const SizedBox(width: 5),
//                                                 Expanded(
//                                                   child: Text(
//                                                     codeName.isEmpty
//                                                         ? 'Course code'
//                                                         : codeName,
//                                                     style: const TextStyle(
//                                                       fontWeight:
//                                                           FontWeight.w700,
//                                                       fontSize: 12,
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                             if (institute.isNotEmpty)
//                                               Padding(
//                                                 padding:
//                                                     const EdgeInsets.only(
//                                                   top: 5,
//                                                 ),
//                                                 child: Text(
//                                                   'Institute: $institute',
//                                                   style: const TextStyle(
//                                                     fontSize: 11,
//                                                     color: Colors.black54,
//                                                   ),
//                                                 ),
//                                               ),
//                                             if (program.isNotEmpty)
//                                               Padding(
//                                                 padding:
//                                                     const EdgeInsets.only(
//                                                   top: 3,
//                                                 ),
//                                                 child: Text(
//                                                   'Program: $program',
//                                                   style: const TextStyle(
//                                                     fontSize: 11,
//                                                     color: Colors.black54,
//                                                   ),
//                                                 ),
//                                               ),
//                                           ],
//                                         ),
//                                       );
//                                     }),
//                                   ],
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ============================================================
// // STUDENT COURSE CONTENT SCREEN
// // GET /api/Student/my-course-content/{courseId}
// // ============================================================

// class StudentCourseContentScreen extends StatefulWidget {
//   final int courseId;
//   final String courseName;
//   final Color primaryColor;

//   const StudentCourseContentScreen({
//     super.key,
//     required this.courseId,
//     required this.courseName,
//     required this.primaryColor,
//   });

//   @override
//   State<StudentCourseContentScreen> createState() =>
//       _StudentCourseContentScreenState();
// }

// class _StudentCourseContentScreenState
//     extends State<StudentCourseContentScreen> {
//   bool isLoading = true;

//   String errorMessage = '';

//   List<dynamic> courseContents = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchCourseContent();
//   }

//   // ============================================================
//   // HELPERS
//   // ============================================================

//   List<dynamic> extractList(dynamic data) {
//     if (data is List) return data;

//     if (data is Map && data['data'] is List) {
//       return data['data'];
//     }

//     return [];
//   }

//   String formatDate(dynamic value) {
//     if (value == null) return '';

//     try {
//       final date = DateTime.parse(value.toString()).toLocal();

//       return '${date.day.toString().padLeft(2, '0')}/'
//           '${date.month.toString().padLeft(2, '0')}/'
//           '${date.year}';
//     } catch (_) {
//       return value.toString();
//     }
//   }

//   String getFileUrl(String path) {
//     String cleanPath = path.trim();

//     if (cleanPath.isEmpty) return '';

//     if (cleanPath.startsWith('http://') ||
//         cleanPath.startsWith('https://')) {
//       return cleanPath;
//     }

//     String base = apiBaseUrl.trim();

//     while (base.endsWith('/')) {
//       base = base.substring(0, base.length - 1);
//     }

//     if (base.toLowerCase().endsWith('/api')) {
//       base = base.substring(0, base.length - 4);
//     }

//     if (!cleanPath.startsWith('/')) {
//       cleanPath = '/$cleanPath';
//     }

//     return '$base$cleanPath';
//   }

//   bool isImageFile(String name) {
//     final value = name.toLowerCase();

//     return value.endsWith('.jpg') ||
//         value.endsWith('.jpeg') ||
//         value.endsWith('.png');
//   }

//   IconData getFileIcon(String name) {
//     final value = name.toLowerCase();

//     if (value.endsWith('.pdf')) {
//       return Icons.picture_as_pdf;
//     }

//     if (value.endsWith('.doc') || value.endsWith('.docx')) {
//       return Icons.description;
//     }

//     if (isImageFile(value)) {
//       return Icons.image;
//     }

//     return Icons.insert_drive_file;
//   }

//   // ============================================================
//   // GET COURSE CONTENT
//   // ============================================================

//   Future<void> fetchCourseContent() async {
//     if (!mounted) return;

//     setState(() {
//       isLoading = true;
//       errorMessage = '';
//     });

//     try {
//       final response = await ApiClient.get(
//         '/api/Student/my-course-content/${widget.courseId}',
//       );

//       final data = await ApiClient.decodeJson(response);

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         setState(() {
//           courseContents = extractList(data);
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           isLoading = false;
//           errorMessage = data is Map
//               ? (data['message']?.toString() ??
//                   'Unable to load course content.')
//               : 'Unable to load course content.';
//         });
//       }
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isLoading = false;
//         errorMessage = 'Error loading course content: $e';
//       });
//     }
//   }

//   // ============================================================
//   // OPEN PDF / DOC / DOCX
//   // ============================================================

//   Future<void> openFile(String url) async {
//     if (url.isEmpty) {
//       showMessage('File URL is not available.', error: true);
//       return;
//     }

//     try {
//       final uri = Uri.parse(url);

//       final success = await launchUrl(
//         uri,
//         mode: LaunchMode.externalApplication,
//       );

//       if (!success && mounted) {
//         showMessage('Unable to open file.', error: true);
//       }
//     } catch (e) {
//       if (mounted) {
//         showMessage('Unable to open file: $e', error: true);
//       }
//     }
//   }

//   // ============================================================
//   // MESSAGE
//   // ============================================================

//   void showMessage(String message, {bool error = false}) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(
//         SnackBar(
//           content: Text(message),
//           backgroundColor: error ? Colors.red : primaryColor,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//   }

//   // ============================================================
//   // IMAGE CONTENT
//   // ============================================================

//   Widget buildImage(String url) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(13),
//       child: Container(
//         width: double.infinity,
//         constraints: const BoxConstraints(
//           maxHeight: 350,
//           minHeight: 150,
//         ),
//         color: pageColor,
//         child: Image.network(
//           url,
//           fit: BoxFit.contain,
//           loadingBuilder: (context, child, progress) {
//             if (progress == null) return child;

//             return const SizedBox(
//               height: 200,
//               child: Center(
//                 child: CircularProgressIndicator(
//                   color: primaryColor,
//                 ),
//               ),
//             );
//           },
//           errorBuilder: (_, __, ___) => const SizedBox(
//             height: 180,
//             child: Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     Icons.broken_image_outlined,
//                     size: 45,
//                     color: Colors.grey,
//                   ),
//                   SizedBox(height: 8),
//                   Text('Unable to load image'),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // DOCUMENT CONTENT
//   // ============================================================

//   Widget buildDocument(String name, String url) {
//     return Container(
//       padding: const EdgeInsets.all(17),
//       decoration: BoxDecoration(
//         color: pageColor,
//         borderRadius: BorderRadius.circular(13),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Row(
//         children: [
//           Container(
//             height: 53,
//             width: 53,
//             decoration: BoxDecoration(
//               color: const Color(0xFFE7F4F1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(
//               getFileIcon(name),
//               color: primaryColor,
//               size: 28,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               name,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w600,
//                 fontSize: 13,
//               ),
//             ),
//           ),
//           IconButton(
//             tooltip: 'Open file',
//             onPressed: () => openFile(url),
//             icon: const Icon(
//               Icons.open_in_new,
//               color: primaryColor,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // CONTENT CARD
//   // ============================================================

//   Widget buildContentCard(Map<String, dynamic> content) {
//     final title = (content['title'] ?? 'Course Content').toString();

//     final description =
//         (content['description'] ?? '').toString();

//     final fileName = (content['file_name'] ?? '').toString();

//     final filePath = (content['file_path'] ?? '').toString();

//     final uploadedDate = content['uploaded_date'];

//     final fileUrl = getFileUrl(filePath);

//     final displayName = fileName.trim().isNotEmpty
//         ? fileName
//         : (filePath.isNotEmpty
//             ? filePath.split('/').last
//             : 'Course Content');

//     return Container(
//       margin: const EdgeInsets.only(bottom: 17),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(17),
//         border: Border.all(color: const Color(0xFFE9EEEE)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.035),
//             blurRadius: 12,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 46,
//                 height: 46,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFE7F4F1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Icon(
//                   Icons.menu_book,
//                   color: primaryColor,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: darkColor,
//                       ),
//                     ),
//                     if (uploadedDate != null) ...[
//                       const SizedBox(height: 5),
//                       Text(
//                         'Uploaded: ${formatDate(uploadedDate)}',
//                         style: TextStyle(
//                           fontSize: 11,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           if (description.trim().isNotEmpty) ...[
//             const SizedBox(height: 16),
//             const Text(
//               'Description',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 13,
//               ),
//             ),
//             const SizedBox(height: 6),
//             Text(
//               description,
//               style: const TextStyle(
//                 fontSize: 13,
//                 height: 1.5,
//                 color: Colors.black54,
//               ),
//             ),
//           ],

//           if (fileUrl.isNotEmpty) ...[
//             const SizedBox(height: 17),
//             if (isImageFile(displayName))
//               buildImage(fileUrl)
//             else
//               buildDocument(displayName, fileUrl),
//           ] else ...[
//             const SizedBox(height: 12),
//             const Text(
//               'No file available.',
//               style: TextStyle(color: Colors.grey, fontSize: 12),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // BUILD
//   // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: pageColor,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         iconTheme: const IconThemeData(color: darkColor),
//         title: Text(
//           widget.courseName,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//           style: const TextStyle(
//             color: darkColor,
//             fontWeight: FontWeight.bold,
//             fontSize: 17,
//           ),
//         ),
//         actions: [
//           IconButton(
//             onPressed: fetchCourseContent,
//             tooltip: 'Refresh',
//             icon: const Icon(Icons.refresh),
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         color: primaryColor,
//         onRefresh: fetchCourseContent,
//         child: isLoading
//             ? ListView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 children: const [
//                   SizedBox(
//                     height: 300,
//                     child: Center(
//                       child: CircularProgressIndicator(
//                         color: primaryColor,
//                       ),
//                     ),
//                   ),
//                 ],
//               )
//             : errorMessage.isNotEmpty
//                 ? ListView(
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     children: [
//                       SizedBox(
//                         height: 350,
//                         child: Center(
//                           child: Padding(
//                             padding: const EdgeInsets.all(25),
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 const Icon(
//                                   Icons.cloud_off_outlined,
//                                   size: 50,
//                                   color: Colors.grey,
//                                 ),
//                                 const SizedBox(height: 15),
//                                 Text(
//                                   errorMessage,
//                                   textAlign: TextAlign.center,
//                                   style: const TextStyle(
//                                     color: Colors.grey,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 15),
//                                 ElevatedButton(
//                                   onPressed: fetchCourseContent,
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: primaryColor,
//                                     foregroundColor: Colors.white,
//                                   ),
//                                   child: const Text('Try Again'),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   )
//                 : courseContents.isEmpty
//                     ? ListView(
//                         physics: const AlwaysScrollableScrollPhysics(),
//                         children: [
//                           SizedBox(
//                             height: 380,
//                             child: Center(
//                               child: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Container(
//                                     height: 85,
//                                     width: 85,
//                                     decoration: const BoxDecoration(
//                                       color: Color(0xFFE7F4F1),
//                                       shape: BoxShape.circle,
//                                     ),
//                                     child: const Icon(
//                                       Icons.folder_open_outlined,
//                                       size: 42,
//                                       color: primaryColor,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 17),
//                                   const Text(
//                                     'No Course Content',
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 18,
//                                       color: darkColor,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 7),
//                                   Text(
//                                     'No content has been uploaded\nfor this course yet.',
//                                     textAlign: TextAlign.center,
//                                     style: TextStyle(
//                                       color: Colors.grey.shade600,
//                                       height: 1.5,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       )
//                     : ListView.builder(
//                         padding: const EdgeInsets.all(20),
//                         physics: const AlwaysScrollableScrollPhysics(),
//                         itemCount: courseContents.length,
//                         itemBuilder: (context, index) {
//                           final item = courseContents[index];

//                           if (item is! Map) {
//                             return const SizedBox.shrink();
//                           }

//                           return buildContentCard(
//                             Map<String, dynamic>.from(item),
//                           );
//                         },
//                       ),
//       ),
//     );
//   }
// }





























// import 'dart:io';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:house_of_tutor/StudentHome.dart';
// import 'package:house_of_tutor/StudentAllClasses.dart';
// import 'package:house_of_tutor/StudentCourses.dart';
// import 'package:house_of_tutor/StudentDrawer.dart';
// import 'package:house_of_tutor/services/api_client.dart';
// import 'package:house_of_tutor/services/api_config.dart';
// import 'package:house_of_tutor/services/auth_store.dart';
// import 'package:url_launcher/url_launcher.dart';

// class StudentAddCourses extends StatefulWidget {
//   const StudentAddCourses({super.key});

//   @override
//   State<StudentAddCourses> createState() => _StudentAddCoursesState();
// }

// class _StudentAddCoursesState extends State<StudentAddCourses> {
//   // ============================================================
//   // BASIC VARIABLES

//   bool isLoading = true;

//   // My enrolled courses
//   List<dynamic> myCourses = [];

//   // Error message
//   String errorMessage = '';

//   // Main color of this screen
//   final Color primaryColor = const Color(0xff009688);

//   // Drawer control
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   // Bottom navigation: this screen is "Add Courses" (index 1)
//   int selectedIndex = 1;

//   // Logo path (change if your asset path is different)
//   static const String logoPath = 'assets/images/logo.png';

//   @override
//   void initState() {
//     super.initState();
//     fetchMyCourses();
//   }

//   // ============================================================
//   // BOTTOM NAVIGATION TAP
//   // ============================================================

//   void onTapBottom(int index) {
//     // Already on this screen
//     if (index == selectedIndex) return;

//     Widget? screen;

//     switch (index) {
//       case 0:
//         // Home / Schedule
//         screen = const StudentHome();
//         break;

//       case 2:
//         // Request
//         screen = const StudentCourses();
//         break;

//       case 3:
//         // Classes
//         screen = const StudentAllClasses();
//         break;
//     }

//     if (screen == null) return;

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => screen!),
//     );
//   }

//   // ============================================================
//   // HELPERS
//   // ============================================================

//   int _courseIdOf(dynamic course) {
//     if (course is! Map) return 0;
//     return int.tryParse(course['course_id']?.toString() ?? '0') ?? 0;
//   }

//   String _courseNameOf(dynamic course) {
//     if (course is! Map) return '';
//     return (course['course_name'] ?? course['course_title'] ?? '').toString();
//   }

//   // ============================================================
//   // 1. GET MY ENROLLED COURSES
//   // ============================================================
//   //
//   // silent = true  -> refresh list without showing the big loader
//   //                   (used after adding a course)
//   // ============================================================

//   Future<void> fetchMyCourses({bool silent = false}) async {
//     if (!mounted) return;

//     if (!silent) {
//       setState(() {
//         isLoading = true;
//         errorMessage = '';
//       });
//     }

//     try {
//       final response = await ApiClient.get("/api/Student/my-courses");

//       final data = await ApiClient.decodeJson(response);

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         List courses = [];

//         // API can return { "data": [...] }
//         if (data is Map && data['data'] is List) {
//           courses = data['data'];
//         }
//         // Or directly [...]
//         else if (data is List) {
//           courses = data;
//         }

//         setState(() {
//           myCourses = courses;
//           isLoading = false;
//           errorMessage = '';
//         });
//       } else {
//         setState(() {
//           errorMessage = ApiClient.messageFromBody(response.body) ??
//               'Failed to load courses.';
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         errorMessage = 'An error occurred: $e';
//         isLoading = false;
//       });
//     }
//   }

//   // ============================================================
//   // 2. SHOW COURSE CATALOG
//   // ============================================================
//   //
//   // The backend "all-courses" API returns ONLY the courses which
//   // the student has NOT enrolled in yet.
//   //
//   // So the full catalog is built here like this:
//   //
//   //   full catalog = available courses (all-courses API)
//   //                + enrolled courses  (my-courses list)
//   //
//   // - Courses never disappear from the catalog
//   // - Enrolled / just added courses show "Added"
//   // - Sheet stays open after adding, so you can add more
//   // ============================================================

//   Future<void> showCourseCatalog() async {
//     try {
//       final response = await ApiClient.get("/api/Student/all-courses");

//       if (response.statusCode == 200) {
//         final decoded = await ApiClient.decodeJson(response);

//         // Courses which are NOT enrolled yet (from backend)
//         List availableCourses = [];

//         if (decoded is List) {
//           availableCourses = decoded;
//         } else if (decoded is Map && decoded['data'] is List) {
//           availableCourses = decoded['data'];
//         }

//         if (!mounted) return;

//         // ------------------------------------------------------
//         // BUILD FULL CATALOG (enrolled + available)
//         // ------------------------------------------------------

//         final Map<int, Map<String, dynamic>> merged = {};

//         // 1) Enrolled courses
//         for (final c in myCourses) {
//           final int id = _courseIdOf(c);
//           if (id == 0) continue;

//           merged[id] = {
//             'course_id': id,
//             'course_name': _courseNameOf(c),
//           };
//         }

//         // 2) Available courses (skip if already added above)
//         for (final c in availableCourses) {
//           final int id = _courseIdOf(c);
//           if (id == 0) continue;

//           merged.putIfAbsent(
//             id,
//             () => {
//               'course_id': id,
//               'course_name': _courseNameOf(c),
//             },
//           );
//         }

//         // Sort by name so the order never changes after adding
//         final List<Map<String, dynamic>> allCourses = merged.values.toList()
//           ..sort(
//             (a, b) => a['course_name']
//                 .toString()
//                 .toLowerCase()
//                 .compareTo(b['course_name'].toString().toLowerCase()),
//           );

//         // IDs of courses student already has
//         final Set<int> enrolledIds =
//             myCourses.map((c) => _courseIdOf(c)).where((id) => id != 0).toSet();

//         // IDs of courses which are being added right now
//         final Set<int> addingIds = {};

//         // Values kept outside builder so they are not reset
//         String searchText = '';
//         String sheetMessage = '';
//         bool sheetOpen = true;

//         showModalBottomSheet(
//           context: context,
//           isScrollControlled: true,
//           backgroundColor: Colors.white,
//           shape: const RoundedRectangleBorder(
//             borderRadius: BorderRadius.vertical(
//               top: Radius.circular(20),
//             ),
//           ),
//           builder: (sheetContext) {
//             return StatefulBuilder(
//               builder: (context, setSheetState) {
//                 // Filter list by search text only
//                 final List filteredCourses = allCourses.where((c) {
//                   final name = c['course_name'].toString().toLowerCase();
//                   return name.contains(searchText.toLowerCase().trim());
//                 }).toList();

//                 return Padding(
//                   // Keeps the sheet above the keyboard
//                   padding: EdgeInsets.only(
//                     bottom: MediaQuery.of(context).viewInsets.bottom,
//                   ),
//                   child: Container(
//                     height: MediaQuery.of(context).size.height * 0.75,
//                     padding: const EdgeInsets.all(20),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Top small line
//                         Center(
//                           child: Container(
//                             width: 40,
//                             height: 4,
//                             decoration: BoxDecoration(
//                               color: Colors.grey.shade300,
//                               borderRadius: BorderRadius.circular(2),
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 15),

//                         // TITLE
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             const Text(
//                               "Course Catalog",
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                             IconButton(
//                               icon: const Icon(
//                                 Icons.close,
//                                 color: Colors.grey,
//                               ),
//                               onPressed: () {
//                                 Navigator.pop(sheetContext);
//                               },
//                             ),
//                           ],
//                         ),

//                         Text(
//                           "Select a course to add to your study plan "
//                           "(${allCourses.length} courses)",
//                           style: const TextStyle(
//                             fontSize: 13,
//                             color: Colors.grey,
//                           ),
//                         ),

//                         const SizedBox(height: 15),

//                         // SEARCH
//                         TextField(
//                           onChanged: (value) {
//                             setSheetState(() {
//                               searchText = value;
//                             });
//                           },
//                           decoration: InputDecoration(
//                             hintText: "Search courses...",
//                             prefixIcon: const Icon(
//                               Icons.search,
//                               color: Colors.grey,
//                             ),
//                             filled: true,
//                             fillColor: Colors.grey.shade50,
//                             contentPadding: const EdgeInsets.symmetric(
//                               vertical: 0,
//                               horizontal: 16,
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide(
//                                 color: Colors.grey.shade200,
//                               ),
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide(
//                                 color: Colors.grey.shade200,
//                               ),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide(color: primaryColor),
//                             ),
//                           ),
//                         ),

//                         // ERROR MESSAGE (if adding a course failed)
//                         if (sheetMessage.isNotEmpty) ...[
//                           const SizedBox(height: 10),
//                           Text(
//                             sheetMessage,
//                             style: const TextStyle(
//                               color: Colors.red,
//                               fontSize: 13,
//                             ),
//                           ),
//                         ],

//                         const SizedBox(height: 15),

//                         // COURSE LIST
//                         Expanded(
//                           child: filteredCourses.isEmpty
//                               ? const Center(
//                                   child: Text("No courses found"),
//                                 )
//                               : ListView.builder(
//                                   itemCount: filteredCourses.length,
//                                   itemBuilder: (context, index) {
//                                     final course = filteredCourses[index];

//                                     final int courseId = _courseIdOf(course);

//                                     final String courseName =
//                                         _courseNameOf(course);

//                                     final bool isEnrolled =
//                                         enrolledIds.contains(courseId);

//                                     final bool isAdding =
//                                         addingIds.contains(courseId);

//                                     // RIGHT SIDE: Added / loader / Add button
//                                     Widget trailing;

//                                     if (isEnrolled) {
//                                       trailing = Container(
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 12,
//                                           vertical: 8,
//                                         ),
//                                         decoration: BoxDecoration(
//                                           color: Colors.teal.shade50,
//                                           borderRadius:
//                                               BorderRadius.circular(8),
//                                         ),
//                                         child: Row(
//                                           mainAxisSize: MainAxisSize.min,
//                                           children: [
//                                             Icon(
//                                               Icons.check_circle,
//                                               size: 16,
//                                               color: primaryColor,
//                                             ),
//                                             const SizedBox(width: 4),
//                                             Text(
//                                               "Added",
//                                               style: TextStyle(
//                                                 color: primaryColor,
//                                                 fontWeight: FontWeight.bold,
//                                                 fontSize: 13,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       );
//                                     } else if (isAdding) {
//                                       trailing = SizedBox(
//                                         width: 24,
//                                         height: 24,
//                                         child: CircularProgressIndicator(
//                                           strokeWidth: 2,
//                                           color: primaryColor,
//                                         ),
//                                       );
//                                     } else {
//                                       trailing = ElevatedButton(
//                                         style: ElevatedButton.styleFrom(
//                                           backgroundColor: primaryColor,
//                                           foregroundColor: Colors.white,
//                                           elevation: 0,
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius:
//                                                 BorderRadius.circular(8),
//                                           ),
//                                           padding: const EdgeInsets.symmetric(
//                                             horizontal: 16,
//                                             vertical: 8,
//                                           ),
//                                         ),
//                                         onPressed: courseId == 0
//                                             ? null
//                                             : () async {
//                                                 setSheetState(() {
//                                                   addingIds.add(courseId);
//                                                   sheetMessage = '';
//                                                 });

//                                                 // Add course (sheet stays open)
//                                                 final String? error =
//                                                     await addStudentCourses(
//                                                   [courseId],
//                                                   showMessage: false,
//                                                 );

//                                                 // Sheet was closed meanwhile
//                                                 if (!sheetOpen) return;

//                                                 setSheetState(() {
//                                                   addingIds.remove(courseId);

//                                                   if (error == null) {
//                                                     enrolledIds.add(courseId);
//                                                   } else {
//                                                     sheetMessage = error;
//                                                   }
//                                                 });
//                                               },
//                                         child: const Text(
//                                           "+ Add",
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         ),
//                                       );
//                                     }

//                                     return Container(
//                                       margin:
//                                           const EdgeInsets.only(bottom: 12),
//                                       padding: const EdgeInsets.all(12),
//                                       decoration: BoxDecoration(
//                                         color: Colors.white,
//                                         borderRadius:
//                                             BorderRadius.circular(12),
//                                         border: Border.all(
//                                           color: Colors.grey.shade200,
//                                         ),
//                                       ),
//                                       child: Row(
//                                         children: [
//                                           // Course icon
//                                           Container(
//                                             padding:
//                                                 const EdgeInsets.all(10),
//                                             decoration: BoxDecoration(
//                                               color: Colors.teal.shade50,
//                                               borderRadius:
//                                                   BorderRadius.circular(10),
//                                             ),
//                                             child: Icon(
//                                               Icons.school,
//                                               color: primaryColor,
//                                               size: 20,
//                                             ),
//                                           ),

//                                           const SizedBox(width: 12),

//                                           // Course name
//                                           Expanded(
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.start,
//                                               children: [
//                                                 Text(
//                                                   courseName,
//                                                   style: const TextStyle(
//                                                     fontWeight:
//                                                         FontWeight.bold,
//                                                     fontSize: 15,
//                                                     color: Colors.black87,
//                                                   ),
//                                                 ),
//                                                 const SizedBox(height: 2),
//                                                 Text(
//                                                   isEnrolled
//                                                       ? "Already in your courses"
//                                                       : "Available for enrollment",
//                                                   style: const TextStyle(
//                                                     color: Colors.grey,
//                                                     fontSize: 12,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),

//                                           const SizedBox(width: 8),

//                                           trailing,
//                                         ],
//                                       ),
//                                     );
//                                   },
//                                 ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             );
//           },
//         ).whenComplete(() {
//           sheetOpen = false;
//         });
//       } else {
//         if (!mounted) return;

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Failed to load available courses'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // ============================================================
//   // 3. ADD STUDENT COURSE
//   // ============================================================
//   //
//   // Returns null  -> course added successfully
//   // Returns text  -> error message
//   //
//   // showMessage = false when called from the catalog sheet
//   // (snackbar would be hidden behind the sheet).
//   // ============================================================

//   Future<String?> addStudentCourses(
//     List<int> courseIds, {
//     bool showMessage = true,
//   }) async {
//     try {
//       final response = await ApiClient.post(
//         "/api/Student/add-courses",
//         {
//           'courseIds': courseIds,
//         },
//       );

//       final resData = await ApiClient.decodeJson(response);

//       if (response.statusCode == 200) {
//         if (mounted && showMessage) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 resData is Map
//                     ? (resData['message'] ?? 'Course added successfully')
//                         .toString()
//                     : 'Course added successfully',
//               ),
//               backgroundColor: primaryColor,
//             ),
//           );
//         }

//         // Refresh my courses in the background
//         await fetchMyCourses(silent: true);

//         return null;
//       }

//       final String message = resData is Map
//           ? (resData['message'] ?? 'Failed to add course').toString()
//           : 'Failed to add course';

//       if (mounted && showMessage) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(message),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }

//       return message;
//     } catch (e) {
//       final String message = 'Error: $e';

//       if (mounted && showMessage) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(message),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }

//       return message;
//     }
//   }

//   // ============================================================
//   // 4. UPLOAD COURSE CONTENT
//   // ============================================================
//   //
//   // POST /api/Student/upload-course-content
//   // multipart/form-data: course_id, title, description, file
//   // ============================================================

//   Future<void> uploadCourseContent(int courseId) async {
//     // STEP 1: PICK FILE
//     final FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
//     );

//     // User cancelled file picker
//     if (result == null) return;

//     final String? selectedPath = result.files.single.path;

//     if (selectedPath == null) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Unable to select file."),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     if (!mounted) return;

//     // STEP 2: TITLE / DESCRIPTION DIALOG
//     //
//     // Controllers are not disposed manually here.
//     // Disposing right after the dialog closes can throw
//     // "TextEditingController used after being disposed".
//     final titleController = TextEditingController();
//     final descriptionController = TextEditingController();

//     final bool? shouldUpload = await showDialog<bool>(
//       context: context,
//       builder: (dialogContext) {
//         String? titleError;

//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               title: const Text(
//                 "Course Content",
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               content: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // SELECTED FILE
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade100,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.insert_drive_file,
//                             color: primaryColor,
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: Text(
//                               result.files.single.name,
//                               style: const TextStyle(fontSize: 13),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 15),

//                     // TITLE
//                     TextField(
//                       controller: titleController,
//                       decoration: InputDecoration(
//                         labelText: "Content Title",
//                         hintText: "Example: Week 1 Lesson Plan",
//                         errorText: titleError,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 12),

//                     // DESCRIPTION
//                     TextField(
//                       controller: descriptionController,
//                       maxLines: 4,
//                       decoration: InputDecoration(
//                         labelText: "Description",
//                         hintText: "Enter details about this content",
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(dialogContext, false),
//                   child: const Text("Cancel"),
//                 ),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: primaryColor,
//                     foregroundColor: Colors.white,
//                   ),
//                   onPressed: () {
//                     // Title is required by backend
//                     if (titleController.text.trim().isEmpty) {
//                       setDialogState(() {
//                         titleError = "Please enter content title.";
//                       });
//                       return;
//                     }

//                     Navigator.pop(dialogContext, true);
//                   },
//                   child: const Text("Upload"),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );

//     // User cancelled dialog
//     if (shouldUpload != true) return;

//     if (!mounted) return;

//     // STEP 3: SHOW LOADING
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) {
//         return Center(
//           child: CircularProgressIndicator(color: primaryColor),
//         );
//       },
//     );

//     try {
//       // STEP 4: SEND MULTIPART REQUEST
//       final file = File(selectedPath);

//       final response = await ApiClient.uploadFile(
//         "/api/Student/upload-course-content",
//         fields: {
//           "course_id": courseId.toString(),
//           "title": titleController.text.trim(),
//           "description": descriptionController.text.trim(),
//         },
//         fileFieldName: "file",
//         file: file,
//       );

//       final responseData = await ApiClient.decodeJson(response);

//       // STEP 5: CLOSE LOADING
//       if (!mounted) return;
//       Navigator.pop(context);

//       // STEP 6: SHOW RESULT
//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               responseData is Map
//                   ? (responseData['message'] ??
//                           'Course content uploaded successfully.')
//                       .toString()
//                   : 'Course content uploaded successfully.',
//             ),
//             backgroundColor: primaryColor,
//           ),
//         );
//       } else {
//         final message = responseData is Map
//             ? (responseData['message'] ?? 'Course content upload failed.')
//             : 'Course content upload failed.';

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(message.toString()),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       // Close loading dialog
//       if (mounted) {
//         Navigator.pop(context);

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Upload Error: $e"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   // ============================================================
//   // 5. OPEN COURSE DETAILS
//   // ============================================================

//   void openCourseDetails(Map<String, dynamic> course) {
//     final int courseId =
//         int.tryParse(course['course_id']?.toString() ?? '0') ?? 0;

//     final String courseName = course['course_name']?.toString() ??
//         course['course_title']?.toString() ??
//         'Course';

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => StudentCourseContentScreen(
//           courseId: courseId,
//           courseName: courseName,
//           primaryColor: primaryColor,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // LOGO WIDGET
//   // ============================================================

//   Widget buildLogo() {
//     return Image.asset(
//       logoPath,
//       height: 32,
//       width: 32,
//       fit: BoxFit.contain,
//       // If the logo file is missing, show the old school icon
//       errorBuilder: (context, error, stackTrace) {
//         return Container(
//           padding: const EdgeInsets.all(6),
//           decoration: BoxDecoration(
//             color: Colors.teal.shade50,
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(
//             Icons.school,
//             color: primaryColor,
//             size: 20,
//           ),
//         );
//       },
//     );
//   }

//   // ============================================================
//   // BUILD SCREEN
//   // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       backgroundColor: Colors.grey.shade50,

//       // DRAWER
//       drawer: const StudentDrawer(),

//       // APP BAR
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(
//             Icons.menu,
//             color: Colors.black87,
//           ),
//           onPressed: () {
//             _scaffoldKey.currentState?.openDrawer();
//           },
//         ),
//         title: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             buildLogo(),
//             const SizedBox(width: 8),
//             const Text(
//               "House of Tutor",
//               style: TextStyle(
//                 color: Colors.black87,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),
//         centerTitle: true,
//       ),

//       // BODY
//       body: Padding(
//         padding: const EdgeInsets.symmetric(
//           horizontal: 20,
//           vertical: 10,
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "My Courses",
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),

//             const SizedBox(height: 4),

//             Text(
//               "${myCourses.length} courses currently enrolled",
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.grey.shade600,
//               ),
//             ),

//             const SizedBox(height: 16),

//             // COURSES
//             Expanded(
//               child: isLoading
//                   // Loading
//                   ? Center(
//                       child: CircularProgressIndicator(
//                         color: primaryColor,
//                       ),
//                     )

//                   // Error
//                   : errorMessage.isNotEmpty && myCourses.isEmpty
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

//                       // No courses
//                       : myCourses.isEmpty
//                           ? const Center(
//                               child: Text(
//                                 "No courses enrolled yet.",
//                                 style: TextStyle(color: Colors.grey),
//                               ),
//                             )

//                           // Course list
//                           : RefreshIndicator(
//                               color: primaryColor,
//                               onRefresh: () => fetchMyCourses(),
//                               child: ListView.builder(
//                                 physics:
//                                     const AlwaysScrollableScrollPhysics(),
//                                 itemCount: myCourses.length,
//                                 itemBuilder: (context, index) {
//                                   final course = Map<String, dynamic>.from(
//                                     myCourses[index],
//                                   );

//                                   final String courseName =
//                                       course['course_name']?.toString() ??
//                                           course['course_title']
//                                               ?.toString() ??
//                                           'Course';

//                                   final int courseId = int.tryParse(
//                                         course['course_id']?.toString() ??
//                                             '0',
//                                       ) ??
//                                       0;

//                                   return GestureDetector(
//                                     onTap: () => openCourseDetails(course),
//                                     child: Container(
//                                       margin:
//                                           const EdgeInsets.only(bottom: 14),
//                                       padding: const EdgeInsets.all(16),
//                                       decoration: BoxDecoration(
//                                         color: Colors.white,
//                                         borderRadius:
//                                             BorderRadius.circular(16),
//                                         boxShadow: [
//                                           BoxShadow(
//                                             color: Colors.black
//                                                 .withOpacity(0.04),
//                                             blurRadius: 8,
//                                             offset: const Offset(0, 2),
//                                           ),
//                                         ],
//                                       ),
//                                       child: Row(
//                                         children: [
//                                           // COURSE ICON
//                                           Container(
//                                             width: 45,
//                                             height: 45,
//                                             decoration: BoxDecoration(
//                                               color: Colors.teal.shade50,
//                                               borderRadius:
//                                                   BorderRadius.circular(10),
//                                             ),
//                                             child: Icon(
//                                               Icons.book,
//                                               color: primaryColor,
//                                               size: 22,
//                                             ),
//                                           ),

//                                           const SizedBox(width: 12),

//                                           // COURSE NAME
//                                           Expanded(
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.start,
//                                               children: [
//                                                 Text(
//                                                   courseName,
//                                                   maxLines: 1,
//                                                   overflow:
//                                                       TextOverflow.ellipsis,
//                                                   style: const TextStyle(
//                                                     fontSize: 16,
//                                                     fontWeight:
//                                                         FontWeight.bold,
//                                                     color: Colors.black87,
//                                                   ),
//                                                 ),
//                                                 const SizedBox(height: 5),
//                                                 Row(
//                                                   children: [
//                                                     Container(
//                                                       width: 6,
//                                                       height: 6,
//                                                       decoration:
//                                                           BoxDecoration(
//                                                         color: primaryColor,
//                                                         shape:
//                                                             BoxShape.circle,
//                                                       ),
//                                                     ),
//                                                     const SizedBox(width: 6),
//                                                     const Text(
//                                                       "Enrolled",
//                                                       style: TextStyle(
//                                                         fontSize: 12,
//                                                         color:
//                                                             Color(0xff009688),
//                                                         fontWeight:
//                                                             FontWeight.w500,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ],
//                                             ),
//                                           ),

//                                           // UPLOAD BUTTON
//                                           IconButton(
//                                             tooltip: "Upload Course Content",
//                                             icon: Icon(
//                                               Icons.upload_file,
//                                               color: primaryColor,
//                                             ),
//                                             onPressed: () async {
//                                               await uploadCourseContent(
//                                                 courseId,
//                                               );
//                                             },
//                                           ),

//                                           // ARROW
//                                           const Icon(
//                                             Icons.chevron_right,
//                                             color: Colors.grey,
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//             ),
//           ],
//         ),
//       ),

//       // ADD COURSE BUTTON
//       floatingActionButton: FloatingActionButton.extended(
//         backgroundColor: primaryColor,
//         foregroundColor: Colors.white,
//         onPressed: showCourseCatalog,
//         icon: const Icon(Icons.add),
//         label: const Text(
//           "Add Course",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//       ),

//       // ==========================================================
//       // BOTTOM NAVIGATION
//       // ==========================================================

//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: selectedIndex,
//         type: BottomNavigationBarType.fixed,
//         selectedItemColor: Colors.teal,
//         unselectedItemColor: Colors.grey,
//         onTap: onTapBottom,
//         items: const [
//           // Home / Schedule
//           BottomNavigationBarItem(
//             icon: Icon(Icons.calendar_today),
//             label: "Schedule",
//           ),

//           // Add Courses
//           BottomNavigationBarItem(
//             icon: Icon(Icons.add_box),
//             label: "Add Courses",
//           ),

//           // Request
//           BottomNavigationBarItem(
//             icon: Icon(Icons.request_page),
//             label: "Request",
//           ),

//           // Classes
//           BottomNavigationBarItem(
//             icon: Icon(Icons.class_),
//             label: "Classes",
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ====================================================================
// // STUDENT COURSE CONTENT SCREEN
// // ====================================================================
// //
// // JPG / JPEG / PNG  -> Show image directly
// // PDF / DOC / DOCX  -> Show file card + Open File button
// //
// // File path is NOT displayed to the student.
// // ====================================================================

// class StudentCourseContentScreen extends StatefulWidget {
//   final int courseId;
//   final String courseName;
//   final Color primaryColor;

//   const StudentCourseContentScreen({
//     super.key,
//     required this.courseId,
//     required this.courseName,
//     required this.primaryColor,
//   });

//   @override
//   State<StudentCourseContentScreen> createState() =>
//       _StudentCourseContentScreenState();
// }

// class _StudentCourseContentScreenState
//     extends State<StudentCourseContentScreen> {
//   // ============================================================
//   // VARIABLES
//   // ============================================================

//   bool isLoading = true;
//   List<dynamic> courseContents = [];
//   String errorMessage = '';

//   @override
//   void initState() {
//     super.initState();
//     fetchCourseContent();
//   }

//   // ============================================================
//   // GET COURSE CONTENT
//   // ============================================================

//   Future<void> fetchCourseContent() async {
//     if (mounted) {
//       setState(() {
//         isLoading = true;
//         errorMessage = '';
//       });
//     }

//     try {
//       final response = await ApiClient.get(
//         "/api/Student/my-course-content/${widget.courseId}",
//       );

//       final data = await ApiClient.decodeJson(response);

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         List<dynamic> content = [];

//         // Expected: { "data": [ ... ] }
//         if (data is Map && data['data'] is List) {
//           content = List<dynamic>.from(data['data']);
//         }
//         // Also support direct list response
//         else if (data is List) {
//           content = List<dynamic>.from(data);
//         }

//         setState(() {
//           courseContents = content;
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           errorMessage = data is Map
//               ? (data['message']?.toString() ??
//                   'Failed to load course content.')
//               : 'Failed to load course content.';
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         errorMessage = 'Error loading content: $e';
//         isLoading = false;
//       });
//     }
//   }

//   // ============================================================
//   // UPDATE COURSE CONTENT (PUT MULTIPART API)
//   // ============================================================
//   // This API updates title and description.
//   // If a new file is selected, it also replaces the old file.

//   Future<void> updateCourseContent({
//     required int contentId,
//     required String title,
//     required String description,
//     File? newFile,
//   }) async {
//     try {
//       // Get login token for Authorization header.
//       await AuthStore.instance.hydrate();
//       final token = AuthStore.instance.token;

//       if (token == null || token.toString().isEmpty) {
//         throw Exception('Login token not found. Please login again.');
//       }

//       // Build correct API URL whether apiBaseUrl contains /api or not.
//       String baseUrl = apiBaseUrl.trim();
//       while (baseUrl.endsWith('/')) {
//         baseUrl = baseUrl.substring(0, baseUrl.length - 1);
//       }

//       String apiUrl;
//       if (baseUrl.toLowerCase().endsWith('/api')) {
//         apiUrl = '$baseUrl/Student/update-course-content/$contentId';
//       } else {
//         apiUrl = '$baseUrl/api/Student/update-course-content/$contentId';
//       }

//       // PUT multipart request (used because a file may also be uploaded).
//       final request = http.MultipartRequest('PUT', Uri.parse(apiUrl));
//       request.headers['Authorization'] = 'Bearer $token';
//       request.headers['Accept'] = 'application/json';

//       request.fields['title'] = title.trim();
//       request.fields['description'] = description.trim();

//       // Attach new file only if user selected one.
//       if (newFile != null) {
//         request.files.add(
//           await http.MultipartFile.fromPath('file', newFile.path),
//         );
//       }

//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);
//       final responseData = await ApiClient.decodeJson(response);

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         Navigator.of(context).pop(); // Close loading dialog.
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Course content updated successfully.'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         await fetchCourseContent();
//       } else {
//         Navigator.of(context).pop(); // Close loading dialog.
//         final message = responseData is Map
//             ? (responseData['message']?.toString() ?? 'Update failed.')
//             : 'Update failed.';
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(message), backgroundColor: Colors.red),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;

//       // Close loader if it is still showing.
//       Navigator.of(context).pop();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Unable to update content: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // ============================================================
//   // EDIT COURSE CONTENT
//   // ============================================================

//   Future<void> editCourseContent(Map<String, dynamic> content) async {
//     final int contentId = int.tryParse(
//           (content['content_id'] ??
//                   content['contentId'] ??
//                   content['ContentId'] ??
//                   content['id'] ??
//                   '0')
//               .toString(),
//         ) ??
//         0;

//     if (contentId == 0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Content ID was not returned by the API.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     final titleController = TextEditingController(
//       text: content['title']?.toString() ?? '',
//     );
//     final descriptionController = TextEditingController(
//       text: content['description']?.toString() ?? '',
//     );

//     File? selectedFile;
//     String selectedFileName = '';

//     // Open edit dialog.
//     await showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return StatefulBuilder(
//           builder: (dialogContext, setDialogState) {
//             return AlertDialog(
//               title: const Text('Edit Course Content'),
//               content: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text('Title'),
//                     const SizedBox(height: 6),
//                     TextField(
//                       controller: titleController,
//                       decoration: const InputDecoration(
//                         hintText: 'Enter title',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 14),
//                     const Text('Description'),
//                     const SizedBox(height: 6),
//                     TextField(
//                       controller: descriptionController,
//                       maxLines: 3,
//                       decoration: const InputDecoration(
//                         hintText: 'Enter description',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 14),
//                     OutlinedButton.icon(
//                       onPressed: () async {
//                         // Pick a replacement file (optional).
//                         final result = await FilePicker.platform.pickFiles(
//                           type: FileType.custom,
//                           allowedExtensions: [
//                             'pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'
//                           ],
//                         );

//                         if (result != null &&
//                             result.files.single.path != null) {
//                           setDialogState(() {
//                             selectedFile = File(result.files.single.path!);
//                             selectedFileName = result.files.single.name;
//                           });
//                         }
//                       },
//                       icon: const Icon(Icons.attach_file),
//                       label: const Text('Choose New File (Optional)'),
//                     ),
//                     if (selectedFileName.isNotEmpty) ...[
//                       const SizedBox(height: 6),
//                       Text(
//                         'Selected: $selectedFileName',
//                         style: const TextStyle(color: Colors.green),
//                       ),
//                     ],
//                     const SizedBox(height: 5),
//                     const Text(
//                       'If you do not select a file, the current file will remain.',
//                       style: TextStyle(fontSize: 12, color: Colors.grey),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(dialogContext),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {
//                     if (titleController.text.trim().isEmpty) {
//                       ScaffoldMessenger.of(dialogContext).showSnackBar(
//                         const SnackBar(content: Text('Please enter title.')),
//                       );
//                       return;
//                     }

//                     Navigator.pop(dialogContext);
//                     _showLoadingDialog();
//                     updateCourseContent(
//                       contentId: contentId,
//                       title: titleController.text,
//                       description: descriptionController.text,
//                       newFile: selectedFile,
//                     );
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: widget.primaryColor,
//                     foregroundColor: Colors.white,
//                   ),
//                   child: const Text('Update'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );

//     titleController.dispose();
//     descriptionController.dispose();
//   }

//   // ============================================================
//   // DELETE COURSE CONTENT
//   // ============================================================

//   Future<void> deleteCourseContent(int contentId) async {
//     try {
//       final response = await ApiClient.delete(
//         '/api/Student/delete-course-content/$contentId',
//       );
//       final data = await ApiClient.decodeJson(response);

//       if (!mounted) return;

//       // Backend normally returns 200 after successful deletion.
//       if (response.statusCode == 200 || response.statusCode == 204) {
//         Navigator.of(context).pop(); // Close loading dialog.
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Course content deleted successfully.'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         await fetchCourseContent();
//       } else {
//         Navigator.of(context).pop(); // Close loading dialog.
//         final message = data is Map
//             ? (data['message']?.toString() ?? 'Delete failed.')
//             : 'Delete failed.';
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(message), backgroundColor: Colors.red),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       Navigator.of(context).pop();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Unable to delete content: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // Ask user before deleting.
//   Future<void> confirmDeleteContent(Map<String, dynamic> content) async {
//     final int contentId = int.tryParse(
//           (content['content_id'] ??
//                   content['contentId'] ??
//                   content['ContentId'] ??
//                   content['id'] ??
//                   '0')
//               .toString(),
//         ) ??
//         0;

//     if (contentId == 0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Content ID was not returned by the API.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     final bool? confirm = await showDialog<bool>(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: const Text('Delete Course Content?'),
//         content: const Text(
//           'Are you sure you want to delete this content? This action cannot be undone.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(dialogContext, true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );

//     if (confirm == true && mounted) {
//       _showLoadingDialog();
//       await deleteCourseContent(contentId);
//     }
//   }

//   // Small loading popup used while update/delete API is running.
//   void _showLoadingDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => const AlertDialog(
//         content: Row(
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(width: 18),
//             Expanded(child: Text('Please wait...')),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // HELPERS
//   // ============================================================

//   String formatDate(dynamic dateValue) {
//     if (dateValue == null) return '';

//     try {
//       final date = DateTime.parse(dateValue.toString());

//       return "${date.day.toString().padLeft(2, '0')}/"
//           "${date.month.toString().padLeft(2, '0')}/"
//           "${date.year}";
//     } catch (_) {
//       return dateValue.toString();
//     }
//   }

//   String getFileName(String fileName, String filePath) {
//     if (fileName.trim().isNotEmpty) {
//       return fileName.trim();
//     }

//     if (filePath.trim().isNotEmpty) {
//       return filePath.split('/').last;
//     }

//     return 'Course Content';
//   }

//   // Backend returns: /CourseContent/Student_1_Course_1.jpg
//   // apiBaseUrl is like: http://YOUR-IP:5000/api
//   // Static files are served from: http://YOUR-IP:5000/CourseContent/...
//   String getFileUrl(String filePath) {
//     String cleanPath = filePath.trim();

//     if (cleanPath.isEmpty) return '';

//     // Backend already returned a full URL
//     if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
//       return cleanPath;
//     }

//     if (!cleanPath.startsWith('/')) {
//       cleanPath = '/$cleanPath';
//     }

//     String serverUrl = apiBaseUrl.trim();

//     // Remove trailing slash
//     while (serverUrl.endsWith('/')) {
//       serverUrl = serverUrl.substring(0, serverUrl.length - 1);
//     }

//     // Remove /api from the end
//     if (serverUrl.toLowerCase().endsWith('/api')) {
//       serverUrl = serverUrl.substring(0, serverUrl.length - 4);
//     }

//     return '$serverUrl$cleanPath';
//   }

//   bool isImageFile(String fileName) {
//     final name = fileName.toLowerCase().trim();

//     return name.endsWith('.jpg') ||
//         name.endsWith('.jpeg') ||
//         name.endsWith('.png');
//   }

//   IconData getFileIcon(String fileName) {
//     final name = fileName.toLowerCase().trim();

//     if (name.endsWith('.pdf')) return Icons.picture_as_pdf;

//     if (name.endsWith('.doc') || name.endsWith('.docx')) {
//       return Icons.description;
//     }

//     if (isImageFile(name)) return Icons.image;

//     return Icons.insert_drive_file;
//   }

//   // ============================================================
//   // OPEN PDF / DOC / DOCX
//   // ============================================================

//   Future<void> openFile(String fileUrl) async {
//     if (fileUrl.trim().isEmpty) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('File URL is not available.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     try {
//       final uri = Uri.parse(fileUrl);

//       final bool opened = await launchUrl(
//         uri,
//         mode: LaunchMode.externalApplication,
//       );

//       if (!opened && mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Unable to open file.'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Unable to open file: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // ============================================================
//   // IMAGE VIEW
//   // ============================================================

//   Widget buildImageContent(String fileUrl) {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(12),
//         child: Image.network(
//           fileUrl,
//           width: double.infinity,
//           fit: BoxFit.contain,
//           loadingBuilder: (
//             BuildContext context,
//             Widget child,
//             ImageChunkEvent? loadingProgress,
//           ) {
//             if (loadingProgress == null) return child;

//             return SizedBox(
//               height: 250,
//               child: Center(
//                 child: CircularProgressIndicator(
//                   color: widget.primaryColor,
//                 ),
//               ),
//             );
//           },
//           errorBuilder: (
//             BuildContext context,
//             Object error,
//             StackTrace? stackTrace,
//           ) {
//             return SizedBox(
//               height: 220,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.broken_image,
//                     size: 50,
//                     color: Colors.grey.shade400,
//                   ),
//                   const SizedBox(height: 10),
//                   const Text(
//                     'Unable to load image',
//                     style: TextStyle(color: Colors.grey),
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // PDF / DOC / DOCX VIEW
//   // ============================================================

//   Widget buildFileContent(String fileName, String fileUrl) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Column(
//         children: [
//           Container(
//             width: 65,
//             height: 65,
//             decoration: BoxDecoration(
//               color: Colors.teal.shade50,
//               borderRadius: BorderRadius.circular(15),
//             ),
//             child: Icon(
//               getFileIcon(fileName),
//               size: 32,
//               color: widget.primaryColor,
//             ),
//           ),

//           const SizedBox(height: 12),

//           Text(
//             fileName,
//             textAlign: TextAlign.center,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//             ),
//           ),

//           const SizedBox(height: 15),

//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton.icon(
//               onPressed: () => openFile(fileUrl),
//               icon: const Icon(Icons.open_in_new),
//               label: const Text('Open File'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: widget.primaryColor,
//                 foregroundColor: Colors.white,
//                 elevation: 0,
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // CONTENT CARD
//   // ============================================================

//   Widget buildContentCard(Map<String, dynamic> content) {
//     final String title = content['title']?.toString().trim().isNotEmpty == true
//         ? content['title'].toString()
//         : 'Course Content';

//     final String description = content['description']?.toString() ?? '';

//     final String fileName = content['file_name']?.toString() ?? '';

//     final String filePath = content['file_path']?.toString() ?? '';

//     final dynamic uploadedDate = content['uploaded_date'];

//     // ID is required by update and delete APIs.
//     final int contentId = int.tryParse(
//           (content['content_id'] ?? content['contentId'] ??
//                   content['ContentId'] ?? content['id'] ?? '0')
//               .toString(),
//         ) ??
//         0;

//     final String displayFileName = getFileName(fileName, filePath);

//     final String fileUrl = getFileUrl(filePath);

//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // TITLE + DATE
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: 45,
//                 height: 45,
//                 decoration: BoxDecoration(
//                   color: Colors.teal.shade50,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(
//                   Icons.menu_book,
//                   color: widget.primaryColor,
//                 ),
//               ),

//               const SizedBox(width: 12),

//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         fontSize: 17,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),

//                     if (uploadedDate != null) ...[
//                       const SizedBox(height: 4),
//                       Text(
//                         'Uploaded: ${formatDate(uploadedDate)}',
//                         style: const TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           // DESCRIPTION
//           if (description.trim().isNotEmpty) ...[
//             const SizedBox(height: 15),

//             const Text(
//               'Description',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),

//             const SizedBox(height: 5),

//             Text(
//               description,
//               style: const TextStyle(
//                 fontSize: 14,
//                 color: Colors.black54,
//                 height: 1.4,
//               ),
//             ),
//           ],

//           // ACTUAL UPLOADED CONTENT
//           // filePath is NOT shown, only used to build the real URL
//           if (fileUrl.isNotEmpty) ...[
//             const SizedBox(height: 16),

//             if (isImageFile(displayFileName))
//               buildImageContent(fileUrl)
//             else
//               buildFileContent(displayFileName, fileUrl),
//           ],

//           // EDIT AND DELETE BUTTONS
//           if (contentId != 0) ...[
//             const SizedBox(height: 15),
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: () => editCourseContent(content),
//                     icon: const Icon(Icons.edit, size: 18),
//                     label: const Text('Edit'),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: widget.primaryColor,
//                       side: BorderSide(color: widget.primaryColor),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: () => confirmDeleteContent(content),
//                     icon: const Icon(Icons.delete, size: 18),
//                     label: const Text('Delete'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red,
//                       foregroundColor: Colors.white,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ],
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
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.black87),
//         title: Text(
//           widget.courseName,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//           style: const TextStyle(
//             color: Colors.black87,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//       body: RefreshIndicator(
//         color: widget.primaryColor,
//         onRefresh: fetchCourseContent,
//         child: isLoading
//             ? ListView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 children: [
//                   SizedBox(
//                     height: 300,
//                     child: Center(
//                       child: CircularProgressIndicator(
//                         color: widget.primaryColor,
//                       ),
//                     ),
//                   ),
//                 ],
//               )
//             : errorMessage.isNotEmpty
//                 ? ListView(
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     children: [
//                       SizedBox(
//                         height: 300,
//                         child: Center(
//                           child: Padding(
//                             padding: const EdgeInsets.all(20),
//                             child: Text(
//                               errorMessage,
//                               textAlign: TextAlign.center,
//                               style: const TextStyle(color: Colors.grey),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   )
//                 : courseContents.isEmpty
//                     ? ListView(
//                         physics: const AlwaysScrollableScrollPhysics(),
//                         children: [
//                           const SizedBox(height: 120),
//                           Icon(
//                             Icons.folder_open,
//                             size: 65,
//                             color: Colors.grey.shade300,
//                           ),
//                           const SizedBox(height: 15),
//                           const Center(
//                             child: Text(
//                               'No Course Content',
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black54,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           const Center(
//                             child: Text(
//                               'No course content has been\nuploaded yet.',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(color: Colors.grey),
//                             ),
//                           ),
//                         ],
//                       )
//                     : ListView.builder(
//                         physics: const AlwaysScrollableScrollPhysics(),
//                         padding: const EdgeInsets.all(20),
//                         itemCount: courseContents.length,
//                         itemBuilder: (context, index) {
//                           final item = courseContents[index];

//                           if (item is! Map) {
//                             return const SizedBox.shrink();
//                           }

//                           return buildContentCard(
//                             Map<String, dynamic>.from(item),
//                           );
//                         },
//                       ),
//       ),
//     );
//   }
// }