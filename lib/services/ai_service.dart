import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // روابط الـ API
  static const String _geminiUrl = 'http://de3.bot-hosting.net:21007/kilwa-chat';
  static const String _imageNanoUrl = 'http://de3.bot-hosting.net:21007/kilwa-img';
  static const String _videoKilwaUrl = 'http://de3.bot-hosting.net:21007/kilwa-video';
  static const String _deepSeekUrl = 'https://zecora0.serv00.net/deepseek.php';
  static const String _nanoBananaProUrl = 'https://zecora0.serv00.net/ai/NanoBanana.php';
  static const String _seedanceUrl = 'https://zecora0.serv00.net/ai/Seedance.php';

  // التحقق من حالة الخدمة من Firestore
  Future<bool> _isServiceEnabled(String service) async {
    try {
      final doc = await _db.collection('settings').doc('ai_services').get();
      if (!doc.exists) return true;
      final data = doc.data() as Map<String, dynamic>;
      return data[service] ?? true;
    } catch (_) {
      return true;
    }
  }

  // تسجيل الاستخدام في السجلات
  Future<void> _log(String userId, String service, String prompt, bool success, [Map<String, dynamic>? extra]) async {
    try {
      await _db.collection('ai_logs').add({
        'userId': userId,
        'service': service,
        'prompt': prompt,
        'success': success,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        if (extra != null) 'extra': extra,
      });
    } catch (_) {}
  }

  // دالة Gemini Chat (متوافقة مع gemini_chat_screen.dart)
  Future<String> geminiChat(String message, String userId) async {
    if (!await _isServiceEnabled('gemini')) throw Exception('الخدمة معطلة حالياً');
    try {
      final response = await http.get(
        Uri.parse('$_geminiUrl?text=${Uri.encodeComponent(message)}'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          await _log(userId, 'gemini', message, true);
          return data['reply'] as String;
        }
      }
      throw Exception('فشل الرد من السيرفر');
    } catch (e) {
      await _log(userId, 'gemini', message, false);
      rethrow;
    }
  }

  // دالة DeepSeek Chat (متوافقة مع deepseek_chat_screen.dart)
  Future<Map<String, dynamic>> deepSeekChat(String message, String userId, {String model = '1', String? conversationId}) async {
    if (!await _isServiceEnabled('deepseek')) throw Exception('الخدمة معطلة حالياً');
    try {
      final body = <String, String>{
        'model': model,
        'message': message,
      };
      if (conversationId != null) body['conversation_id'] = conversationId;

      final response = await http.post(
        Uri.parse(_deepSeekUrl),
        body: body,
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await _log(userId, 'deepseek', message, true, {'model': model});
          return {
            'response': data['response'] as String,
            'conversation_id': data['conversation_id'] as String,
          };
        }
      }
      throw Exception('خطأ في معالجة DeepSeek');
    } catch (e) {
      await _log(userId, 'deepseek', message, false);
      rethrow;
    }
  }

  // دالة توليد الصور
  Future<String> generateImage(String prompt, String userId) async {
    if (!await _isServiceEnabled('imageGen')) throw Exception('الخدمة معطلة حالياً');
    try {
      final response = await http.get(
        Uri.parse('$_imageNanoUrl?prompt=${Uri.encodeComponent(prompt)}'),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          await _log(userId, 'imageGen', prompt, true);
          return data['image_url'] as String;
        }
      }
      throw Exception('فشل توليد الصورة');
    } catch (e) {
      await _log(userId, 'imageGen', prompt, false);
      rethrow;
    }
  }

  // دالة توليد الفيديو
  Future<String> generateVideo(String prompt, String userId) async {
    if (!await _isServiceEnabled('videoGenKilwa')) throw Exception('الخدمة معطلة حالياً');
    try {
      final response = await http.get(
        Uri.parse('$_videoKilwaUrl?prompt=${Uri.encodeComponent(prompt)}'),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          await _log(userId, 'videoGenKilwa', prompt, true);
          return data['video_url'] as String;
        }
      }
      throw Exception('فشل توليد الفيديو');
    } catch (e) {
      await _log(userId, 'videoGenKilwa', prompt, false);
      rethrow;
    }
  }

  // الحصول على إعدادات الخدمات (للإدارة)
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
    } catch (_) {
      return _defaults();
    }
  }

  Map<String, bool> _defaults() => {
    'gemini': true,
    'deepseek': true,
    'imageGen': true,
    'nanoBananaPro': true,
    'videoGenKilwa': true,
    'seedance': true,
  };

  // إحصائيات الاستخدام
  Future<Map<String, int>> getUsageStats() async {
    final stats = <String, int>{
      'gemini': 0,
      'deepseek': 0,
      'imageGen': 0,
      'nanoBananaPro': 0,
      'videoGenKilwa': 0,
      'seedance': 0,
      'total': 0
    };
    try {
      final snap = await _db.collection('ai_logs').get();
      for (final d in snap.docs) {
        final s = d.data()['service'] as String? ?? '';
        if (stats.containsKey(s)) {
          stats[s] = (stats[s] ?? 0) + 1;
        }
      }
      stats['total'] = snap.docs.length;
      return stats;
    } catch (_) {
      return stats;
    }
  }
}
