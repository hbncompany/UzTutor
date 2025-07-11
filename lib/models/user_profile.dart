import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String userType; // 'client', 'tutor' ёки 'teaching_center' ёки 'guest'
  final String? name; // client/tutor учун
  final String? centerName; // teaching_center учун
  final String? phoneNumber;
  final String? imageUrl;
  final List<String>? bookmarkedTutorIds; // Янги майдон
  final List<String>? bookmarkedTeachingCenterIds; // Янги майдон

  UserProfile({
    required this.uid,
    required this.email,
    required this.userType,
    this.name,
    this.centerName,
    this.phoneNumber,
    this.imageUrl,
    this.bookmarkedTutorIds,
    this.bookmarkedTeachingCenterIds,
  });

  // Firestore'дан маълмотни олиш учун Factory constructor
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?; // Nullable qildik
    return UserProfile(
      uid: doc.id,
      email: data?['email'] ?? '',
      userType: data?['userType'] ?? 'client', // Default 'client'
      name: data?['name'],
      centerName: data?['centerName'],
      phoneNumber: data?['phoneNumber'],
      imageUrl: data?['imageUrl'],
      bookmarkedTutorIds: (data?['bookmarkedTutorIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      bookmarkedTeachingCenterIds:
          (data?['bookmarkedTeachingCenterIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
    );
  }

  // Firestore'га маълмотни юбориш учун Map'га айлантириш
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'userType': userType,
      'name': name,
      'centerName': centerName,
      'phoneNumber': phoneNumber,
      'imageUrl': imageUrl,
      'bookmarkedTutorIds': bookmarkedTutorIds,
      'bookmarkedTeachingCenterIds': bookmarkedTeachingCenterIds,
    };
  }

  // Объектининг нусхасини ўзгартирилган қийматлар билан яратиш
  UserProfile copyWith({
    String? uid,
    String? email,
    String? userType,
    String? name,
    String? centerName,
    String? phoneNumber,
    String? imageUrl,
    List<String>? bookmarkedTutorIds,
    List<String>? bookmarkedTeachingCenterIds,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      name: name ?? this.name,
      centerName: centerName ?? this.centerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      bookmarkedTutorIds: bookmarkedTutorIds ?? this.bookmarkedTutorIds,
      bookmarkedTeachingCenterIds:
          bookmarkedTeachingCenterIds ?? this.bookmarkedTeachingCenterIds,
    );
  }
}
