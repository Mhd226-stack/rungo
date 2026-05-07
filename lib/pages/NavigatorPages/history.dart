import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_user/common/responsive.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../noInternet/noInternet.dart';
import 'historydetails.dart';

class History extends StatefulWidget {
  const History({Key? key}) : super(key: key);

  @override
  State<History> createState() => _HistoryState();
}

dynamic selectedHistory;

class _HistoryState extends State<History> {
  int _showHistory = 0;
  bool _isLoading = true;
  dynamic isCompleted;
  bool _cancelRide = false;
  var _cancelId = '';

  @override
  void initState() {
    _isLoading = true;
    _getHistory();
    super.initState();
  }

//get history datas
  _getHistory() async {
    setState(() {
      myHistoryPage.clear();
      myHistory.clear();
    });
    var val = await getHistory('is_later=1');
    if (val == 'success') {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
        child: ValueListenableBuilder(
            valueListenable: valueNotifierBook.value,
            builder: (context, value, child) {
              return Directionality(
                textDirection: (languageDirection == 'rtl')
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Stack(
                  children: [
                    Container(
                      height: media.height * 1,
                      width: media.width * 1,
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
                                width: media.width * 1,
                                alignment: Alignment.center,
                                child: MyText(
                                  text: languages[choosenLanguage]
                                      ['text_enable_history'],
                                  size: media.width * twentythree,
                                  fontweight: FontWeight.w700,
                                ),
                              ),
                              Positioned(
                                  child: InkWell(
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: IosBackButton()))
                            ],
                          ),
                          SizedBox(
                            height: media.width * 0.06,
                          ),
                          Container(
                            height: media.width * 0.12,
                            width: media.width * 0.85,
                            decoration: BoxDecoration(
                              color: page,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      setState(() {
                                        myHistory.clear();
                                        myHistoryPage.clear();
                                        _showHistory = 0;
                                        _isLoading = true;
                                      });

                                      await getHistory('is_later=1');
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    },
                                    child: Container(
                                        height: media.width * 0.1,
                                        alignment: Alignment.center,
                                        width: media.width * 0.28,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(3000),
                                            color: (_showHistory == 0)
                                                ? buttonColor
                                                : darkModeSecContainer),
                                        child: MyText(
                                            text: languages[choosenLanguage]
                                                ['text_upcoming'],
                                            size: media.width * fourteen,
                                            fontweight: FontWeight.w500,
                                            color: white)),
                                  ),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      setState(() {
                                        myHistory.clear();
                                        myHistoryPage.clear();
                                        _showHistory = 1;
                                        _isLoading = true;
                                      });

                                      await getHistory('is_completed=1');
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    },
                                    child: Container(
                                        height: media.width * 0.1,
                                        alignment: Alignment.center,
                                        width: media.width * 0.26,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(3000),
                                            color: (_showHistory == 1)
                                                ? buttonColor
                                                : darkModeSecContainer),
                                        child: MyText(
                                            text: languages[choosenLanguage]
                                                ['text_completed'],
                                            size: media.width * fourteen,
                                            fontweight: FontWeight.w500,
                                            color: white)),
                                  ),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      setState(() {
                                        myHistory.clear();
                                        myHistoryPage.clear();
                                        _showHistory = 2;
                                        _isLoading = true;
                                      });

                                      await getHistory('is_cancelled=1');
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    },
                                    child: Container(
                                        height: media.width * 0.1,
                                        alignment: Alignment.center,
                                        width: media.width * 0.27,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(3000),
                                            color: (_showHistory == 2)
                                                ? buttonColor
                                                : darkModeSecContainer),
                                        child: MyText(
                                            text: languages[choosenLanguage]
                                                ['text_cancelled'],
                                            size: media.width * fourteen,
                                            fontweight: FontWeight.w500,
                                            color: white)),
                                  ),
                                )
                              ],
                            ),
                          ),
                          SizedBox(
                            height: Responsive.height(1, context),
                          ),
                          Container(
                            color: white.withOpacity(0.6),
                            width: media.width * 0.85,
                            height: 1,
                          ),
                          Expanded(
                              child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                (myHistory.isNotEmpty)
                                    ? Column(
                                        children: myHistory
                                            .asMap()
                                            .map((i, value) {
                                              return MapEntry(
                                                  i,
                                                  (_showHistory == 1)
                                                      ?
                                                      //completed ride history
                                                      Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            InkWell(
                                                              onTap: () {
                                                                selectedHistory =
                                                                    i;

                                                                Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                        builder:
                                                                            (context) =>
                                                                                const HistoryDetails()));
                                                              },
                                                              child: Container(
                                                                margin: EdgeInsets.only(
                                                                    top: media
                                                                            .width *
                                                                        0.025,
                                                                    bottom: media
                                                                            .width *
                                                                        0.05,
                                                                    left: media
                                                                            .width *
                                                                        0.015,
                                                                    right: media
                                                                            .width *
                                                                        0.015),
                                                                width: media
                                                                        .width *
                                                                    0.85,
                                                                padding: EdgeInsets.fromLTRB(
                                                                    media.width *
                                                                        0.025,
                                                                    media.width *
                                                                        0.05,
                                                                    media.width *
                                                                        0.025,
                                                                    media.width *
                                                                        0.05),
                                                                decoration: BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10),
                                                                    color:
                                                                        darkModeSecContainer,
                                                                    border: Border.all(
                                                                        color: white
                                                                            .withOpacity(0.3))),
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .end,
                                                                      children: [
                                                                        Container(
                                                                          padding: EdgeInsets.all(Responsive.width(
                                                                              2,
                                                                              context)),
                                                                          decoration: BoxDecoration(
                                                                              color: darkModeDialogColor,
                                                                              borderRadius: BorderRadius.circular(10)),
                                                                          child:
                                                                              MyText(
                                                                            text:
                                                                                myHistory[i]['request_number'],
                                                                            size:
                                                                                media.width * eleven,
                                                                            fontweight:
                                                                                FontWeight.w500,
                                                                            color: (isDarkTheme == true)
                                                                                ? white
                                                                                : textColor,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        SizedBox(
                                                                          width: Responsive.width(
                                                                              10,
                                                                              context),
                                                                        ),
                                                                        Container(
                                                                          height:
                                                                              media.width * 0.14,
                                                                          width:
                                                                              media.width * 0.14,
                                                                          decoration: BoxDecoration(
                                                                              shape: BoxShape.circle,
                                                                              image: DecorationImage(image: NetworkImage(myHistory[i]['driverDetail']['data']['profile_picture']), fit: BoxFit.cover)),
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              media.width * 0.03,
                                                                        ),
                                                                        Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            MyText(
                                                                              text: getFirstName(myHistory[i]['driverDetail']['data']['name']),
                                                                              size: media.width * sixteen,
                                                                              fontweight: FontWeight.w500,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              3,
                                                                        ),
                                                                        Icon(
                                                                          Icons
                                                                              .star,
                                                                          color:
                                                                              Color(0xffF79E1B),
                                                                          size:
                                                                              13,
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              3,
                                                                        ),
                                                                        MyText(
                                                                            text:
                                                                                myHistory[i]['driverDetail']['data']['rating'].toString(),
                                                                            size: 13.0)
                                                                      ],
                                                                    ),
                                                                    SizedBox(
                                                                      height: media
                                                                              .width *
                                                                          0.06,
                                                                    ),
                                                                    Padding(
                                                                      padding: EdgeInsets.only(
                                                                          left: Responsive.width(
                                                                              5,
                                                                              context),
                                                                          right: Responsive.width(
                                                                              3,
                                                                              context)),
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.start,
                                                                        children: [
                                                                          Container(
                                                                            height:
                                                                                media.width * 0.045,
                                                                            width:
                                                                                media.width * 0.045,
                                                                            alignment:
                                                                                Alignment.center,
                                                                            decoration:
                                                                                BoxDecoration(shape: BoxShape.circle, border: Border.all(color: buttonColor)),
                                                                            child:
                                                                                Container(
                                                                              height: media.width * 0.025,
                                                                              width: media.width * 0.025,
                                                                              decoration: BoxDecoration(shape: BoxShape.circle, color: buttonColor),
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                media.width * 0.03,
                                                                          ),
                                                                          Expanded(
                                                                            child:
                                                                                MyText(
                                                                              text: myHistory[i]['pick_address'],
                                                                              // maxLines:
                                                                              //     1,
                                                                              size: media.width * twelve,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      height: media
                                                                              .width *
                                                                          0.03,
                                                                    ),
                                                                    Padding(
                                                                      padding: EdgeInsets.only(
                                                                          left: Responsive.width(
                                                                              5,
                                                                              context),
                                                                          right: Responsive.width(
                                                                              3,
                                                                              context)),
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.start,
                                                                        children: [
                                                                          Icon(
                                                                              Icons.location_on_outlined,
                                                                              color: white,
                                                                              size: media.width * eighteen),
                                                                          SizedBox(
                                                                            width:
                                                                                media.width * 0.03,
                                                                          ),
                                                                          Expanded(
                                                                            child:
                                                                                MyText(
                                                                              text: myHistory[i]['drop_address'],
                                                                              size: media.width * twelve,
                                                                              // maxLines:
                                                                              //     1,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      height: Responsive
                                                                          .height(
                                                                              3,
                                                                              context),
                                                                    ),
                                                                    Container(
                                                                      height: 1,
                                                                      width: media
                                                                              .width *
                                                                          0.9,
                                                                      color: white
                                                                          .withOpacity(
                                                                              0.8),
                                                                    ),
                                                                    SizedBox(
                                                                      height: media
                                                                              .width *
                                                                          0.03,
                                                                    ),
                                                                    Padding(
                                                                      padding: EdgeInsets.only(
                                                                          left: Responsive.width(
                                                                              5,
                                                                              context)),
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Expanded(
                                                                            flex:
                                                                                75,
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                Icon(Icons.credit_card_rounded, color: textColor),
                                                                                SizedBox(
                                                                                  width: media.width * 0.03,
                                                                                ),
                                                                                MyText(
                                                                                  text: languages[choosenLanguage]['text_paymentmethod'],
                                                                                  size: media.width * fourteen,
                                                                                  fontweight: FontWeight.w500,
                                                                                )
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          Expanded(
                                                                              flex: 25,
                                                                              child: Row(
                                                                                children: [
                                                                                  MyText(
                                                                                    text: (myHistory[i]['payment_opt'] == '1')
                                                                                        ? languages[choosenLanguage]['text_cash']
                                                                                        : (myHistory[i]['payment_opt'] == '2')
                                                                                            ? languages[choosenLanguage]['text_wallet']
                                                                                            : (myHistory[i]['payment_opt'] == '0')
                                                                                                ? languages[choosenLanguage]['text_card']
                                                                                                : '',
                                                                                    size: media.width * fourteen,
                                                                                    color: textColor.withOpacity(0.5),
                                                                                  ),
                                                                                ],
                                                                              ))
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      height: media
                                                                              .width *
                                                                          0.02,
                                                                    ),
                                                                    Padding(
                                                                      padding: EdgeInsets.only(
                                                                          left: Responsive.width(
                                                                              5,
                                                                              context)),
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Expanded(
                                                                            flex:
                                                                                75,
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                Icon(Icons.timer, color: textColor),
                                                                                SizedBox(
                                                                                  width: media.width * 0.03,
                                                                                ),
                                                                                MyText(
                                                                                  text: languages[choosenLanguage]['text_duration'],
                                                                                  size: media.width * fourteen,
                                                                                  fontweight: FontWeight.w500,
                                                                                )
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          Expanded(
                                                                              flex: 25,
                                                                              child: Row(
                                                                                children: [
                                                                                  MyText(
                                                                                    text: (myHistory[i]['total_time'] < 50) ? '${myHistory[i]['total_time']} mins' : '${(myHistory[i]['total_time'] / 60).round()} hr',
                                                                                    size: media.width * fourteen,
                                                                                    color: textColor.withOpacity(0.5),
                                                                                  ),
                                                                                ],
                                                                              ))
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      height: media
                                                                              .width *
                                                                          0.02,
                                                                    ),
                                                                    Padding(
                                                                      padding: EdgeInsets.only(
                                                                          left: Responsive.width(
                                                                              5,
                                                                              context)),
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Expanded(
                                                                            flex:
                                                                                75,
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                Icon(Icons.route_rounded, color: textColor),
                                                                                SizedBox(
                                                                                  width: media.width * 0.03,
                                                                                ),
                                                                                MyText(
                                                                                  text: languages[choosenLanguage]['text_distance'],
                                                                                  size: media.width * fourteen,
                                                                                  fontweight: FontWeight.w500,
                                                                                )
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          Expanded(
                                                                              flex: 25,
                                                                              child: Row(
                                                                                children: [
                                                                                  MyText(
                                                                                    text: (myHistory[i]['total_time'] < 50) ? myHistory[i]['total_distance'] + myHistory[i]['unit'] : myHistory[i]['total_distance'] + myHistory[i]['unit'],
                                                                                    size: media.width * fourteen,
                                                                                    color: textColor.withOpacity(0.5),
                                                                                  ),
                                                                                ],
                                                                              ))
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      height: media
                                                                              .width *
                                                                          0.02,
                                                                    ),
                                                                    Padding(
                                                                      padding: EdgeInsets.only(
                                                                          left: Responsive.width(
                                                                              5,
                                                                              context)),
                                                                      child:
                                                                          Row(
                                                                        children: [
                                                                          Expanded(
                                                                            flex:
                                                                                75,
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                Icon(Icons.receipt, color: textColor),
                                                                                SizedBox(
                                                                                  width: media.width * 0.03,
                                                                                ),
                                                                                MyText(
                                                                                  text: languages[choosenLanguage]['text_total'],
                                                                                  size: media.width * fourteen,
                                                                                  fontweight: FontWeight.w500,
                                                                                )
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          MyText(
                                                                            text: '${myHistory[i]['requestBill']['data']['requested_currency_symbol']} ${myHistory[i]['request_eta_amount'].toString()}',
                                                                            size: media.width * fourteen,
                                                                            fontweight: FontWeight.w400,
                                                                            color: textColor.withOpacity(0.5),
                                                                            maxLines: 1,
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        )
                                                      : (_showHistory == 2)
                                                          ?

                                                          //rejected ride
                                                          Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Container(
                                                                  margin: EdgeInsets.only(
                                                                      top: media
                                                                              .width *
                                                                          0.025,
                                                                      bottom: media
                                                                              .width *
                                                                          0.03,
                                                                      left: media
                                                                              .width *
                                                                          0.015,
                                                                      right: media
                                                                              .width *
                                                                          0.015),
                                                                  width: media
                                                                          .width *
                                                                      0.85,
                                                                  padding: EdgeInsets.fromLTRB(
                                                                      media.width *
                                                                          0.025,
                                                                      media.width *
                                                                          0.05,
                                                                      media.width *
                                                                          0.025,
                                                                      media.width *
                                                                          0.05),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    border: Border.all(
                                                                        color: white
                                                                            .withOpacity(0.3)),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10),
                                                                    color:
                                                                        darkModeSecContainer,
                                                                  ),
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Row(
                                                                        children: [
                                                                          Container(
                                                                            padding:
                                                                                EdgeInsets.all(Responsive.width(2, context)),
                                                                            decoration:
                                                                                BoxDecoration(color: darkModeDialogColor, borderRadius: BorderRadius.circular(10)),
                                                                            child:
                                                                                MyText(
                                                                              text: myHistory[i]['request_number'],
                                                                              size: media.width * eleven,
                                                                              fontweight: FontWeight.w500,
                                                                              color: (isDarkTheme == true) ? Colors.white : textColor,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      (myHistory[i]['driverDetail'] !=
                                                                              null)
                                                                          ? Visibility(
                                                                              visible: false,
                                                                              child: Container(
                                                                                padding: EdgeInsets.only(bottom: media.width * 0.05),
                                                                                child: Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                                                  children: [
                                                                                    Container(
                                                                                      height: media.width * 0.13,
                                                                                      width: media.width * 0.13,
                                                                                      decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: NetworkImage(myHistory[i]['driverDetail']['data']['profile_picture']), fit: BoxFit.cover)),
                                                                                    ),
                                                                                    SizedBox(
                                                                                      width: media.width * 0.02,
                                                                                    ),
                                                                                    Column(
                                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                                      children: [
                                                                                        SizedBox(
                                                                                          width: media.width * 0.3,
                                                                                          child: Text(
                                                                                            myHistory[i]['driverDetail']['data']['name'],
                                                                                            style: GoogleFonts.inter(fontSize: media.width * eighteen, fontWeight: FontWeight.w600),
                                                                                          ),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            )
                                                                          : Container(),
                                                                      SizedBox(
                                                                        height: media.width *
                                                                            0.04,
                                                                      ),
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.start,
                                                                        children: [
                                                                          Container(
                                                                            height:
                                                                                media.width * 0.045,
                                                                            width:
                                                                                media.width * 0.045,
                                                                            alignment:
                                                                                Alignment.center,
                                                                            decoration:
                                                                                BoxDecoration(shape: BoxShape.circle, border: Border.all(color: buttonColor)),
                                                                            child:
                                                                                Container(
                                                                              height: media.width * 0.025,
                                                                              width: media.width * 0.025,
                                                                              decoration: BoxDecoration(shape: BoxShape.circle, color: buttonColor),
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                media.width * 0.03,
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                media.width * 0.5,
                                                                            child:
                                                                                MyText(
                                                                              text: myHistory[i]['pick_address'],
                                                                              size: media.width * twelve,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      (myHistory[i]['drop_address'] !=
                                                                              null)
                                                                          ? Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                SizedBox(
                                                                                  height: media.width * 0.03,
                                                                                ),
                                                                                Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                                                  children: [
                                                                                    Icon(Icons.location_on_outlined, color: white, size: media.width * eighteen),
                                                                                    SizedBox(
                                                                                      width: media.width * 0.03,
                                                                                    ),
                                                                                    Expanded(
                                                                                      child: MyText(
                                                                                        text: myHistory[i]['drop_address'],
                                                                                        // overflow: TextOverflow.ellipsis,
                                                                                        size: media.width * twelve,
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ],
                                                                            )
                                                                          : Container(),
                                                                      SizedBox(
                                                                        height: Responsive.height(
                                                                            4,
                                                                            context),
                                                                      ),
                                                                      Container(
                                                                        padding: EdgeInsets.fromLTRB(
                                                                            Responsive.width(6,
                                                                                context),
                                                                            5,
                                                                            Responsive.width(6,
                                                                                context),
                                                                            5),
                                                                        decoration: BoxDecoration(
                                                                            color:
                                                                                darkModeDialogColor,
                                                                            borderRadius:
                                                                                BorderRadius.circular(3000)),
                                                                        child:
                                                                            MyText(
                                                                          text: languages[choosenLanguage]
                                                                              [
                                                                              'text_cancelled'],
                                                                          size: media.width *
                                                                              sixteen,
                                                                          color:
                                                                              Colors.red,
                                                                        ),
                                                                      )
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            )
                                                          : (_showHistory == 0)
                                                              ?

                                                              //upcoming ride
                                                              Stack(
                                                                  alignment:
                                                                      Alignment
                                                                          .bottomCenter,
                                                                  children: [
                                                                    Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Container(
                                                                          margin: EdgeInsets.only(
                                                                              top: media.width * 0.025,
                                                                              bottom: media.width * 0.04,
                                                                              left: media.width * 0.015,
                                                                              right: media.width * 0.015),
                                                                          width:
                                                                              media.width * 0.85,
                                                                          padding: EdgeInsets.fromLTRB(
                                                                              media.width * 0.025,
                                                                              media.width * 0.05,
                                                                              media.width * 0.025,
                                                                              media.width * 0.05),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            borderRadius:
                                                                                BorderRadius.circular(10),
                                                                            border:
                                                                                Border.all(color: white.withOpacity(0.3)),
                                                                            color:
                                                                                darkModeSecContainer,
                                                                          ),
                                                                          child:
                                                                              Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              Row(
                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                children: [
                                                                                  Container(padding: EdgeInsets.all(Responsive.width(2, context)), decoration: BoxDecoration(color: darkModeDialogColor, borderRadius: BorderRadius.circular(10)), child: MyText(text: myHistory[i]['request_number'], size: media.width * eleven, fontweight: FontWeight.w500, color: textColor)),
                                                                                  MyText(
                                                                                    text: myHistory[i]['trip_start_time'],
                                                                                    size: media.width * eleven,
                                                                                    fontweight: FontWeight.w500,
                                                                                    color: white.withOpacity(0.37),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              SizedBox(
                                                                                height: media.width * 0.03,
                                                                              ),
                                                                              (myHistory[i]['driverDetail'] != null)
                                                                                  ? Container(
                                                                                      padding: EdgeInsets.only(bottom: media.width * 0.05),
                                                                                      child: Row(
                                                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                                                        children: [
                                                                                          Container(
                                                                                            height: media.width * 0.16,
                                                                                            width: media.width * 0.16,
                                                                                            decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: NetworkImage(myHistory[i]['driverDetail']['data']['profile_picture']), fit: BoxFit.cover)),
                                                                                          ),
                                                                                          SizedBox(
                                                                                            width: media.width * 0.02,
                                                                                          ),
                                                                                          Column(
                                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                                            children: [
                                                                                              SizedBox(
                                                                                                width: media.width * 0.3,
                                                                                                child: MyText(
                                                                                                  text: myHistory[i]['driverDetail']['data']['name'],
                                                                                                  size: media.width * eighteen,
                                                                                                  fontweight: FontWeight.w600,
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                          Expanded(
                                                                                            child: Row(
                                                                                              mainAxisAlignment: MainAxisAlignment.end,
                                                                                              children: [
                                                                                                Column(
                                                                                                  children: [
                                                                                                    const Icon(
                                                                                                      Icons.cancel,
                                                                                                      color: Color(0xffFF0000),
                                                                                                    ),
                                                                                                    SizedBox(
                                                                                                      height: media.width * 0.01,
                                                                                                    ),
                                                                                                  ],
                                                                                                ),
                                                                                              ],
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    )
                                                                                  : Container(),
                                                                              Row(
                                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                                children: [
                                                                                  Container(
                                                                                    height: media.width * 0.045,
                                                                                    width: media.width * 0.045,
                                                                                    alignment: Alignment.center,
                                                                                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: buttonColor)),
                                                                                    child: Container(
                                                                                      height: media.width * 0.025,
                                                                                      width: media.width * 0.025,
                                                                                      decoration: BoxDecoration(shape: BoxShape.circle, color: buttonColor),
                                                                                    ),
                                                                                  ),
                                                                                  SizedBox(
                                                                                    width: media.width * 0.03,
                                                                                  ),
                                                                                  SizedBox(
                                                                                    width: media.width * 0.5,
                                                                                    child: MyText(
                                                                                      text: myHistory[i]['pick_address'],
                                                                                      // maxLines: 1,
                                                                                      size: media.width * twelve,
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              (myHistory[i]['drop_address'] != null)
                                                                                  ? Column(
                                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                                      children: [
                                                                                        SizedBox(
                                                                                          height: media.width * 0.03,
                                                                                        ),
                                                                                        Row(
                                                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                                                          children: [
                                                                                            Icon(Icons.location_on_outlined, color: white, size: media.width * eighteen),
                                                                                            SizedBox(
                                                                                              width: media.width * 0.03,
                                                                                            ),
                                                                                            Expanded(
                                                                                              child: MyText(
                                                                                                text: myHistory[i]['drop_address'],
                                                                                                size: media.width * twelve,
                                                                                                // maxLines: 1,
                                                                                              ),
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                      ],
                                                                                    )
                                                                                  : Container(),
                                                                              SizedBox(
                                                                                height: Responsive.height(7, context),
                                                                              )
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        Container(
                                                                          padding: EdgeInsets.fromLTRB(
                                                                              Responsive.width(4, context),
                                                                              Responsive.height(1, context),
                                                                              Responsive.width(4, context),
                                                                              Responsive.height(1, context)),
                                                                          decoration: BoxDecoration(
                                                                              borderRadius: BorderRadius.circular(3000),
                                                                              border: Border.all(color: white.withOpacity(0.3)),
                                                                              color: darkModeSecContainer),
                                                                          child:
                                                                              InkWell(
                                                                            onTap:
                                                                                () {
                                                                              setState(() {
                                                                                _cancelRide = true;
                                                                                _cancelId = myHistory[i]['id'];
                                                                              });
                                                                            },
                                                                            child:
                                                                                MyText(
                                                                              text: languages[choosenLanguage]['text_cancel_ride'],
                                                                              size: media.width * sixteen,
                                                                              fontweight: FontWeight.w400,
                                                                              color: Color(0xffEC001B),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          height: Responsive.height(
                                                                              2,
                                                                              context),
                                                                        )
                                                                      ],
                                                                    ),
                                                                    Positioned(
                                                                      bottom: Responsive.height(
                                                                          8.5,
                                                                          context),
                                                                      child:
                                                                          Container(
                                                                        alignment:
                                                                            Alignment.center,
                                                                        width: media.width *
                                                                            0.85,
                                                                        height: Responsive.height(
                                                                            4,
                                                                            context),
                                                                        decoration: BoxDecoration(
                                                                            borderRadius: BorderRadius.circular(
                                                                                10),
                                                                            color: Color.fromRGBO(
                                                                                123,
                                                                                123,
                                                                                123,
                                                                                0.22)),
                                                                        child:
                                                                            MyText(
                                                                          text:
                                                                              '${languages[choosenLanguage]['text_total']} ${myHistory[i]['requested_currency_symbol']} ${myHistory[i]['request_eta_amount']}',
                                                                          size:
                                                                              16,
                                                                          fontweight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                      ),
                                                                    )
                                                                  ],
                                                                )
                                                              : Container());
                                            })
                                            .values
                                            .toList(),
                                      )
                                    : (_isLoading == false)
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                height: media.width * 0.3,
                                              ),
                                              GestureDetector(
                                                // onTap: () async {
                                                //   final fcmToken =
                                                //       await FirebaseMessaging
                                                //           .instance
                                                //           .getToken();
                                                //   if (fcmToken != null) {
                                                //     await http.post(
                                                //       Uri.parse(
                                                //           'https://fcm.googleapis.com/fcm/send'),
                                                //       headers: <String, String>{
                                                //         'Content-Type':
                                                //             'application/json',
                                                //         'Authorization':
                                                //             'key=AAAAPVmZvZY:APA91bGkzkMOEiLFP1a8h6x3cep66R11Y2AGBCrlg6mySXHg-1oZEWuFxlOzwAzpjjDzlh5uoYsEYrTBeY7nZkkEaJt_tYbfCMpXmAd8edJ-YmnFGMuK4ymlWZmICDK2TWVpm5-vrCVh',
                                                //       },
                                                //       body: jsonEncode(
                                                //         <String, dynamic>{
                                                //           'to': fcmToken,
                                                //           'notification':
                                                //               <String, dynamic>{
                                                //             'title':
                                                //                 'Notification Title',
                                                //             'body':
                                                //                 'This is a notification from your app.',
                                                //           },
                                                //           'data':
                                                //               <String, dynamic>{
                                                //             'click_action':
                                                //                 'FLUTTER_NOTIFICATION_CLICK',
                                                //             'status': 'done',
                                                //           },
                                                //         },
                                                //       ),
                                                //     );
                                                //   }
                                                // },
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  height: media.width * 0.5,
                                                  width: media.width * 0.5,
                                                  decoration: const BoxDecoration(
                                                      image: DecorationImage(
                                                          image: AssetImage(
                                                              'assets/images/no_data_found.png'),
                                                          fit: BoxFit.contain)),
                                                ),
                                              ),
                                              SizedBox(
                                                height: media.width * 0.05,
                                              ),
                                              SizedBox(
                                                width: media.width * 0.8,
                                                child: MyText(
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_noorder'],
                                                    textAlign: TextAlign.center,
                                                    fontweight: FontWeight.w600,
                                                    size:
                                                        media.width * sixteen),
                                              ),
                                            ],
                                          )
                                        : Container(),
                                (myHistoryPage['pagination'] != null)
                                    ? (myHistoryPage['pagination']
                                                ['current_page'] <
                                            myHistoryPage['pagination']
                                                ['total_pages'])
                                        ? InkWell(
                                            onTap: () async {
                                              setState(() {
                                                _isLoading = true;
                                              });
                                              if (_showHistory == 0) {
                                                await getHistoryPages(
                                                    'is_later=1&page=${myHistoryPage['pagination']['current_page'] + 1}');
                                              } else if (_showHistory == 1) {
                                                await getHistoryPages(
                                                    'is_completed=1&page=${myHistoryPage['pagination']['current_page'] + 1}');
                                              } else if (_showHistory == 2) {
                                                await getHistoryPages(
                                                    'is_cancelled=1&page=${myHistoryPage['pagination']['current_page'] + 1}');
                                              }
                                              setState(() {
                                                _isLoading = false;
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
                                              child: MyText(
                                                text: languages[choosenLanguage]
                                                    ['text_loadmore'],
                                                size: media.width * sixteen,
                                              ),
                                            ),
                                          )
                                        : Container()
                                    : Container()
                              ],
                            ),
                          ))
                        ],
                      ),
                    ),

                    (_cancelRide == true)
                        ? Positioned(
                            child: Container(
                              height: media.height * 1,
                              width: media.width * 1,
                              color: Colors.transparent.withOpacity(0.6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        padding:
                                            EdgeInsets.all(media.width * 0.05),
                                        width: media.width * 0.9,
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: white.withOpacity(0.3)),
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            color: page),
                                        child: Column(
                                          children: [
                                            SizedBox(
                                              height:
                                                  Responsive.height(3, context),
                                            ),
                                            MyText(
                                              text: languages[choosenLanguage]
                                                  ['text_ridecancel'],
                                              size: media.width * seventeen,
                                            ),
                                            SizedBox(
                                              height: media.width * 0.05,
                                            ),
                                            Button(
                                                onTap: () async {
                                                  setState(() {
                                                    _isLoading = true;
                                                  });
                                                  await cancelLaterRequest(
                                                      _cancelId);
                                                  await _getHistory();
                                                  setState(() {
                                                    _cancelRide = false;
                                                    _cancelId = '';
                                                  });
                                                },
                                                text: languages[choosenLanguage]
                                                    ['text_cancel_ride'])
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 15,
                                        right: 15,
                                        child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                _cancelRide = false;
                                                _cancelId = '';
                                              });
                                            },
                                            child: Icon(
                                              Icons.cancel,
                                              color: textColor,
                                            )),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          )
                        : Container(),

                    //no internet
                    (internet == false)
                        ? Positioned(
                            top: 0,
                            child: NoInternet(
                              onTap: () {
                                setState(() {
                                  internetTrue();
                                });
                              },
                            ))
                        : Container(),

                    //loader
                    (_isLoading == true)
                        ? const Positioned(top: 0, child: Loading())
                        : Container()
                  ],
                ),
              );
            }));
  }
}
