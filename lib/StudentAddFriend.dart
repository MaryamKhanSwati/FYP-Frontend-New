import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:house_of_tutor/services/api_config.dart';
import 'package:house_of_tutor/services/auth_store.dart';

class StudentAddFriend extends StatefulWidget {
  const StudentAddFriend({super.key});

  @override
  State<StudentAddFriend> createState() => _StudentAddFriendState();
}

class _StudentAddFriendState extends State<StudentAddFriend> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _searchController =
      TextEditingController();

  // ============================================================
  // VARIABLES
  // ============================================================

  List<dynamic> students = [];

  bool isLoading = false;
  bool isSearching = false;

  String errorMessage = "";

  Timer? _searchTimer;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    // Load all students when screen opens
    _loadStudents();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // API URL
  // ============================================================

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final base = apiBaseUrl;

    final cleanBase =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;

    final cleanPath =
        path.startsWith('/') ? path : '/$path';

    return Uri.parse('$cleanBase$cleanPath').replace(
      queryParameters: query,
    );
  }

  // ============================================================
  // GET TOKEN
  // ============================================================

  Future<String?> _getToken() async {
    // Your existing AuthStore
    return AuthStore.instance.token;
  }

  // ============================================================
  // LOAD ALL STUDENTS
  // ============================================================

  Future<void> _loadStudents() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = "";
      });

      final token = await _getToken();

      if (token == null || token.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = "Login token not found.";
        });

        return;
      }

      // ----------------------------------------------------------
      // API:
      // GET /api/Student/search-students
      // ----------------------------------------------------------

      final uri = _buildUri(
        '/api/Student/search-students',
      );

      debugPrint("========================================");
      debugPrint("SEARCH ALL STUDENTS");
      debugPrint("URL: $uri");
      debugPrint("========================================");

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("BODY: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          students = data['students'] ?? [];
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          isLoading = false;
          errorMessage = "Session expired. Please login again.";
        });
      } else {
        String message = "Unable to load students.";

        try {
          final data = jsonDecode(response.body);

          if (data['message'] != null) {
            message = data['message'];
          }
        } catch (_) {}

        setState(() {
          isLoading = false;
          errorMessage = message;
        });
      }
    } catch (e) {
      debugPrint("LOAD STUDENTS ERROR: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = "Unable to connect to server.";
      });
    }
  }

  // ============================================================
  // SEARCH STUDENTS
  // ============================================================

  Future<void> _searchStudents(String name) async {
    try {
      setState(() {
        isSearching = true;
        errorMessage = "";
      });

      final token = await _getToken();

      if (token == null || token.isEmpty) {
        setState(() {
          isSearching = false;
          errorMessage = "Login token not found.";
        });

        return;
      }

      // ----------------------------------------------------------
      // API:
      // GET /api/Student/search-students?name=...
      // ----------------------------------------------------------

      final uri = _buildUri(
        '/api/Student/search-students',
        {
          'name': name,
        },
      );

      debugPrint("========================================");
      debugPrint("SEARCH STUDENT");
      debugPrint("SEARCH NAME: $name");
      debugPrint("URL: $uri");
      debugPrint("========================================");

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("BODY: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          students = data['students'] ?? [];
          isSearching = false;
        });
      } else {
        String message = "Unable to search students.";

        try {
          final data = jsonDecode(response.body);

          if (data['message'] != null) {
            message = data['message'];
          }
        } catch (_) {}

        setState(() {
          isSearching = false;
          errorMessage = message;
        });
      }
    } catch (e) {
      debugPrint("SEARCH ERROR: $e");

      if (!mounted) return;

      setState(() {
        isSearching = false;
        errorMessage = "Unable to connect to server.";
      });
    }
  }

  // ============================================================
  // SEARCH TEXT CHANGED
  // ============================================================

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _searchTimer?.cancel();

    // ----------------------------------------------------------
    // If search box is empty
    // Load all students again
    // ----------------------------------------------------------

    if (value.trim().isEmpty) {
      _loadStudents();
      return;
    }

    // ----------------------------------------------------------
    // Wait 500ms before calling API
    // This prevents API call on every single character
    // ----------------------------------------------------------

    _searchTimer = Timer(
      const Duration(milliseconds: 500),
      () {
        _searchStudents(value.trim());
      },
    );
  }

  // ============================================================
  // ADD FRIEND
  // ============================================================

  Future<void> _addFriend(dynamic student) async {
    try {
      final studentId = student['studentId'];

      if (studentId == null) {
        _showMessage(
          "Student ID not found.",
          isError: true,
        );

        return;
      }

      final token = await _getToken();

      if (token == null || token.isEmpty) {
        _showMessage(
          "Login token not found.",
          isError: true,
        );

        return;
      }

      // Show loading on button
      setState(() {
        student['_addingFriend'] = true;
      });

      // ----------------------------------------------------------
      // API:
      // POST /api/Student/add-friend
      //
      // BODY:
      // {
      //   "friendStudentId": 5
      // }
      // ----------------------------------------------------------

      final uri = _buildUri(
        '/api/Student/add-friend',
      );

      debugPrint("========================================");
      debugPrint("ADD FRIEND");
      debugPrint("FRIEND STUDENT ID: $studentId");
      debugPrint("URL: $uri");
      debugPrint("========================================");

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'friendStudentId': studentId,
        }),
      );

      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("BODY: ${response.body}");

      if (!mounted) return;

      // Remove loading
      setState(() {
        student['_addingFriend'] = false;
      });

      // ==========================================================
      // SUCCESS
      // ==========================================================

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Update current student status
        setState(() {
          student['relationshipStatus'] = 'PendingSent';
          student['friendRequestSent'] = true;
          student['friendRequestReceived'] = false;
        });

        _showMessage(
          data['message'] ?? "Friend request sent successfully.",
        );

        return;
      }

      // ==========================================================
      // BAD REQUEST
      // ==========================================================

      if (response.statusCode == 400) {
        String message = "Unable to add friend.";

        String? status;

        try {
          final data = jsonDecode(response.body);

          message = data['message'] ?? message;
          status = data['status'];
        } catch (_) {}

        // --------------------------------------------------------
        // Update UI according to backend status
        // --------------------------------------------------------

        if (status == 'Accepted') {
          setState(() {
            student['relationshipStatus'] = 'Accepted';
          });
        } else if (status == 'PendingSent') {
          setState(() {
            student['relationshipStatus'] = 'PendingSent';
            student['friendRequestSent'] = true;
          });
        } else if (status == 'PendingReceived') {
          setState(() {
            student['relationshipStatus'] = 'PendingReceived';
            student['friendRequestReceived'] = true;
          });
        } else if (status == 'Blocked') {
          setState(() {
            student['relationshipStatus'] = 'Blocked';
          });
        }

        _showMessage(
          message,
          isError: true,
        );

        return;
      }

      // ==========================================================
      // OTHER ERROR
      // ==========================================================

      String message = "Unable to add friend.";

      try {
        final data = jsonDecode(response.body);

        if (data['message'] != null) {
          message = data['message'];
        }
      } catch (_) {}

      _showMessage(
        message,
        isError: true,
      );
    } catch (e) {
      debugPrint("ADD FRIEND ERROR: $e");

      if (!mounted) return;

      setState(() {
        student['_addingFriend'] = false;
      });

      _showMessage(
        "Unable to connect to server.",
        isError: true,
      );
    }
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : const Color(0xFF1E8E7E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // GET BUTTON TEXT
  // ============================================================

  String _getButtonText(dynamic student) {
    final status =
        student['relationshipStatus'] ?? 'None';

    switch (status) {
      case 'PendingSent':
        return 'Request Sent';

      case 'PendingReceived':
        return 'Request Received';

      case 'Accepted':
        return 'Friends';

      case 'Blocked':
        return 'Blocked';

      case 'Rejected':
        return 'Add Friend';

      default:
        return 'Add Friend';
    }
  }

  // ============================================================
  // CHECK IF BUTTON CAN BE PRESSED
  // ============================================================

  bool _canAddFriend(dynamic student) {
    final status =
        student['relationshipStatus'] ?? 'None';

    return status == 'None' || status == 'Rejected';
  }

  // ============================================================
  // BUTTON COLOR
  // ============================================================

  Color _getButtonColor(dynamic student) {
    final status =
        student['relationshipStatus'] ?? 'None';

    if (status == 'Accepted') {
      return Colors.green;
    }

    if (status == 'PendingSent') {
      return Colors.grey;
    }

    if (status == 'PendingReceived') {
      return Colors.orange;
    }

    if (status == 'Blocked') {
      return Colors.red;
    }

    return const Color(0xFF1E8E7E);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title: const Text(
          'Add Friends',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        backgroundColor: const Color(0xFF1E8E7E),

        centerTitle: true,

        elevation: 0,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Column(
        children: [

          // ======================================================
          // SEARCH AREA
          // ======================================================

          Container(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              12,
            ),

            color: Colors.white,

            child: TextField(
              controller: _searchController,

              onChanged: _onSearchChanged,

              decoration: InputDecoration(
                hintText: 'Search student by name...',

                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF1E8E7E),
                ),

                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();

                          setState(() {});

                          _loadStudents();
                        },
                      )
                    : null,

                filled: true,

                fillColor: const Color(0xFFF4F4F4),

                contentPadding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF1E8E7E),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // ======================================================
          // SEARCH LOADING
          // ======================================================

          if (isSearching)
            const LinearProgressIndicator(
              minHeight: 2,
              color: Color(0xFF1E8E7E),
            ),

          // ======================================================
          // ERROR MESSAGE
          // ======================================================

          if (errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),

              child: Container(
                width: double.infinity,

                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: Colors.red.shade50,

                  borderRadius:
                      BorderRadius.circular(10),

                  border: Border.all(
                    color: Colors.red.shade200,
                  ),
                ),

                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        errorMessage,

                        style: TextStyle(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ======================================================
          // STUDENT COUNT
          // ======================================================

          if (!isLoading &&
              errorMessage.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                4,
              ),

              child: Row(
                children: [
                  Text(
                    '${students.length} Student${students.length == 1 ? '' : 's'} Found',

                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),

          // ======================================================
          // STUDENT LIST
          // ======================================================

          Expanded(
            child: _buildStudentList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STUDENT LIST
  // ============================================================

  Widget _buildStudentList() {
    // ----------------------------------------------------------
    // LOADING
    // ----------------------------------------------------------

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1E8E7E),
        ),
      );
    }

    // ----------------------------------------------------------
    // EMPTY
    // ----------------------------------------------------------

    if (students.isEmpty) {
      return _buildEmptyState();
    }

    // ----------------------------------------------------------
    // LIST
    // ----------------------------------------------------------

    return RefreshIndicator(
      color: const Color(0xFF1E8E7E),

      onRefresh: () async {
        if (_searchController.text.trim().isEmpty) {
          await _loadStudents();
        } else {
          await _searchStudents(
            _searchController.text.trim(),
          );
        }
      },

      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          20,
        ),

        itemCount: students.length,

        itemBuilder: (context, index) {
          final student = students[index];

          return _buildStudentCard(student);
        },
      ),
    );
  }

  // ============================================================
  // STUDENT CARD
  // ============================================================

  Widget _buildStudentCard(dynamic student) {
    final String fullName =
        student['fullName']?.toString() ??
            'Unknown Student';

    final String email =
        student['email']?.toString() ??
            '';

    final String status =
        student['relationshipStatus']?.toString() ??
            'None';

    final bool isAdding =
        student['_addingFriend'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(14),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        children: [

          // ======================================================
          // PROFILE ICON
          // ======================================================

          Container(
            width: 52,
            height: 52,

            decoration: BoxDecoration(
              color: const Color(0xFF1E8E7E)
                  .withOpacity(0.12),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.person,
              size: 28,
              color: Color(0xFF1E8E7E),
            ),
          ),

          const SizedBox(width: 14),

          // ======================================================
          // STUDENT INFORMATION
          // ======================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  fullName,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),

                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),

                  Text(
                    email,

                    maxLines: 1,

                    overflow:
                        TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],

                const SizedBox(height: 6),

                // Relationship status
                _buildStatusText(status),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ======================================================
          // ADD FRIEND BUTTON
          // ======================================================

          if (_canAddFriend(student))
            SizedBox(
              height: 40,

              child: ElevatedButton(
                onPressed: isAdding
                    ? null
                    : () {
                        _addFriend(student);
                      },

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF1E8E7E),

                  foregroundColor: Colors.white,

                  disabledBackgroundColor:
                      Colors.grey.shade400,

                  elevation: 0,

                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),

                child: isAdding
                    ? const SizedBox(
                        width: 18,
                        height: 18,

                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisSize:
                            MainAxisSize.min,

                        children: [
                          Icon(
                            Icons.person_add,
                            size: 17,
                          ),

                          SizedBox(width: 5),

                          Text(
                            'Add',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            )
          else
            // ----------------------------------------------------
            // STATUS BUTTON
            // ----------------------------------------------------

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),

              decoration: BoxDecoration(
                color: _getButtonColor(student)
                    .withOpacity(0.10),

                borderRadius:
                    BorderRadius.circular(10),
              ),

              child: Text(
                _getButtonText(student),

                style: TextStyle(
                  fontSize: 12,

                  fontWeight:
                      FontWeight.bold,

                  color:
                      _getButtonColor(student),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS TEXT
  // ============================================================

  Widget _buildStatusText(String status) {
    String text = '';
    Color color = Colors.grey;

    switch (status) {
      case 'PendingSent':
        text = 'Friend request sent';
        color = Colors.orange;
        break;

      case 'PendingReceived':
        text = 'Friend request received';
        color = Colors.blue;
        break;

      case 'Accepted':
        text = 'Already friends';
        color = Colors.green;
        break;

      case 'Blocked':
        text = 'Blocked';
        color = Colors.red;
        break;

      case 'Rejected':
        text = 'Request was rejected';
        color = Colors.grey;
        break;

      default:
        text = 'Not connected';
        color = Colors.grey;
    }

    return Text(
      text,

      style: TextStyle(
        fontSize: 11,
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final bool searching =
        _searchController.text.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Container(
              width: 80,
              height: 80,

              decoration: BoxDecoration(
                color: const Color(0xFF1E8E7E)
                    .withOpacity(0.10),

                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.people_outline,
                size: 40,
                color: Color(0xFF1E8E7E),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              searching
                  ? 'No Student Found'
                  : 'No Students Available',

              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              searching
                  ? 'Try searching with another name.'
                  : 'There are no other students to add.',

              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}