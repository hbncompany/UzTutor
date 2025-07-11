import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth'ни импорт қилиш
import 'package:repetitor_resurs/l10n/app_localizations.dart';
import 'package:repetitor_resurs/providers/user_provider.dart';
import 'package:repetitor_resurs/widgets/app_drawer.dart';
import 'package:repetitor_resurs/screens/chat_list_screen.dart';
import 'package:repetitor_resurs/screens/requests_screen.dart';
import 'package:repetitor_resurs/screens/bookmarked_tutors_screen.dart'; // Янги экран
import 'package:repetitor_resurs/screens/bookmarked_teaching_centers_screen.dart'; // Янги экран
import 'dart:async';
import 'package:intl/intl.dart';

final value = new NumberFormat("#,##0", "en_US");

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  List<Map<String, dynamic>> _topTutors = [];
  List<Map<String, dynamic>> _topTeachingCenters = [];
  bool _isLoadingTutors = true;
  bool _isLoadingCenters = true;
  List<String> _bookmarkedTutorIds = [];
  List<String> _bookmarkedTeachingCenterIds = [];
  late StreamSubscription<DocumentSnapshot> _userProfileSubscription;

  // Намунавий фанлар рўйхати (API'дан олиниши ёки динамик бўлиши мумкин)
  final List<Map<String, dynamic>> _subjects = [
    {'name': 'Graphic de..', 'icon': Icons.brush},
    {'name': 'Biology', 'icon': Icons.eco},
    {'name': 'Mathhemti..', 'icon': Icons.calculate},
    {'name': 'English', 'icon': Icons.language},
    {'name': 'Physics', 'icon': Icons.science},
    {'name': 'Chemistry', 'icon': Icons.science_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _fetchTopTutors();
    _fetchTopTeachingCenters();
    _setupBookmarkListener();
  }

  @override
  void dispose() {
    _userProfileSubscription.cancel();
    super.dispose();
  }

  void _setupBookmarkListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _userProfileSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && mounted) {
          final userData = snapshot.data();
          setState(() {
            _bookmarkedTutorIds =
                List<String>.from(userData?['bookmarkedTutors'] ?? []);
            _bookmarkedTeachingCenterIds =
                List<String>.from(userData?['bookmarkedTeachingCenters'] ?? []);
          });
        }
      }, onError: (error) {
        print("Хатчўп маълумотларини юклашда хато: $error");
      });
    }
  }

  Future<void> _fetchTopTutors() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tutors')
          .orderBy('rating', descending: true) // Рейтинг бўйича саралаш
          .limit(5) // Фақат 5 та репетиторни олиш
          .get();

      if (!mounted) return;
      setState(() {
        _topTutors = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        _isLoadingTutors = false;
      });
    } catch (e) {
      print("Топ репетиторларни юклашда хато: $e");
      if (!mounted) return;
      setState(() {
        _isLoadingTutors = false;
      });
    }
  }

  Future<void> _fetchTopTeachingCenters() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('teachingCenters')
          // .orderBy('averageTutorRating', descending: true) // Агар шундай майдон мавжуд бўлса
          .limit(5) // Фақат 5 та марказни олиш
          .get();

      if (!mounted) return;
      setState(() {
        _topTeachingCenters = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        _isLoadingCenters = false;
      });
    } catch (e) {
      print("Топ ўқув марказларини юклашда хато: $e");
      if (!mounted) return;
      setState(() {
        _isLoadingCenters = false;
      });
    }
  }

  Future<void> _toggleBookmark(
      String itemId, String itemType, bool isBookmarked) async {
    final localizations = AppLocalizations.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(localizations
                .translate('loginRequiredBookmark'))), // Янги таржима
      );
      return;
    }

    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
    String fieldName =
        itemType == 'tutor' ? 'bookmarkedTutors' : 'bookmarkedTeachingCenters';

    try {
      if (isBookmarked) {
        // Хатчўпдан олиб ташлаш
        await userDocRef.update({
          fieldName: FieldValue.arrayRemove([itemId]),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  localizations.translate('bookmarkRemoved'))), // Янги таржима
        );
      } else {
        // Хатчўпга қўшиш
        await userDocRef.update({
          fieldName: FieldValue.arrayUnion([itemId]),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  localizations.translate('bookmarkAdded'))), // Янги таржима
        );
      }
    } catch (e) {
      print("Хатчўпни янгилашда хато: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(localizations.translate('bookmarkError',
                args: {'error': e.toString()}))), // Янги таржима
      );
    }
  }

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
        //title: Text(localizations.translate('appName')),
        foregroundColor: Theme.of(context).iconTheme.color,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.sort_rounded, size: 25),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
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
                    color: Colors.indigo,
                    icon: const Icon(Icons.messenger_outline_rounded),
                    onPressed: () {},
                  );
                }
                if (snapshot.hasError) {
                  print("Чатлар сонини юклашда хато: ${snapshot.error}");
                  return IconButton(
                    color: Colors.indigo,
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 0),
/*
              // Resource Subjects (Horizontal Scroll)
              Text(
                localizations.translate('resourceSubjects'), // Янги таржима
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 110, // Карталар баландлиги
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final subject = _subjects[index];
                    return _buildSubjectCard(
                      context,
                      title: subject['name'],
                      icon: subject['icon'],
                      onTap: () {
                        // Фан бўйича қидирувга ўтиш логикаси
                        Navigator.of(context).pushNamed('/tutor_list',
                            arguments: {'subject': subject['name']});
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),*/

              // Top Tutors (Horizontal Scroll)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations.translate('topTutors'), // Янги таржима
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_rounded), // Хатчўп иконкаси
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              const BookmarkedTutorsScreen()));
                    },
                    color: Theme.of(context).primaryColor,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/tutor_list');
                    },
                    child:
                        Text(localizations.translate('viewAll')), // "View all"
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _isLoadingTutors
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      height: 280, // Репетитор карталари баландлиги
                      child: _topTutors.isEmpty
                          ? Center(
                              child: Text(
                                  localizations.translate('noTutorsFound')))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _topTutors.length,
                              itemBuilder: (context, index) {
                                final tutor = _topTutors[index];
                                final isBookmarked =
                                    _bookmarkedTutorIds.contains(tutor['id']);
                                return _buildTutorCard(
                                  context,
                                  tutorData: tutor,
                                  isBookmarked: isBookmarked,
                                  onToggleBookmark: (bool currentlyBookmarked) {
                                    _toggleBookmark(tutor['id'], 'tutor',
                                        currentlyBookmarked);
                                  },
                                  onTap: () {
                                    print(
                                        tutor); // {createdAt: Timestamp(seconds=1751890601, nanoseconds=164000000), ...}
                                    print('tutorDoc');
                                    Navigator.of(context).pushNamed(
                                      '/tutor_profile',
                                      arguments: tutor[
                                          'id'], // Faqat tutorId (String) yuboriladi
                                    );
                                  },
                                );
                              },
                            ),
                    ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations
                        .translate('topTeachingCenters'), // Янги таржима
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_rounded), // Хатчўп иконкаси
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              const BookmarkedTeachingCentersScreen()));
                    },
                    color: Theme.of(context).primaryColor,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/teaching_center_list');
                    },
                    child:
                        Text(localizations.translate('viewAll')), // "View all"
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _isLoadingCenters
                  ? const Center(child: CircularProgressIndicator())
                  : _topTeachingCenters.isEmpty
                      ? Center(
                          child: Text(localizations
                              .translate('noTeachingCentersFound')))
                      : ListView.builder(
                          shrinkWrap: true,
                          // physics: const NeverScrollableScrollPhysics(), // Бу ерда олиб ташланди
                          itemCount: _topTeachingCenters.length,
                          itemBuilder: (context, index) {
                            final center = _topTeachingCenters[index];
                            final isBookmarked = _bookmarkedTeachingCenterIds
                                .contains(center['id']);
                            return _buildTeachingCenterCard(
                              context,
                              centerData: center,
                              isBookmarked: isBookmarked,
                              onToggleBookmark: (bool currentlyBookmarked) {
                                _toggleBookmark(center['id'], 'teaching_center',
                                    currentlyBookmarked);
                              },
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                    '/teaching_center_profile',
                                    arguments: center['id']);
                              },
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(15),
            /*boxShadow: [
              BoxShadow(
                color: Colors.greenAccent,
                offset: const Offset(
                  5.0,
                  5.0,
                ),
                blurRadius: 10.0,
                spreadRadius: 2.0,
              ), //BoxShadow
              BoxShadow(
                color: Colors.white,
                offset: const Offset(0.0, 0.0),
                blurRadius: 0.0,
                spreadRadius: 0.0,
              ), //BoxShadow
            ],*/
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 30, color: Theme.of(context).indicatorColor),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorCard(
    BuildContext context, {
    required Map<String, dynamic> tutorData,
    required bool isBookmarked,
    required Function(bool) onToggleBookmark,
    required VoidCallback onTap,
  }) {
    final localizations = AppLocalizations.of(context);
    final connectedCentersCount =
        (tutorData['connectedTeachingCenterIds'] as List?)?.length ?? 0;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                blurStyle: BlurStyle.outer,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? Colors.orange : Colors.grey,
                  ),
                  onPressed: () => onToggleBookmark(isBookmarked),
                ),
              ),
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(tutorData['imageUrl'] ??
                    'https://placehold.co/80x80/A78BFA/ffffff?text=T'),
                onBackgroundImageError: (exception, stackTrace) {
                  print('Error loading image: $exception');
                },
              ),
              const SizedBox(height: 10),
              Text(
                tutorData['name'] ?? 'Номаълум',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                tutorData['subject'] ?? 'Фан номаълум',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 18),
                  Text(
                    (tutorData['rating'] ?? 0.0).toStringAsFixed(1),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                localizations.translate('connectedCentersCount',
                    args: {'count': connectedCentersCount}),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${localizations.translate('priceLabel')} ${value.format(tutorData['price'])}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.green[700], fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeachingCenterCard(
    BuildContext context, {
    required Map<String, dynamic> centerData,
    required bool isBookmarked,
    required Function(bool) onToggleBookmark,
    required VoidCallback onTap,
  }) {
    final localizations = AppLocalizations.of(context);
    final connectedTutorsCount =
        (centerData['connectedTutorIds'] as List?)?.length ?? 0;
    final locationsCount = (centerData['locations'] as List?)?.length ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(centerData['imageUrl'] ??
                    'https://placehold.co/60x60/F87171/ffffff?text=TC'),
                onBackgroundImageError: (exception, stackTrace) {
                  print('Error loading image: $exception');
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      centerData['name'] ?? 'Номаълум марказ',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      localizations.translate('connectedTutorsCount',
                          args: {'count': connectedTutorsCount}),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      localizations.translate('locationsCount',
                          args: {'count': locationsCount}),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? Colors.orange : Colors.grey,
                ),
                onPressed: () => onToggleBookmark(isBookmarked),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
