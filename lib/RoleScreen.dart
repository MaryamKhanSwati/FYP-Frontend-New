import 'package:flutter/material.dart';
import 'package:house_of_tutor/StudentSignupScreen.dart';
import 'package:house_of_tutor/TutorSignupScreen.dart';
import 'package:house_of_tutor/LoginScreen.dart';

class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {

  static const Color primaryColor = Color(0xFF249688);
  static const Color headingColor = Color(0xFF07152E);
  static const Color textColor = Color(0xFF526174);
  static const Color lightTextColor = Color(0xFF8C9AAF);
  static const Color cardBackground = Colors.white;
  static const Color iconBackground = Color(0xFFF0F4FC);

  String selectedRole = 'Student';
//navigation
  void _goToStudentSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StudentSignupScreen(),
      ),
    );
  }

  void _goToTeacherSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TutorSignupScreen(),
      ),
    );
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }
//role card
  Widget _buildRoleCard({
    required String role,
    required String smallTitle,
    required String title,
    required String description,
    required IconData icon,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    final bool isSelected = selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = role;
        });

        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          18,
        ),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : const Color(0xFFE1E6ED),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                isSelected ? 0.07 : 0.04,
              ),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================================================
            // TOP SECTION
            // =================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ICON
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    icon,
                    size: 34,
                    color: isSelected
                        ? primaryColor
                        : const Color(0xFF65758A),
                  ),
                ),

                const SizedBox(width: 16),

                // TITLE
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        smallTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: lightTextColor,
                          letterSpacing: 0.6,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: headingColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // RADIO
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : const Color(0xFFD0D8E2),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration:
                                const BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 18),

            // =================================================
            // DESCRIPTION
            // =================================================

            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: textColor,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 17),

            // =================================================
            // DIVIDER
            // =================================================

            Container(
              height: 1,
              width: double.infinity,
              color: const Color(0xFFE9EDF2),
            ),

            const SizedBox(height: 15),

            // =================================================
            // FEATURES
            // =================================================

            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: features.map(
                (feature) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 21,
                        height: 21,
                        decoration:
                            const BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),

                      const SizedBox(width: 7),

                      Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 13,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // MAIN UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: SafeArea(
        child: Stack(
          children: [
            // =================================================
            // SCROLLABLE CONTENT
            // =================================================

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                left: 18,
                right: 18,
                bottom: 105,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 650,
                  ),
                  child: Column(
                    children: [
                      // =================================================
                      // TOP SPACE
                      // =================================================

                      SizedBox(
                        height: screenSize.height < 700
                            ? 15
                            : 22,
                      ),

                      // =================================================
                      // LOGO
                      // =================================================

                      Image.asset(
                        'assets/images/logo.png',
                        width: 145,
                        height: 82,
                        fit: BoxFit.contain,
                      ),

                      SizedBox(
                        height: screenSize.height < 700
                            ? 14
                            : 20,
                      ),

                      // =================================================
                      // STEP 1 OF 3
                      // =================================================

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F4FD),
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFC9D4F5),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'STEP 1 OF 3',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 17),

                      // =================================================
                      // HEADING
                      // =================================================

                      const Text(
                        'Choose Your Account Type',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          color: headingColor,
                          letterSpacing: -0.4,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // =================================================
                      // SUBTITLE
                      // =================================================

                      const Text(
                        'Select how you intend to use House of Tutor to\n'
                        'personalize your experience.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 25),
                      // STUDENT CARD
                        _buildRoleCard(
                        role: 'Student',
                        smallTitle: 'LEARNER',
                        title: 'I am a Student',
                        description:
                            'Connect with qualified home and online tutors, '
                            'book personalized sessions, track learning '
                            'milestones, and elevate your academic performance.',
                        icon: Icons.school_rounded,
                        features: const [
                          'Book Expert Tutors',
                          'Track Progress',
                        ],
                        onTap: _goToStudentSignup,
                      ),

                      const SizedBox(height: 16),
                      // TEACHER CARD
                      _buildRoleCard(
                        role: 'Teacher',
                        smallTitle: 'EDUCATOR',
                        title: 'I am a Teacher',
                        description:
                            'Share your expertise, set flexible teaching '
                            'schedules, reach motivated students nearby, '
                            'and manage bookings through a unified dashboard.',
                        icon: Icons.psychology_rounded,
                        features: const [
                          'Manage Schedule',
                          'Grow Student Base',
                        ],
                        onTap: _goToTeacherSignup,
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),

            // FIXED LOGIN BAR
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(
                      color: Color(0xFFE5E9EE),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment:
                          WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        GestureDetector(
                          onTap: _goToLogin,
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
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