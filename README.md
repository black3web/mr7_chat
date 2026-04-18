# MR7 Chat - تطبيق شات متكامل مع الذكاء الاصطناعي

## نظرة عامة
تطبيق Flutter يعمل على الويب والاندرويد معاً، يتضمن:
- نظام مراسلة فوري (خاص + مجموعات)
- قصص (Stories) مع فيديو وصور
- 5 خدمات ذكاء اصطناعي
- لوحة تحكم المدير
- دعم عربي/انجليزي كامل
- ثيم احمر داكن وأسود فاخر

## خدمات الذكاء الاصطناعي
1. **Gemini 2.5 Flash** - محادثة ذكاء اصطناعي متقدمة
2. **DeepSeek** - V3.2 / R1 / Coder مع ذاكرة
3. **Nano Banana 2** - توليد صور 2K
4. **NanoBanana Pro** - توليد وتعديل صور 1K/2K/4K
5. **Seedance AI** - توليد فيديو (1.0 Lite / 1.0 Pro / 1.5 Pro)
   - نص-الى-فيديو
   - صورة-الى-فيديو
   - دقة 480p/720p، نسب 16:9/9:16/1:1/4:3/3:4/21:9

## حساب المطور
- يوزر: A1
- الرقم السري: 5cd9e55dcaf491d32289b848adeb216e
- يوفر لوحة تحكم كاملة للادارة

## متطلبات التشغيل
- Flutter SDK 3.0+
- Firebase Project: mr7-chat (مضبوط مسبقاً)
- Android minSdk: 21

## تشغيل المشروع
```bash
flutter pub get
flutter run -d chrome    # للويب
flutter run -d android   # للاندرويد
flutter build apk        # بناء APK
flutter build web        # بناء ويب
```

## هيكل المشروع
```
lib/
├── main.dart
├── firebase_options.dart
├── config/
│   ├── theme.dart          # ثيم احمر داكن
│   ├── constants.dart      # ثوابت + APIs
│   └── routes.dart
├── l10n/app_localizations.dart  # عربي/انجليزي
├── models/                 # User/Message/Group/Story/Sticker
├── services/               # Auth/Chat/Group/Story/AI/Storage/Admin
├── providers/app_provider.dart
├── widgets/               # GlassContainer/UserAvatar/Logo/Background
└── screens/
    ├── home/              # HomeScreen + Drawer + Stories + Broadcast
    ├── auth/              # Login + Register
    ├── chat/              # Private + Group chat
    ├── profile/           # Profile + Edit + UserProfile
    ├── ai/                # Gemini/DeepSeek/ImageGen/VideoGen(Seedance)
    ├── stories/           # View + Add story
    ├── settings/          # كامل مع ثيم وخصوصية
    ├── search/            # بحث مستخدمين ومجموعات
    ├── support/           # دعم فني
    └── admin/             # لوحة تحكم كاملة
```
