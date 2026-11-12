
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:house_of_tutor/StudentDrawer.dart';
import 'package:house_of_tutor/services/api_client.dart';

// ====================================================================
// SHARED VALUES
// ====================================================================

const Color _primary = Color(0xff009688);
const Color _background = Color(0xfff5f5f5);
const String _logoPath = 'assets/images/logo.png';

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim()) ?? 0;
}

String _str(dynamic v, String fallback) {
  if (v == null) return fallback;
  final t = v.toString().trim();
  if (t.isEmpty || t.toLowerCase() == 'null') return fallback;
  return t;
}

dynamic _pick(Map m, List<String> keys) {
  for (final k in keys) {
    if (m[k] != null) return m[k];
  }
  return null;
}

String _errorText(dynamic response, String fallback) {
  final msg = ApiClient.messageFromBody(response.body);
  if (msg != null && msg.trim().isNotEmpty) return msg;
  return fallback;
}

void _showSnack(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: error ? Colors.red : _primary,
    ),
  );
}

AppBar _buildAppBar(GlobalKey<ScaffoldState> key) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 1,
    leading: IconButton(
      icon: const Icon(Icons.menu, color: Colors.black87),
      onPressed: () => key.currentState?.openDrawer(),
    ),
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          _logoPath,
          height: 32,
          width: 32,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school, color: _primary, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'House of Tutor',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    ),
    centerTitle: true,
  );
}

// ====================================================================
// OPTION MODEL
// ====================================================================

class _Option {
  final int id;
  final String label;

  const _Option(this.id, this.label);
}

// ====================================================================
// STUDY GROUP MODEL
// ====================================================================

class StudyGroupItem {
  final int id;
  final String name;
  final String tutorName;
  final String courseName;
  final int tutorId;
  final int courseId;
  final int totalMembers;
  final int maxStudents;
  final int remainingSlots;
  final String status;

  const StudyGroupItem({
    required this.id,
    required this.name,
    required this.tutorName,
    required this.courseName,
    required this.tutorId,
    required this.courseId,
    required this.totalMembers,
    required this.maxStudents,
    required this.remainingSlots,
    required this.status,
  });

  factory StudyGroupItem.fromJson(Map<String, dynamic> json) {
    final maxRaw = _toInt(_pick(json, ['maxStudents', 'max_students']));
    final max = maxRaw == 0 ? 10 : maxRaw;

    final total = _toInt(_pick(json, [
      'totalMembers',
      'total_members',
      'membersCount',
      'memberCount',
      'members',
    ]));

    final remainingRaw =
        _pick(json, ['remainingSlots', 'remaining_slots']);

    final remaining = remainingRaw == null
        ? (max - total).clamp(0, max)
        : _toInt(remainingRaw);

    return StudyGroupItem(
      id: _toInt(_pick(json, ['studyGroupId', 'study_group_id', 'id'])),
      name: _str(
        _pick(json, ['groupName', 'group_name', 'name']),
        'Group',
      ),
      tutorName: _str(
        _pick(json, ['tutorName', 'tutor_name']),
        'Not available',
      ),
      courseName: _str(
        _pick(json, [
          'courseTitle',
          'course_title',
          'courseName',
          'course_name',
        ]),
        'Not available',
      ),
      tutorId: _toInt(_pick(json, ['tutorId', 'tutor_id'])),
      courseId: _toInt(_pick(json, ['courseId', 'course_id'])),
      totalMembers: total,
      maxStudents: max,
      remainingSlots: remaining,
      status: _str(json['status'], 'Open'),
    );
  }
}

// ====================================================================
// GROUP INVITATION MODEL
// ====================================================================

class GroupInvitationItem {
  final int invitationId;
  final int studyGroupId;
  final String groupName;
  final int courseId;
  final String courseName;
  final int tutorId;
  final String tutorName;
  final int invitedByStudentId;
  final String invitedByStudentName;
  final DateTime? invitationDate;
  final String invitationStatus;
  final int totalMembers;
  final int maxStudents;

  const GroupInvitationItem({
    required this.invitationId,
    required this.studyGroupId,
    required this.groupName,
    required this.courseId,
    required this.courseName,
    required this.tutorId,
    required this.tutorName,
    required this.invitedByStudentId,
    required this.invitedByStudentName,
    required this.invitationDate,
    required this.invitationStatus,
    required this.totalMembers,
    required this.maxStudents,
  });

  factory GroupInvitationItem.fromJson(Map<String, dynamic> json) {
    DateTime? date;

    final rawDate = json['invitationDate'];

    if (rawDate != null) {
      date = DateTime.tryParse(rawDate.toString())?.toLocal();
    }

    return GroupInvitationItem(
      invitationId: _toInt(json['invitationId']),
      studyGroupId: _toInt(json['studyGroupId']),
      groupName: _str(json['groupName'], 'Study Group'),
      courseId: _toInt(json['courseId']),
      courseName: _str(json['courseTitle'], 'Course'),
      tutorId: _toInt(json['tutorId']),
      tutorName: _str(json['tutorName'], 'Tutor'),
      invitedByStudentId: _toInt(json['invitedByStudentId']),
      invitedByStudentName:
          _str(json['invitedByStudentName'], 'Student'),
      invitationDate: date,
      invitationStatus: _str(json['invitationStatus'], 'Pending'),
      totalMembers: _toInt(json['totalMembers']),
      maxStudents: _toInt(json['maxStudents']) == 0
          ? 10
          : _toInt(json['maxStudents']),
    );
  }
}

// ====================================================================
// STUDENT GROUP SCREEN
// ====================================================================

class StudentGroup extends StatefulWidget {
  const StudentGroup({super.key});

  @override
  State<StudentGroup> createState() => _StudentGroupState();
}

class _StudentGroupState extends State<StudentGroup> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  // 0 = My Groups
  // 1 = Create Group
  // 2 = Group Invitations
  int tabIndex = 0;

  // ============================================================
  // MY GROUPS
  // ============================================================

  bool groupsLoading = true;
  String groupsError = '';
  List<StudyGroupItem> groups = [];

  // ============================================================
  // CREATE GROUP
  // ============================================================

  final TextEditingController nameController = TextEditingController();

  bool tutorsLoading = true;
  String tutorsError = '';
  List<_Option> tutors = [];
  int? selectedTutorId;

  bool coursesLoading = false;
  List<_Option> courses = [];
  int? selectedCourseId;

  bool creating = false;

  // ============================================================
  // GROUP INVITATIONS
  // ============================================================

  bool invitationsLoading = false;
  String invitationsError = '';
  List<GroupInvitationItem> invitations = [];

  int? respondingInvitationId;

  @override
  void initState() {
    super.initState();

    fetchMyGroups();
    fetchTutors();
    fetchGroupInvitations();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  // ============================================================
  // GET MY STUDY GROUPS
  // ============================================================

  Future<void> fetchMyGroups({bool silent = false}) async {
    if (!mounted) return;

    if (!silent) {
      setState(() {
        groupsLoading = true;
        groupsError = '';
      });
    }

    try {
      final response =
          await ApiClient.get('/api/Student/my-study-groups');

      debugPrint('My Groups Status: ${response.statusCode}');
      debugPrint('My Groups Body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final dynamic data = await ApiClient.decodeJson(response);

        List list = [];

        if (data is List) {
          list = data;
        } else if (data is Map) {
          for (final key in ['groups', 'studyGroups', 'data']) {
            if (data[key] is List) {
              list = data[key];
              break;
            }
          }
        }

        setState(() {
          groups = list
              .whereType<Map>()
              .map((e) => StudyGroupItem.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList();

          groupsLoading = false;
          groupsError = '';
        });
      } else {
        setState(() {
          groupsError =
              _errorText(response, 'Failed to load study groups.');
          groupsLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        groupsError = 'An error occurred: $e';
        groupsLoading = false;
      });
    }
  }

  // ============================================================
  // GET GROUP INVITATIONS
  // GET /api/Student/my-group-invitations
  // ============================================================

  Future<void> fetchGroupInvitations({bool silent = false}) async {
    if (!mounted) return;

    if (!silent) {
      setState(() {
        invitationsLoading = true;
        invitationsError = '';
      });
    }

    try {
      final response = await ApiClient.get(
        '/api/Student/my-group-invitations',
      );

      debugPrint('Group Invitations Status: ${response.statusCode}');
      debugPrint('Group Invitations Body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final dynamic data = await ApiClient.decodeJson(response);

        List list = [];

        if (data is Map && data['invitations'] is List) {
          list = data['invitations'];
        } else if (data is List) {
          list = data;
        }

        setState(() {
          invitations = list
              .whereType<Map>()
              .map((e) => GroupInvitationItem.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .where((e) => e.invitationId > 0)
              .toList();

          invitationsLoading = false;
          invitationsError = '';
        });
      } else {
        setState(() {
          invitationsError = _errorText(
            response,
            'Failed to load group invitations.',
          );
          invitationsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Group Invitations Error: $e');

      if (!mounted) return;

      setState(() {
        invitationsError = 'An error occurred: $e';
        invitationsLoading = false;
      });
    }
  }

  // ============================================================
  // ACCEPT / REJECT GROUP INVITATION
  //
  // POST /api/Student/respond-group-invitation
  //
  // Accept:
  // {
  //   "invitationId": 1,
  //   "response": "Accept"
  // }
  //
  // Reject:
  // {
  //   "invitationId": 1,
  //   "response": "Reject"
  // }
  // ============================================================

  Future<void> respondToInvitation(
    GroupInvitationItem invitation,
    String responseType,
  ) async {
    if (respondingInvitationId != null) return;

    setState(() {
      respondingInvitationId = invitation.invitationId;
    });

    try {
      final response = await ApiClient.post(
        '/api/Student/respond-group-invitation',
        {
          'invitationId': invitation.invitationId,
          'response': responseType,
        },
      );

      debugPrint('Invitation Response Status: ${response.statusCode}');
      debugPrint('Invitation Response Body: ${response.body}');

      final dynamic data = await ApiClient.decodeJson(response);

      if (!mounted) return;

      setState(() {
        respondingInvitationId = null;
      });

      if (response.statusCode == 200) {
        final String message = data is Map
            ? _str(
                data['message'],
                responseType == 'Accept'
                    ? 'Invitation accepted successfully.'
                    : 'Invitation rejected successfully.',
              )
            : 'Invitation ${responseType.toLowerCase()}ed successfully.';

        // Remove the responded invitation from pending list.
        setState(() {
          invitations.removeWhere(
            (item) => item.invitationId == invitation.invitationId,
          );
        });

        _showSnack(context, message);

        // If accepted, the student is now a group member.
        if (responseType == 'Accept') {
          await fetchMyGroups(silent: true);
        }

        // Refresh invitations from the server.
        await fetchGroupInvitations(silent: true);
      } else {
        final String message = data is Map
            ? _str(data['message'], 'Unable to process invitation.')
            : 'Unable to process invitation.';

        _showSnack(context, message, error: true);

        // Refresh because group availability or invitation status
        // may have changed on the server.
        fetchGroupInvitations(silent: true);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        respondingInvitationId = null;
      });

      _showSnack(context, 'Error: $e', error: true);
    }
  }

  // ============================================================
  // CONFIRM ACCEPT / REJECT
  // ============================================================

  Future<void> confirmInvitationResponse(
    GroupInvitationItem invitation,
    String responseType,
  ) async {
    final bool accepting = responseType == 'Accept';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            accepting ? 'Accept Invitation?' : 'Reject Invitation?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            accepting
                ? 'Do you want to join "${invitation.groupName}"? '
                    'You will become an active member of this study group.'
                : 'Are you sure you want to reject the invitation '
                    'for "${invitation.groupName}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accepting ? _primary : Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(accepting ? 'Accept' : 'Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await respondToInvitation(invitation, responseType);
    }
  }

  // ============================================================
  // GET TUTORS
  // ============================================================

  Future<void> fetchTutors() async {
    if (!mounted) return;

    setState(() {
      tutorsLoading = true;
      tutorsError = '';
    });

    try {
      final response = await ApiClient.get(
        '/api/Student/non-visiting-group-tutors',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final dynamic data = await ApiClient.decodeJson(response);

        List list = [];

        if (data is Map && data['tutors'] is List) {
          list = data['tutors'];
        } else if (data is List) {
          list = data;
        }

        setState(() {
          tutors = list
              .whereType<Map>()
              .map((t) => _Option(
                    _toInt(t['tutorId']),
                    _str(t['tutorName'], 'Tutor'),
                  ))
              .where((o) => o.id != 0)
              .toList();

          tutorsLoading = false;
        });
      } else {
        setState(() {
          tutorsError = _errorText(response, 'Failed to load tutors.');
          tutorsLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        tutorsError = 'An error occurred: $e';
        tutorsLoading = false;
      });
    }
  }

  // ============================================================
  // TUTOR SELECTED -> GET COURSES
  // ============================================================

  Future<void> onTutorChanged(int? tutorId) async {
    setState(() {
      selectedTutorId = tutorId;
      selectedCourseId = null;
      courses = [];
      coursesLoading = tutorId != null;
    });

    if (tutorId == null) return;

    try {
      final response = await ApiClient.get(
        '/api/Student/non-visiting-group-tutor-courses?tutorId=$tutorId',
      );

      if (!mounted || selectedTutorId != tutorId) return;

      if (response.statusCode == 200) {
        final dynamic data = await ApiClient.decodeJson(response);

        List list = [];

        if (data is Map && data['courses'] is List) {
          list = data['courses'];
        } else if (data is List) {
          list = data;
        }

        setState(() {
          courses = list
              .whereType<Map>()
              .map((c) => _Option(
                    _toInt(c['courseId']),
                    _str(c['courseTitle'], 'Course'),
                  ))
              .where((o) => o.id != 0)
              .toList();

          coursesLoading = false;
        });
      } else {
        setState(() => coursesLoading = false);

        _showSnack(
          context,
          _errorText(response, 'Failed to load courses.'),
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => coursesLoading = false);
      _showSnack(context, 'Error: $e', error: true);
    }
  }

  // ============================================================
  // CREATE STUDY GROUP
  // ============================================================

  Future<void> createGroup() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      _showSnack(context, 'Please enter a group name.', error: true);
      return;
    }

    if (selectedTutorId == null) {
      _showSnack(context, 'Please select a tutor.', error: true);
      return;
    }

    if (selectedCourseId == null) {
      _showSnack(context, 'Please select a course.', error: true);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => creating = true);

    try {
      final response = await ApiClient.post(
        '/api/Student/create-study-group',
        {
          'groupName': name,
          'tutorId': selectedTutorId,
          'courseId': selectedCourseId,
        },
      );

      final dynamic data = await ApiClient.decodeJson(response);

      if (!mounted) return;

      setState(() => creating = false);

      if (response.statusCode == 200) {
        _showSnack(
          context,
          data is Map
              ? _str(data['message'], 'Study group created successfully.')
              : 'Study group created successfully.',
        );

        nameController.clear();

        setState(() {
          selectedTutorId = null;
          selectedCourseId = null;
          courses = [];
          tabIndex = 0;
        });

        fetchMyGroups();
        fetchTutors();
      } else {
        _showSnack(
          context,
          data is Map
              ? _str(data['message'], 'Failed to create group.')
              : 'Failed to create group.',
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => creating = false);
      _showSnack(context, 'Error: $e', error: true);
    }
  }

  // ============================================================
  // OPEN CLASSMATES
  // ============================================================

  Future<void> openClassmates(StudyGroupItem group) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentGroupClassmates(group: group),
      ),
    );

    if (mounted) {
      fetchMyGroups(silent: true);
    }
  }

  // ============================================================
  // TOGGLE BUTTONS
  // ============================================================

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _tabButton('My Groups', Icons.groups, 0),
          _tabButton('Create', Icons.add_circle_outline, 1),
          _tabButton(
            'Invitations',
            Icons.mail_outline,
            2,
            badgeCount: invitations.length,
          ),
        ],
      ),
    );
  }

  Widget _tabButton(
    String label,
    IconData icon,
    int index, {
    int badgeCount = 0,
  }) {
    final selected = tabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => tabIndex = index);

          if (index == 0) {
            fetchMyGroups(silent: true);
          } else if (index == 2) {
            fetchGroupInvitations();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? _primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 19,
                    color: selected ? Colors.white : _primary,
                  ),
                  if (badgeCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: TextStyle(
                          color: selected ? _primary : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MY GROUPS TAB
  // ============================================================

  Widget _buildMyGroups() {
    return RefreshIndicator(
      color: _primary,
      onRefresh: fetchMyGroups,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Study Groups',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2d2d2d),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'View your Non-Visiting tutor study groups.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => setState(() => tabIndex = 1),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (groupsLoading)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(
                child: CircularProgressIndicator(color: _primary),
              ),
            )
          else if (groupsError.isNotEmpty && groups.isEmpty)
            _messageState(
              Icons.error_outline,
              'Something went wrong',
              groupsError,
            )
          else if (groups.isEmpty)
            _messageState(
              Icons.groups,
              'No study groups yet',
              'Tap + to create your first group.',
            )
          else
            ...groups.map(_buildGroupCard),
        ],
      ),
    );
  }

  Widget _buildGroupCard(StudyGroupItem g) {
    final progress = g.maxStudents == 0
        ? 0.0
        : (g.totalMembers / g.maxStudents).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: const Color(0xffe6f4f1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.groups,
                  color: _primary,
                  size: 38,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2d2d2d),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tutor: ${g.tutorName}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Course: ${g.courseName}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(g.status),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${g.totalMembers}/${g.maxStudents} Members',
                style: const TextStyle(fontSize: 15),
              ),
              Text(
                '${g.remainingSlots} slots left',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xffe6f4f1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(_primary),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => openClassmates(g),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Manage Classmates',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final s = status.toLowerCase();

    Color bg = const Color(0xffe6f4f1);
    Color fg = _primary;

    if (s == 'full') {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
    } else if (s != 'open') {
      bg = Colors.grey.shade200;
      fg = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  // ============================================================
  // GROUP INVITATIONS TAB
  // ============================================================

  Widget _buildGroupInvitations() {
    return RefreshIndicator(
      color: _primary,
      onRefresh: fetchGroupInvitations,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
        children: [
          const Text(
            'Group Invitations',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xff2d2d2d),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'View invitations received from other students. '
            'Accept to join a study group or reject if you are not interested.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 20),

          // REFRESH BUTTON
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: invitationsLoading
                  ? null
                  : fetchGroupInvitations,
              icon: const Icon(Icons.refresh, color: _primary),
              label: const Text(
                'Refresh Invitations',
                style: TextStyle(color: _primary),
              ),
            ),
          ),

          if (invitationsLoading)
            const Padding(
              padding: EdgeInsets.only(top: 65),
              child: Center(
                child: CircularProgressIndicator(color: _primary),
              ),
            )
          else if (invitationsError.isNotEmpty &&
              invitations.isEmpty)
            _messageState(
              Icons.error_outline,
              'Unable to Load Invitations',
              invitationsError,
            )
          else if (invitations.isEmpty)
            _messageState(
              Icons.mail_outline,
              'No Group Invitations',
              'You do not have any pending study group invitations. '
                  'When another student invites you to a group, '
                  'the invitation will appear here.',
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xffe6f4f1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: _primary,
                    size: 25,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You have ${invitations.length} pending '
                      'group invitation(s).',
                      style: const TextStyle(
                        color: Color(0xff2d2d2d),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ...invitations.map(_buildInvitationCard),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // INVITATION CARD
  // ============================================================

  Widget _buildInvitationCard(GroupInvitationItem invitation) {
    final bool isProcessing =
        respondingInvitationId == invitation.invitationId;

    final String invitationDate =
        invitation.invitationDate == null
            ? 'Date not available'
            : DateFormat(
                'dd MMM yyyy, hh:mm a',
              ).format(invitation.invitationDate!);

    final bool groupFull =
        invitation.totalMembers >= invitation.maxStudents;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: const Color(0xffe6f4f1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP SECTION
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xffe6f4f1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.groups,
                  color: _primary,
                  size: 34,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.groupName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2d2d2d),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Study Group Invitation',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Pending',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xffeeeeee)),
          const SizedBox(height: 12),

          // INVITATION DETAILS
          _invitationDetail(
            Icons.person_outline,
            'Invited By',
            invitation.invitedByStudentName,
          ),
          _invitationDetail(
            Icons.school_outlined,
            'Tutor',
            invitation.tutorName,
          ),
          _invitationDetail(
            Icons.menu_book_outlined,
            'Course',
            invitation.courseName,
          ),
          _invitationDetail(
            Icons.groups_outlined,
            'Group Members',
            '${invitation.totalMembers}/${invitation.maxStudents}',
          ),
          _invitationDetail(
            Icons.calendar_today_outlined,
            'Invitation Date',
            invitationDate,
          ),

          const SizedBox(height: 14),

          if (groupFull)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This group currently appears to be full. '
                      'The server will verify availability when you accept.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // ACCEPT AND REJECT BUTTONS
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isProcessing
                      ? null
                      : () => confirmInvitationResponse(
                            invitation,
                            'Reject',
                          ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close, size: 19),
                            SizedBox(width: 5),
                            Text(
                              'Reject',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isProcessing
                      ? null
                      : () => confirmInvitationResponse(
                            invitation,
                            'Accept',
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 19),
                            SizedBox(width: 5),
                            Text(
                              'Accept',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
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

  Widget _invitationDetail(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xff2d2d2d),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CREATE GROUP TAB
  // ============================================================

  Widget _buildCreateGroup() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      children: [
        const Text(
          'Create Study Group',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xff2d2d2d),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose a Non-Visiting tutor and a course you study with that tutor.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        // INFORMATION
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xffe6f4f1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: _primary, size: 30),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Only your approved Non-Visiting tutors and courses '
                  'with accepted requests are available. You will '
                  'automatically be the first member. Each group can '
                  'contain up to 10 active students.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xff2d2d2d),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // FORM
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Group Name *'),
              TextField(
                controller: nameController,
                maxLength: 60,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'e.g. Programming Study Group',
                  prefixIcon: const Icon(
                    Icons.groups,
                    color: Colors.black45,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 18),
                  border: _inputBorder(Colors.grey.shade300),
                  enabledBorder: _inputBorder(Colors.grey.shade300),
                  focusedBorder: _inputBorder(_primary),
                ),
              ),
              const SizedBox(height: 22),

              _label('Non-Visiting Tutor *'),
              _dropdown(
                hint: tutorsLoading
                    ? 'Loading tutors...'
                    : tutors.isEmpty
                        ? (tutorsError.isNotEmpty
                            ? 'Failed to load tutors'
                            : 'No tutors available')
                        : 'Select your tutor',
                value: selectedTutorId,
                options: tutors,
                loading: tutorsLoading,
                enabled: !tutorsLoading && tutors.isNotEmpty,
                onChanged: onTutorChanged,
              ),
              const SizedBox(height: 22),

              _label('Course *'),
              _dropdown(
                hint: selectedTutorId == null
                    ? 'Select a tutor first'
                    : coursesLoading
                        ? 'Loading courses...'
                        : courses.isEmpty
                            ? 'No courses available'
                            : 'Select a course',
                value: selectedCourseId,
                options: courses,
                loading: coursesLoading,
                enabled: selectedTutorId != null &&
                    !coursesLoading &&
                    courses.isNotEmpty,
                onChanged: (id) {
                  setState(() => selectedCourseId = id);
                },
              ),
              const SizedBox(height: 26),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: creating ? null : createGroup,
                  child: creating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline, size: 26),
                            SizedBox(width: 12),
                            Text(
                              'Create Study Group',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xff2d2d2d),
        ),
      ),
    );
  }

  OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: 1.2),
    );
  }

  Widget _dropdown({
    required String hint,
    required int? value,
    required List<_Option> options,
    required bool loading,
    required bool enabled,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: 60,
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.arrow_drop_down_circle,
            color: enabled ? _primary : Colors.grey,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: value,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _primary,
                        ),
                      )
                    : const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.black54,
                        size: 28,
                      ),
                hint: Text(
                  hint,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xff2d2d2d),
                ),
                items: options
                    .map(
                      (o) => DropdownMenuItem<int>(
                        value: o.id,
                        child: Text(
                          o.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMMON MESSAGE STATE
  // ============================================================

  Widget _messageState(
    IconData icon,
    String title,
    String message,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 55,
        horizontal: 10,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 75,
            color: Colors.blueGrey.shade200,
          ),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xff2d2d2d),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _background,
      drawer: const StudentDrawer(),
      appBar: _buildAppBar(_scaffoldKey),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 0),
            child: _buildTabs(),
          ),
          Expanded(
            child: IndexedStack(
              index: tabIndex,
              children: [
                _buildMyGroups(),
                _buildCreateGroup(),
                _buildGroupInvitations(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// MANAGE CLASSMATES SCREEN
// ====================================================================

class StudentGroupClassmates extends StatefulWidget {
  final StudyGroupItem group;

  const StudentGroupClassmates({
    super.key,
    required this.group,
  });

  @override
  State<StudentGroupClassmates> createState() =>
      _StudentGroupClassmatesState();
}

class _StudentGroupClassmatesState
    extends State<StudentGroupClassmates> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  bool isLoading = true;
  String errorMessage = '';

  List<Map<String, dynamic>> students = [];

  late int totalMembers;
  late int maxStudents;
  late int remainingSlots;
  late String status;

  int? addingStudentId;

  @override
  void initState() {
    super.initState();

    totalMembers = widget.group.totalMembers;
    maxStudents = widget.group.maxStudents;
    remainingSlots = widget.group.remainingSlots;
    status = widget.group.status;

    fetchEligibleStudents();
  }

  // ============================================================
  // GET ELIGIBLE STUDENTS
  // ============================================================

  Future<void> fetchEligibleStudents({bool silent = false}) async {
    if (!mounted) return;

    final g = widget.group;

    if (g.id == 0 || g.tutorId == 0 || g.courseId == 0) {
      setState(() {
        errorMessage = 'Group details are missing.';
        isLoading = false;
      });
      return;
    }

    if (!silent) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }

    try {
      final response = await ApiClient.get(
        '/api/Student/eligible-group-students'
        '?tutorId=${g.tutorId}&courseId=${g.courseId}'
        '&studyGroupId=${g.id}',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final dynamic data = await ApiClient.decodeJson(response);

        List list = [];

        if (data is Map && data['students'] is List) {
          list = data['students'];
        }

        setState(() {
          if (data is Map) {
            totalMembers = _toInt(data['totalMembers']);

            maxStudents = _toInt(data['maxStudents']) == 0
                ? maxStudents
                : _toInt(data['maxStudents']);

            remainingSlots = _toInt(data['remainingSlots']);
          }

          students = list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

          isLoading = false;
          errorMessage = '';
        });
      } else {
        setState(() {
          errorMessage =
              _errorText(response, 'Failed to load classmates.');
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  // ============================================================
  // ADD MEMBER
  // ============================================================

  Future<void> addMember(int studentId) async {
    if (addingStudentId != null) return;

    setState(() => addingStudentId = studentId);

    try {
      final response = await ApiClient.post(
        '/api/Student/add-study-group-member',
        {
          'studyGroupId': widget.group.id,
          'studentId': studentId,
        },
      );

      final dynamic data = await ApiClient.decodeJson(response);

      if (!mounted) return;

      setState(() => addingStudentId = null);

      if (response.statusCode == 200 && data is Map) {
        setState(() {
          totalMembers = _toInt(data['totalMembers']);
          remainingSlots = _toInt(data['remainingSlots']);
          status = _str(data['status'], status);
        });

        _showSnack(
          context,
          _str(data['message'], 'Student added successfully.'),
        );

        fetchEligibleStudents(silent: true);
      } else {
        _showSnack(
          context,
          data is Map
              ? _str(data['message'], 'Failed to add student.')
              : 'Failed to add student.',
          error: true,
        );

        fetchEligibleStudents(silent: true);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => addingStudentId = null);
      _showSnack(context, 'Error: $e', error: true);
    }
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 24,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: const Color(0xffe6f4f1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.groups,
              color: _primary,
              size: 42,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.group.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xff2d2d2d),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tutor: ${widget.group.tutorName}',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Course: ${widget.group.courseName}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '$totalMembers/$maxStudents',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: _primary,
            ),
          ),
          const Text(
            'Group Members',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$remainingSlots available slot(s)',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STUDENT CARD
  // ============================================================

  Widget _buildStudentCard(Map<String, dynamic> s) {
    final studentId = _toInt(s['studentId']);
    final name = _str(s['fullName'], 'Student');
    final adding = addingStudentId == studentId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xffe6f4f1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: _primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2d2d2d),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Same tutor and course',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
            onPressed: (adding ||
                    remainingSlots <= 0 ||
                    studentId == 0)
                ? null
                : () => addMember(studentId),
            icon: adding
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.person_add_alt_1,
                    size: 18,
                  ),
            label: const Text(
              'Add',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STUDENTS SECTION
  // ============================================================

  Widget _buildStudentsSection() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(color: _primary),
        ),
      );
    }

    if (errorMessage.isNotEmpty && students.isEmpty) {
      return _messageState(
        Icons.error_outline,
        'Something went wrong',
        errorMessage,
      );
    }

    if (students.isEmpty) {
      if (remainingSlots <= 0 || status.toLowerCase() == 'full') {
        return _messageState(
          Icons.group,
          'Group is Full',
          'This group already has the maximum number of members.',
        );
      }

      return _messageState(
        Icons.person_search,
        'No Eligible Classmates',
        'No other eligible students are available for this tutor and course right now.',
      );
    }

    return Column(
      children: students.map(_buildStudentCard).toList(),
    );
  }

  Widget _messageState(
    IconData icon,
    String title,
    String message,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 50,
        horizontal: 10,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.blueGrey.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xff2d2d2d),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _background,
      drawer: const StudentDrawer(),
      appBar: _buildAppBar(_scaffoldKey),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: fetchEligibleStudents,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_back,
                      color: _primary,
                      size: 26,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Back to My Groups',
                      style: TextStyle(
                        fontSize: 17,
                        color: _primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildSummaryCard(),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eligible Classmates',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2d2d2d),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Students with an accepted request for this same tutor and course.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => fetchEligibleStudents(),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xffe6f4f1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: _primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStudentsSection(),
          ],
        ),
      ),
    );
  }
}

















































// import 'package:flutter/material.dart';
// import 'package:house_of_tutor/StudentDrawer.dart';
// import 'package:house_of_tutor/services/api_client.dart';

// // ====================================================================
// // SHARED VALUES AND HELPERS
// // ====================================================================

// const Color _primary = Color(0xff009688);
// const Color _background = Color(0xfff5f5f5);

// // Logo path (change if your asset path is different)
// const String _logoPath = 'assets/images/logo.png';

// int _toInt(dynamic v) {
//   if (v == null) return 0;
//   if (v is int) return v;
//   if (v is num) return v.toInt();
//   return int.tryParse(v.toString().trim()) ?? 0;
// }

// String _str(dynamic v, String fallback) {
//   if (v == null) return fallback;
//   final String t = v.toString().trim();
//   if (t.isEmpty || t.toLowerCase() == 'null') return fallback;
//   return t;
// }

// // Returns the first non-null value from a list of possible keys.
// dynamic _pick(Map m, List<String> keys) {
//   for (final k in keys) {
//     if (m[k] != null) return m[k];
//   }
//   return null;
// }

// String _errorText(dynamic response, String fallback) {
//   final String? msg = ApiClient.messageFromBody(response.body);
//   if (msg != null && msg.trim().isNotEmpty) return msg;
//   return fallback;
// }

// void _showSnack(BuildContext context, String text, {bool error = false}) {
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(
//       content: Text(text),
//       backgroundColor: error ? Colors.red : _primary,
//     ),
//   );
// }

// // Same app bar on both screens: menu (opens drawer) + logo + title.
// AppBar _buildAppBar(GlobalKey<ScaffoldState> scaffoldKey) {
//   return AppBar(
//     backgroundColor: Colors.white,
//     elevation: 1,
//     leading: IconButton(
//       icon: const Icon(Icons.menu, color: Colors.black87),
//       onPressed: () {
//         scaffoldKey.currentState?.openDrawer();
//       },
//     ),
//     title: Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Image.asset(
//           _logoPath,
//           height: 32,
//           width: 32,
//           fit: BoxFit.contain,
//           errorBuilder: (context, error, stackTrace) {
//             return Container(
//               padding: const EdgeInsets.all(6),
//               decoration: BoxDecoration(
//                 color: Colors.teal.shade50,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: const Icon(Icons.school, color: _primary, size: 20),
//             );
//           },
//         ),
//         const SizedBox(width: 8),
//         const Text(
//           'House of Tutor',
//           style: TextStyle(
//             color: Colors.black87,
//             fontWeight: FontWeight.bold,
//             fontSize: 18,
//           ),
//         ),
//       ],
//     ),
//     centerTitle: true,
//   );
// }

// // ====================================================================
// // MODELS
// // ====================================================================

// class _Option {
//   final int id;
//   final String label;

//   const _Option(this.id, this.label);
// }

// class StudyGroupItem {
//   final int id;
//   final String name;
//   final String tutorName;
//   final String courseName;
//   final int tutorId;
//   final int courseId;
//   final int totalMembers;
//   final int maxStudents;
//   final int remainingSlots;
//   final String status;

//   const StudyGroupItem({
//     required this.id,
//     required this.name,
//     required this.tutorName,
//     required this.courseName,
//     required this.tutorId,
//     required this.courseId,
//     required this.totalMembers,
//     required this.maxStudents,
//     required this.remainingSlots,
//     required this.status,
//   });

//   // Supports camelCase and snake_case keys.
//   factory StudyGroupItem.fromJson(Map<String, dynamic> json) {
//     final int max = _toInt(_pick(json, ['maxStudents', 'max_students'])) == 0
//         ? 10
//         : _toInt(_pick(json, ['maxStudents', 'max_students']));

//     final int total = _toInt(_pick(json, [
//       'totalMembers',
//       'total_members',
//       'membersCount',
//       'memberCount',
//       'members',
//     ]));

//     final dynamic remainingRaw =
//         _pick(json, ['remainingSlots', 'remaining_slots']);

//     final int remaining = remainingRaw == null
//         ? (max - total).clamp(0, max)
//         : _toInt(remainingRaw);

//     return StudyGroupItem(
//       id: _toInt(_pick(json, ['studyGroupId', 'study_group_id', 'id'])),
//       name: _str(_pick(json, ['groupName', 'group_name', 'name']), 'Group'),
//       tutorName:
//           _str(_pick(json, ['tutorName', 'tutor_name']), 'Not available'),
//       courseName: _str(
//         _pick(json, [
//           'courseTitle',
//           'course_title',
//           'courseName',
//           'course_name',
//         ]),
//         'Not available',
//       ),
//       tutorId: _toInt(_pick(json, ['tutorId', 'tutor_id'])),
//       courseId: _toInt(_pick(json, ['courseId', 'course_id'])),
//       totalMembers: total,
//       maxStudents: max,
//       remainingSlots: remaining,
//       status: _str(json['status'], 'Open'),
//     );
//   }
// }

// // ====================================================================
// // STUDENT GROUP SCREEN  (My Groups + Create Group)
// // ====================================================================

// class StudentGroup extends StatefulWidget {
//   const StudentGroup({super.key});

//   @override
//   State<StudentGroup> createState() => _StudentGroupState();
// }

// class _StudentGroupState extends State<StudentGroup> {
//   // Drawer control
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   // 0 = My Groups, 1 = Create Group
//   int tabIndex = 0;

//   // ---------------- My Groups ----------------
//   bool groupsLoading = true;
//   String groupsError = '';
//   List<StudyGroupItem> groups = [];

//   // ---------------- Create Group ----------------
//   final TextEditingController nameController = TextEditingController();

//   bool tutorsLoading = true;
//   String tutorsError = '';
//   List<_Option> tutors = [];
//   int? selectedTutorId;

//   bool coursesLoading = false;
//   List<_Option> courses = [];
//   int? selectedCourseId;

//   bool creating = false;

//   @override
//   void initState() {
//     super.initState();
//     fetchMyGroups();
//     fetchTutors();
//   }

//   @override
//   void dispose() {
//     nameController.dispose();
//     super.dispose();
//   }

//   // ============================================================
//   // GET MY STUDY GROUPS
//   // ============================================================

//   Future<void> fetchMyGroups({bool silent = false}) async {
//     if (!mounted) return;

//     if (!silent) {
//       setState(() {
//         groupsLoading = true;
//         groupsError = '';
//       });
//     }

//     try {
//       final response = await ApiClient.get('/api/Student/my-study-groups');

//       debugPrint('My Groups Status: ${response.statusCode}');
//       debugPrint('My Groups Body: ${response.body}');

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         final dynamic data = await ApiClient.decodeJson(response);

//         if (!mounted) return;

//         List list = [];

//         if (data is List) {
//           list = data;
//         } else if (data is Map) {
//           for (final key in ['groups', 'studyGroups', 'data']) {
//             if (data[key] is List) {
//               list = data[key];
//               break;
//             }
//           }
//         }

//         setState(() {
//           groups = list
//               .whereType<Map>()
//               .map((e) => StudyGroupItem.fromJson(Map<String, dynamic>.from(e)))
//               .toList();
//           groupsLoading = false;
//           groupsError = '';
//         });
//       } else {
//         setState(() {
//           groupsError = _errorText(response, 'Failed to load study groups.');
//           groupsLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('My Groups Error: $e');

//       if (!mounted) return;

//       setState(() {
//         groupsError = 'An error occurred: $e';
//         groupsLoading = false;
//       });
//     }
//   }

//   // ============================================================
//   // GET TUTORS (dropdown 1)
//   // ============================================================

//   Future<void> fetchTutors() async {
//     if (!mounted) return;

//     setState(() {
//       tutorsLoading = true;
//       tutorsError = '';
//     });

//     try {
//       final response =
//           await ApiClient.get('/api/Student/non-visiting-group-tutors');

//       debugPrint('Group Tutors Status: ${response.statusCode}');

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         final dynamic data = await ApiClient.decodeJson(response);

//         if (!mounted) return;

//         List list = [];

//         if (data is Map && data['tutors'] is List) {
//           list = data['tutors'];
//         } else if (data is List) {
//           list = data;
//         }

//         setState(() {
//           tutors = list
//               .whereType<Map>()
//               .map((t) => _Option(
//                     _toInt(t['tutorId']),
//                     _str(t['tutorName'], 'Tutor'),
//                   ))
//               .where((o) => o.id != 0)
//               .toList();
//           tutorsLoading = false;
//         });
//       } else {
//         setState(() {
//           tutorsError = _errorText(response, 'Failed to load tutors.');
//           tutorsLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Group Tutors Error: $e');

//       if (!mounted) return;

//       setState(() {
//         tutorsError = 'An error occurred: $e';
//         tutorsLoading = false;
//       });
//     }
//   }

//   // ============================================================
//   // TUTOR SELECTED -> GET COURSES (dropdown 2)
//   // ============================================================

//   Future<void> onTutorChanged(int? tutorId) async {
//     setState(() {
//       selectedTutorId = tutorId;
//       selectedCourseId = null;
//       courses = [];
//       coursesLoading = tutorId != null;
//     });

//     if (tutorId == null) return;

//     try {
//       final response = await ApiClient.get(
//         '/api/Student/non-visiting-group-tutor-courses?tutorId=$tutorId',
//       );

//       debugPrint('Group Courses Status: ${response.statusCode}');

//       if (!mounted) return;

//       // User selected another tutor while this was loading
//       if (selectedTutorId != tutorId) return;

//       if (response.statusCode == 200) {
//         final dynamic data = await ApiClient.decodeJson(response);

//         if (!mounted) return;

//         List list = [];

//         if (data is Map && data['courses'] is List) {
//           list = data['courses'];
//         } else if (data is List) {
//           list = data;
//         }

//         setState(() {
//           courses = list
//               .whereType<Map>()
//               .map((c) => _Option(
//                     _toInt(c['courseId']),
//                     _str(c['courseTitle'], 'Course'),
//                   ))
//               .where((o) => o.id != 0)
//               .toList();
//           coursesLoading = false;
//         });
//       } else {
//         setState(() => coursesLoading = false);
//         _showSnack(
//           context,
//           _errorText(response, 'Failed to load courses.'),
//           error: true,
//         );
//       }
//     } catch (e) {
//       debugPrint('Group Courses Error: $e');

//       if (!mounted) return;

//       setState(() => coursesLoading = false);
//       _showSnack(context, 'Error: $e', error: true);
//     }
//   }

//   // ============================================================
//   // CREATE STUDY GROUP
//   // ============================================================

//   Future<void> createGroup() async {
//     final String name = nameController.text.trim();

//     if (name.isEmpty) {
//       _showSnack(context, 'Please enter a group name.', error: true);
//       return;
//     }

//     if (selectedTutorId == null) {
//       _showSnack(context, 'Please select a tutor.', error: true);
//       return;
//     }

//     if (selectedCourseId == null) {
//       _showSnack(context, 'Please select a course.', error: true);
//       return;
//     }

//     FocusScope.of(context).unfocus();

//     setState(() => creating = true);

//     try {
//       final response = await ApiClient.post(
//         '/api/Student/create-study-group',
//         {
//           'groupName': name,
//           'tutorId': selectedTutorId,
//           'courseId': selectedCourseId,
//         },
//       );

//       final dynamic resData = await ApiClient.decodeJson(response);

//       if (!mounted) return;

//       setState(() => creating = false);

//       if (response.statusCode == 200) {
//         _showSnack(
//           context,
//           resData is Map
//               ? _str(resData['message'], 'Study group created successfully.')
//               : 'Study group created successfully.',
//         );

//         // Clear the form
//         nameController.clear();
//         setState(() {
//           selectedTutorId = null;
//           selectedCourseId = null;
//           courses = [];
//           tabIndex = 0;
//         });

//         // Refresh lists (the tutor list may change)
//         fetchMyGroups();
//         fetchTutors();
//       } else {
//         _showSnack(
//           context,
//           resData is Map
//               ? _str(resData['message'], 'Failed to create group.')
//               : 'Failed to create group.',
//           error: true,
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;

//       setState(() => creating = false);
//       _showSnack(context, 'Error: $e', error: true);
//     }
//   }

//   // ============================================================
//   // OPEN MANAGE CLASSMATES
//   // ============================================================

//   Future<void> openClassmates(StudyGroupItem group) async {
//     await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => StudentGroupClassmates(group: group),
//       ),
//     );

//     // Member count may have changed
//     if (mounted) fetchMyGroups(silent: true);
//   }

//   // ============================================================
//   // TABS
//   // ============================================================

//   Widget _buildTabs() {
//     return Container(
//       padding: const EdgeInsets.all(6),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           _tabButton('My Groups', Icons.groups, 0),
//           _tabButton('Create Group', Icons.add_circle_outline, 1),
//         ],
//       ),
//     );
//   }

//   Widget _tabButton(String label, IconData icon, int index) {
//     final bool selected = tabIndex == index;

//     return Expanded(
//       child: GestureDetector(
//         onTap: () => setState(() => tabIndex = index),
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           padding: const EdgeInsets.symmetric(vertical: 14),
//           decoration: BoxDecoration(
//             color: selected ? _primary : Colors.transparent,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, size: 22, color: selected ? Colors.white : _primary),
//               const SizedBox(width: 8),
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w500,
//                   color: selected ? Colors.white : _primary,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // MY GROUPS TAB
//   // ============================================================

//   Widget _buildMyGroups() {
//     return RefreshIndicator(
//       color: _primary,
//       onRefresh: fetchMyGroups,
//       child: ListView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
//         children: [
//           // HEADER
//           Row(
//             children: [
//               const Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'My Study Groups',
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xff2d2d2d),
//                       ),
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       'View your Non-Visiting tutor study groups.',
//                       style: TextStyle(fontSize: 14, color: Colors.black54),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 12),
//               InkWell(
//                 onTap: () => setState(() => tabIndex = 1),
//                 borderRadius: BorderRadius.circular(16),
//                 child: Container(
//                   width: 56,
//                   height: 56,
//                   decoration: BoxDecoration(
//                     color: _primary,
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: const Icon(Icons.add, color: Colors.white, size: 30),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 20),

//           // CONTENT
//           if (groupsLoading)
//             const Padding(
//               padding: EdgeInsets.only(top: 80),
//               child: Center(
//                 child: CircularProgressIndicator(color: _primary),
//               ),
//             )
//           else if (groupsError.isNotEmpty && groups.isEmpty)
//             Padding(
//               padding: const EdgeInsets.only(top: 80),
//               child: Center(
//                 child: Text(
//                   groupsError,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(color: Colors.grey, fontSize: 15),
//                 ),
//               ),
//             )
//           else if (groups.isEmpty)
//             Padding(
//               padding: const EdgeInsets.only(top: 80),
//               child: Column(
//                 children: [
//                   Icon(Icons.groups, size: 70, color: Colors.grey.shade300),
//                   const SizedBox(height: 12),
//                   const Text(
//                     'No study groups yet',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black54,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   const Text(
//                     'Tap + to create your first group.',
//                     style: TextStyle(color: Colors.grey),
//                   ),
//                 ],
//               ),
//             )
//           else
//             ...groups.map(_buildGroupCard),
//         ],
//       ),
//     );
//   }

//   Widget _buildGroupCard(StudyGroupItem g) {
//     final double progress =
//         g.maxStudents == 0 ? 0 : (g.totalMembers / g.maxStudents).clamp(0, 1);

//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(22),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.07),
//             blurRadius: 10,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ICON
//               Container(
//                 width: 72,
//                 height: 72,
//                 decoration: BoxDecoration(
//                   color: const Color(0xffe6f4f1),
//                   borderRadius: BorderRadius.circular(18),
//                 ),
//                 child: const Icon(Icons.groups, color: _primary, size: 38),
//               ),

//               const SizedBox(width: 16),

//               // DETAILS
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       g.name,
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xff2d2d2d),
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       'Tutor: ${g.tutorName}',
//                       style: const TextStyle(
//                         fontSize: 15,
//                         color: Colors.black54,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Course: ${g.courseName}',
//                       style: const TextStyle(
//                         fontSize: 15,
//                         color: Colors.black54,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(width: 8),

//               _statusBadge(g.status),
//             ],
//           ),

//           const SizedBox(height: 18),

//           // MEMBERS + SLOTS
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 '${g.totalMembers}/${g.maxStudents} Members',
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: Color(0xff2d2d2d),
//                 ),
//               ),
//               Text(
//                 '${g.remainingSlots} slots left',
//                 style: const TextStyle(fontSize: 15, color: Colors.black54),
//               ),
//             ],
//           ),

//           const SizedBox(height: 10),

//           // PROGRESS BAR
//           ClipRRect(
//             borderRadius: BorderRadius.circular(10),
//             child: LinearProgressIndicator(
//               value: progress.toDouble(),
//               minHeight: 10,
//               backgroundColor: const Color(0xffe6f4f1),
//               valueColor: const AlwaysStoppedAnimation<Color>(_primary),
//             ),
//           ),

//           const SizedBox(height: 18),

//           // MANAGE BUTTON
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: _primary,
//                 foregroundColor: Colors.white,
//                 elevation: 0,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//               ),
//               onPressed: () => openClassmates(g),
//               child: const Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     'Manage Classmates',
//                     style: TextStyle(
//                       fontSize: 17,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(width: 10),
//                   Icon(Icons.arrow_forward, size: 22),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _statusBadge(String status) {
//     final String s = status.toLowerCase();

//     Color bg = const Color(0xffe6f4f1);
//     Color fg = _primary;

//     if (s == 'full') {
//       bg = Colors.orange.shade50;
//       fg = Colors.orange.shade800;
//     } else if (s != 'open') {
//       bg = Colors.grey.shade200;
//       fg = Colors.grey.shade700;
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//       decoration: BoxDecoration(
//         color: bg,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Text(
//         status,
//         style: TextStyle(
//           color: fg,
//           fontWeight: FontWeight.bold,
//           fontSize: 15,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // CREATE GROUP TAB
//   // ============================================================

//   Widget _buildCreateGroup() {
//     return ListView(
//       padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
//       children: [
//         const Text(
//           'Create Study Group',
//           style: TextStyle(
//             fontSize: 26,
//             fontWeight: FontWeight.bold,
//             color: Color(0xff2d2d2d),
//           ),
//         ),

//         const SizedBox(height: 8),

//         const Text(
//           'Choose a Non-Visiting tutor and a course you study with that tutor.',
//           style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.4),
//         ),

//         const SizedBox(height: 20),

//         // INFO BOX
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: const Color(0xffe6f4f1),
//             borderRadius: BorderRadius.circular(18),
//           ),
//           child: const Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Icon(Icons.info_outline, color: _primary, size: 30),
//               SizedBox(width: 14),
//               Expanded(
//                 child: Text(
//                   'Only your approved Non-Visiting tutors and courses with '
//                   'accepted requests are available. You will automatically '
//                   'be the first member. Each group can contain up to 10 '
//                   'active students.',
//                   style: TextStyle(
//                     fontSize: 15,
//                     height: 1.5,
//                     color: Color(0xff2d2d2d),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),

//         const SizedBox(height: 20),

//         // FORM CARD
//         Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(24),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.06),
//                 blurRadius: 10,
//                 offset: const Offset(0, 3),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // GROUP NAME
//               _label('Group Name *'),
//               TextField(
//                 controller: nameController,
//                 maxLength: 60,
//                 textCapitalization: TextCapitalization.words,
//                 decoration: InputDecoration(
//                   counterText: '',
//                   hintText: 'e.g. Programming Study Group',
//                   hintStyle: TextStyle(color: Colors.grey.shade500),
//                   prefixIcon: const Icon(Icons.groups, color: Colors.black45),
//                   contentPadding: const EdgeInsets.symmetric(vertical: 18),
//                   border: _inputBorder(Colors.grey.shade300),
//                   enabledBorder: _inputBorder(Colors.grey.shade300),
//                   focusedBorder: _inputBorder(_primary),
//                 ),
//               ),

//               const SizedBox(height: 22),

//               // TUTOR
//               _label('Non-Visiting Tutor *'),
//               _dropdown(
//                 hint: tutorsLoading
//                     ? 'Loading tutors...'
//                     : (tutors.isEmpty
//                         ? (tutorsError.isNotEmpty
//                             ? 'Failed to load tutors'
//                             : 'No tutors available')
//                         : 'Select your tutor'),
//                 value: selectedTutorId,
//                 options: tutors,
//                 loading: tutorsLoading,
//                 enabled: !tutorsLoading && tutors.isNotEmpty,
//                 onChanged: onTutorChanged,
//               ),

//               const SizedBox(height: 22),

//               // COURSE
//               _label('Course *'),
//               _dropdown(
//                 hint: selectedTutorId == null
//                     ? 'Select a tutor first'
//                     : (coursesLoading
//                         ? 'Loading courses...'
//                         : (courses.isEmpty
//                             ? 'No courses available'
//                             : 'Select a course')),
//                 value: selectedCourseId,
//                 options: courses,
//                 loading: coursesLoading,
//                 enabled: selectedTutorId != null &&
//                     !coursesLoading &&
//                     courses.isNotEmpty,
//                 onChanged: (id) => setState(() => selectedCourseId = id),
//               ),

//               const SizedBox(height: 26),

//               // CREATE BUTTON
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _primary,
//                     foregroundColor: Colors.white,
//                     elevation: 0,
//                     padding: const EdgeInsets.symmetric(vertical: 18),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(18),
//                     ),
//                   ),
//                   onPressed: creating ? null : createGroup,
//                   child: creating
//                       ? const SizedBox(
//                           width: 24,
//                           height: 24,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2.5,
//                             color: Colors.white,
//                           ),
//                         )
//                       : const Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.add_circle_outline, size: 26),
//                             SizedBox(width: 12),
//                             Text(
//                               'Create Study Group',
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _label(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: Text(
//         text,
//         style: const TextStyle(fontSize: 16, color: Color(0xff2d2d2d)),
//       ),
//     );
//   }

//   OutlineInputBorder _inputBorder(Color color) {
//     return OutlineInputBorder(
//       borderRadius: BorderRadius.circular(16),
//       borderSide: BorderSide(color: color, width: 1.2),
//     );
//   }

//   // Dropdown styled like the screenshots
//   Widget _dropdown({
//     required String hint,
//     required int? value,
//     required List<_Option> options,
//     required bool loading,
//     required bool enabled,
//     required ValueChanged<int?> onChanged,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14),
//       height: 60,
//       decoration: BoxDecoration(
//         color: enabled ? Colors.white : Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey.shade300, width: 1.2),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             Icons.arrow_drop_down_circle,
//             color: enabled ? _primary : Colors.grey,
//             size: 28,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: DropdownButtonHideUnderline(
//               child: DropdownButton<int>(
//                 isExpanded: true,
//                 value: value,
//                 dropdownColor: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 icon: loading
//                     ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: _primary,
//                         ),
//                       )
//                     : const Icon(
//                         Icons.keyboard_arrow_down,
//                         color: Colors.black54,
//                         size: 28,
//                       ),
//                 hint: Text(
//                   hint,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(fontSize: 17, color: Colors.grey.shade600),
//                 ),
//                 style: const TextStyle(
//                   fontSize: 17,
//                   color: Color(0xff2d2d2d),
//                 ),
//                 items: options
//                     .map(
//                       (o) => DropdownMenuItem<int>(
//                         value: o.id,
//                         child: Text(o.label, overflow: TextOverflow.ellipsis),
//                       ),
//                     )
//                     .toList(),
//                 onChanged: enabled ? onChanged : null,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // BUILD
//   // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       backgroundColor: _background,

//       // DRAWER
//       drawer: const StudentDrawer(),

//       appBar: _buildAppBar(_scaffoldKey),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
//             child: _buildTabs(),
//           ),
//           Expanded(
//             child: tabIndex == 0 ? _buildMyGroups() : _buildCreateGroup(),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ====================================================================
// // MANAGE CLASSMATES SCREEN
// // ====================================================================
// //
// // Shows the group summary and the students who can be added
// // (accepted request for the same tutor and course).
// // ====================================================================

// class StudentGroupClassmates extends StatefulWidget {
//   final StudyGroupItem group;

//   const StudentGroupClassmates({super.key, required this.group});

//   @override
//   State<StudentGroupClassmates> createState() =>
//       _StudentGroupClassmatesState();
// }

// class _StudentGroupClassmatesState extends State<StudentGroupClassmates> {
//   // Drawer control
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   bool isLoading = true;
//   String errorMessage = '';

//   List<Map<String, dynamic>> students = [];

//   late int totalMembers;
//   late int maxStudents;
//   late int remainingSlots;
//   late String status;

//   // Student who is being added right now
//   int? addingStudentId;

//   @override
//   void initState() {
//     super.initState();

//     totalMembers = widget.group.totalMembers;
//     maxStudents = widget.group.maxStudents;
//     remainingSlots = widget.group.remainingSlots;
//     status = widget.group.status;

//     fetchEligibleStudents();
//   }

//   // ============================================================
//   // GET ELIGIBLE STUDENTS
//   // ============================================================

//   Future<void> fetchEligibleStudents({bool silent = false}) async {
//     if (!mounted) return;

//     final StudyGroupItem g = widget.group;

//     if (g.id == 0 || g.tutorId == 0 || g.courseId == 0) {
//       setState(() {
//         errorMessage =
//             'Group details are missing (group, tutor or course id).';
//         isLoading = false;
//       });
//       return;
//     }

//     if (!silent) {
//       setState(() {
//         isLoading = true;
//         errorMessage = '';
//       });
//     }

//     try {
//       final response = await ApiClient.get(
//         '/api/Student/eligible-group-students'
//         '?tutorId=${g.tutorId}&courseId=${g.courseId}&studyGroupId=${g.id}',
//       );

//       debugPrint('Eligible Status: ${response.statusCode}');
//       debugPrint('Eligible Body: ${response.body}');

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         final dynamic data = await ApiClient.decodeJson(response);

//         if (!mounted) return;

//         List list = [];

//         if (data is Map && data['students'] is List) {
//           list = data['students'];
//         }

//         setState(() {
//           if (data is Map) {
//             totalMembers = _toInt(data['totalMembers']);
//             maxStudents = _toInt(data['maxStudents']) == 0
//                 ? maxStudents
//                 : _toInt(data['maxStudents']);
//             remainingSlots = _toInt(data['remainingSlots']);
//           }

//           students = list
//               .whereType<Map>()
//               .map((e) => Map<String, dynamic>.from(e))
//               .toList();

//           isLoading = false;
//           errorMessage = '';
//         });
//       } else {
//         setState(() {
//           errorMessage = _errorText(response, 'Failed to load classmates.');
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Eligible Error: $e');

//       if (!mounted) return;

//       setState(() {
//         errorMessage = 'An error occurred: $e';
//         isLoading = false;
//       });
//     }
//   }

//   // ============================================================
//   // ADD MEMBER
//   // ============================================================

//   Future<void> addMember(int studentId) async {
//     setState(() => addingStudentId = studentId);

//     try {
//       final response = await ApiClient.post(
//         '/api/Student/add-study-group-member',
//         {
//           'studyGroupId': widget.group.id,
//           'studentId': studentId,
//         },
//       );

//       final dynamic resData = await ApiClient.decodeJson(response);

//       if (!mounted) return;

//       setState(() => addingStudentId = null);

//       if (response.statusCode == 200 && resData is Map) {
//         setState(() {
//           totalMembers = _toInt(resData['totalMembers']);
//           remainingSlots = _toInt(resData['remainingSlots']);
//           status = _str(resData['status'], status);
//         });

//         _showSnack(
//           context,
//           _str(resData['message'], 'Student added successfully.'),
//         );

//         fetchEligibleStudents(silent: true);
//       } else {
//         _showSnack(
//           context,
//           resData is Map
//               ? _str(resData['message'], 'Failed to add student.')
//               : 'Failed to add student.',
//           error: true,
//         );

//         // Group may be full now, refresh the numbers
//         fetchEligibleStudents(silent: true);
//       }
//     } catch (e) {
//       if (!mounted) return;

//       setState(() => addingStudentId = null);
//       _showSnack(context, 'Error: $e', error: true);
//     }
//   }

//   // ============================================================
//   // SUMMARY CARD
//   // ============================================================

//   Widget _buildSummaryCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(26),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.07),
//             blurRadius: 10,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Container(
//             width: 74,
//             height: 74,
//             decoration: BoxDecoration(
//               color: const Color(0xffe6f4f1),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: const Icon(Icons.groups, color: _primary, size: 42),
//           ),

//           const SizedBox(height: 14),

//           Text(
//             widget.group.name,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Color(0xff2d2d2d),
//             ),
//           ),

//           const SizedBox(height: 8),

//           Text(
//             'Tutor: ${widget.group.tutorName}',
//             style: const TextStyle(fontSize: 15, color: Colors.black54),
//           ),

//           const SizedBox(height: 6),

//           Text(
//             'Course: ${widget.group.courseName}',
//             textAlign: TextAlign.center,
//             style: const TextStyle(fontSize: 15, color: Colors.black54),
//           ),

//           const SizedBox(height: 18),

//           Text(
//             '$totalMembers/$maxStudents',
//             style: const TextStyle(
//               fontSize: 40,
//               fontWeight: FontWeight.bold,
//               color: _primary,
//             ),
//           ),

//           const Text(
//             'Group Members',
//             style: TextStyle(fontSize: 16, color: Colors.black54),
//           ),

//           const SizedBox(height: 16),

//           Text(
//             '$remainingSlots available slot(s)',
//             style: const TextStyle(fontSize: 15, color: Colors.black54),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // STUDENT CARD
//   // ============================================================

//   Widget _buildStudentCard(Map<String, dynamic> s) {
//     final int studentId = _toInt(s['studentId']);
//     final String name = _str(s['fullName'], 'Student');
//     final bool adding = addingStudentId == studentId;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 24,
//             backgroundColor: const Color(0xffe6f4f1),
//             child: Text(
//               name.isNotEmpty ? name[0].toUpperCase() : '?',
//               style: const TextStyle(
//                 color: _primary,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 20,
//               ),
//             ),
//           ),

//           const SizedBox(width: 14),

//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   name,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontSize: 17,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xff2d2d2d),
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 const Text(
//                   'Same tutor and course',
//                   style: TextStyle(fontSize: 13, color: Colors.black54),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(width: 8),

//           ElevatedButton.icon(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: _primary,
//               foregroundColor: Colors.white,
//               elevation: 0,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 14,
//                 vertical: 10,
//               ),
//             ),
//             onPressed: (adding || remainingSlots <= 0 || studentId == 0)
//                 ? null
//                 : () => addMember(studentId),
//             icon: adding
//                 ? const SizedBox(
//                     width: 16,
//                     height: 16,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: Colors.white,
//                     ),
//                   )
//                 : const Icon(Icons.person_add_alt_1, size: 18),
//             label: const Text(
//               'Add',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // EMPTY / ERROR STATE
//   // ============================================================

//   Widget _buildMessageState(IconData icon, String title, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 10),
//       child: Column(
//         children: [
//           Icon(icon, size: 80, color: Colors.blueGrey.shade200),
//           const SizedBox(height: 16),
//           Text(
//             title,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//               color: Color(0xff2d2d2d),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             text,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               fontSize: 15,
//               color: Colors.black54,
//               height: 1.4,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStudentsSection() {
//     if (isLoading) {
//       return const Padding(
//         padding: EdgeInsets.symmetric(vertical: 60),
//         child: Center(child: CircularProgressIndicator(color: _primary)),
//       );
//     }

//     if (errorMessage.isNotEmpty && students.isEmpty) {
//       return _buildMessageState(
//         Icons.error_outline,
//         'Something went wrong',
//         errorMessage,
//       );
//     }

//     if (students.isEmpty) {
//       if (remainingSlots <= 0 || status.toLowerCase() == 'full') {
//         return _buildMessageState(
//           Icons.group,
//           'Group is Full',
//           'This group already has the maximum number of members.',
//         );
//       }

//       return _buildMessageState(
//         Icons.person_search,
//         'No Eligible Classmates',
//         'No other eligible students are available for this tutor and '
//             'course right now.',
//       );
//     }

//     return Column(
//       children: students.map(_buildStudentCard).toList(),
//     );
//   }

//   // ============================================================
//   // BUILD
//   // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       backgroundColor: _background,

//       // DRAWER
//       drawer: const StudentDrawer(),

//       appBar: _buildAppBar(_scaffoldKey),
//       body: RefreshIndicator(
//         color: _primary,
//         onRefresh: fetchEligibleStudents,
//         child: ListView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
//           children: [
//             // BACK LINK
//             InkWell(
//               onTap: () => Navigator.pop(context),
//               child: const Padding(
//                 padding: EdgeInsets.symmetric(vertical: 8),
//                 child: Row(
//                   children: [
//                     Icon(Icons.arrow_back, color: _primary, size: 26),
//                     SizedBox(width: 12),
//                     Text(
//                       'Back to My Groups',
//                       style: TextStyle(
//                         fontSize: 17,
//                         color: _primary,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 10),

//             _buildSummaryCard(),

//             const SizedBox(height: 28),

//             // HEADER
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Eligible Classmates',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xff2d2d2d),
//                         ),
//                       ),
//                       SizedBox(height: 6),
//                       Text(
//                         'Students with an accepted request for this same '
//                         'tutor and course.',
//                         style: TextStyle(
//                           fontSize: 15,
//                           color: Colors.black54,
//                           height: 1.4,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 InkWell(
//                   onTap: () => fetchEligibleStudents(),
//                   borderRadius: BorderRadius.circular(14),
//                   child: Container(
//                     width: 50,
//                     height: 50,
//                     decoration: BoxDecoration(
//                       color: const Color(0xffe6f4f1),
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                     child: const Icon(Icons.refresh, color: _primary),
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 16),

//             _buildStudentsSection(),
//           ],
//         ),
//       ),
//     );
//   }
// }