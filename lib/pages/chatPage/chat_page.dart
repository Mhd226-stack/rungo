import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_user/common/responsive.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../in_app_calling/call_screen.dart';
import '../loadingPage/loading.dart';
import '../onTripPage/booking_confirmation.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController chatText = TextEditingController();
  ScrollController controller = ScrollController();
  bool _sendingMessage = false;
  @override
  void initState() {
    //get messages
    getCurrentMessages();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Material(
        child: Scaffold(
          body: ValueListenableBuilder(
              valueListenable: valueNotifierBook.value,
              builder: (context, value, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.animateTo(controller.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.ease);
                });
                //call for message seen
                messageSeen();

                return Directionality(
                  textDirection: (languageDirection == 'rtl')
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(
                            media.width * 0.05,
                            MediaQuery.of(context).padding.top +
                                media.width * 0.05,
                            media.width * 0.05,
                            media.width * 0.05),
                        height: media.height * 1,
                        width: media.width * 1,
                        color: page,
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                    padding: EdgeInsets.only(
                                        left: Responsive.width(12, context)),
                                    width: media.width * 0.9,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            width:
                                                Responsive.width(12, context),
                                            height:
                                                Responsive.height(6, context),
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                image: DecorationImage(
                                                    fit: BoxFit.fill,
                                                    image: NetworkImage(
                                                        userRequestData[
                                                                    'driverDetail']
                                                                ['data'][
                                                            'profile_picture']))),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Column(
                                          children: [
                                            InkWell(
                                              child: MyText(
                                                text: userRequestData[
                                                        'driverDetail']['data']
                                                    ['name'],
                                                size: media.width * seventeen,
                                                fontweight: FontWeight.w800,
                                              ),
                                            ),
                                            SizedBox(
                                              child: MyText(
                                                text: userRequestData[
                                                                'driverDetail']
                                                            ['data']
                                                        ['car_make_name'] +
                                                    ' ' +
                                                    userRequestData[
                                                                'driverDetail']
                                                            ['data']
                                                        ['car_model_name'],
                                                size: media.width * twelve,
                                                textAlign: TextAlign.end,
                                                maxLines: 1,
                                                color: const Color(0xff8A8A8A),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          width: Responsive.width(25, context),
                                        ),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              // makingPhoneCall(userRequestData['driverDetail']['data']['mobile']);
                                              if (userRequestData['id'] !=
                                                  null) {
                                                Navigator.push(context,
                                                    MaterialPageRoute(
                                                        builder: (context) {
                                                  FirebaseDatabase.instance
                                                      .ref(
                                                          'requests/${userRequestData['id']}')
                                                      .update({
                                                    callingStatus: readyForCall
                                                  });
                                                  return const CallScreen();
                                                }));
                                              }
                                            },
                                            child: Container(
                                                height: media.height * 0.045,
                                                width: media.width * 0.096,
                                                decoration: BoxDecoration(
                                                    color: buttonColor,
                                                    shape: BoxShape.circle),
                                                alignment: Alignment.center,
                                                child: Icon(Icons.call,
                                                    size: media.width * 0.055)),
                                          ),
                                        )
                                      ],
                                    )),
                                Positioned(
                                  child: InkWell(
                                      onTap: () {
                                        Navigator.pop(context, true);
                                      },
                                      child: IosBackButton()),
                                )
                              ],
                            ),
                            SizedBox(
                              height: media.width * 0.05,
                            ),
                            Expanded(
                                child: SingleChildScrollView(
                              controller: controller,
                              child: Column(
                                children: chatList
                                    .asMap()
                                    .map((i, value) {
                                      return MapEntry(
                                          i,
                                          Container(
                                            padding: EdgeInsets.only(
                                                top: media.width * 0.025),
                                            width: media.width * 0.9,
                                            alignment:
                                                (chatList[i]['from_type'] == 1)
                                                    ? Alignment.centerRight
                                                    : Alignment.centerLeft,
                                            child: Container(
                                              margin: EdgeInsets.only(
                                                  bottom: Responsive.height(
                                                      4, context)),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Visibility(
                                                    visible: !(chatList[i]
                                                            ['from_type'] ==
                                                        1),
                                                    child: Container(
                                                      width: Responsive.width(
                                                          12, context),
                                                      height: Responsive.width(
                                                          12, context),
                                                      decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          image: DecorationImage(
                                                              fit: BoxFit.fill,
                                                              image: NetworkImage(
                                                                  userRequestData[
                                                                              'driverDetail']
                                                                          [
                                                                          'data']
                                                                      [
                                                                      'profile_picture']))),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: chatList[i]
                                                                ['from_type'] ==
                                                            1
                                                        ? 0
                                                        : 10,
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: (chatList[
                                                                    i]
                                                                ['from_type'] ==
                                                            1)
                                                        ? CrossAxisAlignment.end
                                                        : CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Container(
                                                        width:
                                                            media.width * 0.5,
                                                        padding:
                                                            EdgeInsets.fromLTRB(
                                                                media.width *
                                                                    0.04,
                                                                media.width *
                                                                    0.04,
                                                                media.width *
                                                                    0.04,
                                                                media.width *
                                                                    0.02),
                                                        decoration: BoxDecoration(
                                                            borderRadius: (chatList[i][
                                                                        'from_type'] ==
                                                                    1)
                                                                ? BorderRadius.circular(20).copyWith(
                                                                    bottomRight:
                                                                        Radius.circular(
                                                                            0))
                                                                : BorderRadius.circular(20).copyWith(
                                                                    bottomLeft:
                                                                        Radius.circular(
                                                                            0)),
                                                            color: (chatList[i]
                                                                        ['from_type'] ==
                                                                    1)
                                                                ? buttonColor
                                                                : darkModeSenderTextColor),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            MyText(
                                                              text: chatList[i]
                                                                  ['message'],
                                                              size:
                                                                  media.width *
                                                                      sixteen,
                                                              fontweight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: textColor,
                                                            ),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .end,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .end,
                                                              children: [
                                                                MyText(
                                                                  text: chatList[
                                                                          i][
                                                                      'converted_created_at'],
                                                                  size: media
                                                                          .width *
                                                                      twelve,
                                                                  color: white
                                                                      .withOpacity(
                                                                          0.7),
                                                                )
                                                              ],
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ));
                                    })
                                    .values
                                    .toList(),
                              ),
                            )),

                            //text field
                            Container(
                              margin: EdgeInsets.only(top: media.width * 0.025),
                              padding: EdgeInsets.fromLTRB(
                                  media.width * 0.025,
                                  media.width * 0.01,
                                  media.width * 0.025,
                                  media.width * 0.01),
                              width: media.width * 0.9,
                              decoration: BoxDecoration(
                                  border:
                                      Border.all(color: white.withOpacity(0.2)),
                                  borderRadius: BorderRadius.circular(15),
                                  color: darkModeSecContainer),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: media.width * 0.7,
                                    child: TextField(
                                      controller: chatText,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: languages[choosenLanguage]
                                            ['text_entermessage'],
                                        hintStyle: choosenLanguage == 'ar'
                                            ? GoogleFonts.cairo(
                                                color:
                                                    textColor.withOpacity(0.4),
                                                fontSize: media.width * twelve,
                                              )
                                            : GoogleFonts.inter(
                                                color:
                                                    textColor.withOpacity(0.4),
                                                fontSize: 15,
                                                fontWeight: FontWeight.w300),
                                      ),
                                      style: choosenLanguage == 'ar'
                                          ? GoogleFonts.cairo(
                                              color: textColor,
                                            )
                                          : GoogleFonts.inter(
                                              color: textColor,
                                            ),
                                      minLines: 1,
                                      maxLines: 4,
                                      onChanged: (val) {},
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      setState(() {
                                        _sendingMessage = true;
                                      });
                                      await sendMessage(chatText.text);
                                      chatText.clear();
                                      setState(() {
                                        _sendingMessage = false;
                                      });
                                    },
                                    child: Icon(
                                      Icons.send,
                                      color: Color(0xff929292),
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      //loader
                      (_sendingMessage == true)
                          ? const Positioned(top: 0, child: Loading())
                          : Container()
                    ],
                  ),
                );
              }),
        ),
      ),
    );
  }
}
