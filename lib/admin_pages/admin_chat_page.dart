import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminChatPage extends StatefulWidget {
  final String userId; // Define userId as a parameter

  const AdminChatPage({super.key, required this.userId});

  @override
  _AdminChatPageState createState() => _AdminChatPageState();
}

class _AdminChatPageState extends State<AdminChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  late CollectionReference<Map<String, dynamic>> _userChatCollection;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _initializeUserChatCollection();
    _markMessagesAsRead(); // Mark messages as read when page initializes
  }

  Future<void> _initializeUserChatCollection() async {
    _userChatCollection = _firestore
        .collection('Chats')
        .doc(widget.userId)
        .collection('messages');
  }

  Future<void> _sendMessage(String text, String sender) async {
    if (text.isEmpty) {
      return;
    }

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _userChatCollection.add({
        'text': text,
        'sender': sender,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false, // Ensure new messages start as unread
      });

      _messageController.clear();
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> unreadMessagesQuery =
          await _userChatCollection.where('read', isEqualTo: false).get();

      final List<DocumentSnapshot<Map<String, dynamic>>> unreadMessages =
          unreadMessagesQuery.docs;

      final List<Future<void>> updateFutures = [];
      for (var messageDoc in unreadMessages) {
        updateFutures.add(messageDoc.reference.update({'read': true}));
      }

      await Future.wait(updateFutures);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('Users').doc(widget.userId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final userData = snapshot.data?.data() as Map<String, dynamic>?;

            return Text(userData?['sender'] ?? 'Admin Chat');
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _userChatCollection
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages = snapshot.data!.docs;

                List<Widget> messageWidgets = messages.map((message) {
                  final data = message.data() as Map<String, dynamic>;
                  final messageText = data['text'];
                  final messageSender = data['sender'];
                  final currentUser = _auth.currentUser?.email;

                  return Align(
                    alignment: currentUser == messageSender
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 5.0, horizontal: 10.0),
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: currentUser == messageSender
                            ? Colors.blue[200]
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            messageSender,
                            style: TextStyle(
                              fontWeight: currentUser == messageSender
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 5.0),
                          Text(messageText),
                        ],
                      ),
                    ),
                  );
                }).toList();

                return ListView(
                  reverse: true,
                  children: messageWidgets,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final text = _messageController.text;
                    final sender = _auth.currentUser?.email ?? 'Admin';
                    await _sendMessage(text, sender);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
