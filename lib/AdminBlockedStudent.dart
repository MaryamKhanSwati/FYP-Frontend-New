import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:house_of_tutor/services/api_client.dart';

class AdminBlockedStudent extends StatefulWidget {
  const AdminBlockedStudent({super.key});

  @override
  State<AdminBlockedStudent> createState() => _AdminBlockedStudentState();
}

class _AdminBlockedStudentState extends State<AdminBlockedStudent> {
  List<dynamic> blockedStudents = [];
  List<dynamic> filteredStudents = [];
  bool isLoading = true;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getBlockedStudents();
    searchController.addListener(applySearch);
  }

  @override
  void dispose() {
    searchController.removeListener(applySearch);
    searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // GET BLOCKED STUDENTS
  // =========================================================

  Future<void> getBlockedStudents() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiClient.get("/api/Admin/blocked-students");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          blockedStudents = data;
          filteredStudents = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load blocked students")),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // =========================================================
  // SEARCH
  // =========================================================

  void applySearch() {
    final query = searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredStudents = blockedStudents;
      } else {
        filteredStudents = blockedStudents.where((s) {
          final fullName = (s["fullName"] ?? "").toString().toLowerCase();
          final id = (s["studentId"] ?? "").toString().toLowerCase();
          final cnic = (s["cnic"] ?? "").toString().toLowerCase();
          final email = (s["email"] ?? "").toString().toLowerCase();

          return fullName.contains(query) ||
              id.contains(query) ||
              cnic.contains(query) ||
              email.contains(query);
        }).toList();
      }
    });
  }

  // =========================================================
  // RESTORE STUDENT
  // =========================================================

  Future<void> restoreStudent(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Restore Student"),
          content:
              const Text("Are you sure you want to restore this student?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Restore"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final response =
          await ApiClient.put("/api/Admin/restore-student/$id", {});

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student restored successfully")),
        );
        getBlockedStudents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to restore student")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // =========================================================
  // INFO BOX (single field)
  // =========================================================

  Widget infoBox({
    required IconData icon,
    required String label,
    required String value,
    bool copyable = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF8F9FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xffE7E9ED)),
            ),
            child: Icon(icon, size: 18, color: const Color(0xff20B486)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.5,
                    color: Color(0xff9AA5B1),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff17233B),
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              icon: const Icon(Icons.copy, size: 18, color: Color(0xff68768A)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Copied to clipboard")),
                );
              },
            ),
        ],
      ),
    );
  }

  // =========================================================
  // HALF-WIDTH INFO BOX (CNIC row pair)
  // =========================================================

  Widget halfInfoBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xffF8F9FB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xffE7E9ED)),
              ),
              child: Icon(icon, size: 18, color: const Color(0xff20B486)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.5,
                      color: Color(0xff9AA5B1),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff17233B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // STUDENT CARD
  // =========================================================

  Widget studentCard(dynamic student) {
    final String fullName = student["fullName"] ?? "";
    final String email =
        (student["email"] == null || student["email"].toString().isEmpty)
            ? "Not Provided"
            : student["email"].toString();
    final String phone =
        (student["phone"] == null || student["phone"].toString().isEmpty)
            ? "Not Provided"
            : student["phone"].toString();
    final String cnic =
        (student["cnic"] == null || student["cnic"].toString().isEmpty)
            ? "Not Provided"
            : student["cnic"].toString();
    final String fatherCnic = (student["fatherCnic"] == null ||
            student["fatherCnic"].toString().isEmpty)
        ? "Not Provided"
        : student["fatherCnic"].toString();
    final String location = (student["location"] == null ||
            student["location"].toString().trim().isEmpty)
        ? "Not Provided"
        : student["location"].toString();
    final int id = student["studentId"];

    final String initials = fullName.trim().isEmpty
        ? "?"
        : fullName
            .trim()
            .split(" ")
            .where((e) => e.isNotEmpty)
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE7E9ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NAME ROW
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xffEDEFFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xff5146D8),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff101C33),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.fingerprint,
                            size: 15, color: Color(0xff9AA5B1)),
                        const SizedBox(width: 3),
                        Text(
                          "ID: $id",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xff9AA5B1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xffFDECEC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.circle, size: 8, color: Color(0xffE74C4C)),
                    SizedBox(width: 5),
                    Text(
                      "Blocked",
                      style: TextStyle(
                        color: Color(0xffE74C4C),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xffE7E9ED)),
          const SizedBox(height: 12),

          // EMAIL
          infoBox(
            icon: Icons.alternate_email,
            label: "EMAIL ADDRESS",
            value: email,
            copyable: true,
          ),

          // PHONE
          infoBox(
            icon: Icons.phone_outlined,
            label: "PHONE NUMBER",
            value: phone,
          ),

          // CNIC + FATHER CNIC
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              halfInfoBox(
                icon: Icons.badge_outlined,
                label: "STUDENT CNIC",
                value: cnic,
              ),
              const SizedBox(width: 10),
              halfInfoBox(
                icon: Icons.people_outline,
                label: "FATHER CNIC",
                value: fatherCnic,
              ),
            ],
          ),

          // LOCATION
          infoBox(
            icon: Icons.location_on_outlined,
            label: "LOCATION / ADDRESS",
            value: location,
          ),

          const SizedBox(height: 6),

          // RESTORE BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => restoreStudent(id),
              icon: const Icon(Icons.restore, size: 20),
              label: const Text(
                "Restore Student",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff20B486),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18, top: 13, bottom: 13),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xffF8F9FC),
              borderRadius: BorderRadius.circular(15),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Color(0xff17233B),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Column(
          children: [
            Text(
              "Blocked Students",
              style: TextStyle(
                color: Color(0xff17233B),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Account Access Management",
              style: TextStyle(
                color: Color(0xff9AA5B1),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18, top: 12, bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xffF8F9FC),
                borderRadius: BorderRadius.circular(15),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.refresh,
                  size: 24,
                  color: Color(0xff17233B),
                ),
                onPressed: getBlockedStudents,
              ),
            ),
          ),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: getBlockedStudents,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 25),
                  children: [
                    // SEARCH BAR
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xffE7E9ED)),
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: "Search by name, ID, CNIC or email...",
                          hintStyle: TextStyle(
                            color: Color(0xff9AA5B1),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xff9AA5B1),
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // TOTAL BLOCKED PILL
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xffFDECEC),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xffF7B8B8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield,
                              size: 16, color: Color(0xffE74C4C)),
                          const SizedBox(width: 8),
                          Text(
                            "${filteredStudents.length} Total Blocked",
                            style: const TextStyle(
                              color: Color(0xffE74C4C),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // LIST
                    if (filteredStudents.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(
                          child: Text("No blocked students found"),
                        ),
                      )
                    else
                      ...filteredStudents.map((s) => studentCard(s)),
                  ],
                ),
        ),
      ),
    );
  }
}