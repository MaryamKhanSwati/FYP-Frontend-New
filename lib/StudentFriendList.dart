import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:house_of_tutor/services/api_client.dart';

class StudentFriendList extends StatefulWidget {
  const StudentFriendList({super.key});

  @override
  State<StudentFriendList> createState() => _StudentFriendListState();
}

class _StudentFriendListState extends State<StudentFriendList> {
  // ============================================================
  // COLORS
  // ============================================================

  // Main app color
  final Color primaryColor = const Color(0xFF1E8E7E);

  // Background color
  final Color backgroundColor = const Color(0xFFF4F4F4);

  // Text color
  final Color textColor = const Color(0xFF333333);

  // Secondary color
  final Color secondaryColor = const Color(0xFF6A1B9A);

  // ============================================================
  // TOGGLE
  // ============================================================

  // true  = Friend List
  // false = Friend Request
  bool showFriendList = true;

  // ============================================================
  // LOADING
  // ============================================================

  bool isLoading = false;

  // This stores the friendship ID currently being
  // accepted or rejected.
  int? actionFriendshipId;

  // ============================================================
  // DATA
  // ============================================================

  List<dynamic> friends = [];

  List<dynamic> friendRequests = [];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    // When screen opens,
    // show Friend List.
    loadFriends();
  }

  // ============================================================
  // CONVERT API RESPONSE BODY TO JSON
  // ============================================================

  dynamic decodeResponseBody(String body) {
    try {
      if (body.isEmpty) {
        return {};
      }

      return jsonDecode(body);
    } catch (e) {
      return {};
    }
  }

  // ============================================================
  // GET ERROR MESSAGE
  // ============================================================

  String getErrorMessage(
    dynamic data,
    String defaultMessage,
  ) {
    try {
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    } catch (_) {}

    return defaultMessage;
  }

  // ============================================================
  // LOAD FRIEND LIST
  // ============================================================

  Future<void> loadFriends() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      // ========================================================
      // API:
      //
      // GET /api/Student/all-friends
      // ========================================================

      final response = await ApiClient.get(
        '/api/Student/all-friends',
      );

      // ========================================================
      // IMPORTANT:
      //
      // ApiClient returns http.Response.
      //
      // Therefore:
      // response.statusCode
      // response.body
      //
      // NOT:
      // response.data
      // ========================================================

      final data = decodeResponseBody(response.body);

      if (response.statusCode == 200) {
        setState(() {
          friends = data['friends'] ?? [];
        });
      } else {
        showMessage(
          getErrorMessage(
            data,
            'Unable to load friends.',
          ),
          isError: true,
        );
      }
    } catch (e) {
      showMessage(
        'Unable to load friends.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // LOAD FRIEND REQUESTS
  // ============================================================

  Future<void> loadFriendRequests() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      // ========================================================
      // API:
      //
      // GET /api/Student/friend-requests
      // ========================================================

      final response = await ApiClient.get(
        '/api/Student/friend-requests',
      );

      // Convert response.body into JSON
      final data = decodeResponseBody(response.body);

      if (response.statusCode == 200) {
        setState(() {
          friendRequests = data['requests'] ?? [];
        });
      } else {
        showMessage(
          getErrorMessage(
            data,
            'Unable to load friend requests.',
          ),
          isError: true,
        );
      }
    } catch (e) {
      showMessage(
        'Unable to load friend requests.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // ACCEPT FRIEND REQUEST
  // ============================================================

  Future<void> acceptFriendRequest(
    int friendshipId,
  ) async {
    if (!mounted) return;

    setState(() {
      actionFriendshipId = friendshipId;
    });

    try {
      // ========================================================
      // API:
      //
      // POST /api/Student/accept-friend-request
      //
      // BODY:
      //
      // {
      //   "friendshipId": 1
      // }
      // ========================================================

      final response = await ApiClient.post(
        '/api/Student/accept-friend-request',
        {
          'friendshipId': friendshipId,
        },
      );

      // Convert response.body into JSON
      final data = decodeResponseBody(response.body);

      if (response.statusCode == 200) {
        // Remove accepted request from the screen
        setState(() {
          friendRequests.removeWhere(
            (request) =>
                request['friendshipId'] == friendshipId,
          );
        });

        showMessage(
          getErrorMessage(
            data,
            'Friend request accepted successfully.',
          ),
        );

        // Refresh Friend List
        await loadFriends();
      } else {
        showMessage(
          getErrorMessage(
            data,
            'Unable to accept friend request.',
          ),
          isError: true,
        );
      }
    } catch (e) {
      showMessage(
        'Unable to accept friend request.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          actionFriendshipId = null;
        });
      }
    }
  }

  // ============================================================
  // REJECT FRIEND REQUEST
  // ============================================================

  Future<void> rejectFriendRequest(
    int friendshipId,
  ) async {
    if (!mounted) return;

    setState(() {
      actionFriendshipId = friendshipId;
    });

    try {
      // ========================================================
      // API:
      //
      // POST /api/Student/reject-friend-request
      //
      // BODY:
      //
      // {
      //   "friendshipId": 1
      // }
      // ========================================================

      final response = await ApiClient.post(
        '/api/Student/reject-friend-request',
        {
          'friendshipId': friendshipId,
        },
      );

      // Convert response.body into JSON
      final data = decodeResponseBody(response.body);

      if (response.statusCode == 200) {
        // Remove rejected request from screen
        setState(() {
          friendRequests.removeWhere(
            (request) =>
                request['friendshipId'] == friendshipId,
          );
        });

        showMessage(
          getErrorMessage(
            data,
            'Friend request rejected successfully.',
          ),
        );
      } else {
        showMessage(
          getErrorMessage(
            data,
            'Unable to reject friend request.',
          ),
          isError: true,
        );
      }
    } catch (e) {
      showMessage(
        'Unable to reject friend request.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          actionFriendshipId = null;
        });
      }
    }
  }

  // ============================================================
  // CHANGE TOGGLE
  // ============================================================

  void changeTab(bool friendListSelected) {
    setState(() {
      showFriendList = friendListSelected;
    });

    // ==========================================================
    // FRIEND LIST
    // ==========================================================

    if (friendListSelected) {
      loadFriends();
    }

    // ==========================================================
    // FRIEND REQUEST
    // ==========================================================

    else {
      loadFriendRequests();
    }
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),

        backgroundColor:
            isError ? Colors.red : primaryColor,

        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshData() async {
    if (showFriendList) {
      await loadFriends();
    } else {
      await loadFriendRequests();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: primaryColor,

        elevation: 0,

        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'My Friends',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Column(
        children: [
          // ======================================================
          // TOGGLE BUTTON
          // ======================================================

          buildToggle(),

          // ======================================================
          // LIST
          // ======================================================

          Expanded(
            child: RefreshIndicator(
              onRefresh: refreshData,

              color: primaryColor,

              child: isLoading
                  ? buildLoading()
                  : showFriendList
                      ? buildFriendList()
                      : buildFriendRequests(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOGGLE UI
  // ============================================================

  Widget buildToggle() {
    return Container(
      margin: const EdgeInsets.all(16),

      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        children: [
          // ====================================================
          // FRIEND LIST
          // ====================================================

          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!showFriendList) {
                  changeTab(true);
                }
              },

              child: AnimatedContainer(
                duration:
                    const Duration(milliseconds: 250),

                padding:
                    const EdgeInsets.symmetric(
                  vertical: 13,
                ),

                decoration: BoxDecoration(
                  color: showFriendList
                      ? primaryColor
                      : Colors.transparent,

                  borderRadius:
                      BorderRadius.circular(9),
                ),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [
                    Icon(
                      Icons.people,

                      size: 20,

                      color: showFriendList
                          ? Colors.white
                          : textColor,
                    ),

                    const SizedBox(width: 8),

                    Text(
                      'Friend List',

                      style: TextStyle(
                        fontSize: 15,

                        fontWeight:
                            FontWeight.bold,

                        color: showFriendList
                            ? Colors.white
                            : textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ====================================================
          // FRIEND REQUEST
          // ====================================================

          Expanded(
            child: GestureDetector(
              onTap: () {
                if (showFriendList) {
                  changeTab(false);
                }
              },

              child: AnimatedContainer(
                duration:
                    const Duration(milliseconds: 250),

                padding:
                    const EdgeInsets.symmetric(
                  vertical: 13,
                ),

                decoration: BoxDecoration(
                  color: !showFriendList
                      ? secondaryColor
                      : Colors.transparent,

                  borderRadius:
                      BorderRadius.circular(9),
                ),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [
                    Icon(
                      Icons.person_add,

                      size: 20,

                      color: !showFriendList
                          ? Colors.white
                          : textColor,
                    ),

                    const SizedBox(width: 8),

                    Text(
                      'Friend Request',

                      style: TextStyle(
                        fontSize: 15,

                        fontWeight:
                            FontWeight.bold,

                        color: !showFriendList
                            ? Colors.white
                            : textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING UI
  // ============================================================

  Widget buildLoading() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),

      children: [
        SizedBox(
          height:
              MediaQuery.of(context).size.height * 0.30,
        ),

        Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FRIEND LIST
  // ============================================================

  Widget buildFriendList() {
    // ==========================================================
    // NO FRIENDS
    // ==========================================================

    if (friends.isEmpty) {
      return buildEmptyState(
        icon: Icons.people_outline,
        title: 'No Friends Yet',
        subtitle:
            'Your accepted friends will appear here.',
      );
    }

    // ==========================================================
    // FRIENDS
    // ==========================================================

    return ListView.builder(
      physics:
          const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        20,
      ),

      itemCount: friends.length,

      itemBuilder: (context, index) {
        final friend = friends[index];

        return buildFriendCard(friend);
      },
    );
  }

  // ============================================================
  // FRIEND CARD
  // ============================================================

  Widget buildFriendCard(dynamic friend) {
    final String name =
        friend['friendName']?.toString() ??
            'Unknown Student';

    final String email =
        friend['friendEmail']?.toString() ??
            '';

    final String phone =
        friend['friendPhone']?.toString() ??
            '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(14),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        children: [
          // ====================================================
          // PROFILE ICON
          // ====================================================

          CircleAvatar(
            radius: 28,

            backgroundColor:
                primaryColor.withOpacity(0.12),

            child: Icon(
              Icons.person,
              color: primaryColor,
              size: 30,
            ),
          ),

          const SizedBox(width: 14),

          // ====================================================
          // INFORMATION
          // ====================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  name,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 17,

                    fontWeight:
                        FontWeight.bold,

                    color: textColor,
                  ),
                ),

                // ==================================================
                // EMAIL
                // ==================================================

                if (email.isNotEmpty) ...[
                  const SizedBox(height: 5),

                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 15,
                        color:
                            Colors.grey.shade600,
                      ),

                      const SizedBox(width: 5),

                      Expanded(
                        child: Text(
                          email,

                          maxLines: 1,

                          overflow:
                              TextOverflow.ellipsis,

                          style: TextStyle(
                            fontSize: 13,

                            color:
                                Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // ==================================================
                // PHONE
                // ==================================================

                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 15,
                        color:
                            Colors.grey.shade600,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        phone,

                        style: TextStyle(
                          fontSize: 13,

                          color:
                              Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ====================================================
          // ACCEPTED ICON
          // ====================================================

          Container(
            padding: const EdgeInsets.all(8),

            decoration: BoxDecoration(
              color:
                  Colors.green.withOpacity(0.10),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.check,
              color: Colors.green,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FRIEND REQUEST LIST
  // ============================================================

  Widget buildFriendRequests() {
    // ==========================================================
    // NO REQUESTS
    // ==========================================================

    if (friendRequests.isEmpty) {
      return buildEmptyState(
        icon: Icons.person_add_disabled,
        title: 'No Friend Requests',
        subtitle:
            'New friend requests will appear here.',
      );
    }

    // ==========================================================
    // REQUESTS
    // ==========================================================

    return ListView.builder(
      physics:
          const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        20,
      ),

      itemCount: friendRequests.length,

      itemBuilder: (context, index) {
        final request =
            friendRequests[index];

        return buildFriendRequestCard(request);
      },
    );
  }

  // ============================================================
  // FRIEND REQUEST CARD
  // ============================================================

  Widget buildFriendRequestCard(
    dynamic request,
  ) {
    final int friendshipId =
        int.tryParse(
              request['friendshipId']
                      ?.toString() ??
                  '0',
            ) ??
            0;

    final String senderName =
        request['senderName']
                ?.toString() ??
            'Unknown Student';

    final String senderEmail =
        request['senderEmail']
                ?.toString() ??
            '';

    // Check if this particular request
    // is currently processing.
    final bool isProcessing =
        actionFriendshipId == friendshipId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(
          color:
              secondaryColor.withOpacity(0.15),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        children: [
          // ====================================================
          // USER INFORMATION
          // ====================================================

          Row(
            children: [
              CircleAvatar(
                radius: 28,

                backgroundColor:
                    secondaryColor.withOpacity(0.12),

                child: Icon(
                  Icons.person,
                  color: secondaryColor,
                  size: 30,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      senderName,

                      maxLines: 1,

                      overflow:
                          TextOverflow.ellipsis,

                      style: TextStyle(
                        fontSize: 17,

                        fontWeight:
                            FontWeight.bold,

                        color: textColor,
                      ),
                    ),

                    // ==================================================
                    // EMAIL
                    // ==================================================

                    if (senderEmail.isNotEmpty) ...[
                      const SizedBox(height: 5),

                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 15,
                            color:
                                Colors.grey.shade600,
                          ),

                          const SizedBox(width: 5),

                          Expanded(
                            child: Text(
                              senderEmail,

                              maxLines: 1,

                              overflow:
                                  TextOverflow.ellipsis,

                              style: TextStyle(
                                fontSize: 13,

                                color:
                                    Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 5),

                    Text(
                      'Wants to be your friend',

                      style: TextStyle(
                        fontSize: 13,

                        color:
                            secondaryColor,

                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // ====================================================
          // ACCEPT / REJECT
          // ====================================================

          if (isProcessing)

            // ==================================================
            // LOADING
            // ==================================================

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 8,
              ),

              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )

          else

            // ==================================================
            // BUTTONS
            // ==================================================

            Row(
              children: [
                // ==============================================
                // REJECT
                // ==============================================

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (friendshipId > 0) {
                        rejectFriendRequest(
                          friendshipId,
                        );
                      }
                    },

                    icon: const Icon(
                      Icons.close,
                      size: 18,
                    ),

                    label: const Text(
                      'Reject',
                    ),

                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          Colors.red,

                      side: const BorderSide(
                        color: Colors.red,
                      ),

                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 11,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          9,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // ==============================================
                // ACCEPT
                // ==============================================

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (friendshipId > 0) {
                        acceptFriendRequest(
                          friendshipId,
                        );
                      }
                    },

                    icon: const Icon(
                      Icons.check,
                      size: 18,
                    ),

                    label: const Text(
                      'Accept',
                    ),

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          primaryColor,

                      foregroundColor:
                          Colors.white,

                      elevation: 0,

                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 11,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          9,
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
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),

      children: [
        SizedBox(
          height:
              MediaQuery.of(context).size.height * 0.22,
        ),

        Center(
          child: Icon(
            icon,
            size: 70,
            color: Colors.grey.shade400,
          ),
        ),

        const SizedBox(height: 15),

        Center(
          child: Text(
            title,

            style: TextStyle(
              fontSize: 20,

              fontWeight:
                  FontWeight.bold,

              color: textColor,
            ),
          ),
        ),

        const SizedBox(height: 7),

        Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 30,
            ),

            child: Text(
              subtitle,

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 14,

                color:
                    Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}