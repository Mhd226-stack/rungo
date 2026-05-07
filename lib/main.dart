import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'functions/functions.dart';
import 'functions/notifications.dart';
import 'pages/loadingPage/loadingpage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';

// main
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
  } catch (e) {
    print("Firebase est déjà initialisé ou une erreur est survenue : $e");
  }

  checkInternetConnection();
  initMessaging();

  await SharedPreferences.getInstance()
      .then((value) => value.setBool('isDarkTheme', true));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: MaterialApp( // Retire le ValueListenableBuilder temporairement pour tester
          debugShowCheckedModeBanner: false,
          title: 'Rungo', // Petit clin d'oeil à ton projet ;)
          theme: ThemeData.dark(),
          home: const LoadingPage()),
    );
  }
}