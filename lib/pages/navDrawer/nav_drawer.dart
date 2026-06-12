import 'package:flutter/material.dart';
import 'package:flutter_user/common/responsive.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/functions.dart';
import '../../main.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../NavigatorPages/adminchatpage.dart';
import '../NavigatorPages/editprofile.dart';
import '../NavigatorPages/faq.dart';
import '../NavigatorPages/favourite.dart';
import '../NavigatorPages/history.dart';
import '../NavigatorPages/makecomplaint.dart';
import '../NavigatorPages/notification.dart';
import '../NavigatorPages/referral.dart';
import '../NavigatorPages/selectlanguage.dart';
import '../NavigatorPages/settings_page.dart';
import '../NavigatorPages/sos.dart';
import '../NavigatorPages/suppot_page.dart';
import '../NavigatorPages/walletpage.dart';
import '../onTripPage/map_page.dart';
import '../login/login.dart';
import 'package:url_launcher/url_launcher.dart';

class NavDrawer extends StatefulWidget {
  const NavDrawer({Key? key}) : super(key: key);
  @override
  State<NavDrawer> createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  darkthemefun() async {
    setTheme(!isDarkTheme);
    themeNotifier.value = isDarkTheme;
    await getDetailsOfDevice();
    pref.setBool('isDarkTheme', isDarkTheme);
    valueNotifierHome.incrementNotifier();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return ValueListenableBuilder(
        valueListenable: valueNotifierHome.value,
        builder: (context, value, child) {
          return SizedBox(
            width: media.width * 0.8,
            child: Directionality(
              textDirection: (languageDirection == 'rtl')
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Drawer(
                  backgroundColor: page,
                  child: SizedBox(
                    width: media.width * 0.7,
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: media.width * 0.07 +
                                        MediaQuery.of(context).padding.top,
                                  ),
                                  SizedBox(
                                    width: media.width * 0.7,
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: Responsive.width(2, context),
                                        ),
                                        Container(
                                          height: media.width * 0.18,
                                          width: media.width * 0.18,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                  image: NetworkImage(
                                                    (userDetails['profile_picture'] != null && userDetails['profile_picture'].toString().isNotEmpty)
                                                        ? (userDetails['profile_picture'].toString().startsWith('http')
                                                        ? userDetails['profile_picture'].toString()
                                                        : 'https://rungobf.com${userDetails['profile_picture']}')
                                                        : 'https://ui-avatars.com/api/?name=${userDetails['name'] ?? 'U'}&background=random',
                                                  ),
                                                  fit: BoxFit.cover)),
                                        ),
                                        SizedBox(
                                          width: media.width * 0.025,
                                        ),
                                        SizedBox(
                                          child: Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Container(
                                                width: Responsive.width(
                                                    38, context),
                                                child: MyText(
                                                  text: userDetails['name'],
                                                  size: media.width * eighteen,
                                                  fontweight: FontWeight.w600,
                                                  maxLines: 1,
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () async {
                                                  var val = await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                          const EditProfile()));
                                                  if (val) {
                                                    setState(() {});
                                                  }
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.016),
                                                  decoration: BoxDecoration(
                                                      color: buttonColor,
                                                      shape: BoxShape.circle),
                                                  child: Icon(
                                                      Icons.mode_edit_outlined,
                                                      size: media.width *
                                                          seventeen,
                                                      color: textColor),
                                                ),
                                              )
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                      height: Responsive.height(4.5, context)),
                                  // Container(
                                  //   width: media.width * 0.8,
                                  //   height: 1,
                                  //   color: white.withOpacity(0.3),
                                  // ),
                                  // SizedBox(
                                  //     height: Responsive.height(3, context)),
                                  Container(
                                    width: media.width * 0.7,
                                    child: Column(
                                      children: [
                                        //My orders

                                        NavMenu(
                                          onTap: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                    const History()));
                                          },
                                          isSos: true,
                                          text: languages[choosenLanguage]
                                          ['text_my_orders'],
                                          image: 'assets/nav/trips.png',
                                        ),

                                        Container(
                                          padding: EdgeInsets.only(top: media.width * 0.025),
                                          child: ValueListenableBuilder(
                                              valueListenable:
                                              valueNotifierNotification
                                                  .value,
                                              builder: (context, value, child) {
                                                return InkWell(
                                                  onTap: () {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                            const NotificationPage()));
                                                    setState(() {
                                                      userDetails[
                                                      'notifications_count'] = 0;
                                                    });
                                                  },
                                                  child: Padding(
                                                    padding: EdgeInsets.only(
                                                      top: Responsive.height(0.75, context),
                                                      bottom: Responsive.height(2, context),
                                                      left: Responsive.width(2, context),
                                                      right: Responsive.width(2, context),
                                                    ),
                                                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Image.asset(
                                                              'assets/nav/notifications.png',
                                                              width: media
                                                                  .width *
                                                                  twentythree,
                                                              height: media
                                                                  .width *
                                                                  twentythree,
                                                              color: textColor,
                                                            ),
                                                            SizedBox(
                                                                width: 10
                                                            ),
                                                            SizedBox(
                                                              width: (userDetails[
                                                              'notifications_count'] ==
                                                                  0)
                                                                  ? media.width *
                                                                  0.49
                                                                  : media.width *
                                                                  0.435,
                                                              child: MyText(
                                                                text: languages[choosenLanguage]
                                                                [
                                                                'text_notification']
                                                                    .toString(),
                                                                overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                                size: media
                                                                    .width *
                                                                    sixteen,
                                                                color: textColor,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Row(
                                                          mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                          children: [

                                                            Row(
                                                              children: [
                                                                (userDetails['notifications_count'] ==
                                                                    0)
                                                                    ? Container()
                                                                    : Container(
                                                                  height:
                                                                  20,
                                                                  width:
                                                                  20,
                                                                  alignment:
                                                                  Alignment.center,
                                                                  decoration:
                                                                  BoxDecoration(
                                                                    shape: BoxShape.circle,
                                                                    color: buttonColor,
                                                                  ),
                                                                  child:
                                                                  Text(
                                                                    userDetails['notifications_count'].toString(),
                                                                    style: GoogleFonts.inter(fontSize: media.width * fourteen, color: (isDarkTheme) ? Colors.black : buttonText),
                                                                  ),
                                                                ),
                                                                // Icon(
                                                                //   Icons
                                                                //       .play_arrow_rounded,
                                                                //   size: media
                                                                //           .width *
                                                                //       0.05,
                                                                //   color:
                                                                //       textColor,
                                                                // ),
                                                              ],
                                                            ),
                                                          ],
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }),
                                        ),

                                        Padding(
                                          padding: EdgeInsets.only(
                                              top: Responsive.height(0.75, context),
                                              bottom: Responsive.height(0.75, context)),
                                          child: ValueListenableBuilder(
                                              valueListenable: valueNotifierChat.value,
                                              builder: (context, value, child) {
                                                return InkWell(
                                                  onTap: () {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                            const AdminChatPage()));
                                                  },
                                                  child: Container(
                                                    padding: EdgeInsets.only(
                                                        top: media.width * 0.025),
                                                    child: Column(
                                                      children: [
                                                        Row(
                                                          children: [
                                                            SizedBox(
                                                              width: Responsive.width(3.3, context),
                                                            ),
                                                            Icon(Icons.chat,
                                                                size: media.width * 0.055,
                                                                color: textColor),
                                                            SizedBox(
                                                              width: media.width * 0.025,
                                                            ),
                                                            Row(
                                                              mainAxisAlignment:
                                                              MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                SizedBox(
                                                                  width: (unSeenChatCount == '0')
                                                                      ? media.width * 0.5
                                                                      : media.width * 0.445,
                                                                  child: MyText(
                                                                    text: languages[choosenLanguage]
                                                                    ['text_chat_us'],
                                                                    overflow: TextOverflow.ellipsis,
                                                                    size: media.width * sixteen,
                                                                    color: textColor,
                                                                  ),
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    (unSeenChatCount == '0')
                                                                        ? Container()
                                                                        : Container(
                                                                      height: 20,
                                                                      width: 20,
                                                                      alignment: Alignment.center,
                                                                      decoration: BoxDecoration(
                                                                        shape: BoxShape.circle,
                                                                        color: buttonColor,
                                                                      ),
                                                                      child: Text(
                                                                        unSeenChatCount,
                                                                        style: GoogleFonts.inter(
                                                                            fontSize: media.width * fourteen,
                                                                            color: (isDarkTheme)
                                                                                ? Colors.black
                                                                                : buttonText),
                                                                      ),
                                                                    ),
                                                                    Icon(
                                                                      Icons.play_arrow_rounded,
                                                                      size: media.width * 0.05,
                                                                      color: textColor,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            )
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }),
                                        ),
                                        //wallet page
                                        if (userDetails[
                                        'show_wallet_feature_on_mobile_app'] ==
                                            "1")
                                          NavMenu(
                                            onTap: () {
                                              // printWrapped(
                                              //     userDetails.toString());
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                      const WalletPage()));
                                            },
                                            text: languages[choosenLanguage]
                                            ['text_enable_wallet'],
                                            icon: Icons.wallet,
                                          ),

                                        //FAQ
                                        // NavMenu(
                                        //   onTap: () {
                                        //     Navigator.push(
                                        //         context,
                                        //         MaterialPageRoute(
                                        //             builder: (context) =>
                                        //                 const Faq()));
                                        //   },
                                        //   text: languages[choosenLanguage]
                                        //       ['text_faq'],
                                        //   image: 'assets/images/faq.png',
                                        // ),

                                        //sos
                                        NavMenu(

                                          onTap: () async {
                                            var nav = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                    const Sos()));
                                            if (nav) {
                                              setState(() {});
                                            }
                                          },
                                          text: languages[choosenLanguage]
                                          ['text_sos'],
                                          image: 'assets/nav/sos.png',
                                        ),

                                        NavMenu(
                                          isSos: true,
                                          onTap: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        MakeComplaint(
                                                            fromPage: 1)));
                                          },
                                          text: languages[choosenLanguage]
                                          ['text_make_complaints'],
                                          image:
                                          'assets/nav/feedback.png',
                                        ),

                                        //saved address


                                        //select language
                                        NavMenu(
                                          isSos: true,
                                          onTap: () async {
                                            var nav = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                    const SettingsPage()));
                                            // if (nav) {
                                            //   setState(() {});
                                            // }
                                          },
                                          text: languages[choosenLanguage]
                                          ['text_settings'],
                                          image:
                                          'assets/nav/settings.png',

                                        ),
                                        NavMenu(
                                          onTap: () async {
                                            var nav = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                    const SupportPage()));
                                            if (nav) {
                                              setState(() {});
                                            }
                                          },
                                          text: languages[choosenLanguage]
                                          ['text_support'] ?? 'Support',
                                          image:
                                          'assets/nav/support.png',
                                          isSos: true,
                                        ),

                                        //Make Complaint

                                        //delete account
                                        // NavMenu(
                                        //   onTap: () {
                                        //     setState(() {
                                        //       deleteAccount = true;
                                        //     });
                                        //     valueNotifierHome
                                        //         .incrementNotifier();
                                        //     Navigator.pop(context);
                                        //   },
                                        //   text: languages[choosenLanguage]
                                        //       ['text_delete_account'],
                                        //   icon: Icons.delete,
                                        // ),

                                        // Container(
                                        //   padding: EdgeInsets.only(
                                        //       top: media.width * 0.05),
                                        //   child: Row(
                                        //     children: [
                                        //       MyText(
                                        //         text: languages[choosenLanguage]
                                        //             ['text_general'],
                                        //         size: media.width * fourteen,
                                        //         fontweight: FontWeight.w700,
                                        //       ),
                                        //     ],
                                        //   ),
                                        // ),

                                        //privacy policy
                                        // NavMenu(
                                        //   onTap: () {
                                        //     openBrowser(
                                        //         'https://rungobf/privacy/');
                                        //   },
                                        //   text: languages[choosenLanguage]
                                        //       ['text_privacy'],
                                        //   image:
                                        //       'assets/images/privacy_policy.png',
                                        // ),

                                        //referral page
                                        // NavMenu(
                                        //   onTap: () {
                                        //     Navigator.push(
                                        //         context,
                                        //         MaterialPageRoute(
                                        //             builder: (context) =>
                                        //                 const ReferralPage()));
                                        //   },
                                        //   text: languages[choosenLanguage]
                                        //       ['text_enable_referal'],
                                        //   image: 'assets/images/refferal_icon.png',
                                        // ),
                                        NavMenu(
                                          onTap: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                    const Favorite()));
                                          },
                                          text: languages[choosenLanguage]
                                          ['text_favourites'],
                                          image: 'assets/nav/favourite.png',
                                        ),
                                        SizedBox(
                                          height: Responsive.height(3, context),
                                        )
                                      ],
                                    ),
                                  ),
                                  Visibility(
                                    visible: false,
                                    child: InkWell(
                                      onTap: () async {
                                        darkthemefun();
                                      },
                                      child: Container(
                                        padding: EdgeInsets.only(
                                            top: media.width * 0.025),
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              isDarkTheme
                                                  ? Icons.brightness_4_outlined
                                                  : Icons.brightness_3_rounded,
                                              size: media.width * 0.075,
                                              color: textColor.withOpacity(0.8),
                                            ),
                                            SizedBox(
                                              width: media.width * 0.025,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                SizedBox(
                                                    width: media.width * 0.46,
                                                    child: Text(
                                                      languages[choosenLanguage]
                                                      ['text_select_theme'],
                                                      style: GoogleFonts.inter(
                                                          fontSize:
                                                          media.width *
                                                              sixteen,
                                                          color: textColor
                                                              .withOpacity(
                                                              0.8)),
                                                    )),
                                                Switch(
                                                    value: isDarkTheme,
                                                    onChanged: (toggle) async {
                                                      darkthemefun();
                                                    }),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ]),
                          ),
                        ),
                        // ── Assistance ──
                        Padding(
                          padding: EdgeInsets.only(top: media.width * 0.025),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Appel
                              NavMenu(
                                onTap: () => makingPhoneCall(
                                    userDetails['contact_us_mobile1']),
                                text: 'Appel assistance',
                                icon: Icons.call,
                                isSos: true,
                              ),
                              // WhatsApp
                              NavMenu(
                                onTap: () async {
                                  String url =
                                      "https://wa.me/${userDetails['contact_us_mobile1']}/?text=''";
                                  if (await canLaunch(url)) {
                                    await launch(url);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text("WhatsApp non installé")));
                                  }
                                },
                                text: 'WhatsApp assistance',
                                icon: Icons.message_rounded,
                                isSos: true,
                              ),
                              // Urgence
                              NavMenu(
                                onTap: () => makingPhoneCall('000'),
                                text: 'Urgence',
                                icon: Icons.emergency_rounded,
                                isSos: true,
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            final navigator = Navigator.of(context);
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: page,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                title: Text(
                                  languages[choosenLanguage]['text_confirmlogout'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                                ),
                                actions: [
                                  // Annuler
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(
                                      languages[choosenLanguage]['text_cancel'],
                                      style: TextStyle(color: textColor),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(ctx); // ferme le dialog
                                      var result = await userLogout();
                                      if (result == 'success' || result == 'logout') {
                                        userDetails.clear();
                                        navigator.pushAndRemoveUntil(
                                          MaterialPageRoute(
                                            builder: (context) => const Login(),
                                          ),
                                              (route) => false,
                                        );
                                      }
                                    },
                                    child: Text(
                                      languages[choosenLanguage]['text_confirm'],
                                      style: TextStyle(color: buttonColor, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                              alignment: Alignment.center,
                              height: media.width * 0.13,
                              width: media.width * 0.62,
                              decoration: BoxDecoration(
                                  color: buttonColor,
                                  borderRadius: BorderRadius.circular(15)),
                              child: MyText(
                                text: languages[choosenLanguage]
                                ['text_sign_out'],
                                size: media.width * sixteen,
                                fontweight: FontWeight.w500,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              )),
                        ),
                        SizedBox(
                          height: media.width * 0.1,
                        )
                      ],
                    ),
                  )),
            ),
          );
        });
  }
}