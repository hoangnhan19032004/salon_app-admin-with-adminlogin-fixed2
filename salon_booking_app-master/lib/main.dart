import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:salon_app/l10n/app_localizations.dart';
import 'package:salon_app/provider/user_provider.dart';
import 'package:salon_app/screens/introduction/spalsh_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase trong project này đang cấu hình theo Android (google-services.json).
  // Nếu bạn chạy Web/Windows sẽ cần cấu hình riêng (firebase_options.dart / platform support).
  if (kIsWeb) {
    runApp(const _PlatformNotSupportedApp(platformName: "Web"));
    return;
  }

  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Nếu thiếu config Firebase, vẫn cho app chạy để hiển thị hướng dẫn.
    runApp(const _FirebaseInitFailedApp());
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Salon App',
        // ✅ Localization
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        theme: ThemeData(primarySwatch: Colors.blue),

        // ✅ Routes để ProfileScreen có thể Navigator.pushNamedAndRemoveUntil('/')
        routes: {
          '/': (_) => const SplashScreen(),
        },
        initialRoute: '/',
      ),
    );
  }
}

class _PlatformNotSupportedApp extends StatelessWidget {
  final String platformName;
  const _PlatformNotSupportedApp({required this.platformName});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "Nền tảng $platformName chưa được cấu hình cho Firebase trong project này.\n\n"
              "Hãy chạy app trên Android (emulator/điện thoại).\n"
              "Nếu bạn muốn chạy Web: cần cấu hình Firebase Web (firebase_options.dart) và thêm web config trong Firebase Console.",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _FirebaseInitFailedApp extends StatelessWidget {
  const _FirebaseInitFailedApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Không khởi tạo được Firebase.\n\n"
              "Kiểm tra lại: android/app/google-services.json,\n"
              "build.gradle đã apply plugin google-services,\n"
              "và bạn đã bật Firebase cho project.\n\n"
              "Xem thêm hướng dẫn trong file SETUP.md.",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
