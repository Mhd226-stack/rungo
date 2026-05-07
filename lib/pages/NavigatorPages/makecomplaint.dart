import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../noInternet/noInternet.dart';

// ignore: must_be_immutable
class MakeComplaint extends StatefulWidget {
  int fromPage;
  // ignore: use_key_in_widget_constructors
  MakeComplaint({required this.fromPage});

  @override
  State<MakeComplaint> createState() => _MakeComplaintState();
}

int complaintType = 0;

class _MakeComplaintState extends State<MakeComplaint> {
  bool _isLoading = true;
  bool _showOptions = false;
  TextEditingController complaintText = TextEditingController();
  bool _success = false;
  String complaintDesc = '';
  String _error = '';

  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    setState(() {
      complaintType = 0;
      complaintDesc = '';
      generalComplaintList = [];
    });
    if (widget.fromPage == 1) {
      await getGeneralComplaint("request");
    } else {
      await getGeneralComplaint("general");
    }
    setState(() {
      _isLoading = false;
      if (generalComplaintList.isNotEmpty) {
        complaintType = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Material(
        child: Directionality(
          textDirection: (languageDirection == 'rtl')
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: Stack(
            children: [
              Container(
                height: media.height * 1,
                width: media.width * 1,
                color: page,
                padding: EdgeInsets.only(
                    left: media.width * 0.05, right: media.width * 0.05),
                child: Column(
                  children: [
                    SizedBox(
                        height: MediaQuery.of(context).padding.top +
                            media.width * 0.05),
                    Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.only(bottom: media.width * 0.05),
                          width: media.width * 1,
                          alignment: Alignment.center,
                          child: MyText(
                            text: languages[choosenLanguage]
                                ['text_feedback_page'],
                            size: media.width * twentythree,
                            fontweight: FontWeight.w700,
                          ),
                        ),
                        Positioned(
                            child: InkWell(
                                onTap: () {
                                  Navigator.pop(context, false);
                                },
                                child: IosBackButton()))
                      ],
                    ),
                    SizedBox(
                      height: media.width * 0.07,
                    ),
                    (generalComplaintList.isNotEmpty)
                        ? Expanded(
                            child: Column(children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (_showOptions == false) {
                                    _showOptions = true;
                                  } else {
                                    _showOptions = false;
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.only(
                                    left: media.width * 0.04,
                                    right: media.width * 0.05),
                                height: media.width * 0.12,
                                width: media.width * 0.9,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: white.withOpacity(0.3),
                                    )),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    MyText(
                                        text:
                                            generalComplaintList[complaintType]
                                                ['title'],
                                        color: white.withOpacity(0.95),
                                        size: media.width * fourteen),
                                    Container(
                                      height: media.width * 0.075,
                                      width: media.width * 0.07,
                                      child: Icon(
                                          Icons.keyboard_arrow_down_rounded),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            (_showOptions == true)
                                ? Column(
                                    children: [
                                      SizedBox(
                                        height: media.width * 0.05,
                                      ),
                                      Container(
                                        padding:
                                            EdgeInsets.all(media.width * 0.025),
                                        height: media.width * 0.3,
                                        width: media.width * 0.9,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: white.withOpacity(0.3)),
                                          color: page,
                                        ),
                                        child: SingleChildScrollView(
                                          physics:
                                              const BouncingScrollPhysics(),
                                          child: Column(
                                            children: generalComplaintList
                                                .asMap()
                                                .map((i, value) {
                                                  return MapEntry(
                                                      i,
                                                      InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            complaintType = i;
                                                            _showOptions =
                                                                false;
                                                          });
                                                        },
                                                        child: Container(
                                                          width:
                                                              media.width * 0.8,
                                                          padding: EdgeInsets.only(
                                                              top: media.width *
                                                                  0.025,
                                                              bottom:
                                                                  media.width *
                                                                      0.025),
                                                          decoration: BoxDecoration(
                                                              border: Border(
                                                                  bottom: BorderSide(
                                                                      width:
                                                                          1.1,
                                                                      color: (i ==
                                                                              generalComplaintList.length -
                                                                                  1)
                                                                          ? Colors
                                                                              .transparent
                                                                          : white
                                                                              .withOpacity(0.3)))),
                                                          child: MyText(
                                                              text:
                                                                  generalComplaintList[
                                                                          i]
                                                                      ['title'],
                                                              size:
                                                                  media.width *
                                                                      twelve),
                                                        ),
                                                      ));
                                                })
                                                .values
                                                .toList(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(),
                            SizedBox(
                              height: media.width * 0.07,
                            ),
                            Container(
                              padding: EdgeInsets.all(media.width * 0.025),
                              width: media.width * 0.9,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: (_error == '')
                                          ? white.withOpacity(0.3)
                                          : Colors.red,
                                      width: 1.2)),
                              child: TextField(
                                controller: complaintText,
                                minLines: 5,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintStyle: choosenLanguage == 'ar'
                                      ? GoogleFonts.cairo(
                                          color: textColor.withOpacity(0.4),
                                          fontSize: media.width * fourteen,
                                        )
                                      : GoogleFonts.inter(
                                          color: Color(0xff929292),
                                          fontSize: media.width * fourteen,
                                        ),
                                  hintText: languages[choosenLanguage]
                                          ['text_complaint_2'] +
                                      ' (' +
                                      languages[choosenLanguage]
                                          ['text_complaint_3'] +
                                      ')',
                                ),
                                onChanged: (val) {
                                  complaintDesc = val;
                                  if (val.length >= 10 && _error != '') {
                                    setState(() {
                                      _error = '';
                                    });
                                  }
                                },
                                style: choosenLanguage == 'ar'
                                    ? GoogleFonts.cairo(
                                        color: textColor,
                                      )
                                    : GoogleFonts.inter(color: textColor),
                              ),
                            ),
                            if (_error != '')
                              Container(
                                width: media.width * 0.8,
                                padding: EdgeInsets.only(
                                    top: media.width * 0.025,
                                    bottom: media.width * 0.025),
                                child: MyText(
                                  text: _error,
                                  size: media.width * fourteen,
                                  color: Colors.red,
                                ),
                              ),
                          ]))
                        : Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
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
                                      text: languages[choosenLanguage]
                                          ['text_no_complaints'],
                                      textAlign: TextAlign.center,
                                      fontweight: FontWeight.w600,
                                      size: media.width * sixteen),
                                ),
                              ],
                            ),
                          ),
                    (generalComplaintList.isNotEmpty)
                        ? Container(
                            padding: EdgeInsets.all(media.width * 0.05),
                            child: Button(
                                onTap: () async {
                                  if (complaintText.text.length >= 10) {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    dynamic result;

                                    result = await makeGeneralComplaint(
                                        complaintDesc);

                                    setState(() {
                                      if (result == 'success') {
                                        _success = true;
                                      }

                                      _isLoading = false;
                                    });
                                  } else {
                                    setState(() {
                                      _error = languages[choosenLanguage]
                                          ['text_complaint_text_error'];
                                    });
                                  }
                                },
                                text: languages[choosenLanguage]
                                    ['text_submit']),
                          )
                        : Container(),
                    ButtonBottomSpace()
                  ],
                ),
              ),

              (_success == true)
                  ? Positioned(
                      child: Container(
                      height: media.height * 1,
                      width: media.width * 1,
                      color: Colors.transparent.withOpacity(0.6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(media.width * 0.05),
                            width: media.width * 0.9,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  width: 1.2, color: white.withOpacity(0.3)),
                              color: darkModeDialogColor,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  width: media.width * 0.7,
                                  child: MyText(
                                    text: languages[choosenLanguage]
                                        ['text_complaint_success'],
                                    size: media.width * fifteen,
                                    fontweight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(
                                  height: media.width * 0.04,
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  width: media.width * 0.7,
                                  child: MyText(
                                    text: languages[choosenLanguage]
                                        ['text_complaint_success_2'],
                                    size: media.width * fifteen,
                                  ),
                                ),
                                SizedBox(
                                  height: media.width * 0.035,
                                ),
                                Button(
                                    onTap: () {
                                      Navigator.pop(context, true);
                                    },
                                    text: languages[choosenLanguage]
                                        ['text_close'])
                              ],
                            ),
                          )
                        ],
                      ),
                    ))
                  : Container(),
              //loader
              (_isLoading == true)
                  ? const Positioned(top: 0, child: Loading())
                  : Container(),

              //no internet
              (internet == false)
                  ? Positioned(
                      top: 0,
                      child: NoInternet(
                        onTap: () {
                          internetTrue();
                        },
                      ))
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
