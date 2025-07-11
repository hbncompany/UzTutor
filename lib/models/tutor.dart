import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:repetitor_resurs/models/review.dart'; // Review modelini import qilish

class Tutor {
  final String id;
  final String name;
  final String subject;
  final double price;
  final String description;
  final String? imageUrl;
  final double rating;
  final List<Review> reviews;
  final String teachingType; // 'online' or 'offline'
  final String? region; // Only for offline tutors
  final String? district; // Only for offline tutors
  final String? locationTip; // Optional tip for offline location
  final List<String> connectedTeachingCenterIds; // Уланган ўқув марказлари
  final int? experience; // Тажриба
  final String? positionInApp; // Иловадаги позиция

  Tutor({
    required this.id,
    required this.name,
    required this.subject,
    required this.price,
    required this.description,
    this.imageUrl,
    this.rating = 0.0,
    this.reviews = const [],
    required this.teachingType,
    this.region,
    this.district,
    this.locationTip,
    this.connectedTeachingCenterIds = const [],
    this.experience,
    this.positionInApp,
  });

  // Маълумотлар базасидан String қийматни хавфсиз олиш учун ёрдамчи функция
  static String? _safeGetString(
      Map<String, dynamic> data, String key, String docId) {
    final dynamic value = data[key];
    if (value is String) {
      return value;
    }
    // Агар қиймат String бўлмаса, огоҳлантириш чоп этинг ва null қайтаринг
    if (value != null) {
      print(
          'Warning: Document ID: $docId, Field "$key" in Tutor is not a String. Actual type: ${value.runtimeType}. Value: $value');
    }
    return null;
  }

  // Firestore DocumentSnapshot'дан Tutor объектини яратиш
  factory Tutor.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Tutor(
      id: doc.id,
      name: _safeGetString(data, 'name', doc.id) ?? '',
      subject: _safeGetString(data, 'subject', doc.id) ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      description: _safeGetString(data, 'description', doc.id) ?? '',
      imageUrl: _safeGetString(data, 'imageUrl', doc.id),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (data['reviews'] as List<dynamic>?)
              ?.map((reviewData) =>
                  Review.fromMap(reviewData as Map<String, dynamic>))
              .toList() ??
          [],
      teachingType: _safeGetString(data, 'teachingType', doc.id) ?? 'offline',
      region: _safeGetString(data, 'region', doc.id),
      district: _safeGetString(data, 'district', doc.id),
      locationTip: _safeGetString(data, 'locationTip', doc.id),
      connectedTeachingCenterIds:
          List<String>.from(data['connectedTeachingCenterIds'] ?? []),
      experience: (data['experience'] as num?)?.toInt(),
      positionInApp: _safeGetString(data, 'positionInApp', doc.id),
    );
  }

  factory Tutor.fromMap(Map<String, dynamic> data) {
    return Tutor(
      id: data['id'] is String ? data['id'] : '',
      name: data['name'] is String ? data['name'] : '',
      subject: data['subject'] is String ? data['subject'] : '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] is String ? data['description'] : '',
      imageUrl: data['imageUrl'] is String ? data['imageUrl'] : null,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (data['reviews'] as List<dynamic>?)
              ?.map((reviewData) {
                if (reviewData is Map<String, dynamic>) {
                  return Review.fromMap(reviewData);
                }
                print('Warning: Invalid review data format: $reviewData');
                return null;
              })
              .where((review) => review != null)
              .cast<Review>()
              .toList() ??
          [],
      teachingType:
          data['teachingType'] is String ? data['teachingType'] : 'offline',
      region: data['region'] is String ? data['region'] : null,
      district: data['district'] is String ? data['district'] : null,
      locationTip: data['locationTip'] is String ? data['locationTip'] : null,
      connectedTeachingCenterIds: data['connectedTeachingCenterIds'] is List
          ? List<String>.from(data['connectedTeachingCenterIds']
              .map((e) => e is String ? e : ''))
          : [],
      experience: (data['experience'] as num?)?.toInt(),
      positionInApp:
          data['positionInApp'] is String ? data['positionInApp'] : null,
    );
  }

  // Tutor объектини Firestore'га юбориш учун Map'га айлантириш
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviews': reviews.map((review) => review.toMap()).toList(),
      'teachingType': teachingType,
      'region': region,
      'district': district,
      'locationTip': locationTip,
      'connectedTeachingCenterIds': connectedTeachingCenterIds,
      'experience': experience,
      'positionInApp': positionInApp,
    };
  }

  // Объектининг нусхасини ўзгартирилган қийматлар билан яратиш
  Tutor copyWith({
    String? id,
    String? name,
    String? subject,
    double? price,
    String? description,
    String? imageUrl,
    double? rating,
    List<Review>? reviews,
    String? teachingType,
    String? region,
    String? district,
    String? locationTip,
    List<String>? connectedTeachingCenterIds,
    int? experience,
    String? positionInApp,
  }) {
    return Tutor(
      id: id ?? this.id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      teachingType: teachingType ?? this.teachingType,
      region: region ?? this.region,
      district: district ?? this.district,
      locationTip: locationTip ?? this.locationTip,
      connectedTeachingCenterIds:
          connectedTeachingCenterIds ?? this.connectedTeachingCenterIds,
      experience: experience ?? this.experience,
      positionInApp: positionInApp ?? this.positionInApp,
    );
  }
}
