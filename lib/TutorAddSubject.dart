
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:house_of_tutor/TutorDrawer.dart';
import 'package:house_of_tutor/services/api_client.dart';

class TutorAddSubject extends StatefulWidget {
  const TutorAddSubject({super.key});

  @override
  State<TutorAddSubject> createState() => _TutorAddSubjectState();
}

class _TutorAddSubjectState extends State<TutorAddSubject> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryColor = Color(0xFF1E8E7E);
  static const Color backgroundColor = Color(0xFFF4F7F9);
  static const Color textColor = Color(0xFF253238);
  static const Color secondaryTextColor = Color(0xFF78858C);

  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = true;
  bool isRefreshing = false;

  List<Map<String, dynamic>> myCourses = [];
  List<Map<String, dynamic>> availableCourses = [];

  @override
  void initState() {
    super.initState();
    loadCourses();
  }

  // ============================================================
  // JSON HELPERS
  // ============================================================

  dynamic _decodeResponse(dynamic response) {
    if (response.bodyBytes.isNotEmpty) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return null;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _toString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = _toString(value).toLowerCase();

    return text == 'true' ||
        text == '1' ||
        text == 'yes' ||
        text == 'completed';
  }

  String _readAny(Map item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return '';
  }

  dynamic _readRaw(Map item, List<String> keys) {
    for (final key in keys) {
      if (item.containsKey(key) && item[key] != null) {
        return item[key];
      }
    }
    return null;
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;

    if (data is Map) {
      final result = data['courses'] ??
          data['Courses'] ??
          data['data'] ??
          data['items'];

      if (result is List) return result;
    }

    return [];
  }

  String _formatDate(dynamic value) {
    final raw = _toString(value);

    if (raw.isEmpty) return '';

    final parsed = DateTime.tryParse(raw);

    if (parsed == null) return raw;

    return '${parsed.day.toString().padLeft(2, '0')}/'
        '${parsed.month.toString().padLeft(2, '0')}/'
        '${parsed.year}';
  }

  String _displayValue(String value) {
    return value.isEmpty ? 'Not provided' : value;
  }

  // ============================================================
  // LOAD COURSES
  // ============================================================

  Future<void> loadCourses({bool showLoader = true}) async {
    if (!mounted) return;

    if (showLoader) {
      setState(() {
        isLoading = true;
      });
    } else {
      setState(() {
        isRefreshing = true;
      });
    }

    try {
      final responses = await Future.wait([
        ApiClient.get('/api/Tutor/my-courses'),
        ApiClient.get('/api/Tutor/all-courses'),
      ]);

      final myResponse = responses[0];
      final allResponse = responses[1];

      debugPrint('MY COURSES STATUS: ${myResponse.statusCode}');
      debugPrint('MY COURSES BODY: ${myResponse.body}');
      debugPrint('ALL COURSES STATUS: ${allResponse.statusCode}');
      debugPrint('ALL COURSES BODY: ${allResponse.body}');

      if (myResponse.statusCode == 401 ||
          allResponse.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }

      if (myResponse.statusCode != 200) {
        throw Exception(
          ApiClient.messageFromBody(myResponse.body) ??
              'Unable to load your courses.',
        );
      }

      if (allResponse.statusCode != 200) {
        throw Exception(
          ApiClient.messageFromBody(allResponse.body) ??
              'Unable to load available courses.',
        );
      }

      final myData = _decodeResponse(myResponse);
      final allData = _decodeResponse(allResponse);

      final Set<int> addedCourseIds = {};
      final List<Map<String, dynamic>> myList = [];

      for (final item in _extractList(myData)) {
        if (item is! Map) continue;

        final courseId = _toInt(
          _readRaw(item, [
            'course_id',
            'courseId',
            'CourseId',
          ]),
        );

        if (courseId <= 0) continue;

        addedCourseIds.add(courseId);

        myList.add({
          'course_id': courseId,

          'course_name': _readAny(item, [
            'course_name',
            'courseName',
            'CourseName',
          ]),

          'grade': _readAny(item, [
            'grade',
            'Grade',
          ]),

          'institute': _readAny(item, [
            'institute',
            'Institute',
            'university',
            'university_name',
            'universityName',
          ]),

          'hourly_rate': _toDouble(
            _readRaw(item, [
                  'hourly_rate',
                  'hourlyRate',
                  'HourlyRate',
                ]) ??
                0,
          ),

          'previous_teacher': _readAny(item, [
            'previous_teacher',
            'previousTeacher',
            'previous_teacher_name',
            'previousTeacherName',
            'tutor_name',
            'tutorName',
            'TutorName',
          ]),

          'previous_teacher_institute': _readAny(item, [
            'previous_teacher_institute',
            'previousTeacherInstitute',
            'previous_teacher_university',
            'previousTeacherUniversity',
            'tutor_institute',
            'tutorInstitute',
            'tutor_university',
            'tutorUniversity',
            'TutorInstitute',
          ]),

          'study_year': _readAny(item, [
            'study_year',
            'studyYear',
            'StudyYear',
          ]),

          'is_programming_subject': _toBool(
            _readRaw(item, [
                  'is_programming_subject',
                  'isProgrammingSubject',
                  'IsProgrammingSubject',
                ]) ??
                false,
          ),

          'programming_language': _readAny(item, [
            'programming_language',
            'programmingLanguage',
            'ProgrammingLanguage',
          ]),

          'lab_completed': _readRaw(item, [
            'lab_completed',
            'labCompleted',
            'LabCompleted',
          ]),

          'grade_verification_status': _readAny(item, [
            'grade_verification_status',
            'gradeVerificationStatus',
            'verification_status',
            'verificationStatus',
            'GradeVerificationStatus',
          ]),

          'verified_by': _readAny(item, [
            'verified_by',
            'verifiedBy',
            'VerifiedBy',
          ]),

          'verified_date': _readAny(item, [
            'verified_date',
            'verifiedDate',
            'verification_date',
            'verificationDate',
            'VerifiedDate',
          ]),

          'verification_remarks': _readAny(item, [
            'verification_remarks',
            'verificationRemarks',
            'remarks',
            'Remarks',
          ]),
        });
      }

      final List<Map<String, dynamic>> availableList = [];

      for (final item in _extractList(allData)) {
        if (item is! Map) continue;

        final courseId = _toInt(
          _readRaw(item, [
            'course_id',
            'courseId',
            'CourseId',
          ]),
        );

        final courseName = _readAny(item, [
          'course_name',
          'courseName',
          'course_title',
          'courseTitle',
        ]);

        if (courseId <= 0 || courseName.isEmpty) continue;
        if (addedCourseIds.contains(courseId)) continue;

        availableList.add({
          'course_id': courseId,
          'course_name': courseName,
        });
      }

      if (!mounted) return;

      setState(() {
        myCourses = myList;
        availableCourses = availableList;
        isLoading = false;
        isRefreshing = false;
      });
    } catch (e) {
      debugPrint('LOAD COURSES ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRefreshing = false;
      });

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  // ============================================================
  // ADD COURSE API
  // ============================================================

  Future<bool> _addCourse({
    required int courseId,
    required String grade,
    required double hourlyRate,
    required String institute,
    required String previousTeacher,
    required String previousTeacherInstitute,
    required int? studyYear,
    required bool isProgrammingSubject,
    required String? programmingLanguage,
    required bool? labCompleted,
  }) async {
    // IMPORTANT:
    // Backend requires ProgrammingLanguage.
    // Never send null.
    final String languageValue = isProgrammingSubject
        ? (programmingLanguage?.trim() ?? '')
        : 'N/A';

    if (isProgrammingSubject && languageValue.isEmpty) {
      _showMessage(
        'Please enter the programming language.',
        isError: true,
      );
      return false;
    }

    final Map<String, dynamic> courseData = {
      'CourseId': courseId,
      'Grade': grade,
      'HourlyRate': hourlyRate,
      'Institute': institute,
      'PreviousTeacher': previousTeacher,
      'PreviousTeacherInstitute': previousTeacherInstitute,
      'StudyYear': studyYear,
      'IsProgrammingSubject': isProgrammingSubject,

      // Always a non-null string.
      'ProgrammingLanguage': languageValue,

      // Always a boolean.
      'LabCompleted': isProgrammingSubject
          ? (labCompleted ?? false)
          : false,
    };

    final Map<String, dynamic> requestBody = {
      'Courses': [courseData],
    };

    debugPrint('ADD COURSE REQUEST: ${jsonEncode(requestBody)}');

    try {
      final response = await ApiClient.post(
        '/api/Tutor/add-courses',
        requestBody,
      );

      debugPrint('ADD COURSE STATUS: ${response.statusCode}');
      debugPrint('ADD COURSE RESPONSE: ${response.body}');

      if (!mounted) return false;

      if (response.statusCode == 200) {
        _showMessage('Course added successfully!');

        await loadCourses(showLoader: false);

        return true;
      }

      if (response.statusCode == 401) {
        _showMessage(
          'Session expired. Please login again.',
          isError: true,
        );
        return false;
      }

      final message = ApiClient.messageFromBody(response.body);

      _showMessage(
        message ?? 'Unable to add course. Please try again.',
        isError: true,
      );

      return false;
    } catch (e) {
      debugPrint('ADD COURSE ERROR: $e');

      if (mounted) {
        _showMessage(
          'Network error. Please check your internet connection.',
          isError: true,
        );
      }

      return false;
    }
  }

  // ============================================================
  // ADD COURSE DETAILS DIALOG
  // ============================================================

  Future<void> _showCourseDetailsDialog(
    int courseId,
    String courseName,
  ) async {
    final gradeController = TextEditingController();
    final instituteController = TextEditingController();
    final previousTeacherController = TextEditingController();
    final previousTeacherInstituteController =
        TextEditingController();
    final studyYearController = TextEditingController();
    final rateController = TextEditingController();
    final languageController = TextEditingController();

    bool isProgrammingSubject = false;
    bool labCompleted = false;
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submitCourse() async {
              if (isSaving) return;

              final grade =
                  gradeController.text.trim().toUpperCase();

              final institute =
                  instituteController.text.trim();

              final previousTeacher =
                  previousTeacherController.text.trim();

              final previousTeacherInstitute =
                  previousTeacherInstituteController.text.trim();

              final studyYearText =
                  studyYearController.text.trim();

              final rate = double.tryParse(
                rateController.text.trim(),
              );

              final language =
                  languageController.text.trim();

              const validGrades = ['A', 'B', 'C', 'D', 'F'];

              if (!validGrades.contains(grade)) {
                _showMessage(
                  'Enter a valid grade: A, B, C, D or F.',
                  isError: true,
                );
                return;
              }

              if (institute.isEmpty || institute.length > 150) {
                _showMessage(
                  'Please enter a valid institute/university name.',
                  isError: true,
                );
                return;
              }

              if (previousTeacher.isEmpty ||
                  previousTeacher.length > 150) {
                _showMessage(
                  'Please enter the previous teacher name.',
                  isError: true,
                );
                return;
              }

              if (previousTeacherInstitute.isEmpty ||
                  previousTeacherInstitute.length > 150) {
                _showMessage(
                  'Please enter the previous teacher institute/university.',
                  isError: true,
                );
                return;
              }

              int? studyYear;

              if (studyYearText.isNotEmpty) {
                studyYear = int.tryParse(studyYearText);

                if (studyYear == null ||
                    studyYear < 1900 ||
                    studyYear > DateTime.now().year) {
                  _showMessage(
                    'Please enter a valid study year.',
                    isError: true,
                  );
                  return;
                }
              }

              if (rate == null || rate <= 0) {
                _showMessage(
                  'Please enter a valid hourly rate.',
                  isError: true,
                );
                return;
              }

              if (isProgrammingSubject && language.isEmpty) {
                _showMessage(
                  'Please enter the programming language.',
                  isError: true,
                );
                return;
              }

              if (isProgrammingSubject && language.length > 100) {
                _showMessage(
                  'Programming language cannot exceed 100 characters.',
                  isError: true,
                );
                return;
              }

              setDialogState(() {
                isSaving = true;
              });

              final success = await _addCourse(
                courseId: courseId,
                grade: grade,
                hourlyRate: rate,
                institute: institute,
                previousTeacher: previousTeacher,
                previousTeacherInstitute:
                    previousTeacherInstitute,
                studyYear: studyYear,
                isProgrammingSubject: isProgrammingSubject,
                programmingLanguage:
                    isProgrammingSubject ? language : 'N/A',
                labCompleted:
                    isProgrammingSubject ? labCompleted : false,
              );

              if (!dialogContext.mounted) return;

              if (success) {
                Navigator.pop(dialogContext);
              } else {
                setDialogState(() {
                  isSaving = false;
                });
              }
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Row(
                        children: [
                          _iconContainer(Icons.menu_book_rounded),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add Course Details',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Provide your academic information',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // SELECTED COURSE
                      _sectionHeading('Selected Course'),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(.08),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          courseName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // COURSE INFORMATION
                      _sectionHeading('Course Information'),

                      _fieldLabel('Academic Grade'),
                      _textField(
                        controller: gradeController,
                        hint: 'A, B, C, D or F',
                        icon: Icons.school_outlined,
                        maxLength: 1,
                        capitalization:
                            TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp('[a-zA-Z]'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      _fieldLabel('Institute / University'),
                      _textField(
                        controller: instituteController,
                        hint: 'e.g. COMSATS University',
                        icon: Icons.account_balance_outlined,
                        maxLength: 150,
                        capitalization: TextCapitalization.words,
                      ),

                      const SizedBox(height: 14),

                      _fieldLabel('Hourly Rate (PKR)'),
                      _textField(
                        controller: rateController,
                        hint: 'Enter your hourly rate',
                        icon: Icons.payments_outlined,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // PREVIOUS TEACHER
                      _sectionHeading(
                        'Previous Teacher Information',
                      ),

                      _fieldLabel('Teacher / Tutor Name'),
                      _textField(
                        controller: previousTeacherController,
                        hint: 'e.g. Sir Munir',
                        icon: Icons.person_outline,
                        maxLength: 150,
                        capitalization: TextCapitalization.words,
                      ),

                      const SizedBox(height: 14),

                      _fieldLabel(
                        'Teacher Institute / University',
                      ),
                      _textField(
                        controller:
                            previousTeacherInstituteController,
                        hint: 'e.g. COMSATS University',
                        icon: Icons.account_balance_outlined,
                        maxLength: 150,
                        capitalization: TextCapitalization.words,
                      ),

                      const SizedBox(height: 14),

                      _fieldLabel('Study Year'),
                      _textField(
                        controller: studyYearController,
                        hint: 'e.g. 2025',
                        icon: Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // PROGRAMMING INFORMATION
                      _sectionHeading('Programming Information'),

                      _checkboxCard(
                        title: 'Programming Subject',
                        subtitle:
                            'Enable this if the course involves programming.',
                        value: isProgrammingSubject,
                        onChanged: isSaving
                            ? null
                            : (value) {
                                setDialogState(() {
                                  isProgrammingSubject =
                                      value ?? false;

                                  if (!isProgrammingSubject) {
                                    languageController.clear();
                                    labCompleted = false;
                                  }
                                });
                              },
                      ),

                      if (isProgrammingSubject) ...[
                        const SizedBox(height: 14),

                        _fieldLabel('Programming Language'),
                        _textField(
                          controller: languageController,
                          hint: 'Java, C++, Python, etc.',
                          icon: Icons.code_rounded,
                          maxLength: 100,
                          capitalization: TextCapitalization.words,
                        ),

                        const SizedBox(height: 12),

                        _checkboxCard(
                          title: 'Lab Completed / Attended',
                          subtitle: labCompleted
                              ? 'You have completed or attended the lab.'
                              : 'You have not completed or attended the lab.',
                          value: labCompleted,
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    labCompleted = value ?? false;
                                  });
                                },
                        ),
                      ],

                      const SizedBox(height: 22),

                      // ACTION BUTTONS
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(49),
                                foregroundColor: textColor,
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSaving ? null : submitCourse,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size.fromHeight(49),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Save Course',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    gradeController.dispose();
    instituteController.dispose();
    previousTeacherController.dispose();
    previousTeacherInstituteController.dispose();
    studyYearController.dispose();
    rateController.dispose();
    languageController.dispose();
  }

  // ============================================================
  // AVAILABLE COURSES DIALOG
  // ============================================================

  Future<void> _showAvailableCourses() async {
    final searchController = TextEditingController();

    List<Map<String, dynamic>> filteredCourses = [
      ...availableCourses,
    ];

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            void filterCourses(String value) {
              final query = value.trim().toLowerCase();

              setDialogState(() {
                filteredCourses = availableCourses.where((course) {
                  final name = _toString(
                    course['course_name'],
                  ).toLowerCase();

                  return name.contains(query);
                }).toList();
              });
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 30,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 480,
                  maxHeight: 650,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Available Courses',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Select a course you want to teach.',
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: searchController,
                        onChanged: filterCourses,
                        decoration: InputDecoration(
                          hintText: 'Search course name...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: primaryColor,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F7F9),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        '${filteredCourses.length} courses available',
                        style: const TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Flexible(
                        child: filteredCourses.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(30),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.search_off_rounded,
                                        size: 45,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'No courses found.',
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filteredCourses.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 9),
                                itemBuilder: (context, index) {
                                  final course = filteredCourses[index];

                                  final id = _toInt(
                                    course['course_id'],
                                  );

                                  final name = _toString(
                                    course['course_name'],
                                  );

                                  return Material(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(13),
                                    child: InkWell(
                                      borderRadius:
                                          BorderRadius.circular(13),
                                      onTap: id <= 0
                                          ? null
                                          : () {
                                              Navigator.pop(
                                                dialogContext,
                                              );

                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                if (mounted) {
                                                  _showCourseDetailsDialog(
                                                    id,
                                                    name,
                                                  );
                                                }
                                              });
                                            },
                                      child: Container(
                                        padding: const EdgeInsets.all(13),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(13),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            _iconContainer(
                                              Icons.menu_book_rounded,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                name,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: textColor,
                                                ),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 15,
                                              color: primaryColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();
  }

  // ============================================================
  // REUSABLE UI WIDGETS
  // ============================================================

  Widget _iconContainer(IconData icon) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: primaryColor,
        size: 23,
      ),
    );
  }

  Widget _sectionHeading(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style: const TextStyle(
        color: textColor,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 12,
        ),
        counterText: '',
        prefixIcon: Icon(
          icon,
          color: primaryColor,
          size: 20,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Fixed Material / ListTile ink warning.
  Widget _checkboxCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?>? onChanged,
  }) {
    return Material(
      color: const Color(0xFFF7F9FA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: CheckboxListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 5,
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: primaryColor,
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: secondaryTextColor,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GRADE BADGE
  // ============================================================

  Widget _gradeBadge(String grade) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(.09),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        'Grade ${grade.isEmpty ? '-' : grade}',
        style: const TextStyle(
          color: primaryColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // VERIFICATION BADGE
  // ============================================================

  Widget _verificationBadge(String status) {
    final value = status.isEmpty ? 'Pending' : status;

    Color color;
    IconData icon;

    switch (value.toLowerCase()) {
      case 'verified':
      case 'approved':
        color = const Color(0xFF239B69);
        icon = Icons.verified_rounded;
        break;

      case 'rejected':
        color = const Color(0xFFD94B4B);
        icon = Icons.cancel_outlined;
        break;

      default:
        color = const Color(0xFFD28A26);
        icon = Icons.pending_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  Widget _informationRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: secondaryTextColor,
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 125,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF56646B),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(
                fontSize: 12,
                color: secondaryTextColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMATION SECTION
  // ============================================================

  Widget _informationSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEAF0F2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // COURSE CARD
  // ============================================================

  Widget _courseCard(Map<String, dynamic> course) {
    final name = _toString(course['course_name']);
    final grade = _toString(course['grade']);
    final institute = _toString(course['institute']);
    final rate = _toDouble(course['hourly_rate']);

    final previousTeacher =
        _toString(course['previous_teacher']);

    final previousTeacherInstitute =
        _toString(course['previous_teacher_institute']);

    final studyYear = _toString(course['study_year']);

    final isProgramming =
        _toBool(course['is_programming_subject']);

    final language =
        _toString(course['programming_language']);

    final labValue = course['lab_completed'];

    final labStatus = labValue == null
        ? 'Not provided'
        : _toBool(labValue)
            ? 'Completed'
            : 'Not completed';

    final verificationStatus =
        _toString(course['grade_verification_status']);

    final verifiedBy = _toString(course['verified_by']);

    final verifiedDate = _formatDate(course['verified_date']);

    final remarks =
        _toString(course['verification_remarks']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE9EEF0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COURSE HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _iconContainer(Icons.menu_book_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Course' : name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Rs. ${rate.toStringAsFixed(rate % 1 == 0 ? 0 : 2)} / hour',
                      style: const TextStyle(
                        fontSize: 13,
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _gradeBadge(grade),
            ],
          ),

          const SizedBox(height: 15),
          Divider(height: 1, color: Colors.grey.shade200),

          // COURSE INFORMATION
          _informationSection(
            title: 'Course Information',
            icon: Icons.menu_book_outlined,
            children: [
              _informationRow(
                icon: Icons.school_outlined,
                title: 'Academic Grade',
                value: _displayValue(grade),
              ),
              _informationRow(
                icon: Icons.account_balance_outlined,
                title: 'Institute / University',
                value: _displayValue(institute),
              ),
              _informationRow(
                icon: Icons.payments_outlined,
                title: 'Hourly Rate',
                value:
                    'Rs. ${rate.toStringAsFixed(rate % 1 == 0 ? 0 : 2)}',
              ),
            ],
          ),

          // PREVIOUS TEACHER INFORMATION
          _informationSection(
            title: 'Previous Teacher Information',
            icon: Icons.person_outline,
            children: [
              _informationRow(
                icon: Icons.person,
                title: 'Teacher Name',
                value: _displayValue(previousTeacher),
              ),
              _informationRow(
                icon: Icons.account_balance_outlined,
                title: 'Institute / University',
                value: _displayValue(previousTeacherInstitute),
              ),
              _informationRow(
                icon: Icons.calendar_today_outlined,
                title: 'Study Year',
                value: _displayValue(studyYear),
              ),
            ],
          ),

          // PROGRAMMING INFORMATION
          _informationSection(
            title: 'Programming Information',
            icon: Icons.code_rounded,
            children: [
              _informationRow(
                icon: Icons.check_circle_outline,
                title: 'Programming Subject',
                value: isProgramming ? 'Yes' : 'No',
              ),
              if (isProgramming) ...[
                _informationRow(
                  icon: Icons.terminal_rounded,
                  title: 'Programming Language',
                  value: _displayValue(language),
                ),
                _informationRow(
                  icon: Icons.science_outlined,
                  title: 'Lab Status',
                  value: labStatus,
                ),
              ],
            ],
          ),

          // GRADE VERIFICATION
          _informationSection(
            title: 'Grade Verification',
            icon: Icons.verified_user_outlined,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Verification Status',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF56646B),
                        ),
                      ),
                    ),
                    _verificationBadge(verificationStatus),
                  ],
                ),
              ),
              _informationRow(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Verified By',
                value: _displayValue(verifiedBy),
              ),
              _informationRow(
                icon: Icons.calendar_month_outlined,
                title: 'Verified Date',
                value: _displayValue(verifiedDate),
              ),

              if (remarks.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8EA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFF5E5C4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            size: 15,
                            color: Color(0xFF91651F),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Verification Remarks',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF91651F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        remarks,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF91651F),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyCourses() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 75),
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'No Courses Added Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 35),
          child: Text(
            'Start building your teaching profile by adding the courses you can teach.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 25),
        Center(
          child: ElevatedButton.icon(
            onPressed: _showAvailableCourses,
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Course'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? const Color(0xFFD94B4B) : primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(14),
        ),
      );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: textColor),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 27,
            errorBuilder: (_, __, ___) {
              return const Icon(
                Icons.school_rounded,
                color: primaryColor,
                size: 25,
              );
            },
          ),
          const SizedBox(width: 8),
          const Text(
            'House of Tutor',
            style: TextStyle(
              color: primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      drawer: const TutorDrawer(),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : RefreshIndicator(
              color: primaryColor,
              onRefresh: () => loadCourses(showLoader: false),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PAGE HEADING
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Courses',
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Manage the subjects you teach.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(.09),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${myCourses.length}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const Text(
                                'Courses',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // SECTION HEADING
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 19,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Expanded(
                          child: Text(
                            'Your Teaching Subjects',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        Text(
                          '${myCourses.length} total',
                          style: const TextStyle(
                            fontSize: 11,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // COURSE LIST
                    Expanded(
                      child: myCourses.isEmpty
                          ? _emptyCourses()
                          : ListView.separated(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                bottom: 100,
                              ),
                              itemCount: myCourses.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 13),
                              itemBuilder: (context, index) {
                                return _courseCard(myCourses[index]);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : _showAvailableCourses,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Course',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
