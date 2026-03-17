import 'package:cityinsight_mobile/screens/comments.dart';
import 'package:cityinsight_mobile/screens/post_status.dart';
import 'package:cityinsight_mobile/screens/profile.dart';
import 'package:cityinsight_mobile/screens/verify_identity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';
import 'messages_screen.dart';

class CrowdSourcing extends StatefulWidget {
  const CrowdSourcing({super.key});

  @override
  _CrowdSourcingState createState() => _CrowdSourcingState();
}

class _CrowdSourcingState extends State<CrowdSourcing> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<String> _filteredWords = [];
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _fetchFilteredWords();
    _checkUserVerification();
  }

  // Fetch filtered words from Firestore
  Future<void> _fetchFilteredWords() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('filter_words').get();
      setState(() {
        _filteredWords =
            snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      print('Error fetching filtered words: $e');
    }
  }

  // Replace filtered words with asterisks
  String _sanitizeText(String text) {
    if (_filteredWords.isEmpty) return text;

    for (var word in _filteredWords) {
      // Replace all occurrences of the word, case insensitive
      final regex = RegExp(word, caseSensitive: false);
      text = text.replaceAll(regex, '*' * word.length);
    }
    return text;
  }

  // Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    return DateFormat.yMMMd().add_jm().format(timestamp);
  }

  // Fetch and filter data
  Stream<List<Map<String, dynamic>>> _fetchData() async* {
    await for (var snapshot in FirebaseFirestore.instance
        .collection('crowdsourcing')
        .orderBy('date', descending: true)
        .snapshots()) {
      final posts = await Future.wait(snapshot.docs.map((doc) async {
        var data = doc.data();
        data['id'] = doc.id;

        // Fetch username from user document using userId
        if (data['userId'] != null) {
          var userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(data['userId'])
              .get();
          if (userDoc.exists) {
            String firstName = userDoc['firstname'] ?? 'User';
            String lastName = userDoc['lastname'] ?? '';
            data['username'] = '@$firstName $lastName';
          } else {
            data['username'] = '@Unknown User';
          }
        }

        if (data['date'] is Timestamp) {
          data['date'] = (data['date'] as Timestamp).toDate();
        }

        data['isLiked'] =
            data['likes']?.contains(_auth.currentUser?.uid) ?? false;

        var commentsSnapshot = await FirebaseFirestore.instance
            .collection('crowdsourcing')
            .doc(data['id'])
            .collection('comments')
            .get();
        data['commentCount'] = commentsSnapshot.size;

        // Sanitize text fields
        if (data['title'] != null) {
          data['title'] = _sanitizeText(data['title']);
        }
        if (data['body'] != null) {
          data['body'] = _sanitizeText(data['body']);
        }

        return data;
      }).toList());
      yield posts;
    }
  }

  Future<void> _checkUserVerification() async {
    final userId = _auth.currentUser?.uid;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        setState(() {
          _isVerified = userDoc['isFullyVerified'] ?? false;
        });
      } else {
        setState(() {
          _isVerified = false;
        });
      }
    } catch (e) {
      print('Error fetching user verification status: $e');
    } finally {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final accentColor = isDarkMode ? Colors.blue[300] : Colors.blue;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Image.asset(
          'assets/images/logo.png',
          height: 60,
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.message,
              color: Colors.blue,
            ),
            onPressed: () {
              if (_isVerified) {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => MessagesScreen(
                      isDarkMode: isDarkMode,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      "You are not verified. Please verify your identity."),
                ));
              }
            },
          ),
        ],
      ),
      body: _isVerified
          ? StreamBuilder<List<Map<String, dynamic>>>(
              stream: _fetchData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final posts = snapshot.data ?? [];

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final item = posts[index];
                    final postId = item['id'];
                    final date = item['date'] as DateTime?;

                    String formattedTime =
                        date != null ? _formatTimestamp(date) : 'Unknown Time';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 10),
                      elevation: 4,
                      color: bgColor,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: item['profileImageUrl'] !=
                                          null
                                      ? NetworkImage(item['profileImageUrl'])
                                      : const AssetImage(
                                              'assets/images/images.png')
                                          as ImageProvider,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item['username'] ?? '@Unknown User',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item['title'] ?? 'No title',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item['body'] ?? 'No content',
                              style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white70 : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (item['imageUrl'] != null &&
                                item['imageUrl'].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Image.network(
                                  item['imageUrl'],
                                  fit: BoxFit.cover,
                                  height: 200,
                                  width: double.infinity,
                                ),
                              ),
                            const SizedBox(height: 10),
                            Text(
                              'Posted on $formattedTime',
                              style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white54
                                      : Colors.grey[600]),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                IconButton(
                                  onPressed: () => _toggleLike(
                                      postId, item['isLiked'] as bool),
                                  icon: Icon(
                                    item['isLiked'] as bool
                                        ? FontAwesomeIcons.solidHeart
                                        : FontAwesomeIcons.heart,
                                    color: item['isLiked'] as bool
                                        ? Colors.red
                                        : accentColor,
                                  ),
                                ),
                                Text(
                                  '${item['likes']?.length ?? 0} likes',
                                  style: TextStyle(color: textColor),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      CupertinoPageRoute(
                                        builder: (context) => CommentScreen(
                                          postId: postId,
                                          post: item,
                                          isDarkMode: isDarkMode,
                                          username: item['username'],
                                        ),
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    FontAwesomeIcons.comment,
                                    color: accentColor,
                                  ),
                                ),
                                Text(
                                  '${item['commentCount']} comments',
                                  style: TextStyle(color: textColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "You are not verified. Please verify your identity.",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const VerifyIdentityScreen(),
                        ));
                      },
                      child: const Text("Verify"))
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentColor,
        onPressed: () {
          Navigator.of(context).push(PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return const PostStatusScreen();
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              return SlideTransition(position: offsetAnimation, child: child);
            },
          ));
        },
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _toggleLike(String postId, bool isLiked) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final postRef =
          FirebaseFirestore.instance.collection('crowdsourcing').doc(postId);
      if (isLiked) {
        await postRef.update({
          'likes': FieldValue.arrayRemove([userId])
        });
      } else {
        await postRef.update({
          'likes': FieldValue.arrayUnion([userId])
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }
}
