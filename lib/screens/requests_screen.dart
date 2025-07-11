import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:repetitor_resurs/l10n/app_localizations.dart';
import 'package:repetitor_resurs/providers/user_provider.dart';
import 'package:repetitor_resurs/models/request.dart';
import 'package:repetitor_resurs/models/user_profile.dart'; // UserProfile'ни импорт қилиш
import 'package:repetitor_resurs/models/teaching_center.dart'; // TeachingCenter'ни импорт қилиш
import 'package:repetitor_resurs/models/tutor.dart'; // Tutor'ни импорт қилиш
import 'dart:async'; // StreamSubscription учун импорт қилинди

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Фойдаланувчи/Марказ номини олиш учун
  Future<String> _getParticipantName(String userId, String userType) async {
    try {
      if (userType == 'tutor') {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(userId).get();
        return userDoc.get('name') ??
            userDoc.get('email') ??
            'Номаълум репетитор';
      } else if (userType == 'teaching_center') {
        DocumentSnapshot centerDoc =
            await _firestore.collection('teachingCenters').doc(userId).get();
        return centerDoc.get('name') ?? 'Номаълум марказ';
      }
      return 'Номаълум фойдаланувчи';
    } catch (e) {
      print("Иштирокчи номини юклашда хато: $e");
      return 'Хато: ${userId.substring(0, 8)}...';
    }
  }

  Future<void> _processRequest(
      BuildContext context, Request request, String newStatus) async {
    final localizations = AppLocalizations.of(context);
    try {
      await _firestore.collection('requests').doc(request.id).update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });

      if (newStatus == 'accepted') {
        // Репетиторнинг connectedTeachingCenterIds'ига марказ ID'сини қўшиш
        await _firestore.collection('tutors').doc(request.tutorId).update({
          'connectedTeachingCenterIds':
              FieldValue.arrayUnion([request.teachingCenterId]),
        });
        // Ўқув марказининг connectedTutorIds'ини янгилаш
        await _firestore
            .collection('teachingCenters')
            .doc(request.teachingCenterId)
            .update({
          'connectedTutorIds': FieldValue.arrayUnion([request.tutorId]),
        });
      }

      if (!mounted) return; // Хатодан қочиш учун текширув
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(newStatus == 'accepted'
              ? localizations.translate('requestAcceptedSuccess')
              : localizations.translate('requestDeclinedSuccess'))));
    } catch (e) {
      if (!mounted) return; // Хатодан қочиш учун текширув
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(localizations.translate('errorProcessingRequest',
              args: {'error': e.toString()}))));
    }
  }

  Future<void> _removeRequest(BuildContext context, Request request) async {
    final localizations = AppLocalizations.of(context);
    try {
      await _firestore.collection('requests').doc(request.id).delete();
      // Агар сўров қабул қилинган бўлса, уланган репетитор ва марказ маълумотларини ҳам тозалаш
      if (request.status == 'accepted') {
        // Репетиторнинг connectedTeachingCenterIds'идан марказ ID'сини олиб ташлаш
        await _firestore.collection('tutors').doc(request.tutorId).update({
          'connectedTeachingCenterIds':
              FieldValue.arrayRemove([request.teachingCenterId]),
        });
        // Ўқув марказининг connectedTutorIds'идан репетитор ID'сини олиб ташлаш
        await _firestore
            .collection('teachingCenters')
            .doc(request.teachingCenterId)
            .update({
          'connectedTutorIds': FieldValue.arrayRemove([request.tutorId]),
        });
      }
      if (!mounted) return; // Хатодан қочиш учун текширув
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(localizations.translate('requestRemovedSuccess'))));
    } catch (e) {
      if (!mounted) return; // Хатодан қочиш учун текширув
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(localizations.translate('errorProcessingRequest',
              args: {'error': e.toString()}))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final currentUserId = userProvider.firebaseUser?.uid;
    final userType = userProvider.userProfile?.userType;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.indigo,
          title: Text(localizations.translate('requests')),
          centerTitle: true,
        ),
        body: Center(
          child: Text(localizations.translate('loginRequiredReview')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.indigo,
        title: Text(userType == 'tutor'
            ? localizations.translate('myRequestsTitle')
            : localizations.translate('tutorRequestsTitle')),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).focusColor,
          labelColor: Theme.of(context).highlightColor,
          unselectedLabelColor: Theme.of(context).unselectedWidgetColor,
          tabs: [
            Tab(
              icon: const Icon(Icons.done_all_rounded,
                  color: Colors.green), // Accepted icon
              text: localizations.translate('acceptedRequests'),
            ),
            Tab(
              icon: const Icon(Icons.pending_actions_rounded,
                  color: Colors.orange), // Pending icon
              text: localizations.translate('pendingRequests'),
            ),
            Tab(
              icon: const Icon(Icons.cancel_outlined,
                  color: Colors.redAccent), // Cancelled/Declined icon
              text: localizations.translate('cancelledRequests'),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Accepted Requests Tab
          _buildRequestsList(
            context,
            currentUserId,
            userType,
            'accepted',
            orderByField: 'updatedAt', // Accepted requests have updatedAt
          ),
          // Pending Requests Tab
          _buildRequestsList(
            context,
            currentUserId,
            userType,
            'pending',
            orderByField: 'createdAt', // Pending requests only have createdAt
          ),
          // Cancelled Requests Tab
          _buildRequestsList(
            context,
            currentUserId,
            userType,
            'declined', // Assuming 'cancelled' is 'declined' in Firestore
            orderByField: 'updatedAt', // Declined requests have updatedAt
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(
    BuildContext context,
    String currentUserId,
    String? userType,
    String status, {
    required String orderByField,
  }) {
    final localizations = AppLocalizations.of(context);

    Query<Map<String, dynamic>> baseQuery;

    if (userType == 'tutor') {
      baseQuery = _firestore
          .collection('requests')
          .where('tutorId', isEqualTo: currentUserId);
    } else if (userType == 'teaching_center') {
      baseQuery = _firestore
          .collection('requests')
          .where('teachingCenterId', isEqualTo: currentUserId);
    } else {
      // For clients, they don't have requests *sent to them* in this context,
      // but they might have sent requests.
      // Assuming a 'clientId' field exists for requests sent by clients.
      // If clients only view their own sent requests, they would also need a 'clientId' field in the request document.
      // For this implementation, we'll focus on tutors/centers receiving requests.
      return Center(
          child: Text(localizations
              .translate('noRequestsForClient'))); // New translation
    }

    return StreamBuilder<QuerySnapshot>(
      stream: baseQuery
          .where('status', isEqualTo: status)
          .orderBy(orderByField, descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print("Сўровларни юклашда хато: ${snapshot.error}");
          return Center(
              child: Text(localizations.translate('errorLoadingRequests',
                  args: {'error': snapshot.error.toString()})));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text(localizations.translate('noRequestsFoundForStatus',
                  args: {'status': localizations.translate(status)})));
        }

        final requests = snapshot.data!.docs
            .map((doc) => Request.fromFirestore(doc))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final isPending = request.status == 'pending';
            final isAccepted = request.status == 'accepted';
            final isDeclined = request.status == 'declined';

            // Қайси ID'ни профилга ўтказишни аниқлаш
            final String profileIdToView = userType == 'tutor'
                ? request.teachingCenterId
                : request.tutorId;
            // Қайси турдаги профилга ўтишни аниқлаш
            final String profileTypeToView =
                userType == 'tutor' ? 'teaching_center' : 'tutor';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: _getParticipantName(
                          profileIdToView, profileTypeToView),
                      builder: (context, nameSnapshot) {
                        return GestureDetector(
                          // GestureDetector қўшилди
                          onTap: () {
                            print(
                                'Navigating to profile with ID: $profileIdToView');
                            if (profileTypeToView == 'tutor') {
                              Navigator.of(context).pushNamed(
                                '/tutor_profile',
                                arguments: profileIdToView,
                              );
                            } else if (profileTypeToView == 'teaching_center') {
                              Navigator.of(context).pushNamed(
                                '/teaching_center_profile',
                                arguments: profileIdToView,
                              );
                            }
                          },
                          child: Text(
                            userType == 'tutor'
                                ? 'Марказ: ${nameSnapshot.data ?? 'Юкланмоқда...'}'
                                : 'Репетитор: ${nameSnapshot.data ?? 'Юкланмоқда...'}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .primaryColor, // Босиш мумкинлигини кўрсатиш учун ранг
                                  decoration: TextDecoration
                                      .underline, // Босиш мумкинлигини кўрсатиш учун тагига чизиш
                                ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Ҳолат: ',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          isPending
                              ? localizations.translate('requestStatusPending')
                              : isAccepted
                                  ? localizations
                                      .translate('requestStatusAccepted')
                                  : localizations
                                      .translate('requestStatusDeclined'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: isAccepted
                                    ? Colors.green
                                    : (isDeclined ? Colors.red : Colors.orange),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Юборилган сана: ${request.createdAt.toDate().toLocal().toString().split(' ')[0]}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (request.updatedAt != null)
                      Text(
                        'Янгиланган сана: ${request.updatedAt!.toDate().toLocal().toString().split(' ')[0]}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 16),
                    // Ўқув маркази учун ҳаракатлар
                    if (userType == 'teaching_center')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (isPending)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _processRequest(
                                    context, request, 'accepted'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(
                                    localizations.translate('acceptRequest')),
                              ),
                            ),
                          if (isPending) const SizedBox(width: 10),
                          if (isPending)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _processRequest(
                                    context, request, 'declined'),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  foregroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(
                                    localizations.translate('declineRequest')),
                              ),
                            ),
                          // Агар қабул қилинган бўлса, алоқани узиш тугмаси
                          if (isAccepted)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    _removeRequest(context, request),
                                style: OutlinedButton.styleFrom(
                                  side:
                                      const BorderSide(color: Colors.redAccent),
                                  foregroundColor: Colors.redAccent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(localizations
                                    .translate('removeConnection')),
                              ),
                            ),
                        ],
                      ),
                    // Репетитор учун ҳаракатлар
                    if (userType == 'tutor')
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _removeRequest(context, request),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: isAccepted
                                    ? Colors.redAccent
                                    : Colors
                                        .grey), // Қабул қилинган учун қизил, акс ҳолда кулранг
                            foregroundColor: isAccepted
                                ? Colors.redAccent
                                : Colors.grey[700],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            isAccepted
                                ? localizations.translate(
                                    'removeConnection') // Янги таржима
                                : localizations.translate('removeRequest'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class RequestCardPlaceholder extends StatelessWidget {
  const RequestCardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 150, height: 16, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Container(width: 200, height: 14, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Container(width: 100, height: 14, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Container(width: 80, height: 12, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
