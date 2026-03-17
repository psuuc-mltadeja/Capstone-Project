import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> post;
  final String username;
  final bool isDarkMode;

  const CommentScreen({
    Key? key,
    required this.postId,
    required this.post,
    required this.username,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  String currentUsername = '';
  String postUsername = '';
  String currentUserProfileImage = '';

  Future<void> _fetchCurrentUserUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        String firstname = doc['firstname'] ?? 'Unknown';
        String lastname = doc['lastname'] ?? 'User';
        currentUserProfileImage =
            doc['profileImageUrl'] ?? 'assets/images/images.png';
        setState(() {
          currentUsername = '$firstname $lastname';
        });
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
  }

  void _initializePostUsername() {
    setState(() {
      postUsername = widget.post['username'] ?? 'Unknown';
    });
  }

  Future<void> _addComment(String text, [String? parentId]) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String username =
        currentUsername.isEmpty ? widget.username : currentUsername;

    try {
      await FirebaseFirestore.instance
          .collection('crowdsourcing')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'userId': user.uid,
        'username': username,
        'comment': text,
        'profileImageUrl': currentUserProfileImage,
        'date': FieldValue.serverTimestamp(),
        'parentId': parentId,
      });
    } catch (e) {
      print("Error adding comment: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> _fetchComments() {
    return FirebaseFirestore.instance
        .collection('crowdsourcing')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('MMMM d, yyyy ' 'h:mm a').format(date);
  }

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserUsername();
    _initializePostUsername();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final post = widget.post;
    Timestamp postTimestamp = post['postDate'] ?? Timestamp.now();
    String postTimestampFormatted = _formatTimestamp(postTimestamp);

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: isDarkMode ? Colors.black : Colors.blue,
        title: const Text(
          "Post Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // iconTheme: IconThemeData(color: textColor),
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                // Post Card
                Card(
                  elevation: 1,
                  color: isDarkMode ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: post['profileImageUrl']
                                          ?.isNotEmpty ==
                                      true
                                  ? NetworkImage(post['profileImageUrl'])
                                  : const AssetImage('assets/images/images.png')
                                      as ImageProvider,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              postUsername,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post['title'] ?? 'No title',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          post['body'] ?? 'No content',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        if (post['imageUrl'] != null) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              post['imageUrl'],
                              fit: BoxFit.cover,
                              height: 200,
                              width: double.infinity,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          'Posted on $postTimestampFormatted',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white54 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Comments Section
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _fetchComments(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No comments yet.',
                          style: TextStyle(color: textColor, fontSize: 16),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        var comment = snapshot.data![index];
                        Timestamp timestamp =
                            comment['date'] ?? Timestamp.now();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 15),
                            leading: Container(
                              decoration: BoxDecoration(
                                border: Border.all(),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: CircleAvatar(
                                backgroundImage: comment['profileImageUrl']
                                            ?.isNotEmpty ==
                                        true
                                    ? NetworkImage(comment['profileImageUrl'])
                                    : const AssetImage(
                                            'assets/images/images.png')
                                        as ImageProvider,
                              ),
                            ),
                            title: Text(
                              comment['username'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(comment['comment']),
                                const SizedBox(height: 5),
                                Text(
                                  _formatTimestamp(timestamp),
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white54
                                        : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => Divider(
                        color: isDarkMode ? Colors.grey : Colors.grey,
                        thickness: 0.5,
                        indent: 15,
                        endIndent: 15,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Comment Input Field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                hintText: 'Write a comment...',
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send,
                      color: isDarkMode ? Colors.white : Colors.blue),
                  onPressed: () {
                    String text = _commentController.text.trim();
                    if (text.isNotEmpty) {
                      _addComment(text);
                      _commentController.clear();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
