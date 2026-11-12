import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:house_of_tutor/services/api_config.dart';

class AdminTutor extends StatefulWidget {
  const AdminTutor({Key? key}) : super(key: key);

  @override
  State<AdminTutor> createState() => _AdminTutorState();
}

class _AdminTutorState extends State<AdminTutor> {
  
  List<dynamic> pendingTutors = [];
  List<dynamic> filteredTutors = [];

  bool isLoading = true;

  final TextEditingController searchController = TextEditingController();

  String get baseUrl => '$apiBaseUrl/api/Admin';

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterTutors);
    // Load tutors after screen is initialized.
    fetchPendingTutors();
  }

  @override
  void dispose() {
    // Remove listener before disposing controller.
    searchController.removeListener(_filterTutors);
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchPendingTutors() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      final url = Uri.parse('$baseUrl/all-tutors');
      debugPrint('======================================');
      debugPrint('ADMIN TUTOR API');
      debugPrint('GET: $url');
      debugPrint('======================================');
      final response = await http.get(url);
      debugPrint('Response Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      if (!mounted) return;
      if (response.statusCode == 200) {
        dynamic data;
        try {
          data = json.decode(response.body);
        } catch (e) {
          debugPrint('JSON Decode Error: $e');
          if (!mounted) return;
          setState(() {
            isLoading = false;
          });
          _showSnackBar('Invalid response received from server.');
          return;
        }

        List<dynamic> tutors = [];
        if (data is List) {
          tutors = data;
        } else if (data is Map<String, dynamic>) {
          if (data['tutors'] is List) {
            tutors = data['tutors'];
          } else if (data['data'] is List) {
            tutors = data['data'];
          } else if (data['pendingTutors'] is List) {
            tutors = data['pendingTutors'];
          }
        }

        debugPrint('Total tutors received: ${tutors.length}');

        final List<dynamic> pendingOnly = tutors.where((tutor) {
          if (tutor is! Map) {
            return false;
          }

          final statusValue =
              tutor['status'] ??
              tutor['Status'] ??
              tutor['tutorStatus'] ??
              tutor['TutorStatus'];

          // If API does not send status, keep the tutor.
          if (statusValue == null) {
            return true;
          }

          final status = statusValue.toString().toLowerCase().trim();

          return status == 'pending';
        }).toList();

        debugPrint('Pending tutors after filtering: ${pendingOnly.length}');

        // -----------------------------------------------------
        // UPDATE UI
        // -----------------------------------------------------

        if (!mounted) return;

        setState(() {
          pendingTutors = pendingOnly;
          filteredTutors = List<dynamic>.from(pendingOnly);
          isLoading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        String message = 'Failed to load pending tutors.';

        try {
          final errorData = json.decode(response.body);

          if (errorData is Map) {
            message =
                errorData['message']?.toString() ??
                errorData['error']?.toString() ??
                message;
          }
        } catch (_) {
          // Keep default error message.
        }

        _showSnackBar(message);
      }
    } catch (e) {
      debugPrint('fetchPendingTutors Error: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showSnackBar('An error occurred while loading tutors.');
    }
  }

  Future<void> updateTutorStatus(int id, String action) async {
    try {
      final url = Uri.parse('$baseUrl/$action/$id');

      debugPrint('======================================');
      debugPrint('UPDATE TUTOR STATUS');
      debugPrint('PUT: $url');
      debugPrint('======================================');

      final response = await http.put(url);

      debugPrint('Response Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        dynamic data;

        try {
          data = json.decode(response.body);
        } catch (_) {
          data = {};
        }

        final success = data is Map
            ? (data['success'] == true ||
                data['Success'] == true)
            : true;

        if (success) {
          final message = data is Map
              ? data['message']?.toString() ??
                  data['Message']?.toString() ??
                  'Action completed successfully.'
              : 'Action completed successfully.';

          _showSnackBar(message);

          // Refresh pending tutor list.
          await fetchPendingTutors();
        } else {
          final message = data is Map
              ? data['message']?.toString() ??
                  data['Message']?.toString() ??
                  'Failed to perform action.'
              : 'Failed to perform action.';

          _showSnackBar(message);
        }
      } else {
        String message = 'Failed to perform action.';

        try {
          final data = json.decode(response.body);

          if (data is Map) {
            message =
                data['message']?.toString() ??
                data['Message']?.toString() ??
                message;
          }
        } catch (_) {}

        _showSnackBar(message);
      }
    } catch (e) {
      debugPrint('updateTutorStatus Error: $e');

      if (!mounted) return;

      _showSnackBar('An error occurred: $e');
    }
  }

  void _filterTutors() {
    if (!mounted) return;
    final query = searchController.text.toLowerCase().trim();
    final results = pendingTutors.where((tutor) {
      if (tutor is! Map) {
        return false;
      }

      final name =
          (tutor['fullName'] ??
                  tutor['FullName'] ??
                  tutor['name'] ??
                  '')
              .toString()
              .toLowerCase();

      final email =
          (tutor['email'] ??
                  tutor['Email'] ??
                  '')
              .toString()
              .toLowerCase();

      final id =
          (tutor['tutorId'] ??
                  tutor['TutorId'] ??
                  tutor['id'] ??
                  '')
              .toString()
              .toLowerCase();

      return name.contains(query) ||
          email.contains(query) ||
          id.contains(query);
    }).toList();

    setState(() {
      filteredTutors = results;
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) {
      return 'T';
    }

    final parts = name.trim().split(RegExp(r'\s+'));

    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return parts[0][0].toUpperCase();
  }

  String _value(
    Map tutor,
    String key1, {
    String? key2,
    String defaultValue = 'N/A',
  }) {
    final value =
        tutor[key1] ??
        (key2 != null ? tutor[key2] : null);

    if (value == null || value.toString().trim().isEmpty) {
      return defaultValue;
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),

        title: const Column(
          children: [
            Text(
              'Pending Tutors',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Approval Management',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),

        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.black,
            ),
            onPressed: isLoading
                ? null
                : () {
                    fetchPendingTutors();
                  },
          ),
        ],
      ),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by name, email, ID...',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.pending_actions,
                      color: Colors.orange,
                      size: 14,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      '${filteredTutors.length} Total Pending',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
 Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : filteredTutors.isEmpty
                    ? RefreshIndicator(
                        onRefresh: fetchPendingTutors,
                        child: ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 180),

                            Center(
                              child: Text(
                                'No pending tutors found.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchPendingTutors,

                        child: ListView.builder(
                          physics:
                              const AlwaysScrollableScrollPhysics(),

                          padding: const EdgeInsets.only(
                            bottom: 20,
                          ),

                          itemCount: filteredTutors.length,

                          itemBuilder: (context, index) {
                            final tutor =
                                filteredTutors[index];

                            if (tutor is! Map) {
                              return const SizedBox.shrink();
                            }

                            final fullName = _value(
                              tutor,
                              'fullName',
                              key2: 'FullName',
                              defaultValue: 'Unknown',
                            );

                            final tutorIdValue =
                                tutor['tutorId'] ??
                                tutor['TutorId'] ??
                                tutor['id'] ??
                                tutor['Id'] ??
                                0;

                            final int tutorId =
                                int.tryParse(
                                      tutorIdValue.toString(),
                                    ) ??
                                    0;

                            final email = _value(
                              tutor,
                              'email',
                              key2: 'Email',
                              defaultValue:
                                  'Not Available',
                            );

                            final phone = _value(
                              tutor,
                              'phone',
                              key2: 'Phone',
                              defaultValue:
                                  'Not Available',
                            );

                            final qualification =
                                _value(
                              tutor,
                              'qualification',
                              key2: 'Qualification',
                              defaultValue: 'N/A',
                            );

                            final experience = _value(
                              tutor,
                              'experience',
                              key2: 'Experience',
                              defaultValue: 'N/A',
                            );

                            final location = _value(
                              tutor,
                              'location',
                              key2: 'Location',
                              defaultValue:
                                  'Not Provided',
                            );

                            // ---------------------------------
                            // TUTOR CARD
                            // ---------------------------------

                            return Container(
                              margin:
                                  const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),

                              padding:
                                  const EdgeInsets.all(16),

                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(16),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey
                                        .withOpacity(0.1),
                                    blurRadius: 6,
                                    offset:
                                        const Offset(0, 3),
                                  ),
                                ],
                              ),

                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [

                                  // ===========================
                                  // HEADER
                                  // ===========================

                                  Row(
                                    children: [

                                      Container(
                                        padding:
                                            const EdgeInsets.all(
                                          12,
                                        ),

                                        decoration:
                                            BoxDecoration(
                                          color: Colors
                                              .teal.shade50,
                                          borderRadius:
                                              BorderRadius
                                                  .circular(12),
                                        ),

                                        child: Text(
                                          _getInitials(
                                            fullName,
                                          ),

                                          style: TextStyle(
                                            color: Colors
                                                .teal.shade700,
                                            fontWeight:
                                                FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [

                                            Text(
                                              fullName,
                                              style:
                                                  const TextStyle(
                                                fontSize: 16,
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

                                            Text(
                                              'ID: $tutorId',
                                              style:
                                                  const TextStyle(
                                                color:
                                                    Colors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Container(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),

                                        decoration:
                                            BoxDecoration(
                                          color: Colors
                                              .orange.shade50,
                                          borderRadius:
                                              BorderRadius
                                                  .circular(12),
                                        ),

                                        child: const Text(
                                          'Pending',
                                          style: TextStyle(
                                            color:
                                                Colors.orange,
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Divider(
                                    height: 24,
                                  ),

                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.email_outlined,
                                        size: 16,
                                        color: Colors.grey,
                                      ),

                                      const SizedBox(width: 8),

                                      Expanded(
                                        child: Text(
                                          email,
                                          style:
                                              const TextStyle(
                                            fontSize: 13,
                                            color:
                                                Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_outlined,
                                        size: 16,
                                        color: Colors.grey,
                                      ),

                                      const SizedBox(width: 8),

                                      Expanded(
                                        child: Text(
                                          phone,
                                          style:
                                              const TextStyle(
                                            fontSize: 13,
                                            color:
                                                Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.school_outlined,
                                        size: 16,
                                        color: Colors.grey,
                                      ),

                                      const SizedBox(width: 8),

                                      Expanded(
                                        child: Text(
                                          'Qualification: $qualification',
                                          style:
                                              const TextStyle(
                                            fontSize: 13,
                                            color:
                                                Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  // ===========================
                                  // EXPERIENCE
                                  // ===========================

                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.work_outline,
                                        size: 16,
                                        color: Colors.grey,
                                      ),

                                      const SizedBox(width: 8),

                                      Expanded(
                                        child: Text(
                                          'Experience: $experience',
                                          style:
                                              const TextStyle(
                                            fontSize: 13,
                                            color:
                                                Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  // ===========================
                                  // LOCATION
                                  // ===========================

                                  Row(
                                    children: [
                                      const Icon(
                                        Icons
                                            .location_on_outlined,
                                        size: 16,
                                        color: Colors.grey,
                                      ),

                                      const SizedBox(width: 8),

                                      Expanded(
                                        child: Text(
                                          'Location: $location',
                                          style:
                                              const TextStyle(
                                            fontSize: 13,
                                            color:
                                                Colors.black87,
                                          ),
                                          overflow:
                                              TextOverflow
                                                  .ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                Row(
                       children: [
                              Expanded(
      child: SizedBox(
        height: 42,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: tutorId == 0
              ? null
              : () {
                  updateTutorStatus(
                    tutorId,
                    'approve-tutor',
                  );
                },
          child: const Text(
            'Approve',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),

    const SizedBox(width: 6),
    Expanded(
      child: SizedBox(
        height: 42,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: tutorId == 0
              ? null
              : () {
                  updateTutorStatus(
                    tutorId,
                    'reject-tutor',
                  );
                },
          child: const Text(
            'Reject',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),

    const SizedBox(width: 6),

    Expanded(
      child: SizedBox(
        height: 42,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: tutorId == 0
              ? null
              : () {
                  updateTutorStatus(
                    tutorId,
                    'block-tutor',
                  );
                },
          child: const Text(
            'Block',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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
    );
  }
}
