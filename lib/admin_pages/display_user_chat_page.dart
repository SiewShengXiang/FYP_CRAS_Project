import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_chat_page.dart'; // Import your AdminChatPage

class DisplayUserChatPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DisplayUserChatPage({super.key});

  Stream<List<Map<String, String>>> getUsersWithChatStream() {
    return _firestore.collection('Chats').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final userId = doc['userId'] as String?;
        final userEmail = doc['userEmail'] as String?;
        return {'userId': userId ?? '', 'userEmail': userEmail ?? ''};
      }).toList();
    });
  }

  Stream<int> unreadMessagesCountStream(String userId) {
    return _firestore
        .collection('Chats')
        .doc(userId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Chat'),
      ),
      body: StreamBuilder<List<Map<String, String>>>(
        stream: getUsersWithChatStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userId = users[index]['userId'];
              final userEmail = users[index]['userEmail'];

              return StreamBuilder<int>(
                stream: unreadMessagesCountStream(userId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text(
                        '$userEmail ($userId)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const CircularProgressIndicator(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminChatPage(
                              userId: userId,
                            ),
                          ),
                        );
                      },
                    );
                  }

                  if (snapshot.hasError) {
                    return ListTile(
                      title: Text(
                        '$userEmail ($userId)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminChatPage(
                              userId: userId,
                            ),
                          ),
                        );
                      },
                      trailing: const Icon(Icons.error),
                    );
                  }

                  final unreadCount = snapshot.data ?? 0;
                  final hasUnread = unreadCount > 0;

                  return ListTile(
                    title: Text(
                      '$userEmail ($userId)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminChatPage(
                            userId: userId,
                          ),
                        ),
                      );
                    },
                    trailing: hasUnread
                        ? CircleAvatar(
                            backgroundColor: Colors.red,
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          )
                        : null,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
