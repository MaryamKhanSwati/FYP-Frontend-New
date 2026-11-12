import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:house_of_tutor/services/api_client.dart';

class AdminBlockList extends StatefulWidget {
  const AdminBlockList({super.key});

  @override
  State<AdminBlockList> createState() => _AdminBlockListState();
}

class _AdminBlockListState extends State<AdminBlockList> {
  // =====================================================
  // DATA
  // =====================================================

  List<Map<String, dynamic>> blockedTutors = [];
  List<Map<String, dynamic>> filteredTutors = [];

  bool isLoading = true;

  final TextEditingController searchController =
      TextEditingController();

  // =====================================================
  // THEME
  // =====================================================

  final Color primaryColor = const Color(0xFF159B86);
  final Color greenColor = const Color(0xFF10B981);

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();

    fetchBlockedTutors();

    searchController.addListener(_filterTutors);
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // =====================================================
  // GET BLOCKED TUTORS
  // =====================================================

  Future<void> fetchBlockedTutors() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      // ===================================================
      // API
      // GET /api/Admin/blocked-tutors
      // ===================================================

      final response = await ApiClient.get(
        "/api/Admin/blocked-tutors",
      );

      debugPrint(
        "Blocked Tutors Status: ${response.statusCode}",
      );

      debugPrint(
        "Blocked Tutors Response: ${response.body}",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        if (data is List) {
          final List<Map<String, dynamic>> result = [];

          for (final item in data) {
            if (item is Map) {
              result.add(
                Map<String, dynamic>.from(item),
              );
            }
          }

          if (!mounted) return;

          setState(() {
            blockedTutors = result;
            filteredTutors = List.from(result);
            isLoading = false;
          });

          // Apply current search again
          _filterTutors();

          return;
        }

        if (!mounted) return;

        setState(() {
          blockedTutors = [];
          filteredTutors = [];
          isLoading = false;
        });

        _showSnackBar(
          "Invalid blocked tutors response.",
        );
      } else {
        String message =
            "Failed to load blocked tutors.";

        try {
          final data = jsonDecode(
            utf8.decode(response.bodyBytes),
          );

          if (data is Map &&
              data["message"] != null) {
            message =
                data["message"].toString();
          }
        } catch (_) {}

        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        _showSnackBar(message);
      }
    } catch (e) {
      debugPrint(
        "Fetch blocked tutors error: $e",
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showSnackBar(
        "Cannot connect to server.",
      );
    }
  }

  // =====================================================
  // RESTORE TUTOR
  // =====================================================

  Future<void> restoreTutor(int tutorId) async {
    try {
      // ===================================================
      // API
      // PUT /api/Admin/restore-user/{id}
      // ===================================================

      final response = await ApiClient.put(
        "/api/Admin/restore-user/$tutorId",{}
      );

      debugPrint(
        "Restore Status: ${response.statusCode}",
      );

      debugPrint(
        "Restore Response: ${response.body}",
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = {};

        try {
          final decoded = jsonDecode(
            utf8.decode(response.bodyBytes),
          );

          if (decoded is Map) {
            data =
                Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}

        final success =
            data["success"] == true;

        if (success) {
          _showSnackBar(
            data["message"]?.toString() ??
                "Tutor restored successfully.",
            success: true,
          );

          // Refresh list
          await fetchBlockedTutors();
        } else {
          _showSnackBar(
            data["message"]?.toString() ??
                "Failed to restore tutor.",
          );
        }
      } else {
        String message =
            "Failed to restore tutor.";

        try {
          final data = jsonDecode(
            utf8.decode(response.bodyBytes),
          );

          if (data is Map &&
              data["message"] != null) {
            message =
                data["message"].toString();
          }
        } catch (_) {}

        _showSnackBar(message);
      }
    } catch (e) {
      debugPrint(
        "Restore tutor error: $e",
      );

      _showSnackBar(
        "Cannot connect to server.",
      );
    }
  }

  // =====================================================
  // SEARCH
  // =====================================================

  void _filterTutors() {
    final query =
        searchController.text.trim().toLowerCase();

    if (!mounted) return;

    setState(() {
      if (query.isEmpty) {
        filteredTutors =
            List.from(blockedTutors);
        return;
      }

      filteredTutors =
          blockedTutors.where((tutor) {
        final fullName =
            (tutor["fullName"] ?? "")
                .toString()
                .toLowerCase();

        final id =
            (tutor["id"] ?? "")
                .toString()
                .toLowerCase();

        final email =
            (tutor["email"] ?? "")
                .toString()
                .toLowerCase();

        final phone =
            (tutor["phone"] ?? "")
                .toString()
                .toLowerCase();

        final cnic =
            (tutor["cnic"] ?? "")
                .toString()
                .toLowerCase();

        return fullName.contains(query) ||
            id.contains(query) ||
            email.contains(query) ||
            phone.contains(query) ||
            cnic.contains(query);
      }).toList();
    });
  }

  // =====================================================
  // SNACKBAR
  // =====================================================

  void _showSnackBar(
    String message, {
    bool success = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            success ? greenColor : Colors.red,
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // =====================================================
  // INITIALS
  // =====================================================

  String _getInitials(String name) {
    if (name.trim().isEmpty) {
      return "T";
    }

    final parts =
        name.trim().split(RegExp(r"\s+"));

    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}"
          .toUpperCase();
    }

    return parts[0][0].toUpperCase();
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8FA),

      // ===================================================
      // APP BAR
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
        // Change path here if required
        // =================================================

        title: Image.asset(
          "assets/images/logo.png",
          height: 32,

          errorBuilder:
              (context, error, stackTrace) {
            return const Text(
              "House of Tutor",
              style: TextStyle(
                color: Color(0xFF159B86),
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            );
          },
        ),

        centerTitle: true,

        actions: [
          IconButton(
            onPressed: fetchBlockedTutors,
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFF172033),
              size: 22,
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),

      // ===================================================
      // BODY
      // ===================================================

      body: SafeArea(
        child: Column(
          children: [

            // =================================================
            // PAGE HEADER
            // =================================================

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                18,
                16,
                5,
              ),

              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Blocked Tutors",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Color(0xFF121B2E),
                          ),
                        ),

                        SizedBox(height: 3),

                        Text(
                          "Manage blocked tutor accounts",
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Color(0xFF657386),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // =================================================
            // SEARCH BAR
            // =================================================

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                14,
                16,
                10,
              ),

              child: Container(
                height: 50,

                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(12),

                  border: Border.all(
                    color:
                        const Color(0xFFDDE2E7),
                  ),
                ),

                child: TextField(
                  controller:
                      searchController,

                  style: const TextStyle(
                    fontSize: 14,
                  ),

                  decoration:
                      const InputDecoration(
                    border:
                        InputBorder.none,

                    prefixIcon: Icon(
                      Icons.search,
                      color:
                          Color(0xFF66798D),
                    ),

                    hintText:
                        "Search name, ID, email or phone",

                    hintStyle: TextStyle(
                      fontSize: 13,
                      color:
                          Color(0xFF9AA8B8),
                    ),

                    contentPadding:
                        EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            // =================================================
            // TOTAL BLOCKED
            // =================================================

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
              ),

              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(0xFFFFF0F0),

                      borderRadius:
                          BorderRadius.circular(20),

                      border: Border.all(
                        color:
                            const Color(0xFFFFCACA),
                      ),
                    ),

                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,

                      children: [
                        const Icon(
                          Icons.block,
                          color: Colors.red,
                          size: 15,
                        ),

                        const SizedBox(
                          width: 6,
                        ),

                        Text(
                          "${filteredTutors.length} Total Blocked",

                          style:
                              const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // =================================================
            // LIST
            // =================================================

            Expanded(
              child: isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(
                        color:
                            Color(0xFF159B86),
                      ),
                    )
                  : filteredTutors.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color:
                              const Color(
                            0xFF159B86,
                          ),

                          onRefresh:
                              fetchBlockedTutors,

                          child:
                              ListView.builder(
                            physics:
                                const AlwaysScrollableScrollPhysics(),

                            padding:
                                const EdgeInsets
                                    .fromLTRB(
                              16,
                              5,
                              16,
                              25,
                            ),

                            itemCount:
                                filteredTutors.length,

                            itemBuilder:
                                (context, index) {
                              return _buildTutorCard(
                                filteredTutors[
                                    index],
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

  // =====================================================
  // TUTOR CARD
  // =====================================================

  Widget _buildTutorCard(
    Map<String, dynamic> tutor,
  ) {
    final fullName =
        (tutor["fullName"] ??
                "Unknown Tutor")
            .toString();

    final tutorId =
        tutor["id"];

    final email =
        (tutor["email"] ??
                "Not Provided")
            .toString();

    final phone =
        (tutor["phone"] ??
                "Not Provided")
            .toString();

    final cnic =
        (tutor["cnic"] ??
                "Not Provided")
            .toString();

    final location =
        (tutor["location"] ??
                "Not Provided")
            .toString();

    return Container(
      width: double.infinity,

      margin:
          const EdgeInsets.only(bottom: 12),

      padding:
          const EdgeInsets.all(15),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color:
              const Color(0xFFE0E4E8),
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.03,
            ),

            blurRadius: 5,

            offset:
                const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        children: [

          // ===============================================
          // HEADER
          // ===============================================

          Row(
            children: [

              // INITIALS
              Container(
                width: 46,
                height: 46,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFEAF0FF),

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),

                child: Center(
                  child: Text(
                    _getInitials(
                      fullName,
                    ),

                    style:
                        const TextStyle(
                      color:
                          Color(0xFF2563EB),
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              // NAME
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

                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF121B2E),
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      "Tutor ID: $tutorId",

                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            Color(0xFF69778A),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              // BLOCKED
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFFFF0F0),

                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),

                child:
                    const Text(
                  "Blocked",

                  style:
                      TextStyle(
                    color:
                        Colors.red,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Divider(
            height: 1,
            color:
                Color(0xFFE8EBEE),
          ),

          const SizedBox(height: 12),

          // ===============================================
          // EMAIL
          // ===============================================

          _infoRow(
            Icons.email_outlined,
            "EMAIL",
            email,
          ),

          const SizedBox(height: 9),

          // ===============================================
          // PHONE
          // ===============================================

          _infoRow(
            Icons.phone_outlined,
            "PHONE",
            phone,
          ),

          const SizedBox(height: 9),

          // ===============================================
          // CNIC
          // ===============================================

          _infoRow(
            Icons.badge_outlined,
            "CNIC",
            cnic,
          ),

          const SizedBox(height: 9),

          // ===============================================
          // LOCATION
          // ===============================================

          _infoRow(
            Icons.location_on_outlined,
            "LOCATION",
            location,
          ),

          const SizedBox(height: 14),

          // ===============================================
          // RESTORE BUTTON
          // ===============================================

          SizedBox(
            width: double.infinity,

            height: 45,

            child:
                ElevatedButton.icon(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    greenColor,

                foregroundColor:
                    Colors.white,

                elevation: 0,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),

              icon: const Icon(
                Icons.restore,
                size: 18,
              ),

              label: const Text(
                "Restore Tutor",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              onPressed: () {
                final id =
                    int.tryParse(
                  tutorId.toString(),
                );

                if (id == null) {
                  _showSnackBar(
                    "Invalid tutor ID.",
                  );
                  return;
                }

                _showRestoreDialog(
                  id,
                  fullName,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // INFORMATION ROW
  // =====================================================

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Icon(
          icon,
          size: 17,
          color:
              const Color(0xFF8996A5),
        ),

        const SizedBox(
          width: 8,
        ),

        Text(
          "$title: ",

          style:
              const TextStyle(
            fontSize: 10,
            color:
                Color(0xFF8996A5),
            fontWeight:
                FontWeight.bold,
          ),
        ),

        Expanded(
          child: Text(
            value,

            maxLines: 2,

            overflow:
                TextOverflow.ellipsis,

            style:
                const TextStyle(
              fontSize: 12,
              color:
                  Color(0xFF273447),
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // EMPTY STATE
  // =====================================================

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color:
          const Color(0xFF159B86),

      onRefresh:
          fetchBlockedTutors,

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        children: [
          SizedBox(
            height:
                MediaQuery.of(context)
                        .size
                        .height *
                    0.45,

            child: Center(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  Container(
                    width: 70,
                    height: 70,

                    decoration:
                        const BoxDecoration(
                      color:
                          Color(0xFFF1F3F5),
                      shape:
                          BoxShape.circle,
                    ),

                    child:
                        const Icon(
                      Icons.block,
                      size: 35,
                      color:
                          Color(0xFF9AA8B8),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  const Text(
                    "No Blocked Tutors",
                    style:
                        TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xFF273447),
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  const Text(
                    "There are currently no blocked tutor accounts.",
                    textAlign:
                        TextAlign.center,

                    style:
                        TextStyle(
                      fontSize: 12,
                      color:
                          Color(0xFF8996A5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // RESTORE CONFIRMATION
  // =====================================================

  void _showRestoreDialog(
    int tutorId,
    String tutorName,
  ) {
    showDialog(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              15,
            ),
          ),

          title: const Text(
            "Restore Tutor",
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          content: Text(
            "Are you sure you want to restore $tutorName?",
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },

              child:
                  const Text("Cancel"),
            ),

            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    greenColor,
                foregroundColor:
                    Colors.white,
              ),

              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                restoreTutor(
                  tutorId,
                );
              },

              child:
                  const Text(
                "Restore",
              ),
            ),
          ],
        );
      },
    );
  }
}