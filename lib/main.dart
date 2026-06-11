import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'functions/functions.dart';
import 'functions/notifications.dart';
import 'pages/loadingPage/loadingpage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'styles/styles.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

final ValueNotifier<bool> themeNotifier = ValueNotifier(false);

// ── navigateur global pour deep links ──
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    await FirebaseAuth.instance.setLanguageCode('fr');
  } catch (e) {
    print("Firebase est déjà initialisé ou une erreur est survenue : $e");
  }

  checkInternetConnection();
  initMessaging();

  await SharedPreferences.getInstance().then((value) {
    bool savedTheme = value.getBool('isDarkTheme') ?? false;
    setTheme(savedTheme);
    themeNotifier.value = savedTheme;
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleLink(initialLink);
      }
    } catch (e) {
      print('Erreur deep link initial: $e');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
          (uri) => _handleLink(uri),
      onError: (e) => print('Erreur deep link stream: $e'),
    );
  }

  void _handleLink(Uri uri) async {
    final uriStr = uri.toString();
    print('Deep link reçu: $uriStr');

    if (uriStr.contains('google.com/maps') ||
        uriStr.contains('maps.google.com') ||
        uriStr.contains('goo.gl/maps') ||
        uriStr.contains('maps.app.goo.gl') ||
        uri.scheme == 'geo') {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        print('Erreur ouverture Maps: $e');
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: themeNotifier,
        builder: (context, isDark, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Rungo',
            navigatorKey: navigatorKey,
            theme: isDark
                ? ThemeData.dark()
                : ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xffFBFBFB),
              primaryColor: const Color(0xffFFC244),
              drawerTheme: const DrawerThemeData(
                backgroundColor: Color(0xffFBFBFB),
              ),
              colorScheme: const ColorScheme.light(
                primary: Color(0xffFFC244),
                secondary: Color(0xff2ECC71),
              ),
            ),
            home: const LoadingPage(),
          );
        },
      ),
    );
  }
}