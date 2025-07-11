import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:repetitor_resurs/l10n/app_localizations.dart';
import 'package:repetitor_resurs/models/user_profile.dart'; // UserProfile'ни импорт қилиш
import 'package:repetitor_resurs/models/tutor.dart'; // Tutor'ни импорт қилиш (агар репетитор профилини ҳам кўрсатиш керак бўлса)

class OtherUserProfileScreen extends StatelessWidget {
  final String userId;

  const OtherUserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.indigo,
        title: Text(localizations.translate('userProfileTitle')),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userSnapshot.hasError) {
            return Center(child: Text('Хато: ${userSnapshot.error}'));
          }
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return Center(child: Text(localizations.translate('userNotFound')));
          }

          final userProfile = UserProfile.fromFirestore(userSnapshot.data!);
          print(userProfile.uid);
          final bool isTutor = userProfile.userType == 'tutor';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.2),
                      backgroundImage: userProfile.imageUrl != null &&
                              userProfile.imageUrl!.isNotEmpty
                          ? NetworkImage(userProfile.imageUrl!)
                          : null,
                      child: userProfile.imageUrl == null ||
                              userProfile.imageUrl!.isEmpty
                          ? Icon(Icons.person,
                              size: 80, color: Theme.of(context).primaryColor)
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      userProfile.name ??
                          localizations.translate('notAvailable'),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColorDark),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${localizations.translate('emailLabel')} ${userProfile.email}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${localizations.translate('userTypeLabel')} ${userProfile.userType}',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (userProfile.phoneNumber != null &&
                        userProfile.phoneNumber!.isNotEmpty)
                      Text(
                        '${localizations.translate('phoneNumberLabel')}: ${userProfile.phoneNumber}',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 30),
                    // Агар фойдаланувчи репетитор бўлса, унинг репетитор профил маълумотларини ҳам кўрсатиш
                    if (isTutor)
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('tutors')
                            .doc(userId)
                            .get(),
                        builder: (context, tutorSnapshot) {
                          if (tutorSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (tutorSnapshot.hasError) {
                            return Text(
                                'Репетитор маълумотларини юклашда хато: ${tutorSnapshot.error}');
                          }
                          if (!tutorSnapshot.hasData ||
                              !tutorSnapshot.data!.exists) {
                            return Text('Репетитор маълумотлари топилмади.');
                          }

                          final tutor =
                              Tutor.fromFirestore(tutorSnapshot.data!);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(height: 30),
                              Text(
                                localizations.translate('tutorProfileTitle'),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              _buildInfoRow(
                                  context,
                                  Icons.book,
                                  localizations.translate('subjectLabel'),
                                  tutor.subject),
                              _buildInfoRow(
                                  context,
                                  Icons.attach_money,
                                  localizations.translate('priceLabel'),
                                  '${tutor.price.toStringAsFixed(2)} USD'),
                              _buildInfoRow(
                                  context,
                                  Icons.description,
                                  localizations.translate('descriptionLabel'),
                                  tutor.description),
                              _buildInfoRow(
                                  context,
                                  Icons.school,
                                  localizations.translate('teachingTypeLabel'),
                                  tutor.teachingType == 'online'
                                      ? localizations
                                          .translate('onlineTeaching')
                                      : localizations
                                          .translate('offlineTeaching')),
                              if (tutor.teachingType == 'offline') ...[
                                _buildInfoRow(
                                    context,
                                    Icons.location_on,
                                    localizations.translate('selectRegion'),
                                    tutor.region ??
                                        localizations
                                            .translate('notAvailable')),
                                _buildInfoRow(
                                    context,
                                    Icons.location_city,
                                    localizations.translate('selectDistrict'),
                                    tutor.district ??
                                        localizations
                                            .translate('notAvailable')),
                                if (tutor.locationTip != null &&
                                    tutor.locationTip!.isNotEmpty)
                                  _buildInfoRow(
                                      context,
                                      Icons.info_outline,
                                      localizations
                                          .translate('locationTipLabel'),
                                      tutor.locationTip!),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 24),
                                  Text(
                                    '${tutor.rating.toStringAsFixed(1)}/5',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label:',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
