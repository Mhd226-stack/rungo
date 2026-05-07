import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_token_service/agora_token_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_user/common/responsive.dart';
import 'package:flutter_user/functions/functions.dart';
import 'package:flutter_user/pages/onTripPage/booking_confirmation.dart';
import 'package:flutter_user/styles/styles.dart';
import 'package:flutter_user/translations/translation.dart';
import 'package:flutter_user/widgets/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

const _appId = '06b417f44ed0470e9249534d3a603920';
const _appCertificate = '67b6ab170b4b4d7cb78e48f94991f81d';

class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
  });
  @override
  State<CallScreen> createState() => _CallScreen();
}

bool isCallActivated = false;
late RtcEngine rtcEngin;

class _CallScreen extends State<CallScreen> {
  int? _remoteUid;
  bool isChannelCreated = false;

  bool _isMuted = true;
  bool _isSpeakerOn = false;
  @override
  void initState() {
    super.initState();
    FirebaseDatabase.instance
        .ref('requests/${userRequestData['id']}')
        .onValue
        .listen((event) async {
      Map rideRequest = event.snapshot.value as Map;
      String currentCallingStatus = rideRequest[callingStatus];
      if (currentCallingStatus == callingStatusDeclined) {
        await rtcEngin.leaveChannel();
        await rtcEngin.release();
        isCallActivated = false;
        if (mounted) {
          await Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => BookingConfirmation()),
              (route) => false);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initializeAgora();
  }

  initializeAgora() async {
    await [
      Permission.microphone,
      Permission.audio,
    ].request();

    rtcEngin = createAgoraRtcEngine();
    await rtcEngin.initialize(const RtcEngineContext(
        appId: _appId,
        channelProfile: ChannelProfileType.channelProfileCommunication));

    rtcEngin.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) async {
          await FirebaseDatabase.instance
              .ref('requests/${userRequestData['id']}')
              .update({
            callingStatus: callingStatusIncomming,
            shouldShowIncommingCall: true,
            'driver': false
          });
          setState(() {
            isChannelCreated = true;
          });
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() {
            _remoteUid = remoteUid;
            isCallActivated = true;
          });
        },
      ),
    );

    if (!isCallActivated) {
      await rtcEngin.joinChannel(
        token: getToken,
        channelId: userRequestData['id'],
        uid: 0,
        options: const ChannelMediaOptions(
            channelProfile: ChannelProfileType.channelProfileCommunication,
            clientRoleType: ClientRoleType.clientRoleBroadcaster),
      );
    }

    await rtcEngin.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await rtcEngin.enableAudio();
    await rtcEngin.enableLocalAudio(true);
  }

  String get getToken {
    const expirationTimeInSeconds = 3600;
    final currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final privilegeExpiredTs =
        currentTimestamp + expirationTimeInSeconds + 3600;
    String token = RtcTokenBuilder.build(
      appId: _appId,
      appCertificate: _appCertificate,
      channelName: userRequestData['id'],
      uid: 0.toString(),
      role: RtcRole.publisher,
      expireTimestamp: privilegeExpiredTs,
    );
    return token;
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;
    return Scaffold(
        backgroundColor: white,
        appBar: AppBar(
          backgroundColor: page,
          elevation: 0,
          // title: Text(
          //   "Call screen",
          //   style: GoogleFonts.inter(
          //     color: textColor,
          //     fontSize: 23,
          //   ),
          // ),
          leading: InkWell(
              onTap: () async {
                // Navigator.pop(context);
              },
              child: Icon(
                Icons.arrow_back,
                color: Colors.transparent,
              )),
        ),
        body: WillPopScope(
          onWillPop: () {
            return Future(
              () => false,
            );
          },
          child: Container(
            color: page,
            width: screenWidth,
            height: screenHeight,
            child: Stack(alignment: Alignment.topCenter, children: [
              Positioned(
                top: Responsive.height(0, context),
                child: Text(
                  _remoteUid == null
                      ? languages[choosenLanguage]['text_calling']
                      : languages[choosenLanguage]['text_call_activted'],
                  style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Positioned(
                left: Responsive.width(15, context),
                bottom: Responsive.height(8, context),
                child: InkWell(
                  onTap: () async {
                    if (_isMuted) {
                      await rtcEngin.enableLocalAudio(true);
                    } else {
                      await rtcEngin.enableLocalAudio(false);
                    }
                    _isMuted = !_isMuted;
                    setState(() {});
                  },
                  child: Container(
                    width: Responsive.width(15, context),
                    height: Responsive.width(15, context),
                    decoration: BoxDecoration(
                        color: _isMuted ? darkModeSecContainer : buttonColor,
                        shape: BoxShape.circle),
                    child: Icon(
                      _isMuted ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                      size: Responsive.width(8, context),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: Responsive.width(15, context),
                bottom: Responsive.height(8, context),
                child: InkWell(
                  onTap: () async {
                    if (_isSpeakerOn) {
                      await rtcEngin.setEnableSpeakerphone(false);
                    } else {
                      await rtcEngin.setEnableSpeakerphone(true);
                    }
                    _isSpeakerOn = !_isSpeakerOn;
                    setState(() {});
                  },
                  child: Container(
                    width: Responsive.width(15, context),
                    height: Responsive.width(15, context),
                    decoration: BoxDecoration(
                        color:
                            _isSpeakerOn ? buttonColor : darkModeSecContainer,
                        shape: BoxShape.circle),
                    child: Icon(
                      _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                      color: Colors.white,
                      size: Responsive.width(8, context),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: Responsive.height(8, context),
                child: InkWell(
                  onTap: () async {
                    await rtcEngin.leaveChannel();
                    await rtcEngin.release();
                    isCallActivated = false;
                    await FirebaseDatabase.instance
                        .ref('requests/${userRequestData['id']}')
                        .update({callingStatus: callingStatusDeclined});
                    // Navigator.pop(context);
                  },
                  child: Container(
                    width: Responsive.width(15, context),
                    height: Responsive.width(15, context),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child: Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: Responsive.width(9, context),
                    ),
                  ),
                ),
              ),
              Positioned(
                  top: Responsive.height(25, context),
                  child: Column(
                    children: [
                      Container(
                        width: Responsive.width(25, context),
                        height: Responsive.width(25, context),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                                fit: BoxFit.fill,
                                image: NetworkImage(
                                    userRequestData['driverDetail']['data']
                                        ['profile_picture']))),
                      ),
                      SizedBox(
                        height: Responsive.height(3, context),
                      ),
                      MyText(
                          text: userRequestData['driverDetail']['data']['name'],
                          fontweight: FontWeight.w800,
                          size: screenWidth * twentythree)
                    ],
                  ))
            ]),
          ),
        ));
  }
}
