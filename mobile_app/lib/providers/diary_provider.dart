import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/diary_entry_model.dart';
import '../services/firebase/firestore_service.dart';
import '../services/firebase/storage_service.dart';

class DiaryProvider with ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final StorageService _storage = StorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<DiaryEntryModel> _entries = [];
  bool _isLoading = false;
  String? _error;

  List<DiaryEntryModel> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load diary entries from Firestore for a plant
  Future<void> loadEntries(String plantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // ✅ FIX QUAN TRỌNG: Thêm 'userId' vào query để khớp với Security Rules
      // Sử dụng trực tiếp FirebaseFirestore để query phức tạp (nếu service của bạn chưa hỗ trợ)
      final snapshot = await FirebaseFirestore.instance
          .collection('diary_entries')
          .where('userId', isEqualTo: user.uid) // Bắt buộc phải có dòng này
          .where('plantId', isEqualTo: plantId)
          .orderBy('createdAt', descending: true) // Sort ngay tại server
          .get();

      _entries = snapshot.docs.map((doc) {
         // Đảm bảo model của bạn có thể nhận ID từ doc.id nếu cần
         Map<String, dynamic> data = doc.data();
         data['id'] = doc.id; 
         return DiaryEntryModel.fromMap(data);
      }).toList();

      _error = null;
    } catch (e) {
      _error = 'Lỗi tải nhật ký: $e';
      print('Error loading diary entries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new diary entry with multiple images
  Future<bool> addEntry(DiaryEntryModel entry, {List<File>? imageFiles}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      List<String> imageUrls = [];

      // 1. Upload images if provided
      // Dùng một ID tạm hoặc ID thật nếu entry đã có để làm đường dẫn
      String tempEntryId = DateTime.now().millisecondsSinceEpoch.toString();
      if (imageFiles != null && imageFiles.isNotEmpty) {
        final basePath = 'diary/${user.uid}/$tempEntryId';
        imageUrls = await _storage.uploadMultipleImages(basePath, imageFiles);
      }

      // 2. Prepare data to save to Firestore
      final entryData = {
        // 'id': entry.id, // Không cần lưu ID vào field nếu dùng document ID tự sinh
        'activityType': entry.activityType,
        'content': entry.content,
        'plantId': entry.plantId,
        'userId': user.uid,        // ✅ Đảm bảo có userId
        'imageUrls': imageUrls,    // ✅ Dùng key thống nhất 'imageUrls'
        'createdAt': FieldValue.serverTimestamp(), // ✅ Dùng server timestamp
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 3. Save to Firestore (Chỉ gọi 1 lần!)
      await _firestore.addDocument('diary_entries', entryData);

      // 4. Reload entries
      await loadEntries(entry.plantId);

      _error = null;
      return true;
    } catch (e) {
      _error = 'Lỗi thêm nhật ký: $e';
      print('Error adding diary entry: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update diary entry
  Future<bool> updateEntry(String entryId, DiaryEntryModel entry, {List<File>? newImageFiles}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
       if (user == null) throw Exception("User not logged in");
       
      List<String> imageUrls = List.from(entry.imageUrls); // Copy list cũ để tránh lỗi tham chiếu

      // If new images provided, delete old and upload new
      // (Logic này của bạn sẽ xóa HẾT ảnh cũ nếu có ảnh mới. Bạn có chắc muốn vậy không?
      // Hay là muốn thêm ảnh mới vào ảnh cũ? Nếu muốn thay thế hoàn toàn thì OK)
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        for (String oldImageUrl in entry.imageUrls) {
           // Thêm kiểm tra để tránh lỗi nếu URL không đúng định dạng mong đợi
           if (oldImageUrl.isNotEmpty) {
              try { await _storage.deleteImage(oldImageUrl); } catch (e) { print('Lỗi xóa ảnh cũ: $e'); }
           }
        }
        final basePath = 'diary/${user.uid}/$entryId';
        imageUrls = await _storage.uploadMultipleImages(basePath, newImageFiles);
      }

      // Update entry in Firestore
      final updateData = {
        'activityType': entry.activityType,
        'content': entry.content,
        'imageUrls': imageUrls, // ✅ Đảm bảo dùng đúng key 'imageUrls' như lúc add
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.updateDocument('diary_entries', entryId, updateData);

      await loadEntries(entry.plantId);
      _error = null;
      return true;
    } catch (e) {
      _error = 'Lỗi cập nhật nhật ký: $e';
      print('Error updating diary entry: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete diary entry
  Future<bool> deleteEntry(String entryId, String plantId) async {
    // ... (Giữ nguyên logic của bạn, chỉ cần đảm bảo entry lấy ra là đúng)
     _isLoading = true;
    notifyListeners();

    try {
      // Tìm entry cần xóa để lấy danh sách ảnh
      final entryToDelete = _entries.firstWhere(
  (e) => e.id == entryId,
  orElse: () => DiaryEntryModel(
    id: '', 
    plantId: '', 
    userId: '', 
    activityType: '', 
    content: '', 
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(), // <--- THÊM DÒNG NÀY
    imageUrls: []
  )
);

      if (entryToDelete.id.isNotEmpty) {
         for (String imageUrl in entryToDelete.imageUrls) {
          try { await _storage.deleteImage(imageUrl); } catch (e) { print('Error deleting image: $e'); }
        }
      }

      await _firestore.deleteDocument('diary_entries', entryId);
      await loadEntries(plantId);

      _error = null;
      return true;
    } catch (e) {
      _error = 'Lỗi xóa nhật ký: $e';
      print('Error deleting diary entry: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ... Các hàm getter giữ nguyên
  List<DiaryEntryModel> getEntriesByType(String activityType) {
    return _entries.where((e) => e.activityType == activityType).toList();
  }

  List<DiaryEntryModel> getRecentEntries(int count) {
    return _entries.take(count).toList();
  }

  DiaryEntryModel? getEntryById(String entryId) {
    try {
      return _entries.firstWhere((e) => e.id == entryId);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}