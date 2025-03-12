import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _messageController = TextEditingController();
  late CollectionReference<Map<String, dynamic>> _userChatCollection;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _shouldSendAIResponse = true; // Flag to control AI responses

  @override
  void initState() {
    super.initState();
    _initializeUserChatCollection();
    _sendGreetingMessage();
  }

  Future<void> _initializeUserChatCollection() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _userChatCollection = _firestore
          .collection('Chats')
          .doc(currentUser.uid)
          .collection('messages');

      await _firestore.collection('Chats').doc(currentUser.uid).set({
        'userId': currentUser.uid,
        'userEmail': currentUser.email,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _sendGreetingMessage() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final canSendMessage = await _canSendMessage(currentUser.uid);
      if (canSendMessage) {
        await _sendMessage("Hello! How can I assist you today?", "AI");

        final canSendOptions = await _canSendOptionsMessage(currentUser.uid);
        if (canSendOptions) {
          await _sendMessage("[OPTIONS]", "AI");
          await _updateLastOptionsSentDate(currentUser.uid);
        }

        await _updateLastMessageSentDate(currentUser.uid);
      } else {
        print("AI has already sent a message today.");
      }
    }
  }

  Future<bool> _canSendMessage(String userId) async {
    final userDoc = await _firestore.collection('Users').doc(userId).get();
    if (!userDoc.exists) return true;

    final lastMessageSentDate = userDoc['lastMessageSentDate'] as Timestamp?;
    final currentDate = DateTime.now();

    if (lastMessageSentDate == null) return true;

    final lastSentDate = lastMessageSentDate.toDate();
    return currentDate.difference(lastSentDate).inDays >= 1;
  }

  Future<bool> _canSendOptionsMessage(String userId) async {
    final userDoc = await _firestore.collection('Users').doc(userId).get();
    if (!userDoc.exists) return true;

    final lastOptionsSentDate = userDoc['lastOptionsSentDate'] as Timestamp?;
    final currentDate = DateTime.now();

    if (lastOptionsSentDate == null) return true;

    final lastSentDate = lastOptionsSentDate.toDate();
    return currentDate.difference(lastSentDate).inDays >= 1;
  }

  Future<void> _updateLastMessageSentDate(String userId) async {
    await _firestore.collection('Users').doc(userId).update({
      'lastMessageSentDate': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateLastOptionsSentDate(String userId) async {
    await _firestore.collection('Users').doc(userId).update({
      'lastOptionsSentDate': FieldValue.serverTimestamp(),
    });
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
        'read': false, // Default value for unread message
      });

      _messageController.clear();

      // Only send AI response if sender is not 'AI' and AI responses are enabled
      if (sender != 'AI' && _shouldSendAIResponse) {
        await _sendAIResponse(text);
      }
    }
  }

  Future<void> _sendAIResponse(String userMessage) async {
    if (!_shouldSendAIResponse) {
      return; // Exit function without sending any response
    }

    if (userMessage.toLowerCase().contains('chat with admin')) {
      _shouldSendAIResponse = false; // Stop AI responses
      return;
    }

    String response;
    if (userMessage.toLowerCase().contains('how do i rent a car?')) {
      response =
          'Choose any car on the Home page and continue the step, that how you rent a car.';
    } else if (userMessage.toLowerCase().contains('how to refund?')) {
      response =
          'Go to Rental and press cancel booking, the history will show in Refund.';
    } else if (userMessage
        .toLowerCase()
        .contains('what are the terms and conditions?')) {
      response =
          'You need to have license accordingly what you have rented car. ';
    } else {
      response = 'I am not sure about that. Let me connect you to an admin.';
    }

    if (_shouldSendAIResponse) {
      await _sendMessage(response, 'AI');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with AI'),
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _auth.currentUser != null
                  ? _userChatCollection
                      .orderBy('timestamp', descending: true)
                      .snapshots()
                  : const Stream.empty(),
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

                  if (messageText == "[OPTIONS]") {
                    return _buildOptions();
                  }

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
                    final sender = _auth.currentUser?.email ?? 'User';
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

  Widget _buildOptions() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "AI",
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  final currentUser = _auth.currentUser;
                  if (currentUser != null) {
                    QuerySnapshot optionsSnapshot = await _firestore
                        .collection('Chats')
                        .doc(currentUser.uid)
                        .collection('messages')
                        .where('text', isEqualTo: '[OPTIONS]')
                        .limit(1)
                        .get();

                    if (optionsSnapshot.docs.isNotEmpty) {
                      String optionsId = optionsSnapshot.docs.first.id;
                      await _firestore
                          .collection('Chats')
                          .doc(currentUser.uid)
                          .collection('messages')
                          .doc(optionsId)
                          .delete();
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          const Text(
            "How can I assist you? Choose an option below:",
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 10.0),
          Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  _sendMessage('How do I rent a car?',
                      _auth.currentUser?.email ?? 'User');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: Text('How to Rent'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  _sendMessage(
                      'How to refund?', _auth.currentUser?.email ?? 'User');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: Text('Refund'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  _sendMessage('What are the terms and conditions?',
                      _auth.currentUser?.email ?? 'User');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: Text('Terms & Conditions'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  _sendMessage(
                      'Chat with Admin', _auth.currentUser?.email ?? 'User');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: Text('Chat with Admin'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
