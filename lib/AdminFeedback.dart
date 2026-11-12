import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:house_of_tutor/services/api_client.dart';

class AdminFeedback extends StatefulWidget {
  const AdminFeedback({super.key});

  @override
  State<AdminFeedback> createState() => _AdminFeedbackState();
}

class _AdminFeedbackState extends State<AdminFeedback> {
  // =====================================================
  // DATA
  // =====================================================

  List<Map<String, dynamic>> feedbackList = [];
  List<Map<String, dynamic>> filteredFeedbackList = [];

  bool isLoading = true;

  String selectedRating = "All";
  String searchText = "";

  final TextEditingController searchController =
      TextEditingController();

  // =====================================================
  // THEME COLOR
  // =====================================================

  final Color primaryColor = const Color(0xFF159B86);

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();
    getFeedback();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // =====================================================
  // GET ALL FEEDBACK
  // =====================================================

  Future<void> getFeedback() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiClient.get(
        "/api/Admin/all-feedback",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        if (data is List) {
          feedbackList = List<Map<String, dynamic>>.from(
            data.map(
              (item) => Map<String, dynamic>.from(item),
            ),
          );

          applyFilters();
        }
      } else {
        showMessage("Failed to load feedback.");
      }
    } catch (e) {
      debugPrint("Feedback error: $e");
      showMessage("Error loading feedback.");
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // =====================================================
  // DELETE FEEDBACK
  // =====================================================

  Future<void> deleteFeedback(int id) async {
    try {
      final response = await ApiClient.delete(
        "/api/Admin/delete-feedback/$id",
      );

      if (response.statusCode == 200) {
        showMessage(
          "Feedback deleted successfully.",
          success: true,
        );

        await getFeedback();
      } else {
        showMessage("Unable to delete feedback.");
      }
    } catch (e) {
      showMessage("Error deleting feedback.");
    }
  }

  // =====================================================
  // DELETE CONFIRMATION
  // =====================================================

  void showDeleteConfirmation(
    int id,
    String studentName,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Delete Feedback",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Are you sure you want to delete feedback from \"$studentName\"?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                deleteFeedback(id);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // SEARCH + RATING FILTER
  // =====================================================

  void applyFilters() {
    final search = searchText.trim().toLowerCase();

    final result = feedbackList.where((feedback) {
      final studentName =
          (feedback["studentName"] ?? "")
              .toString()
              .toLowerCase();

      final tutorName =
          (feedback["tutorName"] ?? "")
              .toString()
              .toLowerCase();

      final courseName =
          (feedback["courseName"] ?? "")
              .toString()
              .toLowerCase();

      final feedbackText =
          (feedback["feedbackText"] ?? "")
              .toString()
              .toLowerCase();

      final rating =
          double.tryParse(
                (feedback["rating"] ?? 0).toString(),
              ) ??
              0;

      final matchesSearch =
          search.isEmpty ||
          studentName.contains(search) ||
          tutorName.contains(search) ||
          courseName.contains(search) ||
          feedbackText.contains(search);

      bool matchesRating = true;

      if (selectedRating != "All") {
        final selected =
            double.tryParse(selectedRating) ?? 0;

        matchesRating = rating == selected;
      }

      return matchesSearch && matchesRating;
    }).toList();

    if (mounted) {
      setState(() {
        filteredFeedbackList = result;
      });
    }
  }

  // =====================================================
  // AVERAGE RATING
  // =====================================================

  double getAverageRating() {
    if (feedbackList.isEmpty) {
      return 0;
    }

    double total = 0;

    for (final feedback in feedbackList) {
      total +=
          double.tryParse(
            (feedback["rating"] ?? 0).toString(),
          ) ??
          0;
    }

    return total / feedbackList.length;
  }

  // =====================================================
  // POSITIVE FEEDBACK
  // 4 OR 5 STAR
  // =====================================================

  int getPositivePercentage() {
    if (feedbackList.isEmpty) {
      return 0;
    }

    int positive = 0;

    for (final feedback in feedbackList) {
      final rating =
          double.tryParse(
            (feedback["rating"] ?? 0).toString(),
          ) ??
          0;

      if (rating >= 4) {
        positive++;
      }
    }

    return ((positive / feedbackList.length) * 100).round();
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void showMessage(
    String message, {
    bool success = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =====================================================
  // GET RATING
  // =====================================================

  double getRating(
    Map<String, dynamic> feedback,
  ) {
    return double.tryParse(
          (feedback["rating"] ?? 0).toString(),
        ) ??
        0;
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      // ===================================================
      // TOP APP BAR
      // NOW SHOWING LOGO INSTEAD OF FEEDBACK MANAGEMENT
      // ===================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 19,
            color: Color(0xFF172033),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        // =================================================
        // LOGO
        // CHANGE IMAGE PATH HERE IF YOUR LOGO LOCATION
        // IS DIFFERENT
        // =================================================

        title: Image.asset(
          'assets/images/logo.png',
          height: 32,

          // If logo is not found, show text
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return const Text(
              "House of Tutor",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF159B86),
              ),
            );
          },
        ),

        centerTitle: true,

        actions: [
          IconButton(
            onPressed: getFeedback,
            icon: const Icon(
              Icons.refresh,
              size: 22,
              color: Color(0xFF617184),
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),

      // ===================================================
      // BODY
      // ===================================================

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: getFeedback,

          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),

            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              25,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // =================================================
                // PAGE TITLE
                // =================================================

                const Text(
                  "Feedback Management",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF121B2E),
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  "Review student ratings and feedback",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF657386),
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // STAT CARDS
                // =================================================

                Row(
                  children: [
                    Expanded(
                      child: buildStatCard(
                        icon: Icons.rate_review,
                        iconColor:
                            const Color(0xFF249987),
                        iconBackground:
                            const Color(0xFFEAF0FF),
                        value:
                            feedbackList.length.toString(),
                        title: "Reviews",
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: buildStatCard(
                        icon: Icons.star,
                        iconColor:
                            const Color(0xFFEBA900),
                        iconBackground:
                            const Color(0xFFFFF5C9),
                        value: getAverageRating()
                            .toStringAsFixed(1),
                        title: "Avg Rating",
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: buildStatCard(
                        icon: Icons.thumb_up,
                        iconColor:
                            const Color(0xFF1EAA58),
                        iconBackground:
                            const Color(0xFFDDF8E8),
                        value:
                            "${getPositivePercentage()}%",
                        title: "Positive",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // =================================================
                // SEARCH
                // =================================================

                Container(
                  height: 50,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          const Color(0xFFDDE2E7),
                    ),
                  ),

                  child: TextField(
                    controller: searchController,

                    onChanged: (value) {
                      searchText = value;
                      applyFilters();
                    },

                    style: const TextStyle(
                      fontSize: 14,
                    ),

                    decoration:
                        const InputDecoration(
                      border: InputBorder.none,

                      prefixIcon: Icon(
                        Icons.search,
                        size: 22,
                        color: Color(0xFF66798D),
                      ),

                      hintText:
                          "Search student, tutor or course",

                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9AA8B8),
                      ),

                      contentPadding:
                          EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // =================================================
                // RATING FILTERS
                // =================================================

                SingleChildScrollView(
                  scrollDirection:
                      Axis.horizontal,

                  child: Row(
                    children: [
                      buildRatingFilter("All"),
                      buildRatingFilter("5"),
                      buildRatingFilter("4"),
                      buildRatingFilter("3"),
                      buildRatingFilter("2"),
                      buildRatingFilter("1"),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // =================================================
                // FEEDBACK LIST
                // =================================================

                if (isLoading)
                  const Padding(
                    padding:
                        EdgeInsets.only(top: 60),
                    child: Center(
                      child:
                          CircularProgressIndicator(
                        color:
                            Color(0xFF159B86),
                      ),
                    ),
                  )
                else if (filteredFeedbackList.isEmpty)
                  buildEmptyState()
                else
                  Column(
                    children:
                        filteredFeedbackList.map(
                      (feedback) {
                        return buildFeedbackCard(
                          feedback,
                        );
                      },
                    ).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // STAT CARD
  // =====================================================

  Widget buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String value,
    required String title,
  }) {
    return Container(
      height: 125,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE0E4E8),
        ),
      ),

      padding: const EdgeInsets.all(10),

      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius:
                  BorderRadius.circular(10),
            ),

            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF121B2E),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF69778A),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // RATING FILTER
  // =====================================================

  Widget buildRatingFilter(
    String rating,
  ) {
    final isSelected =
        selectedRating == rating;

    final text = rating == "All"
        ? "All"
        : "$rating ★";

    return Padding(
      padding:
          const EdgeInsets.only(right: 8),

      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedRating = rating;
          });

          applyFilters();
        },

        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 8,
          ),

          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor
                : Colors.white,

            borderRadius:
                BorderRadius.circular(20),

            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : const Color(0xFFDCE2E7),
            ),
          ),

          child: Text(
            text,

            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : const Color(0xFF667487),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // FEEDBACK CARD
  // =====================================================

  Widget buildFeedbackCard(
    Map<String, dynamic> feedback,
  ) {
    final id =
        int.tryParse(
              (feedback["id"] ?? 0).toString(),
            ) ??
            0;

    final studentName =
        (feedback["studentName"] ?? "")
            .toString();

    final tutorName =
        (feedback["tutorName"] ?? "")
            .toString();

    final courseName =
        (feedback["courseName"] ?? "")
            .toString();

    final feedbackText =
        (feedback["feedbackText"] ?? "")
            .toString();

    final date =
        (feedback["date"] ?? "")
            .toString();

    final time =
        (feedback["time"] ?? "")
            .toString();

    final feedbackBy =
        (feedback["feedbackBy"] ?? "")
            .toString();

    final rating =
        getRating(feedback);

    final initials =
        getInitials(studentName);

    return Container(
      width: double.infinity,

      margin:
          const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color: const Color(0xFFE0E4E8),
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // =================================================
          // STUDENT HEADER
          // =================================================

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // PROFILE
              Container(
                width: 46,
                height: 46,

                decoration:
                    const BoxDecoration(
                  color: Color(0xFFEFF2FF),
                  shape: BoxShape.circle,
                ),

                child: Center(
                  child: Text(
                    initials,

                    style:
                        const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xFF239986),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // STUDENT + TUTOR
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      studentName.isEmpty
                          ? "Unknown Student"
                          : studentName,

                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF121B2E),
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      tutorName.isEmpty
                          ? "Tutor: Unknown"
                          : "Tutor: $tutorName",

                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            Color(0xFF69778A),
                      ),
                    ),

                    if (courseName.isNotEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.only(
                          top: 2,
                        ),

                        child: Text(
                          "Course: $courseName",

                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 11,
                            color:
                                Color(0xFF8996A5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // DELETE
              InkWell(
                borderRadius:
                    BorderRadius.circular(9),

                onTap: () {
                  showDeleteConfirmation(
                    id,
                    studentName,
                  );
                },

                child: Container(
                  width: 36,
                  height: 36,

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(0xFFFFF1F1),
                    borderRadius:
                        BorderRadius.circular(9),
                  ),

                  child: const Icon(
                    Icons.delete_outline,
                    size: 19,
                    color:
                        Color(0xFFE5484D),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // =================================================
          // FEEDBACK BY
          // =================================================

          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFEFF8F6),
                  borderRadius:
                      BorderRadius.circular(7),
                ),

                child: Text(
                  feedbackBy.isEmpty
                      ? "By: Student"
                      : "By: $feedbackBy",

                  style:
                      const TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xFF258F80),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // =================================================
          // FEEDBACK TEXT
          // =================================================

          Text(
            feedbackText.isEmpty
                ? "No feedback comment"
                : feedbackText,

            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFF273447),
            ),
          ),

          const SizedBox(height: 12),

          const Divider(
            height: 1,
            color: Color(0xFFE8EBEE),
          ),

          const SizedBox(height: 10),

          // =================================================
          // RATING + DATE
          // =================================================

          Row(
            children: [
              // STARS
              Row(
                children: List.generate(
                  5,
                  (index) {
                    return Icon(
                      index < rating.round()
                          ? Icons.star
                          : Icons.star_border,

                      color:
                          const Color(0xFFEBA900),

                      size: 19,
                    );
                  },
                ),
              ),

              const SizedBox(width: 7),

              Text(
                rating.toStringAsFixed(1),

                style:
                    const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFFC67800),
                ),
              ),

              const Spacer(),

              if (date.isNotEmpty ||
                  time.isNotEmpty)
                Flexible(
                  child: Text(
                    "$date ${time.isNotEmpty ? "• $time" : ""}",

                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      fontSize: 10,
                      color:
                          Color(0xFF8290A0),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // EMPTY STATE
  // =====================================================

  Widget buildEmptyState() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.symmetric(
        vertical: 45,
        horizontal: 20,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color: const Color(0xFFE0E4E8),
        ),
      ),

      child: const Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 42,
            color: Color(0xFF9AA8B8),
          ),

          SizedBox(height: 10),

          Text(
            "No Feedback Found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF273447),
            ),
          ),

          SizedBox(height: 4),

          Text(
            "There are no feedback records to display.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF8996A5),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // GET INITIALS
  // =====================================================

  String getInitials(String name) {
    if (name.trim().isEmpty) {
      return "ST";
    }

    final parts =
        name.trim().split(" ");

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return "${parts[0][0]}${parts[1][0]}"
        .toUpperCase();
  }
}

































// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:house_of_tutor/services/api_client.dart';

// class AdminFeedback extends StatefulWidget {
//   const AdminFeedback({super.key});

//   @override
//   State<AdminFeedback> createState() => _AdminFeedbackState();
// }

// class _AdminFeedbackState extends State<AdminFeedback> {
//   // =====================================================
//   // DATA
//   // =====================================================

//   List<Map<String, dynamic>> feedbackList = [];
//   List<Map<String, dynamic>> filteredFeedbackList = [];

//   bool isLoading = true;

//   String selectedRating = "All";
//   String searchText = "";

//   final TextEditingController searchController =
//       TextEditingController();

//   // =====================================================
//   // INIT
//   // =====================================================

//   @override
//   void initState() {
//     super.initState();
//     getFeedback();
//   }

//   @override
//   void dispose() {
//     searchController.dispose();
//     super.dispose();
//   }

//   // =====================================================
//   // GET ALL FEEDBACK
//   // =====================================================

//   Future<void> getFeedback() async {
//     if (!mounted) return;

//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final response = await ApiClient.get(
//         "/api/Admin/all-feedback",
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(
//           utf8.decode(response.bodyBytes),
//         );

//         if (data is List) {
//           feedbackList = List<Map<String, dynamic>>.from(
//             data.map(
//               (item) => Map<String, dynamic>.from(item),
//             ),
//           );

//           applyFilters();
//         }
//       } else {
//         showMessage("Failed to load feedback.");
//       }
//     } catch (e) {
//       debugPrint("Feedback error: $e");
//       showMessage("Error loading feedback.");
//     }

//     if (mounted) {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   // =====================================================
//   // DELETE FEEDBACK
//   // =====================================================

//   Future<void> deleteFeedback(int id) async {
//     try {
//       final response = await ApiClient.delete(
//         "/api/Admin/delete-feedback/$id",
//       );

//       if (response.statusCode == 200) {
//         showMessage(
//           "Feedback deleted successfully.",
//           success: true,
//         );

//         await getFeedback();
//       } else {
//         showMessage("Unable to delete feedback.");
//       }
//     } catch (e) {
//       showMessage("Error deleting feedback.");
//     }
//   }

//   // =====================================================
//   // DELETE CONFIRMATION
//   // =====================================================

//   void showDeleteConfirmation(
//     int id,
//     String studentName,
//   ) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text(
//             "Delete Feedback",
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           content: Text(
//             "Are you sure you want to delete feedback from \"$studentName\"?",
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: const Text("Cancel"),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//                 foregroundColor: Colors.white,
//               ),
//               onPressed: () {
//                 Navigator.pop(context);
//                 deleteFeedback(id);
//               },
//               child: const Text("Delete"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // =====================================================
//   // SEARCH + RATING FILTER
//   // =====================================================

//   void applyFilters() {
//     final search = searchText.trim().toLowerCase();

//     final result = feedbackList.where((feedback) {
//       final studentName =
//           (feedback["studentName"] ?? "")
//               .toString()
//               .toLowerCase();

//       final tutorName =
//           (feedback["tutorName"] ?? "")
//               .toString()
//               .toLowerCase();

//       final courseName =
//           (feedback["courseName"] ?? "")
//               .toString()
//               .toLowerCase();

//       final feedbackText =
//           (feedback["feedbackText"] ?? "")
//               .toString()
//               .toLowerCase();

//       final rating =
//           double.tryParse(
//                 (feedback["rating"] ?? 0).toString(),
//               ) ??
//               0;

//       final matchesSearch =
//           search.isEmpty ||
//           studentName.contains(search) ||
//           tutorName.contains(search) ||
//           courseName.contains(search) ||
//           feedbackText.contains(search);

//       bool matchesRating = true;

//       if (selectedRating != "All") {
//         final selected =
//             double.tryParse(selectedRating) ?? 0;

//         matchesRating = rating == selected;
//       }

//       return matchesSearch && matchesRating;
//     }).toList();

//     if (mounted) {
//       setState(() {
//         filteredFeedbackList = result;
//       });
//     }
//   }

//   // =====================================================
//   // AVERAGE RATING
//   // =====================================================

//   double getAverageRating() {
//     if (feedbackList.isEmpty) {
//       return 0;
//     }

//     double total = 0;

//     for (final feedback in feedbackList) {
//       total +=
//           double.tryParse(
//             (feedback["rating"] ?? 0).toString(),
//           ) ??
//           0;
//     }

//     return total / feedbackList.length;
//   }

//   // =====================================================
//   // POSITIVE FEEDBACK
//   // 4 OR 5 STAR
//   // =====================================================

//   int getPositivePercentage() {
//     if (feedbackList.isEmpty) {
//       return 0;
//     }

//     int positive = 0;

//     for (final feedback in feedbackList) {
//       final rating =
//           double.tryParse(
//             (feedback["rating"] ?? 0).toString(),
//           ) ??
//           0;

//       if (rating >= 4) {
//         positive++;
//       }
//     }

//     return ((positive / feedbackList.length) * 100)
//         .round();
//   }

//   // =====================================================
//   // MESSAGE
//   // =====================================================

//   void showMessage(
//     String message, {
//     bool success = false,
//   }) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor:
//             success ? Colors.green : Colors.red,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   // =====================================================
//   // GET RATING
//   // =====================================================

//   double getRating(
//     Map<String, dynamic> feedback,
//   ) {
//     return double.tryParse(
//           (feedback["rating"] ?? 0).toString(),
//         ) ??
//         0;
//   }

//   // =====================================================
//   // BUILD
//   // =====================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F8FA),

//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,

//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back_ios_new,
//             size: 19,
//             color: Color(0xFF172033),
//           ),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),

//         title: const Column(
//           crossAxisAlignment:
//               CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Feedback Management",
//               style: TextStyle(
//                 fontSize: 17,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF121B2E),
//               ),
//             ),
//             Text(
//               "Student reviews and ratings",
//               style: TextStyle(
//                 fontSize: 11,
//                 color: Color(0xFF69778A),
//               ),
//             ),
//           ],
//         ),

//         actions: [
//           IconButton(
//             onPressed: getFeedback,
//             icon: const Icon(
//               Icons.refresh,
//               size: 22,
//               color: Color(0xFF617184),
//             ),
//           ),
//           const SizedBox(width: 5),
//         ],
//       ),

//       body: SafeArea(
//         child: RefreshIndicator(
//           onRefresh: getFeedback,

//           child: SingleChildScrollView(
//             physics:
//                 const AlwaysScrollableScrollPhysics(),

//             padding: const EdgeInsets.fromLTRB(
//               16,
//               18,
//               16,
//               25,
//             ),

//             child: Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment.start,

//               children: [
//                 // =================================================
//                 // PAGE TITLE
//                 // =================================================

//                 const Text(
//                   "Feedback Management",
//                   style: TextStyle(
//                     fontSize: 25,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF121B2E),
//                   ),
//                 ),

//                 const SizedBox(height: 4),

//                 const Text(
//                   "Review student ratings and feedback",
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: Color(0xFF657386),
//                   ),
//                 ),

//                 const SizedBox(height: 20),

//                 // =================================================
//                 // STAT CARDS
//                 // =================================================

//                 Row(
//                   children: [
//                     Expanded(
//                       child: buildStatCard(
//                         icon: Icons.rate_review,
//                         iconColor:
//                             const Color(0xFF249987),
//                         iconBackground:
//                             const Color(0xFFEAF0FF),
//                         value:
//                             feedbackList.length.toString(),
//                         title: "Reviews",
//                       ),
//                     ),

//                     const SizedBox(width: 10),

//                     Expanded(
//                       child: buildStatCard(
//                         icon: Icons.star,
//                         iconColor:
//                             const Color(0xFFEBA900),
//                         iconBackground:
//                             const Color(0xFFFFF5C9),
//                         value:
//                             getAverageRating()
//                                 .toStringAsFixed(1),
//                         title: "Avg Rating",
//                       ),
//                     ),

//                     const SizedBox(width: 10),

//                     Expanded(
//                       child: buildStatCard(
//                         icon: Icons.thumb_up,
//                         iconColor:
//                             const Color(0xFF1EAA58),
//                         iconBackground:
//                             const Color(0xFFDDF8E8),
//                         value:
//                             "${getPositivePercentage()}%",
//                         title: "Positive",
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 18),

//                 // =================================================
//                 // SEARCH
//                 // =================================================

//                 Container(
//                   height: 50,

//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius:
//                         BorderRadius.circular(12),

//                     border: Border.all(
//                       color: const Color(0xFFDDE2E7),
//                     ),
//                   ),

//                   child: TextField(
//                     controller: searchController,

//                     onChanged: (value) {
//                       searchText = value;
//                       applyFilters();
//                     },

//                     style: const TextStyle(
//                       fontSize: 14,
//                     ),

//                     decoration:
//                         const InputDecoration(
//                       border: InputBorder.none,

//                       prefixIcon: Icon(
//                         Icons.search,
//                         size: 22,
//                         color: Color(0xFF66798D),
//                       ),

//                       hintText:
//                           "Search student, tutor or course",

//                       hintStyle: TextStyle(
//                         fontSize: 13,
//                         color: Color(0xFF9AA8B8),
//                       ),

//                       contentPadding:
//                           EdgeInsets.symmetric(
//                         vertical: 14,
//                       ),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 14),

//                 // =================================================
//                 // RATING FILTERS
//                 // =================================================

//                 SingleChildScrollView(
//                   scrollDirection:
//                       Axis.horizontal,

//                   child: Row(
//                     children: [
//                       buildRatingFilter("All"),
//                       buildRatingFilter("5"),
//                       buildRatingFilter("4"),
//                       buildRatingFilter("3"),
//                       buildRatingFilter("2"),
//                       buildRatingFilter("1"),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 18),

//                 // =================================================
//                 // FEEDBACK
//                 // =================================================

//                 if (isLoading)
//                   const Padding(
//                     padding:
//                         EdgeInsets.only(top: 60),
//                     child: Center(
//                       child:
//                           CircularProgressIndicator(
//                         color:
//                             Color(0xFF159B86),
//                       ),
//                     ),
//                   )

//                 else if (filteredFeedbackList.isEmpty)
//                   buildEmptyState()

//                 else
//                   Column(
//                     children:
//                         filteredFeedbackList.map(
//                       (feedback) {
//                         return buildFeedbackCard(
//                           feedback,
//                         );
//                       },
//                     ).toList(),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // =====================================================
//   // STAT CARD
//   // =====================================================

//   Widget buildStatCard({
//     required IconData icon,
//     required Color iconColor,
//     required Color iconBackground,
//     required String value,
//     required String title,
//   }) {
//     return Container(
//       height: 125,

//       decoration: BoxDecoration(
//         color: Colors.white,

//         borderRadius:
//             BorderRadius.circular(14),

//         border: Border.all(
//           color: const Color(0xFFE0E4E8),
//         ),
//       ),

//       padding: const EdgeInsets.all(10),

//       child: Column(
//         mainAxisAlignment:
//             MainAxisAlignment.center,

//         children: [
//           Container(
//             width: 38,
//             height: 38,

//             decoration: BoxDecoration(
//               color: iconBackground,
//               borderRadius:
//                   BorderRadius.circular(10),
//             ),

//             child: Icon(
//               icon,
//               size: 20,
//               color: iconColor,
//             ),
//           ),

//           const SizedBox(height: 7),

//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF121B2E),
//             ),
//           ),

//           const SizedBox(height: 2),

//           Text(
//             title,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: const TextStyle(
//               fontSize: 11,
//               color: Color(0xFF69778A),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // =====================================================
//   // RATING FILTER
//   // =====================================================

//   Widget buildRatingFilter(
//     String rating,
//   ) {
//     final isSelected =
//         selectedRating == rating;

//     final text =
//         rating == "All"
//             ? "All"
//             : "$rating ★";

//     return Padding(
//       padding:
//           const EdgeInsets.only(right: 8),

//       child: GestureDetector(
//         onTap: () {
//           setState(() {
//             selectedRating = rating;
//           });

//           applyFilters();
//         },

//         child: Container(
//           padding:
//               const EdgeInsets.symmetric(
//             horizontal: 15,
//             vertical: 8,
//           ),

//           decoration: BoxDecoration(
//             color: isSelected
//                 ? const Color(0xFF159B86)
//                 : Colors.white,

//             borderRadius:
//                 BorderRadius.circular(20),

//             border: Border.all(
//               color: isSelected
//                   ? const Color(0xFF159B86)
//                   : const Color(0xFFDCE2E7),
//             ),
//           ),

//           child: Text(
//             text,

//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,

//               color: isSelected
//                   ? Colors.white
//                   : const Color(0xFF667487),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // =====================================================
//   // FEEDBACK CARD
//   // =====================================================

//   Widget buildFeedbackCard(
//     Map<String, dynamic> feedback,
//   ) {
//     final id =
//         int.tryParse(
//               (feedback["id"] ?? 0).toString(),
//             ) ??
//             0;

//     final studentName =
//         (feedback["studentName"] ?? "")
//             .toString();

//     final tutorName =
//         (feedback["tutorName"] ?? "")
//             .toString();

//     final courseName =
//         (feedback["courseName"] ?? "")
//             .toString();

//     final feedbackText =
//         (feedback["feedbackText"] ?? "")
//             .toString();

//     final date =
//         (feedback["date"] ?? "")
//             .toString();

//     final time =
//         (feedback["time"] ?? "")
//             .toString();

//     final feedbackBy =
//         (feedback["feedbackBy"] ?? "")
//             .toString();

//     final rating =
//         getRating(feedback);

//     final initials =
//         getInitials(studentName);

//     return Container(
//       width: double.infinity,

//       margin:
//           const EdgeInsets.only(bottom: 12),

//       padding: const EdgeInsets.all(16),

//       decoration: BoxDecoration(
//         color: Colors.white,

//         borderRadius:
//             BorderRadius.circular(16),

//         border: Border.all(
//           color: const Color(0xFFE0E4E8),
//         ),

//         boxShadow: [
//           BoxShadow(
//             color:
//                 Colors.black.withOpacity(0.03),
//             blurRadius: 5,
//             offset:
//                 const Offset(0, 2),
//           ),
//         ],
//       ),

//       child: Column(
//         crossAxisAlignment:
//             CrossAxisAlignment.start,

//         children: [
//           // =================================================
//           // STUDENT HEADER
//           // =================================================

//           Row(
//             crossAxisAlignment:
//                 CrossAxisAlignment.start,

//             children: [
//               // PROFILE
//               Container(
//                 width: 46,
//                 height: 46,

//                 decoration:
//                     const BoxDecoration(
//                   color: Color(0xFFEFF2FF),
//                   shape: BoxShape.circle,
//                 ),

//                 child: Center(
//                   child: Text(
//                     initials,

//                     style:
//                         const TextStyle(
//                       fontSize: 14,
//                       fontWeight:
//                           FontWeight.bold,
//                       color:
//                           Color(0xFF239986),
//                     ),
//                   ),
//                 ),
//               ),

//               const SizedBox(width: 10),

//               // STUDENT + TUTOR
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment.start,

//                   children: [
//                     Text(
//                       studentName.isEmpty
//                           ? "Unknown Student"
//                           : studentName,

//                       maxLines: 1,
//                       overflow:
//                           TextOverflow.ellipsis,

//                       style:
//                           const TextStyle(
//                         fontSize: 15,
//                         fontWeight:
//                             FontWeight.bold,
//                         color:
//                             Color(0xFF121B2E),
//                       ),
//                     ),

//                     const SizedBox(height: 3),

//                     Text(
//                       tutorName.isEmpty
//                           ? "Tutor: Unknown"
//                           : "Tutor: $tutorName",

//                       maxLines: 1,
//                       overflow:
//                           TextOverflow.ellipsis,

//                       style:
//                           const TextStyle(
//                         fontSize: 12,
//                         color:
//                             Color(0xFF69778A),
//                       ),
//                     ),

//                     if (courseName.isNotEmpty)
//                       Padding(
//                         padding:
//                             const EdgeInsets.only(
//                           top: 2,
//                         ),

//                         child: Text(
//                           "Course: $courseName",

//                           maxLines: 1,
//                           overflow:
//                               TextOverflow.ellipsis,

//                           style:
//                               const TextStyle(
//                             fontSize: 11,
//                             color:
//                                 Color(0xFF8996A5),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),

//               const SizedBox(width: 6),

//               // DELETE
//               InkWell(
//                 borderRadius:
//                     BorderRadius.circular(9),

//                 onTap: () {
//                   showDeleteConfirmation(
//                     id,
//                     studentName,
//                   );
//                 },

//                 child: Container(
//                   width: 36,
//                   height: 36,

//                   decoration:
//                       BoxDecoration(
//                     color:
//                         const Color(0xFFFFF1F1),
//                     borderRadius:
//                         BorderRadius.circular(9),
//                   ),

//                   child: const Icon(
//                     Icons.delete_outline,
//                     size: 19,
//                     color:
//                         Color(0xFFE5484D),
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 12),

//           // =================================================
//           // FEEDBACK BY
//           // =================================================

//           Row(
//             children: [
//               Container(
//                 padding:
//                     const EdgeInsets.symmetric(
//                   horizontal: 8,
//                   vertical: 5,
//                 ),

//                 decoration:
//                     BoxDecoration(
//                   color:
//                       const Color(0xFFEFF8F6),
//                   borderRadius:
//                       BorderRadius.circular(7),
//                 ),

//                 child: Text(
//                   feedbackBy.isEmpty
//                       ? "By: Student"
//                       : "By: $feedbackBy",

//                   style:
//                       const TextStyle(
//                     fontSize: 10,
//                     fontWeight:
//                         FontWeight.w600,
//                     color:
//                         Color(0xFF258F80),
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 10),

//           // =================================================
//           // FEEDBACK TEXT
//           // =================================================

//           Text(
//             feedbackText.isEmpty
//                 ? "No feedback comment"
//                 : feedbackText,

//             style: const TextStyle(
//               fontSize: 13,
//               height: 1.45,
//               color: Color(0xFF273447),
//             ),
//           ),

//           const SizedBox(height: 12),

//           const Divider(
//             height: 1,
//             color: Color(0xFFE8EBEE),
//           ),

//           const SizedBox(height: 10),

//           // =================================================
//           // RATING + DATE
//           // =================================================

//           Row(
//             children: [
//               // STARS
//               Row(
//                 children: List.generate(
//                   5,
//                   (index) {
//                     return Icon(
//                       index < rating.round()
//                           ? Icons.star
//                           : Icons.star_border,

//                       color:
//                           const Color(0xFFEBA900),

//                       size: 19,
//                     );
//                   },
//                 ),
//               ),

//               const SizedBox(width: 7),

//               Text(
//                 rating.toStringAsFixed(1),

//                 style:
//                     const TextStyle(
//                   fontSize: 12,
//                   fontWeight:
//                       FontWeight.bold,
//                   color:
//                       Color(0xFFC67800),
//                 ),
//               ),

//               const Spacer(),

//               if (date.isNotEmpty ||
//                   time.isNotEmpty)
//                 Flexible(
//                   child: Text(
//                     "$date ${time.isNotEmpty ? "• $time" : ""}",

//                     maxLines: 1,
//                     overflow:
//                         TextOverflow.ellipsis,

//                     style:
//                         const TextStyle(
//                       fontSize: 10,
//                       color:
//                           Color(0xFF8290A0),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // =====================================================
//   // EMPTY STATE
//   // =====================================================

//   Widget buildEmptyState() {
//     return Container(
//       width: double.infinity,

//       padding:
//           const EdgeInsets.symmetric(
//         vertical: 45,
//         horizontal: 20,
//       ),

//       decoration: BoxDecoration(
//         color: Colors.white,

//         borderRadius:
//             BorderRadius.circular(16),

//         border: Border.all(
//           color: const Color(0xFFE0E4E8),
//         ),
//       ),

//       child: const Column(
//         children: [
//           Icon(
//             Icons.rate_review_outlined,
//             size: 42,
//             color: Color(0xFF9AA8B8),
//           ),

//           SizedBox(height: 10),

//           Text(
//             "No Feedback Found",
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF273447),
//             ),
//           ),

//           SizedBox(height: 4),

//           Text(
//             "There are no feedback records to display.",
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 12,
//               color: Color(0xFF8996A5),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // =====================================================
//   // GET INITIALS
//   // =====================================================

//   String getInitials(String name) {
//     if (name.trim().isEmpty) {
//       return "ST";
//     }

//     final parts =
//         name.trim().split(" ");

//     if (parts.length == 1) {
//       return parts[0][0].toUpperCase();
//     }

//     return "${parts[0][0]}${parts[1][0]}"
//         .toUpperCase();
//   }
// }
