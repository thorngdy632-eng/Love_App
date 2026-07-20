import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String bio;
  final String profileImageUrl;
  final GeoPoint? location;
  final DateTime? locationUpdatedAt;
  final bool isOnline;
  final DateTime? lastSeen;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.bio = '',
    this.profileImageUrl = '',
    this.location,
    this.locationUpdatedAt,
    this.isOnline = false,
    this.lastSeen,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      bio: map['bio'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      location: map['location'] as GeoPoint?,
      locationUpdatedAt: (map['locationUpdatedAt'] as Timestamp?)?.toDate(),
      isOnline: map['isOnline'] ?? false,
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      if (location != null) 'location': location,
      'locationUpdatedAt': FieldValue.serverTimestamp(),
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? bio,
    String? profileImageUrl,
    GeoPoint? location,
    bool? isOnline,
  }) {
    return UserModel(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      location: location ?? this.location,
      locationUpdatedAt: locationUpdatedAt,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen,
    );
  }
}
