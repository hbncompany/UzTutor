import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:repetitor_resurs/l10n/app_localizations.dart';
import 'package:repetitor_resurs/models/tutor.dart';
import 'package:repetitor_resurs/models/user_profile.dart'; // UserProfile'ни импорт қилиш
import 'package:repetitor_resurs/models/review.dart'; // Review'ни импорт қилиш
import 'package:repetitor_resurs/providers/user_provider.dart';
import 'package:url_launcher/url_launcher.dart'; // url_launcher'ни импорт қилиш
import 'dart:async';
import 'package:intl/intl.dart';

final value = new NumberFormat("#,##0", "en_US");

class TutorProfileScreen extends StatefulWidget {
  final String? tutorId; // Репетитор ID'сини қабул қилади

  const TutorProfileScreen({super.key, required this.tutorId});

  @override
  State<TutorProfileScreen> createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends State<TutorProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _reviewController = TextEditingController();
  int _reviewRating = 5; // Default rating
  String? _message;
  bool _isMessageError = false; // Хато хабарими ёки муваффақият хабарими

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _addReview(BuildContext context, Tutor currentTutor) async {
    final localizations = AppLocalizations.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Фақат клиентлар шарҳ қолдириши мумкин
    if (userProvider.userProfile?.userType != 'client') {
      setState(() {
        _message = localizations
            .translate('loginRequiredReview'); // Хабарни умумий қилиб ишлатамиз
        _isMessageError = true;
      });
      return;
    }

    if (_reviewController.text.isEmpty) {
      setState(() {
        _message = localizations.translate('reviewEmptyError');
        _isMessageError = true;
      });
      return;
    }

    setState(() {
      _message = null;
      _isMessageError = false;
    });

    try {
      final newReview = Review(
        userId: userProvider.firebaseUser!.uid,
        text: _reviewController.text,
        rating: _reviewRating,
        timestamp: Timestamp.now(),
      );

      // Репетитор ҳужжатини янгилаш
      final tutorRef =
          FirebaseFirestore.instance.collection('tutors').doc(currentTutor.id);
      final tutorDoc = await tutorRef.get();

      if (tutorDoc.exists) {
        List<dynamic> currentReviewsData = tutorDoc.data()?['reviews'] ?? [];
        List<Review> currentReviews = currentReviewsData
            .map((e) => Review.fromMap(e as Map<String, dynamic>))
            .toList();
        currentReviews.add(newReview);

        // Янги ўртача рейтингни ҳисоблаш
        double totalRating = 0;
        for (var r in currentReviews) {
          totalRating += r.rating;
        }
        double newAverageRating =
            currentReviews.isEmpty ? 0.0 : totalRating / currentReviews.length;

        await tutorRef.update({
          'reviews': currentReviews.map((r) => r.toMap()).toList(),
          'rating': newAverageRating,
        });

        setState(() {
          _reviewController.clear();
          _reviewRating = 5;
          _message = localizations.translate('reviewSuccess');
          _isMessageError = false;
        });
      } else {
        setState(() {
          _message = localizations.translate('tutorNotFound');
          _isMessageError = true;
        });
      }
    } catch (e) {
      setState(() {
        _message = localizations
            .translate('reviewError', args: {'error': e.toString()});
        _isMessageError = true;
      });
    }
  }

  // Телефон рақамига қўнғироқ қилиш функцияси
  Future<void> _launchPhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қўнғироқ қилиб бўлмади: $phoneNumber')),
      );
    }
  }

  // Connected Teaching Centers сонини олиш
  int _getTeachingCentersCount(List<String>? connectedTeachingCenterIds) {
    return connectedTeachingCenterIds?.length ?? 0;
  }

  // Хатчўп функцияси
  Future<void> _toggleBookmark(Tutor tutor) async {
    final localizations = AppLocalizations.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(localizations
                .translate('loginRequiredBookmark'))), // Янги таржима
      );
      return;
    }

    try {
      await userProvider.toggleTutorBookmark(tutor.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userProvider.isTutorBookmarked(tutor.id)
                ? localizations.translate('tutorBookmarked') // Янги таржима
                : localizations
                    .translate('tutorRemovedBookmark'), // Янги таржима
          ),
        ),
      );
    } catch (e) {
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
    final String? currentUserId = userProvider.firebaseUser?.uid;

    // Фойдаланувчи турини аниқлаш
    final bool isClient = userProvider.userProfile?.userType == 'client';

    if (widget.tutorId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localizations.translate('tutorProfileTitle')),
          centerTitle: true,
        ),
        body: Center(
          child: Text(localizations.translate('tutorNotFound')),
        ),
      );
    }

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('tutors').doc(widget.tutorId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: AppBar(
                title: Text(localizations.translate('tutorProfileTitle')),
                centerTitle: true,
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(
                title: Text(localizations.translate('tutorProfileTitle')),
                centerTitle: true,
              ),
              body: Center(
                child: Text(localizations.translate('errorLoadingTutorProfile',
                    args: {'error': snapshot.error.toString()})),
              ),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Scaffold(
              appBar: AppBar(
                title: Text(localizations.translate('tutorProfileTitle')),
                centerTitle: true,
              ),
              body: Center(
                child: Text(localizations.translate('tutorNotFound')),
              ),
            );
          }

          final currentTutor = Tutor.fromFirestore(snapshot.data!);
          final bool isMyOwnProfile = currentUserId == currentTutor.id;
          final bool isBookmarked =
              userProvider.isTutorBookmarked(currentTutor.id);

          return FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('users').doc(currentTutor.id).get(),
            builder: (context, userSnapshot) {
              UserProfile? tutorUserProfile;
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                tutorUserProfile =
                    UserProfile.fromFirestore(userSnapshot.data!);
              }

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 250.0,
                    floating: false,
                    pinned: true,
                    backgroundColor:
                        Colors.transparent, // Background color for app bar
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            currentTutor.imageUrl ??
                                'https://placehold.co/600x400/A78BFA/ffffff?text=Tutor+Image',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.network(
                              'https://placehold.co/600x400/A78BFA/ffffff?text=Tutor+Image',
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.5),
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.5),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    leading: Container(
                      margin: const EdgeInsets.only(left: 16, top: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.only(right: 16, top: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: isBookmarked ? Colors.amber : Colors.white,
                          ),
                          onPressed: () => _toggleBookmark(currentTutor),
                        ),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(30)),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  currentTutor.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Row(
                                children: [
                                  _buildContactIcon(Icons.call, Colors.green,
                                      () {
                                    if (tutorUserProfile?.phoneNumber != null &&
                                        tutorUserProfile!
                                            .phoneNumber!.isNotEmpty) {
                                      _launchPhoneCall(
                                          tutorUserProfile.phoneNumber!);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                localizations.translate(
                                                    'phoneNumberNotAvailable'))),
                                      );
                                    }
                                  }),
                                  _buildContactIcon(Icons.chat, Colors.blue,
                                      () {
                                    Navigator.of(context).pushNamed(
                                      '/chat',
                                      arguments: currentTutor.toFirestore(),
                                    );
                                  }),
                                  _buildContactIcon(Icons.videocam, Colors.red,
                                      () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Видео қўнғироқ функцияси')),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 24),
                              Text(
                                currentTutor.rating.toStringAsFixed(1),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                ' / 5.0',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            context,
                            localizations.translate('subjectLabel'),
                            currentTutor.subject,
                          ),
                          _buildPriceRow(
                            context,
                            localizations.translate('price'),
                            currentTutor.price,
                          ),
                          _buildInfoRow(
                            context,
                            localizations.translate('regionLabel'),
                            currentTutor.region ??
                                localizations.translate('notAvailable'),
                          ),
                          _buildInfoRow(
                            context,
                            localizations.translate('districtLabel'),
                            currentTutor.district ??
                                localizations.translate('notAvailable'),
                          ),
                          _buildInfoRow(
                            context,
                            localizations.translate('phoneNumberLabel'),
                            tutorUserProfile?.phoneNumber ??
                                localizations.translate('notAvailable'),
                          ),
                          _buildInfoRow(
                            context,
                            localizations.translate('teachingTypeLabel'),
                            currentTutor.teachingType == 'online'
                                ? localizations.translate('onlineTeaching')
                                : localizations.translate('offlineTeaching'),
                          ),
                          if (currentTutor.locationTip != null &&
                              currentTutor.locationTip!.isNotEmpty)
                            _buildInfoRow(
                              context,
                              localizations.translate('locationTipLabel'),
                              currentTutor.locationTip!,
                            ),
                          const SizedBox(height: 24),
                          // Учта устунли маълумот блоклари
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn(
                                context,
                                '${currentTutor.experience ?? 0}',
                                localizations.translate('experienceLabel'),
                              ),
                              _buildStatColumn(
                                context,
                                currentTutor.positionInApp ?? 'N/A',
                                localizations.translate('positionInAppLabel'),
                              ),
                              GestureDetector(
                                // Connected Teaching Centers учун GestureDetector
                                onTap: () {
                                  if (currentTutor
                                      .connectedTeachingCenterIds.isNotEmpty) {
                                    Navigator.of(context).pushNamed(
                                      '/teaching_center_list',
                                      arguments: {
                                        'tutorId': currentTutor.id
                                      }, // Репетитор ID'сини узатамиз
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(localizations.translate(
                                              'noConnectedTeachingCenters'))), // Янги таржима
                                    );
                                  }
                                },
                                child: _buildStatColumn(
                                  context,
                                  _getTeachingCentersCount(currentTutor
                                          .connectedTeachingCenterIds)
                                      .toString(),
                                  localizations.translate('teachingCenters'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            localizations.translate('description'),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentTutor.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '${localizations.translate('reviews')} (${currentTutor.reviews.length})',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          currentTutor.reviews.isEmpty
                              ? Text(localizations.translate('noReviews'))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: currentTutor.reviews.length,
                                  itemBuilder: (context, index) {
                                    final review = currentTutor.reviews[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Фойдаланувчи ID: ${review.userId.substring(0, 8)}...',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                ),
                                                Row(
                                                  children: List.generate(5,
                                                      (starIndex) {
                                                    return Icon(
                                                      starIndex < review.rating
                                                          ? Icons.star
                                                          : Icons.star_border,
                                                      color: Colors.amber,
                                                      size: 18,
                                                    );
                                                  }),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              review.text,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                            Text(
                                              review.timestamp
                                                  .toDate()
                                                  .toLocal()
                                                  .toString()
                                                  .split(' ')[0],
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                      color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                          const SizedBox(height: 24),
                          // Шарҳ қолдириш бўлими фақат клиентлар учун ва ўзининг профили бўлмаса кўринади
                          if (isClient && !isMyOwnProfile)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localizations.translate('addReview'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _reviewController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: localizations
                                        .translate('reviewPlaceholder'),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    filled: true,
                                    fillColor: Theme.of(context).cardColor,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Text(
                                        localizations
                                            .translate('ratingPlaceholder'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium),
                                    const SizedBox(width: 10),
                                    DropdownButton<int>(
                                      value: _reviewRating,
                                      items: List.generate(5, (index) {
                                        return DropdownMenuItem(
                                          value: index + 1,
                                          child: Text('${index + 1}'),
                                        );
                                      }),
                                      onChanged: (value) {
                                        setState(() {
                                          _reviewRating = value!;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                if (_message != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _isMessageError
                                            ? Colors.red.shade100
                                            : Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: _isMessageError
                                                ? Colors.red.shade400
                                                : Colors.green.shade400),
                                      ),
                                      child: Text(
                                        _message!,
                                        style: TextStyle(
                                            color: _isMessageError
                                                ? Colors.red.shade800
                                                : Colors.green.shade800),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _addReview(context, currentTutor),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 5,
                                    ),
                                    child: Text(
                                        localizations.translate('submitReview'),
                                        style: const TextStyle(fontSize: 18)),
                                  ),
                                ),
                              ],
                            )
                          else if (!isMyOwnProfile) // Агар клиент бўлмаса ва ўзининг профили бўлмаса
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                localizations.translate(
                                    'loginRequiredReview'), // Умумий хабар
                                style: TextStyle(
                                    color: Colors.orange[700], fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          if (isMyOwnProfile) // Агар ўзининг профили бўлса
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                localizations.translate(
                                    'cannotReviewOwnProfile'), // Янги таржима
                                style: TextStyle(
                                    color: Colors.orange[700], fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Алоқа иконкалари учун ёрдамчи виджет
  Widget _buildContactIcon(IconData icon, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
        child: IconButton(
          icon: Icon(icon, color: color, size: 24),
          onPressed: onPressed,
        ),
      ),
    );
  }

  // Асосий маълумот қаторлари учун ёрдамчи виджет
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  // Асосий маълумот қаторлари учун ёрдамчи виджет
  Widget _buildPriceRow(BuildContext context, String label, double value) {
    final valued = new NumberFormat("#,##0", "en_US");
    final localizations = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${localizations.translate(label)}', // Use localized label
            style: TextStyle(
              color: Colors.indigo,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${valued.format(value)} UZS', // Use localized label
            style: TextStyle(
              color: Colors.indigo,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Статистика устунлари учун ёрдамчи виджет
  Widget _buildStatColumn(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
