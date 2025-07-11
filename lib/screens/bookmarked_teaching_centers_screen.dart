import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:repetitor_resurs/l10n/app_localizations.dart';
import 'dart:async';

class BookmarkedTeachingCentersScreen extends StatefulWidget {
  const BookmarkedTeachingCentersScreen({super.key});

  @override
  State<BookmarkedTeachingCentersScreen> createState() =>
      _BookmarkedTeachingCentersScreenState();
}

class _BookmarkedTeachingCentersScreenState
    extends State<BookmarkedTeachingCentersScreen> {
  List<Map<String, dynamic>> _bookmarkedTeachingCenters = [];
  bool _isLoading = true;
  String? _errorMessage;
  late StreamSubscription<DocumentSnapshot> _userProfileSubscription;

  @override
  void initState() {
    super.initState();
    _fetchBookmarkedTeachingCenters();
  }

  @override
  void dispose() {
    _userProfileSubscription.cancel();
    super.dispose();
  }

  Future<void> _fetchBookmarkedTeachingCenters() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _errorMessage =
              AppLocalizations.of(context).translate('loginRequiredBookmark');
          _isLoading = false;
        });
      }
      return;
    }

    _userProfileSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .listen((userSnapshot) async {
      if (userSnapshot.exists && mounted) {
        final userData = userSnapshot.data();
        final bookmarkedIds =
            List<String>.from(userData?['bookmarkedTeachingCenters'] ?? []);

        if (bookmarkedIds.isEmpty) {
          setState(() {
            _bookmarkedTeachingCenters = [];
            _isLoading = false;
          });
          return;
        }

        try {
          final centersQuery = await FirebaseFirestore.instance
              .collection('teachingCenters')
              .where(FieldPath.documentId, whereIn: bookmarkedIds)
              .get();

          if (mounted) {
            setState(() {
              _bookmarkedTeachingCenters = centersQuery.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();
              _isLoading = false;
            });
          }
        } catch (e) {
          print("Хатчўпга олинган ўқув марказларини юклашда хато: $e");
          if (mounted) {
            setState(() {
              _errorMessage = AppLocalizations.of(context).translate(
                  'errorLoadingBookmarks',
                  args: {'error': e.toString()});
              _isLoading = false;
            });
          }
        }
      } else if (mounted) {
        setState(() {
          _bookmarkedTeachingCenters = [];
          _isLoading = false;
        });
      }
    }, onError: (error) {
      print("Фойдаланувчи профилини кузатишда хато: $error");
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context).translate(
              'errorLoadingBookmarks',
              args: {'error': error.toString()});
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _toggleBookmark(String centerId, bool isBookmarked) async {
    final localizations = AppLocalizations.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(localizations.translate('loginRequiredBookmark'))),
      );
      return;
    }

    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

    try {
      if (isBookmarked) {
        await userDocRef.update({
          'bookmarkedTeachingCenters': FieldValue.arrayRemove([centerId]),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.translate('bookmarkRemoved'))),
        );
      } else {
        await userDocRef.update({
          'bookmarkedTeachingCenters': FieldValue.arrayUnion([centerId]),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.translate('bookmarkAdded'))),
        );
      }
    } catch (e) {
      print("Хатчўпни янгилашда хато: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(localizations
                .translate('bookmarkError', args: {'error': e.toString()}))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.indigo,
        title: Text(localizations.translate('bookmarkedTeachingCentersTitle')),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _bookmarkedTeachingCenters.isEmpty
                  ? Center(
                      child: Text(localizations
                          .translate('noBookmarkedTeachingCentersFound')))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _bookmarkedTeachingCenters.length,
                      itemBuilder: (context, index) {
                        final center = _bookmarkedTeachingCenters[index];
                        final isBookmarked = currentUserId != null &&
                            _bookmarkedTeachingCenters.any((bCenter) =>
                                bCenter['id'] ==
                                center['id']); // Тўғри текшириш
                        return _buildTeachingCenterCard(
                          context,
                          centerData: center,
                          isBookmarked: isBookmarked,
                          onToggleBookmark: (bool currentlyBookmarked) {
                            _toggleBookmark(center['id'], currentlyBookmarked);
                          },
                          onTap: () {
                            Navigator.of(context).pushNamed(
                                '/teaching_center_profile',
                                arguments: center['id']);
                          },
                        );
                      },
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
