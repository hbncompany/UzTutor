import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:repetitor_resurs/l10n/app_localizations.dart';
import 'package:repetitor_resurs/providers/user_provider.dart';
import 'package:repetitor_resurs/screens/chat_screen.dart';
import 'package:repetitor_resurs/models/tutor.dart'; // Tutor modelini import qilish

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Фойдаланувчининг исмини олиш учун асинхрон функция
  Future<String> _getUserName(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.get('name') ??
            userDoc.get('email') ??
            'Номаълум фойдаланувчи';
      }
      return 'Номаълум фойдаланувчи';
    } catch (e) {
      print("Фойдаланувчи исмини юклашда хато: $e");
      return 'Хато: ${userId.substring(0, 8)}...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final currentUserId = userProvider.firebaseUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.indigo,
          title: Text(localizations.translate('chatListTitle')),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
              localizations.translate('loginRequiredReview')), // Умумий хабар
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.indigo,
        title: Text(localizations.translate('chatListTitle')),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Жорий фойдаланувчи иштирокчи бўлган барча чатларни олиш
        stream: _firestore
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .orderBy('lastMessageAt',
                descending: true) // Энг янги чатларни юқорига олиб чиқиш
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print(snapshot.error);
            return Center(
                child: Text(localizations.translate('errorLoadingChat')));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(localizations.translate('noChatsFound')));
          }

          final chatDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatData = chatDocs[index].data() as Map<String, dynamic>;
              final List<String> participants =
                  List<String>.from(chatData['participants']);
              // Жорий фойдаланувчидан бошқа иштирокчининг IDсини топиш
              final String otherUserId =
                  participants.firstWhere((id) => id != currentUserId);

              // Охирги хабарни олиш ва ўқилмаган хабарларни ҳисоблаш
              final List<dynamic> messagesData = chatData['messages'] ?? [];
              final lastMessage =
                  messagesData.isNotEmpty ? messagesData.last : null;

              int unreadCount = 0;
              if (lastMessage != null &&
                  lastMessage['senderId'] == otherUserId &&
                  !(lastMessage['isRead'] ?? false)) {
                // Агар охирги хабар бошқа фойдаланувчидан бўлса ва ўқилмаган бўлса
                // Бу ерда барча ўқилмаган хабарларни санаш мумкин
                unreadCount = messagesData
                    .where((msg) =>
                        msg['senderId'] == otherUserId &&
                        !(msg['isRead'] ?? false))
                    .length;
              }

              return FutureBuilder<String>(
                future: _getUserName(otherUserId),
                builder: (context, nameSnapshot) {
                  String chatPartnerName = nameSnapshot.data ?? 'Юкланмоқда...';
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.2),
                        child: Text(chatPartnerName[0].toUpperCase(),
                            style: TextStyle(
                                fontSize: 24,
                                color: Theme.of(context).primaryColor)),
                      ),
                      title: Text(
                        chatPartnerName,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: lastMessage != null
                          ? Text(
                              lastMessage['text'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontStyle: unreadCount > 0
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                fontWeight: unreadCount > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: unreadCount > 0
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[600],
                              ),
                            )
                          : Text(localizations.translate('noMessages')),
                      trailing: unreadCount > 0
                          ? Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          : null,
                      onTap: () async {
                        // Чатни очиш ва репетитор маълумотини ўтказиш
                        // Бу ерда otherUserId нинг репетитор эканлигини тасдиқлаш керак
                        // ёки чатга кириш учун фақат ID етарли бўлиши керак.
                        // Ҳозирча, соддалик учун, otherUserId ни репетитор ID си деб фараз қиламиз
                        // ва унинг маълумотларини оламиз.
                        DocumentSnapshot otherUserDoc = await _firestore
                            .collection('users')
                            .doc(otherUserId)
                            .get();
                        //if (otherUserDoc.get('userType') == 'tutor')
                        {
                          // Агар бошқа фойдаланувчи репетитор бўлса, унинг маълумотларини ўтказамиз
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(tutorData: {
                                'id': otherUserDoc.id,
                                'name':
                                    otherUserDoc.get('name') ?? chatPartnerName,
                                'subject':
                                    'Чат', // Чат учун фанни аниқлаштириш керак
                                'rating': 0.0,
                                'price': 0.0,
                                'description': '',
                                'imageUrl': otherUserDoc.get('imageUrl'),
                              }),
                            ),
                          );
                        } /*else {
                          // Агар бошқа фойдаланувчи репетитор бўлмаса, унинг профили йўқ.
                          // Бу ҳолатда фақат чат ID орқали чат экранига ўтиш керак.
                          // ChatScreen'ни чат ID ва currentUserId билан ишлашга мослаштириш керак.
                          // Ҳозирча, соддалик учун, фақат репетиторлар билан чат очишга рухсат берамиз.
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Фақат репетиторлар билан чат очиш мумкин.')),
                          );
                        }*/
                      },
                    ),
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
