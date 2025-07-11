import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:repetitor_resurs/l10n/app_localizations.dart';
import 'dart:async';

class BookmarkedTutorsScreen extends StatefulWidget {
  const BookmarkedTutorsScreen({super.key});

  @override
  State<BookmarkedTutorsScreen> createState() => _BookmarkedTutorsScreenState();
}

class _BookmarkedTutorsScreenState extends State<BookmarkedTutorsScreen> {
  List<Map<String, dynamic>> _bookmarkedTutors = [];
  bool _isLoading = true;
  String? _errorMessage;
  late StreamSubscription<DocumentSnapshot> _userProfileSubscription;

  @override
  void initState() {
    super.initState();
    _fetchBookmarkedTutors();
  }

  @override
  void dispose() {
    _userProfileSubscription.cancel();
    super.dispose();
  }

  Future<void> _fetchBookmarkedTutors() async {
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
            List<String>.from(userData?['bookmarkedTutors'] ?? []);

        if (bookmarkedIds.isEmpty) {
          setState(() {
            _bookmarkedTutors = [];
            _isLoading = false;
          });
          return;
        }

        try {
          final tutorsQuery = await FirebaseFirestore.instance
              .collection('tutors')
              .where(FieldPath.documentId, whereIn: bookmarkedIds)
              .get();

          if (mounted) {
            setState(() {
              _bookmarkedTutors = tutorsQuery.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();
              _isLoading = false;
            });
          }
        } catch (e) {
          print("Хатчўпга олинган репетиторларни юклашда хато: $e");
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
          _bookmarkedTutors = [];
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

  Future<void> _toggleBookmark(String tutorId, bool isBookmarked) async {
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
          'bookmarkedTutors': FieldValue.arrayRemove([tutorId]),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.translate('bookmarkRemoved'))),
        );
      } else {
        await userDocRef.update({
          'bookmarkedTutors': FieldValue.arrayUnion([tutorId]),
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
        title: Text(localizations.translate('bookmarkedTutorsTitle')),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _bookmarkedTutors.isEmpty
                  ? Center(
                      child: Text(
                          localizations.translate('noBookmarkedTutorsFound')))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _bookmarkedTutors.length,
                      itemBuilder: (context, index) {
                        final tutor = _bookmarkedTutors[index];
                        final isBookmarked = currentUserId != null &&
                            _bookmarkedTutors.any((bTutor) =>
                                bTutor['id'] == tutor['id']); // Тўғри текшириш
                        return _buildTutorCard(
                          context,
                          tutorData: tutor,
                          isBookmarked: isBookmarked,
                          onToggleBookmark: (bool currentlyBookmarked) {
                            _toggleBookmark(tutor['id'], currentlyBookmarked);
                          },
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              '/tutor_profile',
                              arguments: tutor[
                                  'id'], // Faqat tutorId (String) yuboriladi
                            );
                          },
                        );
                      },
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
                radius: 40,
                backgroundImage: NetworkImage(tutorData['imageUrl'] ??
                    'https://placehold.co/80x80/A78BFA/ffffff?text=T'),
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
                      tutorData['name'] ?? 'Номаълум',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      tutorData['subject'] ?? 'Фан номаълум',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 18),
                        Text(
                          (tutorData['rating'] ?? 0.0).toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${localizations.translate('priceLabel')} ${(tutorData['price'])}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold),
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
