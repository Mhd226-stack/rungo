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
import 'package:lottie/lottie.dart';
import '../homePage/home_page.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key}) : super(key: key);

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  String dot = '.';
  bool updateAvailable = false;
  dynamic _package;
  dynamic _version;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
    _setDefaultLanguage();
    initApp();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // FIX : langue par défaut = français, second = anglais
  _setDefaultLanguage() {
    if (choosenLanguage == '') {
      choosenLanguage = 'fr';
      languageDirection = 'ltr';
    }
  }

  initApp() async {
    await Future.delayed(const Duration(seconds: 2));

    try {
      await getEmailmodule();
    } catch (e) {
      debugPrint("Erreur getEmailmodule (ignorée) : $e");
    }
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
          MaterialPageRoute(builder: (context) => const RungoHomePage()),
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
            // Couche 1 : Splash Screen (Lottie)
            Container(
              height: media.height,
              width: media.width,
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/images/Delivery.json',
                    width: media.width * 0.7,
                    height: media.width * 0.7,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'RUNGO',
                    style: TextStyle(
                      color: const Color(0xFFFFB800),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                    ),
                  ),
                  //const SizedBox(height: 8),
                  // Text(
                    //'Votre trajet, en un clic',
                    //style: TextStyle(
                      // color: Colors.green,
                      //fontSize: 14,
                      //fontWeight: FontWeight.bold,
                      //letterSpacing: 2,
                      //),
                    //),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: const Color(0xFFDA7756),
                      strokeWidth: 2,
                    ),
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