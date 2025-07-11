import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:repetitor_resurs/models/user_profile.dart';

class UserProvider extends ChangeNotifier {
  User? _firebaseUser;
  UserProfile? _userProfile;
  bool _isLoadingProfile = false;

  User? get firebaseUser => _firebaseUser;
  UserProfile? get userProfile => _userProfile;
  bool get isLoadingProfile => _isLoadingProfile;

  UserProvider();

  Future<void> setUser(User? user) async {
    if (_firebaseUser == user && _userProfile != null && !_isLoadingProfile) {
      return;
    }

    _firebaseUser = user;
    if (user != null) {
      _isLoadingProfile = true;
      notifyListeners();

      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          _userProfile = UserProfile.fromFirestore(doc);
        } else {
          _userProfile = UserProfile(
            uid: user.uid,
            email: user.email ?? 'guest_${user.uid.substring(0, 8)}@anon.com',
            userType: user.isAnonymous ? 'guest' : 'client',
            bookmarkedTutorIds: [], // Янги фойдаланувчи учун бўш рўйхат
            bookmarkedTeachingCenterIds: [], // Янги фойдаланувчи учун бўш рўйхат
          );
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(_userProfile!.toFirestore());
        }
      } catch (e) {
        print("Профилни юклашда хато: $e");
        _userProfile = null;
      } finally {
        _isLoadingProfile = false;
        notifyListeners();
      }
    } else {
      _userProfile = null;
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? imageUrl,
  }) async {
    if (_firebaseUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseUser!.uid)
          .update({
        if (name != null) 'name': name,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (imageUrl != null) 'imageUrl': imageUrl,
      });
      // Янгилашдан кейин ўзгаришларни акс эттириш учун профилни қайта юклаш
      await setUser(
          _firebaseUser); // setUser'ни чақириш орқали профилни қайта юклаш
    } catch (e) {
      print("Профилни янгилашда хато: $e");
    }
  }

  // Репетиторни хатчўпларга қўшиш/олиб ташлаш
  Future<void> toggleTutorBookmark(String tutorId) async {
    if (_firebaseUser == null || _userProfile == null) return;

    List<String> currentBookmarks =
        List.from(_userProfile!.bookmarkedTutorIds ?? []);
    if (currentBookmarks.contains(tutorId)) {
      currentBookmarks.remove(tutorId);
    } else {
      currentBookmarks.add(tutorId);
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseUser!.uid)
          .update({
        'bookmarkedTutorIds': currentBookmarks,
      });
      // Профилни янгилаш ва UI'ни янгилаш
      _userProfile =
          _userProfile!.copyWith(bookmarkedTutorIds: currentBookmarks);
      notifyListeners();
    } catch (e) {
      print("Репетитор хатчўпини янгилашда хато: $e");
      rethrow; // Хатони қайта узатиш
    }
  }

  // Репетитор хатчўпланганми ёки йўқлигини текшириш
  bool isTutorBookmarked(String tutorId) {
    return _userProfile?.bookmarkedTutorIds?.contains(tutorId) ?? false;
  }

  // Ўқув марказини хатчўпларга қўшиш/олиб ташлаш (келажакда фойдаланиш учун)
  Future<void> toggleTeachingCenterBookmark(String centerId) async {
    if (_firebaseUser == null || _userProfile == null) return;

    List<String> currentBookmarks =
        List.from(_userProfile!.bookmarkedTeachingCenterIds ?? []);
    if (currentBookmarks.contains(centerId)) {
      currentBookmarks.remove(centerId);
    } else {
      currentBookmarks.add(centerId);
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseUser!.uid)
          .update({
        'bookmarkedTeachingCenterIds': currentBookmarks,
      });
      _userProfile =
          _userProfile!.copyWith(bookmarkedTeachingCenterIds: currentBookmarks);
      notifyListeners();
    } catch (e) {
      print("Ўқув маркази хатчўпини янгилашда хато: $e");
      rethrow;
    }
  }

  // Ўқув маркази хатчўпланганми ёки йўқлигини текшириш
  bool isTeachingCenterBookmarked(String centerId) {
    return _userProfile?.bookmarkedTeachingCenterIds?.contains(centerId) ??
        false;
  }
}
