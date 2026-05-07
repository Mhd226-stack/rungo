import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../styles/styles.dart';
import '../../functions/functions.dart';
import 'package:http/http.dart' as http;
import '../../widgets/widgets.dart';
import '../language/languages.dart';
import '../login/login.dart';
import '../noInternet/noInternet.dart';
import '../onTripPage/booking_confirmation.dart';
import '../onTripPage/invoice.dart';
import '../onTripPage/map_page.dart';
import 'loading.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key}) : super(key: key);

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  String dot = '.';
  bool updateAvailable = false;
  dynamic _package;
  dynamic _version;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // FIX : définit le français comme langue par défaut au premier lancement
    _setDefaultLanguage();
    initApp();
  }

  // FIX : langue par défaut = français, second = anglais
  _setDefaultLanguage() {
    if (choosenLanguage == '') {
      choosenLanguage = 'fr';
      languageDirection = 'ltr';
    }
  }

  // FIX 1 : getEmailmodule() ne bloque plus le reste en cas d'erreur
  initApp() async {
    try {
      await getEmailmodule();
    } catch (e) {
      // On continue même si getEmailmodule échoue
      debugPrint("Erreur getEmailmodule (ignorée, on continue) : $e");
    }
    // getLanguageDone s'exécute toujours
    await getLanguageDone();
  }

  navigate() {
    if (userRequestData.isNotEmpty && userRequestData['is_completed'] == 1) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Invoice()),
              (route) => false);
    } else if (userRequestData.isNotEmpty &&
        userRequestData['is_completed'] != 1) {
      if (userRequestData['is_rental'] == true) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => BookingConfirmation(type: 1)),
                (route) => false);
      } else {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => BookingConfirmation()),
                (route) => false);
      }
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Maps()),
              (route) => false);
    }
  }

  getLanguageDone() async {
    _package = await PackageInfo.fromPlatform();
    try {
      final ref = FirebaseDatabase.instance.ref().child(
          platform == TargetPlatform.android
              ? 'user_android_version'
              : 'user_ios_version');

      final snapshot = await ref.get().timeout(const Duration(seconds: 5));

      if (snapshot.value != null) {
        var version = snapshot.value.toString().split('.');
        var package = _package.version.toString().split('.');

        for (var i = 0; i < version.length || i < package.length; i++) {
          if (i < version.length && i < package.length) {
            if (int.parse(package[i]) < int.parse(version[i])) {
              setState(() => updateAvailable = true);
              break;
            } else if (int.parse(package[i]) > int.parse(version[i])) {
              setState(() => updateAvailable = false);
              break;
            }
          }
        }
      }

      if (updateAvailable == false) {
        await getDetailsOfDevice();
        var val = await getLocalData();
        debugPrint('getLocalData result: $val');
        debugPrint('choosenLanguage: $choosenLanguage');
        debugPrint('internet: $internet');

        if (val == '3') {
          // Utilisateur connecté avec token valide → Maps
          navigate();
        } else if (val == '2') {
          // Token présent mais session expirée → Login
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const Login()));
        } else {
          // val == '1' ou null → premier lancement → Languages
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const Languages()));
        }
      }
    } catch (e) {
      debugPrint("Erreur getLanguageDone : $e");
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const Languages()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Material(
      child: Scaffold(
        body: Stack(
          children: [
            // Couche 1 : Splash Screen (Logo)
            Container(
              height: media.height,
              width: media.width,
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 85,
                    height: 89.43,
                    child: Image.asset('assets/images/logo.png'),
                  ),
                ],
              ),
            ),

            // Couche 2 : Alerte Mise à jour
            (updateAvailable == true)
                ? Positioned(
                top: 0,
                child: Container(
                  height: media.height,
                  width: media.width,
                  color: Colors.black.withOpacity(0.6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: media.width * 0.9,
                        padding: EdgeInsets.all(media.width * 0.05),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: Column(
                          children: [
                            MyText(
                              text:
                              'Une nouvelle version est disponible. Veuillez mettre à jour.',
                              size: media.width * sixteen,
                              fontweight: FontWeight.w600,
                            ),
                            const SizedBox(height: 20),
                            Button(
                                onTap: () {
                                  if (platform == TargetPlatform.android) {
                                    openBrowser(
                                        'https://play.google.com/store/apps/details?id=${_package.packageName}');
                                  }
                                },
                                text: 'Mettre à jour')
                          ],
                        ),
                      )
                    ],
                  ),
                ))
                : Container(),

            // Couche 3 : Loader de chargement
            (_isLoading == true && internet == true)
                ? const Positioned(top: 0, child: Loading())
                : Container(),

            // Couche 4 : Écran "Pas d'Internet"
            (internet == false)
                ? Positioned(
                top: 0,
                child: NoInternet(
                  onTap: () {
                    setState(() {
                      internetTrue();
                      getLanguageDone();
                    });
                  },
                ))
                : Container(),
          ],
        ),
      ),
    );
  }
}