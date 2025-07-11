import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:repetitor_resurs/l10n/app_localizations.dart';
import 'package:repetitor_resurs/providers/user_provider.dart';
import 'package:repetitor_resurs/widgets/app_drawer.dart';
import 'package:repetitor_resurs/screens/chat_list_screen.dart';
import 'package:repetitor_resurs/screens/requests_screen.dart'; // RequestsScreen'ни импорт қилиш

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final userName = userProvider.userProfile?.name ??
        userProvider.firebaseUser?.email ??
        'Меҳмон';
    final currentUserId = userProvider.firebaseUser?.uid;
    final bool isTutor = userProvider.userProfile?.userType == 'tutor';
    final bool isTeachingCenter =
        userProvider.userProfile?.userType == 'teaching_center';

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('appName')),
        centerTitle: true,
        actions: [
          // Фақат репетиторлар ва ўқув марказлари учун хабарлар иконкасини кўрсатиш
          if (currentUserId != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return IconButton(
                    icon: const Icon(Icons.message),
                    onPressed: () {},
                  );
                }
                if (snapshot.hasError) {
                  print("Чатлар сонини юклашда хато: ${snapshot.error}");
                  return IconButton(
                    icon: const Icon(Icons.message),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const ChatListScreen()));
                    },
                  );
                }

                int unreadChatCount = 0;
                for (var doc in snapshot.data!.docs) {
                  final chatData = doc.data() as Map<String, dynamic>;
                  final List<dynamic> messages = chatData['messages'] ?? [];
                  unreadChatCount += messages
                      .where((msg) =>
                          msg['senderId'] != currentUserId &&
                          !(msg['isRead'] ?? false))
                      .length;
                }

                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.message),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const ChatListScreen()));
                      },
                    ),
                    if (unreadChatCount > 0)
                      Positioned(
                        right: 5,
                        top: 5,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            unreadChatCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          // Фақат репетиторлар ва ўқув марказлари учун сўровлар иконкасини кўрсатиш
          if ((isTutor || isTeachingCenter) && currentUserId != null)
            StreamBuilder<QuerySnapshot>(
              stream: isTutor
                  ? FirebaseFirestore.instance
                      .collection('requests')
                      .where('tutorId', isEqualTo: currentUserId)
                      .where('status', isEqualTo: 'pending')
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('requests')
                      .where('teachingCenterId', isEqualTo: currentUserId)
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return IconButton(
                    icon: const Icon(Icons.mail),
                    onPressed: () {},
                  );
                }
                if (snapshot.hasError) {
                  print("Сўровлар сонини юклашда хато: ${snapshot.error}");
                  return IconButton(
                    icon: const Icon(Icons.mail),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const RequestsScreen()));
                    },
                  );
                }

                int unreadRequestCount = snapshot.data!.docs.length;

                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.mail),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const RequestsScreen()));
                      },
                    ),
                    if (unreadRequestCount > 0)
                      Positioned(
                        right: 5,
                        top: 5,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue, // Сўровлар учун бошқа ранг
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            unreadRequestCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /*
            Text(
              localizations
                  .translate('helloUser', args: {'userName': userName}),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),*/
            Expanded(
              child: GridView.count(
                crossAxisCount: 1, // Мобил учун 1 устун
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 1.8, // Карталарнинг нисбати
                children: [
                  // Ўқув марказлари картаси
                  _buildFeatureCard(
                    context,
                    title: localizations.translate('findTeachingCenters'),
                    icon: Icons.school,
                    imageAsset:
                        'https://placehold.co/600x300/F87171/ffffff?text=Teaching+Centers', // Ўқув марказлари расми
                    onTap: () {
                      Navigator.of(context).pushNamed('/teaching_center_list');
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    title: localizations.translate('findTutor'),
                    icon: Icons.person_search,
                    imageAsset:
                        'https://placehold.co/600x300/A78BFA/ffffff?text=Tutor+Search', // Репетитор қидириш расми
                    onTap: () {
                      Navigator.of(context).pushNamed('/tutor_list');
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    title: localizations.translate('findResources'),
                    icon: Icons.library_books,
                    imageAsset:
                        'https://placehold.co/600x300/818CF8/ffffff?text=Educational+Resources', // Ресурс топиш расми
                    onTap: () {
                      Navigator.of(context).pushNamed('/resources');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String imageAsset,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.8),
                Theme.of(context).colorScheme.secondary.withOpacity(0.8)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
