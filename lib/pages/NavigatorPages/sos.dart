import 'package:flutter/material.dart';
import 'package:flutter_user/common/responsive.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import 'pickcontacts.dart';

class Sos extends StatefulWidget {
  const Sos({Key? key}) : super(key: key);

  @override
  State<Sos> createState() => _SosState();
}

class _SosState extends State<Sos> {
  bool _isDeleting = false;
  bool _isLoading = false;
  String _deleteId = '';

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
                                          ['text_add_trust_contact']
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

                          MyText(
                            text: languages[choosenLanguage]
                                ['text_trust_contact_3'],
                            size: media.width * eighteen,
                            fontweight: FontWeight.w400,
                          ),
                          SizedBox(
                            height: media.width * 0.02,
                          ),
                          MyText(
                            text: languages[choosenLanguage]
                                ['text_trust_contact_4'],
                            size: media.width * fourteen,
                            textAlign: TextAlign.start,
                            color: Color(0xff929292),
                          ),
                          SizedBox(
                            height: media.width * 0.06,
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: media.width * 0.025,
                                  ),
                                  (sosData
                                          .where((element) =>
                                              element['user_type'] != 'admin')
                                          .isNotEmpty)
                                      ? Container(
                                          padding: EdgeInsets.fromLTRB(
                                              media.width * 0.02,
                                              Responsive.height(2, context),
                                              Responsive.width(4, context),
                                              Responsive.height(2, context)),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: white.withOpacity(0.3)),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: darkModeSecContainer,
                                          ),
                                          child: Column(
                                            children: sosData
                                                .asMap()
                                                .map((i, value) {
                                                  return MapEntry(
                                                      i,
                                                      (sosData[i]['user_type'] !=
                                                              'admin')
                                                          ? Container(
                                                              padding: EdgeInsets
                                                                  .all(media
                                                                          .width *
                                                                      0.02),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .account_box_sharp,
                                                                    size: media
                                                                            .width *
                                                                        0.06,
                                                                    color:
                                                                        textColor,
                                                                  ),
                                                                  Column(
                                                                    children: [
                                                                      Container(
                                                                        padding:
                                                                            EdgeInsets.only(bottom: media.width * 0.01),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          border:
                                                                              Border(
                                                                            bottom:
                                                                                BorderSide(color: textColor.withOpacity(0.2)),
                                                                          ),
                                                                        ),
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                SizedBox(
                                                                                  width: media.width * 0.65,
                                                                                  child: MyText(
                                                                                    text: sosData[i]['name'],
                                                                                    size: media.width * sixteen,
                                                                                    fontweight: FontWeight.w400,
                                                                                  ),
                                                                                ),
                                                                                SizedBox(
                                                                                  height: media.width * 0.005,
                                                                                ),
                                                                                MyText(
                                                                                  text: sosData[i]['number'],
                                                                                  size: media.width * twelve,
                                                                                  color: Color(0xff7B7B7B),
                                                                                ),
                                                                                SizedBox(
                                                                                  height: media.width * 0.01,
                                                                                ),
                                                                              ],
                                                                            ),
                                                                            InkWell(
                                                                                onTap: () {
                                                                                  setState(() {
                                                                                    _deleteId = sosData[i]['id'];
                                                                                    _isDeleting = true;
                                                                                  });
                                                                                },
                                                                                child: Icon(Icons.delete, color: textColor))
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  )
                                                                ],
                                                              ),
                                                            )
                                                          : Container());
                                                })
                                                .values
                                                .toList(),
                                          ),
                                        )
                                      : Column(
                                          children: [
                                            GestureDetector(
                                              onTap: () async {
                                                var nav = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const PickContact(
                                                              from: '1',
                                                            )));
                                                if (nav) {
                                                  setState(() {});
                                                }
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(
                                                    media.width * 0.05),
                                                width: media.width * 0.9,
                                                decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: white
                                                            .withOpacity(0.3)),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    color:
                                                        darkModeSecContainer),
                                                child: Column(
                                                  children: [
                                                    Icon(Icons.add_card,
                                                        color: textColor
                                                            .withOpacity(0.5)),
                                                    SizedBox(
                                                      height:
                                                          media.width * 0.02,
                                                    ),
                                                    MyText(
                                                        text: languages[choosenLanguage]
                                                            [
                                                            'text_new_connection'],
                                                        color: textColor
                                                            .withOpacity(0.7),
                                                        size: media.width *
                                                            fourteen)
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                ],
                              ),
                            ),
                          ),

                          //add sos button
                          (sosData
                                      .where((element) =>
                                          element['user_type'] != 'admin')
                                      .length <
                                  5)
                              ? Container(
                                  padding: EdgeInsets.only(
                                      top: media.width * 0.05,
                                      bottom: media.width * 0.0),
                                  child: Button(
                                      onTap: () async {
                                        var nav = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const PickContact(
                                                      from: '1',
                                                    )));
                                        if (nav) {
                                          setState(() {});
                                        }
                                      },
                                      text: languages[choosenLanguage]
                                          ['text_add_trust_contact']))
                              : Container(),
                          ButtonBottomSpace(
                            height: 4,
                          )
                        ],
                      ),
                    ),

                    //delete sos
                    (_isDeleting == true)
                        ? Positioned(
                            top: 0,
                            child: Container(
                              height: media.height * 1,
                              width: media.width * 1,
                              color: Colors.transparent.withOpacity(0.6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: media.width * 0.9,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [],
                                    ),
                                  ),
                                  Stack(
                                    alignment: Alignment.topRight,
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
                                            color: darkModeDialogColor),
                                        child: Column(
                                          children: [
                                            SizedBox(
                                              height: Responsive.height(
                                                  3.5, context),
                                            ),
                                            MyText(
                                              text: languages[choosenLanguage]
                                                  ['text_removeSos'],
                                              size: media.width * sixteen,
                                              fontweight: FontWeight.w600,
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(
                                              height: media.width * 0.05,
                                            ),
                                            Button(
                                                onTap: () async {
                                                  setState(() {
                                                    _isLoading = true;
                                                  });

                                                  var val = await deleteSos(
                                                      _deleteId);
                                                  if (val == 'success') {
                                                    setState(() {
                                                      _isDeleting = false;
                                                    });
                                                  }
                                                  setState(() {
                                                    _isLoading = false;
                                                  });
                                                },
                                                text: languages[choosenLanguage]
                                                    ['text_confirm'])
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 15,
                                        right: 15,
                                        child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                _isDeleting = false;
                                              });
                                            },
                                            child: const Icon(Icons.cancel)),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          )
                        : Container(),
                    //loader
                    (_isLoading == true)
                        ? const Positioned(top: 0, child: Loading())
                        : Container()
                  ],
                ),
              );
            }),
      ),
    );
  }
}
