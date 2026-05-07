import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import 'adminchatpage.dart';
import 'faq.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _controller = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Material(
        child: ValueListenableBuilder(
            valueListenable: valueNotifierHome.value,
            builder: (context, value, child) {
              return Directionality(
                textDirection: (languageDirection == 'rtl')
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.only(
                          left: media.width * 0.05, right: media.width * 0.05),
                      height: media.height * 1,
                      width: media.width * 1,
                      color: page,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).padding.top +
                                  media.width * 0.05),
                          Stack(
                            children: [
                              Container(
                                padding:
                                EdgeInsets.only(bottom: media.width * 0.05),
                                width: media.width * 1,
                                alignment: Alignment.center,
                                child: MyText(
                                  text: languages[choosenLanguage]
                                  ['test_support']
                                      .toString(),
                                  size: media.width * twenty,
                                  fontweight: FontWeight.w700,
                                ),
                              ),
                              Positioned(
                                  child: InkWell(
                                      onTap: () {
                                        Navigator.pop(context, true);
                                      },
                                      child: IosBackButton())),
                            ],
                          ),
                          SizedBox(
                            height: media.width * 0.09,
                          ),
                          settingWidget(
                              image: 'assets/images/message_icon.png',
                              title: languages[choosenLanguage]
                              ['text_chat_us']
                                  .toString(),
                              button: false,
                              onTap: () {
                                Navigator.push(context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const AdminChatPage()));
                              }),
                          SizedBox(height: 10),
                          settingWidget(
                              image: 'assets/images/faq_icon.png',
                              title: languages[choosenLanguage]
                              ['text_faq']
                                  .toString(),
                              button: false,
                              onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const Faq()));
                              }),
                          SizedBox(height: 10),
                          settingWidget(
                              image: 'assets/images/privacy_icon.png',
                              title: languages[choosenLanguage]
                              ['text_privacy']
                                  .toString(),
                              button: false,
                              onTap: () {
                                    openBrowser(
                                        'https://clust.al/en/privacy/');
                              }),
                          ButtonBottomSpace(
                            height: 4,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
      ),
    );
  }

  Widget settingWidget(
      {required String image,
        required String title,
        required bool button,
        bool? isSwitchOn,
        required VoidCallback onTap}) {
    var media = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: media.width * 0.15,
        margin:
        EdgeInsets.only(left: media.width * 0.05, right: media.width * 0.05),
        padding: EdgeInsets.only(
            top: media.width * 0.05,
            bottom: media.width * 0.05,
            left: media.width * 0.07,
            right: media.width * 0.07),
        width: media.width * 1,
        decoration: BoxDecoration(
          color: Color(0xff191B1A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Image.asset(
              image,
              scale: 1,
              color: Colors.white,
            ),
            SizedBox(
              width: media.width * 0.05,
            ),
            Expanded(
              child: MyText(
                  text: title,
                  size: media.width * 0.04,
                  color: Colors.white),
            ),
            button
                ? Container(
              padding: EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Color(0xff7B7B7B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AdvancedSwitch(
                onChanged: (value) {
                  print('this is vale $value');
                  isDarkTheme = value;
                  // change here the theme
                },
                width: media.width * 0.1,
                height: media.width * 0.05,
                activeColor: Colors.white,
                inactiveColor: Color(0xff191B1A),
                controller: _controller,
              ),
            )
                : Container(),
            Icon(Icons.arrow_forward_ios_outlined , size: 20,
              color: Color(0xffFFFF).withOpacity(0.46),)
          ],
        ),
      ),
    );
  }
}
