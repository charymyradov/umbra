import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/firestore_maps.dart';

/// `users/{uid}` dokümanı — doküman ID'si kullanıcının Auth UID'si.
class Profile {
  const Profile({
    required this.id,
    this.fullName,
    this.role,
    this.avatarUrl,
    this.createdAt,
  });

  final String id;
  final String? fullName;
  final String? role;
  final String? avatarUrl;
  final DateTime? createdAt;

  String get firstName {
    final n = (fullName ?? '').trim();
    if (n.isEmpty) return 'there';
    return n.split(' ').first;
  }

  String get initial {
    final n = (fullName ?? '').trim();
    return n.isEmpty ? 'U' : n[0].toUpperCase();
  }

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        fullName: json['full_name'] as String?,
        role: json['role'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        createdAt: DateTime.tryParse('${json['created_at']}')?.toLocal(),
      );
}

class ProfileRepository {
  ProfileRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<Profile?> fetch(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return null;
    return Profile.fromJson(docData(doc));
  }

  Future<void> upsert({
    required String userId,
    String? fullName,
    String? role,
  }) async {
    final ref = _users.doc(userId);
    final existing = await ref.get();
    await ref.set({
      'full_name': ?fullName,
      'role': ?role,
      'updated_at': isoNow(),
      if (!existing.exists) 'created_at': isoNow(),
    }, SetOptions(merge: true));
  }
}
