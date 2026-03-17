import 'package:cityinsight_mobile/components/chat_bubble.dart';
import 'package:cityinsight_mobile/services/chat/chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverId;
  final String receiverName;

  const ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageC = TextEditingController();
  final ChatService _chatService = ChatService();
  FocusNode myFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 500), () => scrollDown());
      }
    });
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    messageC.dispose();
    super.dispose();
  }

  void scrollDown() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 1),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void sendMessage() async {
    if (messageC.text.isNotEmpty) {
      await _chatService.sendMessage(widget.receiverId, messageC.text);
      messageC.clear();
    }
    scrollDown();
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Colors for Dark Mode
    final appBarColor = isDarkMode ? Colors.black : Colors.blue;
    final appBarTextColor = isDarkMode ? Colors.white : Colors.white;
    final inputBorderColor =
        isDarkMode ? Colors.grey[700] : Colors.grey.shade300;
    final inputFocusBorderColor =
        isDarkMode ? Colors.blue[300] : Colors.blue[700];
    // final messageBubbleColor =
    //     isDarkMode ? Colors.blueGrey[900] : Colors.blue[50];
    // final currentUserBubbleColor =
    //     isDarkMode ? Colors.blue[800] : Colors.blue[300];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.receiverName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: appBarColor,
        foregroundColor: appBarTextColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(currentUserId),
          ),
          _buildUserInput(inputBorderColor, inputFocusBorderColor),
        ],
      ),
    );
  }

  Widget _buildMessageList(String currentUserId) {
    return StreamBuilder(
      stream: _chatService.getMessages(currentUserId, widget.receiverId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("Error loading messages");
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No messages yet"));
        }

        return ListView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children:
              snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isCurrentUser =
        data['senderId'] == FirebaseAuth.instance.currentUser!.uid;

    // Extract timestamp
    Timestamp timestamp = data['timestamp'];
    DateTime messageTime = timestamp.toDate();
    DateTime now = DateTime.now();

    // Determine how to format the timestamp
    String formattedTime;

    // Use timeago for relative time like "Just now", "2 days ago"
    if (now.difference(messageTime).inDays < 1) {
      formattedTime =
          timeago.format(messageTime); // e.g., "Just now", "5 minutes ago"
    } else if (now.difference(messageTime).inDays == 1) {
      formattedTime = "Yesterday";
    } else if (now.difference(messageTime).inDays < 7) {
      formattedTime = DateFormat('EEEE').format(messageTime); // e.g., "Monday"
    } else {
      formattedTime = DateFormat('MMM dd, yyyy')
          .format(messageTime); // e.g., "Oct 12, 2024"
    }

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            ChatBubble(
              message: data['message'],
              isCurrentUser: isCurrentUser,
              messageId: doc.id,
              userId: data['senderId'],
            ),
            // Display the formatted timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.grey.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInput(
      Color? inputBorderColor, Color? inputFocusBorderColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 8.0, right: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: messageC,
                focusNode: myFocusNode,
                decoration: InputDecoration(
                  hintText: "Type a message",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide:
                        BorderSide(color: inputBorderColor ?? Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide:
                        BorderSide(color: inputBorderColor ?? Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide:
                        BorderSide(color: inputFocusBorderColor ?? Colors.blue),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: sendMessage,
            icon: const FaIcon(FontAwesomeIcons.paperPlane,
                color: Color(0xFF3F7CB6)),
            tooltip: "Send Message",
          ),
        ],
      ),
    );
  }
}
