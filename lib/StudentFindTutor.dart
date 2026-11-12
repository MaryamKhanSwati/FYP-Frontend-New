
import 'package:flutter/material.dart';
import 'package:house_of_tutor/services/api_client.dart';
import 'package:house_of_tutor/services/auth_store.dart';

class StudentFindTutor extends StatefulWidget {
  final int courseId;
  final String courseName;
  final double? userLat;
  final double? userLng;

  const StudentFindTutor({
    super.key,
    required this.courseId,
    required this.courseName,
    this.userLat,
    this.userLng,
  });

  @override
  State<StudentFindTutor> createState() => _StudentFindTutorState();
}

class _StudentFindTutorState extends State<StudentFindTutor> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryColor = Color(0xFF1E8E7E);
  static const Color darkPrimaryColor = Color(0xFF176B60);
  static const Color backgroundColor = Color(0xFFF4F6F8);

  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = true;
  bool isSubmitting = false;

  List<dynamic> tutorsList = [];
  List<dynamic> filteredTutors = [];

  String errorMessage = '';
  String sortBy = 'feedback';

  final TextEditingController searchController =
      TextEditingController();

  // Separate controllers are IMPORTANT.
  // Learning duration: Hours / Days / Weeks.
  final TextEditingController learningDurationController =
      TextEditingController();

  // Accelerated course duration: Weeks.
  final TextEditingController acceleratedWeeksController =
      TextEditingController();

  // Accelerated classes per week.
  final TextEditingController classesPerWeekController =
      TextEditingController();

  final Set<int> selectedTutorIds = {};

  String? selectedDay;
  String? selectedTime;

  String learningMode = 'SpecificTime';
  String learningDurationUnit = 'Hours';

  String planType = 'Normal';

  DateTime startDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    searchController.addListener(_filterTutors);

    fetchTutors();
  }

  @override
  void dispose() {
    searchController.dispose();
    learningDurationController.dispose();
    acceleratedWeeksController.dispose();
    classesPerWeekController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOCATION
  // ============================================================

  bool _isValidLatitude(double value) =>
      value >= -90 && value <= 90;

  bool _isValidLongitude(double value) =>
      value >= -180 && value <= 180;

  Future<Map<String, double>?> _getUserLocation() async {
    if (widget.userLat != null &&
        widget.userLng != null &&
        _isValidLatitude(widget.userLat!) &&
        _isValidLongitude(widget.userLng!)) {
      return {
        'latitude': widget.userLat!,
        'longitude': widget.userLng!,
      };
    }

    await AuthStore.instance.hydrate();

    final lat = AuthStore.instance.lastLat;
    final lng = AuthStore.instance.lastLng;

    if (lat == null || lng == null) return null;

    if (!_isValidLatitude(lat) ||
        !_isValidLongitude(lng)) {
      return null;
    }

    return {
      'latitude': lat,
      'longitude': lng,
    };
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _displayValue(
    dynamic value, [
    String fallback = 'Not provided',
  ]) {
    if (value == null) return fallback;

    final result = value.toString().trim();

    if (result.isEmpty || result.toLowerCase() == 'null') {
      return fallback;
    }

    return result;
  }

  dynamic _firstValue(Map item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString().trim() ?? '') ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString().trim() ?? '') ?? 0;
  }

  int? _toIntNullable(dynamic value) {
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString().trim() ?? '');
  }

  bool _toBool(dynamic value) {
    if (value == true) return true;
    if (value == false || value == null) return false;

    return value.toString().toLowerCase() == 'true' ||
        value.toString() == '1';
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // ============================================================
  // TUTOR INFORMATION
  // ============================================================

  int? _getTutorId(dynamic tutor) {
    if (tutor is! Map) return null;

    return _toIntNullable(
      _firstValue(tutor, [
        'tutor_id',
        'tutorId',
        'id',
      ]),
    );
  }

  String _getTutorName(dynamic tutor) {
    if (tutor is! Map) return 'Tutor';

    return _displayValue(
      _firstValue(tutor, [
        'tutor_name',
        'tutorName',
        'name',
        'full_name',
        'fullName',
      ]),
      'Tutor',
    );
  }

  String _getInstitute(dynamic tutor) {
    if (tutor is! Map) return 'Not provided';

    return _displayValue(
      _firstValue(tutor, ['institute', 'Institute']),
    );
  }

  String _getGrade(dynamic tutor) {
    if (tutor is! Map) return 'Not provided';

    return _displayValue(
      _firstValue(tutor, ['grade', 'Grade']),
    );
  }

  String _getHourlyPrice(dynamic tutor) {
    if (tutor is! Map) return 'Not provided';

    final value = _firstValue(tutor, [
      'hourly_rate',
      'hourlyRate',
    ]);

    if (value == null) return 'Not provided';

    final amount = double.tryParse(value.toString());

    if (amount == null) return 'Not provided';

    final formatted = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);

    return 'Rs. $formatted / hour';
  }

  double _getRating(dynamic tutor) {
    if (tutor is! Map) return 0;

    return _toDouble(
      _firstValue(tutor, [
        'average_rating',
        'averageRating',
      ]),
    );
  }

  int _getReviewCount(dynamic tutor) {
    if (tutor is! Map) return 0;

    return _toInt(
      _firstValue(tutor, [
        'total_reviews',
        'totalReviews',
      ]),
    );
  }

  // ============================================================
  // PREVIOUS TEACHERS
  // Backend: previous_teachers
  // ============================================================

  List<dynamic> _getPreviousTeachers(dynamic tutor) {
    if (tutor is! Map) return [];

    final data = tutor['previous_teachers'];

    return data is List ? data : [];
  }

  // ============================================================
  // PROGRAMMING LANGUAGES
  // Backend: programming_languages
  // ============================================================

  List<dynamic> _getProgrammingLanguages(dynamic tutor) {
    if (tutor is! Map) return [];

    final data = tutor['programming_languages'];

    return data is List ? data : [];
  }

  // ============================================================
  // LAB INFORMATION
  // Backend: lab_completed
  // ============================================================

  bool _getLabCompleted(dynamic tutor) {
    if (tutor is! Map) return false;

    return _toBool(tutor['lab_completed']);
  }

  // ============================================================
  // AVAILABLE SLOTS
  // Backend: common_slots
  // ============================================================

  List<dynamic> _getSlots(dynamic tutor) {
    if (tutor is! Map) return [];

    final rawSlots = tutor['common_slots'];

    if (rawSlots is! List) return [];

    return rawSlots.where((slot) {
      if (slot is! Map) return false;

      final day = slot['day']?.toString().trim() ?? '';
      final time = slot['time']?.toString().trim() ?? '';

      return _toBool(slot['is_available']) &&
          day.isNotEmpty &&
          time.isNotEmpty;
    }).toList();
  }

  bool _hasSelectedSlot(dynamic tutor) {
    if (selectedDay == null || selectedTime == null) {
      return false;
    }

    return _getSlots(tutor).any((slot) {
      return slot['day']
                  .toString()
                  .trim()
                  .toLowerCase() ==
              selectedDay!.trim().toLowerCase() &&
          slot['time']
                  .toString()
                  .trim()
                  .toLowerCase() ==
              selectedTime!.trim().toLowerCase();
    });
  }

  // ============================================================
  // FETCH VISITING TUTORS
  // Backend:
  // GET search-by-time-location-visiting-tutor
  // ============================================================

  Future<void> fetchTutors() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final location = await _getUserLocation();

      if (location == null) {
        throw Exception(
          'Your location is not available. Please update your location and try again.',
        );
      }

      final userLat = location['latitude']!;
      final userLng = location['longitude']!;

      final endpoint =
          '/api/Student/search-by-time-location-visiting-tutor'
          '?userLat=$userLat'
          '&userLng=$userLng'
          '&courseId=${widget.courseId}'
          '&sortBy=$sortBy';

      debugPrint('====================================');
      debugPrint('VISITING TUTOR SEARCH');
      debugPrint('URL: $endpoint');
      debugPrint('====================================');

      final response = await ApiClient.get(endpoint);

      debugPrint('Search Status: ${response.statusCode}');
      debugPrint('Search Response: ${response.body}');

      if (!mounted) return;

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final data = await ApiClient.decodeJson(response);

        List<dynamic> tutors = [];

        // Backend response:
        // {
        //   sort_by: "...",
        //   course_id: 1,
        //   teaching_mode: "Visiting",
        //   total_tutors: 5,
        //   tutors: [...]
        // }

        if (data is Map) {
          final rawTutors = data['tutors'];

          if (rawTutors is List) {
            tutors = rawTutors;
          }
        } else if (data is List) {
          tutors = data;
        }

        setState(() {
          tutorsList = tutors;
          filteredTutors = List.from(tutors);
          errorMessage = '';
          isLoading = false;
        });

        _filterTutors();
      } else {
        final data = await ApiClient.decodeJson(response);

        final message = data is Map
            ? _displayValue(
                data['message'],
                'No tutors available.',
              )
            : ApiClient.messageFromBody(response.body) ??
                'No tutors available.';

        setState(() {
          tutorsList = [];
          filteredTutors = [];
          errorMessage = message;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('StudentFindTutor Error: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        tutorsList = [];
        filteredTutors = [];
        errorMessage = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // SEARCH FILTER
  // ============================================================

  void _filterTutors() {
    if (!mounted) return;

    final query = searchController.text.trim().toLowerCase();

    final results = tutorsList.where((tutor) {
      final name = _getTutorName(tutor).toLowerCase();

      final institute = _getInstitute(tutor).toLowerCase();

      return name.contains(query) ||
          institute.contains(query);
    }).toList();

    setState(() {
      filteredTutors = results;
    });
  }

  // ============================================================
  // SORTING
  // ============================================================

  void _changeSort(String? value) {
    if (value == null || value == sortBy) return;

    setState(() {
      sortBy = value;

      selectedTutorIds.clear();
      selectedDay = null;
      selectedTime = null;
    });

    fetchTutors();
  }

  // ============================================================
  // SLOT SELECTION
  // ============================================================

  void _selectSlot(String day, String time) {
    setState(() {
      if (selectedDay != day || selectedTime != time) {
        selectedTutorIds.clear();
      }

      selectedDay = day;
      selectedTime = time;
    });
  }

  // ============================================================
  // TUTOR SELECTION
  // ============================================================

  void _toggleTutorSelection(int tutorId) {
    setState(() {
      if (selectedTutorIds.contains(tutorId)) {
        selectedTutorIds.remove(tutorId);
      } else {
        selectedTutorIds.add(tutorId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      selectedTutorIds.clear();
      selectedDay = null;
      selectedTime = null;
    });
  }

  // ============================================================
  // CREATE REQUEST
  // Backend: POST create-request
  // ============================================================

  Future<void> bookClassRequest() async {
    if (selectedDay == null || selectedTime == null) {
      _showError('Please select an available day and time.');
      return;
    }

    if (selectedTutorIds.isEmpty) {
      _showError('Please select at least one tutor.');
      return;
    }

    // ----------------------------------------------------------
    // LEARNING DURATION VALIDATION
    // ----------------------------------------------------------

    int? learningDuration;

    if (learningMode == 'SpecificTime') {
      learningDuration = int.tryParse(
        learningDurationController.text.trim(),
      );

      if (learningDuration == null || learningDuration <= 0) {
        _showError('Enter a valid learning duration.');
        return;
      }

      if (!['Hours', 'Days', 'Weeks']
          .contains(learningDurationUnit)) {
        _showError('Please select a valid duration unit.');
        return;
      }
    }

    // ----------------------------------------------------------
    // ACCELERATED PLAN VALIDATION
    // ----------------------------------------------------------

    int? requestedWeeks;
    int? requestedClasses;

    if (planType == 'Accelerated') {
      requestedWeeks = int.tryParse(
        acceleratedWeeksController.text.trim(),
      );

      requestedClasses = int.tryParse(
        classesPerWeekController.text.trim(),
      );

      if (requestedWeeks == null || requestedWeeks <= 0) {
        _showError(
          'Enter a valid accelerated course duration in weeks.',
        );
        return;
      }

      if (requestedClasses == null || requestedClasses <= 0) {
        _showError('Enter valid classes per week.');
        return;
      }
    }

    if (!mounted) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      // --------------------------------------------------------
      // EXACT BACKEND PAYLOAD
      // --------------------------------------------------------

      final requestBody = <String, dynamic>{
        'tutor_ids': selectedTutorIds.toList(),

        'course_id': widget.courseId,

        'day': selectedDay,

        'time': selectedTime!.trim(),

        // Learning mode
        'learning_mode': learningMode,

        'learning_duration':
            learningMode == 'SpecificTime'
                ? learningDuration
                : null,

        'learning_duration_unit':
            learningMode == 'SpecificTime'
                ? learningDurationUnit
                : null,

        // Course plan
        'plan_type': planType,

        'requested_duration_weeks':
            planType == 'Accelerated'
                ? requestedWeeks
                : null,

        'requested_classes_per_week':
            planType == 'Accelerated'
                ? requestedClasses
                : null,

        // Course start date
        'start_date': _formatDate(startDate),
      };

      debugPrint('====================================');
      debugPrint('CREATE TUTOR REQUEST');
      debugPrint('Request Body: $requestBody');
      debugPrint('====================================');

      final response = await ApiClient.post(
        '/api/Student/create-request',
        requestBody,
      );

      debugPrint('Create Status: ${response.statusCode}');
      debugPrint('Create Response: ${response.body}');

      final data = await ApiClient.decodeJson(response);

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        // Clear previous selection after success.
        setState(() {
          selectedTutorIds.clear();
          selectedDay = null;
          selectedTime = null;

          learningDurationController.clear();
          acceleratedWeeksController.clear();
          classesPerWeekController.clear();
        });

        _showSuccessDialog(
          data is Map
              ? _displayValue(
                  data['message'],
                  'Tutor request created successfully.',
                )
              : 'Tutor request created successfully.',
          data,
        );
      } else {
        final message = data is Map
            ? _displayValue(
                data['message'] ?? data['error'],
                'Failed to create tutor request.',
              )
            : ApiClient.messageFromBody(response.body) ??
                'Failed to create tutor request.';

        _showError(message);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      _showError('Error creating request: $e');
    }
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  void _showSuccessDialog(String message, dynamic data) {
    final requestGroupId =
        data is Map ? data['request_group_id'] : null;

    final requestId =
        data is Map ? data['request_id'] : null;

    final totalTutors =
        data is Map ? data['total_tutors'] : null;

    final plan =
        data is Map ? data['plan_type'] : planType;

    final deadline =
        data is Map ? data['response_deadline'] : null;

    final originalWeeks =
        data is Map ? data['original_duration_weeks'] : null;

    final originalClasses =
        data is Map ? data['original_classes_per_week'] : null;

    final requestedWeeks =
        data is Map ? data['requested_duration_weeks'] : null;

    final requestedClasses =
        data is Map ? data['requested_classes_per_week'] : null;

    final totalClasses =
        data is Map ? data['total_classes'] : null;

    final responseStartDate =
        data is Map ? data['start_date'] : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: primaryColor,
                  size: 65,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Request Submitted!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),

                if (requestGroupId != null)
                  _successDetail(
                    'Request Group',
                    '#$requestGroupId',
                  ),

                if (requestId != null)
                  _successDetail(
                    'Request ID',
                    '$requestId',
                  ),

                if (totalTutors != null)
                  _successDetail(
                    'Selected Tutors',
                    '$totalTutors',
                  ),

                _successDetail('Course Plan', '$plan'),

                if (originalWeeks != null)
                  _successDetail(
                    'Original Duration',
                    '$originalWeeks weeks',
                  ),

                if (originalClasses != null)
                  _successDetail(
                    'Original Classes/Week',
                    '$originalClasses',
                  ),

                if (requestedWeeks != null)
                  _successDetail(
                    'Requested Duration',
                    '$requestedWeeks weeks',
                  ),

                if (requestedClasses != null)
                  _successDetail(
                    'Requested Classes/Week',
                    '$requestedClasses',
                  ),

                if (totalClasses != null)
                  _successDetail(
                    'Total Course Classes',
                    '$totalClasses',
                  ),

                if (responseStartDate != null)
                  _successDetail(
                    'Start Date',
                    '$responseStartDate',
                  ),

                if (deadline != null)
                  _successDetail(
                    'Response Deadline',
                    '$deadline',
                  ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'The first tutor receives the request first. '
                    'They have 2 minutes to respond before the queue can proceed.',
                    style: TextStyle(
                      fontSize: 12,
                      color: darkPrimaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                style: _primaryButtonStyle(),
                child: const Text('Done'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _successDetail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOOKING / CONFIRMATION DIALOG
  // ============================================================

  void _showBookingDialog() {
    if (selectedDay == null ||
        selectedTime == null ||
        selectedTutorIds.isEmpty) {
      _showError('Select a time slot and tutor first.');
      return;
    }

    String dialogLearningMode = learningMode;
    String dialogDurationUnit = learningDurationUnit;
    String dialogPlanType = planType;

    // IMPORTANT:
    // These are separate controllers.
    final learningDurationDialog = TextEditingController(
      text: learningDurationController.text,
    );

    final acceleratedWeeksDialog = TextEditingController(
      text: acceleratedWeeksController.text,
    );

    final classesDialog = TextEditingController(
      text: classesPerWeekController.text,
    );

    DateTime dialogStartDate = startDate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Confirm Tutor Request',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ------------------------------------------------
                      // SELECTED TUTORS
                      // ------------------------------------------------

                      _dialogSectionTitle('Selected Tutors'),

                      _dialogInfo(
                        Icons.people_outline,
                        '${selectedTutorIds.length} tutor(s) selected',
                      ),

                      const SizedBox(height: 16),

                      // ------------------------------------------------
                      // SELECTED TIME
                      // ------------------------------------------------

                      _dialogSectionTitle('Selected Time'),

                      _dialogInfo(
                        Icons.calendar_month,
                        '$selectedDay - $selectedTime',
                      ),

                      const SizedBox(height: 18),

                      // ------------------------------------------------
                      // COURSE PLAN
                      // ------------------------------------------------

                      _dialogSectionTitle(
                        'Course Completion Plan',
                      ),

                      const SizedBox(height: 8),

                      DropdownButtonFormField<String>(
                        value: dialogPlanType,
                        isExpanded: true,
                        decoration: _inputDecoration(
                          'Select course plan',
                          Icons.menu_book_outlined,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Normal',
                            child: Text('Normal Plan'),
                          ),
                          DropdownMenuItem(
                            value: 'Accelerated',
                            child: Text(
                              'Accelerated / Fast Track',
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            dialogPlanType = value;
                          });
                        },
                      ),

                      // ------------------------------------------------
                      // ACCELERATED COURSE FIELDS
                      // ------------------------------------------------

                      if (dialogPlanType == 'Accelerated') ...[
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Fast Track: Total classes must remain equal '
                            'to the original course plan configured by Admin.',
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: acceleratedWeeksDialog,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            'Requested duration (weeks)',
                            Icons.calendar_today,
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: classesDialog,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            'Classes per week',
                            Icons.event_available,
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // ------------------------------------------------
                      // START DATE
                      // ------------------------------------------------

                      _dialogSectionTitle('Course Start Date'),

                      const SizedBox(height: 8),

                      InkWell(
                        onTap: () async {
                          final now = DateTime.now();

                          final selected = await showDatePicker(
                            context: dialogContext,
                            initialDate:
                                dialogStartDate.isBefore(now)
                                    ? DateTime(
                                        now.year,
                                        now.month,
                                        now.day,
                                      )
                                    : dialogStartDate,
                            firstDate: DateTime(
                              now.year,
                              now.month,
                              now.day,
                            ),
                            lastDate: DateTime(2100),
                          );

                          if (selected != null) {
                            setDialogState(() {
                              dialogStartDate = selected;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.date_range,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _formatDate(dialogStartDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ------------------------------------------------
                      // LEARNING MODE
                      // ------------------------------------------------

                      _dialogSectionTitle('Learning Mode'),

                      const SizedBox(height: 8),

                      DropdownButtonFormField<String>(
                        value: dialogLearningMode,
                        isExpanded: true,
                        decoration: _inputDecoration(
                          'Learning mode',
                          Icons.access_time,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'SpecificTime',
                            child: Text('Specific Time'),
                          ),
                          DropdownMenuItem(
                            value: 'FullTime',
                            child: Text('Full Time'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            dialogLearningMode = value;
                          });
                        },
                      ),

                      // ------------------------------------------------
                      // LEARNING DURATION
                      // ------------------------------------------------

                      if (dialogLearningMode == 'SpecificTime') ...[
                        const SizedBox(height: 12),

                        TextField(
                          controller: learningDurationDialog,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            'Learning duration',
                            Icons.timelapse,
                          ),
                        ),

                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value: dialogDurationUnit,
                          isExpanded: true,
                          decoration: _inputDecoration(
                            'Duration unit',
                            Icons.schedule,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Hours',
                              child: Text('Hours'),
                            ),
                            DropdownMenuItem(
                              value: 'Days',
                              child: Text('Days'),
                            ),
                            DropdownMenuItem(
                              value: 'Weeks',
                              child: Text('Weeks'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setDialogState(() {
                              dialogDurationUnit = value;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          // ------------------------------------------
                          // SAVE DIALOG VALUES
                          // ------------------------------------------

                          learningMode = dialogLearningMode;

                          learningDurationUnit =
                              dialogDurationUnit;

                          planType = dialogPlanType;

                          startDate = dialogStartDate;

                          // Learning duration is independent.
                          if (learningMode == 'SpecificTime') {
                            learningDurationController.text =
                                learningDurationDialog.text.trim();
                          } else {
                            learningDurationController.clear();
                          }

                          // Accelerated course duration.
                          if (planType == 'Accelerated') {
                            acceleratedWeeksController.text =
                                acceleratedWeeksDialog.text.trim();

                            classesPerWeekController.text =
                                classesDialog.text.trim();
                          } else {
                            acceleratedWeeksController.clear();
                            classesPerWeekController.clear();
                          }

                          Navigator.pop(dialogContext);

                          await bookClassRequest();
                        },
                  style: _primaryButtonStyle(),
                  child: const Text('Send Request'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      learningDurationDialog.dispose();
      acceleratedWeeksDialog.dispose();
      classesDialog.dispose();
    });
  }

  Widget _dialogSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }

  Widget _dialogInfo(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: darkPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 19),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
    );
  }

  // ============================================================
  // BUTTON STYLE
  // ============================================================

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // MAIN SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'FIND YOUR TUTOR',
              style: TextStyle(
                color: primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.courseName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ------------------------------------------------------
          // SEARCH AND SORTING
          // ------------------------------------------------------

          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 15),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tutor by name...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(
                      Icons.sort,
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Sort by:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: sortBy,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          filled: true,
                          fillColor: backgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'feedback',
                            child: Text('Feedback'),
                          ),
                          DropdownMenuItem(
                            value: 'institute',
                            child: Text('Institute'),
                          ),
                          DropdownMenuItem(
                            value: 'grade',
                            child: Text('Grade'),
                          ),
                          DropdownMenuItem(
                            value: 'fee',
                            child: Text('Lowest Fee'),
                          ),
                        ],
                        onChanged: _changeSort,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ------------------------------------------------------
          // SELECTED SLOT
          // ------------------------------------------------------

          if (selectedDay != null && selectedTime != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.teal.shade100,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_available,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected Common Slot',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkPrimaryColor,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '$selectedDay | $selectedTime',
                          style: const TextStyle(
                            fontSize: 12,
                            color: darkPrimaryColor,
                          ),
                        ),
                        Text(
                          '${selectedTutorIds.length} tutor(s) selected',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _clearSelection,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),

          // ------------------------------------------------------
          // INSTRUCTIONS
          // ------------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 17,
                  color: Colors.grey,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    selectedDay == null
                        ? 'First select a common available time slot, then select tutors offering that slot.'
                        : 'Now select tutors who offer the selected time slot.',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------------
          // TUTORS LIST
          // ------------------------------------------------------

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  )
                : filteredTutors.isEmpty
                    ? _buildEmptyView()
                    : RefreshIndicator(
                        color: primaryColor,
                        onRefresh: fetchTutors,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            20,
                          ),
                          itemCount: filteredTutors.length,
                          itemBuilder: (context, index) {
                            return _buildTutorCard(
                              filteredTutors[index],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),

      // --------------------------------------------------------
      // BOTTOM REQUEST BUTTON
      // --------------------------------------------------------

      bottomNavigationBar: selectedTutorIds.isNotEmpty
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed:
                      isSubmitting ? null : _showBookingDialog,
                  icon: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    isSubmitting
                        ? 'Sending Request...'
                        : 'Continue with ${selectedTutorIds.length} Tutor(s)',
                  ),
                  style: _primaryButtonStyle(),
                ),
              ),
            )
          : null,
    );
  }

  // ============================================================
  // EMPTY / ERROR VIEW
  // ============================================================

  Widget _buildEmptyView() {
    final hasError = errorMessage.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasError
                  ? Icons.location_off_outlined
                  : Icons.person_search_outlined,
              size: 65,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 15),
            Text(
              hasError ? errorMessage : 'No tutors found.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: fetchTutors,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: _primaryButtonStyle(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TUTOR CARD
  // ============================================================

  Widget _buildTutorCard(dynamic tutor) {
    if (tutor is! Map) {
      return const SizedBox.shrink();
    }

    final tutorId = _getTutorId(tutor);
    final tutorName = _getTutorName(tutor);

    final initials = tutorName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0])
        .take(2)
        .join()
        .toUpperCase();

    final rating = _getRating(tutor);
    final reviews = _getReviewCount(tutor);
    final distance = _toDouble(tutor['distance']);

    final grade = _getGrade(tutor);
    final institute = _getInstitute(tutor);
    final price = _getHourlyPrice(tutor);

    final location = _displayValue(
      tutor['location'],
      'Location unavailable',
    );

    final slots = _getSlots(tutor);

    final hasSelectedSlot = _hasSelectedSlot(tutor);

    final isSelected =
        tutorId != null && selectedTutorIds.contains(tutorId);

    final canSelect =
        selectedDay != null && hasSelectedSlot;

    final teachers = _getPreviousTeachers(tutor);
    final languages = _getProgrammingLanguages(tutor);
    final labCompleted = _getLabCompleted(tutor);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: isSelected
              ? primaryColor
              : Colors.grey.shade200,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // TUTOR HEADING
          // ------------------------------------------------------

          Row(
            children: [
              Checkbox(
                value: isSelected,
                activeColor: primaryColor,
                onChanged: canSelect && tutorId != null
                    ? (_) => _toggleTutorSelection(tutorId)
                    : null,
              ),
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(
                    initials.isEmpty ? 'T' : initials,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tutorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${rating.toStringAsFixed(1)} ($reviews reviews)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (isSelected)
            _statusLabel(
              'Tutor selected',
              Icons.check_circle,
              Colors.teal,
            ),

          const SizedBox(height: 14),

          // ------------------------------------------------------
          // LOCATION
          // ------------------------------------------------------

          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 17,
                color: primaryColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
              const Icon(
                Icons.near_me_outlined,
                size: 15,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                '${distance.toStringAsFixed(2)} km',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ------------------------------------------------------
          // BASIC INFORMATION
          // ------------------------------------------------------

          _buildDetailRow(
            Icons.school_outlined,
            'Grade',
            grade,
          ),

          _buildDetailRow(
            Icons.account_balance_outlined,
            'Institute',
            institute,
          ),

          _buildDetailRow(
            Icons.payments_outlined,
            'Hourly Fee',
            price,
            valueColor: primaryColor,
          ),

          const SizedBox(height: 15),

          // ------------------------------------------------------
          // PREVIOUS TEACHERS
          // ------------------------------------------------------

          _buildSectionHeading(
            Icons.person_search_outlined,
            'Previously Studied Under',
          ),

          const SizedBox(height: 9),

          if (teachers.isEmpty)
            _emptyDetail(
              'No previous teacher information provided.',
            )
          else
            ...teachers.map((teacher) {
              if (teacher is! Map) {
                return const SizedBox.shrink();
              }

              final name = _displayValue(
                teacher['teacher_name'],
                'Unknown Teacher',
              );

              final teacherInstitute = _displayValue(
                teacher['institute'],
              );

              final year = _displayValue(
                teacher['study_year'],
              );

              final description = _displayValue(
                teacher['description'],
                '',
              );

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Institute: $teacherInstitute',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    if (year != 'Not provided')
                      Text(
                        'Study year: $year',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    if (description.isNotEmpty)
                      Text(
                        'Details: $description',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 12),

          // ------------------------------------------------------
          // LAB STATUS
          // ------------------------------------------------------

          _buildSectionHeading(
            Icons.science_outlined,
            'Course Lab',
          ),

          const SizedBox(height: 8),

          _statusLabel(
            labCompleted
                ? 'Lab Completed'
                : 'Lab Not Completed / Not Confirmed',
            labCompleted
                ? Icons.check_circle
                : Icons.info_outline,
            labCompleted ? Colors.green : Colors.orange,
          ),

          const SizedBox(height: 15),

          // ------------------------------------------------------
          // PROGRAMMING LANGUAGES
          // ------------------------------------------------------

          _buildSectionHeading(
            Icons.code,
            'Programming Languages',
          ),

          const SizedBox(height: 8),

          if (languages.isEmpty)
            _emptyDetail(
              'No programming languages provided for this course.',
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: languages.map((language) {
                final name = language is Map
                    ? _displayValue(
                        language['language_name'],
                        'Unknown',
                      )
                    : language.toString();

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      color: Colors.deepPurple.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 17),

          // ------------------------------------------------------
          // AVAILABLE SLOTS
          // ------------------------------------------------------

          _buildSectionHeading(
            Icons.schedule,
            'Available Time Slots',
          ),

          const SizedBox(height: 10),

          if (slots.isEmpty)
            _emptyDetail('No available time slots.')
          else
            ...slots.map((slot) {
              return _buildAvailableSlot(
                day: slot['day'].toString(),
                time: slot['time'].toString(),
              );
            }),

          if (selectedDay != null && !hasSelectedSlot)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                'This tutor does not offer your selected time slot.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADING
  // ============================================================

  Widget _buildSectionHeading(
    IconData icon,
    String title,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: primaryColor,
          size: 18,
        ),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _buildDetailRow(
    IconData icon,
    String title,
    String value, {
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: primaryColor,
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 75,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS LABEL
  // ============================================================

  Widget _statusLabel(
    String title,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY DETAIL
  // ============================================================

  Widget _emptyDetail(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.grey,
        ),
      ),
    );
  }

  // ============================================================
  // AVAILABLE SLOT
  // ============================================================

  Widget _buildAvailableSlot({
    required String day,
    required String time,
  }) {
    final isSelected =
        selectedDay?.trim().toLowerCase() ==
                day.trim().toLowerCase() &&
            selectedTime?.trim().toLowerCase() ==
                time.trim().toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.teal.shade50
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: isSelected
              ? primaryColor
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 15,
            color: primaryColor,
          ),
          const SizedBox(width: 7),
          Expanded(
            flex: 3,
            child: Text(
              day,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(
            Icons.access_time,
            size: 15,
            color: primaryColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 4,
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 5),
          SizedBox(
            height: 33,
            child: ElevatedButton(
              onPressed: () => _selectSlot(day, time),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected
                    ? darkPrimaryColor
                    : primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isSelected ? 'Selected' : 'Select',
                style: const TextStyle(fontSize: 10),
              ),
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
// import 'package:house_of_tutor/services/auth_store.dart';

// class StudentFindTutor extends StatefulWidget {
//   final int courseId;
//   final String courseName;
//   final double? userLat;
//   final double? userLng;

//   const StudentFindTutor({
//     super.key,
//     required this.courseId,
//     required this.courseName,
//     this.userLat,
//     this.userLng,
//   });

//   @override
//   State<StudentFindTutor> createState() => _StudentFindTutorState();
// }

// class _StudentFindTutorState extends State<StudentFindTutor> {
//   // ============================================================
//   // COLORS
//   // ============================================================

//   static const Color primaryColor = Color(0xFF1E8E7E);
//   static const Color darkPrimaryColor = Color(0xFF176B60);
//   static const Color backgroundColor = Color(0xFFF4F6F8);

//   // ============================================================
//   // DATA
//   // ============================================================

//   bool isLoading = true;
//   bool isSubmitting = false;

//   List<dynamic> tutorsList = [];
//   List<dynamic> filteredTutors = [];

//   String errorMessage = '';

//   String sortBy = 'feedback';

//   final TextEditingController searchController =
//       TextEditingController();

//   final TextEditingController durationController =
//       TextEditingController();

//   final TextEditingController classesPerWeekController =
//       TextEditingController();

//   final Set<int> selectedTutorIds = {};

//   // A single common slot is sent to every selected tutor.
//   String? selectedDay;
//   String? selectedTime;

//   // Learning mode
//   String learningMode = 'SpecificTime';
//   String learningDurationUnit = 'Hours';

//   // Course plan
//   String planType = 'Normal';
//   DateTime startDate = DateTime.now();

//   @override
//   void initState() {
//     super.initState();

//     searchController.addListener(_filterTutors);

//     fetchTutors();
//   }

//   @override
//   void dispose() {
//     searchController.dispose();
//     durationController.dispose();
//     classesPerWeekController.dispose();

//     super.dispose();
//   }

//   // ============================================================
//   // LOCATION
//   // ============================================================

//   bool _isValidLatitude(double value) =>
//       value >= -90 && value <= 90;

//   bool _isValidLongitude(double value) =>
//       value >= -180 && value <= 180;

//   Future<Map<String, double>?> _getUserLocation() async {
//     if (widget.userLat != null &&
//         widget.userLng != null &&
//         _isValidLatitude(widget.userLat!) &&
//         _isValidLongitude(widget.userLng!)) {
//       return {
//         'latitude': widget.userLat!,
//         'longitude': widget.userLng!,
//       };
//     }

//     await AuthStore.instance.hydrate();

//     final lat = AuthStore.instance.lastLat;
//     final lng = AuthStore.instance.lastLng;

//     if (lat == null || lng == null) return null;

//     if (!_isValidLatitude(lat) ||
//         !_isValidLongitude(lng)) {
//       return null;
//     }

//     return {
//       'latitude': lat,
//       'longitude': lng,
//     };
//   }

//   // ============================================================
//   // SAFE HELPERS
//   // ============================================================

//   String _displayValue(
//     dynamic value, [
//     String fallback = 'Not provided',
//   ]) {
//     if (value == null) return fallback;

//     final result = value.toString().trim();

//     if (result.isEmpty || result.toLowerCase() == 'null') {
//       return fallback;
//     }

//     return result;
//   }

//   dynamic _firstValue(Map item, List<String> keys) {
//     for (final key in keys) {
//       final value = item[key];

//       if (value != null &&
//           value.toString().trim().isNotEmpty) {
//         return value;
//       }
//     }

//     return null;
//   }

//   double _toDouble(dynamic value) {
//     if (value is num) return value.toDouble();

//     return double.tryParse(
//           value?.toString().trim() ?? '',
//         ) ??
//         0;
//   }

//   int _toInt(dynamic value) {
//     if (value is num) return value.toInt();

//     return int.tryParse(
//           value?.toString().trim() ?? '',
//         ) ??
//         0;
//   }

//   int? _toIntNullable(dynamic value) {
//     if (value is num) return value.toInt();

//     return int.tryParse(
//       value?.toString().trim() ?? '',
//     );
//   }

//   bool _toBool(dynamic value) {
//     if (value == true) return true;
//     if (value == false || value == null) return false;

//     return value.toString().toLowerCase() == 'true' ||
//         value.toString() == '1';
//   }

//   String _formatDate(DateTime date) {
//     final year = date.year.toString().padLeft(4, '0');
//     final month = date.month.toString().padLeft(2, '0');
//     final day = date.day.toString().padLeft(2, '0');

//     return '$year-$month-$day';
//   }

//   // ============================================================
//   // TUTOR INFORMATION
//   // ============================================================

//   int? _getTutorId(dynamic tutor) {
//     if (tutor is! Map) return null;

//     return _toIntNullable(
//       _firstValue(tutor, [
//         'tutor_id',
//         'tutorId',
//         'id',
//       ]),
//     );
//   }

//   String _getTutorName(dynamic tutor) {
//     if (tutor is! Map) return 'Tutor';

//     return _displayValue(
//       _firstValue(tutor, [
//         'tutor_name',
//         'tutorName',
//         'name',
//         'full_name',
//         'fullName',
//       ]),
//       'Tutor',
//     );
//   }

//   String _getInstitute(dynamic tutor) {
//     if (tutor is! Map) return 'Not provided';

//     return _displayValue(
//       _firstValue(tutor, [
//         'institute',
//         'Institute',
//       ]),
//     );
//   }

//   String _getGrade(dynamic tutor) {
//     if (tutor is! Map) return 'Not provided';

//     return _displayValue(
//       _firstValue(tutor, [
//         'grade',
//         'Grade',
//       ]),
//     );
//   }

//   String _getHourlyPrice(dynamic tutor) {
//     if (tutor is! Map) return 'Not provided';

//     final value = _firstValue(tutor, [
//       'hourly_rate',
//       'hourlyRate',
//     ]);

//     if (value == null) return 'Not provided';

//     final amount = double.tryParse(value.toString());

//     if (amount == null) return 'Not provided';

//     final formatted =
//         amount == amount.roundToDouble()
//             ? amount.toStringAsFixed(0)
//             : amount.toStringAsFixed(2);

//     return 'Rs. $formatted / hour';
//   }

//   double _getRating(dynamic tutor) {
//     if (tutor is! Map) return 0;

//     return _toDouble(
//       _firstValue(tutor, [
//         'average_rating',
//         'averageRating',
//       ]),
//     );
//   }

//   int _getReviewCount(dynamic tutor) {
//     if (tutor is! Map) return 0;

//     return _toInt(
//       _firstValue(tutor, [
//         'total_reviews',
//         'totalReviews',
//       ]),
//     );
//   }

//   // ============================================================
//   // PREVIOUS TEACHERS
//   // API: previous_teachers
//   // ============================================================

//   List<dynamic> _getPreviousTeachers(dynamic tutor) {
//     if (tutor is! Map) return [];

//     final data = tutor['previous_teachers'];

//     return data is List ? data : [];
//   }

//   // ============================================================
//   // PROGRAMMING LANGUAGES
//   // API: programming_languages
//   // ============================================================

//   List<dynamic> _getProgrammingLanguages(dynamic tutor) {
//     if (tutor is! Map) return [];

//     final data = tutor['programming_languages'];

//     return data is List ? data : [];
//   }

//   // ============================================================
//   // LAB INFORMATION
//   // API: lab_completed
//   // ============================================================

//   bool _getLabCompleted(dynamic tutor) {
//     if (tutor is! Map) return false;

//     return _toBool(tutor['lab_completed']);
//   }

//   // ============================================================
//   // AVAILABLE SLOTS
//   // API: common_slots
//   // ============================================================

//   bool _isSlotAvailable(dynamic slot) {
//     if (slot is! Map) return false;

//     return _toBool(slot['is_available']);
//   }

//   List<dynamic> _getSlots(dynamic tutor) {
//     if (tutor is! Map) return [];

//     final rawSlots = tutor['common_slots'];

//     if (rawSlots is! List) return [];

//     return rawSlots.where((slot) {
//       if (slot is! Map) return false;

//       final day = slot['day']?.toString().trim() ?? '';
//       final time = slot['time']?.toString().trim() ?? '';

//       return _isSlotAvailable(slot) &&
//           day.isNotEmpty &&
//           time.isNotEmpty;
//     }).toList();
//   }

//   bool _hasSelectedSlot(dynamic tutor) {
//     if (selectedDay == null || selectedTime == null) {
//       return false;
//     }

//     return _getSlots(tutor).any((slot) {
//       return slot['day']
//                   .toString()
//                   .trim()
//                   .toLowerCase() ==
//               selectedDay!.trim().toLowerCase() &&
//           slot['time']
//                   .toString()
//                   .trim()
//                   .toLowerCase() ==
//               selectedTime!.trim().toLowerCase();
//     });
//   }

//   // ============================================================
//   // FETCH TUTORS
//   // ============================================================

//   Future<void> fetchTutors() async {
//     if (!mounted) return;

//     setState(() {
//       isLoading = true;
//       errorMessage = '';
//     });

//     try {
//       final location = await _getUserLocation();

//       if (location == null) {
//         throw Exception(
//           'Your location is not available. Please update your location and try again.',
//         );
//       }

//       final userLat = location['latitude']!;
//       final userLng = location['longitude']!;

//       final endpoint =
//           '/api/Student/search-by-time-location-visiting-tutor'
//           '?userLat=$userLat'
//           '&userLng=$userLng'
//           '&courseId=${widget.courseId}'
//           '&sortBy=$sortBy';

//       debugPrint('Tutor Search URL: $endpoint');

//       final response = await ApiClient.get(endpoint);

//       debugPrint('Search Status: ${response.statusCode}');
//       debugPrint('Search Response: ${response.body}');

//       if (!mounted) return;

//       if (response.statusCode >= 200 &&
//           response.statusCode < 300) {
//         final data = await ApiClient.decodeJson(response);

//         List<dynamic> tutors = [];

//         if (data is Map) {
//           final rawTutors = data['tutors'];

//           if (rawTutors is List) {
//             tutors = rawTutors;
//           }
//         } else if (data is List) {
//           tutors = data;
//         }

//         setState(() {
//           tutorsList = tutors;
//           filteredTutors = List.from(tutors);
//           errorMessage = '';
//           isLoading = false;
//         });

//         _filterTutors();
//       } else {
//         final data = await ApiClient.decodeJson(response);

//         final message = data is Map
//             ? _displayValue(
//                 data['message'],
//                 'No tutors available.',
//               )
//             : ApiClient.messageFromBody(response.body) ??
//                 'No tutors available.';

//         setState(() {
//           tutorsList = [];
//           filteredTutors = [];
//           errorMessage = message;
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('StudentFindTutor Error: $e');

//       if (!mounted) return;

//       setState(() {
//         isLoading = false;
//         tutorsList = [];
//         filteredTutors = [];
//         errorMessage = e.toString().replaceFirst(
//               'Exception: ',
//               '',
//             );
//       });
//     }
//   }

//   // ============================================================
//   // SEARCH FILTER
//   // ============================================================

//   void _filterTutors() {
//     if (!mounted) return;

//     final query = searchController.text.trim().toLowerCase();

//     final results = tutorsList.where((tutor) {
//       return _getTutorName(tutor)
//           .toLowerCase()
//           .contains(query);
//     }).toList();

//     setState(() {
//       filteredTutors = results;
//     });
//   }

//   // ============================================================
//   // SORTING
//   // ============================================================

//   void _changeSort(String? value) {
//     if (value == null || value == sortBy) return;

//     setState(() {
//       sortBy = value;
//       selectedTutorIds.clear();
//       selectedDay = null;
//       selectedTime = null;
//     });

//     fetchTutors();
//   }

//   // ============================================================
//   // SLOT SELECTION
//   // ============================================================

//   void _selectSlot(String day, String time) {
//     setState(() {
//       // A different slot means previous tutor selections
//       // cannot safely be reused.
//       if (selectedDay != day || selectedTime != time) {
//         selectedTutorIds.clear();
//       }

//       selectedDay = day;
//       selectedTime = time;
//     });
//   }

//   // ============================================================
//   // TUTOR SELECTION
//   // ============================================================

//   void _toggleTutorSelection(int tutorId) {
//     setState(() {
//       if (selectedTutorIds.contains(tutorId)) {
//         selectedTutorIds.remove(tutorId);
//       } else {
//         selectedTutorIds.add(tutorId);
//       }
//     });
//   }

//   void _clearSelection() {
//     setState(() {
//       selectedTutorIds.clear();
//       selectedDay = null;
//       selectedTime = null;
//     });
//   }

//   // ============================================================
//   // CREATE REQUEST
//   // ============================================================

//   Future<void> bookClassRequest() async {
//     if (selectedDay == null || selectedTime == null) {
//       _showError('Please select an available day and time.');
//       return;
//     }

//     if (selectedTutorIds.isEmpty) {
//       _showError('Please select at least one tutor.');
//       return;
//     }

//     int? duration;
//     int? requestedWeeks;
//     int? requestedClasses;

//     if (learningMode == 'SpecificTime') {
//       duration = int.tryParse(durationController.text.trim());

//       if (duration == null || duration <= 0) {
//         _showError('Enter a valid learning duration.');
//         return;
//       }
//     }

//     // Accelerated course validation.
//     if (planType == 'Accelerated') {
//       requestedWeeks = int.tryParse(
//         durationController.text.trim(),
//       );

//       requestedClasses = int.tryParse(
//         classesPerWeekController.text.trim(),
//       );

//       if (requestedWeeks == null || requestedWeeks <= 0) {
//         _showError('Enter a valid accelerated course duration.');
//         return;
//       }

//       if (requestedClasses == null || requestedClasses <= 0) {
//         _showError('Enter valid classes per week.');
//         return;
//       }
//     }

//     if (!mounted) return;

//     setState(() {
//       isSubmitting = true;
//     });

//     try {
//       final cleanTime = selectedTime!.trim();

//       final requestBody = <String, dynamic>{
//         'tutor_ids': selectedTutorIds.toList(),
//         'course_id': widget.courseId,
//         'day': selectedDay,
//         'time': cleanTime,

//         // Learning mode
//         'learning_mode': learningMode,

//         'learning_duration': duration,

//         'learning_duration_unit':
//             learningMode == 'SpecificTime'
//                 ? learningDurationUnit
//                 : null,

//         // Course plan
//         'plan_type': planType,

//         'requested_duration_weeks':
//             planType == 'Accelerated'
//                 ? requestedWeeks
//                 : null,

//         'requested_classes_per_week':
//             planType == 'Accelerated'
//                 ? requestedClasses
//                 : null,

//         // Start date
//         'start_date': _formatDate(startDate),
//       };

//       debugPrint('Create Request Body: $requestBody');

//       final response = await ApiClient.post(
//         '/api/Student/create-request',
//         requestBody,
//       );

//       debugPrint('Create Request Status: ${response.statusCode}');
//       debugPrint('Create Request Response: ${response.body}');

//       final data = await ApiClient.decodeJson(response);

//       if (!mounted) return;

//       setState(() {
//         isSubmitting = false;
//       });

//       if (response.statusCode >= 200 &&
//           response.statusCode < 300) {
//         setState(() {
//           selectedTutorIds.clear();
//           selectedDay = null;
//           selectedTime = null;
//           durationController.clear();
//           classesPerWeekController.clear();
//         });

//         _showSuccessDialog(
//           data is Map
//               ? _displayValue(
//                   data['message'],
//                   'Tutor request created successfully.',
//                 )
//               : 'Tutor request created successfully.',
//           data,
//         );
//       } else {
//         final message = data is Map
//             ? _displayValue(
//                 data['message'] ?? data['error'],
//                 'Failed to create tutor request.',
//               )
//             : ApiClient.messageFromBody(response.body) ??
//                 'Failed to create tutor request.';

//         _showError(message);
//       }
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isSubmitting = false;
//       });

//       _showError('Error creating request: $e');
//     }
//   }

//   // ============================================================
//   // SUCCESS DIALOG
//   // ============================================================

//   void _showSuccessDialog(String message, dynamic data) {
//     final requestGroupId =
//         data is Map ? data['request_group_id'] : null;

//     final totalTutors =
//         data is Map ? data['total_tutors'] : null;

//     final plan =
//         data is Map ? data['plan_type'] : planType;

//     final deadline =
//         data is Map ? data['response_deadline'] : null;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(18),
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(
//                 Icons.check_circle,
//                 color: primaryColor,
//                 size: 65,
//               ),
//               const SizedBox(height: 12),
//               const Text(
//                 'Request Submitted!',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 message,
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 15),

//               if (requestGroupId != null)
//                 _successDetail(
//                   'Request Group',
//                   '#$requestGroupId',
//                 ),

//               if (totalTutors != null)
//                 _successDetail(
//                   'Selected Tutors',
//                   '$totalTutors',
//                 ),

//               _successDetail(
//                 'Course Plan',
//                 '$plan',
//               ),

//               if (deadline != null)
//                 _successDetail(
//                   'Response Deadline',
//                   '$deadline',
//                 ),

//               const SizedBox(height: 12),

//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.teal.shade50,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Text(
//                   'The first tutor receives the request first. '
//                   'They have 2 minutes to respond before the queue can proceed.',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: darkPrimaryColor,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.pop(dialogContext);
//                 },
//                 style: _primaryButtonStyle(),
//                 child: const Text('Done'),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _successDetail(String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(color: Colors.grey),
//           ),
//           Flexible(
//             child: Text(
//               value,
//               textAlign: TextAlign.end,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // BOOKING / CONFIRMATION DIALOG
//   // ============================================================

//   void _showBookingDialog() {
//     if (selectedDay == null ||
//         selectedTime == null ||
//         selectedTutorIds.isEmpty) {
//       _showError('Select a time slot and tutor first.');
//       return;
//     }

//     String dialogLearningMode = learningMode;
//     String dialogDurationUnit = learningDurationUnit;
//     String dialogPlanType = planType;

//     final durationControllerDialog = TextEditingController(
//       text: durationController.text,
//     );

//     final classesControllerDialog = TextEditingController(
//       text: classesPerWeekController.text,
//     );

//     DateTime dialogStartDate = startDate;

//     showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(18),
//               ),
//               title: const Text(
//                 'Confirm Tutor Request',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 19,
//                 ),
//               ),
//               content: SizedBox(
//                 width: double.maxFinite,
//                 child: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Selected tutors
//                       _dialogSectionTitle('Selected Tutors'),

//                       _dialogInfo(
//                         Icons.people_outline,
//                         '${selectedTutorIds.length} tutor(s) selected',
//                       ),

//                       const SizedBox(height: 16),

//                       // Selected slot
//                       _dialogSectionTitle('Selected Time'),

//                       _dialogInfo(
//                         Icons.calendar_month,
//                         '$selectedDay - $selectedTime',
//                       ),

//                       const SizedBox(height: 18),

//                       // Course plan
//                       _dialogSectionTitle('Course Completion Plan'),

//                       const SizedBox(height: 8),

//                       DropdownButtonFormField<String>(
//                         value: dialogPlanType,
//                         isExpanded: true,
//                         decoration: _inputDecoration(
//                           'Select course plan',
//                           Icons.menu_book_outlined,
//                         ),
//                         items: const [
//                           DropdownMenuItem(
//                             value: 'Normal',
//                             child: Text('Normal Plan'),
//                           ),
//                           DropdownMenuItem(
//                             value: 'Accelerated',
//                             child: Text('Accelerated / Fast Track'),
//                           ),
//                         ],
//                         onChanged: (value) {
//                           if (value == null) return;

//                           setDialogState(() {
//                             dialogPlanType = value;
//                           });
//                         },
//                       ),

//                       if (dialogPlanType == 'Accelerated') ...[
//                         const SizedBox(height: 12),

//                         const Text(
//                           'Enter your preferred accelerated schedule. '
//                           'The backend will verify that the total number '
//                           'of classes remains unchanged.',
//                           style: TextStyle(
//                             color: Colors.grey,
//                             fontSize: 12,
//                           ),
//                         ),

//                         const SizedBox(height: 12),

//                         TextField(
//                           controller: durationControllerDialog,
//                           keyboardType: TextInputType.number,
//                           decoration: _inputDecoration(
//                             'Requested duration (weeks)',
//                             Icons.calendar_today,
//                           ),
//                         ),

//                         const SizedBox(height: 12),

//                         TextField(
//                           controller: classesControllerDialog,
//                           keyboardType: TextInputType.number,
//                           decoration: _inputDecoration(
//                             'Classes per week',
//                             Icons.event_available,
//                           ),
//                         ),
//                       ],

//                       const SizedBox(height: 18),

//                       // Start date
//                       _dialogSectionTitle('Course Start Date'),

//                       const SizedBox(height: 8),

//                       InkWell(
//                         onTap: () async {
//                           final selected = await showDatePicker(
//                             context: dialogContext,
//                             initialDate: dialogStartDate.isBefore(
//                               DateTime.now(),
//                             )
//                                 ? DateTime.now()
//                                 : dialogStartDate,
//                             firstDate: DateTime.now(),
//                             lastDate: DateTime(2100),
//                           );

//                           if (selected != null) {
//                             setDialogState(() {
//                               dialogStartDate = selected;
//                             });
//                           }
//                         },
//                         child: Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.all(14),
//                           decoration: BoxDecoration(
//                             border: Border.all(
//                               color: Colors.grey.shade300,
//                             ),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Row(
//                             children: [
//                               const Icon(
//                                 Icons.date_range,
//                                 color: primaryColor,
//                               ),
//                               const SizedBox(width: 10),
//                               Expanded(
//                                 child: Text(
//                                   _formatDate(dialogStartDate),
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ),
//                               const Icon(
//                                 Icons.arrow_drop_down,
//                                 color: Colors.grey,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 18),

//                       // Learning mode
//                       _dialogSectionTitle('Learning Mode'),

//                       const SizedBox(height: 8),

//                       DropdownButtonFormField<String>(
//                         value: dialogLearningMode,
//                         isExpanded: true,
//                         decoration: _inputDecoration(
//                           'Learning mode',
//                           Icons.access_time,
//                         ),
//                         items: const [
//                           DropdownMenuItem(
//                             value: 'SpecificTime',
//                             child: Text('Specific Time'),
//                           ),
//                           DropdownMenuItem(
//                             value: 'FullTime',
//                             child: Text('Full Time'),
//                           ),
//                         ],
//                         onChanged: (value) {
//                           if (value == null) return;

//                           setDialogState(() {
//                             dialogLearningMode = value;
//                           });
//                         },
//                       ),

//                       if (dialogLearningMode == 'SpecificTime') ...[
//                         const SizedBox(height: 12),

//                         TextField(
//                           controller: durationControllerDialog,
//                           keyboardType: TextInputType.number,
//                           decoration: _inputDecoration(
//                             'Learning duration',
//                             Icons.timelapse,
//                           ),
//                         ),

//                         const SizedBox(height: 12),

//                         DropdownButtonFormField<String>(
//                           value: dialogDurationUnit,
//                           isExpanded: true,
//                           decoration: _inputDecoration(
//                             'Duration unit',
//                             Icons.schedule,
//                           ),
//                           items: const [
//                             DropdownMenuItem(
//                               value: 'Hours',
//                               child: Text('Hours'),
//                             ),
//                             DropdownMenuItem(
//                               value: 'Days',
//                               child: Text('Days'),
//                             ),
//                             DropdownMenuItem(
//                               value: 'Weeks',
//                               child: Text('Weeks'),
//                             ),
//                           ],
//                           onChanged: (value) {
//                             if (value == null) return;

//                             setDialogState(() {
//                               dialogDurationUnit = value;
//                             });
//                           },
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(dialogContext);
//                   },
//                   child: const Text(
//                     'Cancel',
//                     style: TextStyle(color: Colors.grey),
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: isSubmitting
//                       ? null
//                       : () async {
//                           // Save dialog values.
//                           learningMode = dialogLearningMode;
//                           learningDurationUnit = dialogDurationUnit;
//                           planType = dialogPlanType;

//                           startDate = dialogStartDate;

//                           if (planType == 'Accelerated') {
//                             durationController.text =
//                                 durationControllerDialog.text.trim();

//                             classesPerWeekController.text =
//                                 classesControllerDialog.text.trim();
//                           } else if (learningMode == 'SpecificTime') {
//                             durationController.text =
//                                 durationControllerDialog.text.trim();
//                           } else {
//                             durationController.clear();
//                             classesPerWeekController.clear();
//                           }

//                           Navigator.pop(dialogContext);

//                           await bookClassRequest();
//                         },
//                   style: _primaryButtonStyle(),
//                   child: const Text('Send Request'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     ).then((_) {
//       durationControllerDialog.dispose();
//       classesControllerDialog.dispose();
//     });
//   }

//   Widget _dialogSectionTitle(String title) {
//     return Text(
//       title,
//       style: const TextStyle(
//         fontWeight: FontWeight.bold,
//         fontSize: 14,
//       ),
//     );
//   }

//   Widget _dialogInfo(IconData icon, String text) {
//     return Container(
//       margin: const EdgeInsets.only(top: 8),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.teal.shade50,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: primaryColor, size: 19),
//           const SizedBox(width: 9),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(
//                 color: darkPrimaryColor,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   InputDecoration _inputDecoration(
//     String hint,
//     IconData icon,
//   ) {
//     return InputDecoration(
//       hintText: hint,
//       prefixIcon: Icon(icon, size: 19),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(color: Colors.grey.shade300),
//       ),
//       contentPadding: const EdgeInsets.symmetric(
//         horizontal: 12,
//         vertical: 13,
//       ),
//     );
//   }

//   // ============================================================
//   // BUTTON STYLE
//   // ============================================================

//   ButtonStyle _primaryButtonStyle() {
//     return ElevatedButton.styleFrom(
//       backgroundColor: primaryColor,
//       foregroundColor: Colors.white,
//       elevation: 0,
//       minimumSize: const Size(double.infinity, 48),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//     );
//   }

//   // ============================================================
//   // ERROR MESSAGE
//   // ============================================================

//   void _showError(String message) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red.shade700,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   // ============================================================
//   // MAIN SCREEN
//   // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black87,
//         centerTitle: true,
//         title: Column(
//           children: [
//             const Text(
//               'FIND YOUR TUTOR',
//               style: TextStyle(
//                 color: primaryColor,
//                 fontSize: 10,
//                 fontWeight: FontWeight.bold,
//                 letterSpacing: 1.4,
//               ),
//             ),
//             const SizedBox(height: 3),
//             Text(
//               widget.courseName,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 fontSize: 17,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//           ],
//         ),
//       ),
//       body: Column(
//         children: [
//           // Search and sorting
//           Container(
//             color: Colors.white,
//             padding: const EdgeInsets.fromLTRB(16, 10, 16, 15),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: searchController,
//                   decoration: InputDecoration(
//                     hintText: 'Search tutor by name...',
//                     prefixIcon: const Icon(Icons.search),
//                     filled: true,
//                     fillColor: backgroundColor,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(13),
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   children: [
//                     const Icon(
//                       Icons.sort,
//                       color: primaryColor,
//                       size: 20,
//                     ),
//                     const SizedBox(width: 8),
//                     const Text(
//                       'Sort by:',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 13,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: DropdownButtonFormField<String>(
//                         value: sortBy,
//                         isExpanded: true,
//                         decoration: InputDecoration(
//                           contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 5,
//                           ),
//                           filled: true,
//                           fillColor: backgroundColor,
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                             borderSide: BorderSide.none,
//                           ),
//                         ),
//                         items: const [
//                           DropdownMenuItem(
//                             value: 'feedback',
//                             child: Text('Feedback'),
//                           ),
//                           DropdownMenuItem(
//                             value: 'institute',
//                             child: Text('Institute'),
//                           ),
//                           DropdownMenuItem(
//                             value: 'grade',
//                             child: Text('Grade'),
//                           ),
//                           DropdownMenuItem(
//                             value: 'fee',
//                             child: Text('Lowest Fee'),
//                           ),
//                         ],
//                         onChanged: _changeSort,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // Selected slot and tutors
//           if (selectedDay != null && selectedTime != null)
//             Container(
//               width: double.infinity,
//               margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.teal.shade50,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.teal.shade100),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(
//                     Icons.event_available,
//                     color: primaryColor,
//                   ),
//                   const SizedBox(width: 9),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Selected Common Slot',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: darkPrimaryColor,
//                             fontSize: 12,
//                           ),
//                         ),
//                         Text(
//                           '$selectedDay | $selectedTime',
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: darkPrimaryColor,
//                           ),
//                         ),
//                         Text(
//                           '${selectedTutorIds.length} tutor(s) selected',
//                           style: const TextStyle(
//                             fontSize: 11,
//                             color: Colors.grey,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   TextButton(
//                     onPressed: _clearSelection,
//                     child: const Text('Clear'),
//                   ),
//                 ],
//               ),
//             ),

//           // Instructions
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
//             child: Row(
//               children: [
//                 const Icon(
//                   Icons.info_outline,
//                   size: 17,
//                   color: Colors.grey,
//                 ),
//                 const SizedBox(width: 7),
//                 Expanded(
//                   child: Text(
//                     selectedDay == null
//                         ? 'First select a common available time slot, then select tutors offering that slot.'
//                         : 'Now select tutors who offer the selected time slot.',
//                     style: const TextStyle(
//                       color: Colors.grey,
//                       fontSize: 11,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           Expanded(
//             child: isLoading
//                 ? const Center(
//                     child: CircularProgressIndicator(
//                       color: primaryColor,
//                     ),
//                   )
//                 : filteredTutors.isEmpty
//                     ? _buildEmptyView()
//                     : RefreshIndicator(
//                         color: primaryColor,
//                         onRefresh: fetchTutors,
//                         child: ListView.builder(
//                           padding: const EdgeInsets.fromLTRB(
//                             16,
//                             8,
//                             16,
//                             20,
//                           ),
//                           itemCount: filteredTutors.length,
//                           itemBuilder: (context, index) {
//                             return _buildTutorCard(
//                               filteredTutors[index],
//                             );
//                           },
//                         ),
//                       ),
//           ),
//         ],
//       ),

//       // Bottom request button
//       bottomNavigationBar: selectedTutorIds.isNotEmpty
//           ? SafeArea(
//               child: Container(
//                 padding: const EdgeInsets.all(14),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.06),
//                       blurRadius: 10,
//                       offset: const Offset(0, -3),
//                     ),
//                   ],
//                 ),
//                 child: ElevatedButton.icon(
//                   onPressed:
//                       isSubmitting ? null : _showBookingDialog,
//                   icon: isSubmitting
//                       ? const SizedBox(
//                           height: 18,
//                           width: 18,
//                           child: CircularProgressIndicator(
//                             color: Colors.white,
//                             strokeWidth: 2,
//                           ),
//                         )
//                       : const Icon(Icons.send),
//                   label: Text(
//                     isSubmitting
//                         ? 'Sending Request...'
//                         : 'Continue with ${selectedTutorIds.length} Tutor(s)',
//                   ),
//                   style: _primaryButtonStyle(),
//                 ),
//               ),
//             )
//           : null,
//     );
//   }

//   // ============================================================
//   // EMPTY / ERROR VIEW
//   // ============================================================

//   Widget _buildEmptyView() {
//     final bool hasError = errorMessage.isNotEmpty;

//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(25),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               hasError
//                   ? Icons.location_off_outlined
//                   : Icons.person_search_outlined,
//               size: 65,
//               color: Colors.grey.shade400,
//             ),
//             const SizedBox(height: 15),
//             Text(
//               hasError ? errorMessage : 'No tutors found.',
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 color: Colors.grey,
//                 fontSize: 14,
//               ),
//             ),
//             const SizedBox(height: 18),
//             ElevatedButton.icon(
//               onPressed: fetchTutors,
//               icon: const Icon(Icons.refresh),
//               label: const Text('Try Again'),
//               style: _primaryButtonStyle(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // TUTOR CARD
//   // ============================================================

//   Widget _buildTutorCard(dynamic tutor) {
//     if (tutor is! Map) return const SizedBox.shrink();

//     final tutorId = _getTutorId(tutor);
//     final tutorName = _getTutorName(tutor);

//     final initials = tutorName
//         .trim()
//         .split(RegExp(r'\s+'))
//         .where((word) => word.isNotEmpty)
//         .map((word) => word[0])
//         .take(2)
//         .join()
//         .toUpperCase();

//     final rating = _getRating(tutor);
//     final reviews = _getReviewCount(tutor);
//     final distance = _toDouble(tutor['distance']);

//     final grade = _getGrade(tutor);
//     final institute = _getInstitute(tutor);
//     final price = _getHourlyPrice(tutor);

//     final location = _displayValue(
//       tutor['location'],
//       'Location unavailable',
//     );

//     final slots = _getSlots(tutor);

//     final bool hasSelectedSlot = _hasSelectedSlot(tutor);

//     final bool isSelected =
//         tutorId != null && selectedTutorIds.contains(tutorId);

//     final bool canSelect =
//         selectedDay != null && hasSelectedSlot;

//     final teachers = _getPreviousTeachers(tutor);
//     final languages = _getProgrammingLanguages(tutor);
//     final labCompleted = _getLabCompleted(tutor);

//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(17),
//         border: Border.all(
//           color: isSelected
//               ? primaryColor
//               : Colors.grey.shade200,
//           width: isSelected ? 1.5 : 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.035),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Tutor heading
//           Row(
//             children: [
//               Checkbox(
//                 value: isSelected,
//                 activeColor: primaryColor,
//                 onChanged: canSelect && tutorId != null
//                     ? (_) => _toggleTutorSelection(tutorId)
//                     : null,
//               ),
//               Container(
//                 height: 50,
//                 width: 50,
//                 decoration: BoxDecoration(
//                   color: Colors.teal.shade50,
//                   borderRadius: BorderRadius.circular(13),
//                 ),
//                 child: Center(
//                   child: Text(
//                     initials.isEmpty ? 'T' : initials,
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: primaryColor,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 11),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       tutorName,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 5),
//                     Row(
//                       children: [
//                         const Icon(
//                           Icons.star,
//                           color: Colors.amber,
//                           size: 16,
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           '${rating.toStringAsFixed(1)} ($reviews reviews)',
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: Colors.black54,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           if (isSelected)
//             _statusLabel(
//               'Tutor selected',
//               Icons.check_circle,
//               Colors.teal,
//             ),

//           const SizedBox(height: 14),

//           // Location
//           Row(
//             children: [
//               const Icon(
//                 Icons.location_on_outlined,
//                 size: 17,
//                 color: primaryColor,
//               ),
//               const SizedBox(width: 6),
//               Expanded(
//                 child: Text(
//                   location,
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color: Colors.black54,
//                   ),
//                 ),
//               ),
//               const Icon(
//                 Icons.near_me_outlined,
//                 size: 15,
//                 color: Colors.grey,
//               ),
//               const SizedBox(width: 4),
//               Text(
//                 '${distance.toStringAsFixed(2)} km',
//                 style: const TextStyle(
//                   fontSize: 12,
//                   color: Colors.black54,
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 14),

//           // Basic tutor information
//           _buildDetailRow(
//             Icons.school_outlined,
//             'Grade',
//             grade,
//           ),

//           _buildDetailRow(
//             Icons.account_balance_outlined,
//             'Institute',
//             institute,
//           ),

//           _buildDetailRow(
//             Icons.payments_outlined,
//             'Hourly Fee',
//             price,
//             valueColor: primaryColor,
//           ),

//           const SizedBox(height: 15),

//           // Previous teachers
//           _buildSectionHeading(
//             Icons.person_search_outlined,
//             'Previously Studied Under',
//           ),

//           const SizedBox(height: 9),

//           if (teachers.isEmpty)
//             _emptyDetail('No previous teacher information provided.')
//           else
//             ...teachers.map((teacher) {
//               if (teacher is! Map) {
//                 return const SizedBox.shrink();
//               }

//               final name = _displayValue(
//                 teacher['teacher_name'],
//                 'Unknown Teacher',
//               );

//               final teacherInstitute = _displayValue(
//                 teacher['institute'],
//               );

//               final year = _displayValue(
//                 teacher['study_year'],
//               );

//               return Container(
//                 width: double.infinity,
//                 margin: const EdgeInsets.only(bottom: 7),
//                 padding: const EdgeInsets.all(11),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade50,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       name,
//                       style: const TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Institute: $teacherInstitute',
//                       style: const TextStyle(
//                         fontSize: 11,
//                         color: Colors.black54,
//                       ),
//                     ),
//                     if (year != 'Not provided')
//                       Text(
//                         'Study year: $year',
//                         style: const TextStyle(
//                           fontSize: 11,
//                           color: Colors.black54,
//                         ),
//                       ),
//                   ],
//                 ),
//               );
//             }),

//           const SizedBox(height: 12),

//           // Lab status
//           _buildSectionHeading(
//             Icons.science_outlined,
//             'Course Lab',
//           ),

//           const SizedBox(height: 8),

//           _statusLabel(
//             labCompleted
//                 ? 'Lab Completed'
//                 : 'Lab Not Completed / Not Confirmed',
//             labCompleted
//                 ? Icons.check_circle
//                 : Icons.info_outline,
//             labCompleted ? Colors.green : Colors.orange,
//           ),

//           const SizedBox(height: 15),

//           // Programming languages
//           _buildSectionHeading(
//             Icons.code,
//             'Programming Languages',
//           ),

//           const SizedBox(height: 8),

//           if (languages.isEmpty)
//             _emptyDetail(
//               'No programming languages provided for this course.',
//             )
//           else
//             Wrap(
//               spacing: 7,
//               runSpacing: 7,
//               children: languages.map((language) {
//                 final name = language is Map
//                     ? _displayValue(
//                         language['language_name'],
//                         'Unknown',
//                       )
//                     : language.toString();

//                 return Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 11,
//                     vertical: 7,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.deepPurple.shade50,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     name,
//                     style: TextStyle(
//                       color: Colors.deepPurple.shade700,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),

//           const SizedBox(height: 17),

//           // Available slots
//           _buildSectionHeading(
//             Icons.schedule,
//             'Available Time Slots',
//           ),

//           const SizedBox(height: 10),

//           if (slots.isEmpty)
//             _emptyDetail('No available time slots.')
//           else
//             ...slots.map((slot) {
//               return _buildAvailableSlot(
//                 day: slot['day'].toString(),
//                 time: slot['time'].toString(),
//               );
//             }),

//           if (selectedDay != null && !hasSelectedSlot)
//             Padding(
//               padding: const EdgeInsets.only(top: 7),
//               child: Text(
//                 'This tutor does not offer your selected time slot.',
//                 style: TextStyle(
//                   fontSize: 11,
//                   color: Colors.orange.shade800,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // SECTION HEADING
//   // ============================================================

//   Widget _buildSectionHeading(
//     IconData icon,
//     String title,
//   ) {
//     return Row(
//       children: [
//         Icon(
//           icon,
//           color: primaryColor,
//           size: 18,
//         ),
//         const SizedBox(width: 7),
//         Text(
//           title,
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 13,
//           ),
//         ),
//       ],
//     );
//   }

//   // ============================================================
//   // DETAIL ROW
//   // ============================================================

//   Widget _buildDetailRow(
//     IconData icon,
//     String title,
//     String value, {
//     Color? valueColor,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 7),
//       padding: const EdgeInsets.symmetric(
//         horizontal: 11,
//         vertical: 10,
//       ),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade50,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             icon,
//             size: 18,
//             color: primaryColor,
//           ),
//           const SizedBox(width: 9),
//           SizedBox(
//             width: 75,
//             child: Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 12,
//                 color: Colors.black54,
//               ),
//             ),
//           ),
//           const SizedBox(width: 6),
//           Expanded(
//             child: Text(
//               value,
//               textAlign: TextAlign.end,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//                 color: valueColor ?? Colors.black87,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // STATUS LABEL
//   // ============================================================

//   Widget _statusLabel(
//     String title,
//     IconData icon,
//     Color color,
//   ) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 10,
//         vertical: 7,
//       ),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.09),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 15, color: color),
//           const SizedBox(width: 6),
//           Flexible(
//             child: Text(
//               title,
//               style: TextStyle(
//                 fontSize: 11,
//                 color: color,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // EMPTY DETAIL
//   // ============================================================

//   Widget _emptyDetail(String message) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade50,
//         borderRadius: BorderRadius.circular(9),
//       ),
//       child: Text(
//         message,
//         style: const TextStyle(
//           fontSize: 11,
//           color: Colors.grey,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // AVAILABLE SLOT
//   // ============================================================

//   Widget _buildAvailableSlot({
//     required String day,
//     required String time,
//   }) {
//     final bool isSelected =
//         selectedDay?.trim().toLowerCase() ==
//                 day.trim().toLowerCase() &&
//             selectedTime?.trim().toLowerCase() ==
//                 time.trim().toLowerCase();

//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.symmetric(
//         horizontal: 10,
//         vertical: 9,
//       ),
//       decoration: BoxDecoration(
//         color: isSelected
//             ? Colors.teal.shade50
//             : Colors.grey.shade50,
//         borderRadius: BorderRadius.circular(11),
//         border: Border.all(
//           color: isSelected
//               ? primaryColor
//               : Colors.grey.shade200,
//         ),
//       ),
//       child: Row(
//         children: [
//           const Icon(
//             Icons.calendar_today_outlined,
//             size: 15,
//             color: primaryColor,
//           ),
//           const SizedBox(width: 7),
//           Expanded(
//             flex: 3,
//             child: Text(
//               day,
//               style: const TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           const Icon(
//             Icons.access_time,
//             size: 15,
//             color: primaryColor,
//           ),
//           const SizedBox(width: 6),
//           Expanded(
//             flex: 4,
//             child: Text(
//               time,
//               style: const TextStyle(
//                 fontSize: 11,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           const SizedBox(width: 5),
//           SizedBox(
//             height: 33,
//             child: ElevatedButton(
//               onPressed: () => _selectSlot(day, time),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: isSelected
//                     ? darkPrimaryColor
//                     : primaryColor,
//                 foregroundColor: Colors.white,
//                 elevation: 0,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 11,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: Text(
//                 isSelected ? 'Selected' : 'Select',
//                 style: const TextStyle(fontSize: 10),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }























// import 'package:flutter/material.dart';
// import 'package:house_of_tutor/services/api_client.dart';
// import 'package:house_of_tutor/services/auth_store.dart';

// class StudentFindTutor extends StatefulWidget {
//   final int courseId;
//   final String courseName;
//   final double? userLat;
//   final double? userLng;

//   const StudentFindTutor({
//     super.key,
//     required this.courseId,
//     required this.courseName,
//     this.userLat,
//     this.userLng,
//   });

//   @override
//   State<StudentFindTutor> createState() => _StudentFindTutorState();
// }

// class _StudentFindTutorState extends State<StudentFindTutor> {
//   // ============================================================
//   // COLORS
//   // ============================================================

//   static const Color primaryColor = Color(0xff009688);
//   static const Color darkPrimaryColor = Color(0xff00695C);
//   static const Color backgroundColor = Color(0xffF5F7FA);

//   // ============================================================
//   // DATA
//   // ============================================================

//   bool isLoading = true;
//   bool isSubmitting = false;

//   List<dynamic> tutorsList = [];
//   List<dynamic> filteredTutors = [];

//   String errorMessage = '';

//   final TextEditingController searchController = TextEditingController();
//   final TextEditingController durationController = TextEditingController();

//   // Selected tutor IDs
//   final Set<int> selectedTutorIds = {};

//   // Selected day and time
//   String? selectedDay;
//   String? selectedTime;

//   // Learning mode
//   String learningMode = 'SpecificTime';
//   String learningDurationUnit = 'Hours';

//   @override
//   void initState() {
//     super.initState();
//     searchController.addListener(_filterTutors);
//     fetchTutors();
//   }

//   @override
//   void dispose() {
//     searchController.removeListener(_filterTutors);
//     searchController.dispose();
//     durationController.dispose();
//     super.dispose();
//   }

//   // ============================================================
//   // LOCATION
//   // ============================================================

//   Future<Map<String, double>?> _getUserLocation() async {
//     // First use the location passed from the previous screen.
//     if (widget.userLat != null &&
//         widget.userLng != null &&
//         _isValidLatitude(widget.userLat!) &&
//         _isValidLongitude(widget.userLng!)) {
//       return {
//         'latitude': widget.userLat!,
//         'longitude': widget.userLng!,
//       };
//     }

//     // If no location was passed, use AuthStore.
//     await AuthStore.instance.hydrate();

//     final double? lat = AuthStore.instance.lastLat;
//     final double? lng = AuthStore.instance.lastLng;

//     if (lat == null || lng == null) return null;
//     if (!_isValidLatitude(lat) || !_isValidLongitude(lng)) {
//       return null;
//     }

//     return {
//       'latitude': lat,
//       'longitude': lng,
//     };
//   }

//   bool _isValidLatitude(double value) {
//     return value >= -90 && value <= 90;
//   }

//   bool _isValidLongitude(double value) {
//     return value >= -180 && value <= 180;
//   }

//   // ============================================================
//   // SAFE VALUE HELPERS
//   // ============================================================

//   String _displayValue(dynamic value, [String fallback = 'Not provided']) {
//     if (value == null) return fallback;

//     final String result = value.toString().trim();

//     if (result.isEmpty || result.toLowerCase() == 'null') {
//       return fallback;
//     }

//     return result;
//   }

//   // Get the first available value from the API response.
//   dynamic _firstValue(Map item, List<String> keys) {
//     for (final key in keys) {
//       final value = item[key];

//       if (value != null && value.toString().trim().isNotEmpty) {
//         return value;
//       }
//     }

//     return null;
//   }

//   double _toDouble(dynamic value) {
//     if (value is num) return value.toDouble();
//     return double.tryParse(value?.toString().trim() ?? '') ?? 0.0;
//   }

//   int _toInt(dynamic value) {
//     if (value is num) return value.toInt();
//     return int.tryParse(value?.toString().trim() ?? '') ?? 0;
//   }

//   int? _toIntNullable(dynamic value) {
//     if (value is int) return value;
//     if (value is num) return value.toInt();

//     return int.tryParse(value?.toString().trim() ?? '');
//   }

//   // ============================================================
//   // TUTOR DETAILS
//   // These field names support different API naming styles.
//   // ============================================================

//   String _getTutorName(dynamic tutor) {
//     if (tutor is! Map) return 'Tutor';

//     return _displayValue(
//       _firstValue(tutor, [
//         'tutor_name',
//         'tutorName',
//         'name',
//         'full_name',
//         'fullName',
//       ]),
//       'Tutor',
//     );
//   }

//   String _getInstitute(dynamic tutor) {
//     if (tutor is! Map) return 'Not provided';

//     return _displayValue(
//       _firstValue(tutor, [
//         'institute',
//         'Institute',
//         'tutor_institute',
//         'tutorInstitute',
//         'institute_name',
//         'instituteName',
//         'institution',
//         'institution_name',
//         'institutionName',
//       ]),
//     );
//   }

//   String _getGrade(dynamic tutor) {
//     if (tutor is! Map) return 'Not provided';

//     return _displayValue(
//       _firstValue(tutor, [
//         'grade',
//         'Grade',
//         'tutor_grade',
//         'tutorGrade',
//         'course_grade',
//         'courseGrade',
//       ]),
//     );
//   }

//   String _getHourlyPrice(dynamic tutor) {
//     if (tutor is! Map) return 'Not provided';

//     final dynamic price = _firstValue(tutor, [
//       'hourly_rate',
//       'hourlyRate',
//       'hourly_fee',
//       'hourlyFee',
//       'price',
//       'fee',
//       'Fee',
//       'rate',
//       'Rate',
//     ]);

//     if (price == null) return 'Not provided';

//     final double? amount = double.tryParse(price.toString());

//     if (amount == null) return 'Not provided';

//     final String formatted = amount == amount.roundToDouble()
//         ? amount.toStringAsFixed(0)
//         : amount.toStringAsFixed(2);

//     return 'Rs. $formatted / hour';
//   }

//   int? _getTutorId(dynamic tutor) {
//     if (tutor is! Map) return null;

//     return _toIntNullable(
//       _firstValue(tutor, [
//         'tutor_id',
//         'tutorId',
//         'id',
//       ]),
//     );
//   }

//   double _getRating(dynamic tutor) {
//     if (tutor is! Map) return 0;

//     return _toDouble(
//       _firstValue(tutor, [
//         'average_rating',
//         'averageRating',
//         'rating',
//         'Rating',
//       ]),
//     );
//   }

//   int _getReviewCount(dynamic tutor) {
//     if (tutor is! Map) return 0;

//     return _toInt(
//       _firstValue(tutor, [
//         'total_reviews',
//         'totalReviews',
//         'reviews_count',
//         'review_count',
//         'reviewCount',
//       ]),
//     );
//   }

//   // ============================================================
//   // AVAILABLE SLOTS
//   // ============================================================

//   bool _isSlotAvailable(dynamic slot) {
//     if (slot is! Map) return false;

//     final value = slot['is_available'];

//     return value == true ||
//         value?.toString().trim().toLowerCase() == 'true' ||
//         value?.toString().trim() == '1';
//   }

//   List<dynamic> _getSlots(dynamic tutor) {
//     if (tutor is! Map) return [];

//     dynamic rawSlots;

//     if (tutor['common_slots'] is List) {
//       rawSlots = tutor['common_slots'];
//     } else if (tutor['available_slots'] is List) {
//       rawSlots = tutor['available_slots'];
//     } else if (tutor['slots'] is List) {
//       rawSlots = tutor['slots'];
//     }

//     if (rawSlots is! List) return [];

//     return rawSlots.where((slot) {
//       if (slot is! Map) return false;

//       final day = slot['day']?.toString().trim() ?? '';
//       final time = slot['time']?.toString().trim() ?? '';

//       return _isSlotAvailable(slot) && day.isNotEmpty && time.isNotEmpty;
//     }).map((slot) {
//       return Map<String, dynamic>.from(slot as Map);
//     }).toList();
//   }

//   // ============================================================
//   // MERGE DUPLICATE TUTOR RECORDS
//   // ============================================================

//   List<dynamic> _mergeTutorsById(List<dynamic> input) {
//     final Map<int, Map<String, dynamic>> tutorMap = {};
//     final List<Map<String, dynamic>> tutorsWithoutId = [];

//     for (final item in input) {
//       if (item is! Map) continue;

//       final tutor = Map<String, dynamic>.from(item);
//       final int? tutorId = _getTutorId(tutor);
//       final slots = _getSlots(tutor);

//       if (tutorId == null) {
//         tutor['common_slots'] = slots;
//         tutorsWithoutId.add(tutor);
//         continue;
//       }

//       if (!tutorMap.containsKey(tutorId)) {
//         tutor['common_slots'] = <Map<String, dynamic>>[];
//         tutorMap[tutorId] = tutor;
//       }

//       final existing = tutorMap[tutorId]!;
//       final List<dynamic> existingSlots =
//           existing['common_slots'] as List<dynamic>;

//       for (final slot in slots) {
//         final bool alreadyExists = existingSlots.any((oldSlot) {
//           return oldSlot is Map &&
//               oldSlot['day'].toString().trim().toLowerCase() ==
//                   slot['day'].toString().trim().toLowerCase() &&
//               oldSlot['time'].toString().trim().toLowerCase() ==
//                   slot['time'].toString().trim().toLowerCase();
//         });

//         if (!alreadyExists) {
//           existingSlots.add(slot);
//         }
//       }

//       // Keep information that might be missing in the first record.
//       for (final key in [
//         'tutor_name',
//         'name',
//         'grade',
//         'institute',
//         'hourly_rate',
//         'location',
//         'average_rating',
//         'total_reviews',
//       ]) {
//         final oldValue = existing[key];
//         final newValue = tutor[key];

//         if ((oldValue == null || oldValue.toString().trim().isEmpty) &&
//             newValue != null) {
//           existing[key] = newValue;
//         }
//       }
//     }

//     final List<dynamic> result = [
//       ...tutorMap.values,
//       ...tutorsWithoutId,
//     ];

//     // Only show tutors with at least one available slot.
//     return result.where((tutor) => _getSlots(tutor).isNotEmpty).toList();
//   }

//   // ============================================================
//   // FETCH TUTORS FROM BACKEND
//   // ============================================================

//   Future<void> fetchTutors() async {
//     if (!mounted) return;

//     setState(() {
//       isLoading = true;
//       errorMessage = '';
//     });

//     try {
//       final location = await _getUserLocation();

//       if (location == null) {
//         if (!mounted) return;

//         setState(() {
//           errorMessage =
//               'Your location is not available.\n'
//               'Please login again to update your location.';
//           tutorsList = [];
//           filteredTutors = [];
//           isLoading = false;
//         });

//         return;
//       }

//       final double userLat = location['latitude']!;
//       final double userLng = location['longitude']!;

//       final String endpoint =
//           '/api/Student/search-by-time-location-visiting-tutor'
//           '?userLat=${Uri.encodeQueryComponent(userLat.toString())}'
//           '&userLng=${Uri.encodeQueryComponent(userLng.toString())}'
//           '&courseId=${widget.courseId}';

//       debugPrint('Tutor Search API: $endpoint');

//       final response = await ApiClient.get(endpoint);

//       debugPrint('Tutor Search Status: ${response.statusCode}');
//       debugPrint('Tutor Search Response: ${response.body}');

//       if (!mounted) return;

//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         final data = await ApiClient.decodeJson(response);

//         List<dynamic> tutors = [];

//         if (data is List) {
//           tutors = data;
//         } else if (data is Map) {
//           final possibleData =
//               data['data'] ?? data['tutors'] ?? data['results'];

//           if (possibleData is List) {
//             tutors = possibleData;
//           }
//         }

//         final mergedTutors = _mergeTutorsById(tutors);

//         setState(() {
//           tutorsList = mergedTutors;
//           filteredTutors = List<dynamic>.from(mergedTutors);
//           errorMessage = '';
//           isLoading = false;
//         });
//       } else {
//         final message = ApiClient.messageFromBody(response.body) ??
//             'No tutors available in your area.';

//         setState(() {
//           errorMessage = message;
//           tutorsList = [];
//           filteredTutors = [];
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('StudentFindTutor Error: $e');

//       if (!mounted) return;

//       setState(() {
//         errorMessage = 'Unable to find tutors.\n$e';
//         tutorsList = [];
//         filteredTutors = [];
//         isLoading = false;
//       });
//     }
//   }

//   // ============================================================
//   // SEARCH TUTORS BY NAME
//   // ============================================================

//   void _filterTutors() {
//     if (!mounted) return;

//     final query = searchController.text.trim().toLowerCase();

//     if (query.isEmpty) {
//       setState(() {
//         filteredTutors = List<dynamic>.from(tutorsList);
//       });
//       return;
//     }

//     final results = tutorsList.where((tutor) {
//       return tutor is Map &&
//           _getTutorName(tutor).toLowerCase().contains(query);
//     }).toList();

//     setState(() {
//       filteredTutors = results;
//     });
//   }

//   // ============================================================
//   // SELECT / UNSELECT TUTOR
//   // ============================================================

//   bool _isTutorSelected(int? tutorId) {
//     return tutorId != null && selectedTutorIds.contains(tutorId);
//   }

//   void _toggleTutorSelection(int tutorId) {
//     setState(() {
//       if (selectedTutorIds.contains(tutorId)) {
//         selectedTutorIds.remove(tutorId);
//       } else {
//         selectedTutorIds.add(tutorId);
//       }
//     });
//   }

//   void _clearSelection() {
//     setState(() {
//       selectedTutorIds.clear();
//       selectedDay = null;
//       selectedTime = null;
//     });
//   }

//   // ============================================================
//   // SEND REQUEST TO SELECTED TUTORS
//   // ============================================================

//   Future<void> bookClassRequest() async {
//     if (selectedTutorIds.isEmpty) {
//       _showError('Please select at least one tutor.');
//       return;
//     }

//     if (selectedDay == null || selectedTime == null) {
//       _showError('Please select a day and time.');
//       return;
//     }

//     if (learningMode == 'SpecificTime') {
//       final duration = int.tryParse(durationController.text.trim());

//       if (duration == null || duration <= 0) {
//         _showError('Please enter a valid learning duration.');
//         return;
//       }
//     }

//     if (!mounted) return;

//     setState(() {
//       isSubmitting = true;
//     });

//     try {
//       int? duration;

//       if (learningMode == 'SpecificTime') {
//         duration = int.tryParse(durationController.text.trim());
//       }

//       String cleanTime = selectedTime!.trim();

//       if (cleanTime.contains(',')) {
//         cleanTime = cleanTime.split(',').last.trim();
//       }

//       final requestBody = <String, dynamic>{
//         'tutor_ids': selectedTutorIds.toList(),
//         'course_id': widget.courseId,
//         'day': selectedDay!.trim(),
//         'time': cleanTime,
//         'learning_mode': learningMode,
//         'learning_duration': duration,
//         'learning_duration_unit':
//             learningMode == 'SpecificTime' ? learningDurationUnit : null,
//       };

//       debugPrint('Create Request Body: $requestBody');

//       final response = await ApiClient.post(
//         '/api/Student/create-request',
//         requestBody,
//       );

//       debugPrint('Create Request Status: ${response.statusCode}');
//       debugPrint('Create Request Response: ${response.body}');

//       final data = await ApiClient.decodeJson(response);

//       if (!mounted) return;

//       setState(() {
//         isSubmitting = false;
//       });

//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         final message = data is Map
//             ? (data['message'] ?? 'Tutor request created successfully.')
//                 .toString()
//             : 'Tutor request created successfully.';

//         setState(() {
//           selectedTutorIds.clear();
//           selectedDay = null;
//           selectedTime = null;
//         });

//         _showSuccessDialog(message, data);
//       } else {
//         final message = data is Map
//             ? (data['message'] ??
//                     data['error'] ??
//                     'Failed to create tutor request.')
//                 .toString()
//             : ApiClient.messageFromBody(response.body) ??
//                 'Failed to create tutor request.';

//         _showError(message);
//       }
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isSubmitting = false;
//       });

//       _showError('Error creating request: $e');
//     }
//   }

//   // ============================================================
//   // SUCCESS DIALOG
//   // ============================================================

//   void _showSuccessDialog(String message, dynamic responseData) {
//     final currentTutor = responseData is Map
//         ? responseData['current_tutor_id']?.toString()
//         : null;

//     final totalTutors = responseData is Map
//         ? responseData['total_tutors']?.toString()
//         : null;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) {
//         return AlertDialog(
//           title: const Row(
//             children: [
//               Icon(Icons.check_circle, color: primaryColor),
//               SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   'Request Sent',
//                   style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ],
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(message),
//               if (totalTutors != null) ...[
//                 const SizedBox(height: 10),
//                 Text('Tutors selected: $totalTutors'),
//               ],
//               if (currentTutor != null) ...[
//                 const SizedBox(height: 6),
//                 Text(
//                   'First tutor ID: $currentTutor',
//                   style: const TextStyle(color: Colors.grey, fontSize: 13),
//                 ),
//               ],
//               const SizedBox(height: 12),
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: Colors.teal.shade50,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: const Text(
//                   'The first tutor has 2 minutes to accept. '
//                   'If the tutor does not accept, the request can move '
//                   'to the next queued tutor.',
//                   style: TextStyle(fontSize: 12, color: darkPrimaryColor),
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             ElevatedButton(
//               onPressed: () => Navigator.pop(dialogContext),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: primaryColor,
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // ============================================================
//   // BOOKING DIALOG
//   // ============================================================

//   void _showBookingDialog() {
//     if (selectedTutorIds.isEmpty) {
//       _showError('Please select at least one tutor first.');
//       return;
//     }

//     if (selectedDay == null || selectedTime == null) {
//       _showError('Please select an available day and time.');
//       return;
//     }

//     String dialogLearningMode = learningMode;
//     String dialogDurationUnit = learningDurationUnit;

//     final dialogDurationController = TextEditingController(
//       text: durationController.text,
//     );

//     showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               title: const Text(
//                 'Confirm Tutor Request',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               content: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Selected Tutors',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: Colors.teal.shade50,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Text(
//                         '${selectedTutorIds.length} tutor(s) selected',
//                         style: const TextStyle(
//                           color: darkPrimaryColor,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     const Text(
//                       'Selected Time',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     Text('$selectedDay - $selectedTime'),
//                     const SizedBox(height: 16),
//                     const Text(
//                       'Learning Mode',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     DropdownButtonFormField<String>(
//                       value: dialogLearningMode,
//                       decoration: const InputDecoration(
//                         border: OutlineInputBorder(),
//                       ),
//                       items: const [
//                         DropdownMenuItem(
//                           value: 'SpecificTime',
//                           child: Text('Specific Time'),
//                         ),
//                         DropdownMenuItem(
//                           value: 'FullTime',
//                           child: Text('Full Time'),
//                         ),
//                       ],
//                       onChanged: (value) {
//                         if (value == null) return;

//                         setDialogState(() {
//                           dialogLearningMode = value;
//                         });
//                       },
//                     ),
//                     if (dialogLearningMode == 'SpecificTime') ...[
//                       const SizedBox(height: 14),
//                       const Text(
//                         'Learning Duration',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 8),
//                       TextField(
//                         controller: dialogDurationController,
//                         keyboardType: TextInputType.number,
//                         decoration: const InputDecoration(
//                           hintText: 'Enter duration',
//                           border: OutlineInputBorder(),
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       DropdownButtonFormField<String>(
//                         value: dialogDurationUnit,
//                         decoration: const InputDecoration(
//                           border: OutlineInputBorder(),
//                         ),
//                         items: const [
//                           DropdownMenuItem(
//                             value: 'Hours',
//                             child: Text('Hours'),
//                           ),
//                           DropdownMenuItem(
//                             value: 'Days',
//                             child: Text('Days'),
//                           ),
//                           DropdownMenuItem(
//                             value: 'Weeks',
//                             child: Text('Weeks'),
//                           ),
//                         ],
//                         onChanged: (value) {
//                           if (value == null) return;

//                           setDialogState(() {
//                             dialogDurationUnit = value;
//                           });
//                         },
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(dialogContext),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: isSubmitting
//                       ? null
//                       : () async {
//                           learningMode = dialogLearningMode;
//                           learningDurationUnit = dialogDurationUnit;
//                           durationController.text =
//                               dialogDurationController.text.trim();

//                           Navigator.pop(dialogContext);
//                           await bookClassRequest();
//                         },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: primaryColor,
//                     foregroundColor: Colors.white,
//                   ),
//                   child: const Text('Send Request'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     ).then((_) {
//       dialogDurationController.dispose();
//     });
//   }

//   // ============================================================
//   // ERROR MESSAGE
//   // ============================================================

//   void _showError(String message) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   // ============================================================
//   // BUILD SCREEN
//   // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back_ios,
//             color: Colors.black87,
//             size: 20,
//           ),
//           onPressed: () => Navigator.pop(context),
//         ),
//         centerTitle: true,
//         title: Column(
//           children: [
//             const Text(
//               'TUTOR DISCOVERY',
//               style: TextStyle(
//                 fontSize: 10,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey,
//                 letterSpacing: 1.2,
//               ),
//             ),
//             const SizedBox(height: 2),
//             Text(
//               widget.courseName,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//           ],
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         child: Column(
//           children: [
//             if (selectedTutorIds.isNotEmpty)
//               Container(
//                 width: double.infinity,
//                 margin: const EdgeInsets.only(bottom: 12),
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.teal.shade50,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.teal.shade100),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.people, color: primaryColor),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         '${selectedTutorIds.length} tutor(s) selected',
//                         style: const TextStyle(
//                           color: darkPrimaryColor,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     TextButton(
//                       onPressed: _clearSelection,
//                       child: const Text('Clear'),
//                     ),
//                   ],
//                 ),
//               ),

//             // Search box
//             TextField(
//               controller: searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search tutors by name...',
//                 prefixIcon: const Icon(Icons.search, color: Colors.grey),
//                 filled: true,
//                 fillColor: Colors.white,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(14),
//                   borderSide: BorderSide(color: Colors.grey.shade200),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(14),
//                   borderSide: BorderSide(color: Colors.grey.shade200),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),

//             if (selectedTutorIds.isEmpty)
//               const Align(
//                 alignment: Alignment.centerLeft,
//                 child: Padding(
//                   padding: EdgeInsets.only(bottom: 8),
//                   child: Text(
//                     'Select tutors using the checkbox, then select a time slot.',
//                     style: TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                 ),
//               ),

//             Expanded(
//               child: isLoading
//                   ? const Center(
//                       child: CircularProgressIndicator(color: primaryColor),
//                     )
//                   : filteredTutors.isEmpty
//                       ? errorMessage.isNotEmpty
//                           ? _buildErrorView()
//                           : const Center(
//                               child: Text(
//                                 'No tutors found.',
//                                 style: TextStyle(color: Colors.grey),
//                               ),
//                             )
//                       : ListView.builder(
//                           itemCount: filteredTutors.length,
//                           itemBuilder: (context, index) {
//                             return _buildTutorCard(filteredTutors[index]);
//                           },
//                         ),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: selectedTutorIds.isNotEmpty
//           ? SafeArea(
//               child: Container(
//                 padding: const EdgeInsets.all(12),
//                 color: Colors.white,
//                 child: ElevatedButton.icon(
//                   onPressed: isSubmitting ? null : _showBookingDialog,
//                   icon: const Icon(Icons.send),
//                   label: Text(
//                     selectedDay != null && selectedTime != null
//                         ? 'Send Request to ${selectedTutorIds.length} Tutors'
//                         : 'Select Day & Time',
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: primaryColor,
//                     foregroundColor: Colors.white,
//                     minimumSize: const Size(double.infinity, 50),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//             )
//           : null,
//     );
//   }

//   // ============================================================
//   // ERROR VIEW
//   // ============================================================

//   Widget _buildErrorView() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.location_off, size: 50, color: Colors.grey.shade400),
//             const SizedBox(height: 15),
//             Text(
//               errorMessage,
//               textAlign: TextAlign.center,
//               style: const TextStyle(color: Colors.grey, fontSize: 15),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: fetchTutors,
//               icon: const Icon(Icons.refresh),
//               label: const Text('Try Again'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: primaryColor,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // TUTOR CARD
//   // Grade, Institute, and Price are displayed here.
//   // ============================================================

//   Widget _buildTutorCard(dynamic tutor) {
//     if (tutor is! Map) return const SizedBox.shrink();

//     final String tutorName = _getTutorName(tutor);

//     final String initials = tutorName.trim().isNotEmpty
//         ? tutorName
//             .trim()
//             .split(RegExp(r'\s+'))
//             .where((word) => word.isNotEmpty)
//             .map((word) => word[0])
//             .take(2)
//             .join()
//             .toUpperCase()
//         : 'T';

//     final double rating = _getRating(tutor);
//     final int reviews = _getReviewCount(tutor);
//     final double distance = _toDouble(tutor['distance']);

//     final String location = _displayValue(
//       _firstValue(tutor, ['location', 'address']),
//       'Location unavailable',
//     );

//     // These are the three fields you requested.
//     final String grade = _getGrade(tutor);
//     final String institute = _getInstitute(tutor);
//     final String hourlyPrice = _getHourlyPrice(tutor);

//     final List<dynamic> availableSlots = _getSlots(tutor);
//     final int? tutorId = _getTutorId(tutor);
//     final bool isSelected = _isTutorSelected(tutorId);

//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: isSelected ? primaryColor : Colors.transparent,
//           width: 1.5,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Tutor name and rating
//           Row(
//             children: [
//               Checkbox(
//                 value: isSelected,
//                 activeColor: primaryColor,
//                 onChanged: tutorId == null
//                     ? null
//                     : (_) => _toggleTutorSelection(tutorId),
//               ),
//               Container(
//                 width: 50,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color: Colors.teal.shade50,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Center(
//                   child: Text(
//                     initials,
//                     style: const TextStyle(
//                       color: primaryColor,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       tutorName,
//                       style: const TextStyle(
//                         fontSize: 17,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Row(
//                       children: [
//                         const Icon(Icons.star, size: 16, color: Colors.amber),
//                         const SizedBox(width: 4),
//                         Expanded(
//                           child: Text(
//                             '${rating.toStringAsFixed(1)} ($reviews reviews)',
//                             style: const TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           if (isSelected)
//             Container(
//               margin: const EdgeInsets.only(top: 8),
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//               decoration: BoxDecoration(
//                 color: Colors.teal.shade50,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: const Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.check_circle, size: 15, color: primaryColor),
//                   SizedBox(width: 5),
//                   Text(
//                     'Tutor selected',
//                     style: TextStyle(
//                       color: darkPrimaryColor,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//           const SizedBox(height: 14),

//           // Location and distance
//           Row(
//             children: [
//               const Icon(Icons.location_on, size: 16, color: Colors.grey),
//               const SizedBox(width: 5),
//               Expanded(
//                 child: Text(
//                   location,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               const Icon(Icons.near_me, size: 14, color: Colors.grey),
//               const SizedBox(width: 4),
//               Text(
//                 '${distance.toStringAsFixed(2)} km',
//                 style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//               ),
//             ],
//           ),

//           const SizedBox(height: 14),

//           // ========================================================
//           // NEW: GRADE
//           // ========================================================

//           _buildTutorDetail(
//             icon: Icons.school_outlined,
//             title: 'Grade',
//             value: grade,
//           ),

//           const SizedBox(height: 9),

//           // ========================================================
//           // NEW: INSTITUTE
//           // ========================================================

//           _buildTutorDetail(
//             icon: Icons.account_balance_outlined,
//             title: 'Institute',
//             value: institute,
//           ),

//           const SizedBox(height: 9),

//           // ========================================================
//           // NEW: HOURLY PRICE
//           // ========================================================

//           _buildTutorDetail(
//             icon: Icons.payments_outlined,
//             title: 'Price',
//             value: hourlyPrice,
//             valueColor: primaryColor,
//           ),

//           const SizedBox(height: 18),

//           // Available slots heading
//           const Row(
//             children: [
//               Icon(Icons.schedule, size: 18, color: primaryColor),
//               SizedBox(width: 6),
//               Text(
//                 'Available Time Slots',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 10),

//           if (availableSlots.isEmpty)
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Text(
//                 'No available slots.',
//                 style: TextStyle(color: Colors.grey, fontSize: 13),
//               ),
//             )
//           else
//             ...availableSlots.map((slot) {
//               return _buildAvailableSlot(
//                 day: slot['day'].toString().trim(),
//                 time: slot['time'].toString().trim(),
//               );
//             }),

//           const SizedBox(height: 8),

//           if (availableSlots.isNotEmpty)
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: Colors.teal.shade50,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Row(
//                 children: [
//                   Icon(Icons.info_outline, size: 16, color: darkPrimaryColor),
//                   SizedBox(width: 7),
//                   Expanded(
//                     child: Text(
//                       'Select a day and time, then select the tutors you want.',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: darkPrimaryColor,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // TUTOR DETAIL ROW
//   // ============================================================

//   Widget _buildTutorDetail({
//     required IconData icon,
//     required String title,
//     required String value,
//     Color? valueColor,
//   }) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade50,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, size: 20, color: primaryColor),
//           const SizedBox(width: 10),
//           SizedBox(
//             width: 72,
//             child: Text(
//               title,
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.grey.shade600,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               value,
//               textAlign: TextAlign.end,
//               style: TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.bold,
//                 color: valueColor ?? Colors.black87,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // AVAILABLE SLOT ROW
//   // ============================================================

//   Widget _buildAvailableSlot({
//     required String day,
//     required String time,
//   }) {
//     final bool isSelected =
//         selectedDay?.trim().toLowerCase() == day.trim().toLowerCase() &&
//         selectedTime?.trim().toLowerCase() == time.trim().toLowerCase();

//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//       decoration: BoxDecoration(
//         color: isSelected ? Colors.teal.shade100 : Colors.teal.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isSelected ? primaryColor : Colors.teal.shade100,
//         ),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 4,
//             child: Row(
//               children: [
//                 const Icon(
//                   Icons.calendar_today,
//                   size: 15,
//                   color: primaryColor,
//                 ),
//                 const SizedBox(width: 6),
//                 Expanded(
//                   child: Text(
//                     day,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w600,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             flex: 5,
//             child: Row(
//               children: [
//                 const Icon(
//                   Icons.access_time,
//                   size: 15,
//                   color: primaryColor,
//                 ),
//                 const SizedBox(width: 6),
//                 Expanded(
//                   child: Text(
//                     time,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w600,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               setState(() {
//                 selectedDay = day;
//                 selectedTime = time;
//               });
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: isSelected ? darkPrimaryColor : primaryColor,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//               minimumSize: const Size(0, 34),
//               elevation: 0,
//             ),
//             child: Text(
//               isSelected ? 'Selected' : 'Select',
//               style: const TextStyle(fontSize: 11),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }