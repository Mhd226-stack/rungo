import 'package:flutter/material.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../login/login.dart';

class Languages extends StatefulWidget {
  const Languages({Key? key}) : super(key: key);

  @override
  State<Languages> createState() => _LanguagesState();
}

class _LanguagesState extends State<Languages> {

  // Liste ordonnée : fr → en → reste
  List<String> _orderedLanguageKeys = [];

  @override
  void initState() {
    super.initState();
    // Langue par défaut = français
    choosenLanguage = 'fr';
    languageDirection = 'ltr';
    _buildOrderedList();
  }

  // FIX : fr en premier, en en second, reste trié
  _buildOrderedList() {
    const List<String> priority = ['fr', 'en'];
    final List<String> rest = languages.keys
        .where((k) => !priority.contains(k))
        .toList()
      ..sort();
    _orderedLanguageKeys = [
      ...priority.where((k) => languages.containsKey(k)),
      ...rest,
    ];
  }

  navigate() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const Login()));
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Material(
      child: Directionality(
        textDirection: (languageDirection == 'rtl')
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: media.width * 0.05),
          height: media.height,
          width: media.width,
          color: darkModeBackground,
          child: Column(
            children: [
              // HEADER
              SizedBox(height: MediaQuery.of(context).padding.top + 20),
              MyText(
                color: white,
                // FIX : sécurisé contre null — français garanti d'exister
                text: (languages[choosenLanguage] != null)
                    ? languages[choosenLanguage]['text_choose_language'].toString()
                    : 'Choisissez la langue',
                size: 26,
                fontweight: FontWeight.w700,
              ),

              // LISTE SCROLLABLE
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(height: 20),
                    SizedBox(
                      height: media.height * 0.20,
                      child: Image.asset(
                        'assets/images/change_language.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // FIX : liste ordonnée avec null-safety
                    ..._orderedLanguageKeys.map((i) {
                      if (languages[i] == null) return const SizedBox();
                      return InkWell(
                        onTap: () {
                          setState(() {
                            choosenLanguage = i;
                            languageDirection =
                            (['ar', 'ur', 'iw'].contains(i)) ? 'rtl' : 'ltr';
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(media.width * 0.025),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              MyText(
                                text: languagesCode
                                    .firstWhere(
                                      (e) => e['code'] == i,
                                  orElse: () => {'name': i},
                                )['name']
                                    .toString(),
                                size: 16,
                                color: white,
                                fontweight: FontWeight.w400,
                              ),
                              Container(
                                height: media.width * 0.05,
                                width: media.width * 0.05,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: buttonColor, width: 1.2),
                                ),
                                alignment: Alignment.center,
                                child: (choosenLanguage == i)
                                    ? Container(
                                  height: media.width * 0.03,
                                  width: media.width * 0.03,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: buttonColor,
                                  ),
                                )
                                    : const SizedBox(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              // BOUTON CONFIRMATION
              // FIX : pref null-safety + try/catch sur getlangid
              if (choosenLanguage.isNotEmpty && languages[choosenLanguage] != null)
                Button(
                  onTap: () async {
                    try {
                      await getlangid();
                    } catch (e) {
                      debugPrint('Erreur getlangid (ignorée) : $e');
                    }
                    // FIX : pref peut être null si getDetailsOfDevice pas encore appelé
                    if (pref != null) {
                      pref.setString('languageDirection', languageDirection);
                      pref.setString('choosenLanguage', choosenLanguage);
                    }
                    navigate();
                  },
                  text: languages[choosenLanguage]['text_confirm'].toString(),
                ),
              const ButtonBottomSpace(),
            ],
          ),
        ),
      ),
    );
  }
}