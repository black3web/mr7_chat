import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _geminiUrl = 'http://de3.bot-hosting.net:21007/kilwa-chat';
  static const String _imageNanoUrl = 'http://de3.bot-hosting.net:21007/kilwa-img';
  static const String _videoKilwaUrl = 'http://de3.bot-hosting.net:21007/kilwa-video';
  static const String _deepSeekUrl = 'https://zecora0.serv00.net/deepseek.php';
  static const String _nanoBananaProUrl = 'https://zecora0.serv00.net/ai/NanoBanana.php';
  static const String _seedanceUrl = 'https://zecora0.serv00.net/ai/Seedance.php';

  // Available Seedance models
  static const List<Map<String, dynamic>> seedanceModels = [
    {
      'id': 'Seedance 1.5 Pro',
      'name': 'Seedance 1.5 Pro',
      'durations': [4, 8, 12],
      'resolutions': ['480p', '720p'],
      'ratios': ['16:9', '9:16', '1:1', '4:3', '3:4', '21:9'],
      'supportsImageInput': true,
      'hasAudio': false,
    },
    {
      'id': 'Seedance 1.0 Pro',
      'name': 'Seedance 1.0 Pro',
      'durations': [5, 10],
      'resolutions': ['480p', '720p'],
      'ratios': ['16:9', '9:16', '1:1', '4:3', '3:4', '21:9'],
      'supportsImageInput': true,
      'hasAudio': false,
    },
    {
      'id': 'Seedance 1.0 Lite',
      'name': 'Seedance 1.0 Lite',
      'durations': [5, 10],
      'resolutions': ['480p', '720p'],
      'ratios': ['16:9', '9:16', '1:1', '4:3', '3:4', '21:9'],
      'supportsImageInput': true,
      'hasAudio': false,
    },
  ];

  static const List<String> imageRatios = ['1:1', '16:9', '9:16', '4:3', '3:4'];
  static const List<String> imageResolutions = ['1K', '2K', '4K'];
  static const List<Map<String, String>> deepSeekModels = [
    {'id': '1', 'name': 'DeepSeek V3.2'},
    {'id': '2', 'name': 'DeepSeek R1'},
    {'id': '3', 'name': 'DeepSeek Coder'},
  ];

  Future<bool> _isServiceEnabled(String service) async {
    try {
      final doc = await _db.collection('settings').doc('ai_services').get();
      if (!doc.exists) return true;
      return (doc.data() as Map<String, dynamic>)[service] ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> _log(String userId, String service, String prompt, bool success, [Map<String, dynamic>? extra]) async {
    try {
      await _db.collection('ai_logs').add({
        'userId': userId,
        'service': service,
        'prompt': prompt,
        'success': success,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'extra': extra,
      });
    } catch (_) {}
  }

  // Gemini Chat
  Future<String> geminiChat(String message, String userId) async {
    if (!await _isServiceEnabled('gemini')) throw Exception('الخدمة غير متاحة حاليا');
    try {
      final res = await http.get(
        Uri.parse('$_geminiUrl?text=${Uri.encodeComponent(message)}'),
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          await _log(userId, 'gemini', message, true);
          return data['reply'] as String;
        }
      }
      throw Exception('حدث خطأ في المعالجة');
    } catch (e) {
      await _log(userId, 'gemini', message, false);
      if (e.toString().contains('حدث خطأ')) rethrow;
      throw Exception('تعذر الاتصال بالخدمة');
    }
  }

  // DeepSeek Chat
  Future<Map<String, dynamic>> deepSeekChat(String message, String userId, {String model = '1', String? conversationId}) async {
    if (!await _isServiceEnabled('deepseek')) throw Exception('الخدمة غير متاحة حاليا');
    try {
      final body = <String, String>{'model': model, 'message': message};
      if (conversationId != null) body['conversation_id'] = conversationId;
      final res = await http.post(Uri.parse(_deepSeekUrl), body: body).timeout(const Duration(seconds: 45));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          await _log(userId, 'deepseek', message, true, {'model': model});
          return {'response': data['response'] as String, 'conversation_id': data['conversation_id'] as String};
        }
      }
      throw Exception('حدث خطأ في المعالجة');
    } catch (e) {
      await _log(userId, 'deepseek', message, false);
      if (e.toString().contains('حدث خطأ')) rethrow;
      throw Exception('تعذر الاتصال بالخدمة');
    }
  }

  // Generate image with Nano Banana 2
  Future<String> generateImageNano(String prompt, String userId) async {
    if (!await _isServiceEnabled('imageGen')) throw Exception('الخدمة غير متاحة حاليا');
    try {
      final res = await http.get(
        Uri.parse('$_imageNanoUrl?text=${Uri.encodeComponent(prompt)}'),
      ).timeout(const Duration(seconds: 60));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success' && data['image_url'] != null) {
          await _log(userId, 'imageGen', prompt, true, {'url': data['image_url']});
          return data['image_url'] as String;
        }
      }
      throw Exception('فشل توليد الصورة');
    } catch (e) {
      await _log(userId, 'imageGen', prompt, false);
      if (e.toString().contains('فشل')) rethrow;
      throw Exception('تعذر الاتصال بالخدمة');
    }
  }

  // NanoBanana Pro - create or edit image
  Future<String> nanoBananaPro({
    required String prompt,
    required String userId,
    String ratio = '1:1',
    String resolution = '2K',
    String? imageUrl,
    List<String>? imageUrls,
  }) async {
    if (!await _isServiceEnabled('nanoBananaPro')) throw Exception('الخدمة غير متاحة حاليا');
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_nanoBananaProUrl));
      request.fields['text'] = prompt;
      request.fields['ratio'] = ratio;
      request.fields['res'] = resolution;
      if (imageUrls != null && imageUrls.isNotEmpty) {
        request.fields['links'] = imageUrls.length == 1 ? imageUrls.first : jsonEncode(imageUrls);
      } else if (imageUrl != null) {
        request.fields['links'] = imageUrl;
      }
      final streamed = await request.send().timeout(const Duration(seconds: 90));
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['url'] != null) {
          await _log(userId, 'nanoBananaPro', prompt, true, {'url': data['url'], 'mode': data['mode']});
          return data['url'] as String;
        }
      }
      throw Exception('فشل معالجة الصورة');
    } catch (e) {
      await _log(userId, 'nanoBananaPro', prompt, false);
      if (e.toString().contains('فشل')) rethrow;
      throw Exception('تعذر الاتصال بالخدمة');
    }
  }

  // Video generation with Kilwa API
  Future<String> generateVideoKilwa(String prompt, String userId) async {
    if (!await _isServiceEnabled('videoGen')) throw Exception('الخدمة غير متاحة حاليا');
    try {
      final res = await http.get(
        Uri.parse('$_videoKilwaUrl?text=${Uri.encodeComponent(prompt)}'),
      ).timeout(const Duration(seconds: 120));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success' && data['video_url'] != null) {
          await _log(userId, 'videoGenKilwa', prompt, true, {'url': data['video_url']});
          return data['video_url'] as String;
        }
      }
      throw Exception('فشل توليد الفيديو');
    } catch (e) {
      await _log(userId, 'videoGenKilwa', prompt, false);
      if (e.toString().contains('فشل')) rethrow;
      throw Exception('تعذر الاتصال بالخدمة');
    }
  }

  // Seedance Video Generation (text-to-video or image-to-video)
  Future<String> seedanceGenerate({
    required String prompt,
    required String userId,
    String model = 'Seedance 1.5 Pro',
    int duration = 8,
    String resolution = '720p',
    String aspectRatio = '16:9',
    String? imageUrl,
  }) async {
    if (!await _isServiceEnabled('seedance')) throw Exception('الخدمة غير متاحة حاليا');
    try {
      final body = <String, dynamic>{
        'prompt': prompt,
        'model': model,
        'duration': duration,
        'resolution': resolution,
        'aspect_ratio': aspectRatio,
      };
      if (imageUrl != null && imageUrl.isNotEmpty) {
        body['image_url'] = imageUrl;
      }
      final res = await http.post(
        Uri.parse(_seedanceUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 180));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final videoUrl = (data['data'] as Map<String, dynamic>?)?['video_url'] as String?;
          if (videoUrl != null && videoUrl.isNotEmpty) {
            await _log(userId, 'seedance', prompt, true, {'url': videoUrl, 'model': model, 'duration': duration});
            return videoUrl;
          }
        }
      }
      throw Exception('فشل توليد الفيديو');
    } catch (e) {
      await _log(userId, 'seedance', prompt, false);
      if (e.toString().contains('فشل')) rethrow;
      throw Exception('تعذر الاتصال بالخدمة');
    }
  }

  // Toggle a service on/off
  Future<void> toggleService(String service, bool enabled) async {
    await _db.collection('settings').doc('ai_services').set({service: enabled}, SetOptions(merge: true));
  }

  // Get service enabled states
  Future<Map<String, bool>> getServiceStates() async {
    try {
      final doc = await _db.collection('settings').doc('ai_services').get();
      if (!doc.exists) return _defaults();
      final d = doc.data() as Map<String, dynamic>;
      return {
        'gemini': d['gemini'] ?? true,
        'deepseek': d['deepseek'] ?? true,
        'imageGen': d['imageGen'] ?? true,
        'nanoBananaPro': d['nanoBananaPro'] ?? true,
        'videoGenKilwa': d['videoGenKilwa'] ?? true,
        'seedance': d['seedance'] ?? true,
      };
    } catch (_) { return _defaults(); }
  }

  Map<String, bool> _defaults() => {
    'gemini': true, 'deepseek': true, 'imageGen': true,
    'nanoBananaPro': true, 'videoGenKilwa': true, 'seedance': true,
  };

  Future<Map<String, int>> getUsageStats() async {
    final stats = <String, int>{'gemini': 0, 'deepseek': 0, 'imageGen': 0, 'nanoBananaPro': 0, 'videoGenKilwa': 0, 'seedance': 0, 'total': 0};
    try {
      final snap = await _db.collection('ai_logs').get();
      for (final d in snap.docs) {
        final s = d.data()['service'] as String? ?? '';
        if (stats.containsKey(s)) stats[s] = (stats[s] ?? 0) + 1;
        stats['total'] = (stats['total'] ?? 0) + 1;
      }
    } catch (_) {}
    return stats;
  }

  Stream<List<Map<String, dynamic>>> logsStream() {
    return _db.collection('ai_logs').orderBy('timestamp', descending: true).limit(200)
      .snapshots().map((s) => s.docs.map((d) => {...d.data(), 'docId': d.id}).toList());
  }
}