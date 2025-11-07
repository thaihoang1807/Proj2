import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ Add document
  Future<String?> addDocument(String collection, Map<String, dynamic> data) async {
    try {
      var docRef = await _db.collection(collection).add(data);
      print('✅ Added document to $collection: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error adding document: $e');
      return null;
    }
  }

  // ✅ Update document
  Future<bool> updateDocument(
      String collection, String docId, Map<String, dynamic> data) async {
    try {
      await _db.collection(collection).doc(docId).update(data);
      print('✅ Updated document $docId in $collection');
      return true;
    } catch (e) {
      print('❌ Error updating document: $e');
      return false;
    }
  }

  // ✅ Delete document
  Future<bool> deleteDocument(String collection, String docId) async {
    try {
      await _db.collection(collection).doc(docId).delete();
      print('✅ Deleted document $docId from $collection');
      return true;
    } catch (e) {
      print('❌ Error deleting document: $e');
      return false;
    }
  }

  // ✅ Get one document
  Future<Map<String, dynamic>?> getDocument(String collection, String docId) async {
    try {
      var doc = await _db.collection(collection).doc(docId).get();
      if (doc.exists) {
        print('✅ Got document $docId from $collection');
        return {...doc.data()!, 'id': doc.id};
      }
      return null;
    } catch (e) {
      print('❌ Error getting document: $e');
      return null;
    }
  }

  // ✅ Get all documents in a collection
  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    try {
      var snapshot = await _db.collection(collection).get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      print('❌ Error getting collection: $e');
      return [];
    }
  }

  // ✅ Query by field (ví dụ: userId)
  Future<List<Map<String, dynamic>>> queryCollection(
      String collection, String field, dynamic value) async {
    try {
      var snapshot =
          await _db.collection(collection).where(field, isEqualTo: value).get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      print('❌ Error querying collection: $e');
      return [];
    }
  }

  // ✅ Stream collection
  Stream<List<Map<String, dynamic>>> streamCollection(String collection) {
    return _db.collection(collection).snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  // ✅ Stream one document
  Stream<Map<String, dynamic>?> streamDocument(String collection, String docId) {
    return _db.collection(collection).doc(docId).snapshots().map(
        (doc) => doc.data() != null ? {...doc.data()!, 'id': doc.id} : null);
  }
}
