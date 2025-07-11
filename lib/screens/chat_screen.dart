import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:repetitor_resurs/l10n/app_localizations.dart';
import 'package:repetitor_resurs/models/chat_message.dart';
import 'package:repetitor_resurs/models/tutor.dart';
import 'package:repetitor_resurs/providers/user_provider.dart';
import 'package:repetitor_resurs/screens/other_user_profile_screen.dart'; // Янги экранни импорт қилиш

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> tutorData; // Номини ўзгартирдик

  const ChatScreen({super.key, required this.tutorData});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _errorMessage;

  // Чат ID ни аниқлаш (фойдаланувчи ва репетитор ID лари асосида)
  String _getChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  @override
  void initState() {
    super.initState();
    // Чат очилганда ўқилмаган хабарларни ўқилган деб белгилаш
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  Future<void> _markMessagesAsRead() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.firebaseUser?.uid;
    if (currentUserId == null) return;

    final chatId = _getChatId(currentUserId, widget.tutorData['id']);
    final chatDocRef = _firestore.collection('chats').doc(chatId);

    try {
      final chatDoc = await chatDocRef.get();
      if (chatDoc.exists) {
        final chatData = chatDoc.data() as Map<String, dynamic>;
        List<dynamic> messages = List.from(chatData['messages'] ?? []);

        bool changed = false;
        for (int i = 0; i < messages.length; i++) {
          // Жорий фойдаланувчига юборилган ва ўқилмаган хабарларни белгилаш
          if (messages[i]['senderId'] != currentUserId &&
              !(messages[i]['isRead'] ?? false)) {
            messages[i]['isRead'] = true;
            changed = true;
          }
        }

        if (changed) {
          await chatDocRef.update({'messages': messages});
        }
      }
    } catch (e) {
      print("Хабарларни ўқилган деб белгилашда хато: $e");
    }
  }

  Future<void> _sendMessage(
      BuildContext context, String currentUserId, String tutorId) async {
    final localizations = AppLocalizations.of(context);
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _errorMessage = null;
    });

    final chatId = _getChatId(currentUserId, tutorId);
    final chatDocRef = _firestore.collection('chats').doc(chatId);

    try {
      final newMessage = ChatMessage(
        senderId: currentUserId,
        text: _messageController.text.trim(),
        timestamp: Timestamp.now(),
        isRead: false, // Янги юборилган хабар ўқилмаган
      );

      await chatDocRef.set(
        {
          'participants': [currentUserId, tutorId],
          'messages': FieldValue.arrayUnion([newMessage.toMap()]),
          'lastMessageAt': Timestamp.now(),
        },
        SetOptions(merge: true), // Агар чат мавжуд бўлса, уни янгилайди
      );
      _messageController.clear();
    } catch (e) {
      setState(() {
        _errorMessage = localizations
            .translate('errorSendingMessage', args: {'error': e.toString()});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final currentUserId = userProvider.firebaseUser?.uid;
    // Tutor маълмотини widget.tutorData'дан оламиз
    final Tutor tutor = Tutor.fromMap(widget.tutorData);

    if (currentUserId == null) {
      return Center(
          child: Text(localizations.translate('loginRequiredReview')));
    }

    final chatId = _getChatId(currentUserId, tutor.id);

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.indigo,
        title: GestureDetector(
          // AppBar title'ни босиш мумкин қилдик
          onTap: () {
            // Бошқа фойдаланувчининг профилига ўтиш
            Navigator.of(context).pushNamed(
              '/other_user_profile',
              arguments: tutor.id, // Репетиторнинг ID'сини ўтказамиз
            );
          },
          child: Text(localizations
              .translate('chatWith', args: {'tutorName': tutor.name})),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('chats').doc(chatId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text(localizations.translate('errorLoadingChat')));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(
                      child: Text(localizations.translate('noMessages')));
                }

                final chatData = snapshot.data!.data() as Map<String, dynamic>;
                final messagesData = (chatData['messages'] as List<dynamic>?)
                        ?.map((msg) =>
                            ChatMessage.fromMap(msg as Map<String, dynamic>))
                        .toList() ??
                    [];

                // Хабарларни вақт бўйича саралаш
                messagesData.sort((a, b) => a.timestamp.compareTo(b.timestamp));

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  reverse: false, // Энг янги хабар пастда бўлиши учун
                  itemCount: messagesData.length,
                  itemBuilder: (context, index) {
                    final message = messagesData[index];
                    final isMe = message.senderId == currentUserId;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe
                                ? const Radius.circular(12)
                                : const Radius.circular(0),
                            bottomRight: isMe
                                ? const Radius.circular(0)
                                : const Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${message.timestamp.toDate().hour}:${message.timestamp.toDate().minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.black54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
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
                      hintText: localizations.translate('messageHint'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: () =>
                      _sendMessage(context, currentUserId, tutor.id),
                  mini: true,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
