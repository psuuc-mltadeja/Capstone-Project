import 'package:cityinsight_mobile/components/user_tile.dart';
import 'package:cityinsight_mobile/services/chat/chat.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BlockedUserScreen extends StatelessWidget {
  BlockedUserScreen({super.key});

  final ChatService cs = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void showUnblockDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Unblock User"),
        content: const Text("Are you sure you want to unblock this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              cs.unblockUser(userId);
              Navigator.of(context).pop();

              // Delay showing the SnackBar until the dialog is closed
              Future.delayed(const Duration(milliseconds: 100), () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("User unblocked"),
                  ),
                );
              });
            },
            child: const Text("Unblock"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        title: const Text(
          "Blocked Users",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: cs.getBlockedUserStream(_auth.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error"),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final blockedUsers = snapshot.data ?? [];

          if (blockedUsers.isEmpty) {
            return const Center(
              child: Text("No Blocked Users"),
            );
          }

          return ListView.builder(
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              return UserTile(
                  text: "${user['firstname']} ${user['lastname']}",
                  onTap: () => showUnblockDialog(context, user['uid']));
            },
          );
        },
      ),
    );
  }
}
