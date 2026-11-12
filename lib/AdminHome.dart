import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:house_of_tutor/AdminDrawer.dart';
import 'package:house_of_tutor/AdminStudent.dart';
import 'package:house_of_tutor/AdminSubject.dart';
import 'package:house_of_tutor/AdminApprovedTutor.dart';
import 'package:house_of_tutor/AdminTutor.dart';
import 'package:house_of_tutor/services/api_client.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
 
  int totalTutors = 0;//varaibles of dashboard
  int totalStudents = 0;
  int totalClasses = 0;
  int totalSubjects = 0;
  int notificationCount = 0;
  bool isLoading = true;

  // INIT STATE mean when thescreen are opens 
  @override
  void initState() {
    super.initState();
    getDashboardData();
    getNotificationCount();
  }

  Future<void> getDashboardData() async {
    try {
      final response = await ApiClient.get(
        "/api/Admin/dashboard",
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;//screen exit or not

        setState(() {
          totalTutors = int.tryParse(
                data["totalTutors"].toString(),
              ) ?? 0;

          totalStudents = int.tryParse(
                data["totalStudents"].toString(),
              ) ??0;

          totalClasses = int.tryParse(
                data["totalClasses"].toString(),
              ) ??0;
              
          totalSubjects = int.tryParse(
                data["totalSubjects"].toString(),
              ) ??0;

          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(//const mean fixed the value 
            content: Text("Failed to load dashboard"),
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

  Future<void> getNotificationCount() async {
    try {
      final response = await ApiClient.get(
        "/api/Admin/notification-count",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          notificationCount = int.tryParse(
                data["count"].toString(),
              ) ??0;
        });
      } else {
        if (!mounted) return;

        setState(() {
          notificationCount = 0;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        notificationCount = 0;
      });
    }
  }

  Widget dashboardCard({
    required String number,
    required String title,
    required IconData icon,
    required Color iconBackground,
    required VoidCallback onTap,//asa func jou kuch return nhi karta
  }) {
    return InkWell(//widget ko click able banta hai 
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xffE7E9ED),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP ROW
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                // ICON
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    size: 27,
                    color: const Color(0xff17233B),
                  ),
                ),

                // ARROW
                const Icon(
                  Icons.arrow_forward,
                  size: 27,
                  color: Color(0xffB7BEC8),
                ),
              ],
            ),

            // =================================================
            // NUMBER + TITLE
            // =================================================

            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // NUMBER
                      Text(
                        number,
                        style: const TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff101C33),
                        ),
                      ),

                      const SizedBox(height: 5),

                      // TITLE
                      Text(
                        title,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          color: Color(0xff68768A),
                        ),
                      ),
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

  // QUICK MANAGEMENT BUTTON
  Widget quickButton({
    required IconData icon,
    required String title,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 78,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xffE7E9ED),
          ),
        ),
        child: Row(
          children: [
            // ICON
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius:
                    BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                size: 26,
                color: iconColor,
              ),
            ),

            const SizedBox(width: 10),

            // TITLE
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff17233B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // OPEN NOTIFICATIONS 
  Future<void> openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminTutor(),
      ),
    );
    // Refresh notification count when coming back from AdminTutor.
    await getNotificationCount();
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      drawer: const AdminDrawer(),
      // APP BAR
     appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        centerTitle: true,
        // MENU
        leading: Builder(
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.only(
                left: 18,
                top: 13,
                bottom: 13,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffF8F9FC),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.menu,
                    size: 29,
                    color: Color(0xff17233B),
                  ),
                  onPressed: () {
                    Scaffold.of(context)
                        .openDrawer();
                  },
                ),
              ),
            );
          },
        ),

        // LOGO
            title: Image.asset(
          "assets/images/logo.png",
          height: 50,
          fit: BoxFit.contain,
          errorBuilder:
              (context, error, stackTrace) {
            return const Text(
              "House of Tutor",
              style: TextStyle(
                color: Color(0xff17233B),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),

        // NOTIFICATION
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 18,
              top: 12,
              bottom: 12,
            ),
            child: Container(
              width: 55,
              decoration: BoxDecoration(
                color: const Color(0xffF8F9FC),
                borderRadius:
                    BorderRadius.circular(15),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // NOTIFICATION ICON
                  Center(
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.notifications_none,
                        size: 30,
                        color: Color(0xff17233B),
                      ),
                      onPressed: () {
                        openNotifications();
                      },
                    ),
                  ),

                  if (notificationCount > 0)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        constraints:
                            const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 5,
                        ),
                        alignment: Alignment.center,
                        decoration:
                            const BoxDecoration(
                          color: Color(0xffE74C4C),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          notificationCount > 99
                              ? "99+"
                              : notificationCount
                                  .toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
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
          onRefresh: () async {
            await getDashboardData();
            await getNotificationCount();
          },
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              18,
              32,
              18,
              25,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // =================================================
                // DASHBOARD OVERVIEW
                // =================================================

                const Text(
                  "DASHBOARD OVERVIEW",
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: 0.8,
                    color: Color(0xff68768A),
                  ),
                ),

                const SizedBox(height: 10),

                // =================================================
                // WELCOME
                // =================================================

                const Row(
                  children: [
                    Flexible(
                      child: Text(
                        "Welcome back, Admin",
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Color(0xff101C33),
                        ),
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      "👋",
                      style: TextStyle(
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                    if (isLoading)
                  const Center(
                    child: Padding(
                      padding:
                          EdgeInsets.all(50),
                      child:
                          CircularProgressIndicator(),
                    ),
                  ),

                // DASHBOARD CARDS
                if (!isLoading)
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.92,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    children: [
                      
                      dashboardCard(
                        number:
                            totalTutors.toString(),
                        title: "Total Tutors",
                        icon:
                            Icons.cast_for_education,
                        iconBackground:
                            const Color(0xffF0F1FF),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminApprovedTutor(),
                            ),
                          );
                        },
                      ),

                      dashboardCard(
                        number:
                            totalStudents.toString(),
                        title: "Total Students",
                        icon: Icons.school,
                        iconBackground:
                            const Color(0xffEFF9FF),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminStudent(),
                            ),
                          );
                        },
                      ),
                    
                      dashboardCard(
                        number:
                            totalClasses.toString(),
                        title: "All Classes",
                        icon:
                            Icons.meeting_room,
                        iconBackground:
                            const Color(0xffF3F0FF),
                        onTap: () {},
                      ),

                      dashboardCard(
                        number:
                            totalSubjects.toString(),
                        title: "Total Subjects",
                        icon: Icons.menu_book,
                        iconBackground:
                            const Color(0xffEFFFF7),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminSubject(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                const SizedBox(height: 35),

                // =================================================
                // QUICK MANAGEMENT
                // =================================================

                const Text(
                  "Quick Management",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                    color: Color(0xff101C33),
                  ),
                ),

                const SizedBox(height: 18),

                // =================================================
                // QUICK BUTTONS
                // =================================================

                Row(
                  children: [
                    // =================================================
                    // APPROVE TUTORS
                    // =================================================

                    Expanded(
                      child: quickButton(
                        icon:
                            Icons.person_add_alt_1,
                        title:
                            "Approve Tutors",
                        backgroundColor:
                            const Color(0xffF0F1FF),
                        iconColor:
                            const Color(0xff5146D8),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminApprovedTutor(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 15),

                    // =================================================
                    // ADD SUBJECTS
                    // =================================================

                    Expanded(
                      child: quickButton(
                        icon:
                            Icons.library_add,
                        title:
                            "Add Subjects",
                        backgroundColor:
                            const Color(0xffEFFFF7),
                        iconColor:
                            const Color(0xff20B486),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminSubject(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),

      // BOTTOM NAVIGATION
  bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: 0,
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
           
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AdminApprovedTutor(),
                ),
              );
            }

            if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AdminStudent(),
                ),
              );
            }

            if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AdminSubject(),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}