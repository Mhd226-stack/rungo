import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_user/common/responsive.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../referralcode/referral_code.dart';
import 'login.dart';

class AggreementPage extends StatefulWidget {
  const AggreementPage({Key? key}) : super(key: key);

  @override
  State<AggreementPage> createState() => _AggreementPageState();
}

class _AggreementPageState extends State<AggreementPage> {
  //navigate
  navigate() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Referral()),
        (route) => false);
  }

  bool ischeck = false;
  // ignore: unused_field
  String _error = '';
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Material(
      color: page,
      child: Directionality(
        textDirection: (languageDirection == 'rtl')
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(
                        top: Responsive.height(1.8, context),
                        bottom: Responsive.height(3, context)),
                    child: MyText(
                      textAlign: TextAlign.center,
                      text: languages[choosenLanguage]['text_accept_head'],
                      size: 20,
                      fontweight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    height: media.width * 0.3,
                    width: media.width * 0.3,
                    decoration: const BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage('assets/images/terms_image.png'),
                            fit: BoxFit.contain)),
                  ),
                  SizedBox(
                    height: Responsive.height(3, context),
                  ),
                  SizedBox(
                      width: media.width * 0.9,
                      child: RichText(
                        text: TextSpan(
                          // text: 'Hello ',
                          style: choosenLanguage == 'ar'
                              ? GoogleFonts.cairo(
                                  color: textColor,
                                  fontSize: media.width * fourteen,
                                )
                              : GoogleFonts.inter(
                                  color: textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400),
                          children: [
                            TextSpan(
                              text: languages[choosenLanguage]
                                  ['text_agree_text1'],
                              style: GoogleFonts.inter(
                                  color: textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400),
                            ),
                            TextSpan(
                                text: languages[choosenLanguage]
                                    ['text_terms_of_use'],
                                style: choosenLanguage == 'ar'
                                    ? GoogleFonts.cairo(
                                        color: buttonColor,
                                        fontSize: media.width * fourteen,
                                      )
                                    : GoogleFonts.inter(
                                        color: buttonColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    openBrowser('http://192.168.11.107/privacy');
                                  }),
                            TextSpan(
                                text: languages[choosenLanguage]
                                    ['text_agree_text2']),
                            TextSpan(
                                text: languages[choosenLanguage]
                                    ['text_privacy'],
                                style: choosenLanguage == 'ar'
                                    ? GoogleFonts.cairo(
                                        color: buttonColor,
                                        fontSize: media.width * fourteen,
                                      )
                                    : GoogleFonts.inter(
                                        color: buttonColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    openBrowser('http://192.168.11.107/privacy');
                                  }),
                          ],
                        ),
                      )),
                  Container(
                    padding: const EdgeInsets.only(top: 15, bottom: 15),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 10,
                        ),
                        InkWell(
                          onTap: () {
                            if (ischeck == false) {
                              setState(() {
                                ischeck = true;
                              });
                            } else {
                              setState(() {
                                ischeck = false;
                              });
                            }
                          },
                          child: Container(
                            height: media.width * 0.05,
                            width: media.width * 0.05,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: ischeck ? white : Colors.transparent,
                                border: ischeck
                                    ? null
                                    : Border.all(color: buttonColor, width: 2)),
                            child: ischeck == false
                                ? null
                                : Icon(
                                    Icons.done,
                                    size: media.width * 0.04,
                                    color: buttonColor,
                                  ),
                          ),
                        ),
                        SizedBox(
                          width: media.width * 0.02,
                        ),
                        MyText(
                          text: languages[choosenLanguage]['text_iagree'],
                          size: 12,
                          fontweight: FontWeight.w400,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            (_error != '')
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MyText(
                        text: _error,
                        size: media.width * fourteen,
                        color: verifyDeclined,
                      ),
                    ],
                  )
                : Container(),
            (ischeck == true)
                ? Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 15),
                    child: Button(
                        onTap: () async {
                          loginLoading = true;
                          _error = '';
                          valueNotifierLogin.incrementNotifier();
                          var register = await registerUser();
                          if (register == 'true') {
                            //referral page
                            navigate();
                          } else {
                            setState(() {
                              _error = register.toString();
                            });
                          }
                          loginLoading = false;
                          valueNotifierLogin.incrementNotifier();
                        },
                        text: languages[choosenLanguage]['text_next']),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 15),
                    child: Button(
                        onTap: () async {},
                        text: languages[choosenLanguage]['text_next'],
                        color: Colors.grey,
                        textcolor: textColor.withOpacity(0.5)),
                  )
          ],
        ),
      ),
    );
  }
}
