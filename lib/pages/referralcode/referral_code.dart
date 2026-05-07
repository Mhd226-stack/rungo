import 'package:flutter/material.dart';
import 'package:flutter_user/common/responsive.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../onTripPage/map_page.dart';

class Referral extends StatefulWidget {
  const Referral({Key? key}) : super(key: key);

  @override
  State<Referral> createState() => _ReferralState();
}

dynamic referralCode;

class _ReferralState extends State<Referral> {
  bool _loading = false;
  String _error = '';
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    referralCode = '';
    super.initState();
  }

  //navigate
  navigate() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const Maps()));
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Material(
      child: Directionality(
        textDirection: (languageDirection == 'rtl')
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Stack(
          children: [
            Container(
              padding: EdgeInsets.only(
                  left: media.width * 0.08, right: media.width * 0.08),
              height: media.height,
              width: media.width,
              color: page,
              child: Column(
                children: [
                  SizedBox(
                    height: Responsive.height(24, context),
                  ),
                  SizedBox(
                      width: media.width * 1,
                      child: MyText(
                        text: languages[choosenLanguage]['text_apply_referral'],
                        size: 26,
                        fontweight: FontWeight.w700,
                      )),
                  SizedBox(height: Responsive.height(3, context)),
                  SizedBox(
                      width: media.width * 1,
                      child: MyText(
                        text: languages[choosenLanguage]['referral_code'],
                        size: 14,
                        fontweight: FontWeight.w600,
                      )),
                  SizedBox(height: Responsive.height(1, context)),
                  Container(
                    padding: EdgeInsets.only(left: 10, right: 10),
                    alignment: Alignment.center,
                    width: Responsive.width(90, context),
                    height: Responsive.height(6, context),
                    decoration: BoxDecoration(
                        border: Border.all(color: darkModeBorderColor),
                        color: darkModeSecContainer,
                        borderRadius: BorderRadius.circular(15)),
                    child: InputField(
                      text: languages[choosenLanguage]['text_enter_referral'],
                      textController: controller,
                      onTap: (val) {
                        setState(() {
                          referralCode = controller.text;
                        });
                      },
                      color: (_error == '') ? null : Colors.red,
                    ),
                  ),
                  (_error != '')
                      ? Container(
                          margin: EdgeInsets.only(top: media.height * 0.02),
                          child: MyText(
                            text: _error,
                            size: media.width * sixteen,
                            color: Colors.red,
                          ),
                        )
                      : Container(),
                  SizedBox(
                    height: Responsive.height(13, context),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      //skip
                      Expanded(
                        child: Button(
                            borcolor: darkModeBorderColor.withAlpha(25),
                            color: darkModeSecContainer,
                            textcolor: textColor.withAlpha(100),
                            onTap: () async {
                              setState(() {
                                _loading = true;
                              });
                              // var val = await registerUser();
                              FocusManager.instance.primaryFocus?.unfocus();
                              _error = '';
                              // if (val == 'true') {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const Maps()));
                              // } else {
                              //   setState(() {
                              //     _error = languages[choosenLanguage]
                              //         ['text_somethingwentwrong'];
                              //   });
                              // }
                              setState(() {
                                _loading = false;
                              });
                            },
                            text: languages[choosenLanguage]['text_skip']),
                      ),
                      SizedBox(
                        width: Responsive.width(3, context),
                      ),
                      //apply code
                      Expanded(
                        child: Button(
                          onTap: () async {
                            if (controller.text.isNotEmpty) {
                              FocusManager.instance.primaryFocus?.unfocus();
                              setState(() {
                                _error = '';
                                _loading = true;
                              });
                              // var val = await registerUser();
                              // if (val == 'true') {
                              var result = await updateReferral();
                              if (result == 'true') {
                                navigate();
                              } else {
                                setState(() {
                                  _error = languages[choosenLanguage]
                                      ['text_referral_code'];
                                });
                              }
                              // } else {
                              //   setState(() {
                              //     _error = languages[choosenLanguage]
                              //         ['text_somethingwentwrong'];
                              //   });
                              // }
                              setState(() {
                                _loading = false;
                              });
                            } else {}
                          },
                          text: languages[choosenLanguage]['text_apply'],
                          color: (controller.text.isNotEmpty)
                              ? buttonColor
                              : Colors.grey,
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
            //loader
            (_loading == true)
                ? const Positioned(top: 0, child: Loading())
                : Container()
          ],
        ),
      ),
    );
  }
}
