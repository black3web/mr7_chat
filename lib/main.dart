import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'l10n/app_localizations.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize developer account
  await AuthService().initDevAccount();

  // Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0A0A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final provider = AppProvider();
  await provider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const MR7App(),
    ),
  );
}

class MR7App extends StatelessWidget {
  const MR7App({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return MaterialApp(
      title: 'MR7 Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: p.themeMode,
      locale: p.locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.generateRoute,
      builder: (context, child) {
        // Apply RTL/LTR globally based on language
        return Directionality(
          textDirection:
              p.language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
    );
  }
}
