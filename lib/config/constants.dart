class AppConstants {
  // App Info
  static const String appName = 'MR7';
  static const String appFullName = 'MR7 Chat';
  static const String appVersion = '1.0.0';

  // Developer
  static const String devName = 'جلال';
  static const String devUsername = 'A1';
  static const String devPassword = '5cd9e55dcaf491d32289b848adeb216e';
  static const String devWebsite = 'https://black3web.github.io/Blackweb/';
  static const String devTelegram = 'https://t.me/swc_t';
  static const String devId = '000000000000001';

  // AI API Endpoints
  static const String geminiApiUrl = 'http://de3.bot-hosting.net:21007/kilwa-chat';
  static const String imageGenApiUrl = 'http://de3.bot-hosting.net:21007/kilwa-img';
  static const String videoGenApiUrl = 'http://de3.bot-hosting.net:21007/kilwa-video';
  static const String deepSeekApiUrl = 'https://zecora0.serv00.net/deepseek.php';
  static const String nanoBananaProUrl = 'https://zecora0.serv00.net/ai/NanoBanana.php';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String messagesCollection = 'messages';
  static const String groupsCollection = 'groups';
  static const String storiesCollection = 'stories';
  static const String chatsCollection = 'chats';
  static const String supportCollection = 'support';
  static const String broadcastsCollection = 'broadcasts';
  static const String aiLogsCollection = 'ai_logs';
  static const String stickersCollection = 'stickers';
  static const String reactionsCollection = 'reactions';
  static const String notificationsCollection = 'notifications';

  // Story settings
  static const int storyDurationHours = 48;
  static const int maxStoriesPerCycle = 3;
  static const int maxStoryVideoDurationSeconds = 300; // 5 min

  // Message limits
  static const int maxMessageLength = 5000;
  static const int maxStickerVideoSeconds = 15;
  static const int maxStickersPerPack = 250;

  // Username validation
  static const int minUsernameLength = 4;
  static const int maxUsernameLength = 25;
  static const int minPasswordLength = 4;
  static const int maxPasswordLength = 100;
  static const int minNameLength = 1;
  static const int maxNameLength = 50;
  static const String usernameRegex = r'^[a-zA-Z0-9_-]+$';

  // User ID
  static const int userIdLength = 15;

  // AI Models
  static const Map<String, String> deepSeekModels = {
    '1': 'DeepSeek V3.2',
    '2': 'DeepSeek R1',
    '3': 'DeepSeek Coder',
  };

  // Image ratios
  static const List<String> imageRatios = ['1:1', '16:9', '9:16', '4:3', '3:4'];
  static const List<String> imageResolutions = ['1K', '2K', '4K'];

  // Reaction emojis
  static const List<String> reactions = [
    '🌹', '🫶', '❤', '💋', '♥', '😂', '🤣', '🌚', '🙂', '🗿',
    '❌', '💔', '🫀', '😁', '😑', '😉', '😕', '😯', '😮\u200d💨', '☹️',
    '✅', '🤖', '⚡', '❓', '🚀', '💘', '🌀', '🫠', '😨', '☠️',
    '💕', '✋', '🌷', '📓', '🤤', '👆', '❤️\u200d🩹', '📜', '😪', '👤',
    '🤏', '🙃', '‼️', '🥷', '🎶', '🦔', '✨', '🔫', '🤌', '😍',
    '👑', '🔥', '✌', '🥀', '💎', '🧑', '👏', '🎉', '👍', '☝',
    '🥱', '😱', '😒', '🫤', '😔', '💀', '😚', '🥲', '🫂', '👌',
    '😘', '🤨', '💪', '😀', '💍', '❤️\u200d🔥', '💐', '😶', '☕', '🌱',
    '💗', '🌸', '🥹', '🫦', '😃', '💖', '🤩', '😊',
  ];

  // Available background colors for user avatars
  static const List<int> avatarColors = [
    0xFF8B0000, 0xFF1565C0, 0xFF2E7D32, 0xFF6A1B9A,
    0xFF00838F, 0xFFEF6C00, 0xFFAD1457, 0xFF37474F,
    0xFF4E342E, 0xFF004D40, 0xFF1B5E20, 0xFF1A237E,
  ];

  // SharedPreferences keys
  static const String prefLanguage = 'language';
  static const String prefTheme = 'theme';
  static const String prefCurrentUser = 'current_user';
  static const String prefAccounts = 'accounts';
  static const String prefChatBackground = 'chat_background';
  static const String prefFcmToken = 'fcm_token';
}
