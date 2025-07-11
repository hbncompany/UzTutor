import 'package:cloud_firestore/cloud_firestore.dart';

class TeachingCenterLocation {
  final String region;
  final String district;
  final String? locationTip;
  final String?
      type; // 'online' or 'offline' - for future use if needed per location

  TeachingCenterLocation({
    required this.region,
    required this.district,
    this.locationTip,
    this.type,
  });

  factory TeachingCenterLocation.fromMap(Map<String, dynamic> data) {
    return TeachingCenterLocation(
      region: data['region'] ?? '',
      district: data['district'] ?? '',
      locationTip: data['locationTip'],
      type: data['type'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'region': region,
      'district': district,
      'locationTip': locationTip,
      'type': type,
    };
  }
}

class TeachingCenter {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? imageUrl;
  final String description;
  final List<TeachingCenterLocation> locations;
  final List<String> connectedTutorIds; // Уланган репетиторлар IDлари

  TeachingCenter({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.imageUrl,
    required this.description,
    this.locations = const [],
    this.connectedTutorIds = const [],
  });

  factory TeachingCenter.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TeachingCenter(
      id: doc.id,
      name: data['name'] ?? 'Номаълум марказ',
      phoneNumber: data['phoneNumber'],
      imageUrl: data['imageUrl'],
      description: data['description'] ?? 'Тавсиф мавжуд эмас.',
      locations: (data['locations'] as List<dynamic>?)
              ?.map((locData) => TeachingCenterLocation.fromMap(
                  locData as Map<String, dynamic>))
              .toList() ??
          [],
      connectedTutorIds: (data['connectedTutorIds'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'imageUrl': imageUrl,
      'description': description,
      'locations': locations.map((e) => e.toMap()).toList(),
      'connectedTutorIds': connectedTutorIds,
    };
  }
}
