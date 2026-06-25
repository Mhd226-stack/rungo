import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_user/common/responsive.dart';
import 'package:flutter_user/pages/login/login.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool isLoading = true;
  bool error = false;
  dynamic notificationid;

  @override
  void initState() {
    getdata();
    super.initState();
  }

  getdata() async {
    var val = await getnotificationHistory();
    setState(() {
      if (val == 'success') {
        isLoading = false;
      } else {
        isLoading = true;
      }
    });
  }

  navigateLogout() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const Login()));
  }

  bool showinfo = false;
  int? showinfovalue;
  bool showToastbool = false;

  showToast() async {
    setState(() {
      showToastbool = true;
    });
    Future.delayed(const Duration(seconds: 1), () async {
      setState(() {
        showToastbool = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    log('Ami here');
    var media = MediaQuery.of(context).size;
    return Material(
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
                      height: media.height,
                      width: media.width,
                      color: page,
                      padding: EdgeInsets.fromLTRB(media.width * 0.05,
                          media.width * 0.05, media.width * 0.05, 0),
                      child: Column(
                        children: [
                          SizedBox(height: MediaQuery.of(context).padding.top),
                          Stack(
                            children: [
                              Container(
                                padding:
                                EdgeInsets.only(bottom: media.width * 0.05),
                                width: media.width,
                                alignment: Alignment.center,
                                child: MyText(
                                  text: languages[choosenLanguage]
                                  ['text_notification'],
                                  size: media.width * twentythree,
                                  fontweight: FontWeight.w700,
                                ),
                              ),
                              Positioned(
                                  child: InkWell(
                                      onTap: () async {
                                        Navigator.pop(context);
                                      },
                                      child: IosBackButton()))
                            ],
                          ),
                          SizedBox(height: Responsive.height(2, context)),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  if (notificationHistory.isNotEmpty)
                                    Column(
                                      children: [
                                        Column(
                                          children: notificationHistory
                                              .asMap()
                                              .map((i, value) {
                                            return MapEntry(
                                              i,
                                              Stack(
                                                alignment:
                                                Alignment.bottomRight,
                                                children: [
                                                  InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        showinfovalue = i;
                                                        showinfo = true;
                                                      });
                                                    },
                                                    child: Container(
                                                      margin: EdgeInsets.only(
                                                          top: media.width *
                                                              0.02,
                                                          bottom:
                                                          media.width *
                                                              0.02),
                                                      width:
                                                      media.width * 0.9,
                                                      padding:
                                                      EdgeInsets.all(
                                                          media.width *
                                                              0.025),
                                                      decoration: BoxDecoration(
                                                          border: Border.all(
                                                              color: white
                                                                  .withOpacity(
                                                                  0.3),
                                                              width: 1.2),
                                                          borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                              12),
                                                          color: page),
                                                      child: Column(
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Container(
                                                                  height:
                                                                  media.width *
                                                                      0.1,
                                                                  width: media
                                                                      .width *
                                                                      0.1,
                                                                  decoration: BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      color: white.withOpacity(
                                                                          0.22)),
                                                                  alignment:
                                                                  Alignment
                                                                      .center,
                                                                  child: const Icon(
                                                                      Icons
                                                                          .notifications)),
                                                              SizedBox(
                                                                width: media
                                                                    .width *
                                                                    0.025,
                                                              ),
                                                              Column(
                                                                crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                                children: [
                                                                  Row(
                                                                    mainAxisAlignment:
                                                                    MainAxisAlignment.spaceBetween,
                                                                    children: [
                                                                      SizedBox(
                                                                        width:
                                                                        media.width * 0.38,
                                                                        child:
                                                                        Text(
                                                                          notificationHistory[i]['title'].toString(),
                                                                          overflow: TextOverflow.ellipsis,
                                                                          style: GoogleFonts.inter(fontSize: media.width * sixteen, color: textColor, fontWeight: FontWeight.w500),
                                                                        ),
                                                                      ),
                                                                      Column(
                                                                        children: [
                                                                          SizedBox(
                                                                            width: media.width * 0.3,
                                                                            child: Text(
                                                                              notificationHistory[i]['converted_created_at'].toString(),
                                                                              overflow: TextOverflow.ellipsis,
                                                                              style: GoogleFonts.inter(fontSize: media.width * twelve, color: white.withOpacity(0.58), fontWeight: FontWeight.w400),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  SizedBox(
                                                                    width: media.width *
                                                                        0.55,
                                                                    child:
                                                                    Text(
                                                                      notificationHistory[i]['body']
                                                                          .toString(),
                                                                      overflow:
                                                                      TextOverflow.ellipsis,
                                                                      style:
                                                                      GoogleFonts.inter(
                                                                        fontSize:
                                                                        media.width * twelve,
                                                                        color:
                                                                        hintColor,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(
                                                            height: media
                                                                .width *
                                                                0.02,
                                                          ),
                                                          if (notificationHistory[i]['image'] != null &&
                                                              notificationHistory[i]['image'].toString().isNotEmpty &&
                                                              !notificationHistory[i]['image'].toString().endsWith('/'))
                                                            Container(
                                                              height: media.width * 0.1,
                                                              width: media.width * 0.6,
                                                              decoration: BoxDecoration(
                                                                borderRadius: BorderRadius.circular(10),
                                                                border: Border.all(color: white.withOpacity(0.2)),
                                                                image: DecorationImage(
                                                                  fit: BoxFit.cover,
                                                                  image: NetworkImage(
                                                                    notificationHistory[i]['image'],
                                                                  ),
                                                                ),
                                                              ),
                                                            )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    bottom: 10,
                                                    child: Container(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        width: media.width *
                                                            0.15,
                                                        child: IconButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              error = true;
                                                              notificationid =
                                                              notificationHistory[i]['id'];
                                                            });
                                                          },
                                                          icon: const Icon(
                                                              Icons.delete),
                                                        )),
                                                  )
                                                ],
                                              ),
                                            );
                                          })
                                              .values
                                              .toList(),
                                        ),
                                        if (notificationHistoryPage['pagination'] != null)
                                          if (notificationHistoryPage['pagination']['current_page'] <
                                              notificationHistoryPage['pagination']['total_pages'])
                                            InkWell(
                                              onTap: () async {
                                                setState(() {
                                                  isLoading = true;
                                                });
                                                var val = await getNotificationPages(
                                                    'page=${notificationHistoryPage['pagination']['current_page'] + 1}');
                                                if (val == 'logout') {
                                                  navigateLogout();
                                                }
                                                setState(() {
                                                  isLoading = false;
                                                });
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(
                                                    media.width * 0.025),
                                                margin: EdgeInsets.only(
                                                    bottom: media.width * 0.05),
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                    BorderRadius.circular(10),
                                                    color: page,
                                                    border: Border.all(
                                                        color: borderLines,
                                                        width: 1.2)),
                                                child: Text(
                                                  languages[choosenLanguage]
                                                  ['text_loadmore'],
                                                  style: GoogleFonts.inter(
                                                      fontSize:
                                                      media.width * sixteen,
                                                      color: textColor),
                                                ),
                                              ),
                                            ),
                                      ],
                                    )
                                  else
                                    Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: media.width * 0.3,
                                        ),
                                        Container(
                                          alignment: Alignment.center,
                                          height: media.width * 0.5,
                                          width: media.width * 0.5,
                                          decoration: const BoxDecoration(
                                              image: DecorationImage(
                                                  image: AssetImage(
                                                      'assets/images/no_data_found.png'),
                                                  fit: BoxFit.contain)),
                                        ),
                                        SizedBox(
                                          height: media.width * 0.05,
                                        ),
                                        SizedBox(
                                          width: media.width * 0.8,
                                          child: MyText(
                                              text: languages[choosenLanguage][
                                              'text_no_notification_found'],
                                              textAlign: TextAlign.center,
                                              fontweight: FontWeight.w600,
                                              size: media.width * sixteen),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Popup showinfo ──────────────────────────────────────
                    if (showinfo == true)
                      Positioned(
                          top: 0,
                          child: Container(
                            height: media.height,
                            width: media.width,
                            color: Colors.transparent.withOpacity(0.6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(media.width * 0.05),
                                      width: media.width * 0.9,
                                      constraints: BoxConstraints(
                                          maxHeight: media.height * 0.75), // ← AJOUT
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              color: white.withOpacity(0.3)),
                                          borderRadius: BorderRadius.circular(30),
                                          color: darkModeDialogColor),
                                      child: SingleChildScrollView( // ← AJOUT
                                        child: Column(              // ← AJOUT
                                          children: [
                                            MyText(
                                              text: notificationHistory[showinfovalue!]['title'].toString(),
                                              size: media.width * twentyfour,
                                              fontweight: FontWeight.w600,
                                            ),
                                            SizedBox(height: media.width * 0.02),
                                            MyText(
                                              text: notificationHistory[showinfovalue!]['body'].toString(),
                                              size: media.width * seventeen,
                                              color: Color(0xff7B7B7B),
                                            ),
                                            SizedBox(height: media.width * 0.05),
                                            if (notificationHistory[showinfovalue!]['image'] != null &&
                                                notificationHistory[showinfovalue!]['image'].toString().isNotEmpty &&
                                                !notificationHistory[showinfovalue!]['image'].toString().endsWith('/'))
                                              Container(
                                                height: media.width * 0.4,
                                                width: media.width * 0.6,
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(color: white.withOpacity(0.2)),
                                                    image: DecorationImage(
                                                        fit: BoxFit.cover,
                                                        image: NetworkImage(
                                                          notificationHistory[showinfovalue!]['image'],
                                                        ))),
                                              )
                                          ],
                                        ),       // ferme Column
                                      ),         // ferme SingleChildScrollView
                                    ),           // ferme Container
                                    Positioned(
                                      top: 15,
                                      right: 15,
                                      child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              showinfo = false;
                                              showinfovalue = null;
                                            });
                                          },
                                          child: const Icon(Icons.cancel)),
                                    )
                                  ],
                                )
                              ],
                            ),
                          )),

                    // ── Popup error (suppression) ───────────────────────────
                    if (error == true)
                      Positioned(
                          top: 0,
                          child: Container(
                            height: media.height,
                            width: media.width,
                            color: Colors.transparent.withOpacity(0.6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(media.width * 0.05),
                                  width: media.width * 0.9,
                                  constraints: BoxConstraints(maxHeight: media.height * 0.75),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: white.withOpacity(0.3)),
                                      color: darkModeDialogColor),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        MyText(
                                          text: languages[choosenLanguage]['text_delete_notification'],
                                          size: media.width * sixteen,
                                          textAlign: TextAlign.center,
                                          fontweight: FontWeight.w600,
                                        ),
                                        SizedBox(height: media.width * 0.05),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Button(
                                                onTap: () async {
                                                  setState(() {
                                                    error = false;
                                                    notificationid = null;
                                                  });
                                                },
                                                borderRadius: 3000.0,
                                                width: Responsive.width(20, context),
                                                color: darkModeSecContainer,
                                                borcolor: white.withOpacity(0.2),
                                                height: Responsive.height(5, context),
                                                text: languages[choosenLanguage]['text_no']),
                                            SizedBox(width: media.width * 0.03),
                                            Button(
                                                onTap: () async {
                                                  setState(() {
                                                    isLoading = true;
                                                  });
                                                  var result = await deleteNotification(notificationid);
                                                  if (result == 'success') {
                                                    setState(() {
                                                      getdata();
                                                      error = false;
                                                      isLoading = false;
                                                      showToast();
                                                    });
                                                  }
                                                },
                                                width: Responsive.width(20, context),
                                                borderRadius: 3000.0,
                                                height: Responsive.height(5, context),
                                                text: languages[choosenLanguage]['text_yes']),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )),

                    if (isLoading == true)
                      const Positioned(top: 0, child: Loading())
                    else
                      Container(),
                    if (showToastbool == true)
                      Positioned(
                          bottom: media.height * 0.2,
                          left: media.width * 0.2,
                          right: media.width * 0.2,
                          child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.all(media.width * 0.025),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.transparent.withOpacity(0.6)),
                            child: MyText(
                              text: languages[choosenLanguage]['text_notification_deleted'],
                              size: media.width * twelve,
                              color: topBar,
                            ),
                          ))
                    else
                      Container()
                  ],
                ),
              );
            }));
  }
}