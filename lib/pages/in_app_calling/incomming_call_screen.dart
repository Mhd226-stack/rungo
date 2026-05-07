import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_token_service/agora_token_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_user/translations/translation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../common/responsive.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../widgets/widgets.dart';
import '../onTripPage/booking_confirmation.dart';

const _appId = '06b417f44ed0470e9249534d3a603920';
const _appCertificate = '67b6ab170b4b4d7cb78e48f94991f81d';
const callingStatus = 'calling_status';
const callingStatusIncomming = 'incomming';
const shouldShowIncommingCall = 'should_show_incomming_call';
const callingStatusDeclined = 'declined';
const callingStatusAccepted = 'accepted';

class IncommingCallScreen extends StatefulWidget {
  const IncommingCallScreen();

  @override
  State<IncommingCallScreen> createState() => _CallScreen();
}

late RtcEngine rtcEngin;
bool isCallActivated = false;

class _CallScreen extends State<IncommingCallScreen> {
  int? _remoteUid;
  bool isChannelCreated = false;
  final _ringtonePlayer = FlutterRingtonePlayer();
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    FirebaseDatabase.instance.ref('requests/${userRequestData['id']}').update({
      callingStatus: callingStatusIncomming,
      shouldShowIncommingCall: false
    });
    FirebaseDatabase.instance
        .ref('requests/${userRequestData['id']}')
        .onValue
        .listen((event) async {
      Map rideRequest = event.snapshot.value as Map;
      String currentCallingStatus = rideRequest[callingStatus];
      if (currentCallingStatus == callingStatusDeclined) {
        isCallActivated = false;
        await _ringtonePlayer.stop();
        await Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => BookingConfirmation()),
            (route) => false);
      } else if (currentCallingStatus == callingStatusAccepted) {
        isCallActivated = true;
      }
    });
  }

  Future<void> initializeAgora() async {
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
          FirebaseDatabase.instance
              .ref('requests/${userRequestData['id']}')
              .update({callingStatus: callingStatusIncomming});
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

    await rtcEngin.joinChannel(
      token: getToken,
      channelId: userRequestData['id'],
      uid: 0,
      options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster),
    );

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
          //   "Incomming call",
          //   style: GoogleFonts.inter(
          //     color: black,
          //   ),
          // ),
          leading: GestureDetector(
              onTap: () async {
                // await rtcEngin.leaveChannel();
                // await rtcEngin.release();
                // Navigator.pop(context);
              },
              child: Icon(
                Icons.arrow_back,
                color: Colors.transparent,
              )),
        ),
        body: WillPopScope(
          onWillPop: () => Future.value(false),
          child: Container(
            color: page,
            width: screenWidth,
            height: screenHeight,
            child: Stack(alignment: Alignment.topCenter, children: [
              Positioned(
                top: 0,
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
              Visibility(
                visible: isCallActivated,
                child: Positioned(
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
              ),
              Visibility(
                visible: isCallActivated,
                child: Positioned(
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
              ),
              Visibility(
                visible: !isCallActivated,
                child: Positioned(
                  bottom: Responsive.height(8, context),
                  right: Responsive.width(25, context),
                  child: InkWell(
                    onTap: () async {
                      await _ringtonePlayer.stop();
                      await initializeAgora();
                      await FirebaseDatabase.instance
                          .ref('requests/${userRequestData['id']}')
                          .update({callingStatus: callingStatusIncomming});
                    },
                    child: Container(
                      width: Responsive.width(15, context),
                      height: Responsive.width(15, context),
                      decoration: BoxDecoration(
                          color: buttonColor, shape: BoxShape.circle),
                      child: const Icon(
                        Icons.call,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: Responsive.height(8, context),
                left: Responsive.width(isCallActivated ? 40 : 25, context),
                child: InkWell(
                  onTap: () async {
                    if (isCallActivated) {
                      await rtcEngin.leaveChannel();
                      await rtcEngin.release();
                      isCallActivated = false;
                      await FirebaseDatabase.instance
                          .ref('requests/${userRequestData['id']}')
                          .update({
                        callingStatus: callingStatusDeclined,
                        shouldShowIncommingCall: true
                      });
                    } else {
                      // await rtcEngin.release();
                      isCallActivated = false;
                      await FirebaseDatabase.instance
                          .ref('requests/${userRequestData['id']}')
                          .update({
                        callingStatus: callingStatusDeclined,
                        shouldShowIncommingCall: true
                      });
                    }
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
