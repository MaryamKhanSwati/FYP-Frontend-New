import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:house_of_tutor/AdminDrawer.dart';
import 'package:house_of_tutor/AdminHome.dart';
import 'package:house_of_tutor/AdminStudent.dart';
import 'package:house_of_tutor/AdminSubject.dart';
import 'package:house_of_tutor/services/api_client.dart';

class AdminApprovedTutor extends StatefulWidget {
  const AdminApprovedTutor({super.key});

  @override
  State<AdminApprovedTutor> createState() =>
      _AdminApprovedTutorState();
}

class _AdminApprovedTutorState extends State<AdminApprovedTutor> {
  List<dynamic> tutors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getApprovedTutors();
  }

  // =========================================================
  // GET APPROVED TUTORS
  // =========================================================

  Future<void> getApprovedTutors() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final response = await ApiClient.get(
        "/api/Admin/approved-tutors",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          tutors = data;
          isLoading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Failed to load approved tutors",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
        ),
      );
    }
  }

  // =========================================================
  // GET TUTOR DETAILS
  // =========================================================

  Future<void> viewTutorDetails(int id) async {
    try {
      final response = await ApiClient.get(
        "/api/Admin/tutor/$id",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                data["fullName"] ?? "",
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Email: ${data["email"] ?? "-"}",
                    ),
                    const SizedBox(height: 6),

                    Text(
                      "Phone: ${data["phone"] ?? "-"}",
                    ),
                    const SizedBox(height: 6),

                    Text(
                      "CNIC: ${data["cnic"] ?? "-"}",
                    ),
                    const SizedBox(height: 6),

                    Text(
                      "Qualification: "
                      "${data["qualification"] ?? "-"}",
                    ),
                    const SizedBox(height: 6),

                    Text(
                      "Experience: "
                      "${data["experience"] ?? "-"}",
                    ),
                    const SizedBox(height: 6),

                    Text(
                      "Location: "
                      "${data["location"] ?? "-"}",
                    ),
                    const SizedBox(height: 6),

                    Text(
                      "Radius: "
                      "${data["radius"] ?? "-"}",
                    ),
                    const SizedBox(height: 6),

                    Text(
                      "Status: "
                      "${data["status"] ?? "-"}",
                    ),
                    const SizedBox(height: 6),

                    Text(
                      "Subjects: "
                      "${(data["subjects"] as List?)?.join(", ") ?? "-"}",
                    ),
                    const SizedBox(height: 6),

                    Text(
                      "Rating: "
                      "${data["rating"]?.toStringAsFixed(1) ?? "0.0"} "
                      "(${data["totalReviews"] ?? 0} reviews)",
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Failed to load tutor details",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
        ),
      );
    }
  }

  // =========================================================
  // REJECT TUTOR
  // =========================================================

  Future<void> rejectTutor(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Reject Tutor",
          ),
          content: const Text(
            "Are you sure you want to reject this tutor?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Reject"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final response = await ApiClient.put(
        "/api/Admin/reject-tutor/$id",
        {},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Tutor rejected successfully",
            ),
          ),
        );

        getApprovedTutors();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Failed to reject tutor",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
        ),
      );
    }
  }

  // =========================================================
  // BLOCK TUTOR
  // =========================================================

  Future<void> blockTutor(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Block Tutor",
          ),
          content: const Text(
            "Are you sure you want to block this tutor?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Block"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final response = await ApiClient.put(
        "/api/Admin/block-tutor/$id",
        {},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Tutor blocked successfully",
            ),
          ),
        );

        getApprovedTutors();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Failed to block tutor",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
        ),
      );
    }
  }

  // =========================================================
  // TUTOR CARD
  // =========================================================

  Widget tutorCard(dynamic tutor) {
    final String fullName =
        tutor["fullName"] ?? "";

    final String status =
        tutor["status"] ?? "";

    final int id =
        int.tryParse(
              tutor["id"].toString(),
            ) ??
            0;

    final String initials =
        fullName.trim().isEmpty
            ? "?"
            : fullName
                .trim()
                .split(" ")
                .where(
                  (e) => e.isNotEmpty,
                )
                .map(
                  (e) => e[0],
                )
                .take(2)
                .join()
                .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xffE7E9ED),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.06,
            ),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // =================================================
          // NAME ROW
          // =================================================

          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    const Color(0xffEFFFF7),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xff20B486),
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 12),

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
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xff101C33),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xffEFFFF7,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color:
                                Color(0xff20B486),
                          ),
                          SizedBox(width: 5),
                          Text(
                            "Approved",
                            style: TextStyle(
                              color:
                                  Color(0xff20B486),
                              fontWeight:
                                  FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // =================================================
          // STATUS BOX
          // =================================================

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  const Color(0xffF8F9FB),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified,
                  color:
                      Color(0xff20B486),
                  size: 22,
                ),

                const SizedBox(width: 10),

                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Status",
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Color(0xff68768A),
                      ),
                    ),

                    Text(
                      status,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xff101C33),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // =================================================
          // ACTION BUTTONS (kept in a single row — compact
          // padding + smaller icon/font so 3 buttons always
          // fit on one line, even on narrow screens)
          // =================================================

          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: "View",
                  icon: Icons.remove_red_eye,
                  bgColor: const Color(0xff258F81),
                  fgColor: Colors.white,
                  onTap: () => viewTutorDetails(id),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _actionButton(
                  label: "Reject",
                  icon: Icons.cancel,
                  bgColor: const Color(0xffF5D67B),
                  fgColor: const Color(0xff101C33),
                  onTap: () => rejectTutor(id),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _actionButton(
                  label: "Block",
                  icon: Icons.block,
                  bgColor: const Color(0xffF7B8B8),
                  fgColor: const Color(0xff101C33),
                  onTap: () => blockTutor(id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SINGLE-LINE ACTION BUTTON HELPER
  // =========================================================
  // Uses FittedBox so the icon+label pair always shrinks to
  // fit inside one line instead of wrapping to two lines on
  // smaller/narrower devices.

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color fgColor,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 10,
        ),
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BOTTOM NAVIGATION
  // =========================================================

  Widget buildBottomNavigationBar() {
    return SafeArea(
      top: false,
      child: BottomNavigationBar(
        // Tutors is selected
        currentIndex: 1,

        type:
            BottomNavigationBarType.fixed,

        backgroundColor: Colors.white,

        elevation: 8,

        selectedItemColor:
            const Color(0xff258F81),

        unselectedItemColor:
            const Color(0xff68768A),

        selectedFontSize: 11,

        unselectedFontSize: 11,

        iconSize: 24,

        selectedLabelStyle:
            const TextStyle(
          fontWeight: FontWeight.bold,
          height: 1.0,
        ),

        unselectedLabelStyle:
            const TextStyle(
          height: 1.0,
        ),

        items: const [
          // HOME
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
            ),
            label: "Home",
          ),

          // TUTORS
          BottomNavigationBarItem(
            icon: Icon(
              Icons.groups,
            ),
            label: "Tutors",
          ),

          // STUDENTS
          BottomNavigationBarItem(
            icon: Icon(
              Icons.school,
            ),
            label: "Students",
          ),

          // SUBJECTS
          BottomNavigationBarItem(
            icon: Icon(
              Icons.menu_book,
            ),
            label: "Subjects",
          ),
        ],

        onTap: (index) {
          // =================================================
          // HOME
          // =================================================

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const AdminHome(),
              ),
            );
          }

          // =================================================
          // TUTORS
          // =================================================

          if (index == 1) {
            // Already on Tutors page.
          }

          // =================================================
          // STUDENTS
          // =================================================

          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const AdminStudent(),
              ),
            );
          }

          // =================================================
          // SUBJECTS
          // =================================================

          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const AdminSubject(),
              ),
            );
          }
        },
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF8F9FB),

      // =====================================================
      // DRAWER
      // =====================================================

      drawer: const AdminDrawer(),

      // =====================================================
      // APP BAR — "Approved Tutors" text replaced with the
      // House of Tutor logo, matching the reference screenshot.
      // Make sure assets/images/logo.png is declared under
      // flutter -> assets in pubspec.yaml.
      // =====================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        title: Image.asset(
          "assets/images/logo.png",
          height: 40,
          fit: BoxFit.contain,
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: getApprovedTutors,

          child: isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )
              : tutors.isEmpty
                  ? ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(
                          height: 150,
                        ),
                        Center(
                          child: Text(
                            "No approved tutors found",
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.all(18),
                      itemCount:
                          tutors.length,
                      itemBuilder:
                          (context, index) {
                        return tutorCard(
                          tutors[index],
                        );
                      },
                    ),
        ),
      ),

      // =====================================================
      // BOTTOM NAVIGATION
      // =====================================================

      bottomNavigationBar:
          buildBottomNavigationBar(),
    );
  }
}
