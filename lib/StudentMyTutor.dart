import 'package:flutter/material.dart';
import 'package:house_of_tutor/services/api_client.dart';

class StudentMyTutor extends StatefulWidget {
  const StudentMyTutor({super.key});

  @override
  State<StudentMyTutor> createState() => _StudentMyTutorState();
}

class _StudentMyTutorState extends State<StudentMyTutor> {
  bool isLoading = true;
  List<dynamic> tutorsList = [];
  String errorMessage = '';

  // ============================================================
  // THEME COLOR
  // ============================================================
  final Color primaryColor = const Color(0xff009688);

  @override
  void initState() {
    super.initState();
    fetchMyTutors();
  }

  // ============================================================
  // FETCH MY TUTORS
  // ============================================================
  Future<void> fetchMyTutors() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
          errorMessage = '';
        });
      }

      final response = await ApiClient.get(
        '/api/Student/my-tutors',
      );

      if (response.statusCode == 200) {
        final data = await ApiClient.decodeJson(response);

        if (!mounted) return;

        setState(() {
          tutorsList = data is List ? data : [];
          isLoading = false;
        });
      } else {
        final msg = ApiClient.messageFromBody(response.body) ??
            'Failed to load tutors';

        if (!mounted) return;

        setState(() {
          errorMessage = msg;
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  // ============================================================
  // SAVE GRADE
  // ============================================================
  Future<void> saveGrade(int courseId, String grade) async {
    if (grade.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a grade'),
        ),
      );
      return;
    }

    try {
      final response = await ApiClient.post(
        '/api/Student/save-grade',
        {
          'courseId': courseId,
          'grade': grade.trim(),
        },
      );

      if (response.statusCode == 200) {
        await fetchMyTutors();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grade saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final msg = ApiClient.messageFromBody(response.body) ??
            'Failed to save grade';

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving grade: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // GIVE FEEDBACK
  // ============================================================
  Future<void> giveFeedback(
    int tutorId,
    int courseId,
    int rating,
    String comment,
  ) async {
    try {
      final response = await ApiClient.post(
        '/api/Student/give-feedback',
        {
          'tutorId': tutorId,
          'courseId': courseId,

          // IMPORTANT:
          // Rating selected from 1 to 5 stars
          'rating': rating,

          'comment': comment.trim(),
        },
      );

      if (response.statusCode == 200) {
        await fetchMyTutors();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final msg = ApiClient.messageFromBody(response.body) ??
            'Failed to submit feedback';

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // UPDATE GRADE DIALOG
  // ============================================================
  void showGradeDialog(
    int courseId,
    String currentGrade,
  ) {
    final TextEditingController gradeController =
        TextEditingController(text: currentGrade);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Update Grade',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: TextField(
            controller: gradeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Enter Grade (e.g. A, B+)',
              prefixIcon: const Icon(
                Icons.school_outlined,
                color: Color(0xff009688),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final grade = gradeController.text.trim();

                Navigator.pop(dialogContext);

                saveGrade(courseId, grade);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // FEEDBACK DIALOG WITH STAR RATING
  // ============================================================
  void showFeedbackDialog(
    int tutorId,
    int courseId,
  ) {
    // Default rating = 5 stars
    int rating = 5;

    final TextEditingController commentController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    color: Color(0xff009688),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Give Feedback',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // STAR RATING TITLE
                    // ==================================================
                    const Text(
                      'Rate your tutor',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ==================================================
                    // STAR RATING
                    // ==================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) {
                          final int starNumber = index + 1;

                          return IconButton(
                            tooltip: '$starNumber Star',
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                rating = starNumber;
                              });
                            },
                            icon: Icon(
                              starNumber <= rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber.shade700,
                              size: 34,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 4),

                    // ==================================================
                    // RATING TEXT
                    // ==================================================
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$rating / 5 Stars',
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // COMMENT
                    // ==================================================
                    const Text(
                      'Your Comment',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Write your feedback...',
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(
                            bottom: 55,
                          ),
                          child: Icon(
                            Icons.comment_outlined,
                            color: Color(0xff009688),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xff009688),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Cancel',
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    Icons.send,
                    size: 17,
                  ),
                  label: const Text(
                    'Submit',
                  ),
                  onPressed: () async {
                    // ==================================================
                    // COMMENT VALIDATION
                    // ==================================================
                    if (commentController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please write a comment',
                          ),
                        ),
                      );
                      return;
                    }

                    // Close dialog first
                    Navigator.pop(dialogContext);

                    // Send selected star rating
                    await giveFeedback(
                      tutorId,
                      courseId,
                      rating,
                      commentController.text,
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // GET INITIALS
  // ============================================================
  String getInitials(String name) {
    if (name.trim().isEmpty) {
      return 'T';
    }

    final parts = name.trim().split(' ');

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      // ============================================================
      // APP BAR
      // ============================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Image.asset(
          'assets/images/logo.png',
          height: 30,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return const Text(
              'House of Tutor',
              style: TextStyle(
                color: Color(0xff009688),
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),

        centerTitle: true,
      ),

      // ============================================================
      // BODY
      // ============================================================
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 45,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: fetchMyTutors,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // ==================================================
                      // PAGE TITLE
                      // ==================================================
                      const Text(
                        'My Tutors',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Track your coursework, grades, and tutor feedback',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // ==================================================
                      // TUTOR LIST
                      // ==================================================
                      Expanded(
                        child: tutorsList.isEmpty
                            ? RefreshIndicator(
                                color: primaryColor,
                                onRefresh: fetchMyTutors,
                                child: ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: const [
                                    SizedBox(height: 150),
                                    Center(
                                      child: Text(
                                        'No assigned tutors found.',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                color: primaryColor,
                                onRefresh: fetchMyTutors,
                                child: ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: tutorsList.length,
                                  itemBuilder:
                                      (context, index) {
                                    final tutor =
                                        tutorsList[index];

                                    final String tutorName =
                                        tutor['tutorName']
                                                ?.toString() ??
                                            'Tutor';

                                    final String courseName =
                                        tutor['courseName']
                                                ?.toString() ??
                                            '';

                                    final String grade =
                                        tutor['grade']
                                                ?.toString() ??
                                            '-';

                                    final bool isCompleted =
                                        tutor['isCompleted'] ==
                                            true;

                                    final bool feedbackGiven =
                                        tutor['feedbackGiven'] ==
                                            true;

                                    return Container(
                                      margin:
                                          const EdgeInsets.only(
                                        bottom: 14,
                                      ),
                                      padding:
                                          const EdgeInsets.all(
                                        14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(
                                          16,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 8,
                                            offset:
                                                const Offset(
                                              0,
                                              3,
                                            ),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          // ============================================
                                          // TUTOR HEADER
                                          // ============================================
                                          Row(
                                            children: [
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration:
                                                    BoxDecoration(
                                                  color: Colors
                                                      .teal
                                                      .shade50,
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                    12,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    getInitials(
                                                      tutorName,
                                                    ),
                                                    style:
                                                        const TextStyle(
                                                      color: Color(
                                                        0xff009688,
                                                      ),
                                                      fontWeight:
                                                          FontWeight
                                                              .bold,
                                                      fontSize:
                                                          17,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(
                                                width: 12,
                                              ),

                                              // Tutor name + course
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    Text(
                                                      tutorName,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow
                                                              .ellipsis,
                                                      style:
                                                          const TextStyle(
                                                        fontSize:
                                                            17,
                                                        fontWeight:
                                                            FontWeight
                                                                .bold,
                                                        color: Colors
                                                            .black87,
                                                      ),
                                                    ),

                                                    const SizedBox(
                                                      height: 4,
                                                    ),

                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .book_outlined,
                                                          size: 14,
                                                          color: Colors
                                                              .grey,
                                                        ),
                                                        const SizedBox(
                                                          width: 5,
                                                        ),
                                                        Expanded(
                                                          child:
                                                              Text(
                                                            courseName,
                                                            maxLines:
                                                                1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                TextStyle(
                                                              fontSize:
                                                                  13,
                                                              color: Colors
                                                                  .grey
                                                                  .shade600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(
                                                width: 8,
                                              ),

                                              // Grade
                                              Container(
                                                padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                  horizontal: 10,
                                                  vertical: 7,
                                                ),
                                                decoration:
                                                    BoxDecoration(
                                                  color: Colors
                                                      .teal
                                                      .shade50,
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                    10,
                                                  ),
                                                  border:
                                                      Border.all(
                                                    color: Colors
                                                        .teal
                                                        .shade100,
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    const Text(
                                                      'GRADE',
                                                      style:
                                                          TextStyle(
                                                        fontSize:
                                                            9,
                                                        fontWeight:
                                                            FontWeight
                                                                .bold,
                                                        color: Color(
                                                          0xff009688,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      height: 2,
                                                    ),
                                                    Text(
                                                      grade,
                                                      style:
                                                          const TextStyle(
                                                        fontSize:
                                                            15,
                                                        fontWeight:
                                                            FontWeight
                                                                .bold,
                                                        color: Color(
                                                          0xff00796B,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),

                                          // ============================================
                                          // DIVIDER
                                          // ============================================
                                          const Padding(
                                            padding:
                                                EdgeInsets.symmetric(
                                              vertical: 11,
                                            ),
                                            child: Divider(
                                              height: 1,
                                            ),
                                          ),

                                          // ============================================
                                          // COURSE STATUS
                                          // ============================================
                                          Row(
                                            children: [
                                              if (isCompleted)
                                                Container(
                                                  padding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    horizontal: 9,
                                                    vertical: 5,
                                                  ),
                                                  decoration:
                                                      BoxDecoration(
                                                    color: Colors
                                                        .green
                                                        .shade50,
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                      20,
                                                    ),
                                                  ),
                                                  child:
                                                      const Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .check_circle,
                                                        color: Colors
                                                            .green,
                                                        size: 14,
                                                      ),
                                                      SizedBox(
                                                        width: 4,
                                                      ),
                                                      Text(
                                                        'Course Completed',
                                                        style:
                                                            TextStyle(
                                                          color: Colors
                                                              .green,
                                                          fontSize:
                                                              11,
                                                          fontWeight:
                                                              FontWeight
                                                                  .w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              else
                                                Container(
                                                  padding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    horizontal: 9,
                                                    vertical: 5,
                                                  ),
                                                  decoration:
                                                      BoxDecoration(
                                                    color: Colors
                                                        .orange
                                                        .shade50,
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                      20,
                                                    ),
                                                  ),
                                                  child:
                                                      const Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .schedule,
                                                        color: Colors
                                                            .orange,
                                                        size: 14,
                                                      ),
                                                      SizedBox(
                                                        width: 4,
                                                      ),
                                                      Text(
                                                        'In Progress',
                                                        style:
                                                            TextStyle(
                                                          color: Colors
                                                              .orange,
                                                          fontSize:
                                                              11,
                                                          fontWeight:
                                                              FontWeight
                                                                  .w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),

                                          const SizedBox(
                                            height: 12,
                                          ),

                                          // ============================================
                                          // BUTTONS
                                          // ============================================
                                          Row(
                                            children: [
                                              // UPDATE GRADE
                                              Expanded(
                                                child:
                                                    OutlinedButton
                                                        .icon(
                                                  style:
                                                      OutlinedButton
                                                          .styleFrom(
                                                    foregroundColor:
                                                        primaryColor,
                                                    side:
                                                        BorderSide(
                                                      color:
                                                          primaryColor,
                                                    ),
                                                    minimumSize:
                                                        const Size(
                                                      0,
                                                      42,
                                                    ),
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 8,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                        10,
                                                      ),
                                                    ),
                                                  ),
                                                  icon:
                                                      const Icon(
                                                    Icons
                                                        .edit_outlined,
                                                    size: 17,
                                                  ),
                                                  label:
                                                      const Text(
                                                    'Update Grade',
                                                    style:
                                                        TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    showGradeDialog(
                                                      tutor[
                                                          'courseId'],
                                                      grade,
                                                    );
                                                  },
                                                ),
                                              ),

                                              const SizedBox(
                                                width: 9,
                                              ),

                                              // FEEDBACK
                                              Expanded(
                                                child: feedbackGiven
                                                    ? Container(
                                                        height: 42,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors
                                                              .teal
                                                              .shade50,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            10,
                                                          ),
                                                        ),
                                                        child:
                                                            const Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .verified,
                                                              color:
                                                                  Color(
                                                                0xff009688,
                                                              ),
                                                              size:
                                                                  16,
                                                            ),
                                                            SizedBox(
                                                              width:
                                                                  5,
                                                            ),
                                                            Text(
                                                              'Feedback Given',
                                                              style:
                                                                  TextStyle(
                                                                color:
                                                                    Color(
                                                                  0xff00796B,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize:
                                                                    11,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    : ElevatedButton
                                                        .icon(
                                                        style:
                                                            ElevatedButton
                                                                .styleFrom(
                                                          backgroundColor:
                                                              primaryColor,
                                                          foregroundColor:
                                                              Colors
                                                                  .white,
                                                          elevation:
                                                              0,
                                                          minimumSize:
                                                              const Size(
                                                            0,
                                                            42,
                                                          ),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal:
                                                                8,
                                                          ),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              10,
                                                            ),
                                                          ),
                                                        ),
                                                        icon:
                                                            const Icon(
                                                          Icons
                                                              .star_rate_outlined,
                                                          size:
                                                              18,
                                                        ),
                                                        label:
                                                            const Text(
                                                          'Feedback',
                                                          style:
                                                              TextStyle(
                                                            fontSize:
                                                                12,
                                                          ),
                                                        ),
                                                        onPressed:
                                                            () {
                                                          showFeedbackDialog(
                                                            tutor[
                                                                'tutorId'],
                                                            tutor[
                                                                'courseId'],
                                                          );
                                                        },
                                                      ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
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
}











































// //import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:house_of_tutor/services/api_client.dart';

// class StudentMyTutor extends StatefulWidget {
//   const StudentMyTutor({super.key});

//   @override
//   State<StudentMyTutor> createState() => _StudentMyTutorState();
// }

// class _StudentMyTutorState extends State<StudentMyTutor> {
//   bool isLoading = true;
//   List<dynamic> tutorsList = [];
//   String errorMessage = '';

//   @override
//   void initState() {
//     super.initState();
//     fetchMyTutors();
//   }

//   Future<void> fetchMyTutors() async {
//     try {
//       final response = await ApiClient.get('/api/Student/my-tutors');

//       if (response.statusCode == 200) {
//         final data = await ApiClient.decodeJson(response);
//         setState(() {
//           tutorsList = data is List ? data : [];
//           isLoading = false;
//         });
//       } else {
//         final msg = ApiClient.messageFromBody(response.body) ?? 'Failed to load tutors';
//         setState(() {
//           errorMessage = msg;
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         errorMessage = 'An error occurred: $e';
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> saveGrade(int courseId, String grade) async {
//     try {
//       final response = await ApiClient.post(
//         '/api/Student/save-grade',
//         {
//           'courseId': courseId,
//           'grade': grade,
//         },
//       );

//       if (response.statusCode == 200) {
//         fetchMyTutors(); // Refresh list
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Grade saved successfully')),
//         );
//       } else {
//         final msg = ApiClient.messageFromBody(response.body) ?? 'Failed to save grade';
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(msg)),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error saving grade: $e')),
//       );
//     }
//   }

//   Future<void> giveFeedback(int tutorId, int courseId, int rating, String comment) async {
//     try {
//       final response = await ApiClient.post(
//         '/api/Student/give-feedback',
//         {
//           'tutorId': tutorId,
//           'courseId': courseId,
//           'rating': rating,
//           'comment': comment,
//         },
//       );

//       if (response.statusCode == 200) {
//         fetchMyTutors(); // Refresh list
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Feedback submitted successfully')),
//         );
//       } else {
//         final msg = ApiClient.messageFromBody(response.body) ?? 'Failed to submit feedback';
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(msg)),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }

//   void showGradeDialog(int courseId, String currentGrade) {
//     TextEditingController gradeController = TextEditingController(text: currentGrade);
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Text("Update Grade"),
//         content: TextField(
//           controller: gradeController,
//           decoration: const InputDecoration(hintText: "Enter Grade (e.g. A, B+)"),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff009688), foregroundColor: Colors.white),
//             onPressed: () {
//               Navigator.pop(context);
//               saveGrade(courseId, gradeController.text);
//             },
//             child: const Text("Save"),
//           ),
//         ],
//       ),
//     );
//   }

//   void showFeedbackDialog(int tutorId, int courseId) {
//     int rating = 5;
//     TextEditingController commentController = TextEditingController();
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Text("Give Feedback"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: commentController,
//               decoration: const InputDecoration(hintText: "Write your comment here..."),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff009688), foregroundColor: Colors.white),
//             onPressed: () {
//               Navigator.pop(context);
//               giveFeedback(tutorId, courseId, rating, commentController.text);
//             },
//             child: const Text("Submit"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Image.asset(
//           'assets/images/logo.png',
//           height: 30,
//           errorBuilder: (context, error, stackTrace) => const Text(
//             "House of Tutor",
//             style: TextStyle(color: Color(0xff009688), fontWeight: FontWeight.bold),
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: isLoading
//           ? const Center(
//               child: CircularProgressIndicator(color: Color(0xff009688)),
//             )
//           : errorMessage.isNotEmpty
//               ? Center(
//                   child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
//                 )
//               : Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         "My Tutors",
//                         style: TextStyle(
//                           fontSize: 26,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         "Track your coursework, grades, and tutor feedback",
//                         style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//                       ),
//                       const SizedBox(height: 20),
//                       Expanded(
//                         child: tutorsList.isEmpty
//                             ? const Center(child: Text("No assigned tutors found."))
//                             : ListView.builder(
//                                 itemCount: tutorsList.length,
//                                 itemBuilder: (context, index) {
//                                   final tutor = tutorsList[index];
//                                   String tutorName = tutor['tutorName'] ?? 'Tutor';
//                                   String initials = tutorName.isNotEmpty
//                                       ? tutorName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
//                                       : 'T';

//                                   return Container(
//                                     margin: const EdgeInsets.only(bottom: 16),
//                                     padding: const EdgeInsets.all(16),
//                                     decoration: BoxDecoration(
//                                       color: Colors.white,
//                                       borderRadius: BorderRadius.circular(16),
//                                       boxShadow: [
//                                         BoxShadow(
//                                           color: Colors.black.withOpacity(0.05),
//                                           blurRadius: 10,
//                                           offset: const Offset(0, 4),
//                                         ),
//                                       ],
//                                     ),
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Row(
//                                           children: [
//                                             Container(
//                                               width: 50,
//                                               height: 50,
//                                               decoration: BoxDecoration(
//                                                 color: Colors.teal.shade50,
//                                                 borderRadius: BorderRadius.circular(12),
//                                               ),
//                                               child: Center(
//                                                 child: Text(
//                                                   initials,
//                                                   style: const TextStyle(
//                                                     color: Color(0xff009688),
//                                                     fontWeight: FontWeight.bold,
//                                                     fontSize: 18,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                             const SizedBox(width: 14),
//                                             Expanded(
//                                               child: Column(
//                                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                                 children: [
//                                                   Text(
//                                                     tutorName,
//                                                     style: const TextStyle(
//                                                       fontSize: 18,
//                                                       fontWeight: FontWeight.bold,
//                                                       color: Colors.black87,
//                                                     ),
//                                                   ),
//                                                   const SizedBox(height: 4),
//                                                   Row(
//                                                     children: [
//                                                       const Icon(Icons.book, size: 14, color: Colors.grey),
//                                                       const SizedBox(width: 6),
//                                                       Text(
//                                                         tutor['courseName'] ?? '',
//                                                         style: TextStyle(
//                                                           fontSize: 14,
//                                                           color: Colors.grey.shade600,
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                             Container(
//                                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                                               decoration: BoxDecoration(
//                                                 color: Colors.teal.shade50,
//                                                 borderRadius: BorderRadius.circular(12),
//                                                 border: Border.all(color: Colors.teal.shade100),
//                                               ),
//                                               child: Column(
//                                                 children: [
//                                                   const Text(
//                                                     "GRADE",
//                                                     style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal),
//                                                   ),
//                                                   Text(
//                                                     tutor['grade'] ?? '-',
//                                                     style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff00796B)),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         const Padding(
//                                           padding: EdgeInsets.symmetric(vertical: 12),
//                                           child: Divider(height: 1),
//                                         ),
//                                         Row(
//                                           children: [
//                                             if (tutor['isCompleted'] == true)
//                                               Container(
//                                                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                                                 decoration: BoxDecoration(
//                                                   color: Colors.green.shade50,
//                                                   borderRadius: BorderRadius.circular(20),
//                                                 ),
//                                                 child: Row(
//                                                   children: const [
//                                                     Icon(Icons.check_circle, color: Colors.green, size: 14),
//                                                     SizedBox(width: 4),
//                                                     Text("Course Completed", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
//                                                   ],
//                                                 ),
//                                               ),
//                                           ],
//                                         ),
//                                         const SizedBox(height: 12),
//                                         Row(
//                                           children: [
//                                             Expanded(
//                                               child: OutlinedButton.icon(
//                                                 style: OutlinedButton.styleFrom(
//                                                   foregroundColor: const Color(0xff009688),
//                                                   side: const BorderSide(color: Color(0xff009688)),
//                                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                                                 ),
//                                                 icon: const Icon(Icons.star_outline, size: 18),
//                                                 label: const Text("Update Grade"),
//                                                 onPressed: () => showGradeDialog(tutor['courseId'], tutor['grade'] ?? ''),
//                                               ),
//                                             ),
//                                             const SizedBox(width: 10),
//                                             Expanded(
//                                               child: tutor['feedbackGiven'] == true
//                                                   ? Container(
//                                                       padding: const EdgeInsets.symmetric(vertical: 12),
//                                                       decoration: BoxDecoration(
//                                                         color: Colors.teal.shade50,
//                                                         borderRadius: BorderRadius.circular(10),
//                                                       ),
//                                                       child: Row(
//                                                         mainAxisAlignment: MainAxisAlignment.center,
//                                                         children: const [
//                                                           Icon(Icons.verified, color: Color(0xff009688), size: 16),
//                                                           SizedBox(width: 6),
//                                                           Text("Feedback Given", style: TextStyle(color: Color(0xff00796B), fontWeight: FontWeight.w600, fontSize: 13)),
//                                                         ],
//                                                       ),
//                                                     )
//                                                   : ElevatedButton.icon(
//                                                       style: ElevatedButton.styleFrom(
//                                                         backgroundColor: const Color(0xff009688),
//                                                         foregroundColor: Colors.white,
//                                                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                                                         elevation: 0,
//                                                       ),
//                                                       icon: const Icon(Icons.rate_review, size: 18),
//                                                       label: const Text("Feedback"),
//                                                       onPressed: () => showFeedbackDialog(tutor['tutorId'], tutor['courseId']),
//                                                     ),
//                                             ),
//                                           ],
//                                         ),
//                                       ],
//                                     ),
//                                   );
//                                 },
//                               ),
//                       ),
//                     ],
//                   ),
//                 ),
//     );
//   }
// }

















// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'services/api_client.dart';

// // class StudentMyTutor extends StatefulWidget {
// //   const StudentMyTutor({super.key});

// //   @override
// //   State<StudentMyTutor> createState() => _StudentMyTutorState();
// // }

// // class _StudentMyTutorState extends State<StudentMyTutor> {
// //   bool loading = false;
// //   List<MyTutor> tutors = [];

// //   @override
// //   void initState() {
// //     super.initState();
// //     fetchTutors();
// //   }

// //   ////////////////////////////////////////////////////////////
// //   /// FETCH TUTORS
// //   ////////////////////////////////////////////////////////////
// //   Future<void> fetchTutors() async {
// //     try {
// //       if (mounted) {
// //         setState(() {
// //           loading = true;
// //         });
// //       }

// //       final response = await ApiClient.get("/api/Student/my-tutors");

// //       print(response.body);

// //       if (response.statusCode == 200) {
// //         final List data = jsonDecode(
// //           utf8.decode(response.bodyBytes),
// //         );

// //         tutors = data.map((e) => MyTutor.fromJson(e)).toList();

// //         if (mounted) {
// //           setState(() {});
// //         }
// //       } else {
// //         if (mounted) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(
// //               content: Text(
// //                 ApiClient.messageFromBody(response.body) ?? "Unable to load tutors",
// //               ),
// //             ),
// //           );
// //         }
// //       }
// //     } catch (e) {
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text("Error : $e"),
// //           ),
// //         );
// //       }
// //     } finally {
// //       if (mounted) {
// //         setState(() {
// //           loading = false;
// //         });
// //       }
// //     }
// //   }

// //   ////////////////////////////////////////////////////////////
// //   /// OPEN FEEDBACK DIALOG
// //   ////////////////////////////////////////////////////////////
// //   Future<void> openFeedbackDialog(MyTutor tutor) async {
// //     final commentController = TextEditingController();
// //     double rating = 5;

// //     await showDialog(
// //       context: context,
// //       builder: (dialogContext) {
// //         return StatefulBuilder(
// //           builder: (context, setDialogState) {
// //             return AlertDialog(
// //               title: Text("Feedback for ${tutor.tutorName}"),
// //               content: SingleChildScrollView(
// //                 child: Column(
// //                   mainAxisSize: MainAxisSize.min,
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const Text(
// //                       "Rating",
// //                       style: TextStyle(fontWeight: FontWeight.bold),
// //                     ),
// //                     const SizedBox(height: 10),
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.center,
// //                       children: List.generate(
// //                         5,
// //                         (index) {
// //                           return IconButton(
// //                             onPressed: () {
// //                               setDialogState(() {
// //                                 rating = (index + 1).toDouble();
// //                               });
// //                             },
// //                             icon: Icon(
// //                               index < rating ? Icons.star : Icons.star_border,
// //                               color: Colors.amber,
// //                               size: 35,
// //                             ),
// //                           );
// //                         },
// //                       ),
// //                     ),
// //                     const SizedBox(height: 20),
// //                     TextField(
// //                       controller: commentController,
// //                       maxLines: 5,
// //                       decoration: const InputDecoration(
// //                         labelText: "Comment",
// //                         hintText: "Write your feedback...",
// //                         border: OutlineInputBorder(),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //               actions: [
// //                 TextButton(
// //                   onPressed: () {
// //                     Navigator.pop(dialogContext);
// //                   },
// //                   child: const Text("Cancel"),
// //                 ),
// //                 ElevatedButton(
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: Colors.teal,
// //                   ),
// //                   onPressed: () async {
// //                     if (commentController.text.trim().isEmpty) {
// //                       ScaffoldMessenger.of(context).showSnackBar(
// //                         const SnackBar(
// //                           content: Text("Please write a comment"),
// //                         ),
// //                       );
// //                       return;
// //                     }

// //                     await submitFeedback(
// //                       tutorId: tutor.tutorId,
// //                       courseId: tutor.courseId,
// //                       rating: rating.toInt(),
// //                       comment: commentController.text,
// //                     );

// //                     if (mounted) {
// //                       Navigator.pop(dialogContext);
// //                     }
// //                   },
// //                   child: const Text("Submit"),
// //                 ),
// //               ],
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }

// //   ////////////////////////////////////////////////////////////
// //   /// SUBMIT FEEDBACK
// //   ////////////////////////////////////////////////////////////
// //   Future<void> submitFeedback({
// //     required int tutorId,
// //     required int courseId,
// //     required int rating,
// //     required String comment,
// //   }) async {
// //     try {
// //       final response = await ApiClient.post(
// //         "/api/Student/give-feedback",
// //         {
// //           "tutorId": tutorId,
// //           "courseId": courseId,
// //           "rating": rating,
// //           "comment": comment,
// //         },
// //       );

// //       print(response.body);

// //       if (response.statusCode == 200) {
// //         if (mounted) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             const SnackBar(
// //               content: Text("Feedback submitted successfully"),
// //             ),
// //           );
// //           fetchTutors();
// //         }
// //       } else {
// //         if (mounted) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             SnackBar(
// //               content: Text(
// //                 ApiClient.messageFromBody(response.body) ?? "Unable to submit feedback",
// //               ),
// //             ),
// //           );
// //         }
// //       }
// //     } catch (e) {
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text("Error : $e"),
// //           ),
// //         );
// //       }
// //     }
// //   }

// //   ////////////////////////////////////////////////////////////
// //   /// BUILD METHOD
// //   ////////////////////////////////////////////////////////////
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("My Tutors"),
// //         centerTitle: true,
// //         backgroundColor: Colors.teal,
// //       ),
// //       body: loading
// //           ? const Center(
// //               child: CircularProgressIndicator(),
// //             )
// //           : tutors.isEmpty
// //               ? const Center(
// //                   child: Text("No tutors found"),
// //                 )
// //               : RefreshIndicator(
// //                   onRefresh: fetchTutors,
// //                   child: ListView.builder(
// //                     padding: const EdgeInsets.all(15),
// //                     itemCount: tutors.length,
// //                     itemBuilder: (context, index) {
// //                       final tutor = tutors[index];

// //                       return Card(
// //                         margin: const EdgeInsets.only(bottom: 15),
// //                         elevation: 4,
// //                         shape: RoundedRectangleBorder(
// //                           borderRadius: BorderRadius.circular(15),
// //                         ),
// //                         child: Padding(
// //                           padding: const EdgeInsets.all(16),
// //                           child: Column(
// //                             crossAxisAlignment: CrossAxisAlignment.start,
// //                             children: [
// //                               Row(
// //                                 children: [
// //                                   const CircleAvatar(
// //                                     radius: 28,
// //                                     backgroundColor: Colors.teal,
// //                                     child: Icon(
// //                                       Icons.person,
// //                                       color: Colors.white,
// //                                       size: 30,
// //                                     ),
// //                                   ),
// //                                   const SizedBox(width: 15),
// //                                   Expanded(
// //                                     child: Column(
// //                                       crossAxisAlignment: CrossAxisAlignment.start,
// //                                       children: [
// //                                         Text(
// //                                           tutor.tutorName,
// //                                           style: const TextStyle(
// //                                             fontWeight: FontWeight.bold,
// //                                             fontSize: 18,
// //                                           ),
// //                                         ),
// //                                         const SizedBox(height: 5),
// //                                         Text(tutor.courseName),
// //                                       ],
// //                                     ),
// //                                   ),
// //                                 ],
// //                               ),
// //                               const SizedBox(height: 20),
// //                               Row(
// //                                 children: [
// //                                   badge(
// //                                     tutor.isCompleted ? "Completed" : "In Progress",
// //                                     tutor.isCompleted ? Colors.green : Colors.orange,
// //                                   ),
// //                                   const SizedBox(width: 10),
// //                                   badge(
// //                                     tutor.feedbackGiven ? "Feedback Given" : "Pending",
// //                                     tutor.feedbackGiven ? Colors.blue : Colors.red,
// //                                   ),
// //                                 ],
// //                               ),
// //                               const SizedBox(height: 20),
// //                               SizedBox(
// //                                 width: double.infinity,
// //                                 child: ElevatedButton(
// //                                   style: ElevatedButton.styleFrom(
// //                                     backgroundColor: Colors.teal,
// //                                   ),
// //                                   onPressed: tutor.feedbackGiven
// //                                       ? null
// //                                       : () => openFeedbackDialog(tutor),
// //                                   child: Text(
// //                                     tutor.feedbackGiven ? "Feedback Submitted" : "Give Feedback",
// //                                   ),
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       );
// //                     },
// //                   ),
// //                 ),
// //     );
// //   }
// // }

// // ////////////////////////////////////////////////////////////
// // /// BADGE WIDGET (Global Helpmethod)
// // ////////////////////////////////////////////////////////////
// // Widget badge(String text, Color color) {
// //   return Container(
// //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// //     decoration: BoxDecoration(
// //       color: color.withOpacity(.15),
// //       borderRadius: BorderRadius.circular(20),
// //     ),
// //     child: Text(
// //       text,
// //       style: TextStyle(
// //         color: color,
// //         fontWeight: FontWeight.bold,
// //       ),
// //     ),
// //   );
// // }

// // ////////////////////////////////////////////////////////////
// // /// MODEL
// // ////////////////////////////////////////////////////////////
// // class MyTutor {
// //   final int tutorId;
// //   final String tutorName;
// //   final int courseId;
// //   final String courseName;
// //   final bool isCompleted;
// //   final String completedDate;
// //   final bool feedbackGiven;

// //   MyTutor({
// //     required this.tutorId,
// //     required this.tutorName,
// //     required this.courseId,
// //     required this.courseName,
// //     required this.isCompleted,
// //     required this.completedDate,
// //     required this.feedbackGiven,
// //   });

// //   factory MyTutor.fromJson(Map<String, dynamic> json) {
// //     return MyTutor(
// //       tutorId: json["tutorId"] ?? 0,
// //       tutorName: json["tutorName"] ?? "",
// //       courseId: json["courseId"] ?? 0,
// //       courseName: json["courseName"] ?? "",
// //       isCompleted: json["isCompleted"] ?? false,
// //       completedDate: json["completedDate"]?.toString() ?? "",
// //       feedbackGiven: json["feedbackGiven"] ?? false,
// //     );
// //   }
// // }