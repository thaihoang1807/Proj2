import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload image file (Giữ nguyên)
  Future<String?> uploadImage(String path, File file) async {
    try {
      var ref = _storage.ref().child(path);
      // Tùy chọn: Thêm metadata để đảm bảo file được xử lý đúng là ảnh
      var metadata = SettableMetadata(contentType: 'image/jpeg');
      var uploadTask = await ref.putFile(file, metadata);
      var downloadUrl = await uploadTask.ref.getDownloadURL();
      print('✅ Uploaded image to $path');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading image to $path: $e');
      rethrow;
    }
  }

  // Delete image (Giữ nguyên)
  Future<bool> deleteImage(String imageUrl) async {
    try {
      var ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('✅ Deleted image: $imageUrl');
      return true;
    } catch (e) {
      print('❌ Error deleting image: $e');
      // Có thể không cần rethrow nếu muốn tiếp tục xóa các ảnh khác dù 1 ảnh lỗi
      rethrow;
    }
  }

  // Upload multiple images (TỐI ƯU HÓA: Chạy song song)
  Future<List<String>> uploadMultipleImages(
    String basePath,
    List<File> files,
  ) async {
    if (files.isEmpty) return [];

    // Tạo danh sách các tác vụ upload
    List<Future<String?>> uploadTasks = [];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < files.length; i++) {
      // Thêm index 'i' để đảm bảo tên file KHÔNG BAO GIỜ trùng nhau
      String fileName = '${timestamp}_$i.jpg';
      String fullPath = '$basePath/$fileName';
      
      uploadTasks.add(uploadImage(fullPath, files[i]));
    }

    // Chạy tất cả tác vụ cùng lúc và chờ hoàn thành
    try {
      final results = await Future.wait(uploadTasks);
      // Lọc bỏ các kết quả null (nếu có lỗi upload 1 vài file)
      return results.whereType<String>().toList();
    } catch (e) {
      print('❌ Error during multiple upload: $e');
      rethrow;
    }
  }

  // Get download URL (Giữ nguyên)
  Future<String?> getDownloadUrl(String path) async {
    try {
      return await _storage.ref().child(path).getDownloadURL();
    } catch (e) {
      print('❌ Error getting download URL: $e');
      return null;
    }
  }
}