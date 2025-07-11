import 'package:cloud_firestore/cloud_firestore.dart';

class Request {
  final String id; // Request ID
  final String tutorId;
  final String teachingCenterId;
  final String status; // 'pending', 'accepted', 'declined'
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  Request({
    required this.id,
    required this.tutorId,
    required this.teachingCenterId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Request.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Request(
      id: doc.id,
      tutorId: data['tutorId'] ?? '',
      teachingCenterId: data['teachingCenterId'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tutorId': tutorId,
      'teachingCenterId': teachingCenterId,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
