import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/plant_model.dart';
import '../firebase/firestore_service.dart';
import '../../core/constants/app_constants.dart';

class PlantApiService {
  final _firestore = FirebaseFirestore.instance;
  final _firestoreService = FirestoreService(); // ✅ thêm dòng này

  // ✅ Thêm cây mới và gán đúng userId
  Future<String?> addPlant(PlantModel plant) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final docRef = _firestore.collection(AppConstants.plantsCollection).doc();

    await docRef.set({
      'id': docRef.id,
      'userId': user.uid,
      'name': plant.name,
      'species': plant.species,
      'description': plant.description,
      'imageUrl': plant.imageUrl,
      'plantedDate': Timestamp.fromDate(plant.plantedDate),
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    // --- LỖI CỦA BẠN LÀ THIẾU DÒNG NÀY ---
    return docRef.id; // <-- BẮT BUỘC PHẢI RETURN ID
  }

  // ✅ Cập nhật cây
  Future<bool> updatePlant(String plantId, PlantModel plant) async {
    try {
      return await _firestoreService.updateDocument(
        AppConstants.plantsCollection,
        plantId,
        plant.toMap(),
      );
    } catch (e) {
      print('Error updating plant: $e');
      return false;
    }
  }

  // ✅ Xoá cây
  Future<bool> deletePlant(String plantId) async {
    try {
      return await _firestoreService.deleteDocument(
        AppConstants.plantsCollection,
        plantId,
      );
    } catch (e) {
      print('Error deleting plant: $e');
      return false;
    }
  }

  // ✅ Lấy cây theo ID
  Future<PlantModel?> getPlant(String plantId) async {
    try {
      var data = await _firestoreService.getDocument(
        AppConstants.plantsCollection,
        plantId,
      );
      if (data != null) {
        // --- CẢI TIẾN (NÊN LÀM) ---
        // Gán ID từ doc.id để phòng trường hợp data không có field 'id'
        data['id'] = plantId; 
        return PlantModel.fromMap(data);
      }
      return null;
    } catch (e) {
      print('Error getting plant: $e');
      return null;
    }
  }

  // ✅ Lấy danh sách cây theo userId
  Future<List<PlantModel>> getPlantsByUserId(String userId) async {
    try {
      var data = await _firestoreService.queryCollection(
        AppConstants.plantsCollection,
        'userId',
        userId,
      );
      
      // --- CẢI TIẾN (NÊN LÀM) ---
      // Gán 'id' từ doc.id vào data map
      // (Giả sử queryCollection trả về List<QueryDocumentSnapshot> 
      // hoặc bạn cần sửa _firestoreService để nó làm việc này)
      //
      // Nếu _firestoreService.queryCollection trả về List<Map<String, dynamic>>
      // thì bạn cần đảm bảo service đó đã gán doc.id vào map.
      // Nếu không, 'id' trong PlantModel.fromMap(item) có thể bị rỗng.
      
      return data.map((item) => PlantModel.fromMap(item)).toList();
    } catch (e) {
      print('Error getting plants: $e');
      return [];
    }
  }

  // ✅ Tìm kiếm cây
  Future<List<PlantModel>> searchPlants(String userId, String query) async {
    try {
      var plants = await getPlantsByUserId(userId);
      return plants
          .where((plant) =>
              plant.name.toLowerCase().contains(query.toLowerCase()) ||
              plant.species.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      print('Error searching plants: $e');
      return [];
    }
  }
}