import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();
  final _picker = ImagePicker();

  // Pick image from gallery
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    return await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
  }

  // Pick video
  Future<XFile?> pickVideo({ImageSource source = ImageSource.gallery}) async {
    return await _picker.pickVideo(source: source);
  }

  // Upload profile photo
  Future<String> uploadProfilePhoto(XFile file) async {
    final fileName = '${_uuid.v4()}${path.extension(file.name)}';
    final ref = _storage.ref().child('profile_photos/$fileName');

    UploadTask task;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      task = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      task = ref.putFile(File(file.path));
    }

    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  // Upload chat media
  Future<String> uploadMedia(XFile file, String chatId) async {
    final ext = path.extension(file.name);
    final fileName = '${_uuid.v4()}$ext';
    final ref = _storage.ref().child('chat_media/$chatId/$fileName');

    UploadTask task;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      task = ref.putData(bytes);
    } else {
      task = ref.putFile(File(file.path));
    }

    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  // Upload bytes (for generated stickers etc)
  Future<String> uploadBytes(Uint8List bytes, String folder, String extension) async {
    final fileName = '${_uuid.v4()}.$extension';
    final ref = _storage.ref().child('$folder/$fileName');
    final task = ref.putData(bytes);
    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  // Upload story media
  Future<String> uploadStoryMedia(XFile file, String userId) async {
    final ext = path.extension(file.name);
    final fileName = '${_uuid.v4()}$ext';
    final ref = _storage.ref().child('stories/$userId/$fileName');

    UploadTask task;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      task = ref.putData(bytes);
    } else {
      task = ref.putFile(File(file.path));
    }

    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  // Upload sticker
  Future<String> uploadSticker(XFile file, String userId, String packId) async {
    final ext = path.extension(file.name);
    final fileName = '${_uuid.v4()}$ext';
    final ref = _storage.ref().child('stickers/$userId/$packId/$fileName');

    UploadTask task;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      task = ref.putData(bytes);
    } else {
      task = ref.putFile(File(file.path));
    }

    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  // Upload group photo
  Future<String> uploadGroupPhoto(XFile file, String groupId) async {
    final fileName = '${_uuid.v4()}${path.extension(file.name)}';
    final ref = _storage.ref().child('group_photos/$groupId/$fileName');

    UploadTask task;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      task = ref.putData(bytes);
    } else {
      task = ref.putFile(File(file.path));
    }

    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  // Upload support image
  Future<String> uploadSupportImage(XFile file, String userId) async {
    final fileName = '${_uuid.v4()}${path.extension(file.name)}';
    final ref = _storage.ref().child('support/$userId/$fileName');

    UploadTask task;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      task = ref.putData(bytes);
    } else {
      task = ref.putFile(File(file.path));
    }

    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  // Delete file by URL
  Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}
