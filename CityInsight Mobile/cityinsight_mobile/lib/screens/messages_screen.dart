import 'package:cityinsight_mobile/screens/chat_page.dart';
import 'package:cityinsight_mobile/services/chat/chat.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, required this.isDarkMode});
  final bool isDarkMode;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ChatService _chatService = ChatService();
  String query = '';
  String? currentUserProfilePic;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserProfilePicture();
  }

  void _fetchCurrentUserProfilePicture() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch the user's profile picture from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        currentUserProfilePic = userDoc[
            'profileImageUrl']; // Assuming 'avatarUrl' contains the profile picture URL
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.isDarkMode
            ? Colors.grey[900]
            : Colors.blue, // Adjust AppBar color
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Messages",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Overall padding for body
        child: Column(
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: widget.isDarkMode
                    ? Colors.grey[800]
                    : Colors.white, // Search bar background
              ),
              child: TextField(
                onChanged: (value) => setState(() {
                  query = value.toLowerCase();
                }),
                style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: "Search users...",
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search,
                      color: widget.isDarkMode
                          ? Colors.white
                          : Colors.grey), // Icon color
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
            const Gap(10),
            // Expanded list of items
            Expanded(
              child: _buildUserList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder(
      stream: _chatService.getUsersWithoutBlocked(),
      builder: (_, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error"));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];

        // Filter users based on the query
        final filteredUsers = query.isEmpty
            ? users
            : users.where((userData) {
                final fullName =
                    "${userData['firstname']} ${userData['lastname']}"
                        .toLowerCase();
                return fullName.contains(query);
              }).toList();

        if (filteredUsers.isEmpty) {
          return const Center(child: Text("No Users Found"));
        }

        return ListView(
          children: filteredUsers
              .map<Widget>((userData) => _buildUserListItem(userData, context))
              .toList(),
        );
      },
    );
  }

  Widget _buildUserListItem(
      Map<String, dynamic> userData, BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Ensure the current user is logged in and not comparing to null
    if (currentUser == null || userData['email'] == currentUser.email) {
      return Container(); // Do not display the current user's tile
    }

    // Print for debugging purposes
    print(
        "Building user tile for ${userData['firstname']} ${userData['lastname']}");

    return GestureDetector(
      onTap: () {
        // Log receiver details for debugging
        print("Navigating to ChatPage with receiverId: ${userData['uid']}");
        print("Receiver Email: ${userData['email']}");

        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ChatPage(
            receiverEmail: userData['email'] ?? '',
            receiverId: userData['uid'] ?? '',
            receiverName:
                "${userData["firstname"] ?? ''} ${userData["lastname"] ?? ''}",
          ),
        ));
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // User avatar with null checks
              CircleAvatar(
                backgroundImage: userData['profileImageUrl'] != null
                    ? NetworkImage(userData['profileImageUrl'])
                    : const AssetImage('assets/images/images.png')
                        as ImageProvider,
                radius: 30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${userData['firstname'] ?? 'Unknown'} ${userData['lastname'] ?? 'User'}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.message, color: Colors.teal),
                onPressed: () {
                  // Log the message sending action for debugging
                  print("Message icon pressed for ${userData['email']}");
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChatPage(
                      receiverEmail: userData['email'] ?? '',
                      receiverId: userData['uid'] ??
                          '', // Ensure this is being passed correctly
                      receiverName:
                          "${userData["firstname"] ?? ''} ${userData["lastname"] ?? ''}",
                    ),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
