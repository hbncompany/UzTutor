import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String userId;
  final String text;
  final int rating;
  final Timestamp timestamp;

  Review({
    required this.userId,
    required this.text,
    required this.rating,
    required this.timestamp,
  });

  // Маълумотлар базасидан String қийматни хавфсиз олиш учун ёрдамчи функция
  static String _safeGetString(Map<String, dynamic> data, String key) {
    final dynamic value = data[key];
    if (value is String) {
      return value;
    }
    // Агар қиймат String бўлмаса, огоҳлантириш чоп этинг ва бўш қатор қайтаринг
    if (value != null) {
      print(
          'Warning: Review field "$key" is not a String. Actual type: ${value.runtimeType}. Value: $value');
    }
    return ''; // Дефолт бўш қатор ёки бошқа дефолт қиймат
  }

  // Firestore'дан маълмотни олиш учун
  factory Review.fromMap(Map<String, dynamic> data) {
    return Review(
      userId: _safeGetString(data, 'userId'), // Хавфсиз парслаш
      text: _safeGetString(data, 'text'), // Хавфсиз парслаш
      rating: (data['rating'] as num?)?.toInt() ??
          0, // num дан int га ўтказиш, дефолт 0
      timestamp: data['timestamp'] as Timestamp? ??
          Timestamp.now(), // Дефолт жорий вақт
    );
  }

  // Firestore'га маълмотни юбориш учун
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'text': text,
      'rating': rating,
      'timestamp': timestamp,
    };
  }
}
