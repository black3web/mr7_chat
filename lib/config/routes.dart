import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/language_select_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/chat/group_chat_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/stories/story_view_screen.dart';
import '../screens/stories/add_story_screen.dart';
import '../screens/ai/gemini_chat_screen.dart'; // هذا الملف أصبح يحتوي على شاشتي Gemini و DeepSeek
import '../screens/ai/image_gen_screen.dart';
import '../screens/ai/video_gen_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/support/support_screen.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/search/search_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String languageSelect = '/language';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String chat = '/chat';
  static const String groupChat = '/group-chat';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String userProfile = '/user-profile';
  static const String storyView = '/story-view';
  static const String addStory = '/add-story';
  static const String geminiChat = '/ai/gemini';
  static const String deepSeekChat = '/ai/deepseek';
  static const String imageGen = '/ai/image-gen';
  static const String imageGenPro = '/ai/image-gen-pro';
  static const String videoGen = '/ai/video-gen';
  static const String settings = '/settings';
  static const String support = '/support';
  static const String admin = '/admin';
  static const String search = '/search';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    languageSelect: (_) => const LanguageSelectScreen(),
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    home: (_) => const HomeScreen(),
    profile: (_) => const ProfileScreen(),
    editProfile: (_) => const EditProfileScreen(),
    settings: (_) => const SettingsScreen(),
    support: (_) => const SupportScreen(),
    admin: (_) => const AdminScreen(),
    search: (_) => const SearchScreen(),
    geminiChat: (_) => const GeminiChatScreen(),
    deepSeekChat: (_) => const DeepSeekChatScreen(), // تم ربطها بنجاح الآن
    imageGen: (_) => const ImageGenScreen(),
    imageGenPro: (_) => const ImageGenScreen(),
    videoGen: (_) => const VideoGenScreen(),
    addStory: (_) => const AddStoryScreen(),
  };

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case chat:
        final args = settings.arguments as Map<String, dynamic>;
        return _route(ChatScreen(chatId: args['chatId'], otherUserId: args['otherUserId']));
      case groupChat:
        final args = settings.arguments as Map<String, dynamic>;
        return _route(GroupChatScreen(groupId: args['groupId']));
      case userProfile:
        final args = settings.arguments as Map<String, dynamic>;
        return _route(UserProfileScreen(userId: args['userId']));
      case storyView:
        final args = settings.arguments as Map<String, dynamic>;
        return _route(StoryViewScreen(stories: args['stories'], initialIndex: args['initialIndex'] ?? 0));
      default:
        return _route(const SplashScreen());
    }
  }

  static PageRouteBuilder _route(Widget child) {
    return PageRouteBuilder(
      pageBuilder: (_, anim, __) => child,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 280),
    );
  }
}
