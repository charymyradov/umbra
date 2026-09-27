import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore dokümanını model `fromJson`'ına uygun map'e çevirir:
/// doküman id'si `id` alanına yazılır, `Timestamp` alanları ISO-8601
/// string'e çözülür (modeller tarihleri string olarak okur).
///
/// Tarih alanları ISO-8601 UTC string olarak yazılır ve sıralama istemci
/// tarafında yapılır. Böylece sorgular tek alan (`user_id`) eşitlik filtresiyle
/// sınırlı kalır; composite index kurulumu gerekmez.
Map<String, dynamic> docData(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = <String, dynamic>{...?doc.data(), 'id': doc.id};
  return data.map((key, value) => MapEntry(key, _decode(value)));
}

/// Alan adı ve değer verilmiş ham map — model `fromJson`'ı için hazır.
Map<String, dynamic> mapData(Map<String, dynamic> data) =>
    data.map((key, value) => MapEntry(key, _decode(value)));

Object? _decode(Object? value) {
  if (value is Timestamp) return value.toDate().toUtc().toIso8601String();
  if (value is Map) {
    return value.map((Object? k, Object? v) => MapEntry(k.toString(), _decode(v)));
  }
  if (value is List) return value.map(_decode).toList();
  return value;
}

/// Yerel tarih → Firestore'a yazılacak ISO-8601 UTC string.
String isoNow() => DateTime.now().toUtc().toIso8601String();

String isoOf(DateTime time) => time.toUtc().toIso8601String();
