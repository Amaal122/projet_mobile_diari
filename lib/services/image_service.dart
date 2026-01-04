/// Image Service
/// ==============
/// Handles image picking and uploading to Firebase Storage
/// For dish images, profile photos, etc.

import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  static Future<XFile?> pickFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick image from camera
  static Future<XFile?> pickFromCamera() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  /// Upload image to Firebase Storage
  /// Returns the download URL
  static Future<String?> uploadImage({
    required Uint8List imageBytes,
    required String path,
    String? fileName,
  }) async {
    try {
      final name = fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(path).child(name);
      
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Upload dish image
  static Future<String?> uploadDishImage({
    required Uint8List imageBytes,
    required String chefId,
    String? dishId,
  }) async {
    final id = dishId ?? DateTime.now().millisecondsSinceEpoch.toString();
    return uploadImage(
      imageBytes: imageBytes,
      path: 'dishes/$chefId',
      fileName: '$id.jpg',
    );
  }

  /// Upload profile image
  static Future<String?> uploadProfileImage({
    required Uint8List imageBytes,
    required String userId,
  }) async {
    return uploadImage(
      imageBytes: imageBytes,
      path: 'profiles',
      fileName: '$userId.jpg',
    );
  }

  /// Delete image from Firebase Storage
  static Future<bool> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  /// Pick and upload dish image in one step
  static Future<String?> pickAndUploadDishImage({
    required String chefId,
    String? dishId,
    bool fromCamera = false,
  }) async {
    try {
      final XFile? image = fromCamera 
          ? await pickFromCamera() 
          : await pickFromGallery();
      
      if (image == null) return null;
      
      final bytes = await image.readAsBytes();
      return uploadDishImage(
        imageBytes: bytes,
        chefId: chefId,
        dishId: dishId,
      );
    } catch (e) {
      debugPrint('Error picking and uploading: $e');
      return null;
    }
  }
}
