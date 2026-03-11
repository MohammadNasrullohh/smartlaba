import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreScope {
  final String userUid;
  final String role;
  final String ownerUid;
  final String activeStoreId;
  final String activeStoreName;
  final String dataOwnerUid;
  final bool ownerHasMultipleStores;

  const FirestoreScope({
    required this.userUid,
    required this.role,
    required this.ownerUid,
    required this.activeStoreId,
    required this.activeStoreName,
    required this.dataOwnerUid,
    required this.ownerHasMultipleStores,
  });
}

Future<FirestoreScope?> resolveCurrentFirestoreScope({
  FirebaseFirestore? firestore,
  FirebaseAuth? auth,
}) async {
  final resolvedFirestore = firestore ?? FirebaseFirestore.instance;
  final resolvedAuth = auth ?? FirebaseAuth.instance;
  final currentUser = resolvedAuth.currentUser;
  if (currentUser == null) {
    return null;
  }

  final userDoc = await resolvedFirestore
      .collection('users')
      .doc(currentUser.uid)
      .get();
  final userData = userDoc.data() ?? const <String, dynamic>{};
  final role = readTrimmedStringValue(userData['role'], fallback: 'Owner');
  final ownerUid = role == 'Kasir'
      ? readTrimmedStringValue(userData['ownerUid'])
      : currentUser.uid;

  var activeStoreId = readTrimmedStringValue(userData['storeId']);
  var activeStoreName = readTrimmedStringValue(userData['storeName']);

  var ownerHasMultipleStores = false;
  if (ownerUid.isNotEmpty) {
    final storesSnapshot = await resolvedFirestore
        .collection('stores')
        .where('ownerUid', isEqualTo: ownerUid)
        .limit(2)
        .get();
    ownerHasMultipleStores = storesSnapshot.docs.length > 1;

    if (activeStoreId.isEmpty && storesSnapshot.docs.length == 1) {
      final storeDoc = storesSnapshot.docs.first;
      final storeData = storeDoc.data();
      activeStoreId = storeDoc.id;
      activeStoreName = readTrimmedStringValue(storeData['name']);
    }
  }

  final dataOwnerUid = ownerUid.isNotEmpty ? ownerUid : currentUser.uid;

  return FirestoreScope(
    userUid: currentUser.uid,
    role: role,
    ownerUid: ownerUid,
    activeStoreId: activeStoreId,
    activeStoreName: activeStoreName,
    dataOwnerUid: dataOwnerUid,
    ownerHasMultipleStores: ownerHasMultipleStores,
  );
}

bool matchesOwnerScopedRecord({
  required String recordOwnerUid,
  required String ownerUid,
}) {
  if (ownerUid.isEmpty) {
    return true;
  }

  return recordOwnerUid.isNotEmpty && recordOwnerUid == ownerUid;
}

bool matchesStoreScopedRecord({
  required String recordOwnerUid,
  required String recordStoreId,
  required FirestoreScope scope,
  bool includeLegacyOwnerFallback = false,
}) {
  if (scope.ownerUid.isNotEmpty &&
      recordOwnerUid.isNotEmpty &&
      recordOwnerUid != scope.ownerUid) {
    return false;
  }

  if (scope.activeStoreId.isNotEmpty) {
    if (recordStoreId.isNotEmpty) {
      return recordStoreId == scope.activeStoreId;
    }

    if (!includeLegacyOwnerFallback) {
      return false;
    }

    if (scope.ownerHasMultipleStores) {
      return false;
    }

    if (recordOwnerUid.isNotEmpty) {
      return recordOwnerUid == scope.ownerUid;
    }

    return true;
  }

  if (scope.ownerUid.isNotEmpty && recordOwnerUid.isNotEmpty) {
    return recordOwnerUid == scope.ownerUid;
  }

  return true;
}

bool matchesScopedSubcollectionData({
  required Map<String, dynamic> data,
  required FirestoreScope scope,
  bool includeLegacyWhenStoreSelected = true,
}) {
  return matchesStoreScopedRecord(
    recordOwnerUid: readTrimmedStringValue(data['ownerUid']),
    recordStoreId: readTrimmedStringValue(data['storeId']),
    scope: scope,
    includeLegacyOwnerFallback: includeLegacyWhenStoreSelected,
  );
}

Map<String, dynamic> buildScopedWriteData(FirestoreScope scope) {
  final data = <String, dynamic>{};

  if (scope.ownerUid.isNotEmpty) {
    data['ownerUid'] = scope.ownerUid;
  }
  if (scope.activeStoreId.isNotEmpty) {
    data['storeId'] = scope.activeStoreId;
  }
  if (scope.activeStoreName.isNotEmpty) {
    data['storeName'] = scope.activeStoreName;
  }

  return data;
}

String readTrimmedStringValue(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
  if (value is num) {
    return value.toString();
  }
  return fallback;
}
