import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:house_of_tutor/TutorAddSubject.dart';
import 'package:house_of_tutor/TutorDrawer.dart';
import 'package:house_of_tutor/TutorHome.dart';
import 'package:house_of_tutor/TutorNotification.dart';
import 'package:house_of_tutor/TutorStudentProfile.dart';
import 'package:house_of_tutor/TutorTodayClasses.dart';
import 'package:house_of_tutor/services/api_client.dart';

class TutorStudentRequest extends StatefulWidget {
  const TutorStudentRequest({super.key});

  @override
  State<TutorStudentRequest> createState() => _TutorStudentRequestState();
}

class _TutorStudentRequestState extends State<TutorStudentRequest> {
  // =========================================================
  // STATE VARIABLES
  // =========================================================

  bool isLoading = false;

  // Used when Accept/Reject button is pressed
  int? processingRequestId;

  List<dynamic> requestsList = [];

  // Request tab is selected
  int selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  // =========================================================
  // SAFE INT CONVERSION
  // =========================================================

  int getInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  // =========================================================
  // SAFE STRING CONVERSION
  // =========================================================

  String getString(dynamic value, [String defaultValue = ""]) {
    if (value == null) {
      return defaultValue;
    }

    return value.toString();
  }

  // =========================================================
  // DATE FORMAT
  // =========================================================

  String formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return "N/A";
    }

    final String date = value.toString();

    if (date.contains("T")) {
      return date.split("T")[0];
    }

    return date;
  }

  // =========================================================
  // FETCH REQUESTS
  // =========================================================

  Future<void> fetchRequests() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiClient.get(
        "/api/Tutor/my-requests",
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        List<dynamic> loadedRequests = [];

        // -----------------------------------------------------
        // CASE 1:
        // {
        //   "data": [...]
        // }
        // -----------------------------------------------------

        if (decoded is Map && decoded["data"] is List) {
          loadedRequests = decoded["data"];
        }

        // -----------------------------------------------------
        // CASE 2:
        // {
        //   "requests": [...]
        // }
        // -----------------------------------------------------

        else if (decoded is Map && decoded["requests"] is List) {
          loadedRequests = decoded["requests"];
        }

        // -----------------------------------------------------
        // CASE 3:
        // Direct list
        // [...]
        // -----------------------------------------------------

        else if (decoded is List) {
          loadedRequests = decoded;
        }

        if (!mounted) return;

        setState(() {
          requestsList = loadedRequests;
        });
      } else {
        if (!mounted) return;

        showMessage(
          "Failed to load requests (${response.statusCode})",
          Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return;

      showMessage(
        "Error loading requests: $e",
        Colors.red,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // =========================================================
  // ACCEPT REQUEST
  // =========================================================

  Future<void> acceptRequest(int requestId) async {
    if (requestId <= 0) {
      showMessage(
        "Invalid request ID",
        Colors.red,
      );
      return;
    }

    // Prevent double click
    if (processingRequestId != null) {
      return;
    }

    setState(() {
      processingRequestId = requestId;
    });

    try {
      final response = await ApiClient.put(
        "/api/Tutor/accept-request/$requestId",
        {},
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        showMessage(
          "Request accepted successfully",
          Colors.green,
        );

        // Remove accepted request immediately
        setState(() {
          requestsList.removeWhere(
            (item) => getInt(item["request_id"]) == requestId,
          );
        });

        // Also refresh from backend
        await fetchRequests();
      } else {
        String message = "Failed to accept request";

        try {
          final decoded = jsonDecode(response.body);

          if (decoded is Map && decoded["message"] != null) {
            message = decoded["message"].toString();
          }
        } catch (_) {}

        if (!mounted) return;

        showMessage(
          message,
          Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return;

      showMessage(
        "Error accepting request: $e",
        Colors.red,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        processingRequestId = null;
      });
    }
  }

  // =========================================================
  // REJECT REQUEST
  // =========================================================

  Future<void> rejectRequest(int requestId) async {
    if (requestId <= 0) {
      showMessage(
        "Invalid request ID",
        Colors.red,
      );
      return;
    }

    // Prevent double click
    if (processingRequestId != null) {
      return;
    }

    setState(() {
      processingRequestId = requestId;
    });

    try {
      final response = await ApiClient.put(
        "/api/Tutor/reject-request/$requestId",
        {},
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        showMessage(
          "Request rejected successfully",
          Colors.orange,
        );

        // -----------------------------------------------------
        // IMPORTANT:
        // Remove rejected request immediately.
        // If backend moved next queued tutor to Pending,
        // fetchRequests() will show the next request.
        // -----------------------------------------------------

        setState(() {
          requestsList.removeWhere(
            (item) => getInt(item["request_id"]) == requestId,
          );
        });

        // Refresh list
        await fetchRequests();
      } else {
        String message = "Failed to reject request";

        try {
          final decoded = jsonDecode(response.body);

          if (decoded is Map && decoded["message"] != null) {
            message = decoded["message"].toString();
          }
        } catch (_) {}

        if (!mounted) return;

        showMessage(
          message,
          Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return;

      showMessage(
        "Error rejecting request: $e",
        Colors.red,
      );
    } finally {
      if (!mounted) return;

      setState(() {
        processingRequestId = null;
      });
    }
  }

  // =========================================================
  // SNACKBAR
  // =========================================================

  void showMessage(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // =========================================================
  // BOTTOM NAVIGATION
  // =========================================================

  void onItemTapped(int index) {
    if (selectedIndex == index) {
      return;
    }

    setState(() {
      selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TutorHome(),
          ),
        );
        break;

      case 1:
        // Already on request screen
        break;

      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TutorTodayClasses(),
          ),
        );
        break;

      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TutorAddSubject(),
          ),
        );
        break;
    }
  }

  // =========================================================
  // LOGO
  // =========================================================

  Widget buildLogo() {
    return Image.asset(
      "assets/images/logo.png",
      height: 34,
      width: 34,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.school,
            color: Color(0xFF00695C),
            size: 23,
          ),
        );
      },
    );
  }

  // =========================================================
  // REQUEST CARD
  // =========================================================

  Widget buildRequestCard(dynamic req) {
    // -------------------------------------------------------
    // SAFELY GET DATA FROM API
    // -------------------------------------------------------

    final int requestId = getInt(req["request_id"]);

    final int studentId = getInt(req["student_id"]);

    final String studentName = getString(
      req["student_name"],
      "Student Name",
    );

    final String courseName = getString(
      req["course_name"],
      "Subject",
    );

    final String requestDate = formatDate(
      req["request_date"],
    );

    final String classDate = formatDate(
      req["class_date"],
    );

    final String day = getString(
      req["day"],
      "N/A",
    );

    final String time = getString(
      req["time"],
      "N/A",
    );

    final String requestType = getString(
      req["request_type"],
      "Normal",
    );

    // Is this request currently processing?
    final bool isProcessing =
        processingRequestId == requestId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
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
          // =================================================
          // STUDENT HEADER
          // =================================================

          Row(
            children: [
              Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFF009688),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      "Teaching Request",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    courseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF00695C),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),

          // =================================================
          // REQUEST DETAILS
          // =================================================

          _detailRow(
            icon: Icons.mail_outline,
            label: "Requested On",
            value: requestDate,
          ),

          const SizedBox(height: 9),

          _detailRow(
            icon: Icons.calendar_today_outlined,
            label: "Class Start Date",
            value: classDate,
          ),

          const SizedBox(height: 9),

          _detailRow(
            icon: Icons.access_time_outlined,
            label: "Schedule & Time",
            value: "$day, $time",
          ),

          const SizedBox(height: 9),

          _detailRow(
            icon: Icons.category_outlined,
            label: "Request Category",
            value: requestType,
          ),

          const SizedBox(height: 16),

          // =================================================
          // VIEW STUDENT PROFILE
          // =================================================

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Colors.grey.shade300,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
              onPressed: isProcessing
                  ? null
                  : () {
                      if (studentId <= 0) {
                        showMessage(
                          "Student information not found",
                          Colors.red,
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TutorStudentProfile(
                            studentId: studentId,
                          ),
                        ),
                      );
                    },
              child: const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    color: Color(0xFF009688),
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    "View Student Profile",
                    style: TextStyle(
                      color: Color(0xFF009688),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // =================================================
          // ACCEPT + DECLINE
          // =================================================

          Row(
            children: [
              // ------------------------------------------------
              // ACCEPT
              // ------------------------------------------------

              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF009688),
                    disabledBackgroundColor:
                        Colors.grey.shade300,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isProcessing
                      ? null
                      : () => acceptRequest(requestId),
                  child: isProcessing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Accept Request",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(width: 10),

              // ------------------------------------------------
              // DECLINE
              // ------------------------------------------------

              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Colors.redAccent,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isProcessing
                      ? null
                      : () => rejectRequest(requestId),
                  child: const Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.close,
                        color: Colors.redAccent,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Decline",
                        style: TextStyle(
                          color: Colors.redAccent,
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
        ],
      ),
    );
  }

  // =========================================================
  // DETAIL ROW
  // =========================================================

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade600,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(
                Icons.menu,
                color: Colors.black87,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),

        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildLogo(),

            const SizedBox(width: 8),

            const Text(
              "House of Tutor",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: "Notifications",
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.black87,
              size: 27,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const TutorNotification(),
                ),
              );
            },
          ),
        ],
      ),

      drawer: const TutorDrawer(),

      // =====================================================
      // BODY
      // =====================================================

      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF009688),
          onRefresh: fetchRequests,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF009688),
                  ),
                )
              : requestsList.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height:
                              MediaQuery.of(context)
                                      .size
                                      .height *
                                  0.35,
                        ),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 55,
                                color:
                                    Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "No pending requests found",
                                style: TextStyle(
                                  fontSize: 15,
                                  color:
                                      Colors.grey.shade600,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "New student requests will appear here.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: requestsList.length,
                      itemBuilder: (context, index) {
                        return buildRequestCard(
                          requestsList[index],
                        );
                      },
                    ),
        ),
      ),

      // =====================================================
      // BOTTOM NAVIGATION
      // =====================================================

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor:
            const Color(0xFF009688),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.calendar_today,
            ),
            label: "Schedule",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.people_outline,
            ),
            label: "Request",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.school_outlined,
            ),
            label: "Today",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_circle_outline,
            ),
            label: "Subject",
          ),
        ],
      ),
    );
  }
}
















// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:house_of_tutor/TutorAddSubject.dart';
// import 'package:house_of_tutor/TutorDrawer.dart';
// import 'package:house_of_tutor/TutorHome.dart';
// import 'package:house_of_tutor/TutorNotification.dart';
// import 'package:house_of_tutor/TutorStudentProfile.dart';
// import 'package:house_of_tutor/TutorTodayClasses.dart';
// import 'package:house_of_tutor/services/api_client.dart';

// class TutorStudentRequest extends StatefulWidget {
//   const TutorStudentRequest({super.key});

//   @override
//   State<TutorStudentRequest> createState() => _TutorStudentRequestState();
// }

// class _TutorStudentRequestState extends State<TutorStudentRequest> {
//   // =========================================================
//   // STATE VARIABLES
//   // =========================================================

//   bool isLoading = false;
//   List<dynamic> requestsList = [];
//   int selectedIndex = 1; // Request tab is selected in bottom nav

//   @override
//   void initState() {
//     super.initState();
//     fetchRequests();
//   }

//   // =========================================================
//   // FETCH PENDING REQUESTS API
//   // =========================================================

//   Future<void> fetchRequests() async {
//     if (!mounted) return;

//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final response = await ApiClient.get("/api/Tutor/my-requests");

//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(response.body);

//         if (decoded is Map && decoded["data"] != null) {
//           setState(() {
//             requestsList = decoded["data"];
//           });
//         } else if (decoded is List) {
//           setState(() {
//             requestsList = decoded;
//           });
//         }
//       } else {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Failed to load requests (${response.statusCode})"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }

//   // =========================================================
//   // ACCEPT REQUEST API
//   // =========================================================

//   Future<void> acceptRequest(int requestId) async {
//     try {
//       final response = await ApiClient.put(
//         "/api/Tutor/accept-request/$requestId",
//         {},
//       );

//       if (response.statusCode == 200) {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Request accepted successfully"),
//             backgroundColor: Colors.green,
//           ),
//         );
//         fetchRequests(); // Refresh list
//       } else {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Failed to accept request"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // =========================================================
//   // REJECT REQUEST API
//   // =========================================================

//   Future<void> rejectRequest(int requestId) async {
//     try {
//       final response = await ApiClient.put(
//         "/api/Tutor/reject-request/$requestId",
//         {},
//       );

//       if (response.statusCode == 200) {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Request rejected"),
//             backgroundColor: Colors.orange,
//           ),
//         );
//         fetchRequests(); // Refresh list
//       } else {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Failed to reject request"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // =========================================================
//   // BOTTOM NAVIGATION
//   // =========================================================

//   void onItemTapped(int index) {
//     if (selectedIndex == index) return;

//     setState(() {
//       selectedIndex = index;
//     });

//     switch (index) {
//       case 0:
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const TutorHome()),
//         );
//         break;
//       case 1:
//         // Already here
//         break;
//       case 2:
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const TutorTodayClasses()),
//         );
//         break;
//       case 3:
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const TutorAddSubject()),
//         );
//         break;
//     }
//   }

//   // =========================================================
//   // LOGO WIDGET
//   // =========================================================

//   Widget buildLogo() {
//     return Image.asset(
//       "assets/images/logo.png",
//       height: 34,
//       width: 34,
//       fit: BoxFit.contain,
//       errorBuilder: (context, error, stackTrace) {
//         return Container(
//           height: 34,
//           width: 34,
//           decoration: BoxDecoration(
//             color: Colors.teal.shade50,
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: const Icon(
//             Icons.school,
//             color: Color(0xFF00695C),
//             size: 23,
//           ),
//         );
//       },
//     );
//   }

//   // =========================================================
//   // BUILD
//   // =========================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//         leading: Builder(
//           builder: (context) {
//             return IconButton(
//               icon: const Icon(Icons.menu, color: Colors.black87),
//               onPressed: () {
//                 Scaffold.of(context).openDrawer();
//               },
//             );
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
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             tooltip: "Notifications",
//             icon: const Icon(
//               Icons.notifications_none,
//               color: Colors.black87,
//               size: 27,
//             ),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => TutorNotification()),
//               );
//             },
//           ),
//         ],
//       ),
//       drawer: const TutorDrawer(),
//       body: SafeArea(
//         child: isLoading
//             ? const Center(
//                 child: CircularProgressIndicator(
//                   color: Color(0xFF009688),
//                 ),
//               )
//             : requestsList.isEmpty
//                 ? Center(
//                     child: Text(
//                       "No pending requests found",
//                       style: TextStyle(
//                         fontSize: 15,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                   )
//                 : ListView.builder(
//                     padding: const EdgeInsets.all(12),
//                     itemCount: requestsList.length,
//                     itemBuilder: (context, index) {
//                       final req = requestsList[index];

//                       final int requestId = req["request_id"] ?? 0;
//                       final int studentId = req["student_id"] ?? 0;
//                       final String studentName =
//                           req["student_name"] ?? "Student Name";
//                       final String courseName =
//                           req["course_name"] ?? "Subject";
//                       final String requestDate =
//                           req["request_date"]?.toString().split("T")[0] ?? "";
//                       final String classDate =
//                           req["class_date"]?.toString().split("T")[0] ?? "";
//                       final String day = req["day"] ?? "";
//                       final String time = req["time"] ?? "";
//                       final String requestType =
//                           req["request_type"] ?? "Normal";

//                       return Container(
//                         margin: const EdgeInsets.only(bottom: 16),
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(16),
//                           border: Border.all(color: Colors.grey.shade200),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.03),
//                               blurRadius: 8,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // TOP HEADER: Student info + Course pill
//                             Row(
//                               children: [
//                                 Container(
//                                   height: 45,
//                                   width: 45,
//                                   decoration: BoxDecoration(
//                                     color: const Color(0xFF009688),
//                                     borderRadius: BorderRadius.circular(25),
//                                   ),
//                                   child: const Icon(
//                                     Icons.person,
//                                     color: Colors.white,
//                                     size: 24,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 12),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         studentName,
//                                         style: const TextStyle(
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.black87,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 2),
//                                       const Text(
//                                         "Teaching Request",
//                                         style: TextStyle(
//                                           fontSize: 12,
//                                           color: Colors.grey,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 10,
//                                     vertical: 6,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: Colors.teal.shade50,
//                                     borderRadius: BorderRadius.circular(20),
//                                   ),
//                                   child: Text(
//                                     courseName,
//                                     style: const TextStyle(
//                                       color: Color(0xFF00695C),
//                                       fontSize: 11,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),

//                             const Padding(
//                               padding: EdgeInsets.symmetric(vertical: 12),
//                               child: Divider(height: 1),
//                             ),

//                             // DETAILS LIST
//                             _detailRow(
//                               icon: Icons.mail_outline,
//                               label: "Requested On",
//                               value: requestDate,
//                             ),
//                             const SizedBox(height: 8),
//                             _detailRow(
//                               icon: Icons.calendar_today_outlined,
//                               label: "Class Start Date",
//                               value: classDate,
//                             ),
//                             const SizedBox(height: 8),
//                             _detailRow(
//                               icon: Icons.access_time_outlined,
//                               label: "Schedule & Time",
//                               value: "$day, $time",
//                             ),
//                             const SizedBox(height: 8),
//                             _detailRow(
//                               icon: Icons.category_outlined,
//                               label: "Request Category",
//                               value: requestType,
//                             ),

//                             const SizedBox(height: 16),

//                             // VIEW STUDENT PROFILE BUTTON
//                             SizedBox(
//                               width: double.infinity,
//                               child: OutlinedButton(
//                                 style: OutlinedButton.styleFrom(
//                                   side: BorderSide(
//                                     color: Colors.grey.shade300,
//                                   ),
//                                   padding: const EdgeInsets.symmetric(
//                                     vertical: 12,
//                                   ),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                 ),
//                                 onPressed: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (_) => TutorStudentProfile(
//                                         studentId:studentId,
//                                       ),
//                                     ),
//                                   );
//                                 },
//                                 child: const Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       Icons.person_outline,
//                                       color: Color(0xFF009688),
//                                       size: 18,
//                                     ),
//                                     SizedBox(width: 6),
//                                     Text(
//                                       "View Student Profile",
//                                       style: TextStyle(
//                                         color: Color(0xFF009688),
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 14,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),

//                             const SizedBox(height: 12),

//                             // ACCEPT & DECLINE BUTTONS
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: ElevatedButton(
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: const Color(0xFF009688),
//                                       elevation: 0,
//                                       padding: const EdgeInsets.symmetric(
//                                         vertical: 12,
//                                       ),
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(10),
//                                       ),
//                                     ),
//                                     onPressed: () => acceptRequest(requestId),
//                                     child: const Row(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.center,
//                                       children: [
//                                         Icon(
//                                           Icons.check,
//                                           color: Colors.white,
//                                           size: 16,
//                                         ),
//                                         SizedBox(width: 4),
//                                         Text(
//                                           "Accept Request",
//                                           style: TextStyle(
//                                             color: Colors.white,
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 13,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 Expanded(
//                                   child: OutlinedButton(
//                                     style: OutlinedButton.styleFrom(
//                                       side: const BorderSide(
//                                         color: Colors.redAccent,
//                                       ),
//                                       padding: const EdgeInsets.symmetric(
//                                         vertical: 12,
//                                       ),
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(10),
//                                       ),
//                                     ),
//                                     onPressed: () => rejectRequest(requestId),
//                                     child: const Row(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.center,
//                                       children: [
//                                         Icon(
//                                           Icons.close,
//                                           color: Colors.redAccent,
//                                           size: 16,
//                                         ),
//                                         SizedBox(width: 4),
//                                         Text(
//                                           "Decline",
//                                           style: TextStyle(
//                                             color: Colors.redAccent,
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 13,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: selectedIndex,
//         onTap: onItemTapped,
//         type: BottomNavigationBarType.fixed,
//         selectedItemColor: const Color(0xFF009688),
//         unselectedItemColor: Colors.grey,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.calendar_today),
//             label: "Schedule",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.people_outline),
//             label: "Request",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.school_outlined),
//             label: "Today",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.add_circle_outline),
//             label: "Subject",
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _detailRow({
//     required IconData icon,
//     required String label,
//     required String value,
//   }) {
//     return Row(
//       children: [
//         Icon(icon, size: 18, color: Colors.grey.shade600),
//         const SizedBox(width: 8),
//         Text(
//           label,
//           style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
//         ),
//         const Spacer(),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 13,
//             fontWeight: FontWeight.w500,
//             color: Colors.black87,
//           ),
//         ),
//       ],
//     );
//   }
// }