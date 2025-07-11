import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:repetitor_resurs/l10n/app_localizations.dart';
import 'package:repetitor_resurs/models/teaching_center.dart';
import 'package:repetitor_resurs/models/user_profile.dart'; // UserProfile'ни импорт қилиш
import 'package:url_launcher/url_launcher.dart'; // url_launcher'ни импорт қилиш

class TeachingCenterProfileScreen extends StatefulWidget {
  final String centerId;

  const TeachingCenterProfileScreen({super.key, required this.centerId});

  @override
  State<TeachingCenterProfileScreen> createState() =>
      _TeachingCenterProfileScreenState();
}

class _TeachingCenterProfileScreenState
    extends State<TeachingCenterProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Телефон рақамига қўнғироқ қилиш функцияси
  Future<void> _launchPhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Қўнғироқ қилиб бўлмади: $phoneNumber')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.indigo,
        title: Text(localizations.translate('teachingCenterProfileTitle')),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            _firestore.collection('teachingCenters').doc(widget.centerId).get(),
        builder: (context, centerSnapshot) {
          if (centerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (centerSnapshot.hasError) {
            return Center(child: Text('Хато: ${centerSnapshot.error}'));
          }
          if (!centerSnapshot.hasData || !centerSnapshot.data!.exists) {
            return Center(
                child: Text(localizations
                    .translate('noTeachingCentersFound'))); // Умумий хабар
          }

          final teachingCenter =
              TeachingCenter.fromFirestore(centerSnapshot.data!);

          return FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('users').doc(widget.centerId).get(),
            builder: (context, userSnapshot) {
              UserProfile? centerUserProfile;
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                centerUserProfile =
                    UserProfile.fromFirestore(userSnapshot.data!);
              }

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
                          radius: 70,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.2),
                          backgroundImage: teachingCenter.imageUrl != null &&
                                  teachingCenter.imageUrl!.isNotEmpty
                              ? NetworkImage(teachingCenter.imageUrl!)
                              : null,
                          child: teachingCenter.imageUrl == null ||
                                  teachingCenter.imageUrl!.isEmpty
                              ? Icon(Icons.school,
                                  size: 70,
                                  color: Theme.of(context).primaryColor)
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          teachingCenter.name,
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
                          teachingCenter.description,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Divider(),
                        const SizedBox(height: 10),
                        // Телефон рақамини кўрсатиш ва босиш мумкин қилиш
                        if (centerUserProfile?.phoneNumber != null &&
                            centerUserProfile!.phoneNumber!.isNotEmpty)
                          GestureDetector(
                            onTap: () => _launchPhoneCall(
                                centerUserProfile!.phoneNumber!),
                            child: _buildInfoRow(
                                context,
                                Icons.phone,
                                localizations.translate('phoneNumberLabel'),
                                centerUserProfile!.phoneNumber!),
                          ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                            context,
                            Icons.group,
                            localizations.translate('tutorsConnected', args: {
                              'count': teachingCenter.connectedTutorIds.length
                            }),
                            ''), // Connected tutors count
                        const SizedBox(height: 10),
                        Text(
                          localizations.translate('locationsLabel'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        if (teachingCenter.locations.isEmpty)
                          Text(localizations.translate('notAvailable'))
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: teachingCenter.locations.length,
                            itemBuilder: (context, index) {
                              final location = teachingCenter.locations[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.location_on,
                                        size: 20,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${location.region}, ${location.district}${location.locationTip != null && location.locationTip!.isNotEmpty ? ' (${location.locationTip})' : ''}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Ушбу марказга уланган репетиторлар рўйхатига ўтиш
                              Navigator.of(context).pushNamed(
                                '/tutor_list',
                                arguments: {
                                  'teachingCenterId': teachingCenter.id
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 5,
                            ),
                            icon: const Icon(Icons.group),
                            label: Text(localizations.translate('viewTutors'),
                                style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
