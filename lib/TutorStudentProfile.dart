import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:house_of_tutor/services/api_client.dart';

class TutorStudentProfile extends StatefulWidget {
  final int? studentId;

  const TutorStudentProfile({
    super.key,
    this.studentId,
  });

  @override
  State<TutorStudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<TutorStudentProfile> {
  bool loading = true;
  Map<String, dynamic>? profile;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryTeal = Color(0xff229487);
  static const Color darkText = Color(0xff10182b);
  static const Color greyText = Color(0xff6f7d8e);
  static const Color lightBlue = Color(0xffeef6ff);
  static const Color background = Color(0xfff8f9fc);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  // ============================================================
  // FETCH PROFILE
  // ============================================================

  Future<void> fetchProfile() async {
    try {
      if (mounted) {
        setState(() {
          loading = true;
        });
      }

      final String endpoint = widget.studentId != null
          ? '/api/Tutor/student-profile/${widget.studentId}'
          : '/api/Student/my-profile';

      final response = await ApiClient.get(endpoint);

      debugPrint("PROFILE STATUS : ${response.statusCode}");
      debugPrint("PROFILE BODY : ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        if (mounted) {
          setState(() {
            profile = decoded is Map<String, dynamic>
                ? decoded
                : <String, dynamic>{};
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ApiClient.messageFromBody(response.body) ??
                    "Failed to load profile",
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("PROFILE ERROR : $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ============================================================
  // GET VALUE
  // ============================================================

  String getValue(String key) {
    final value = profile?[key];

    if (value == null) {
      return "";
    }

    return value.toString().trim();
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    final bool hasValue = value.trim().isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ICON
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: primaryTeal,
                  size: 23,
                ),
              ),

              const SizedBox(width: 15),

              // TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: greyText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      hasValue ? value : "Not provided",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        color: hasValue
                            ? darkText
                            : const Color(0xff9aa6b5),
                        fontWeight: FontWeight.w600,
                        fontStyle: hasValue
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (!isLast)
          const Divider(
            height: 1,
            color: Color(0xffeeeeee),
          ),
      ],
    );
  }

  // ============================================================
  // PROFILE AVATAR
  // ============================================================

  Widget buildProfileAvatar() {
    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: primaryTeal,
          width: 3,
        ),
      ),
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primaryTeal,
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.person,
          size: 52,
          color: Colors.white,
        ),
      ),
    );
  }

  // ============================================================
  // ACCOUNT BADGE
  // ============================================================

  Widget buildAccountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffeff8ff),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xffdceeff),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: primaryTeal,
            ),
            child: const Icon(
              Icons.check,
              size: 13,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 7),

          const Text(
            "Student Account",
            style: TextStyle(
              fontSize: 13,
              color: primaryTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget buildHeader() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xffe4e6ea),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // BACK BUTTON
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xfff1f5fa),
              borderRadius: BorderRadius.circular(13),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Color(0xff16243a),
              ),
            ),
          ),

          const Spacer(),

          // LOGO
          Image.asset(
            "assets/images/logo.png",
            width: 55,
            height: 55,
            fit: BoxFit.contain,
          ),

          const Spacer(),

          // RIGHT EMPTY SPACE
          const SizedBox(
            width: 42,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PERSONAL INFORMATION CARD
  // ============================================================

  Widget buildInformationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xffeeeeee),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "PERSONAL INFORMATION",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xff8a98a9),
              letterSpacing: 0.4,
            ),
          ),

          const SizedBox(height: 10),

          // FULL NAME
          buildInfoRow(
            icon: Icons.person_outline,
            label: "Full Name",
            value: getValue("full_name"),
          ),

          // EMAIL
          buildInfoRow(
            icon: Icons.mail_outline,
            label: "Email Address",
            value: getValue("email"),
          ),

          // CNIC
          buildInfoRow(
            icon: Icons.badge_outlined,
            label: "CNIC Number",
            value: getValue("cnic"),
          ),

          // PHONE
          buildInfoRow(
            icon: Icons.phone_outlined,
            label: "Contact Number",
            value: getValue("phone"),
          ),

          // LOCATION
          buildInfoRow(
            icon: Icons.location_on_outlined,
            label: "Primary Location",
            value: getValue("location"),
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: primaryTeal,
                ),
              )
            : Column(
                children: [
                  // HEADER
                  buildHeader(),

                  // CONTENT
                  Expanded(
                    child: RefreshIndicator(
                      color: primaryTeal,
                      onRefresh: fetchProfile,
                      child: SingleChildScrollView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 25,
                        ),
                        child: Column(
                          children: [
                            // PROFILE IMAGE
                            buildProfileAvatar(),

                            const SizedBox(height: 18),

                            // NAME
                            Text(
                              getValue("full_name").isEmpty
                                  ? "Student"
                                  : getValue("full_name"),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: darkText,
                              ),
                            ),

                            const SizedBox(height: 9),

                            // ACCOUNT BADGE
                            buildAccountBadge(),

                            const SizedBox(height: 25),

                            // INFORMATION CARD
                            buildInformationCard(),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
