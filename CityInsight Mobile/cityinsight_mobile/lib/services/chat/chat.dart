import 'package:cityinsight_mobile/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ChatService();

  // * GET ALL USERS
  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _firebaseFirestore.collection("users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return doc.data();
      }).toList();
    });
  }

  // * GET USERS WITHOUT BLOCKED USER
  Stream<List<Map<String, dynamic>>> getUsersWithoutBlocked() {
    final currentUser = _auth.currentUser;
    return _firebaseFirestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('blockedUsers')
        .snapshots()
        .asyncMap((snapshot) async {
      final blockedUserIds = snapshot.docs.map((doc) => doc.id).toList();
      final usersSnapshot = await _firebaseFirestore.collection('users').get();

      return usersSnapshot.docs
          .where((doc) =>
              doc.data()['email'] != currentUser.email &&
              !blockedUserIds.contains(doc.id))
          .map((doc) => doc.data())
          .toList();
    });
  }

  // * SEND MESSAGE
  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserId = _auth.currentUser!.uid;
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    print("Sending message to chatRoomId: $chatRoomId");

    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: _auth.currentUser!.email!,
      receiverId: receiverId,
      message: message,
      timestamp: Timestamp.now(),
      chatRoomId: chatRoomId, // Add this line
    );

    try {
      // Save to the correct chat room document using chatRoomId
      await _firebaseFirestore
          .collection("chat_rooms")
          .doc(
              chatRoomId) // This is the key part: using chatRoomId as the document ID
          .collection(
              "messages") // Store the message in the messages subcollection
          .add(newMessage
              .toMap()); // Assuming Message class has a toMap() method
      print("Message sent successfully");
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  // * GET MESSAGES
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    if (userId.isEmpty || otherUserId.isEmpty) {
      print("Error: userId or otherUserId is empty");
      return const Stream
          .empty(); // Return an empty stream to avoid null issues
    }

    // Sort IDs to generate a consistent chat room ID for both users
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    print("Fetching messages for chatRoomId: $chatRoomId");

    // Fetch messages ordered by timestamp
    return _firebaseFirestore
        .collection("chat_rooms")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy("timestamp",
            descending: false) // Fetch messages in reverse order if preferred
        .snapshots()
        .handleError((error) {
      print("Error fetching messages: $error");
    });
  }

  // * REPORT USER
  Future<void> reportUser(String messageId, String userId) async {
    final currentUser = _auth.currentUser;
    final report = {
      "reportedBy": currentUser!.uid,
      "messageId": messageId,
      "messageOwner": userId,
      "timestamp": FieldValue.serverTimestamp(),
    };
    await _firebaseFirestore.collection("reports").add(report);
  }

  // * BLOCK USER
  Future<void> blockUser(String userId) async {
    final currentUser = _auth.currentUser;
    await _firebaseFirestore
        .collection("users")
        .doc(currentUser!.uid)
        .collection('blockedUsers')
        .doc(userId)
        .set({});
    notifyListeners();
  }

  // * UNBLOCK USER
  Future<void> unblockUser(String blockedUserId) async {
    final currentUser = _auth.currentUser;
    await _firebaseFirestore
        .collection("users")
        .doc(currentUser!.uid)
        .collection('blockedUsers')
        .doc(blockedUserId)
        .delete();
  }

  // * DISPLAY BLOCKED USERS
  Stream<List<Map<String, dynamic>>> getBlockedUserStream(String userId) {
    return _firebaseFirestore
        .collection("users")
        .doc(userId)
        .collection("blockedUsers")
        .snapshots()
        .asyncMap((snapshot) async {
      final blockedUserIds = snapshot.docs.map((doc) => doc.id).toList();
      final userDocs = await Future.wait(
        blockedUserIds
            .map((id) => _firebaseFirestore.collection("users").doc(id).get()),
      );

      return userDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }
}
